# Wallet.SyncFundedWalletStatusesAsync

> Synchronizes pool wallet funding statuses by checking the blockchain confirmation state and request status of FundingSent wallets, updating them to FundingVerified or FundingFailed based on the underlying transaction outcomes.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Multi-step status sync for FundingSent pool wallets |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure synchronizes the funding status of pool wallets with the actual blockchain and request outcomes. When pool wallets are funded, they enter 'FundingSent' status. This procedure checks whether the underlying blockchain transaction has been verified or failed, and updates the pool wallet status accordingly to 'FundingVerified' or 'FundingFailed'. The redeem scheduler runs this periodically to keep pool wallet statuses consistent with reality.

The procedure uses three temp tables to stage the data: #fundings (wallets in FundingSent without a terminal status), #statuses (latest blockchain confirmation status per correlation), and #requests (request-level status for transactions that skipped blockchain confirmation).

---

## 2. Business Logic

### 2.1 Three-Stage Status Resolution

**What**: Checks blockchain and request statuses to determine the correct funding outcome.

**Columns/Parameters Involved**: `WalletPoolStatuses`, `SentTransactionStatuses`, `RequestStatuses`

**Rules**:
- Stage 1: Find FundingSent pool wallets that don't yet have FundingVerified or FundingFailed
- Stage 2: Get latest SentTransactionStatuses for each funding's CorrelationId
- Stage 3: For transactions without blockchain status, check RequestStatuses
- Update pool wallet status based on confirmed blockchain or request outcomes

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no parameters) | - | - | - | - | - | Parameterless - processes all pending FundingSent wallets. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.PromotionTags | JOIN | Crypto-to-promotion mapping |
| - | Wallet.WalletPool | JOIN | Pool wallet records |
| - | Wallet.WalletPoolStatuses | JOIN + INSERT | Current + new statuses |
| - | Dictionary.WalletPoolStatuses | JOIN | Status name resolution |
| - | Wallet.SentTransactions | JOIN | Funding transaction lookup |
| - | Wallet.SentTransactionStatuses | JOIN | Blockchain confirmation status |
| - | Wallet.Requests + RequestStatuses | JOIN | Request-level status fallback |
| - | Wallet.CryptoTypes | JOIN | Crypto mapping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemSchedulerUser | - | EXECUTE | Periodic funding status sync |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.SyncFundedWalletStatusesAsync (procedure)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletPoolStatuses (table)
+-- Dictionary.WalletPoolStatuses (table)
+-- Wallet.PromotionTags (table)
+-- Wallet.CryptoTypes (table)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool + WalletPoolStatuses | Tables | Pool wallet status management |
| Dictionary.WalletPoolStatuses | Table | Status name resolution |
| Wallet.SentTransactions + SentTransactionStatuses | Tables | Blockchain status check |
| Wallet.Requests + RequestStatuses | Tables | Request status fallback |
| Wallet.PromotionTags + CryptoTypes | Tables | Funding context |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RedeemSchedulerUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses 3 temp tables for staged processing.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run the sync
```sql
EXEC Wallet.SyncFundedWalletStatusesAsync;
```

### 8.2 Check wallets still in FundingSent
```sql
SELECT wps.WalletPoolId, wps.CorrelationId FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
    JOIN Dictionary.WalletPoolStatuses dps WITH (NOLOCK) ON dps.Id = wps.WalletPoolStatusId
WHERE dps.Name = 'FundingSent';
```

### 8.3 Check funding outcomes
```sql
SELECT dps.Name, COUNT(*) FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK)
    JOIN Dictionary.WalletPoolStatuses dps WITH (NOLOCK) ON dps.Id = wps.WalletPoolStatusId
WHERE dps.Name IN ('FundingSent', 'FundingVerified', 'FundingFailed') GROUP BY dps.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SyncFundedWalletStatusesAsync | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.SyncFundedWalletStatusesAsync.sql*
