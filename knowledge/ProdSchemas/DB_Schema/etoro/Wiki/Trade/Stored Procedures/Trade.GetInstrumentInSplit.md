# Trade.GetInstrumentInSplit

> Returns instruments currently undergoing a stock split - those with an active (non-complete) split status.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns all instruments that have an active stock split in progress. Stock splits require special handling by the trading engine - positions must be adjusted (units multiplied, rates divided), and new orders may need to be suspended during the split window. This SP identifies which instruments are currently in that state.

The procedure exists to allow the trading engine and monitoring systems to check which instruments are mid-split. Status values < 10 indicate active/in-progress splits, while status >= 10 indicates completed splits. The ordered result by InstrumentID supports binary search in consumers.

Data flow: no parameters. Reads Trade.InstrumentSplitStatus filtered by Status < 10. Returns InstrumentID and Status ordered by InstrumentID.

---

## 2. Business Logic

### 2.1 Active Split Status Filter

**What**: Only returns splits that are in progress, not completed.

**Columns/Parameters Involved**: `Status`

**Rules**:
- Status < 10: split is in progress (various stages of the split workflow)
- Status >= 10: split is complete (historically tracked but no longer active)
- The exact status values represent split lifecycle stages in Trade.InstrumentSplitStatus

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID (output) | INT | NO | - | CODE-BACKED | Instrument currently undergoing a stock split. FK to Trade.Instrument. |
| 2 | Status (output) | INT | NO | - | CODE-BACKED | Split workflow status. Values < 10 indicate active/in-progress stages. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.InstrumentSplitStatus | FROM | Source of active split statuses |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentInSplit (procedure)
+-- Trade.InstrumentSplitStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentSplitStatus | Table | FROM - filtered by Status < 10 |

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

### 8.1 Execute to see active splits

```sql
EXEC Trade.GetInstrumentInSplit;
```

### 8.2 Check all split statuses

```sql
SELECT  InstrumentID, Status
FROM    Trade.InstrumentSplitStatus WITH (NOLOCK)
ORDER BY InstrumentID;
```

### 8.3 Join with instrument names

```sql
SELECT  iss.InstrumentID, imd.InstrumentDisplayName, iss.Status
FROM    Trade.InstrumentSplitStatus iss WITH (NOLOCK)
JOIN    Trade.InstrumentMetaData imd WITH (NOLOCK) ON iss.InstrumentID = imd.InstrumentID
WHERE   iss.Status < 10;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentInSplit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentInSplit.sql*
