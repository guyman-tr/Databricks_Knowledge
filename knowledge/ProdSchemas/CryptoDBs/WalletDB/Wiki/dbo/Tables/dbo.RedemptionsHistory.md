# dbo.RedemptionsHistory

> SCD Type 2 history table tracking every state change of crypto redemption requests - from initial persistence through execution to success or failure.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, no PK constraint) |
| **Partition** | No |
| **Indexes** | 1 active (ix_RedemptionsHistory CLUSTERED on EndDate, BeginDate) |

---

## 1. Business Meaning

This table is the temporal history of all crypto redemption requests in the wallet system. A "redemption" is the process of converting a customer's crypto position into actual cryptocurrency and sending it to a blockchain address - essentially the "sell crypto and withdraw to wallet" flow. Each redemption request generates multiple rows as it progresses through status changes (Persisted -> Retrieved -> SentToExecuter -> SuccessReported/FailureReported), with each status transition creating a new SCD Type 2 version.

Without this table, the system would lose the full audit trail of redemption state transitions. The main Wallet schema tables hold only the current state; this dbo history table preserves every intermediate state with precise timestamps, enabling reconciliation, debugging of stuck redemptions, and compliance reporting.

Data originates from the Wallet schema's redemption processing pipeline. The table follows the same SCD Type 2 temporal pattern as dbo.Wallets and dbo.TransactionsHistory (BeginDate/EndDate, PAGE compression, clustered index on EndDate/BeginDate). With 4.3 million rows, it captures the full history of all redemptions since the wallet system's inception in April 2018.

---

## 2. Business Logic

### 2.1 Redemption Lifecycle (Status Progression)

**What**: Each redemption follows a defined status progression tracked as SCD Type 2 temporal versions.

**Columns/Parameters Involved**: `Id`, `RedemptionStatus`, `BeginDate`, `EndDate`

**Rules**:
- Each status change creates a new row with the same Id but updated RedemptionStatus
- The previous row's EndDate is set to the new row's BeginDate (closing the old version)
- The latest version has EndDate matching the next transition (or far-future for current state)

**Diagram**:
```
RedemptionStatus lifecycle:
  0 (Persisted) --> 1 (Retrieved) --> 2 (SentToExecuter) --> 3 (SuccessReported)
                                                         \-> 4 (FailureReported)

Distribution: 0=1.1M, 1=31K, 2=1.1M, 3=2.0M, 4=2K
Most redemptions succeed (3=SuccessReported dominates).
Status 1 (Retrieved) is transient - very few rows remain in this state.
```

### 2.2 Fee Structure

**What**: Redemptions involve multiple fee components tracked separately.

**Columns/Parameters Involved**: `eToroFeeAmount`, `InitialFeeAmount`, `EstimatedBlockchainFee`

**Rules**:
- `InitialFeeAmount`: Fee calculated at redemption initiation
- `eToroFeeAmount`: eToro platform fee actually charged
- `EstimatedBlockchainFee`: Estimated on-chain gas/network fee (may differ from actual)
- Net amount sent = RequestedAmount - eToroFeeAmount - actual blockchain fee

---

## 3. Data Overview

| Id | RequestingGcid | CryptoId | RequestedAmount | RedemptionStatus | eToroFeeAmount | Meaning |
|---|---|---|---|---|---|---|
| 1 | 9694133 | 1 (BTC) | 0.022134 | 0 (Persisted) | 0.001 | Initial redemption request for ~0.022 BTC, just persisted - awaiting pickup by the execution engine |
| 1 | 9694133 | 1 (BTC) | 0.022134 | 1 (Retrieved) | 0.001 | Same redemption retrieved by execution service - being prepared for blockchain submission |
| 2 | 9694133 | 1 (BTC) | 0.022113 | 0 (Persisted) | 0.001 | Another BTC redemption by the same customer, slightly different amount |
| 2 | 9694133 | 1 (BTC) | 0.022113 | 1 (Retrieved) | 0.001 | Second redemption progressed to Retrieved state |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Redemption request identifier. Groups all temporal versions of the same redemption. Multiple rows share the same Id with different RedemptionStatus values and BeginDate/EndDate ranges. |
| 2 | OriginalRequestGuid | uniqueidentifier | NO | - | CODE-BACKED | Unique GUID for the original redemption request. Used for end-to-end correlation across the wallet system and external services. |
| 3 | SendRequestCorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Correlation ID linking this redemption to the outbound send transaction. NULL until the redemption progresses to the send phase. Bridges the redemption to the corresponding Wallet.SentTransactions record. |
| 4 | PositionId | bigint | YES | - | CODE-BACKED | Trading position ID that triggered this redemption. Links the crypto redemption back to the trading platform's position (the crypto holding being redeemed). NULL for non-position-based redemptions. |
| 5 | RequestingGcid | bigint | NO | - | CODE-BACKED | Global Customer ID of the customer requesting the redemption. Identifies who initiated the withdrawal of crypto from their wallet. |
| 6 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency being redeemed. Maps to Wallet.CryptoTypes: 1=BTC, 2=ETH, 3=BCH, 4=XRP, etc. |
| 7 | RequestedAmount | decimal(36,18) | NO | - | CODE-BACKED | Amount of cryptocurrency requested for redemption, in native crypto units. This is the gross amount before fees. |
| 8 | eToroFeeAmount | decimal(36,18) | NO | - | CODE-BACKED | eToro platform fee charged for this redemption, in native crypto units. Deducted from the RequestedAmount before blockchain submission. |
| 9 | RedemptionStatus | tinyint | NO | - | VERIFIED | Redemption processing status: 0=Persisted (request saved), 1=Retrieved (picked up by execution engine), 2=SentToExecuter (submitted to blockchain), 3=SuccessReported (confirmed on-chain), 4=FailureReported (execution failed). (Dictionary.RedemptionStatus) |
| 10 | BillingTransId | bigint | YES | - | CODE-BACKED | Billing system transaction ID. Links the redemption to the platform's billing/accounting system for financial reconciliation. |
| 11 | BillingRedeemId | bigint | YES | - | CODE-BACKED | Billing system redemption record ID. Separate from BillingTransId - references the specific redemption entry in the billing ledger. |
| 12 | BeginDate | datetime2(7) | NO | - | CODE-BACKED | SCD Type 2 version start timestamp. When this particular status version became effective. |
| 13 | EndDate | datetime2(7) | NO | - | CODE-BACKED | SCD Type 2 version end timestamp. When the next status transition occurred. The current/latest version's EndDate matches the subsequent version's BeginDate. |
| 14 | EstimatedBlockchainFee | decimal(36,18) | YES | - | CODE-BACKED | Estimated on-chain network/gas fee at the time of redemption request. NULL for older records. The actual fee may differ from this estimate. |
| 15 | InitialFeeAmount | decimal(36,18) | NO | - | CODE-BACKED | Fee amount calculated at the time of initial redemption request. May differ from eToroFeeAmount if fee policies changed between request and execution. |
| 16 | SourceWalletId | uniqueidentifier | YES | - | CODE-BACKED | Source wallet identifier from which the crypto is being redeemed. NULL for older records before multi-wallet support was added. Links to the specific customer wallet. |
| 17 | TransactionTypeId | tinyint | YES | - | CODE-BACKED | Transaction type classifier: 0=Redeem (standard redemption). NULL for older records predating this column. Maps to Dictionary.TransactionTypes. 70% of rows are type 0, 30% NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedemptionStatus | Dictionary.RedemptionStatus | Lookup | Redemption lifecycle status: 0=Persisted through 4=FailureReported |
| CryptoId | Wallet.CryptoTypes | Implicit | Cryptocurrency being redeemed (1=BTC, 2=ETH, etc.) |
| TransactionTypeId | Dictionary.TransactionTypes | Implicit | Transaction type (0=Redeem for standard redemptions) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the dbo schema code scan.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_RedemptionsHistory | CLUSTERED | EndDate, BeginDate | - | - | Active |

Data compression: PAGE.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get current status of a redemption
```sql
SELECT Id, OriginalRequestGuid, RequestingGcid, CryptoId,
       RequestedAmount, RedemptionStatus, BeginDate, EndDate
FROM dbo.RedemptionsHistory WITH (NOLOCK)
WHERE Id = 1
ORDER BY BeginDate
```

### 8.2 Find failed redemptions in a date range
```sql
SELECT Id, RequestingGcid, CryptoId, RequestedAmount, BeginDate
FROM dbo.RedemptionsHistory WITH (NOLOCK)
WHERE RedemptionStatus = 4
  AND BeginDate >= '2024-01-01'
ORDER BY BeginDate DESC
```

### 8.3 Redemption status distribution with readable names
```sql
SELECT rs.Name AS Status, COUNT(*) AS Cnt
FROM dbo.RedemptionsHistory rh WITH (NOLOCK)
JOIN Dictionary.RedemptionStatus rs WITH (NOLOCK) ON rs.Id = rh.RedemptionStatus
GROUP BY rs.Name
ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 7.4/10 (Elements: 9.4/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.RedemptionsHistory | Type: Table | Source: WalletDB/dbo/Tables/dbo.RedemptionsHistory.sql*
