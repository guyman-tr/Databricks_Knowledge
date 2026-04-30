# Trade.Tv_InstrumentToTickerMapping

> Table-valued parameter type for instrument-to-ticker lookup - passes a list of IDs (instrument or ticker mapping IDs) to retrieve ticker mappings.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | ID (bigint) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Tv_InstrumentToTickerMapping carries a list of bigint IDs used for instrument-to-ticker mapping lookups. The single column ID can represent instrument IDs, ticker mapping IDs, or related entity IDs depending on how Trade.GetInstrumentToTickerMapping interprets it.

This type exists to pass a variable list of IDs to GetInstrumentToTickerMapping. Callers avoid building dynamic SQL or comma-separated strings; they pass a TVP and the procedure returns the corresponding ticker mappings.

The type flows from reporting or trading services into Trade.GetInstrumentToTickerMapping. The procedure uses the TVP to filter or JOIN against the instrument-ticker mapping tables and return results.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single-column ID list.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | - | CODE-BACKED | Instrument or ticker mapping identifier |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInstrumentToTickerMapping | @InstrumentID | Parameter (TVP) | Retrieves instrument-to-ticker mapping for given IDs |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrumentToTickerMapping | Stored Procedure | READONLY parameter for ticker mapping lookup |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get ticker mapping for single ID
```sql
DECLARE @InstrumentID Trade.Tv_InstrumentToTickerMapping;
INSERT INTO @InstrumentID (ID) VALUES (12345);
EXEC Trade.GetInstrumentToTickerMapping @InstrumentID = @InstrumentID;
```

### 8.2 Get ticker mappings for multiple IDs
```sql
DECLARE @InstrumentID Trade.Tv_InstrumentToTickerMapping;
INSERT INTO @InstrumentID (ID) VALUES (100), (101), (102);
EXEC Trade.GetInstrumentToTickerMapping @InstrumentID = @InstrumentID;
```

### 8.3 Empty TVP (all mappings - if supported)
```sql
DECLARE @InstrumentID Trade.Tv_InstrumentToTickerMapping;
EXEC Trade.GetInstrumentToTickerMapping @InstrumentID = @InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 6.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Tv_InstrumentToTickerMapping | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.Tv_InstrumentToTickerMapping.sql*
