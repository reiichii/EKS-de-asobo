# Terraform, ArgoCDで構成管理しつつ遊ベるEKSクラスタを構築する

## ディレクトリ構成

```
.
├── argocd_apps/          # ArgoCDアプリケーション定義
│   ├── games.yaml        # ゲームアプリケーション用ApplicationSet
│   ├── ops.yaml          # 運用系アプリケーション用ApplicationSet
│   ├── game_manifests/   # ゲームアプリケーションのマニフェスト
│   └── ops_manifests/    # 運用系（Karpenter等）のマニフェスト
└── terraform/            # インフラ構築用Terraformコード
    ├── main.tf           # メイン設定ファイル
    ├── variables.tf
    └── modules/
        ├── albc/         # AWS Load Balancer Controller
        ├── argocd/       # ArgoCD
        └── karpenter/    # Karpenter
```

## 前提条件

- AWSアカウント
- AWS CLI
- Terraform
- kubectl

## 構築手順

⚠️エラーが出た時にトラブルシューティングしやすくする目的で段階的に適用します。

### VPC、EKSクラスタ構築

Terraformを初期化・実行し、EKSクラスタを構築します。(EKSクラスタ構築には10分ほどかかります)

```
terraform -chdir=terraform init
```

```
terraform -chdir=terraform apply -target=module.vpc
```

```
terraform -chdir=terraform apply -target=module.eks
```

以下のコマンドを実行します。

```
aws eks --region ap-northeast-1 update-kubeconfig --name eks-handson
```

これによりローカル環境に接続情報を持つファイルが作成され、作成したEKSクラスタに対してkubectlコマンドでアクセスできるようになります。

```
kubectl get pod -n kube-system
```

```
# 出力例
NAME                           READY   STATUS    RESTARTS   AGE
aws-node-khlck                 2/2     Running   0          112s
aws-node-kqkbr                 2/2     Running   0          109s
coredns-5c658475b5-gklm7       1/1     Running   0          5m47s
coredns-5c658475b5-zwxcb       1/1     Running   0          5m47s
eks-pod-identity-agent-fh9wd   1/1     Running   0          113s
eks-pod-identity-agent-wprbj   1/1     Running   0          113s
kube-proxy-jr6nr               1/1     Running   0          109s
kube-proxy-knv9h               1/1     Running   0          112s
```

### ArgoCDの構築

AWS Load Balancerを構築します。

```
terraform -chdir=terraform apply -target=module.albc
```

以下により、aws-load-balancer-controllerがデプロイされていることが確認できます。

```
kubectl get deployment -n kube-system aws-load-balancer-controller
```

```
# 出力例
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller   2/2     2            2           71s
```

続いてArgoCDを構築します。

```
terraform -chdir=terraform apply -target=module.argocd
```

関連リソースが構築されていることが確認できます。

```
kubectl get deployment -n argocd
```

```
# 出力例
NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
argocd-applicationset-controller   1/1     1            1           36s
argocd-dex-server                  1/1     1            1           36s
argocd-notifications-controller    1/1     1            1           36s
argocd-redis                       1/1     1            1           36s
argocd-repo-server                 1/1     1            1           36s
argocd-server                      1/1     1            1           36s
```

Application Load Balancerの構築完了まで数分かかります。
その後Load Balancerに割り当てられたDNSからArgoCDのUIにアクセスしますが、インストールに利用したargo-helmのv6.0.0以降、Application Load Balancerにおいて空のホストのルーティングを設定できなくなったようです（空にするとデフォルトで「argocd.example.com」が入る）。

そのため本検証では以下のようにローカル環境でホストの設定を行います（Load BalancerのIPは固定ではないので、期間が空いたら再設定が必要になります）。

```
ALB_URL=$(kubectl get ingress argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
ALB_IP=$(dig +short $ALB_URL | head -1)
echo "$ALB_IP argocd.example.com" | sudo tee -a /etc/hosts
```

ブラウザから `http://argocd.example.com` へアクセスすると、ArgoCDのログイン画面が表示されます。ArgoCDの初期設定パスワードは構築時のログに出力され、Terraformで用いているライブラリによってEKSのsecretsに保存されるようになっているため、以下のようにパスワードを取得できます。ユーザー名は `admin`です。

```
echo "ArgoCD admin Password: $(kubectl get secrets argocd-initial-admin-secret -n argocd --template="{{index .data.password | base64decode}}")"
```

```
# 出力例
ArgoCD admin Password: xxx
```

### Karpenterのデプロイ

Karpenterを構築します。

```
terraform -chdir=terraform apply -target=module.karpenter
```

ここまででcontrollerの稼働が確認できます。

```
kubectl get deployment -n karpenter
```

```
# 出力例
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
karpenter   1/1     1            1           29s
```

続いてKarpenterで使われるNodePoolと、EC2NodeClassをArgoCDを使ってデプロイします。
以下のコマンドでArgoCDへアプリケーションセットを登録します。

```
kubectl apply --server-side -f argocd_apps/ops.yaml
```

ArgoCDのコンソールから、ops-applicationsというアプリケーションが追加されていることが確認できます。
詳細を開くと、EC2NodeClassとEC2NodePoolがあることが確認できます。

Karpenterの上で稼働するアプリケーションをデプロイし、インスタンスがスケールすることを確認します。

application用manifestを管理するApplicationSetをArgoCDに登録します。
先ほどと同様、以下のコマンドでArgoCDへアプリケーションセットを登録します。

```
kubectl apply --server-side -f argocd_apps/games.yaml
```

ArgoCDのコンソールから、games-applicationsというアプリケーションが追加されていることが確認できます。
application側のingressの設定により、ArgoCDで使用しているものとは別のLoad Balancerが起動します。

以下でNodeGroupに所属していないNode(Karpenterによって作成されたインスタンス)が増えていることを確認できます。

```
kubectl get nodes -o custom-columns="NAME:.metadata.name,CREATED-BY:.metadata.labels.karpenter\.sh/nodepool,NODE-GROUP:.metadata.labels.eks\.amazonaws\.com/nodegroup"
```

```
# 出力例
NAME                                             CREATED-BY   NODE-GROUP
ip-10-0-21-15.ap-northeast-1.compute.internal    <none>       ops-20250929130728367300000004
ip-10-0-23-127.ap-northeast-1.compute.internal   default      <none>
ip-10-0-45-103.ap-northeast-1.compute.internal   <none>       ops-20250929130728367300000004
```

アプリケーションは以下のコマンドでurlを取得し、ブラウザからアクセスできます。

```
echo "Application URL: http://$(kubectl get -n game-2048 ingress game-2048 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
```

## クリーンアップ

最初にApplicationSetを削除します。これを行わなずterraform destroyのみ実行すると自動作成されたLoad Balancerが削除されずに残ってしまいます。

```
kubectl delete -n argocd applicationset games-applications
kubectl delete -n argocd applicationset ops-applications
kubectl delete -n argocd ing
```

続いてTerraformで全てのリソースをdestoryします。時間がかかってタイムアウトしたりする場合があるので、その場合は再度destroyを実行してください。

```
terraform -chdir=terraform destroy
```

最後にもう一度destroyを実行し、リソースの削除漏れがないことを確認してください。
