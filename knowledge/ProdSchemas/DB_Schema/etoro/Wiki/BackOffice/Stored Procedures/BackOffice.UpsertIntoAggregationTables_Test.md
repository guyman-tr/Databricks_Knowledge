# BackOffice.UpsertIntoAggregationTables_Test

> Test orchestrator for the aggregation pipeline: reads high-water marks, batches History.Credit in 6002-row windows, and calls BackOffice.UpsertIntoAggregationTablesAction_Test in a loop until fully caught up.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - reads state from Dictionary.AggregationLastValue |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpsertIntoAggregationTables_Test` is the test/debug variant of the production aggregation orchestrator. It mirrors the logic of `BackOffice.UpsertIntoAggregationTables` (the production version, in Batch 21 - pending documentation) but calls `BackOffice.UpsertIntoAggregationTablesAction_Test` rather than the production `UpsertIntoAggregationTablesAction`.

The orchestrator reads the last processed CreditID and login timestamp from `Dictionary.AggregationLastValue`, determines the current maximum CreditID in `History.Credit`, and loops in batches of 6002 credits until all pending events have been processed. This design enables catch-up processing when the job has fallen behind.

The `_Test` suffix indicates this is not the production scheduler target - it is used for development testing, debugging, and dry-runs to validate aggregation logic without affecting the production aggregation state. However, since it calls `_Test` which likely writes to the same or test tables, its use in non-test environments should be controlled.

---

## 2. Business Logic

### 2.1 High-Water Mark Read

**What**: Reads the last processed CreditID and login timestamp from Dictionary.AggregationLastValue to determine where the next batch starts.

**Rules**:
- `@LastCreditID` from `Dictionary.AggregationLastValue WHERE TableName='History.Credit' AND IncreasingColumnName='CreditID'`
- `@LastLoggedOut` from `Dictionary.AggregationLastValue WHERE TableName='History.Login' AND IncreasingColumnName='LoggedOut'`
- `@MaxCreditID` from `MAX(CreditID) FROM History.Credit` - current end of the event stream

### 2.2 Batched Loop - 6002 Credits Per Iteration

**What**: Processes credits in chunks of up to 6002 to limit transaction size and memory usage.

**Rules**:
- If `@LastCreditID + 6002 >= @MaxCreditID`: this is the final batch, use `@MaxCreditIDToUse = @MaxCreditID`.
- Otherwise: `@MaxCreditIDToUse = @LastCreditID + 6002` (a partial batch).
- For each batch:
  - Computes `@MaxCreditOccurred` from `History.Credit WHERE CreditID = @MaxCreditIDToUse`
  - Computes `@MaxLoginID` from `History.Login WHERE LoggedOut <= @MaxCreditOccurred`
  - Computes `@MaxLoggedOut` from `History.Login WHERE LoginID = @MaxLoginID`
  - EXECs `BackOffice.UpsertIntoAggregationTablesAction_Test` with the batch parameters
- After the last batch (MaxCreditIDToUse = @MaxCreditID), BREAK.

**Diagram**:
```
Read Dictionary.AggregationLastValue -> @LastCreditID, @LastLoggedOut
Read History.Credit MAX -> @MaxCreditID

WHILE (1=1):
  @MaxCreditIDToUse = MIN(@LastCreditID + 6002, @MaxCreditID)
  Lookup @MaxCreditOccurred, @MaxLoginID, @MaxLoggedOut
  EXEC UpsertIntoAggregationTablesAction_Test(@LastCreditID, @LastLoggedOut, @MaxCreditIDToUse, ...)
  IF @MaxCreditIDToUse = @MaxCreditID: BREAK
  @LastCreditID = @MaxCreditIDToUse; @LastLoggedOut = @MaxLoggedOut
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | This procedure is parameterless. All inputs are read from Dictionary.AggregationLastValue and History.Credit at runtime. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LastCreditID, @LastLoggedOut | Dictionary.AggregationLastValue | SELECT source | Reads high-water marks for Credit and Login |
| @MaxCreditID | History.Credit | SELECT source | Gets current maximum CreditID |
| @MaxCreditOccurred | History.Credit | SELECT (by CreditID) | Gets Occurred timestamp for the batch upper bound |
| @MaxLoginID, @MaxLoggedOut | History.Login | SELECT | Gets last login up to @MaxCreditOccurred |
| Batch execution | BackOffice.UpsertIntoAggregationTablesAction_Test | EXEC callee | Core aggregation action (test variant) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No callers found in BackOffice SPs. | - | - | Invoked manually or via test SQL Agent job for aggregation testing/debugging. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpsertIntoAggregationTables_Test (procedure)
+-- Dictionary.AggregationLastValue (table) [SELECT: high-water marks]
+-- History.Credit (table) [SELECT: max CreditID + Occurred per batch]
+-- History.Login (table) [SELECT: max login per batch window]
+-- BackOffice.UpsertIntoAggregationTablesAction_Test (procedure) [EXEC: per-batch action]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AggregationLastValue | Table | SELECT last processed CreditID and Login timestamp |
| History.Credit | Table | SELECT MAX(CreditID) for loop end; SELECT Occurred by CreditID for batch params |
| History.Login | Table | SELECT MAX(LoginID) and LoggedOut for batch login window |
| BackOffice.UpsertIntoAggregationTablesAction_Test | Procedure | EXEC: the actual per-batch aggregation action (test version) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Invoked manually or via test scheduler. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`
- No transaction wrapping at the orchestrator level - each batch is self-contained in the callee
- Batch size: 6002 credits per iteration (hardcoded)
- No error handling in this wrapper - errors propagate from the callee

---

## 8. Sample Queries

### 8.1 Check how far behind the aggregation is

```sql
SELECT
    alv.LastSampleID AS LastCreditID,
    MAX(hc.CreditID) AS CurrentMaxCreditID,
    MAX(hc.CreditID) - alv.LastSampleID AS CreditsToProcess,
    CEILING(CAST(MAX(hc.CreditID) - alv.LastSampleID AS FLOAT) / 6002) AS BatchesRequired
FROM Dictionary.AggregationLastValue alv WITH (NOLOCK)
CROSS JOIN History.Credit hc WITH (NOLOCK)
WHERE alv.TableName = 'History.Credit'
  AND alv.IncreasingColumnName = 'CreditID'
GROUP BY alv.LastSampleID;
```

### 8.2 Run the test orchestrator manually

```sql
EXEC BackOffice.UpsertIntoAggregationTables_Test;
-- Processes all pending credits in 6002-row batches against test aggregation tables.
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object (test variant - not tracked separately from the production procedure).

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 callee analyzed (UpsertIntoAggregationTablesAction_Test) | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpsertIntoAggregationTables_Test | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpsertIntoAggregationTables_Test.sql*
