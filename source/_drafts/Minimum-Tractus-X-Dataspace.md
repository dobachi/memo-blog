---

title: Minimum Tractus-X Dataspace
date: 2023-10-29 23:20:05
categories:
  - Knowledge Management
  - Data Spaces
  - Tractus-X
tags:
  - Data Spaces
  - IDS
  - Tructus-X

---

# メモ

[MXDのGitHub page] の通り、Minimum Tractus-X Dataspaceが登場した。
登場したのは、コミット履歴を見る限り、

```
Commits on Aug 7, 2023
```

のようだ。

## 準備

[準備] の通り、環境としてはKinDを用いた例になっている。予め環境整備しておくと良い。
その他、Terraformを用いるようだ。

## 基本

### 構成


まずTractus-X EDCコネクタが2種類。説明ではAliceとBobとされてる。
その他、vault、PostgreSQL、Identity Walletアプリ、Keycloakインスタンス。

### 起動


[起動方法] にある通り、kindを使って環境を起動する。

REAMDEに記載の内容。

```bash
# firstly go to the folder containing the config files
cd <path/of/mxd>
kind create cluster -n mxd --config kind.config.yaml
# the next step is specific to KinD and will be different for other Kubernetes runtimes!
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
# wait until the ingress controller is ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
terraform init
terraform apply
# type "yes" and press enter when prompted to do so 
```

軽く中身を確認する。

まず最初にkindでクラスタを構成する。

```bash
$ kind create cluster -n mxd --config kind.config.yaml
```

名前は `mxd` としている。

```bash
$ kind get clusters
mxd
$ kubectl cluster-info --context kind-mxd
Kubernetes control plane is running at https://127.0.0.1:33287
CoreDNS is running at https://127.0.0.1:33287/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

コンフィグファイルは以下の通り。

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
```

上記の通り、Ingress Controllerを用いている。

続いて、kubernetesにデプロイする。

```bash
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
$ kubectl wait --namespace ingress-nginx \
```

[KindのIngress NGINXのデプロイ] に記載の通り、
https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml が用いられている。

続いて、Terafformで環境構成する。

```bash
$ terraform init
$ terraform apply
```

起動したPodを見ると以下のとおり。

```bash
$ kubectl get pods
NAME                                                    READY   STATUS    RESTARTS        AGE
alice-tractusx-connector-controlplane-6fbdcf9c4-dxrr5   1/1     Running   1 (3h50m ago)   4d23h
alice-tractusx-connector-dataplane-5b6cc8c8fd-prxk9     1/1     Running   1 (3h50m ago)   4d23h
alice-vault-0                                           1/1     Running   1 (3h50m ago)   4d23h
bob-tractusx-connector-controlplane-847c74bb8c-r5h54    1/1     Running   1 (3h50m ago)   4d23h
bob-tractusx-connector-dataplane-5c9dc89c9-j9vt2        1/1     Running   1 (3h50m ago)   4d23h
bob-vault-0                                             1/1     Running   1 (3h50m ago)   4d23h
keycloak-6bdf4d7689-bkb24                               1/1     Running   2 (3h50m ago)   4d23h
miw-574bf87bc-bzdr8                                     1/1     Running   1 (3h50m ago)   4d23h
postgres-66677b8665-nqrr9                               1/1     Running   1 (3h50m ago)   4d23h
```

### Terraformの内容

Terraformのコンフィグの内容を確認する。

ひとまず `main.tf` を確認する。

#### main.tf

下記の通り、keycloakとkubernetesに依存関係を持つ。

```terraform
terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    // for generating passwords, clientsecrets etc.
    random = {
      source = "hashicorp/random"
    }

    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.3.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}
```

KubernetesのコンフィグPATHが指定されている。

```terraform
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
```

１つ目のコネクタの定義

```terraform
# First connector
module "alice-connector" {
  source            = "./modules/connector"
  humanReadableName = "alice"
  participantId     = var.alice-bpn
  database-host     = local.pg-ip
  database-name     = "alice"
  database-credentials = {
    user     = "postgres"
    password = "postgres"
  }
  ssi-config = {
    miw-url            = "http://${kubernetes_service.miw.metadata.0.name}:${var.miw-api-port}"
    miw-authorityId    = var.miw-bpn
    oauth-tokenUrl     = "http://${kubernetes_service.keycloak.metadata.0.name}:${var.keycloak-port}/realms/miw_test/protocol/openid-connect/token"
    oauth-clientid     = "alice_private_client"
    oauth-secretalias  = "client_secret_alias"
    oauth-clientsecret = "alice_private_client"
  }
}
```

`./modules/connector` 以下にコネクタのコンフィグが含まれている。
また先に構成したPostgreSQLを利用している。
合わせて認証の設定も含まれている。

２つ目のコネクタの定義も同様である。

### ./modules/connector

つづいてコネクタのコンフィグを見てみる。

# 参考

## GitHub

* [MXDのGitHub page]
* [準備]
* [起動方法]
* [KindのIngress NGINXのデプロイ]

[MXDのGitHub page]: https://github.com/eclipse-tractusx/tutorial-resources/tree/main/mxd
[準備]: https://github.com/eclipse-tractusx/tutorial-resources/tree/main/mxd#1-prerequisites
[起動方法]: https://github.com/eclipse-tractusx/tutorial-resources/tree/main/mxd#2-basic-dataspace-setup
[KindのIngress NGINXのデプロイ]: https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml



<!-- vim: set et tw=0 ts=2 sw=2: -->
