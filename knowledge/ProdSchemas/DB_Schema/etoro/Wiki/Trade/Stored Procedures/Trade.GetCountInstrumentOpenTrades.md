# Trade.GetCountInstrumentOpenTrades

> Counts the number of currently open positions for a specific instrument, used to assess instrument-level activity and enforce position limits.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns count of open positions by InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure counts how many open trading positions exist for a given financial instrument. This is used for operational monitoring (how popular is an instrument?), capacity planning, and potentially for enforcing instrument-level position limits. A high count may trigger risk management attention or infrastructure scaling.

Note that this queries the Trade.Position VIEW (not the base Trade.PositionTbl table), which filters to open positions only (StatusID=1). The view provides the standard filtered access pattern for open positions.

Data flow: Monitoring service or risk engine provides an InstrumentID -> procedure counts open positions in Trade.Position view -> returns the count.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple COUNT aggregation.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | Financial instrument to count open positions for. Filters Trade.Position view. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NumOfOpenTrades | INT | NO | - | CODE-BACKED | Total number of currently open positions for the specified instrument. Count from Trade.Position view (which filters StatusID=1). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Position | Read | Counts open positions filtered by InstrumentID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Monitoring/Risk Services | EXEC | Caller | Checks instrument-level position counts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCountInstrumentOpenTrades (procedure)
└── Trade.Position (view)
    └── Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Source for counting open positions (view filters to StatusID=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Monitoring/Risk Services | External | Instrument activity monitoring |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- No NOLOCK hint - may block under heavy write load
- No SET NOCOUNT ON

---

## 8. Sample Queries

### 8.1 Execute for a specific instrument

```sql
EXEC Trade.GetCountInstrumentOpenTrades @InstrumentID = 1001;
```

### 8.2 Find the most traded instruments

```sql
SELECT InstrumentID, COUNT(*) AS NumOfOpenTrades
FROM Trade.Position WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY COUNT(*) DESC;
```

### 8.3 Check instruments with more than 1000 open positions

```sql
SELECT InstrumentID, COUNT(*) AS NumOfOpenTrades
FROM Trade.Position WITH (NOLOCK)
GROUP BY InstrumentID
HAVING COUNT(*) > 1000
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCountInstrumentOpenTrades | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCountInstrumentOpenTrades.sql*
