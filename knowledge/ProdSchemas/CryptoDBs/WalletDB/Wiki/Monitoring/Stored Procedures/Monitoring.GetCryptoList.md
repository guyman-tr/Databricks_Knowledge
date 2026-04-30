# Monitoring.GetCryptoList

> Lists recent send and receive transactions that have non-green AML (anti-money-laundering) validation statuses, enriched with customer, crypto, and AML details for compliance monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns flagged AML transactions with provider status details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetCryptoList is a compliance monitoring procedure that surfaces crypto transactions flagged by the AML (Chainalysis) provider with a non-green status. "Green" means the transaction passed compliance checks; any other status (yellow, red, etc.) requires attention. This combines both sent and received transactions into a single result set for unified monitoring.

Without this procedure, the compliance team would need to separately query sent and received transactions, cross-reference AML validations, and filter out internal omnibus transfers - a complex manual process that would delay the identification of flagged transactions.

The procedure uses a UNION ALL to combine sent transactions (verified, IsSend=1) and received transactions (verified, IsSend=0), both filtered to Chainalysis (AmlProviderId=1) with non-green status. It excludes omnibus wallets (Gcid=0) for sends and filters out internal transfers (where sender address belongs to an omnibus wallet) for receives.

---

## 2. Business Logic

### 2.1 AML Status Flagging

**What**: Identifies transactions with AML provider statuses other than "green" (clean).

**Columns/Parameters Involved**: `ProviderStatus`, `AmlProviderId`, `IsSend`

**Rules**:
- Only Chainalysis validations (AmlProviderId = 1) are checked
- ProviderStatus != 'green' triggers inclusion in results
- Send transactions: must be Verified (SentTransactionStatuses.StatusId = 2) and not from omnibus (Gcid > 0)
- Receive transactions: must be Verified (ReceivedTransactionStatuses.StatusId = 2), not from omnibus (Gcid > 0), and sender address must NOT be an omnibus wallet address

### 2.2 Internal Transfer Exclusion

**What**: Filters out receive transactions that originate from the platform's own omnibus wallets.

**Columns/Parameters Involved**: `SenderAddress`, `Gcid`

**Rules**:
- For received transactions, the SenderAddress is checked against all addresses of omnibus wallets (Gcid=0) with the same CryptoId
- If the sender is an omnibus wallet, the transaction is an internal platform transfer and excluded from AML monitoring

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Hours | INT | NO | 1 | CODE-BACKED | Lookback window in hours from current time. Default 1 hour for frequent polling. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | gcid | INT | NO | - | CODE-BACKED | Global Customer ID of the wallet owner involved in the flagged transaction. |
| 2 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency identifier for the transaction. |
| 3 | MarketRatesCurrencySymbol | NVARCHAR | NO | - | CODE-BACKED | Market rates currency symbol for the crypto. From Wallet.CryptoMarketRatesMappings. |
| 4 | Amount | DECIMAL | NO | - | CODE-BACKED | Transaction amount flagged by AML. |
| 5 | Address | NVARCHAR | NO | - | CODE-BACKED | Blockchain address involved in the flagged transaction. |
| 6 | ProviderStatus | NVARCHAR | NO | - | CODE-BACKED | AML provider (Chainalysis) status: non-green value indicating compliance concern. |
| 7 | IsSend | BIT | NO | - | CODE-BACKED | Direction flag: 1 = outgoing (send), 0 = incoming (receive). |
| 8 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Correlation ID for tracing the full transaction flow. |
| 9 | Occurred | DATETIME2 | NO | - | CODE-BACKED | Timestamp when the transaction occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.SentTransactions | FROM (read) | Source of outgoing transactions |
| Query body | Wallet.SentTransactionStatuses | JOIN | Filters to verified sends (StatusId=2) |
| Query body | Wallet.AmlValidations | JOIN | AML provider status for sends (IsSend=1, AmlProviderId=1) |
| Query body | Wallet.CustomerWalletsView | JOIN | Maps wallets to customers, filters out omnibus |
| Query body | Wallet.ReceivedTransactions | FROM (read) | Source of incoming transactions |
| Query body | Wallet.ReceivedTransactionStatuses | JOIN | Filters to verified receives (StatusId=2) |
| Query body | Wallet.CryptoMarketRatesMappings | JOIN | Maps CryptoId to market rate symbol |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetCryptoList (procedure)
  ├── Wallet.SentTransactions (table)
  ├── Wallet.SentTransactionStatuses (table)
  ├── Wallet.AmlValidations (table)
  ├── Wallet.CustomerWalletsView (view)
  ├── Wallet.ReceivedTransactions (table)
  ├── Wallet.ReceivedTransactionStatuses (table)
  └── Wallet.CryptoMarketRatesMappings (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | FROM - sent transaction data |
| Wallet.SentTransactionStatuses | Table | JOIN - verified status filter |
| Wallet.AmlValidations | Table | JOIN - AML provider status lookup |
| Wallet.CustomerWalletsView | View | JOIN - customer/wallet mapping |
| Wallet.ReceivedTransactions | Table | FROM - received transaction data |
| Wallet.ReceivedTransactionStatuses | Table | JOIN - verified status filter |
| Wallet.CryptoMarketRatesMappings | Table | JOIN - crypto symbol lookup |

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

### 8.1 Check last hour for flagged transactions
```sql
EXEC Monitoring.GetCryptoList;
```

### 8.2 Check last 24 hours
```sql
EXEC Monitoring.GetCryptoList @Hours = 24;
```

### 8.3 Check current non-green AML validations independently
```sql
SELECT TOP 20 av.CorrelationId, av.Address, av.Amount, av.ProviderStatus, av.IsSend, av.Created
FROM Wallet.AmlValidations av WITH (NOLOCK)
WHERE av.AmlProviderId = 1 AND av.ProviderStatus <> 'green'
  AND av.Created >= DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY av.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetCryptoList | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetCryptoList.sql*
