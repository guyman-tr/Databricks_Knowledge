# Wallet.Redemptions

> Records every redemption operation where a customer converts a crypto trading position into actual cryptocurrency deposited into their wallet, tracking the position, amounts, fees, and processing status.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 5 active NC (1 unique) + 1 clustered PK |
| **Temporal** | Yes - SYSTEM_VERSIONING with history table dbo.RedemptionsHistory |

---

## 1. Business Meaning

This table records every crypto redemption - the process of converting a trading position (CFD or real) into actual cryptocurrency in the customer's wallet. This is the bridge between eToro's trading platform (where users hold positions) and the wallet platform (where users hold real crypto). With ~1.13M rows, redemptions are a core business flow.

Each redemption links a trading position (PositionId) to a requested crypto amount, minus eToro's fee. The process involves: (1) closing or adjusting the trading position, (2) calculating the equivalent crypto amount, (3) executing a blockchain transfer from the omnibus to the customer's wallet. This is tracked through the `RedemptionStatus` state machine.

Rows are created by `Wallet.AddNewRedemptionRequest`. The temporal versioning tracks status changes over time. The `HandlePendingRedemptions` background process picks up persisted redemptions and sends them to the execution service.

---

## 2. Business Logic

### 2.1 Redemption Lifecycle

**What**: Redemptions progress through a defined lifecycle from persistence to blockchain execution.

**Columns/Parameters Involved**: `RedemptionStatus`, `SendRequestCorrelationId`

**Rules**:
- 0=Persisted: Request saved, awaiting pickup by HandlePendingRedemptions process
- 1=Retrieved: Processing service has picked up the request
- 2=SentToExecuter: Forwarded to blockchain execution service
- 3=SuccessReported: Blockchain transfer confirmed (most recent entries show this)
- 4=FailureReported: Blockchain transfer failed
- See [Redemption Status](../../_glossary.md#redemption-status). FK to Dictionary.RedemptionStatus.
- SendRequestCorrelationId links to the send transaction request once execution begins

### 2.2 Fee Calculation

**What**: Each redemption deducts an eToro fee and optional blockchain fee from the requested amount.

**Columns/Parameters Involved**: `RequestedAmount`, `eToroFeeAmount`, `InitialFeeAmount`, `EstimatedBlockchainFee`

**Rules**:
- RequestedAmount is the gross crypto amount the customer is redeeming
- eToroFeeAmount is eToro's service fee (typically ~2% of RequestedAmount)
- InitialFeeAmount is a fixed base fee (defaults to 0)
- EstimatedBlockchainFee is the estimated network fee for the transfer
- Net amount to customer = RequestedAmount - eToroFeeAmount - InitialFeeAmount - blockchain fee

---

## 3. Data Overview

| Id | PositionId | CryptoId | RequestedAmount | eToroFeeAmount | RedemptionStatus | Meaning |
|---|---|---|---|---|---|---|
| 1138358 | 3403582325 | 64 (SOL) | 42.335 | 0.847 | 3 (SuccessReported) | SOL redemption: 42.3 SOL requested, 0.85 fee charged. Successfully executed on blockchain. |
| 1138357 | 3289256132 | 1 (BTC) | 0.005064 | 0.000101 | 2 (SentToExecuter) | BTC redemption in progress: sent to blockchain execution, awaiting confirmation. |
| 1138356 | 3403560860 | 64 (SOL) | 4.811 | 0.096 | 3 (SuccessReported) | Smaller SOL redemption from same customer. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | OriginalRequestGuid | uniqueidentifier | NO | - | CODE-BACKED | GUID of the original redemption request from the trading platform. Used for idempotency and cross-system correlation. |
| 3 | SendRequestCorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Links to the send transaction request in Wallet.Requests.CorrelationId created when the blockchain transfer is initiated. NULL until the redemption reaches the execution stage. |
| 4 | PositionId | bigint | YES | - | VERIFIED | Trading platform position being redeemed. Unique constraint - each position can only be redeemed once. NULL only for legacy records. |
| 5 | RequestingGcid | bigint | NO | - | CODE-BACKED | Global Customer ID of the customer requesting the redemption. |
| 6 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency being redeemed. Implicit reference to Wallet.CryptoTypes.CryptoID. |
| 7 | RequestedAmount | decimal(36,18) | NO | - | VERIFIED | Gross amount of crypto requested for redemption. In native units of CryptoId. |
| 8 | eToroFeeAmount | decimal(36,18) | NO | - | VERIFIED | eToro's service fee deducted from the redemption. Typically ~2% of RequestedAmount. |
| 9 | RedemptionStatus | tinyint | NO | - | VERIFIED | Lifecycle status: 0=Persisted, 1=Retrieved, 2=SentToExecuter, 3=SuccessReported, 4=FailureReported. See [Redemption Status](../../_glossary.md#redemption-status). FK to Dictionary.RedemptionStatus. |
| 10 | BillingTransId | bigint | YES | - | NAME-INFERRED | Transaction ID in the billing/accounting system for the fee charge. |
| 11 | BillingRedeemId | bigint | YES | - | NAME-INFERRED | Redemption ID in the billing/accounting system. |
| 12 | BeginDate | datetime2(7) | NO | sysutcdatetime() | CODE-BACKED | System-versioned temporal column (ROW START). |
| 13 | EndDate | datetime2(7) | NO | 9999-12-31... | CODE-BACKED | System-versioned temporal column (ROW END). |
| 14 | EstimatedBlockchainFee | decimal(36,18) | YES | - | CODE-BACKED | Estimated network fee for the blockchain transfer. Calculated before execution based on current network conditions. |
| 15 | InitialFeeAmount | decimal(36,18) | NO | 0 | CODE-BACKED | Fixed base fee charged regardless of amount. Defaults to 0 for most cryptos. |
| 16 | SourceWalletId | uniqueidentifier | YES | - | CODE-BACKED | The omnibus/system wallet from which the crypto is sent to the customer. FK to Wallet.Wallets.WalletId. NULL for legacy records. |
| 17 | TransactionTypeId | tinyint | YES | - | CODE-BACKED | Type of sent transaction created: typically 0 (Redeem) or 8 (RedeemAsic). FK to Dictionary.TransactionTypes. See [Transaction Type](../../_glossary.md#transaction-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedemptionStatus | Dictionary.RedemptionStatus | FK | Lifecycle status |
| SourceWalletId | Wallet.Wallets | FK | Source omnibus wallet |
| TransactionTypeId | Dictionary.TransactionTypes | FK | Sent transaction type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AddNewRedemptionRequest | - | Writer | Creates redemption records |
| Wallet.GetRedemptionByPositionId | - | Reader | Looks up by position |
| Wallet.GetPendingRedemptionRequests | - | Reader | Finds unprocessed redemptions |
| Wallet.UpdateStatusOfRedeemRequestsByRedemptionIds | - | Modifier | Updates status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.Redemptions (table)
├── Wallet.Wallets (table)
├── Dictionary.RedemptionStatus (table)
└── Dictionary.TransactionTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Wallets | Table | FK target for SourceWalletId |
| Dictionary.RedemptionStatus | Table | FK target for RedemptionStatus |
| Dictionary.TransactionTypes | Table | FK target for TransactionTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AddNewRedemptionRequest | Stored Procedure | Creates records |
| Wallet.GetRedemptionByPositionId | Stored Procedure | Looks up by position |
| Wallet.GetPendingRedemptionRequests | Stored Procedure | Finds pending redemptions |
| Wallet.GetStuckRedeemRequests | Stored Procedure | Finds stuck redemptions |
| Wallet.UpdateStatusOfRedeemRequestsByRedemptionIds | Stored Procedure | Updates status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RedemptionId | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_Redemptions_PositionId | NC UNIQUE | PositionId ASC | - | - | Active |
| IX_Wallet_Redemptions_OriginalRequestGuid | NC | OriginalRequestGuid | - | - | Active |
| IX_Wallet_Redemptions_SendRequestCorrelationId | NC | SendRequestCorrelationId | - | - | Active |
| ix_Redemptions_CryptoId_RequestingGcid | NC | RequestingGcid, CryptoId | - | - | Active |
| ix_Redemptions_RedemptionStatus | NC | RedemptionStatus | - | - | Active |
| nci_wi_Redemptions_... | NC | RedemptionStatus | CryptoId, RequestingGcid, SendRequestCorrelationId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (BeginDate) | DEFAULT | sysutcdatetime() |
| DF (EndDate) | DEFAULT | 9999-12-31 23:59:59.9999999 |
| DF (InitialFeeAmount) | DEFAULT | 0 |
| FK_Redemptions_RedemptionStatus | FK | -> Dictionary.RedemptionStatus.Id |
| FK_...SourceWalletId | FK | -> Wallet.Wallets.WalletId |
| FK_...TransactionTypeId | FK | -> Dictionary.TransactionTypes.Id |

---

## 8. Sample Queries

### 8.1 Get redemptions for a customer
```sql
SELECT r.Id, r.PositionId, ct.Name AS Crypto, r.RequestedAmount, r.eToroFeeAmount,
    rs.Name AS Status, r.BeginDate
FROM Wallet.Redemptions r WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON r.CryptoId = ct.CryptoID
JOIN Dictionary.RedemptionStatus rs WITH (NOLOCK) ON r.RedemptionStatus = rs.Id
WHERE r.RequestingGcid = 35569867
ORDER BY r.Id DESC
```

### 8.2 Find stuck redemptions
```sql
SELECT r.Id, r.RequestingGcid, ct.Name AS Crypto, r.RequestedAmount, rs.Name AS Status, r.BeginDate
FROM Wallet.Redemptions r WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON r.CryptoId = ct.CryptoID
JOIN Dictionary.RedemptionStatus rs WITH (NOLOCK) ON r.RedemptionStatus = rs.Id
WHERE r.RedemptionStatus IN (0, 1, 2)
  AND r.BeginDate < DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY r.BeginDate
```

### 8.3 Redemption volume and fees by crypto
```sql
SELECT ct.Name AS Crypto, COUNT(*) AS RedemptionCount,
    SUM(r.RequestedAmount) AS TotalRequested, SUM(r.eToroFeeAmount) AS TotalFees
FROM Wallet.Redemptions r WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON r.CryptoId = ct.CryptoID
WHERE r.RedemptionStatus = 3
GROUP BY ct.Name
ORDER BY RedemptionCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 8.8/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.Redemptions | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.Redemptions.sql*
