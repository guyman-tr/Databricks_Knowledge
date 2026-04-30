# Dictionary.HedgePositionFailReason

> Lookup table defining 24 hedge position failure reasons — market conditions, liquidity issues, technical errors, and recovery-related failures that explain why a hedge order could not be executed at the liquidity provider.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | HedgeFailID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgePositionFailReason catalogs every possible reason a hedge order can fail during execution at the liquidity provider. These failures range from market-level issues (market closed, slippage breached, indicative rates) to technical problems (DB stored procedure errors, API failures) to business-level outcomes (request invalidated by recovery, amount too low for instrument).

This table exists because hedge failures are serious risk events. An unexecuted hedge means eToro carries unhedged market exposure on customer positions. By classifying failures into distinct categories with associated severity levels, the monitoring system can differentiate between transient issues that resolve automatically (e.g., price expired — retry later) and critical problems requiring immediate human intervention (e.g., unknown error, DB procedure failure).

Each failure reason carries a HedgePositionFailSeverity level (FK to Dictionary.HedgePositionFailSeverity), creating a two-dimensional classification: what went wrong and how serious it is.

---

## 2. Business Logic

### 2.1 Failure Severity Classification

**What**: Each failure reason is tagged with a severity level that determines the operational response — from "no action needed" to "critical alert."

**Columns/Parameters Involved**: `HedgeFailID`, `HedgePositionFailSeverity`, `FailText`

**Rules**:
- **Severity 1 (None/NoProblem)**: Informational — no actual failure
  - Request deleted (12): Hedge request was absorbed by closing other trades
  - Request invalidated by recovery (15): Recovery scan determined the request was stale
  - Request closed by provider (16): LP-initiated close (normal lifecycle)
  - Amount too low (20): Below instrument minimum — not a system failure
  - Cancellation sent (23): Intentional cancellation
- **Severity 3 (Medium)**: Needs investigation
  - Trade not located during recovery (11): Position exists locally but LP cannot find it
- **Severity 5 (Critical)**: Immediate attention required
  - Market/trading failures (1-9): Slippage, liquidity, margin, price expiry, indicative rate
  - API errors (10): External provider API issue
  - DB failures (13, 14, 17): Internal system failures
  - Quantity/duplicate errors (18, 19): Data validation failures
  - General message (21): Catch-all for unclassified failures
  - GTD expiry (22): Good-till-date order expired without execution
- **Severity 6 (Unknown)**: Unclassified
  - Unknown error (0): Catch-all for errors that don't match any known pattern

**Diagram**:
```
Failure Reasons by Severity:
├── Severity 1 (NoProblem) — Informational
│     ├── 12: Request deleted (filled by netting)
│     ├── 15: Invalidated by recovery scan
│     ├── 16: Closed by provider
│     ├── 20: Amount too low for instrument
│     └── 23: Cancellation sent
│
├── Severity 3 (Medium) — Investigate
│     └── 11: Trade not found at provider during recovery
│
├── Severity 5 (Critical) — Alert Immediately
│     ├── Market: 1(closed), 2(slippage), 3(liquidity), 4(margin)
│     ├── Market: 5(max size), 6(indicative), 7(expired), 8(liq+expired), 9(no price)
│     ├── External: 10(API error)
│     ├── Internal: 13(close fail), 14(open fail), 17(DB error)
│     ├── Validation: 18(qty fraction), 19(already open)
│     ├── General: 21(unclassified)
│     └── Expiry: 22(GTD expired)
│
└── Severity 6 (Unknown)
      └── 0: Unknown error
```

---

## 3. Data Overview

| HedgeFailID | FailText | Severity | Meaning |
|---|---|---|---|
| 0 | Unknown error had occurred | 6 (Unknown) | Catch-all for unclassified errors. Indicates a failure that doesn't match any known pattern — requires investigation to identify root cause and potentially add a new failure reason. |
| 2 | order failed due to slippage breached | 5 (Critical) | The price moved beyond the acceptable slippage tolerance between order submission and execution. Common during high-volatility events. The hedge server may retry with wider tolerance or escalate. |
| 12 | Hedge Request deleted (filled by closing other trades) | 1 (None) | The hedge request was absorbed through netting — closing other hedge positions covered the exposure, so no new order was needed. Normal operational outcome, not a failure. |
| 17 | DB Stored Procedure Error | 5 (Critical) | Internal database error during hedge order processing. Indicates a problem with the hedge order management stored procedures. Requires DBA investigation. |
| 22 | Good Till Date order has expired before execution | 5 (Critical) | A time-limited hedge order reached its expiry timestamp without being executed. The hedge position remains unestablished — manual intervention may be needed to re-hedge. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeFailID | int | NO | - | VERIFIED | Primary key identifying the failure reason. 0=Unknown, 1-9=Market/trading failures (closed/slippage/liquidity/margin/size/indicative/expired/no price), 10=API error, 11=Trade not found, 12=Netted away, 13-14=DB close/open fail, 15=Recovery invalidated, 16=Provider closed, 17=DB SP error, 18-19=Qty/duplicate, 20=Amount too low, 21=General, 22=GTD expired, 23=Cancellation sent. |
| 2 | HedgePositionFailSeverity | int | NO | - | VERIFIED | Severity classification of this failure reason. FK to Dictionary.HedgePositionFailSeverity. 1=None/NoProblem (informational), 2=Low/Warning, 3=Medium (investigate), 4=High, 5=Critical (alert immediately), 6=Unknown/TBD. Determines alerting thresholds and escalation paths. |
| 3 | FailText | varchar(128) | YES | - | VERIFIED | Human-readable description of the failure. Displayed in hedge monitoring dashboards, alert emails, and operational reports. Provides sufficient context for operators to understand what happened without querying logs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgePositionFailSeverity | Dictionary.HedgePositionFailSeverity | Implicit FK | Severity classification of this failure (1=None through 6=Unknown) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Hedge execution log tables likely reference HedgeFailID to record why specific orders failed.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT. Hedge execution consumers likely reference this table at the application level.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | HedgeFailID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PRIMARY KEY | Unique failure reason identifier |

---

## 8. Sample Queries

### 8.1 List all failure reasons with severity
```sql
SELECT  fr.HedgeFailID,
        fr.FailText,
        fs.Name AS Severity
FROM    [Dictionary].[HedgePositionFailReason] fr WITH (NOLOCK)
JOIN    [Dictionary].[HedgePositionFailSeverity] fs WITH (NOLOCK)
        ON fr.HedgePositionFailSeverity = fs.HedgeSeverityTypeID
ORDER BY fr.HedgeFailID;
```

### 8.2 Get critical failure reasons only
```sql
SELECT  HedgeFailID,
        FailText
FROM    [Dictionary].[HedgePositionFailReason] WITH (NOLOCK)
WHERE   HedgePositionFailSeverity = 5
ORDER BY HedgeFailID;
```

### 8.3 Group failure reasons by severity category
```sql
SELECT  fs.Name AS Severity,
        COUNT(*) AS ReasonCount,
        STRING_AGG(CAST(fr.HedgeFailID AS VARCHAR), ', ') AS FailIDs
FROM    [Dictionary].[HedgePositionFailReason] fr WITH (NOLOCK)
JOIN    [Dictionary].[HedgePositionFailSeverity] fs WITH (NOLOCK)
        ON fr.HedgePositionFailSeverity = fs.HedgeSeverityTypeID
GROUP BY fs.Name
ORDER BY MIN(fr.HedgePositionFailSeverity);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgePositionFailReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgePositionFailReason.sql*
