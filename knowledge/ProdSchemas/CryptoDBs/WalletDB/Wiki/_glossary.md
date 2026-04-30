# Business Glossary - WalletDB

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-14 | Terms: 50 lookup-backed, 0 concept-based | Sources: 50 Dictionary tables, 0 object docs*

---

## Lookup-Backed Terms

## Address Ownership Proof Option {#address-ownership-proof-option}

**Definition**: Defines the level of proof required from a user to verify ownership of an external cryptocurrency address before allowing transactions. Controls compliance requirements for address whitelisting.

**Source Table**: `Dictionary.AddressOwnershipProofOption`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No ownership proof required for this address |
| 1 | Blocked | Address is blocked from use; ownership cannot be proven or is rejected |
| 2 | Declaration | User must submit a self-declaration of address ownership |
| 3 | ProofOfOwnership | User must provide cryptographic proof (e.g., signed message) of address ownership |

**Used By**:

---

## Address Ownership Proof Type {#address-ownership-proof-type}

**Definition**: Specifies the method used to prove ownership of an external cryptocurrency address. Determines the verification mechanism applied during address whitelisting.

**Source Table**: `Dictionary.AddressOwnershipProofType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Declaration | User signs a legal declaration affirming they own the address |
| 2 | Signature | User provides a cryptographic signature from the address's private key |

**Used By**:

---

## Address Resolver Provider {#address-resolver-provider}

**Definition**: Blockchain-specific service implementations that validate and resolve cryptocurrency addresses. Each crypto asset type uses a dedicated provider that understands its address format and validation rules.

**Source Table**: `Dictionary.AddressResolverProviders`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | CryptoAddressResolverBaseProvider | Base/fallback address resolver for generic crypto address validation |
| 2 | BitcoinAddressResolverProvider | Validates and resolves Bitcoin (BTC) addresses |
| 3 | BchAddressResolverProvider | Validates and resolves Bitcoin Cash (BCH) addresses including CashAddr format |
| 4 | LitecoinAddressResolverProvider | Validates and resolves Litecoin (LTC) addresses |
| 5 | EthAddressResolverProvider | Validates and resolves Ethereum (ETH) and ERC-20 token addresses |
| 6 | RippleAddressResolverProvider | Validates and resolves Ripple (XRP) addresses including destination tags |
| 7 | StellarAddressResolverProvider | Validates and resolves Stellar (XLM) addresses including memo IDs |
| 8 | EOSAddressResolverProvider | Validates and resolves EOS account names |
| 9 | EtcAddressResolverProvider | Validates and resolves Ethereum Classic (ETC) addresses |

**Used By**:

---

## Address Type Display Name {#address-type-display-name}

**Definition**: User-facing display labels for different cryptocurrency address format variants. Used to show human-readable address type identifiers in the UI.

**Source Table**: `Dictionary.AddressTypeDisplayNames`

**Values**:

| ID | Type | DisplayName | Business Meaning |
|----|------|-------------|-----------------|
| 1 | 3prefix | 3 | Original Bitcoin P2SH (Pay-to-Script-Hash) address starting with "3" |
| 2 | cashaddr | CashAddr | Bitcoin Cash new-format CashAddr address |
| 3 | Mprefix | M | Litecoin new-format M-prefix address |

**Used By**:

---

## AML Provider {#aml-provider}

**Definition**: Anti-Money Laundering screening service providers used to evaluate transaction risk. Each provider performs compliance checks on crypto addresses and transactions before allowing fund movement.

**Source Table**: `Dictionary.AmlProviders`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Chainalysis | Primary AML provider - performs blockchain analytics and risk scoring via API |
| 2 | BlackList | Internal blacklist-based screening against known bad addresses |
| 3 | Unsupported | Placeholder for crypto assets where no AML provider integration exists |
| 4 | ChainalysisCDN | Chainalysis screening via CDN-cached data for faster lookups |

**Used By**:

---

## AML Status Type {#aml-status-type}

**Definition**: Result of an AML (Anti-Money Laundering) screening check on a transaction or address. Determines whether the transaction can proceed, must be blocked, or needs investigation.

**Source Table**: `Dictionary.AmlStatusType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Pass | AML check passed - transaction is cleared to proceed |
| 1 | Rejected | AML check found risk indicators - transaction is blocked |
| 2 | Failed | AML check could not complete (provider error/timeout) - requires retry or manual review |

**Used By**:

---

## Asset Type {#asset-type}

**Definition**: Classification of cryptocurrency assets by their blockchain implementation. Determines how the system interacts with the blockchain for wallet creation, address generation, and transaction processing.

**Source Table**: `Dictionary.AssetTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Coin | Native blockchain coin (e.g., BTC, ETH, LTC) - has its own blockchain and native transaction support |
| 2 | ERC20 | Ethereum-based token following the ERC-20 standard - shares Ethereum addresses and uses token contract interactions |

**Used By**:

---

## Chainalysis Category {#chainalysis-category}

**Definition**: Risk categorization of cryptocurrency addresses as classified by Chainalysis blockchain analytics. Used in AML screening to identify the nature of counterparty addresses and assess transaction risk.

**Source Table**: `Dictionary.ChainalysisCategoryId`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | child abuse material | Address linked to CSAM - highest risk, immediate block |
| 2 | darknet market | Address associated with darknet marketplace activity |
| 3 | sanctioned entity | Address belonging to a sanctioned individual or organization |
| 4 | no kyc exchange | Exchange that does not perform KYC verification |
| 6 | stolen funds | Address holding or moving stolen cryptocurrency |
| 7 | mining pool | Legitimate mining pool address |
| 9 | other | Uncategorized or miscellaneous classification |
| 10 | ethereum contract | Smart contract address on Ethereum |
| 11 | hosted wallet | Custodial wallet service (exchange, platform) |
| 12 | ransomware | Address linked to ransomware payments |
| 13 | mixing | Cryptocurrency mixing/tumbling service to obscure transaction trails |
| 14 | ico | Initial Coin Offering related address |
| 15 | erc20 token | ERC-20 token contract address |
| 16 | gambling | Online gambling platform address |
| 17 | merchant services | Legitimate payment processor or merchant |
| 18 | scam | Address associated with known scams |
| 19 | p2p exchange | Peer-to-peer exchange platform |
| 20 | none | No specific category identified |
| 21 | exchange | Regulated cryptocurrency exchange |
| 22 | mining | Individual mining operation |
| 23 | terrorist financing | Address linked to terrorist financing activity |
| 24 | atm | Bitcoin/crypto ATM operator |
| 25 | sanctioned jurisdiction | Address in a sanctioned jurisdiction |
| 26 | lending | DeFi or CeFi lending platform |
| 27 | decentralized exchange | DEX (Uniswap, SushiSwap, etc.) |
| 28 | fraud shop | Platform selling stolen data or fraud tools |
| 29 | illicit actor-org | Known illicit organization |
| 30 | infrastructure as a service | Blockchain infrastructure provider |
| 31 | token smart contract | Token contract deployment |
| 32 | smart contract | Generic smart contract |
| 33 | protocol privacy | Privacy-focused protocol (Tornado Cash, etc.) |
| 34 | special measures | Under special regulatory measures |
| 35 | malware | Address linked to malware distribution |
| 36 | online pharmacy | Unregulated online pharmacy |
| 37 | bridge | Cross-chain bridge protocol |
| 38 | nft platform - collection | NFT marketplace or collection |
| 39 | seized funds | Funds seized by law enforcement |
| 41 | unnamed service | Unidentified crypto service |
| 42 | stolen bitcoins | Specifically stolen Bitcoin |
| 43 | stolen ether | Specifically stolen Ether |
| 999 | custom address | Custom/manually flagged address |

**Used By**:

---

## Chargeback Status {#chargeback-status}

**Definition**: Classification of chargeback events against crypto-to-fiat or payment transactions. Distinguishes between different types of fund reversal scenarios.

**Source Table**: `Dictionary.ChargebackStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | ChargeBack | Full chargeback initiated by payment provider or customer dispute |
| 2 | Refund | Voluntary refund initiated by eToro |
| 3 | RefundAsChargeback | Refund processed through the chargeback mechanism |

**Used By**:

---

## Checksum Type {#checksum-type}

**Definition**: Identifies which type of entity a checksum record is associated with. Checksums provide data integrity verification for wallet-related records.

**Source Table**: `Dictionary.ChecksumTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | WalletPool | Checksum for wallet pool records (pre-generated wallets) |
| 2 | Wallet | Checksum for customer wallet records |
| 3 | StakingAddress | Checksum for staking address records |
| 4 | EtoroExternalAddress | Checksum for eToro external address records |

**Used By**:

---

## Client Notification Type {#client-notification-type}

**Definition**: Types of notifications sent to customers about wallet activity. Triggers push notifications or in-app alerts based on transaction events.

**Source Table**: `Dictionary.ClientNotificationTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | SentTransaction | Notification when an outgoing transaction is processed |
| 2 | ReceivedTransaction | Notification when an incoming transaction is detected |
| 3 | PendingPayment | Notification about a payment awaiting processing |

**Used By**:

---

## Conversion Status {#conversion-status}

**Definition**: Lifecycle status of a crypto-to-crypto conversion operation. Tracks whether the swap between two crypto assets completed successfully.

**Source Table**: `Dictionary.ConversionStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Pending | Conversion initiated, awaiting execution |
| 2 | Failed | Conversion failed during execution |
| 3 | Completed | Conversion successfully executed, assets swapped |

**Used By**:

---

## Conversion Type {#conversion-type}

**Definition**: Determines which side of a crypto conversion has a fixed amount. Controls the conversion pricing model.

**Source Table**: `Dictionary.ConversionTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | FixedFrom | The source amount is fixed; destination amount is calculated from market rate |
| 2 | FixedTo | The destination amount is fixed; source amount is calculated from market rate |

**Used By**:

---

## Correlated Request Type {#correlated-request-type}

**Definition**: Defines the relationship type when one request is linked to another. Used to track causally-related operations.

**Source Table**: `Dictionary.CorrelatedRequestsTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Bounceback | A send-back transaction triggered by a received transaction that cannot be processed (e.g., AML failure, ineligible customer) |

**Used By**:

---

## Crypto Activity Status {#crypto-activity-status}

**Definition**: Controls the availability of a specific cryptocurrency for wallet operations. Used as a feature flag to manage crypto asset rollouts and restrictions.

**Source Table**: `Dictionary.CryptoActivityStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | NotActive | Crypto is disabled - no operations allowed |
| 1 | ComingSoon | Crypto is announced but not yet available for operations |
| 2 | Available | Crypto is fully available for all operations (send, receive, convert) |
| 3 | AvailableRedeemOnly | Crypto is in wind-down mode - only redemption (withdrawal) is allowed |

**Used By**:

---

## Crypto Coin Provider {#crypto-coin-provider}

**Definition**: Specific blockchain service provider implementations for each cryptocurrency. Maps crypto assets to their technical provider (BitGo or CUG) and provider-specific API integration.

**Source Table**: `Dictionary.CryptoCoinProviders`

**Values**:

| ID | Name | WalletProviderId | Business Meaning |
|----|------|-----------------|-----------------|
| 1 | BitGoBlockchainProviderV2 | 1 | BitGo provider for UTXO-based blockchains (BTC, LTC, BCH) |
| 2 | BitGoEthereumProviderV2 | 1 | BitGo provider for Ethereum and ERC-20 tokens |
| 3 | BitgoRippleProviderV2 | 1 | BitGo provider for XRP/Ripple |
| 4 | BitGoStellarProviderV2 | 1 | BitGo provider for Stellar (XLM) |
| 5 | BitGoEOSProviderV2 | 1 | BitGo provider for EOS |
| 6 | CUGBlockchainProvider | 2 | CUG (Crypto Unified Gateway) provider for UTXO blockchains |
| 7 | BitGoTronProviderV2 | 1 | BitGo provider for TRON (TRX) |
| 8 | BitGoEthereumClassicProviderV2 | 1 | BitGo provider for Ethereum Classic (ETC) |
| 9 | CUGAccountBasedBlockchainProvider | 2 | CUG provider for account-based blockchains (ETH-like) |

**Used By**:

---

## Customer Value Eligibility Changing Source {#customer-value-eligibility-changing-source}

**Definition**: Identifies which system or team changed a customer's eligibility status for crypto wallet operations. Provides audit trail for eligibility modifications.

**Source Table**: `Dictionary.CustomerValueEligibilityChangingSource`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Source of change is not recorded |
| 1 | BackOffice | Change made by internal back-office staff |
| 2 | Banking | Change triggered by banking/fiat compliance system |
| 3 | Crypto | Change triggered by crypto compliance system |

**Used By**:

---

## Customer Wallet Status {#customer-wallet-status}

**Definition**: Activation state of a customer's wallet. Tracks whether the wallet has completed its setup process.

**Source Table**: `Dictionary.CustomerWalletStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Pending | Wallet created but not yet fully activated (awaiting blockchain confirmation or funding) |
| 1 | Active | Wallet is fully activated and operational |

**Used By**:

---

## Eligibility Status {#eligibility-status}

**Definition**: Controls the level of access a customer has to crypto wallet operations. Used for compliance-driven restrictions on specific customers or customer segments.

**Source Table**: `Dictionary.EligibilityStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | BlockedFromAccess | Customer is completely blocked from crypto wallet access |
| 1 | ReadOnly | Customer can view wallet data but cannot perform any transactions |
| 2 | AllOperations | Customer has full access to all crypto wallet operations |
| 3 | AllOperationsForExistingUsersOnly | Full access restricted to customers who already have wallets; new onboarding blocked |

**Used By**:

---

## Error Monitoring Policy {#error-monitoring-policy}

**Definition**: Defines how transaction errors are classified and what retry/escalation behavior applies. Each policy maps to a resulting transaction status that determines the error's severity.

**Source Table**: `Dictionary.ErrorMonitoringPolicies`

**Values**:

| ID | Name | TransactionStatusId | Business Meaning |
|----|------|-------------------|-----------------|
| 1 | TemporaryHiccup | 6 (WavedError) | Transient error that auto-resolves; transaction marked as waved |
| 2 | PermanentErrorForOneDay | 5 (PermanentError) | Persistent error with 1-day monitoring window before permanent failure |
| 3 | PermanentErrorForOneWeek | 5 (PermanentError) | Persistent error with 1-week monitoring window before permanent failure |
| 4 | TentativeTimeoutError | 6 (WavedError) | Timeout that may resolve on retry; marked as waved |
| 5 | ImmaditaeFailure | 6 (WavedError) | Immediate failure with no retry (e.g., unsupported coin type) |
| 6 | HalfHourRetry | 6 (WavedError) | Error retried at 30-minute intervals |
| 7 | TwoDays | 6 (WavedError) | Error monitored for 2-day window |

**Used By**:

---

## Error Source {#error-source}

**Definition**: Identifies the system component that generated a transaction error. Used for error routing and monitoring.

**Source Table**: `Dictionary.ErrorSources`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Bitgo | Error originated from BitGo blockchain provider API |
| 2 | SQL | Error originated from database operations |
| 3 | General | Error from internal application logic or other sources |

**Used By**:

---

## eToro Legal Entity {#etoro-legal-entity}

**Definition**: The eToro corporate legal entity under which a customer's account is registered. Determines regulatory jurisdiction, compliance requirements, and feature availability.

**Source Table**: `Dictionary.EtoroLegalEntities`

**Values**:

| ID | Name | DisplayName | Business Meaning |
|----|------|-------------|-----------------|
| 1 | EtoroX | eToroX | eToro's crypto exchange entity |
| 2 | EtoroUS | eToroUS | US-regulated entity |
| 3 | EtoroGermany | eToroGermany | German-regulated entity (BaFin) |
| 4 | EtoroDA | eToroDA | Digital Assets entity |
| 5 | EtoroSEY | eToroSEY | Seychelles entity |
| 6 | EtoroEU | eToroEU | EU-regulated entity (CySEC) |
| 7 | EtoroAUS | eToroAUS | Australian-regulated entity (ASIC) |
| 8 | EtoroME | eToroME | Middle East entity |
| 9 | EtoroUK | eToroUK | UK-regulated entity (FCA) |
| 10 | EtoroNY | eToroNY | New York entity (BitLicense) |

**Used By**:

---

## External Address Type {#external-address-type}

**Definition**: Classifies the purpose of an eToro-controlled external blockchain address. These addresses are used for outbound fund movements from the platform.

**Source Table**: `Dictionary.ExternalAddressTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | OmnibusMoneyOut | Address used for omnibus (batched) outbound transfers |
| 2 | UserMoneyOut | Address used for individual user withdrawal transfers |
| 3 | CryptoToFiat | Address used for crypto-to-fiat conversion outflows |
| 4 | CryptoToPosition | Address used for crypto-to-trading-position conversion outflows |

**Used By**:

---

## Init Token Status {#init-token-status}

**Definition**: Status of a blockchain token initialization process. Tracks whether a new token/coin has been successfully initialized on the provider.

**Source Table**: `Dictionary.InitTokenStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Initiated | Token initialization request sent to provider |
| 2 | FoundExisted | Token already existed on provider - no initialization needed |
| 3 | Failed | Token initialization failed |

**Used By**:

---

## Internal Transaction Error Code {#internal-transaction-error-code}

**Definition**: Internal error codes for transaction failures that map to specific business scenarios. Used for programmatic error handling.

**Source Table**: `Dictionary.InternalTransactionErrorCodes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | InsufficientFunds | Transaction failed because the source wallet has insufficient balance |

**Used By**:

---

## Limit Action {#limit-action}

**Definition**: Defines what happens when a transaction limit is exceeded. Controls whether the system blocks the transaction or just raises an alert.

**Source Table**: `Dictionary.LimitActions`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Enforce | Transaction is blocked when limit is exceeded |
| 2 | Alert | Transaction proceeds but an alert is raised for monitoring |

**Used By**:

---

## Limit Classification {#limit-classification}

**Definition**: Severity classification of a transaction limit. Determines whether exceeding the limit is a hard block or a soft warning.

**Source Table**: `Dictionary.LimitClassifications`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Soft | Advisory limit - can be overridden or waived |
| 2 | Hard | Strict limit - cannot be exceeded under any circumstances |

**Used By**:

---

## Limit Scope {#limit-scope}

**Definition**: Time dimension of a transaction limit. Determines whether the limit applies to individual transactions or accumulated amounts over a period.

**Source Table**: `Dictionary.LimitScopes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Single | Limit applies to each individual transaction |
| 2 | Periodic | Limit applies to cumulative amount within a time period (e.g., daily, monthly) |

**Used By**:

---

## Limit Target {#limit-target}

**Definition**: Specifies whether a transaction limit applies to an individual user or globally across all users.

**Source Table**: `Dictionary.LimitTargets`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | User | Limit applies per individual customer |
| 2 | Global | Limit applies system-wide across all customers |

**Used By**:

---

## Limit Type {#limit-type}

**Definition**: Direction of a transaction limit - whether it enforces a minimum or maximum threshold.

**Source Table**: `Dictionary.LimitTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Min | Minimum amount threshold (transaction must be at least this amount) |
| 2 | Max | Maximum amount threshold (transaction cannot exceed this amount) |

**Used By**:

---

## Manual Approve Transaction Status {#manual-approve-transaction-status}

**Definition**: Workflow status for transactions requiring manual approval by operations staff. Used for high-value or flagged transactions that cannot be auto-processed.

**Source Table**: `Dictionary.ManualApproveTransactionStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Pending | Transaction awaiting reviewer action |
| 2 | Approved | Transaction approved by reviewer, ready for execution |
| 3 | Rejected | Transaction rejected by reviewer, will not proceed |
| 4 | Sent | Approved transaction has been submitted for blockchain execution |

**Used By**:

---

## Payment Status {#payment-status}

**Definition**: Lifecycle status of a fiat payment transaction linked to crypto operations. Tracks the multi-step payment flow through provider initiation, document handling, and settlement.

**Source Table**: `Dictionary.PaymentStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | PendingProvider | Payment created, waiting for payment provider to acknowledge |
| 2 | InitiateStarted | Payment initiation request sent to provider |
| 3 | DocumentCompleted | Required payment documents processed successfully |
| 4 | InitiateCompleted | Payment fully initiated with provider |
| 5 | InitiateFailed | Payment initiation failed at provider |
| 6 | TransferCompleted | Funds transfer confirmed by provider |
| 7 | PendingTransaction | Payment waiting for associated blockchain transaction |
| 8 | Failed | Payment failed permanently |
| 9 | Completed | Payment fully settled and complete |
| 10 | InternalError | Payment failed due to internal system error |
| 11 | ProviderSubmitted | Payment submitted to provider, awaiting confirmation |

**Used By**:

---

## Received Transaction Type {#received-transaction-type}

**Definition**: Classifies the purpose of an incoming blockchain transaction received into an eToro wallet. Determines how the received funds are processed and allocated.

**Source Table**: `Dictionary.ReceivedTransactionTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | MoneyIn | Customer deposit - user sent crypto from external wallet to their eToro wallet |
| 2 | Redeem | Incoming funds from a redemption address (transfer from trading position to wallet) |
| 3 | Funding | Incoming funds for wallet pool funding operations |
| 4 | ConversionFromUser | Received side of a user-initiated crypto conversion |
| 5 | ConversionFromEtoro | Received side of an eToro-initiated conversion |
| 6 | Payment | Incoming funds related to a payment operation |
| 7 | RedeemAsic | Incoming funds from ASIC-specific redemption |
| 8 | StakeAndRewardsRefund | Refund of staking principal and/or rewards |

**Used By**:

---

## Redemption Status {#redemption-status}

**Definition**: Tracks the lifecycle of a crypto redemption request - the process of converting a trading position back into actual cryptocurrency in the user's wallet.

**Source Table**: `Dictionary.RedemptionStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Persisted | Redemption request saved to database |
| 1 | Retrieved | Redemption request picked up by processing service |
| 2 | SentToExecuter | Redemption forwarded to the blockchain execution service |
| 3 | SuccessReported | Blockchain execution confirmed success |
| 4 | FailureReported | Blockchain execution reported failure |

**Used By**:

---

## Request Status {#request-status}

**Definition**: Comprehensive lifecycle status for all wallet operation requests. This is the primary state machine tracking a request from creation through blockchain execution, AML checks, and final settlement.

**Source Table**: `Dictionary.RequestStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Start | Request created and initialized |
| 1 | Done | Request completed successfully |
| 2 | Error | Request failed with permanent error |
| 3 | ExecuterEnqueued | Request queued for blockchain execution service |
| 4 | ReadByExecuter | Execution service has picked up the request |
| 5 | TransactionSentToBlockChain | Blockchain transaction broadcast to network |
| 6 | TransactionConfirmed | Blockchain transaction received network confirmations |
| 7 | TransactionVerified | Transaction verification checks passed |
| 8 | AmlEnqueued | Request queued for AML screening |
| 9 | ReadByAml | AML service has picked up the request |
| 16 | TemporaryError | Transient error - will be retried |
| 25 | WaitingForManualApproval | Request flagged for manual review by operations |
| 26 | ManuallyApproved | Operations staff approved the request |
| 27 | ManuallyRejected | Operations staff rejected the request |
| 28 | StakingEnqueued | Request queued for staking service |
| 29 | ReadByStakingService | Staking service has picked up the request |
| 30 | ConversionWorkerEnqueued | Request queued for conversion processing |
| 31 | ReadByConversionWorker | Conversion worker has picked up the request |
| 32 | FiatAccountFunded | Fiat side of conversion has been funded |
| 33 | MarketMakerUpdated | Market maker position updated for conversion |
| 34 | OperationRejected | Operation rejected by business rules or compliance |
| 35 | SendTransactionOrchestratorEnqueued | Queued for the send transaction orchestrator (saga-based) |
| 36 | BounceBackPending | Bounceback identified, awaiting initiation |
| 37 | BounceBackInitiated | Bounceback send-back transaction started |
| 38 | BounceBackHandled | Bounceback fully processed |
| 39 | TravelRuleFlowInitiated | Travel Rule compliance flow started |
| 40 | TravelRuleCompleted | Travel Rule compliance requirements satisfied |
| 41 | AmlFailed | AML screening failed - transaction blocked |
| 42 | TravelRuleMessageCreated | Travel Rule message sent to counterparty VASP |

**Key Characteristics**:
- Statuses 0-9 represent the core happy path: Start -> Enqueue -> Execute -> Confirm -> Done
- Statuses 16, 25-27 represent exception/manual intervention flows
- Statuses 28-33 are service-specific processing states
- Statuses 34-42 represent compliance and edge-case flows (bouncebacks, travel rule)
- Gap between 9 and 16 suggests historical statuses were removed

**Used By**:

---

## Request Type {#request-type}

**Definition**: Classification of wallet operation requests by their business purpose. Each request type triggers a different processing pipeline.

**Source Table**: `Dictionary.RequestTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | CreateWallet | Request to create a new blockchain wallet for a customer |
| 1 | SendTransaction | Request to send crypto from eToro to an external address |
| 2 | InitiatePayment | Request to initiate a fiat payment linked to crypto |
| 3 | Redeem | Request to convert a trading position into actual crypto in the user's wallet |
| 4 | Conversion | Request to swap one crypto asset for another |
| 5 | Funding | Request to fund a wallet pool address from the omnibus |
| 6 | Staking | Request to stake crypto for rewards |
| 7 | ConversionToFiat | Request to convert crypto holdings to fiat currency |
| 8 | ReceiveTransaction | Request triggered by an incoming blockchain transaction |
| 9 | ConversionToPosition | Request to convert crypto into a trading position |

**Used By**:

---

## Saga Status Type {#saga-status-type}

**Definition**: Status of a distributed saga (multi-step transactional workflow). The saga pattern coordinates complex operations that span multiple services with compensating rollback actions.

**Source Table**: `Dictionary.SagaStatusTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Start | Saga initiated, executing forward steps |
| 2 | Rollback | Saga failed, executing compensating (rollback) steps |
| 3 | Completed | All saga steps completed successfully |
| 4 | Failed | Saga failed and rollback completed (or rollback also failed) |
| 5 | ForceStop | Saga was forcibly terminated by an operator or automated circuit breaker before reaching a natural terminal state |

**Used By**: Saga.SagaStatusTypes, Saga.SagaRuns, Saga.SagaRunStatuses

---

## Staking Status {#staking-status}

**Definition**: Lifecycle status of a crypto staking operation where assets are locked to earn rewards.

**Source Table**: `Dictionary.StakingStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Pending | Staking operation initiated, awaiting blockchain confirmation |
| 2 | Failed | Staking operation failed |
| 3 | Completed | Assets successfully staked and earning rewards |

**Used By**: Staking.StakingStatuses (FK), Staking.StakingData (JOIN), Wallet.GetStakingTransactionList (JOIN), Wallet.GetStakingTransactionListV2 (JOIN)

---

## Step Status Type {#step-status-type}

**Definition**: Status of an individual step within a saga workflow. Each saga contains multiple steps that execute sequentially.

**Source Table**: `Dictionary.StepStatusTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Start | Step execution began |
| 2 | Failed | Step execution failed |
| 3 | Retry | Step is being retried after a transient failure |
| 4 | Done | Step completed successfully |
| 5 | Schedule | Step is scheduled for deferred execution, used for polling steps that check external service results at timed intervals |

**Used By**: Saga.StepStatusTypes, Saga.SagaSteps, Saga.SagaStepStatuses

---

## Transaction Output Source ID Type {#transaction-output-source-id-type}

**Definition**: Identifies the business entity type that a sent transaction output references. Used to link blockchain transaction outputs back to business objects.

**Source Table**: `Dictionary.TransactionOutputSourceIdType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | PositionId | Output is linked to a trading position (redemption scenario) |

**Used By**:

---

## Transaction Status {#transaction-status}

**Definition**: Blockchain transaction confirmation status. Tracks the lifecycle of a sent transaction from submission through network confirmation.

**Source Table**: `Dictionary.TransactionStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Pending | Transaction submitted to blockchain, awaiting confirmation |
| 1 | Confirmed | Transaction received sufficient network confirmations |
| 2 | Verified | Transaction verified correct by internal checks |
| 3 | Error | Transaction encountered an error |
| 4 | Timeout | Transaction timed out waiting for confirmation |
| 5 | PermanentError | Transaction permanently failed - no further retries |
| 6 | WavedError | Transaction error was waived/dismissed (auto-resolved or manually cleared) |

**Used By**:

---

## Transaction Type {#transaction-type}

**Definition**: Classification of sent blockchain transactions by their business purpose. Determines the execution pipeline, fee structure, and monitoring rules.

**Source Table**: `Dictionary.TransactionTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Redeem | Transfer from omnibus to customer wallet (position-to-crypto conversion) |
| 1 | CustomerMoneyOut | Customer-initiated withdrawal to external address |
| 2 | AmlMoneyBack | Return funds to sender after AML rejection |
| 4 | Funding | Transfer from omnibus to pool wallet for pre-funding |
| 5 | ConversionMoneyIn | Incoming leg of a crypto-to-crypto conversion |
| 6 | ConversionMoneyOut | Outgoing leg of a crypto-to-crypto conversion |
| 7 | Payment | Fiat payment-linked crypto transfer |
| 8 | RedeemAsic | ASIC-specific redemption transfer |
| 9 | Staking | Transfer to staking contract/address |
| 10 | BlockChainActivation | On-chain wallet activation transaction (e.g., EOS account creation) |
| 11 | OmnibusMoneyOut | Batched outbound transfer from omnibus wallet |
| 12 | ConversionToFiat | Crypto sold and converted to fiat currency |
| 13 | ManualUserMoneyOut | Manual user withdrawal processed by operations |
| 14 | StakeAndRewardsRefund | Refund of staked assets and accumulated rewards |
| 15 | CustomerMoneyBack | Return of customer funds (non-AML related) |

**Key Characteristics**:
- ID 3 is missing (possibly deprecated)
- Types 0, 1, 2 are the original core transaction types
- Types 4-15 were added as new business flows were introduced

**Used By**:

---

## Travel Rule Address Type {#travel-rule-address-type}

**Definition**: Classifies counterparty wallet addresses under Travel Rule compliance. Determines the level of beneficiary information required.

**Source Table**: `Dictionary.TravelRuleAddressType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Private | Self-hosted/non-custodial wallet - owner controls private keys |
| 2 | Hosted | Custodial wallet hosted by a VASP (Virtual Asset Service Provider) |

**Used By**:

---

## Travel Rule Compliance Option {#travel-rule-compliance-option}

**Definition**: Available compliance actions for transactions subject to Travel Rule requirements. Controls how the system handles beneficiary information gathering.

**Source Table**: `Dictionary.TravelRuleComplianceOptions`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | None | No Travel Rule compliance action required |
| 1 | Blocked | Transaction blocked until compliance requirements are met |
| 2 | Declaration | User must provide a declaration about the beneficiary |
| 3 | ProofOfOwnership | User must prove ownership of the destination address |

**Used By**:

---

## Travel Rule Status {#travel-rule-status}

**Definition**: Workflow status for Travel Rule compliance processing. Tracks the state of required beneficiary information gathering and approval for cross-VASP transfers.

**Source Table**: `Dictionary.TravelRuleStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | PendingManualApproval | Travel Rule information submitted, awaiting compliance team review |
| 1 | Approved | Compliance team approved - transaction can proceed |
| 2 | Canceled | Travel Rule flow canceled (e.g., user withdrew the transaction) |
| 3 | PendingMissingInformation | Review found missing required information - waiting for user to provide |
| 4 | MissingInformationAdded | User provided the missing information - ready for re-review |
| 5 | MustCancel | Transaction must be canceled due to compliance failure |

**Used By**:

---

## Validate Token Status {#validate-token-status}

**Definition**: Result of token validation - checking whether a blockchain token/coin is properly configured and operational.

**Source Table**: `Dictionary.ValidateTokenStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Verified | Token validated successfully and is operational |
| 2 | Failed | Token validation failed - not usable |

**Used By**:

---

## Wallet Pool Status {#wallet-pool-status}

**Definition**: Lifecycle status of pre-generated wallets in the pool. Wallets are created in advance and move through verification and funding stages before being assigned to customers.

**Source Table**: `Dictionary.WalletPoolStatuses`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Pending | Wallet created on blockchain, awaiting verification |
| 2 | Verified | Wallet verified on blockchain - ready for funding or assignment |
| 3 | Failed | Wallet creation or verification failed |
| 4 | FundingInitiated | Funding transaction to wallet has been initiated |
| 5 | FundingSent | Funding transaction broadcast to blockchain |
| 6 | FundingVerified | Funding confirmed - wallet has balance and is ready for assignment |
| 7 | FundingFailed | Funding transaction failed |
| 10 | Timeout | Wallet operation timed out |
| 11 | VerifiedForAssign | Wallet verified and specifically marked as ready for customer assignment |

**Key Characteristics**:
- Statuses 1-3 cover initial wallet creation
- Statuses 4-7 cover the funding lifecycle
- Gap between 7 and 10 suggests deprecated statuses
- Status 11 is a specialized verified state for the assignment workflow

**Used By**:

---

## Wallet Provider {#wallet-provider}

**Definition**: Top-level cryptocurrency custody and wallet infrastructure provider. All blockchain operations route through one of these providers.

**Source Table**: `Dictionary.WalletProvider`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Bitgo | BitGo - institutional-grade multi-sig custody provider (primary) |
| 2 | CUG | Crypto Unified Gateway - eToro's internal blockchain gateway |
| 3 | None | No provider required (used for internal/virtual wallets) |

**Used By**:

---

## Wallet Type {#wallet-type}

**Definition**: Classifies wallets by their operational purpose. Each type serves a specific role in the crypto fund flow architecture.

**Source Table**: `Dictionary.WalletTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Redeem | Wallet used for receiving redemption transfers (position-to-crypto) |
| 2 | Conversion | Wallet used for holding crypto during conversion operations |
| 3 | Funding | Wallet used for pre-funding operations (omnibus to pool) |
| 4 | Payment | Wallet used for fiat payment-linked operations |
| 5 | Customer | Customer-facing wallet for holding, sending, and receiving crypto |
| 6 | C2F | Crypto-to-Fiat conversion wallet |
| 7 | StakingRefund | Wallet for receiving staking principal and reward refunds |

**Used By**:

---

## Business Concepts

*No concept-based terms yet. Will be populated as object documentation progresses.*
