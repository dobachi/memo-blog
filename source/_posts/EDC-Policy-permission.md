---

title: EDCステータス変化の様子の謎メモ
date: 2024-10-13 22:13:02
categories:
  - Knowledge Management
  - Data Spaces
  - EDC
tags:
  - Data Spaces
  - Connector
  - EDC

---

# メモ

[EDC/Samples] のステータス変化の謎メモ。
調べたのは、コミットb7e2220のバージョン。

このバージョンで扱うEDC Connectorのバージョンは以下。

gradle/libs.versions.toml:7

```
edc = "0.8.1"
```

```bash
git clone git@github.com:eclipse-edc/Connector.git -b refs/tags/v0.8.1
```

```diff
diff --git a/gradle.properties b/gradle.properties
index 4511d8eb5..1c57d1403 100644
--- a/gradle.properties
+++ b/gradle.properties
@@ -1,7 +1,8 @@
 group=org.eclipse.edc
-version=0.8.1-SNAPSHOT
+version=0.8.1
 # for now, we're using the same version for the autodoc plugin and the processor, but that could change in the future
-annotationProcessorVersion=0.8.1-SNAPSHOT
-edcGradlePluginsVersion=0.8.1-SNAPSHOT
+annotationProcessorVersion=0.8.1
+edcGradlePluginsVersion=0.8.1
 edcScmUrl=https://github.com/eclipse-edc/Connector.git
 edcScmConnection=scm:git:git@github.com:eclipse-edc/Connector.git
+org.gradle.jvmargs=-Xmx4096M
\ No newline at end of file
diff --git a/gradle/libs.versions.toml b/gradle/libs.versions.toml
index bdd4f8d83..ac3efafe5 100644
--- a/gradle/libs.versions.toml
+++ b/gradle/libs.versions.toml
@@ -9,7 +9,7 @@ atomikos = "6.0.0"
 awaitility = "4.2.1"
 bouncyCastle-jdk18on = "1.78.1"
 cloudEvents = "4.0.1"
-edc = "0.8.1-SNAPSHOT"
+edc = "0.8.1"
 failsafe = "3.3.2"
 h2 = "2.3.230"
 httpMockServer = "5.15.0"
```

## デバッガをアタッチして動作を確認

ひとまずContract Negotiation。

どうやらProvider側では、Consumerからリクエストが届いたときに、
`org.eclipse.edc.protocol.dsp.negotiation.http.api.controller.DspNegotiationApiController#initialContractRequest`が呼ばれる様子。

Provider側でContractNegotiationのログが出るのは２箇所。

`org.eclipse.edc.connector.controlplane.services.contractnegotiation.ContractNegotiationProtocolServiceImpl#update`
ここには、PROVIDER型のContractNegotiationが渡されてくる。


もうひとつは
`org.eclipse.edc.statemachine.AbstractStateEntityManager#update`

```java
    protected void update(E entity) {
        store.save(entity);
        monitor.debug(() -> "[%s] %s %s is now in state %s"
                .formatted(this.getClass().getSimpleName(), entity.getClass().getSimpleName(),
                        entity.getId(), entity.stateAsString()));
    }

```

`org.eclipse.edc.connector.controlplane.contract.negotiation.ProviderContractNegotiationManagerImpl` が用いいられる。

型階層は以下の通り。

```
core/common/lib/state-machine-lib/src/main/java/org/eclipse/edc/statemachine/AbstractStateEntityManager.java
core/control-plane/control-plane-contract/src/main/java/org/eclipse/edc/connector/controlplane/contract/negotiation/AbstractContractNegotiationManager.java
core/control-plane/control-plane-contract/src/main/java/org/eclipse/edc/connector/controlplane/contract/negotiation/ProviderContractNegotiationManagerImpl.java
```

`org.eclipse.edc.connector.controlplane.contract.negotiation.ProviderContractNegotiationManagerImpl`内のプロセッサの定義で、リクエストなどが届いたときの動作を定義。

org.eclipse.edc.connector.controlplane.contract.negotiation.ProviderContractNegotiationManagerImpl#configureStateMachineManager

```java
    protected StateMachineManager.Builder configureStateMachineManager(StateMachineManager.Builder builder) {
        return builder
                .processor(processNegotiationsInState(OFFERING, this::processOffering))
                .processor(processNegotiationsInState(REQUESTED, this::processRequested))
                .processor(processNegotiationsInState(ACCEPTED, this::processAccepted))
                .processor(processNegotiationsInState(AGREEING, this::processAgreeing))
                .processor(processNegotiationsInState(VERIFIED, this::processVerified))
                .processor(processNegotiationsInState(FINALIZING, this::processFinalizing))
                .processor(processNegotiationsInState(TERMINATING, this::processTerminating));
    }

```

ここで管理されるステータスはいかに定義されている。

org.eclipse.edc.connector.controlplane.contract.spi.types.negotiation.ContractNegotiationStates

```java
public enum ContractNegotiationStates {

    INITIAL(50),
    REQUESTING(100),
    REQUESTED(200),
    OFFERING(300),
    OFFERED(400),
    ACCEPTING(700),
    ACCEPTED(800),
    AGREEING(825),
    AGREED(850),
    VERIFYING(1050),
    VERIFIED(1100),
    FINALIZING(1150),
    FINALIZED(1200),
    TERMINATING(1300),
    TERMINATED(1400);

(snip)
```

例えば、とあるケースではREQUESTED(200)の次はAGREEING(825)に変わった。

`org.eclipse.edc.connector.controlplane.contract.negotiation.ProviderContractNegotiationManagerImpl#processAgreeing` がProvider側が合意をするためのメソッド。

以下の処理を行うとAgreement情報が生成される。

org/eclipse/edc/connector/controlplane/contract/negotiation/ProviderContractNegotiationManagerImpl.java:121


```java
        var agreement = Optional.ofNullable(negotiation.getContractAgreement())
                .orElseGet(() -> {
                    var lastOffer = negotiation.getLastContractOffer();

                    return ContractAgreement.Builder.newInstance()
                            .contractSigningDate(clock.instant().getEpochSecond())
                            .providerId(participantId)
                            .consumerId(negotiation.getCounterPartyId())
                            .policy(lastOffer.getPolicy().toBuilder().type(PolicyType.CONTRACT).build())
                            .assetId(lastOffer.getAssetId())
                            .build();
                });

```

以下のような感じ。

```
agreement = {ContractAgreement@7424} 
 id = "b092de56-c860-4972-8e09-e00e77ce97c4"
 providerId = "provider"
 consumerId = "consumer"
 contractSigningDate = 1728916940
 assetId = "assetId"
 policy = {Policy@7429} 
  permissions = {ArrayList@7431}  size = 0
  prohibitions = {ArrayList@7432}  size = 0
  obligations = {ArrayList@7433}  size = 0
  profiles = {ArrayList@7434}  size = 0
  extensibleProperties = {HashMap@7435}  size = 0
  inheritsFrom = null
  assigner = null
  assignee = null
  target = "assetId"
  type = {PolicyType@7436} "CONTRACT"
```

dispatchメソッド。

org/eclipse/edc/connector/controlplane/contract/negotiation/ProviderContractNegotiationManagerImpl.java:136

```java
        return dispatch(messageBuilder, negotiation, Object.class)
                .onSuccess((n, result) -> transitionToAgreed(n, agreement))
                .onFailure((n, throwable) -> transitionToAgreeing(n))
                .onFatalError((n, failure) -> transitionToTerminated(n, failure.getFailureDetail()))
                .onRetryExhausted((n, throwable) -> transitionToTerminating(n, format("Failed to send agreement to consumer: %s", throwable.getMessage())))
                .execute("[Provider] send agreement");
```

上記の通り、成功か失敗か（どのような失敗か）によってステート変更が変わる。

ここに渡ってくるnegotiationは以下のような感じ。

```
negotiation = {ContractNegotiation@7419} 
 callbackAddresses = {ArrayList@7440}  size = 0
 correlationId = "028d3abb-5086-4324-be77-087095f382c0"
 counterPartyId = "consumer"
 counterPartyAddress = "http://localhost:29194/protocol"
 protocol = "dataspace-protocol-http"
 type = {ContractNegotiation$Type@7444} "PROVIDER"
 contractAgreement = null
 contractOffers = {ArrayList@7445}  size = 1
 protocolMessages = {ProtocolMessages@7446} 
 state = 825
 stateCount = 1
 stateTimestamp = 1728916898826
 traceContext = {HashMap@7447}  size = 0
 errorDetail = null
 pending = false
 updatedAt = 1728916898826
 id = "af2c8a47-022f-450c-87e2-c425de871ab1"
 clock = {Clock$SystemClock@7422} "SystemClock[Z]"
 createdAt = 1728916898526
```

`org.eclipse.edc.connector.controlplane.contract.negotiation.AbstractContractNegotiationManager#dispatch`

メッセージビルドの様子。

org/eclipse/edc/connector/controlplane/contract/negotiation/AbstractContractNegotiationManager.java:93

```java
        messageBuilder.counterPartyAddress(negotiation.getCounterPartyAddress())
                .counterPartyId(negotiation.getCounterPartyId())
                .protocol(negotiation.getProtocol())
                .processId(Optional.ofNullable(negotiation.getCorrelationId()).orElse(negotiation.getId()));

        if (type() == ContractNegotiation.Type.CONSUMER) {
            messageBuilder.consumerPid(negotiation.getId()).providerPid(negotiation.getCorrelationId());
        } else {
            messageBuilder.providerPid(negotiation.getId()).consumerPid(negotiation.getCorrelationId());
        }

        if (negotiation.lastSentProtocolMessage() != null) {
            messageBuilder.id(negotiation.lastSentProtocolMessage());
        }

        var message = messageBuilder.build();

```

これによりビルドされるメッセージは以下のようなもの。

```
message = {ContractAgreementMessage@7463} 
 contractAgreement = {ContractAgreement@7424} 
 id = "c8a7b6dc-7e44-4bcd-9645-a12d5f8690b6"
 processId = "028d3abb-5086-4324-be77-087095f382c0"
 consumerPid = "028d3abb-5086-4324-be77-087095f382c0"
 providerPid = "af2c8a47-022f-450c-87e2-c425de871ab1"
 protocol = "dataspace-protocol-http"
 counterPartyAddress = "http://localhost:29194/protocol"
 counterPartyId = "consumer"
```

org/eclipse/edc/connector/controlplane/contract/negotiation/AbstractContractNegotiationManager.java:112


```java
        return entityRetryProcessFactory.doAsyncStatusResultProcess(negotiation, () -> dispatcherRegistry.dispatch(responseType, message));
```

上記の通り、`org.eclipse.edc.spi.message.RemoteMessageDispatcherRegistry` を使ってメッセージを送信。
実装は `org.eclipse.edc.connector.core.message.RemoteMessageDispatcherRegistryImpl` である。

org/eclipse/edc/connector/core/message/RemoteMessageDispatcherRegistryImpl.java:41


```java
    public <T> CompletableFuture<StatusResult<T>> dispatch(Class<T> responseType, RemoteMessage message) {
        Objects.requireNonNull(message, "Message was null");
        var protocol = message.getProtocol();
        var dispatcher = dispatchers.get(protocol);
        if (dispatcher == null) {
            return failedFuture(new EdcException("No provider dispatcher registered for protocol: " + protocol));
        }
        return dispatcher.dispatch(responseType, message);
    }
```

`protocol`には`dataspace-protocol-http`が入る。

`dispatcher`には以下のようなものが入る。

```
dispatcher = {DspHttpRemoteMessageDispatcherImpl@7489} 
 handlers = {HashMap@7491}  size = 13
 policyScopes = {HashMap@7492}  size = 12
 httpClient = {EdcHttpClientImpl@7493} 
 identityService = {MockIdentityService@7494} 
 policyEngine = {PolicyEngineImpl@7495} 
 tokenDecorator = {DspHttpCoreExtension$lambda@7496} 
 audienceResolver = {IamMockExtension$lambda@7497} 
```

## Policyの判定

Policy定義の際に呼び出されるやつ。

org/eclipse/edc/connector/controlplane/api/management/policy/v3/PolicyDefinitionApiV3Controller.java:57

```java
    @POST
    @Override
    public JsonObject createPolicyDefinitionV3(JsonObject request) {
        return createPolicyDefinition(request);
    }
```

コネクタに登録した際に、ログに残るやつ

org/eclipse/edc/connector/controlplane/api/management/policy/BasePolicyDefinitionApiController.java:87

```java
        var createdDefinition = service.create(definition)
                .onSuccess(d -> monitor.debug(format("Policy Definition created %s", d.getId())))
                .orElseThrow(exceptionMapper(PolicyDefinition.class, definition.getId()));
```

コントラクトのバリデーションサービスは以下。

`org.eclipse.edc.connector.controlplane.contract.validation.ContractValidationServiceImpl`

この中で`org.eclipse.edc.connector.controlplane.contract.validation.ContractValidationServiceImpl#evaluatePolicy`が呼ばれる。

org/eclipse/edc/connector/controlplane/contract/validation/ContractValidationServiceImpl.java:154

```java
    private Result<Policy> evaluatePolicy(Policy policy, String scope, ParticipantAgent agent, ContractOfferId offerId) {
        var policyContext = PolicyContextImpl.Builder.newInstance().additional(ParticipantAgent.class, agent).build();
        var policyResult = policyEngine.evaluate(scope, policy, policyContext);
        if (policyResult.failed()) {
            return failure(format("Policy in scope %s not fulfilled for offer %s, policy evaluation %s", scope, offerId.toString(), policyResult.getFailureDetail()));
        }
        return Result.success(policy);
    }
```

上記の`policyEngine`には以下が入っている。

```
policyEngine = {PolicyEngineImpl@7419} 
 constraintFunctions = {TreeMap@7462}  size = 1
 dynamicConstraintFunctions = {ArrayList@7503}  size = 0
 ruleFunctions = {TreeMap@7454}  size = 0
 preValidators = {HashMap@7423}  size = 0
 postValidators = {HashMap@7517}  size = 0
 scopeFilter = {ScopeFilter@7509} 
```


ポリシー評価 org.eclipse.edc.policy.evaluator.PolicyEvaluator

デフォルトのポリシーエンジン org.eclipse.edc.policy.engine.PolicyEngineImpl

元になったインターフェース org.eclipse.edc.policy.engine.spi.PolicyEngine

コントラクトネゴシエーションが走ると、Providerで以下が走る。


org.eclipse.edc.policy.engine.PolicyEngineImpl#evaluate
org/eclipse/edc/policy/engine/PolicyEngineImpl.java:69

```java
    public Result<Void> evaluate(String scope, Policy policy, PolicyContext context) {
        var delimitedScope = scope + ".";

        var scopedPreValidators = preValidators.entrySet().stream().filter(entry -> scopeFilter(entry.getKey(), delimitedScope)).flatMap(l -> l.getValue().stream()).toList();

(snip)
```

評価はPolicyEvaluatorが行う。

org/eclipse/edc/policy/engine/PolicyEngineImpl.java:79


```java
        var evalBuilder = PolicyEvaluator.Builder.newInstance();

```

org/eclipse/edc/policy/engine/PolicyEngineImpl.java:115

```java
        var result = evaluator.evaluate(filteredPolicy);
```

`filteredPolicy`には以下のようなものが入る。

```
filteredPolicy = {Policy@7361} 
 permissions = {ArrayList@7364}  size = 0
 prohibitions = {ArrayList@7365}  size = 0
 obligations = {ArrayList@7366}  size = 0
 profiles = {ArrayList@7367}  size = 0
 extensibleProperties = {HashMap@7368}  size = 0
 inheritsFrom = null
 assigner = null
 assignee = null
 target = null
 type = {PolicyType@7369} "SET"
```

org/eclipse/edc/policy/evaluator/PolicyEvaluator.java:66

```java

    public PolicyEvaluationResult evaluate(Policy policy) {
        return policy.accept(this) ? new PolicyEvaluationResult() : new PolicyEvaluationResult(ruleProblems);
    }
```

`org.eclipse.edc.policy.evaluator.PolicyEvaluator#visitPolicy`が呼ばれる。

org/eclipse/edc/policy/evaluator/PolicyEvaluator.java:71

```java
    public Boolean visitPolicy(Policy policy) {
        policy.getPermissions().forEach(permission -> permission.accept(this));
        policy.getProhibitions().forEach(prohibition -> prohibition.accept(this));
        policy.getObligations().forEach(duty -> duty.accept(this));
        return ruleProblems.isEmpty();
    }
```

上記の通り、もし`policy`が空だと何も生じず、`ruleProblems`が空なのでTrueが返る。

## アセットセレクタ

`org.eclipse.edc.connector.controlplane.contract.validation.ContractValidationServiceImpl#validateInitialOffer(org.eclipse.edc.connector.controlplane.contract.spi.validation.ValidatableConsumerOffer, org.eclipse.edc.spi.agent.ParticipantAgent)` が用いられる。

org/eclipse/edc/connector/controlplane/contract/validation/ContractValidationServiceImpl.java:144

```java
        var testCriteria = new ArrayList<>(consumerOffer.getContractDefinition().getAssetsSelector());
        testCriteria.add(new Criterion(Asset.PROPERTY_ID, "=", consumerOffer.getOfferId().assetIdPart()));
        if (assetIndex.countAssets(testCriteria) <= 0) {
            return failure("Asset ID from the ContractOffer is not included in the ContractDefinition");
        }
```

AssetIndexの型階層は以下の通り。

```
AssetIndex (org.eclipse.edc.connector.controlplane.asset.spi.index)
  InMemoryAssetIndex (org.eclipse.edc.connector.controlplane.defaults.storage.assetindex)
  SqlAssetIndex (org.eclipse.edc.connector.controlplane.store.sql.assetindex)
```

このうち、手元の環境で呼び出されたのはInMemoryAssetIndex。

org/eclipse/edc/connector/controlplane/defaults/storage/assetindex/InMemoryAssetIndex.java:112

```java
    public long countAssets(List<Criterion> criteria) {
        return filterBy(criteria).count();
    }
```

org.eclipse.edc.connector.controlplane.defaults.storage.assetindex.InMemoryAssetIndex#filterBy

```java
    private Stream<Asset> filterBy(List<Criterion> criteria) {
        var predicate = criteria.stream()
                .map(criterionOperatorRegistry::toPredicate)
                .reduce(x -> true, Predicate::and);

        return cache.values().stream()
                .filter(predicate);
    }
```

クライテリアの評価用のPredicate生成は`org.eclipse.edc.spi.query.CriterionOperatorRegistry`。実装は`org.eclipse.edc.query.CriterionOperatorRegistryImpl`。

org.eclipse.edc.query.CriterionOperatorRegistryImpl#toPredicate

```
    @Override
    public <T> Predicate<T> toPredicate(Criterion criterion) {
        var predicate = operatorPredicates.get(criterion.getOperator().toLowerCase());
        if (predicate == null) {
            throw new IllegalArgumentException(format("Operator [%s] is not supported.", criterion.getOperator()));
        }

        return t -> {

            var operandLeft = (String) criterion.getOperandLeft();

            var property = propertyLookups.stream()
                    .map(it -> it.getProperty(operandLeft, t))
                    .filter(Objects::nonNull)
                    .findFirst()
                    .orElse(null);

            if (property == null) {
                return false;
            }

            return predicate.test(property, criterion.getOperandRight());
        };

    }
```

# 参考

* [EDC/Samples]

[EDC/Samples]: https://github.com/eclipse-edc/Samples




<!-- vim: set et tw=0 ts=2 sw=2: -->
