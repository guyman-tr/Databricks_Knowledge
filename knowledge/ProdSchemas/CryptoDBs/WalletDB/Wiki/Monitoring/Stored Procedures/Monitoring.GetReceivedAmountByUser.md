# Monitoring.GetReceivedAmountByUser

> Aggregates total verified/confirmed received crypto amounts per customer wallet within a configurable time window, excluding omnibus wallets, Redeem wallets, self-transfers, and failed transactions.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns per-user/wallet/crypto received totals |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetReceivedAmountByUser calculates how much crypto each customer has received within a recent time window. This enables monitoring for unusually large inflows that may require compliance review or could indicate suspicious activity. Only non-omnibus, non-Redeem wallet types are included, and self-transfers (from the user's own addresses) are excluded.

Without this procedure, identifying customers with large recent inflows would require complex manual queries spanning multiple tables. This procedure provides a ready-made aggregation for threshold-based alerting.

The procedure joins ReceivedTransactions to CustomerWalletsView to get customer context, uses a correlated subquery to determine the latest status per transaction (via Dictionary.TransactionStatus name), and sums only Verified/Confirmed amounts. Transactions from the user's own addresses (self-transfers) are excluded via WalletAddresses.

---

## 2. Business Logic

### 2.1 Inflow Aggregation Rules

**What**: Calculates net verified received amounts per customer/wallet/crypto.

**Columns/Parameters Involved**: `@TimeInterval`, `Amount`, `Status`, `Gcid`, `WalletTypeId`

**Rules**:
- Only Verified and Confirmed transactions are summed (other statuses contribute 0)
- Statuses excluded: Timeout, PermanentError, WavedError
- Omnibus wallets (Gcid=0) excluded - platform wallets are not customer activity
- Redeem wallet type excluded - redemption wallets are operational, not customer-facing
- Self-transfers excluded: if the sender address matches any of the user's own wallet addresses, the receive is excluded
- @TimeInterval is in minutes (default 60)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeInterval | INT | NO | 60 | CODE-BACKED | Lookback window in minutes from current UTC time. Default 60 minutes (1 hour). |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Gcid | INT | NO | - | CODE-BACKED | Customer ID who received crypto. |
| 2 | WalletId | BIGINT | NO | - | CODE-BACKED | Wallet that received the funds. |
| 3 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency type received. |
| 4 | TotalAmount | DECIMAL | NO | - | CODE-BACKED | Sum of verified/confirmed received amounts in the window. Transactions with non-success statuses contribute 0 to the sum. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.ReceivedTransactions | FROM (read) | Source of receive records |
| Query body | Wallet.CustomerWalletsView | JOIN | Maps wallets to customers, filters Gcid/type |
| Query body | Wallet.ReceivedTransactionStatuses | Subquery | Gets latest status per transaction |
| Query body | Dictionary.TransactionStatus | Subquery JOIN | Maps status ID to name |
| Query body | Wallet.WalletAddresses | NOT IN subquery | Excludes self-transfers |
| Query body | Dictionary.WalletTypes | JOIN | Excludes Redeem wallet type |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetReceivedAmountByUser (procedure)
  ├── Wallet.ReceivedTransactions (table)
  ├── Wallet.CustomerWalletsView (view)
  ├── Wallet.ReceivedTransactionStatuses (table)
  ├── Dictionary.TransactionStatus (table)
  ├── Wallet.WalletAddresses (table)
  └── Dictionary.WalletTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | FROM - receive records |
| Wallet.CustomerWalletsView | View | JOIN - wallet/customer mapping |
| Wallet.ReceivedTransactionStatuses | Table | Subquery - latest status |
| Dictionary.TransactionStatus | Table | Subquery - status name |
| Wallet.WalletAddresses | Table | NOT IN - self-transfer exclusion |
| Dictionary.WalletTypes | Table | JOIN - type filter |

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

### 8.1 Check last hour (default)
```sql
EXEC Monitoring.GetReceivedAmountByUser;
```

### 8.2 Check last 24 hours
```sql
EXEC Monitoring.GetReceivedAmountByUser @TimeInterval = 1440;
```

### 8.3 Find top receivers in last hour
```sql
-- Run the procedure and sort by TotalAmount DESC externally
EXEC Monitoring.GetReceivedAmountByUser @TimeInterval = 60;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetReceivedAmountByUser | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetReceivedAmountByUser.sql*
