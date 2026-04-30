# Wallet.UpdateReportRecord

> Bulk-updates legacy reconciliation records in FinanceReportsBalances with verified BitGo/Blox balance values and classification results via the BalanceType table-valued parameter.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BalanceUpdates (Wallet.BalanceType TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.UpdateReportRecord applies verified reconciliation results to legacy balance records in Wallet.FinanceReportsBalances. After the application calls BitGo and Blox APIs to verify each discrepant wallet, it packages the results into a Wallet.BalanceType table-valued parameter (TVP) and passes it to this procedure. The procedure joins the TVP to the target table on (ReportId, WalletId, CryptoId) and updates six columns: FindDiscrepancy, LevelId, ErrorMsg, BitgoValue, BloxValue, and Retries.

This procedure exists as the "Phase 2" update step in the legacy reconciliation pipeline. After Wallet.CreateNewReports (or Wallet.GetWalletBalanceReport) creates preliminary records, the application verifies each discrepancy and reports results back through this procedure. It is the legacy counterpart to Wallet.UpdateReportRecords (which updates the current FinanceReportRecords table and includes additional pruning logic).

The TVP is first materialized into a #BalanceUpdates temp table with an index on (ReportId, WalletId, CryptoId) for efficient joining against the partitioned target table. This materialization pattern avoids optimizer issues with TVP statistics.

---

## 2. Business Logic

### 2.1 Verified Result Application (Simple Update)

**What**: Applies API-verified reconciliation results to legacy balance records without any filtering or pruning logic.

**Columns/Parameters Involved**: `@BalanceUpdates`, `FindDiscrepancy`, `LevelId`, `ErrorMsg`, `BitgoValue`, `BloxValue`, `Retries`

**Rules**:
- TVP data is copied to #BalanceUpdates temp table for materialization
- An index #IX_BalanceUpdates is created on (ReportId, WalletId, CryptoId) for efficient joining
- UPDATE joins #BalanceUpdates to FinanceReportsBalances on the three-part composite key
- Six columns are updated: FindDiscrepancy, LevelId, ErrorMsg, BitgoValue, BloxValue, Retries
- Unlike Wallet.UpdateReportRecords, this procedure does NOT check ProcessAllRecords or prune unchanged records -- all records in the TVP are updated
- No transaction wrapping -- the UPDATE is a single atomic statement

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BalanceUpdates | Wallet.BalanceType (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing verified reconciliation results. Each row has (ReportId, WalletId, CryptoId) as the composite key plus (FindDiscrepancy, LevelId, ErrorMsg, BitgoValue, BloxValue, Retries) as the update payload. See Wallet.BalanceType documentation for column details. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BalanceUpdates | Wallet.BalanceType | TVP parameter | Receives batch reconciliation results in the BalanceType table-valued parameter |
| (UPDATE) | Wallet.FinanceReportsBalances | MODIFIER | Updates legacy balance records with verified API results |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the application layer after API verification of discrepant wallets.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpdateReportRecord (procedure)
+-- Wallet.BalanceType (user defined type)
+-- Wallet.FinanceReportsBalances (table)
    +-- Wallet.FinanceReports (table) [implicit ref on ReportId]
    +-- Dictionary.FinanceReportLevel (table) [implicit ref on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.BalanceType | User Defined Type | TVP parameter type for batch reconciliation results |
| Wallet.FinanceReportsBalances | Table | UPDATE target - receives verified reconciliation results |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository. Called directly by the application.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Prepare and execute a TVP update
```sql
DECLARE @Updates Wallet.BalanceType;

INSERT INTO @Updates (ReportId, WalletId, CryptoId, FindDiscrepancy, LevelId, ErrorMsg, BitgoValue, BloxValue, Retries)
VALUES
    (2141, '749DB5AA-3724-47DA-A540-41D3DB8402DC', 64, 0, 1, NULL, 8.20000000, 8.20000000, 0),
    (2141, 'B4EDCB68-1234-5678-ABCD-EF1234567890', 21, 1, 3, NULL, 50.00000000, 50.00000000, 1);

EXEC Wallet.UpdateReportRecord @BalanceUpdates = @Updates;
```

### 8.2 Verify updates were applied
```sql
SELECT Id, WalletId, CryptoId, FindDiscrepancy, LevelId, BitgoValue, BloxValue, Retries
FROM Wallet.FinanceReportsBalances WITH (NOLOCK)
WHERE ReportId = 2141
  AND WalletId IN ('749DB5AA-3724-47DA-A540-41D3DB8402DC', 'B4EDCB68-1234-5678-ABCD-EF1234567890');
```

### 8.3 Check classification distribution after updates
```sql
SELECT ISNULL(l.Name, 'Unclassified') AS LevelName, COUNT(*) AS RecordCount
FROM Wallet.FinanceReportsBalances frb WITH (NOLOCK)
LEFT JOIN Dictionary.FinanceReportLevel l WITH (NOLOCK) ON frb.LevelId = l.Id
WHERE frb.ReportId = 2141
GROUP BY l.Name
ORDER BY RecordCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpdateReportRecord | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.UpdateReportRecord.sql*
