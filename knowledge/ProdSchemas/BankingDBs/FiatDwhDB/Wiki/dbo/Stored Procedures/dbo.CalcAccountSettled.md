# dbo.CalcAccountSettled

> Read-only procedure that calculates the settled balance for an account by summing AccumulatedAmount across all settled, rejected, and returned transaction statuses.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT SUM aggregation across FiatTransactions + FiatTransactionsStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

CalcAccountSettled computes the platform-calculated settled balance for an account in a specific currency. It sums the AccumulatedAmount from FiatTransactionsStatuses for all transactions with status 'Settled', 'Rejected', or 'Returned'. This calculated value can be compared against the CUG and Provider settled balances in BalanceReports for reconciliation.

---

## 2. Business Logic

### 2.1 Settled Balance Calculation

**What**: Computes CalcSettled = SUM(AccumulatedAmount) for settled/rejected/returned transactions.

**Columns/Parameters Involved**: `@AccountId`, `@CurrencyIson`

**Rules**:
- Joins FiatTransactions -> FiatTransactionsStatuses -> Dictionary.TransactionStatuses
- Filters on status names: 'Settled', 'Rejected', 'Returned' (not status IDs - uses dictionary name lookup)
- Groups by AccountId, Gcid
- Returns: AccountId, CalcSettled (sum), Gcid
- Note: TransactionCategories join exists but is commented out (was previously used to filter by category)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountId | bigint | NO | - | CODE-BACKED | FK to FiatAccount.Id. The account to calculate settled balance for. |
| 2 | @CurrencyIson | nvarchar(128) | NO | - | CODE-BACKED | ISO currency code filter. Only transactions in this currency are included. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatTransactions | Read | Transaction records |
| JOIN | dbo.FiatAccount | Read | Account context |
| JOIN | dbo.FiatTransactionsStatuses | Read | Status + amounts |
| JOIN | dbo.FiatCurrencyBalances | Read | Currency filter |
| JOIN | Dictionary.TransactionStatuses | Read | Status name filter |
| JOIN | Dictionary.TransactionCategories | Read | (commented out) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CalcAccountSettled (procedure)
├── dbo.FiatTransactions (table)
├── dbo.FiatAccount (table)
├── dbo.FiatTransactionsStatuses (table)
├── dbo.FiatCurrencyBalances (table)
├── Dictionary.TransactionStatuses (table)
└── Dictionary.TransactionCategories (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatTransactions | Table | Transaction records |
| dbo.FiatAccount | Table | Account context |
| dbo.FiatTransactionsStatuses | Table | Status + amounts |
| dbo.FiatCurrencyBalances | Table | Currency filter |

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

### 8.1 Calculate settled balance for an account in EUR
```sql
EXEC dbo.CalcAccountSettled @AccountId = 410569, @CurrencyIson = '978';
```

### 8.2 Compare with BalanceReports
```sql
-- Get CalcSettled from procedure
EXEC dbo.CalcAccountSettled @AccountId = 410569, @CurrencyIson = '978';
-- Compare with latest BalanceReports
SELECT TOP 1 CalcSettled, CugSettled, ProviderSettled/100 AS ProviderMajor
FROM dbo.BalanceReports WITH (NOLOCK) WHERE AccountId = 410569 ORDER BY Created DESC;
```

### 8.3 Manual equivalent query
```sql
SELECT fa.Id AS AccountId, SUM(ts.AccumulatedAmount) AS CalcSettled, fa.Gcid
FROM dbo.FiatTransactions t WITH (NOLOCK)
JOIN dbo.FiatAccount fa WITH (NOLOCK) ON fa.Id = t.AccountId
JOIN dbo.FiatTransactionsStatuses ts WITH (NOLOCK) ON ts.TransactionId = t.Id
JOIN dbo.FiatCurrencyBalances cb WITH (NOLOCK) ON cb.Id = t.CurrencyBalanceId
JOIN Dictionary.TransactionStatuses dts WITH (NOLOCK) ON ts.TransactionStatusId = dts.Id
WHERE dts.Name IN ('Settled', 'Rejected', 'Returned')
  AND fa.Id = 410569 AND cb.CurrencyISON = '978'
GROUP BY fa.Id, fa.Gcid;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | BalanceReports discrepancy detection compares CalcSettled with Provider/CUG balances |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.CalcAccountSettled | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.CalcAccountSettled.sql*
