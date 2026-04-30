# Wallet.UpdateReports

> Marks a legacy reconciliation run as complete by setting its EndTime in the FinanceReports table.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Id parameter - identifies which legacy run to complete |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.UpdateReports is the completion marker for the legacy reconciliation system. After the application finished processing all wallet-crypto pairs in a legacy run (inserting records via Wallet.CreateNewReports and updating them via Wallet.UpdateReportRecord), it called this procedure to stamp the EndTime, signaling that the run was complete.

This procedure exists to close the run lifecycle in Wallet.FinanceReports, the legacy run-tracking table. It is the legacy counterpart to Wallet.UpdateReportRun (which serves the same role for the current Wallet.FinanceReportRuns table). Since the legacy system stopped receiving data in December 2024, this procedure is no longer actively called in production.

The procedure is a single-statement UPDATE -- it sets EndTime = GETDATE() on the row identified by @Id. Like its current counterpart, it uses GETDATE() (local time) rather than GETUTCDATE(), maintaining the timezone inconsistency pattern.

---

## 2. Business Logic

### 2.1 Legacy Run Completion

**What**: Stamps the EndTime on a legacy reconciliation run to signal completion.

**Columns/Parameters Involved**: `@Id`, `EndTime`

**Rules**:
- Called after Wallet.CreateNewReports inserted the run and child FinanceReportsBalances records
- EndTime is set to GETDATE() (local time), matching the pattern used by the current Wallet.UpdateReportRun
- 68 out of 2,094 legacy runs (3.2%) have NULL EndTime, indicating runs that were never completed -- more than the current system (0%)
- No longer called in production since the system migrated to Wallet.FinanceReportRuns in December 2024

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | bigint | NO | - | CODE-BACKED | The FinanceReports.Id to mark as complete. This is the PK of the legacy run row created by Wallet.CreateNewReports. No validation -- non-existent IDs result in a no-op UPDATE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Id | Wallet.FinanceReports | UPDATE | Sets EndTime on the identified legacy run row |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Was called by the application layer after legacy reconciliation processing completed. No longer actively used.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpdateReports (procedure)
+-- Wallet.FinanceReports (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReports | Table | UPDATE SET EndTime - marks the legacy run as complete |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure for a specific legacy run
```sql
-- Mark legacy run 2141 as complete
EXEC Wallet.UpdateReports @Id = 2141;
```

### 8.2 Check if a legacy run was completed
```sql
SELECT Id, StartTime, EndTime,
       CASE WHEN EndTime IS NULL THEN 'NEVER COMPLETED' ELSE 'COMPLETED' END AS Status,
       DATEDIFF(MINUTE, StartTime, EndTime) AS DurationMinutes
FROM Wallet.FinanceReports WITH (NOLOCK)
WHERE Id = 2141;
```

### 8.3 Find legacy runs that never completed
```sql
SELECT Id, StartTime
FROM Wallet.FinanceReports WITH (NOLOCK)
WHERE EndTime IS NULL
ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpdateReports | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.UpdateReports.sql*
