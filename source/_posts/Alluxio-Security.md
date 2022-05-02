---

title: Alluxio Security
date: 2019-05-10 16:07:48
categories:
  - Knowledge Management
  - Alluxio
tags:
  - Alluxio
  - Security

---

# 参考

* [Alluxio公式ドキュメントのセキュリティに関する説明]
* [公式ドキュメントのAuthenticationの説明]
* [Kerberosがサポートされていない？]
* [AlluxioのJAAS実装では、login時に必ずTrueを返す？]
* [commitでも特に認証をしていないように見える？]

[Alluxio公式ドキュメントのセキュリティに関する説明]: https://docs.alluxio.io/os/user/stable/en/advanced/Security.html
[公式ドキュメントのAuthenticationの説明]: https://docs.alluxio.io/os/user/1.5/en/Security.html#authentication
[Kerberosがサポートされていない？]: https://github.com/Alluxio/alluxio/blob/master/core/common/src/main/java/alluxio/security/login/LoginModuleConfiguration.java#L81
[AlluxioのJAAS実装では、login時に必ずTrueを返す？]: https://github.com/Alluxio/alluxio/blob/master/core/common/src/main/java/alluxio/security/login/AlluxioLoginModule.java#L55
[commitでも特に認証をしていないように見える？]: https://github.com/Alluxio/alluxio/blob/master/core/common/src/main/java/alluxio/security/login/AlluxioLoginModule.java#L84
[mSubject.getPrincipalsしている箇所]: https://github.com/Alluxio/alluxio/blob/master/core/common/src/main/java/alluxio/security/login/AlluxioLoginModule.java#L86

# メモ

[Alluxio公式ドキュメントのセキュリティに関する説明] を眺めてみる。

提供機能は以下の通りか。

* 認証
* 認可
  * POSIXパーミッション相当の認可機能を提供する
* Impersonation
  * システムユーザなどが複数のユーザを演じることが可能
* 監査ログの出力

## ユーザ認証

基本的には、2019/05/10現在ではSIMPLEモードが用いられるようである。
`alluxio.security.login.username` プロパティで指定されたユーザ名か、そうでなければOS上のユーザ名がログインユーザ名として用いられる。

[公式ドキュメントのAuthenticationの説明] によると、

> JAAS (Java Authentication and Authorization Service) is used to determine who is currently executing the process.

とのこと。設定をどうするのか、という点はあまり記載されていない。

### Kerberos認証はサポートされていない

なお、 [Kerberosがサポートされていない？] を見る限り、2019/05/10現在でKerberosがサポートされていない。

### SIMPLEモードの認証

また、 [AlluxioのJAAS実装では、login時に必ずTrueを返す？] を見ると、2019/05/10現在ではユーザ・パスワード認証がloginメソッド内で定義されていないように見える。
また、念のために [commitでも特に認証をしていないように見える？] を見ても、commitメソッド内でも何かしら認証しているように見えない？

ただ、 [mSubject.getPrincipalsしている箇所] があるので、そこを確認したほうが良さそう。

関連する実装を確認する。

そこでまずは、 `alluxio.security.LoginUser#login` メソッドを確認する。
当該メソッドではSubjectインスタンスを生成し、 `alluxio.security.LoginUser#createLoginContext` メソッド
内部で `javax.security.auth.login.LoginContext` クラスのインスタンス生成に用いている。

alluxio/security/LoginUser.java:80
```
    Subject subject = new Subject();

    try {
      // Use the class loader of User.class to construct the LoginContext. LoginContext uses this
      // class loader to dynamically instantiate login modules. This enables
      // Subject#getPrincipals to use reflection to search for User.class instances.
      LoginContext loginContext = createLoginContext(authType, subject, User.class.getClassLoader(),
          new LoginModuleConfiguration(), conf);
      loginContext.login();
```

ちなみに、 `alluxio.security.authentication.AuthType` を確認している中で、
SIMPLEモードのときはクライアント側、サーバ側ともにVerify処理をしない旨のコメントを見つけた。

alluxio/security/authentication/AuthType.java:26
```
  /**
   * User is aware in Alluxio. On the client side, the login username is determined by the
   * "alluxio.security.login.username" property, or the OS user upon failure.
   * On the server side, the verification of client user is disabled.
   */
  SIMPLE,
```

現時点でわかったことをまとめると、SIMPLEモード時はプロパティで渡された情報や、そうでなければ
OSユーザから得られた情報を用いてユーザ名を用いるようになっている。

### CUSTOMモードの認証

一方、CUSTOMモード時はサーバ側で任意のVersify処理を実行する旨のコメントが記載されていた。

```
  /**
   * User is aware in Alluxio. On the client side, the login username is determined by the
   * "alluxio.security.login.username" property, or the OS user upon failure.
   * On the server side, the user is verified by a Custom authentication provider
   * (Specified by property "alluxio.security.authentication.custom.provider.class").
   */
  CUSTOM,
```

ユーザをVerifyしたいときは、CUSTOMモードを使い、サーバ側で確認せよ、ということか。
ただ、CUSTOMモードは [Alluxio公式ドキュメントのセキュリティに関する説明] において、

> CUSTOM
> Authentication is enabled. Alluxio file system can know the user accessing it,
> and use customized AuthenticationProvider to verify the user is the one he/she claims.
>
> Experimental. This mode is only used in tests currently.

と記載されており、「Experimental」であることから、積極的には使いづらい状況に見える。（2019/05/10現在）

関連事項として、 `alluxio.security.authentication.AuthenticationProvider` を見ると、
`alluxio.security.authentication.custom.provider.class` プロパティで渡された
クラス名を用いて CustomAuthenticationProvider をインスタンス生成するようにしているように見える。

alluxio/security/authentication/AuthenticationProvider.java:44
```
      switch (authType) {
        case SIMPLE:
          return new SimpleAuthenticationProvider();
        case CUSTOM:
          String customProviderName =
              conf.get(PropertyKey.SECURITY_AUTHENTICATION_CUSTOM_PROVIDER_CLASS);
          return new CustomAuthenticationProvider(customProviderName);
        default:
          throw new AuthenticationException("Unsupported AuthType: " + authType.getAuthName());
```

なお、テストには以下のような実装が見られ、CUSTOMモードの使い方を想像できる。

* alluxio.security.authentication.PlainSaslServerCallbackHandlerTest.NameMatchAuthenticationProvider
* alluxio.security.authentication.GrpcSecurityTest.ExactlyMatchAuthenticationProvider
* alluxio.server.auth.MasterClientAuthenticationIntegrationTest.NameMatchAuthenticationProvider
* alluxio.security.authentication.CustomAuthenticationProviderTest.MockAuthenticationProvider

ExactlyMatchAuthenticationProviderを用いたテストは以下の通り。

alluxio/security/authentication/GrpcSecurityTest.java:78
```
  public void testCustomAuthentication() throws Exception {

    mConfiguration.set(PropertyKey.SECURITY_AUTHENTICATION_TYPE, AuthType.CUSTOM.getAuthName());
    mConfiguration.set(PropertyKey.SECURITY_AUTHENTICATION_CUSTOM_PROVIDER_CLASS,
        ExactlyMatchAuthenticationProvider.class.getName());
    GrpcServer server = createServer(AuthType.CUSTOM);
    server.start();
    GrpcChannelBuilder channelBuilder =
        GrpcChannelBuilder.newBuilder(getServerConnectAddress(server), mConfiguration);
    channelBuilder.setCredentials(ExactlyMatchAuthenticationProvider.USERNAME,
        ExactlyMatchAuthenticationProvider.PASSWORD, null).build();
    server.shutdown();
  }
```

alluxio/security/authentication/GrpcSecurityTest.java:93
```
  public void testCustomAuthenticationFails() throws Exception {

    mConfiguration.set(PropertyKey.SECURITY_AUTHENTICATION_TYPE, AuthType.CUSTOM.getAuthName());
    mConfiguration.set(PropertyKey.SECURITY_AUTHENTICATION_CUSTOM_PROVIDER_CLASS,
        ExactlyMatchAuthenticationProvider.class.getName());
    GrpcServer server = createServer(AuthType.CUSTOM);
    server.start();
    GrpcChannelBuilder channelBuilder =
        GrpcChannelBuilder.newBuilder(getServerConnectAddress(server), mConfiguration);
    mThrown.expect(UnauthenticatedException.class);
    channelBuilder.setCredentials("fail", "fail", null).build();
    server.shutdown();
  }
```

参考までに、SIMPLEモードで用いられる `alluxio.security.authentication.plain.SimpleAuthenticationProvider` では、
実際に以下のように何もしないauthenticateメソッドが定義されている。

```
  public void authenticate(String user, String password) throws AuthenticationException {
    // no-op authentication
  }
```


## 監査ログ

[Alluxio公式ドキュメントのセキュリティに関する説明] の「AUDITING」にログのエントリが記載されている。
2019/05/10時点では、以下の通り。

* succeeded:
  * True if the command has succeeded. To succeed, it must also have been allowed.
* allowed:
  * True if the command has been allowed.
    Note that a command can still fail even if it has been allowed.
* ugi:
  * User group information, including username, primary group, and authentication type.
* ip:
  * Client IP address.
* cmd:
  * Command issued by the user.
* src:
  * Path of the source file or directory.
* dst:
  * Path of the destination file or directory. If not applicable, the value is null.
* perm:
  * User:group:mask or null if not applicable.

HDFSにおける監査ログ相当の内容が出力されるようだ。
これが、下層にあるストレージによらずに出力されるとしたら、
Alluxioによる抽象化層でAuditログを取る、という方針も悪くないか？

ただ、そのときにはどのパス（URI？）に、どのストレージをマウントしたか、という情報もセットで保存しておく必要があるだろう。
