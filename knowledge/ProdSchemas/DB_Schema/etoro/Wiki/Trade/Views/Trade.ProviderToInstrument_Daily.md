# Trade.ProviderToInstrument_Daily

> Simple SELECT * wrapper on Trade.ProviderToInstrument providing a stable access point for daily batch processes and cross-database linked server queries.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | ProviderID, InstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.ProviderToInstrument_Daily is a pass-through view that exposes all columns from Trade.ProviderToInstrument via SELECT *. It provides no filtering, aggregation, or transformation. Each row represents the provider-instrument configuration (precision, spreads, leverage limits, trading flags, etc.) for a given (ProviderID, InstrumentID) pair. The view exists as a stable abstraction for daily batch processes and BI consumers, particularly when accessed via linked servers across databases.

Without this view, consumers would query Trade.ProviderToInstrument directly. The _Daily suffix suggests this view was created for ETL or reporting pipelines that run on a daily schedule and need a consistent object reference. The wrapper may also isolate consumers from future schema changes if the base table is refactored - the view could be updated to map columns while preserving the interface.

The view performs a single SELECT * FROM Trade.ProviderToInstrument. No NOLOCK hint in the base definition; callers may add WITH (NOLOCK) in their queries if needed.

---

## 2. Business Logic

No business logic. Direct SELECT * from Trade.ProviderToInstrument. All columns and rows pass through unchanged.

---

## 3. Data Overview

N/A - output mirrors Trade.ProviderToInstrument. See [Trade.ProviderToInstrument](../Tables/Trade.ProviderToInstrument.md) for data overview.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | 0 | CODE-BACKED | Part of PK. Provider identifier. |
| 2 | InstrumentID | int | NO | 0 | CODE-BACKED | Part of PK. FK to Trade.Instrument. |
| 3 | (all other ProviderToInstrument columns) | (varies) | (varies) | - | CODE-BACKED | Precision, UnitMargin, AllowedRateDiffPercentage, Enabled, AllowBuy, AllowSell, etc. See Trade.ProviderToInstrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Explicit FK | Via ProviderToInstrument |
| ProviderID | (Provider) | Implicit FK | Provider reference |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ProviderToInstrument_Daily (view)
    |
    +-- Trade.ProviderToInstrument (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - source table, SELECT * |

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

### 8.1 All provider-instrument configurations

```sql
SELECT *
FROM Trade.ProviderToInstrument_Daily WITH (NOLOCK);
```

### 8.2 Enabled instruments for a provider

```sql
SELECT ProviderID, InstrumentID, Precision, Enabled
FROM Trade.ProviderToInstrument_Daily WITH (NOLOCK)
WHERE ProviderID = @ProviderID AND Enabled = 1;
```

### 8.3 Configuration for specific instrument

```sql
SELECT *
FROM Trade.ProviderToInstrument_Daily WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ProviderToInstrument_Daily | Type: View | Source: etoro/etoro/Trade/Views/Trade.ProviderToInstrument_Daily.sql*
