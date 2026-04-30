# Trade.Report_PositionsFailSummary

> Produces a multi-result-set analytical report on position operation success rates for CySEC-regulated customers over a date range, breaking down failures into justified vs. unjustified categories and by session type (manual TAPI vs. automated system).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate + @EndDate (reporting window) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.Report_PositionsFailSummary generates a position operations quality report scoped to CySEC-regulated customers (BackOffice.Customer.RegulationID=1). It calculates success rates for position open/close and edit operations over a date range, classifies failures as "justified" (expected system rejections per Dictionary.Justefied patterns) vs. "unjustified" (unexpected failures), and splits results by user action type (TAPI manual trades vs. automated system operations).

This procedure exists to support regulatory reporting and operational quality monitoring. CySEC compliance requires tracking execution quality. The justified/unjustified split distinguishes between expected failures (e.g., insufficient balance, market closed) from unexpected technical failures that need investigation. The TAPI vs. System split identifies whether failures affect user-initiated trades or automated processes.

Data flow: Called by BI/reporting tools with a date range. Sources: History.PositionFail (failed position attempts), History.PositionChangeLog_Active (successful position changes), Dictionary.Justefied (pattern-match list of justified error patterns), BackOffice.Customer (CySEC filter). Returns 5 result sets in sequence: justified failures, unjustified failures, edit failure counts, summary success rates, detailed breakdown.

---

## 2. Business Logic

### 2.1 FailReason Normalization

**What**: Before grouping failures, all numeric digits are stripped from FailReason strings to normalize error messages that contain variable data (e.g., position IDs, amounts).

**Columns/Parameters Involved**: `FailReason`

**Rules**:
- Replaces digits 0-9 with 'x', then collapses repeated 'x' sequences: 'xx'->'x', 'xxx'->'x'.
- Also normalizes 'x.x'->'x' (decimal numbers) and '-x'->'x' (negative numbers).
- Example: "Position 12345 insufficient balance 100.50" -> "Position x insufficient balance x".
- This allows GROUP BY on normalized FailReason to aggregate similar errors that differ only in their embedded numbers.

### 2.2 Justified vs. Unjustified Failure Classification

**What**: Dictionary.Justefied holds LIKE patterns that identify expected/acceptable failure reasons. Failures matching any pattern are "justified"; non-matching are "unjustified."

**Columns/Parameters Involved**: `FailReason`, `Dictionary.Justefied.Name`

**Rules**:
- Inner JOIN to Dictionary.Justefied WHERE TypeName LIKE Name -> justified failure.
- WHERE NOT EXISTS (SELECT 1 FROM Dictionary.Justefied WHERE TypeName LIKE Name) -> unjustified failure.
- Justified failures don't reduce the success rate denominator - they are expected and excluded from "real" failure count.
- Success rate formula: (Overall - Unjustified Failure) / Overall * 100.0

### 2.3 Session Type Segmentation (TAPI vs. System)

**What**: SessionID distinguishes user-initiated trades from automated system operations.

**Columns/Parameters Involved**: `SessionID`

**Rules**:
- SessionID > 0: TAPI (Trading API) - user-initiated manual trades.
- SessionID < 0: System/Non-Manual - automated operations (margin calls, automated closures, etc.).
- SessionID = 0 or NULL: Legacy/Old Trading (commented out in current version - excluded from results).
- All success/failure counts are split into these two columns in the output.

### 2.4 Output Result Sets (5 in sequence)

**What**: The procedure returns 5 SELECT result sets that together form a complete quality report.

**Columns/Parameters Involved**: Multiple

**Rules**:
- Result Set 1: Justified failures list (TypeName, justified TAPI count, justified System count).
- Result Set 2: Failure count for edit operations by session type (inline SELECT from #Details for 'Failure to Edit Position').
- Result Set 3: Unjustified failures list (normalized FailReason, unjustified TAPI count, unjustified System count) ordered by TAPI count descending.
- Result Set 4: #Summary - success rates: Open/Close Success Rate %, 7 Days rate (incomplete/placeholder), Edit Success Rate %, 7 Days Edit rate (incomplete/placeholder).
- Result Set 5: #Details - row-level breakdown: Overall attempts, success counts, justified failures, unjustified failures (both open/close and edit categories).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | NO | - | CODE-BACKED | Start of the reporting window (inclusive). Applied to History.PositionFail.OpenOccurred and History.PositionChangeLog_Active.Occurred via BETWEEN. |
| 2 | @EndDate | datetime | NO | - | CODE-BACKED | End of the reporting window (inclusive). Applied as BETWEEN upper bound to the same columns. |

**Output (multiple result sets):**

| # | Result Set | Columns | Description |
|---|-----------|---------|-------------|
| 3 | RS1: Justified Failures | TypeName, justified TAPI, justified all | Failure patterns matched in Dictionary.Justefied, split by session type. |
| 4 | RS2: Edit Failure Counts | Manaual Actions - TAPI, Non-Manual Action | Count of unjustified edit position failures by session type. |
| 5 | RS3: Unjustified Failures | TypeName, unjust TAPI, unjust all | Failure patterns NOT in Dictionary.Justefied, ordered by TAPI count DESC. |
| 6 | RS4: Summary | Description, Manaual Actions - TAPI, Non-Manual Action | Success rates (%) for Open/Close and Edit operations. |
| 7 | RS5: Details | Description, Manaual Actions - TAPI, Non-Manual Action | Row-per-category breakdown: attempts, successes, justified, unjustified failures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HPOF.CID | History.PositionFail | Reader (SELECT) | Source of position failure events. Filtered to date range and CySEC customers. |
| BC.RegulationID=1 | BackOffice.Customer | JOIN | Restricts to CySEC-regulated customers only. |
| cl.ChangeTypeID | History.PositionChangeLog_Active | Reader (SELECT) | Source of successful position change events. |
| ChangeTypeID | Dictionary.PCL_ChangeType | JOIN | Resolves ChangeTypeID to ChangeTypeName for success categorization. |
| FailReason | Dictionary.Justefied | LIKE JOIN | Classifies failures as justified (matched) vs. unjustified (unmatched). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BI/reporting tools for regulatory reporting.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Report_PositionsFailSummary (procedure)
├── History.PositionFail (table)
├── BackOffice.Customer (table)
├── History.PositionChangeLog_Active (table)
├── Dictionary.PCL_ChangeType (table)
└── Dictionary.Justefied (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionFail | Table | Reads failed position events for the date range; filters to CySEC customers (RegulationID=1) and OrderID IS NULL. |
| BackOffice.Customer | Table | JOIN to filter to CySEC-regulated customers (RegulationID=1). |
| History.PositionChangeLog_Active | Table | Reads successful position change events for the date range; filters to CySEC customers. |
| Dictionary.PCL_ChangeType | Table | JOIN to resolve ChangeTypeID to ChangeTypeName (distinguishes open/close from edit operations). |
| Dictionary.Justefied | Table | LIKE pattern-match to classify failures as justified (expected) vs. unjustified. |

### 6.2 Objects That Depend On This

No dependents found. Called directly by BI/reporting tools.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: The "7 Days" section (lines ~319 onwards) creates placeholder temp tables (#AllSuccess_7Days, #AllFailure_7Days) but only partially implements the 7-day reporting logic - those summary rows remain at 0.0% in #Summary. The unjustified failure rate calculation in RS3 uses a hardcoded divisor of 0 in a CASE statement that always resolves to 1 (defensive divide-by-zero protection).

---

## 8. Sample Queries

### 8.1 Run the full position fail summary report

```sql
EXEC Trade.Report_PositionsFailSummary
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-31';
-- Returns 5 result sets: justified failures, edit failures, unjustified failures, summary rates, details
```

### 8.2 Quick failure preview without the procedure

```sql
SELECT TOP 20
    HPOF.FailReason,
    COUNT(*) AS FailCount,
    CASE WHEN LOWER(HPOF.FailReason) LIKE '%error editing%' THEN 1 ELSE 0 END AS IsEditFail,
    CASE WHEN HPOF.SessionID > 0 THEN 'TAPI' WHEN HPOF.SessionID < 0 THEN 'System' ELSE 'Other' END AS SessionType
FROM History.PositionFail HPOF WITH (NOLOCK)
JOIN BackOffice.Customer BC WITH (NOLOCK) ON HPOF.CID = BC.CID AND BC.RegulationID = 1
WHERE HPOF.OpenOccurred BETWEEN '2026-01-01' AND '2026-03-31'
    AND HPOF.OrderID IS NULL
GROUP BY HPOF.FailReason, HPOF.SessionID,
    CASE WHEN LOWER(HPOF.FailReason) LIKE '%error editing%' THEN 1 ELSE 0 END
ORDER BY COUNT(*) DESC;
```

### 8.3 View justified failure patterns

```sql
SELECT Name AS JustifiedPattern
FROM Dictionary.Justefied WITH (NOLOCK)
ORDER BY Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Report_PositionsFailSummary | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Report_PositionsFailSummary.sql*
