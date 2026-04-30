# Trade.InstrumentMetaData_Daily

> Simple SELECT * wrapper on Trade.InstrumentMetaData providing a stable access point for daily batch processes and BI.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.InstrumentMetaData_Daily is a thin wrapper around Trade.InstrumentMetaData that exposes all columns via SELECT *. It serves as a stable access point for daily batch processes and Business Intelligence (BI) consumers, potentially for cross-database linked server queries where a view reference is preferred over direct table access.

This view exists because some consumers require a fixed interface that does not change when the base table adds or removes columns. By querying the view, callers get a stable contract. Additionally, linked server queries often use views as entry points to isolate schema changes. The _Daily suffix suggests it is intended for batch or scheduled workloads rather than real-time trading.

The view definition is `Select * From Trade.InstrumentMetaData a` - a single-table projection with no filters. Output mirrors InstrumentMetaData exactly.

---

## 2. Business Logic

No complex business logic. This is a direct projection from Trade.InstrumentMetaData.

---

## 3. Data Overview

N/A - output mirrors Trade.InstrumentMetaData. See [Trade.InstrumentMetaData](../Tables/Trade.InstrumentMetaData.md) for data overview.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| * | (all columns) | - | - | - | CODE-BACKED | All columns from Trade.InstrumentMetaData. See base table documentation for full element list. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit FK | Via InstrumentMetaData.InstrumentID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentMetaData_Daily (view)
    |
    +-- Trade.InstrumentMetaData (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | FROM - source of all columns |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Full snapshot for daily batch
```sql
SELECT *
FROM Trade.InstrumentMetaData_Daily WITH (NOLOCK)
WHERE Tradable = 1
ORDER BY InstrumentID
```

### 8.2 Tradable instruments for BI extract
```sql
SELECT InstrumentID, InstrumentDisplayName, SymbolFull, Tradable
FROM Trade.InstrumentMetaData_Daily WITH (NOLOCK)
WHERE Tradable = 1
```

### 8.3 Linked server style query
```sql
SELECT *
FROM [LinkedServer].[Database].Trade.InstrumentMetaData_Daily WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentMetaData_Daily | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentMetaData_Daily.sql*
