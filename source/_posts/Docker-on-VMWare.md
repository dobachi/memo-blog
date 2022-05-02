---

title: Docker on VMWare
date: 2019-11-09 21:33:42
categories:
  - Knowledge Management
  - Windows
  - Docker
tags:
  - Docker
  - VMWare
  - Windows

---

# 参考

* [Docker ToolboxをVMware Workstationで使う]
* [Hyper-VでなくVMwareでDocker for Windows を使う]
* [Get Docker Engine - Community for Ubuntu]

[Docker ToolboxをVMware Workstationで使う]: https://qiita.com/NaokiTsuchiya/items/b3680e97cd7378f9049d
[Hyper-VでなくVMwareでDocker for Windows を使う]: https://a5m2.mmatsubara.com/wp/?p=463
[Get Docker Engine - Community for Ubuntu]: https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository

# メモ

[Hyper-VでなくVMwareでDocker for Windows を使う] に習った。

## Docker環境

手元の環境は Windows + VMWare だったので、Vagrant + VMWareで環境を構築し、その中にDockerをインストールすることにした。

[Get Docker Engine - Community for Ubuntu] を参考に、dockerをインストールするようにした。
参考までに、Vagrantfileは以下のような感じである。
ubuntu18系をベースとしつつ、プロビジョニングの際にDockerをインストールする。

ただし、以下のVagrantfileのプロビジョニングでは、DockerサービスにTCPで接続することを許可するようにしている。
これはセキュリティ上問題があるため、注意して取り扱うこと。（あくまで動作確認程度に留めるのがよさそう）

Vagrantfile
```
Vagrant.configure("2") do |config|
  config.vm.define "docker-01" do |config|
        config.vm.box = "bento/ubuntu-18.04"
        config.vm.network :private_network, ip: "172.16.19.220"
        config.vm.hostname = "docker-01"
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    apt-key fingerprint 0EBFCD88
    add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    sed -i "s;fd://;tcp://0.0.0.0:2375;g" /lib/systemd/system/docker.service
  SHELL

end
```

WSLなどから以下のようにすることで、VM内のDockerにアクセスできる。

```
$ sudo docker --host tcp://172.16.19.220:2375 run hello-world
```

環境変数として、DOCKER_HOSTを設定しておいても良いだろう。

<!-- vim: set tw=0 ts=4 sw=4: -->
