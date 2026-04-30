# Trade.AlertForOpenPositionWithStatus2

> Detects positions stuck in StatusID=2 (closed) in Trade.PositionTbl for more than one day, categorizes them by server error code, and emails the trading and DBA teams with remediation guidance.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters - parameterless alert) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure detects positions that are "stuck" in the closing process. When a position closes, its StatusID transitions to 2 in `Trade.PositionTbl`. Normally, closed positions are quickly archived or finalized. If a position remains in PositionTbl with StatusID=2 for more than one day, it indicates a failure in the close finalization pipeline.

Without this alert, stuck positions would accumulate silently, potentially causing data inconsistencies, inaccurate PnL reporting, and customer complaints about positions that appear closed but aren't fully processed.

The procedure builds a comprehensive error code mapping (400+ error codes from 405 to 940) into a temp table, then joins `Trade.PositionTbl` (StatusID=2, CloseOccurred older than 1 day) to `History.PositionFail` to match each stuck position to its failure error code and a human-readable server error description. Results are aggregated by error code, server error, and database error pattern, then emailed as an HTML table. The email subject includes the total count, and the body advises executing `Trade.CloseOpenPositionWithStatus2` to remediate.

---

## 2. Business Logic

### 2.1 Error Code Classification

**What**: Each stuck position's failure reason is classified into a server error code and a database error pattern for grouped diagnosis.

**Columns/Parameters Involved**: `History.PositionFail.ErrorCode`, `History.PositionFail.FailReason`

**Rules**:
- Server error codes range from 405 (LOW_CREDIT) through 940 (MIRROR_SET_SL_FAILURE) - covers the full trading engine error space
- FailReason patterns are analyzed via LIKE clauses to extract standardized database error categories (e.g., "Execution Timeout Expired", "Error closing position limit- Unable to retrieve position data!")
- Special case: FailReason containing "@IsMirror cannot be null" is mapped to ErrorCode -1
- Results are aggregated by (ErrorCode, ServerError, Db_Error) with a count

### 2.2 Email Recipient Resolution

**What**: Email recipients are read from the Maintenance.Feature configuration table.

**Rules**:
- FeatureID=105 in Maintenance.Feature contains the email address list
- Fallback to 'Tradingbackend@etoro.com;dba@etoro.com' in the SELECT
- Empty HTML check prevents sending emails with no data rows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No parameters. Parameterless alert procedure. Sends results via email. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CTE | Trade.PositionTbl | READER | Positions with StatusID=2, CloseOccurred > 1 day ago |
| JOIN | History.PositionFail | READER | Error codes and failure reasons |
| SELECT | Maintenance.Feature | READER | Email address configuration (FeatureID=105) |
| EXEC | msdb.dbo.sp_send_dbmail | System call | Sends HTML email alert |

### 5.2 Referenced By (other objects point to this)

No SQL-level dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AlertForOpenPositionWithStatus2 (procedure)
+-- Trade.PositionTbl (table)
+-- History.PositionFail (table)
+-- Maintenance.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | READER - positions stuck with StatusID=2 |
| History.PositionFail | Table | READER - error codes and failure reasons |
| Maintenance.Feature | Table | READER - email address config |

### 6.2 Objects That Depend On This

No SQL-level dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Error code map | In-memory reference | #ServersError temp table with 100+ error code-to-description mappings covering the full trading engine error space |

---

## 8. Sample Queries

### 8.1 Preview stuck positions

```sql
SELECT  P.PositionID, P.StatusID, P.CloseOccurred, PF.ErrorCode, PF.FailReason
FROM    Trade.PositionTbl P WITH (NOLOCK)
JOIN    History.PositionFail PF WITH (NOLOCK) ON P.PositionID = PF.PositionID
WHERE   P.StatusID = 2
        AND P.CloseOccurred < DATEADD(DAY, -1, GETDATE());
```

### 8.2 Run the alert

```sql
EXEC Trade.AlertForOpenPositionWithStatus2;
```

### 8.3 Aggregate stuck positions by error code

```sql
SELECT  PF.ErrorCode, COUNT(*) AS StuckCount
FROM    Trade.PositionTbl P WITH (NOLOCK)
JOIN    History.PositionFail PF WITH (NOLOCK) ON P.PositionID = PF.PositionID
WHERE   P.StatusID = 2 AND P.CloseOccurred < DATEADD(DAY, -1, GETDATE())
GROUP BY PF.ErrorCode
ORDER BY StuckCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AlertForOpenPositionWithStatus2 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AlertForOpenPositionWithStatus2.sql*
