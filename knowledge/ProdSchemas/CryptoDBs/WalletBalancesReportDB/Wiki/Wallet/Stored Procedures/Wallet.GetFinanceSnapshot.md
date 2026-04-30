# Wallet.GetFinanceSnapshot

> Creates a point-in-time snapshot of the most recent reconciliation record for each wallet-crypto pair as of a given date, optionally returning the results or storing them in a global temp table for downstream queries.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @From datetime + @CreateOnly flag |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetFinanceSnapshot produces a point-in-time view of reconciliation state by finding the most recent FinanceReportRecords entry for each wallet-crypto pair as of a specified date. It answers the question: "What was the latest reconciliation result for every wallet at time X?" This enables historical analysis, trend detection, and comparison of reconciliation state across different points in time.

This procedure exists for ad-hoc investigation and operational analysis. When operations teams need to understand the reconciliation state at a specific date (e.g., before a system change, after an incident), this procedure reconstructs that state from the historical record. It is not part of the regular reconciliation pipeline but serves as an analytical tool.

The procedure reads the current wallet list from the external table (Wallet.vu_GetWalletBalanceReport) to get the active wallet set, then uses CROSS APPLY to find each wallet's latest FinanceReportRecords entry on or before @From. Results are stored in a global temp table (##FinanceSnapshot) which persists across the session -- when @CreateOnly=1 (default), the table is created but not returned, allowing downstream queries to analyze it. When @CreateOnly=0, the results are also returned directly.

---

## 2. Business Logic

### 2.1 Point-in-Time Reconstruction

**What**: Reconstructs the reconciliation state at any historical point by finding the latest record per wallet-crypto pair before the cutoff date.

**Columns/Parameters Involved**: `@From`, `@CreateOnly`, `vu_GetWalletBalanceReport`, `FinanceReportRecords`

**Rules**:
- Reads the current active wallet set from vu_GetWalletBalanceReport into a #View temp table
- For each wallet-crypto pair in #View, uses CROSS APPLY with TOP 1 ORDER BY Created DESC WHERE Created <= @From to find the latest record
- @From defaults to GETDATE() (current time) if not specified, giving the current latest snapshot
- Results are stored in ##FinanceSnapshot (global temp table) -- the DROP TABLE IF EXISTS ensures any previous snapshot is replaced
- @CreateOnly=1 (default): creates the global temp table only, allowing ad-hoc queries against ##FinanceSnapshot
- @CreateOnly=0: also returns the snapshot data as a result set ordered by WalletId, CryptoId
- Wallets that have no FinanceReportRecords entry before @From are excluded (CROSS APPLY filters them out)

**Diagram**:
```
Wallet.vu_GetWalletBalanceReport         Wallet.FinanceReportRecords
  (active wallets)                        (historical reconciliation data)
       |                                        |
       | SELECT INTO #View                      |
       v                                        |
  Active wallet set                             |
       |                                        |
       | CROSS APPLY (TOP 1 WHERE              |
       |   WalletId = v.WalletId AND           |
       |   CryptoId = v.CryptoId AND           |
       |   Created <= @From                     |
       |   ORDER BY Created DESC)               |
       v                                        v
  ##FinanceSnapshot (global temp table)
       |
       | @CreateOnly = 0?
       |     YES: Also SELECT * FROM ##FinanceSnapshot
       |     NO:  Table exists for downstream queries
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @From | datetime | YES | NULL (defaults to GETDATE()) | CODE-BACKED | Cutoff date for the point-in-time snapshot. Only FinanceReportRecords with Created <= @From are considered. NULL defaults to GETDATE(), giving the latest snapshot. Use a past date to reconstruct historical state. |
| 2 | @CreateOnly | bit | YES | 1 | CODE-BACKED | Controls output behavior. 1 (default) = create ##FinanceSnapshot global temp table only (for downstream ad-hoc queries); 0 = also return the snapshot as a result set ordered by WalletId, CryptoId. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT INTO) | Wallet.vu_GetWalletBalanceReport | READ | Reads the active wallet set from the external table |
| (CROSS APPLY) | Wallet.FinanceReportRecords | READ | Finds the latest reconciliation record per wallet-crypto pair before the cutoff date |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Used as an ad-hoc analytical tool by operations teams.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetFinanceSnapshot (procedure)
+-- Wallet.vu_GetWalletBalanceReport (external table)
|   +-- RemoteReferenceData (external data source)
+-- Wallet.FinanceReportRecords (table)
    +-- Wallet.FinanceReportRuns (table) [FK on ReportId]
    +-- Dictionary.FinanceReportLevel (table) [FK on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.vu_GetWalletBalanceReport | External Table | SELECT INTO #View - reads the active wallet set |
| Wallet.FinanceReportRecords | Table | CROSS APPLY - finds latest record per wallet before cutoff date |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Ad-hoc analytical tool.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Create a snapshot for the current state (default)
```sql
EXEC Wallet.GetFinanceSnapshot;
-- ##FinanceSnapshot global temp table is now available
SELECT TOP 10 * FROM ##FinanceSnapshot;
```

### 8.2 Create and return a historical snapshot
```sql
EXEC Wallet.GetFinanceSnapshot @From = '2025-12-31', @CreateOnly = 0;
```

### 8.3 Analyze discrepancy distribution from a snapshot
```sql
EXEC Wallet.GetFinanceSnapshot @From = '2026-04-15';

SELECT ISNULL(l.Name, 'No Discrepancy') AS LevelName, COUNT(*) AS WalletCount
FROM ##FinanceSnapshot fs
LEFT JOIN Dictionary.FinanceReportLevel l WITH (NOLOCK) ON fs.LevelId = l.Id
GROUP BY l.Name
ORDER BY WalletCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetFinanceSnapshot | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.GetFinanceSnapshot.sql*
