---

title: Create projects includes sbt launcher
date: 2020-12-07 01:12:13
categories:
  - Knowledge Management
  - Scala
  - SBT
tags:
  - SBT
  - Scala

---

# 参考

* [launcher]
* [sbt-launcher-package]
* [Coursier を使って最速でScalaの開発環境を整える]
* [csのインストール]

[launcher]: https://github.com/sbt/launcher
[sbt-launcher-package]: https://github.com/sbt/sbt-launcher-package
[Coursier を使って最速でScalaの開発環境を整える]: https://nomadblacky.hatenablog.com/entry/2020/03/22/164815
[csのインストール]: https://get-coursier.io/docs/cli-installation


# メモ

プロジェクト内に、sbt自体を含めてクローンしただけでビルドできるようにしたい、という動機。
現時点ではCoursierプロジェクトが汎用性※が高く便利であると、個人的には感じた。

※ここでは、多くの環境で実行可能で、様々なツールを一度にセットアップ可能という意味。

## Coursierプロジェクト

[Coursier を使って最速でScalaの開発環境を整える] のブログに記載されているとおり、
Scala開発環境を簡単に整えられる。

ひとまずDocker内で試す。

```shell
$ sudo docker pull ubuntu:18.04
$ sudo docker run -rm -it -d --name ubu ubuntu:18.04
$ sudo docker exec -it ubu /bin/bash
```

Dockerコンテナ内でインストール。

```shell
# apt update
# apt install -y curl
# curl -fLo cs https://git.io/coursier-cli-linux &&
     chmod +x cs &&
     ./cs
```

結果として以下がインストールされた様子。

```
Checking if the standard Scala applications are installed
  Installed ammonite
  Installed cs
  Installed coursier
  Installed scala
  Installed scalac
  Installed sbt
  Installed sbtn
  Installed scalafmt
```

`~/.profile`に環境変数等がまとまっているので有効化する。

```
# source ~/.profile
```

これでインストールされたコマンドが使用できるようになった。

なお、参考までに上記でダウンロードしたcsコマンドは以下の通り。

```
$ ./cs setup --help
Command: setup
Usage: cs setup
  --jvm  <string?>
  --jvm-dir  <string?>
  --system-jvm  <bool?>
  --local-only  <bool>
  --update  <bool>
  --jvm-index  <string?>
  --graalvm-home  <string?>
  --graalvm-option  <string*>
  --graalvm-default-version  <string?>
  --install-dir | --dir  <string?>
  --install-platform  <string?>
        Platform for prebuilt binaries (e.g. "x86_64-pc-linux", "x86_64-apple-darwin", "x86_64-pc-win32")
  --install-prefer-prebuilt  <bool>
  --only-prebuilt  <bool>
        Require prebuilt artifacts for native applications, don't try to build native executable ourselves
  --repository | -r  <maven|sonatype:$repo|ivy2local|bintray:$org/$repo|bintray-ivy:$org/$repo|typesafe:ivy-$repo|typesafe:$repo|sbt-plugin:$repo|ivy:$pattern>
        Repository - for multiple repositories, separate with comma and/or add this option multiple times (e.g. -r central,ivy2local -r sonatype:snapshots, or equivalently -r central,ivy2local,sonatype:snapshots)
  --default-repositories  <bool>
  --proguarded  <bool?>
  --channel  <org:name>
        Channel for apps
  --default-channels  <bool>
        Add default channels
  --contrib  <bool>
        Add contrib channel
  --file-channels  <bool>
        Add channels read from the configuration directory
  --cache  <string?>
        Cache directory (defaults to environment variable COURSIER_CACHE, or ~/.cache/coursier/v1 on Linux and ~/Library/Caches/Coursier/v1 on Mac)
  --mode | -m  <offline|update-changing|update|missing|force>
        Download mode (default: missing, that is fetch things missing from cache)
  --ttl | -l  <duration>
        TTL duration (e.g. "24 hours")
  --parallel | -n  <int>
        Maximum number of parallel downloads (default: 6)
  --checksum  <checksum1,checksum2,...>
        Checksum types to check - end with none to allow for no checksum validation if no checksum is available, example: SHA-256,SHA-1,none
  --retry-count  <int>
        Retry limit for Checksum error when fetching a file
  --cache-file-artifacts | --cfa  <bool>
        Flag that specifies if a local artifact should be cached.
  --follow-http-to-https-redirect  <bool>
        Whether to follow http to https redirections
  --credentials  <host(realm) user:pass|host user:pass>
        Credentials to be used when fetching metadata or artifacts. Specify multiple times to pass multiple credentials. Alternatively, use the COURSIER_CREDENTIALS environment variable
  --credential-file  <string*>
        Path to credential files to read credentials from
  --use-env-credentials  <bool>
        Whether to read credentials from COURSIER_CREDENTIALS (env) or coursier.credentials (Java property), along those passed with --credentials and --credential-file
  --quiet | -q  <counter>
        Quiet output
  --verbose | -v  <counter>
        Increase verbosity (specify several times to increase more)
  --progress | -P  <bool>
        Force display of progress bars
  --env  <bool>
  --user-home  <string?>
  --banner  <bool?>
  --yes | -y  <bool?>
  --try-revert  <bool>
  --apps  <string*>
```

## （補足）sbt-launcher-packageプロジェクト

[sbt-launcher-package] をビルドすることでSBTランチャーを提供できそうだった。


## （補足）launcherプロジェクト

https://github.com/sbt/launcher/blob/1.x/.java-version にも記載されているとおり、
JDK7系にしか公式に対応していなかった。



<!-- vim: set et tw=0 ts=2 sw=2: -->
