# Trade.GetExchangeIDsByTimeUTC

> Returns exchange IDs that are active based on UTC and Australia local time parameters, via a thin wrapper around the Trade.GetExchangeIDsByTime table-valued function.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | ExchangeID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns a list of exchange IDs that are considered active or relevant at a given moment, determined by two time parameters: a global UTC start time and an Australia-specific local start time. It models the concept of "which exchanges are relevant for time-sensitive operations" across global and regional time zones. Without it, callers would need to invoke the underlying TVF directly or duplicate its logic. It exists to provide a simple, consistent API for trading or reporting systems that need to know which exchanges are "in scope" for a given time window. The procedure is called whenever exchange filtering by time is required, such as when generating exchange-aware reports or when executing time-based trading logic that must respect regional market hours.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The procedure delegates all logic to Trade.GetExchangeIDsByTime. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GlobalStartTimeUTC | INT | - | - | CODE-BACKED | Caller-provided UTC start time. Used to determine which exchanges are active in global terms. |
| 2 | @AustraliaStartTimeLocal | INT | - | - | CODE-BACKED | Australia local start time. Used for region-specific exchange selection when Australia market hours matter. |
| 3 | ExchangeID | INT | - | - | CODE-BACKED | Primary output. Exchange identifier returned by the TVF. Each row represents one exchange in scope for the given time parameters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| N/A | Trade.GetExchangeIDsByTime | Function | This procedure calls the TVF and returns its ExchangeID column. All time-based logic lives in the function. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetExchangeIDsByTimeUTC (procedure)
└── Trade.GetExchangeIDsByTime (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetExchangeIDsByTime | Table-Valued Function | Called in SELECT; returns ExchangeID. Parameters passed through. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Not analyzed in this phase | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get exchanges for a given global and Australia local time

```sql
EXEC Trade.GetExchangeIDsByTimeUTC
    @GlobalStartTimeUTC = 1710547200,
    @AustraliaStartTimeLocal = 1710550800;
```

### 8.2 Use result set in an IN clause for downstream query

```sql
DECLARE @GlobalStartTimeUTC INT = 1710547200;
DECLARE @AustraliaStartTimeLocal INT = 1710550800;

SELECT p.PositionID, p.InstrumentID
FROM Trade.PositionTbl p WITH (NOLOCK)
WHERE p.ExchangeID IN (SELECT ExchangeID FROM Trade.GetExchangeIDsByTime(@GlobalStartTimeUTC, @AustraliaStartTimeLocal));
```

### 8.3 Call procedure and join to Exchange lookup for display

```sql
CREATE TABLE #Ex (ExchangeID INT);
INSERT INTO #Ex (ExchangeID) EXEC Trade.GetExchangeIDsByTimeUTC @GlobalStartTimeUTC = 1710547200, @AustraliaStartTimeLocal = 1710550800;

SELECT e.ExchangeID, ex.Name
FROM #Ex e
JOIN Dictionary.Exchange ex WITH (NOLOCK) ON ex.ExchangeID = e.ExchangeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 6.5/10 (Elements: 7/10, Logic: 5/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetExchangeIDsByTimeUTC | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetExchangeIDsByTimeUTC.sql*
