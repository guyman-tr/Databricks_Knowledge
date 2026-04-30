# Hedge.Report_TCA_Test

> Development/debugging variant of Report_TCA: executes only the date-range expansion variable dump (returning 8 diagnostic SELECT statements), then immediately RETURNs. The full TCA logic (FULL JOIN on breakdown logs, cost computations, aggregation) is unreachable dead code after the RETURN statement. Used by developers to test date window calculations without running the expensive production query.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Start DATETIME, @End DATETIME; DEBUG only - full TCA logic is dead code after RETURN; no DATA_READER EXECUTE permission |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.Report_TCA_Test` is the debug/development counterpart to `Hedge.Report_TCA`. It was created to let developers test and verify the date range expansion logic (which expands @Start/@End by ±1-2 days for the intermediate queries) without running the full expensive TCA pipeline against the production breakdown log tables.

**Execution behavior**:
1. Computes the 6 expanded date range variables (same as Report_TCA: @StartResponse, @EndResponse, @StartOccurred, @EndOccurred, @StartResponseOccurred, @EndResponseOccurred)
2. Returns 8 diagnostic SELECT statements - one per variable - so the caller can see all computed date ranges
3. Immediately hits `RETURN` - the rest of the procedure body is **never executed**

The subsequent code (spread load, FULL JOIN, cost calculations, temp table creation, final aggregation) is present as reference code but is entirely unreachable. A second `RETURN` appears later in the body (before the #Main section) as an additional safety guard.

**Key difference from Report_TCA**: Report_TCA_Test uses DIRECT table joins (not pre-loaded temp tables #Req/#Res), reflecting the pre-2013 architecture before Yitzchak's refactoring. The dead code in this procedure is therefore an older version of the TCA logic.

**Permission note**: `Report_TCA_Test` does NOT have DATA_READER EXECUTE permission (unlike Report_TCA). Only PROD\BIadmins has VIEW DEFINITION. This confirms it is a developer-only tool not intended for BI analyst consumption.

---

## 2. Business Logic

### 2.1 Active Execution Path (Date Range Debug)

**What**: The only code that actually executes is the variable calculation and result dump.

**Rules**:
- Same expansion logic as Report_TCA:
  - `@StartResponse = @Start - 1 day`
  - `@EndResponse = @End + 1 day`
  - `@StartOccurred = @Start - 1 day`
  - `@EndOccurred = @End + 1 day`
  - `@StartResponseOccurred = @StartResponse - 1 day` = `@Start - 2 days`
  - `@EndResponseOccurred = @EndResponse + 1 day` = `@End + 2 days`
- Returns 8 rows (one per diagnostic SELECT):
  - '@StartResponse', '@EndResponse', '@StartOccurred', '@EndOccurred', '@StartResponseOccurred', '@EndResponseOccurred', '@Start', '@End'
- Hits `RETURN` immediately after the debug output.

### 2.2 Dead Code (Post-RETURN)

**What**: All TCA logic after the first RETURN is unreachable reference code.

**Rules**:
- The FULL JOIN, #A temp table, cost computations, NC index creation, and final aggregation are all present but never execute.
- Notable difference from Report_TCA: uses `FROM Hedge.ExecutionResponseBreakdownLog ... FULL JOIN Hedge.ExecutionRequestBreakdownLog` directly (no pre-load into #Req/#Res temp tables).
- A second `RETURN` before the #Main section provides an additional guard (also unreachable after the first RETURN).
- This dead code shows the pre-2013 architecture and serves as documentation of the TCA logic history.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Start | DATETIME | NO | - | CODE-BACKED | Analysis window start. Used to compute the 6 expanded date range variables that are dumped in the debug output. |
| 2 | @End | DATETIME | NO | - | CODE-BACKED | Analysis window end. Same purpose as @Start. |

Result set (what actually gets returned):

| # | Column 1 | Column 2 | Description |
|---|----------|----------|-------------|
| 1 | '@StartResponse' | value | @Start - 1 day |
| 2 | '@EndResponse' | value | @End + 1 day |
| 3 | '@StartOccurred' | value | @Start - 1 day |
| 4 | '@EndOccurred' | value | @End + 1 day |
| 5 | '@StartResponseOccurred' | value | @Start - 2 days |
| 6 | '@EndResponseOccurred' | value | @End + 2 days |
| 7 | '@Start' | value | Original @Start |
| 8 | '@End' | value | Original @End |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | (none - RETURN before any table access) | - | All table references are in dead code after RETURN |

### 5.2 Referenced By (other objects point to this)

No EXECUTE permission for any data role. PROD\BIadmins holds VIEW DEFINITION. Used by developers debugging the TCA date range logic.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.Report_TCA_Test (procedure)
+-- (no live dependencies - all table references in unreachable dead code after RETURN)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| None (active path) | - | Active code computes date arithmetic only, no table reads |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Developer debugging tool. |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURN after debug output | Dead code guard | Prevents the expensive TCA query from ever executing in this procedure. The full TCA code is present as reference but is completely unreachable. |
| No temp table pre-loading | Historical pattern | Dead code uses direct table FULL JOIN (pre-2013 style), not the #Req/#Res pre-load optimization present in Report_TCA. |
| No DATA_READER EXECUTE | Access restriction | Only developers/admins can run this procedure. BI analysts use Report_TCA instead. |

---

## 8. Sample Queries

### 8.1 Test date range expansion for a given window
```sql
EXEC [Hedge].[Report_TCA_Test]
    @Start = '2026-03-01 00:00:00',
    @End   = '2026-03-07 23:59:59'
-- Returns 8 rows showing all expanded date range variables
-- No TCA data is returned (RETURN exits before any table access)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.Report_TCA_Test | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.Report_TCA_Test.sql*
