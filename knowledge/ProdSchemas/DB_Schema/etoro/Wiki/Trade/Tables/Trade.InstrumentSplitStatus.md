# Trade.InstrumentSplitStatus

> Tracks instruments that are in an active or pending stock split, associating each instrument with a SplitID and a workflow status. Used by split activation and instrument-listing logic.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (INT, PK CLUSTERED) |
| **Row Count** | 34 |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

Trade.InstrumentSplitStatus records which instruments are currently undergoing or have recently undergone a corporate split event. Each row links an InstrumentID to a SplitID (from History.SplitRatio) and a Status that indicates where the instrument stands in the split workflow (e.g., in progress, completed).

This table supports the split activation pipeline: when a stock splits (e.g., 4:1), positions must be adjusted, open orders may be closed or modified, and the instrument’s price/amount ratios are updated in History.SplitRatio. InstrumentSplitStatus allows procedures like Trade.GetInstrumentInSplit to quickly identify instruments with Status &lt; 10 (active/pending splits) without scanning History.SplitRatio.

Data is maintained as part of the split lifecycle (Trade.ActivateSplit, History.SplitRatio). Trade.GetInstrumentInSplit reads rows where Status &lt; 10 and returns InstrumentID and Status for downstream consumers.

---

## 2. Business Logic

### 2.1 Split Status Values

**What**: Status indicates the split workflow stage.

**Columns/Parameters Involved**: `Status`, `InstrumentID`, `SplitID`

**Rules**:
- **Status &lt; 10**: Instrument is in an active or pending split (returned by Trade.GetInstrumentInSplit)
- **Status = 10**: Split completed or not active (instrument not returned by GetInstrumentInSplit)
- Status = 1 observed for instruments with in-progress splits; Status = 10 for completed
- One row per InstrumentID (PK); multiple instruments can share the same SplitID

**Diagram**:
```
Status values:
  1  ──► Active/Pending split (returned by GetInstrumentInSplit)
  10 ──► Completed / Inactive (filtered out)
```

### 2.2 Instrument-to-Split Mapping

**What**: Each instrument in a split is tied to the same History.SplitRatio event.

**Columns/Parameters Involved**: `InstrumentID`, `SplitID`

**Rules**:
- SplitID references History.SplitRatio.ID (logical FK)
- PK is InstrumentID only; SplitID and Status are attributes
- GetInstrumentInSplit filters WHERE Status &lt; 10

---

## 3. Data Overview

| InstrumentID | SplitID | Status | Meaning |
|--------------|---------|--------|---------|
| 1002 | 9628 | 10 | Completed split |
| 1003 | 7250 | 10 | Completed split |
| 1004 | 9630 | 10 | Completed split |
| 1007 | 8808 | 1 | Active/pending split |
| 1010 | 8809 | 1 | Active/pending split |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Instrument in split. References Trade.Instrument.InstrumentID |
| 2 | SplitID | int | NO | - | VERIFIED | Split event ID from History.SplitRatio |
| 3 | Status | int | NO | - | CODE-BACKED | Workflow status: &lt;10 = active/pending, 10 = completed |

---

## 5. Relationships

### 5.1 References To

| Referenced Table | Column | Relationship |
|------------------|--------|--------------|
| Trade.Instrument | InstrumentID | Implicit; instruments must exist |
| History.SplitRatio | SplitID (ID) | Implicit; SplitID identifies the split event |

### 5.2 Referenced By

| Referencing Object | Column | Type |
|--------------------|--------|------|
| Trade.GetInstrumentInSplit | InstrumentSplitStatus | Reader—returns InstrumentID, Status WHERE Status &lt; 10 |

---

## 6. Dependencies

### 6.0 Chain

```
History.SplitRatio ──► Trade.InstrumentSplitStatus
Trade.Instrument  ──► Trade.InstrumentSplitStatus
```

### 6.1 Depends On

| Object | Purpose |
|--------|---------|
| Trade.Instrument | InstrumentID domain |
| History.SplitRatio | SplitID (split event) |

### 6.2 Depended On By

| Object | Purpose |
|--------|---------|
| Trade.GetInstrumentInSplit | Returns instruments with active splits (Status &lt; 10) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included | Fill Factor | Status |
|------------|------|-------------|----------|-------------|--------|
| PK_InstrumentSplitStatus | CLUSTERED | InstrumentID ASC | - | 90 | Active |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK_InstrumentSplitStatus | PRIMARY KEY | InstrumentID |

---

## 8. Sample Queries

```sql
SELECT InstrumentID, SplitID, Status
FROM Trade.InstrumentSplitStatus WITH (NOLOCK)
WHERE Status < 10
ORDER BY InstrumentID;

SELECT COUNT(*) AS TotalInSplit
FROM Trade.InstrumentSplitStatus WITH (NOLOCK);

SELECT iss.InstrumentID, iss.SplitID, iss.Status, sr.MinDate, sr.PriceRatio
FROM Trade.InstrumentSplitStatus iss WITH (NOLOCK)
JOIN History.SplitRatio sr WITH (NOLOCK) ON sr.ID = iss.SplitID
WHERE iss.Status < 10
ORDER BY iss.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

- No Jira/Confluence references found in this documentation pass.

---

*Generated: 2026-03-14 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
