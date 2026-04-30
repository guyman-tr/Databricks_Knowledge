# Wallet.GetPendingRedemptionRequests

> Retrieves pending crypto redemption requests (RedemptionStatus=0) with special handling for initial fees and per-crypto batch limits (XLM, CryptoId=64), preparing them for execution.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns pending redemptions with fee calculations and per-wallet deduplication |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves crypto-to-fiat redemption requests that are ready to be executed. When a customer sells their crypto position, a redemption request is created to transfer the crypto from the customer's wallet to eToro's omnibus wallet. This procedure gathers those pending requests with all the details needed for execution: destination address, amounts, fees, and wallet identifiers.

The procedure implements several business rules to prevent issues: initial fee deduction logic (first redemption per wallet may incur a creation fee), per-wallet ordering (one redemption at a time per wallet to prevent race conditions), and crypto-specific batch limits (XLM and CryptoId=64 have special serialization requirements).

Data uses multiple CTEs: rowsToUpdate (base pending redemptions), processedRedeems4InitialFee (wallets that already paid initial fees), processedRedeems4XLM/pendingRedeems4XLM (XLM-specific serialization logic). Joins `Wallet.Redemptions`, `Wallet.CustomerWalletsView`, and `Wallet.CryptoTypes`.

---

## 2. Business Logic

### 2.1 Initial Fee Handling

**What**: First redemption per wallet may include an initial/creation fee that subsequent redemptions do not.

**Columns/Parameters Involved**: `InitialFeeUnits`, `InitialFeeAmount`, `WalletRowNum`

**Rules**:
- CryptoTypes.InitialFeeUnits defines the fee amount for the crypto (e.g., XRP reserve)
- InitialFeeAmount = InitialFeeUnits ONLY when: (a) no prior processed redemption exists for this wallet (processedRedeems4InitialFee is NULL) AND (b) this is the first redemption for this wallet in the batch (WalletRowNum = 1)
- Otherwise InitialFeeAmount = 0 (fee already paid on a previous redemption)

### 2.2 Per-Crypto Batch Limits

**What**: Some cryptocurrencies require serialized processing (one at a time per wallet).

**Columns/Parameters Involved**: `CryptoId`, `MaxRowNum`, `RowNum`

**Rules**:
- CryptoId=21 (XLM/Stellar): If no completed redemption exists (prxlm NULL) AND no pending redemption exists (pexlm NULL), MaxRowNum=1 (process one). If pending exists, MaxRowNum=0 (wait). If completed exists, MaxRowNum=10000 (no limit)
- CryptoId=64: Always MaxRowNum=1 (strict serialization)
- All other cryptos: MaxRowNum=10000 (effectively unlimited per wallet)
- WHERE RowNum <= MaxRowNum enforces the limit

**Diagram**:
```
Redemptions (RedemptionStatus=0, pending)
    |
    +-- JOIN CustomerWalletsView (Gcid + CryptoId) -> destination wallet
    +-- JOIN CryptoTypes -> InitialFeeUnits
    |
    +-- CTE: processedRedeems4InitialFee -> wallets with prior processed redeems
    +-- CTE: processedRedeems4XLM -> XLM wallets with completed redeems (status>=3)
    +-- CTE: pendingRedeems4XLM -> XLM wallets with in-progress redeems (status=2)
    |
    v
Per-wallet ordering (ROW_NUMBER) with crypto-specific MaxRowNum limits
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

This procedure has no input parameters.

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | BIGINT | NO | - | CODE-BACKED | Redemptions record ID. Primary identifier for the redemption request. |
| 2 | PositionId | BIGINT | NO | - | CODE-BACKED | Trading position ID being redeemed. Links the crypto redemption to the trading platform's position. |
| 3 | RequestingGcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID who requested the redemption. |
| 4 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency being redeemed. FK to Wallet.CryptoTypes. |
| 5 | DestinationAddress | NVARCHAR | YES | - | CODE-BACKED | Customer's wallet address where redemption proceeds will be sent. From CustomerWalletsView.Address. |
| 6 | RequestedAmount | DECIMAL | NO | - | CODE-BACKED | Amount of crypto requested for redemption. |
| 7 | EtoroFeeAmount | DECIMAL | YES | - | CODE-BACKED | eToro's fee for the redemption (aliased from eToroFeeAmount). |
| 8 | RedemptionStatus | INT | NO | - | CODE-BACKED | Always 0 (Pending) due to the WHERE filter. |
| 9 | InitialFeeAmount | DECIMAL | NO | - | CODE-BACKED | Initial/creation fee amount. Non-zero only for the first redemption per wallet when InitialFeeUnits > 0. |
| 10 | RecordId | BIGINT | NO | - | CODE-BACKED | WalletRecordId from CustomerWalletsView. Used for wallet identification. |
| 11 | WalletId | BIGINT | NO | - | CODE-BACKED | Wallet record ID from CustomerWalletsView.Id. |
| 12 | ProviderWalletId | NVARCHAR | YES | - | CODE-BACKED | Custody provider's wallet ID (aliased from BlockchainProviderWalletId). |
| 13 | SourceWalletId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Source wallet for the redemption transfer. |
| 14 | TransactionTypeId | INT | YES | - | CODE-BACKED | Transaction type classification for the redemption. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Redemptions | FROM | Pending redemption requests |
| RequestingGcid + CryptoId | Wallet.CustomerWalletsView | JOIN | Customer's destination wallet |
| CryptoId | Wallet.CryptoTypes | JOIN | Crypto configuration (InitialFeeUnits) |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by the redemption execution service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingRedemptionRequests (procedure)
+-- Wallet.Redemptions (table)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.CryptoTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | FROM + CTEs - pending and historical redemptions |
| Wallet.CustomerWalletsView | View | JOIN - customer wallet details |
| Wallet.CryptoTypes | Table | JOIN - initial fee configuration |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Wallet.GetPendingRedemptionRequests;
```

### 8.2 Count pending redemptions by crypto
```sql
SELECT CryptoId, COUNT(*) AS PendingCount, SUM(RequestedAmount) AS TotalAmount
FROM Wallet.Redemptions WITH (NOLOCK)
WHERE RedemptionStatus = 0
GROUP BY CryptoId
ORDER BY PendingCount DESC;
```

### 8.3 Check redemption status distribution
```sql
SELECT RedemptionStatus, COUNT(*) AS RedeemCount
FROM Wallet.Redemptions WITH (NOLOCK)
GROUP BY RedemptionStatus
ORDER BY RedemptionStatus;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingRedemptionRequests | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingRedemptionRequests.sql*
