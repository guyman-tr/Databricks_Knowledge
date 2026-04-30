# Wallet.UpdateReportRun

> Marks a reconciliation run as complete by setting its EndTime in the current FinanceReportRuns table.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Id parameter - identifies which run to complete |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.UpdateReportRun is the completion marker for reconciliation runs in the current system. After the application finishes processing all wallet-crypto pairs in a run (inserting records via Wallet.CreateNewReportRun and updating them via Wallet.UpdateReportRecords), it calls this procedure to stamp the EndTime, signaling that the run is complete.

This procedure exists to close the run lifecycle in Wallet.FinanceReportRuns. Operations monitoring depends on EndTime being populated to determine whether a run completed successfully. A NULL EndTime after the expected processing window would trigger investigation. It is the current-system counterpart to the legacy Wallet.UpdateReports.

The procedure is a single-statement UPDATE -- it sets EndTime = GETDATE() on the row identified by @Id. Note: it uses GETDATE() (local server time) rather than GETUTCDATE() (UTC), which creates a potential timezone inconsistency with StartTime (set as GETUTCDATE() by Wallet.CreateNewReportRun). This is a known pattern inherited from the legacy system.

---

## 2. Business Logic

### 2.1 Run Completion Timestamp

**What**: Stamps the EndTime on a reconciliation run to signal completion.

**Columns/Parameters Involved**: `@Id`, `EndTime`

**Rules**:
- Called after Wallet.CreateNewReportRun inserts the run and child records, and after the application processes all results via Wallet.UpdateReportRecords
- EndTime is set to GETDATE() (local time), creating a timezone inconsistency with StartTime (GETUTCDATE/UTC)
- No validation is performed -- if @Id doesn't match a row, the UPDATE silently affects zero rows
- Can theoretically be called multiple times for the same @Id, overwriting EndTime with the latest local time

**Diagram**:
```
Wallet.CreateNewReportRun
  | INSERT run + records (StartTime = GETUTCDATE())
  v
Application processes records
  | Calls Wallet.UpdateReportRecords
  v
Wallet.UpdateReportRun(@Id)
  | UPDATE SET EndTime = GETDATE()
  v
Run is "complete"
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | bigint | NO | - | CODE-BACKED | The FinanceReportRuns.Id to mark as complete. This is the PK of the run row created by Wallet.CreateNewReportRun. No validation is performed -- non-existent IDs result in a no-op UPDATE. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Id | Wallet.FinanceReportRuns | UPDATE | Sets EndTime on the identified run row |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the application layer after reconciliation processing completes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpdateReportRun (procedure)
+-- Wallet.FinanceReportRuns (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReportRuns | Table | UPDATE SET EndTime - marks the run as complete |

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

### 8.1 Execute the procedure for a specific run
```sql
-- Mark run 622 as complete
EXEC Wallet.UpdateReportRun @Id = 622;
```

### 8.2 Verify a run was completed
```sql
SELECT Id, StartTime, EndTime,
       CASE WHEN EndTime IS NULL THEN 'IN PROGRESS' ELSE 'COMPLETED' END AS Status
FROM Wallet.FinanceReportRuns WITH (NOLOCK)
WHERE Id = 622;
```

### 8.3 Find runs missing EndTime (potentially incomplete)
```sql
SELECT Id, StartTime
FROM Wallet.FinanceReportRuns WITH (NOLOCK)
WHERE EndTime IS NULL
ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpdateReportRun | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.UpdateReportRun.sql*
