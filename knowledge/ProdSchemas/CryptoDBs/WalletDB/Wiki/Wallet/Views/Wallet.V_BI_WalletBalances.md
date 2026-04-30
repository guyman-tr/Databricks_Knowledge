# Wallet.V_BI_WalletBalances

> BI-facing view over Wallet.WalletBalances that returns balance snapshots within a rolling 20-day window, providing the business intelligence team with recent balance history without exposing the full multi-million-row base table.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View |
| **Key Identifier** | Id (int, from WalletBalances surrogate key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view provides a filtered, BI-optimized window into wallet balance history. It returns all balance snapshots where the `DateTo` falls within the last 20 days and the `DateFrom` is in the past. With ~832K rows (vs ~4.3M in the base table), it gives BI pipelines a manageable dataset for recent balance trend analysis, daily reports, and dashboards without scanning the entire balance history.

Without this view, BI queries would need to scan the full WalletBalances table and apply date filtering themselves. The view encapsulates the rolling-window logic so BI consumers can simply `SELECT *` and get the relevant subset. The "V_BI_" prefix follows the convention for views exposed to business intelligence tools.

Data flows into WalletBalances via the UpdateWalletBalances background process (Wallet.Processes Id=1) which periodically polls blockchain providers for current balances. This view passively exposes those snapshots within the 20-day window. It is not referenced by any stored procedure or other view in the SSDT - its consumers are external BI tools (e.g., Power BI, data pipelines).

---

## 2. Business Logic

### 2.1 Rolling 20-Day Window Filter

**What**: The view applies a date-based filter that returns only balance records whose time window overlaps with the last 20 days.

**Columns/Parameters Involved**: `DateFrom`, `DateTo`

**Rules**:
- `DateFrom < GETDATE()`: Excludes any future-dated records (safety filter - should not exist in practice)
- `DateTo >= CAST(DATEADD(day, -20, GETDATE()) AS DATE)`: Includes all records whose validity window extends into the last 20 days
- Records with `DateTo = '3000-01-01'` (current balances) always pass this filter since 3000-01-01 >= any 20-day-ago date
- Historical records older than 20 days are excluded, reducing the dataset from ~4.3M to ~832K rows
- The `CAST(...AS DATE)` truncation ensures the boundary is at midnight, providing a clean daily cutoff

---

## 3. Data Overview

| Id | WalletId (truncated) | CryptoId | DateFrom | DateTo | Balance | Meaning |
|---|---|---|---|---|---|---|
| 6133040 | 9516D5D6-... | 2 (ETH) | 2026-04-15 04:11 | 3000-01-01 | 0.000055 | Current ETH balance - the 3000-01-01 sentinel marks this as the latest/active snapshot. Dust-level amount. |
| 6133039 | 81AA369F-... | 107 | 2026-04-15 04:09 | 3000-01-01 | 367.992103 | Current balance of crypto 107 (likely USDC). Substantial holding actively visible to BI. |
| 6133037 | AD4E8E53-... | 1 (BTC) | 2026-04-15 04:06 | 3000-01-01 | 0 | Zero BTC balance - wallet emptied. Record retained for reporting completeness. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Auto-incrementing surrogate key from the base WalletBalances table. Not used as FK - the business key is (WalletId, CryptoId, DateTo). From Wallet.WalletBalances.Id. |
| 2 | WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet this balance belongs to. Implicit reference to Wallet.WalletPool.WalletId. From Wallet.WalletBalances.WalletId. |
| 3 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency this balance measures. FK to Wallet.CryptoTypes.CryptoID. Combined with WalletId and DateTo for unique identification. From Wallet.WalletBalances.CryptoId. |
| 4 | DateFrom | datetime2(7) | NO | - | CODE-BACKED | Start of this balance snapshot's validity window. Set to the time the balance was confirmed by the blockchain provider. Filtered by `DateFrom < GETDATE()` in the view. From Wallet.WalletBalances.DateFrom. |
| 5 | DateTo | datetime2(7) | NO | - | CODE-BACKED | End of this balance snapshot's validity window. 3000-01-01 = current/open balance. Updated to the next snapshot's DateFrom when a new balance is recorded. Filtered by `DateTo >= 20 days ago` in the view. From Wallet.WalletBalances.DateTo. |
| 6 | Balance | decimal(36,18) | YES | - | VERIFIED | The confirmed crypto balance in native units (e.g., BTC, ETH). NULL is possible but rare - indicates balance could not be determined. Uses high-precision decimal for sub-unit accuracy across all crypto types. From Wallet.WalletBalances.Balance. |
| 7 | Occurred | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this balance record was created/updated in the database. May differ from DateFrom if there was processing delay between provider confirmation and DB write. From Wallet.WalletBalances.Occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | Wallet.WalletBalances | SELECT (source) | Direct SELECT from the base balance table with date filtering |
| WalletId | Wallet.WalletPool | Implicit | Wallet identification via WalletId GUID |
| CryptoId | Wallet.CryptoTypes | Implicit | Crypto asset identification |

### 5.2 Referenced By (other objects point to this)

No stored procedures, views, or functions in the SSDT reference this view. Its consumers are external BI tools and data pipelines.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.V_BI_WalletBalances (view)
+-- Wallet.WalletBalances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletBalances | Table | SELECT all columns with date-range filter |

### 6.2 Objects That Depend On This

No dependents found in SSDT. External BI tools consume this view directly.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (no SCHEMABINDING, so indexed view not possible).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get current balances for a specific wallet
```sql
SELECT CryptoId, Balance, DateFrom
FROM Wallet.V_BI_WalletBalances WITH (NOLOCK)
WHERE WalletId = '9516D5D6-A81B-420B-AF05-6BEDD3205BF8'
  AND DateTo = '3000-01-01'
ORDER BY CryptoId
```

### 8.2 Daily balance trend for a wallet over the last 7 days
```sql
SELECT
    CAST(DateFrom AS DATE) AS BalanceDate,
    CryptoId,
    Balance
FROM Wallet.V_BI_WalletBalances WITH (NOLOCK)
WHERE WalletId = '9516D5D6-A81B-420B-AF05-6BEDD3205BF8'
  AND DateFrom >= DATEADD(day, -7, GETDATE())
ORDER BY DateFrom DESC
```

### 8.3 Count of active (non-zero) balances by crypto type
```sql
SELECT
    ct.CryptoName,
    COUNT(*) AS ActiveBalances
FROM Wallet.V_BI_WalletBalances bi WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = bi.CryptoId
WHERE bi.DateTo = '3000-01-01'
  AND bi.Balance > 0
GROUP BY ct.CryptoName
ORDER BY ActiveBalances DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.V_BI_WalletBalances | Type: View | Source: WalletDB/Wallet/Views/Wallet.V_BI_WalletBalances.sql*
