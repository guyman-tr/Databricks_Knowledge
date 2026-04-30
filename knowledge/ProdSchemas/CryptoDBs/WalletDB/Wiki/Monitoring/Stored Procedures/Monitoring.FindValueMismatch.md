# Monitoring.FindValueMismatch

> Detects inconsistencies in customer eligibility value history by comparing the last two recorded value changes per customer, flagging cases where the old value of the latest record does not match the new value of the prior record.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set of mismatched customer value records |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.FindValueMismatch is an alerting procedure that identifies data integrity issues in the customer eligibility value tracking system. The Eligibility.CustomerValues table records a history of value changes for each customer (identified by Gcid), with each record storing the old value and new value at the time of change. This procedure verifies that the chain of changes is consistent - the OldValue of the most recent change should equal the NewValue of the preceding change.

Without this procedure, silent data corruption in the eligibility value chain could go undetected. If a customer's value history has gaps or overwrites (e.g., due to race conditions or failed partial updates), downstream systems that rely on eligibility values for trading limits or compliance checks would use incorrect data.

The procedure is called by external monitoring tools on a scheduled basis. It scans the last N days (default 7) of changes, using ROW_NUMBER partitioned by Gcid to find the two most recent records per customer, then compares them for consistency.

---

## 2. Business Logic

### 2.1 Value Chain Consistency Check

**What**: Verifies that sequential value changes for a customer form a consistent chain where each change's starting point matches the previous change's ending point.

**Columns/Parameters Involved**: `@NumberOfDays`, `Gcid`, `OldValue`, `NewValue`, `Occured`

**Rules**:
- For each customer (Gcid), the procedure finds the two most recent records ordered by Occured DESC
- Record A (most recent): its OldValue should equal Record B's (prior) NewValue
- If they differ, it indicates a gap or corruption in the value chain
- NULL values in either OldValue or NewValue are excluded (these represent initial value assignments or resets)
- Only changes within the last @NumberOfDays are considered

**Diagram**:
```
Time -->  Record B (prior)     Record A (latest)
          OldValue -> NewValue  OldValue -> NewValue
                         |          |
                         +----------+
                         Must match!
                      If not: MISMATCH ALERT
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumberOfDays | INT | NO | 7 | CODE-BACKED | Lookback window in days from current date. Limits the scan to recent value changes only. Default of 7 days covers a full week of changes for typical monitoring cadence. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Gcid | INT | NO | - | CODE-BACKED | Global Customer ID identifying which customer has the value mismatch. From Eligibility.CustomerValues. |
| 2 | NewTime | DATETIME | NO | - | CODE-BACKED | Timestamp of the most recent value change record (Record A). Indicates when the mismatch was introduced. |
| 3 | OldTime | DATETIME | NO | - | CODE-BACKED | Timestamp of the prior value change record (Record B). The reference point for comparison. |
| 4 | LastOldValue | SQL_VARIANT | YES | - | CODE-BACKED | The OldValue from the most recent record (Record A). This is the "starting point" that should match Record B's ending point. |
| 5 | PriorNewValue | SQL_VARIANT | YES | - | CODE-BACKED | The NewValue from the prior record (Record B). This is the "ending point" that Record A should have started from. When LastOldValue != PriorNewValue, a mismatch is confirmed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Eligibility.CustomerValues | FROM (read) | Reads the full value change history to find the two most recent records per customer |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.FindValueMismatch (procedure)
  └── Eligibility.CustomerValues (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Eligibility.CustomerValues | Table | FROM - reads value change history partitioned by Gcid |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run with default 7-day lookback
```sql
EXEC Monitoring.FindValueMismatch;
```

### 8.2 Check last 30 days for broader analysis
```sql
EXEC Monitoring.FindValueMismatch @NumberOfDays = 30;
```

### 8.3 Investigate a specific customer's value history after mismatch detected
```sql
SELECT Gcid, Occured, OldValue, NewValue
FROM Eligibility.CustomerValues WITH (NOLOCK)
WHERE Gcid = 12345
ORDER BY Occured DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.FindValueMismatch | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.FindValueMismatch.sql*
