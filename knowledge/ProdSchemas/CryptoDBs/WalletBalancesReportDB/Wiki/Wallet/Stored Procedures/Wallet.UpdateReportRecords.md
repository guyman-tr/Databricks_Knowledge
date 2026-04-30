# Wallet.UpdateReportRecords

> Bulk-updates current reconciliation records in FinanceReportRecords with verified results and optionally prunes unchanged records to reduce storage, using the BalanceType TVP and the run's ProcessAllRecords parameter.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BalanceUpdates (Wallet.BalanceType TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.UpdateReportRecords is the "Phase 2" update step in the current reconciliation pipeline. After the application verifies each discrepant wallet by calling BitGo and Blox APIs, it packages the results into a Wallet.BalanceType TVP and calls this procedure. The procedure applies the verified results (FindDiscrepancy, LevelId, ErrorMsg, BitgoValue, BloxValue, Retries) to Wallet.FinanceReportRecords AND optionally prunes records that haven't changed from the previous run -- a storage optimization unique to the current system.

This procedure exists as the evolution of Wallet.UpdateReportRecord (legacy). The key advancement is the pruning logic: when the run's Parameters JSON has ProcessAllRecords=false, the procedure compares each record's verified results against the previous run's record for the same wallet-crypto pair. If all key fields are identical (FindDiscrepancy, LevelId, ErrorMsg, BitgoValue, BloxValue), the new record is DELETED as redundant. This keeps the FinanceReportRecords table from growing linearly with each run for stable wallets.

The procedure reads the run's Parameters JSON from Wallet.FinanceReportRuns to determine whether to prune. It joins FinanceReportRecords to itself via CROSS APPLY (TOP 1 ORDER BY Created DESC WHERE Created < current record) to find each record's predecessor. After pruning (if applicable), it applies the standard six-column UPDATE to all surviving records and stamps LastChecked = GETUTCDATE().

---

## 2. Business Logic

### 2.1 Conditional Record Pruning

**What**: Deletes current-run records that are identical to the previous run's records for the same wallet-crypto pair, reducing table growth.

**Columns/Parameters Involved**: `ProcessAllRecords` (from FinanceReportRuns.Parameters JSON), `FindDiscrepancy`, `LevelId`, `ErrorMsg`, `BitgoValue`, `BloxValue`

**Rules**:
- Reads ProcessAllRecords from the run's Parameters JSON via JSON_VALUE(frr.Parameters, '$.ProcessAllRecords')
- When ProcessAllRecords = false (0): the pruning logic executes
- For each record in the TVP, finds the PREVIOUS record for the same WalletId+CryptoId (CROSS APPLY TOP 1 ORDER BY Created DESC WHERE Created < current)
- Compares: FindDiscrepancy, LevelId, ErrorMsg, BitgoValue, BloxValue
- If ALL five fields are identical (Changed=0): the current run's record is DELETED from FinanceReportRecords
- When ProcessAllRecords = true (1): pruning is skipped entirely, all records are kept
- **POTENTIAL BUG**: The DELETE JOIN condition has `l.CryptoId = l.CryptoId` (self-join on #Last instead of cross-table join) -- this may cause incorrect pruning behavior. Should likely be `l.CryptoId = frr.CryptoId`.

**Diagram**:
```
@BalanceUpdates (TVP)
  |
  | Copy to #BalanceUpdates
  | Create indexes
  v
Check run Parameters JSON
  |
  | ProcessAllRecords = false?
  |     NO: Skip to UPDATE
  |     YES: Pruning logic:
  |           |
  |           | For each record in this run:
  |           |   Find PREVIOUS record (same wallet+crypto, earlier Created)
  |           |   Compare 5 fields
  |           |   If ALL match: DELETE this run's record
  |           v
  |     Pruned set
  v
UPDATE surviving records
  SET FindDiscrepancy, LevelId, ErrorMsg,
      BitgoValue, BloxValue, Retries, LastChecked
```

### 2.2 Verified Result Application

**What**: Updates all surviving (non-pruned) records with the verified API results.

**Columns/Parameters Involved**: `FindDiscrepancy`, `LevelId`, `ErrorMsg`, `BitgoValue`, `BloxValue`, `Retries`, `LastChecked`

**Rules**:
- Joins #BalanceUpdates to FinanceReportRecords on (ReportId, WalletId, CryptoId)
- Updates seven columns (six from TVP + LastChecked = GETUTCDATE())
- The LastChecked timestamp is used by Wallet.CreateNewReportRun's incremental logic to determine when a wallet should be rechecked
- Unlike the legacy UpdateReportRecord, this procedure also sets LastChecked -- enabling the incremental processing optimization

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
| @BalanceUpdates | Wallet.BalanceType | TVP parameter | Receives batch reconciliation results |
| (JSON_VALUE) | Wallet.FinanceReportRuns | READ | Reads Parameters JSON to determine ProcessAllRecords flag |
| (UPDATE/DELETE) | Wallet.FinanceReportRecords | MODIFIER | Updates with verified results; optionally deletes unchanged records |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the application layer after API verification.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpdateReportRecords (procedure)
+-- Wallet.BalanceType (user defined type)
+-- Wallet.FinanceReportRuns (table)
+-- Wallet.FinanceReportRecords (table)
    +-- Wallet.FinanceReportRuns (table) [FK on ReportId]
    +-- Dictionary.FinanceReportLevel (table) [FK on LevelId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.BalanceType | User Defined Type | TVP parameter type for batch reconciliation results |
| Wallet.FinanceReportRuns | Table | READ - reads Parameters JSON to check ProcessAllRecords flag |
| Wallet.FinanceReportRecords | Table | UPDATE/DELETE target - receives verified results, optionally pruned |

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

### 8.1 Execute a TVP update with pruning
```sql
DECLARE @Updates Wallet.BalanceType;

INSERT INTO @Updates (ReportId, WalletId, CryptoId, FindDiscrepancy, LevelId, ErrorMsg, BitgoValue, BloxValue, Retries)
VALUES
    (622, '749DB5AA-3724-47DA-A540-41D3DB8402DC', 64, 0, 1, NULL, 8.20000000, 8.20000000, 0),
    (622, '58F66320-1234-5678-ABCD-EF1234567890', 21, 1, 3, NULL, 50.00000000, 50.00000000, 1);

EXEC Wallet.UpdateReportRecords @BalanceUpdates = @Updates;
-- Records unchanged from the previous run will be pruned (if ProcessAllRecords=false)
```

### 8.2 Check how many records survived pruning
```sql
SELECT COUNT(*) AS SurvivingRecords
FROM Wallet.FinanceReportRecords WITH (NOLOCK)
WHERE ReportId = 622;
```

### 8.3 Compare record counts across recent runs (shows pruning effect)
```sql
SELECT TOP 10 frr.Id AS RunId, frr.StartTime,
       COUNT(rec.Id) AS RecordCount,
       JSON_VALUE(frr.Parameters, '$.ProcessAllRecords') AS ProcessAllRecords
FROM Wallet.FinanceReportRuns frr WITH (NOLOCK)
LEFT JOIN Wallet.FinanceReportRecords rec WITH (NOLOCK) ON rec.ReportId = frr.Id
GROUP BY frr.Id, frr.StartTime, frr.Parameters
ORDER BY frr.Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpdateReportRecords | Type: Stored Procedure | Source: WalletBalancesReportDB/Wallet/Stored Procedures/Wallet.UpdateReportRecords.sql*
