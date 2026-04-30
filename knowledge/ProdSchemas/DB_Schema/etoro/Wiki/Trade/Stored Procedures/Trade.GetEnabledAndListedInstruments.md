# Trade.GetEnabledAndListedInstruments

> Returns InstrumentIDs of all instruments that are both enabled at a provider and tradable, optionally filtered by OME instance number.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstanceNumber (optional OME filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetEnabledAndListedInstruments returns the list of instruments that are currently both enabled for trading at a provider (ProviderToInstrument.Enabled=1) and marked as tradable in the instrument metadata (InstrumentMetaData.Tradable=1). Optionally, results can be filtered by OME (Order Matching Engine) instance number.

This procedure exists because the trading engine needs to know which instruments are available for trading on each OME instance. An instrument must be both enabled at the provider level AND tradable at the metadata level to accept orders. This is typically called during service startup or instrument cache refresh.

Data flows from Trade.ProviderToInstrument (provider-level enablement) joined with Trade.InstrumentMetaData (tradability flag) and Trade.Instrument (OME assignment). Uses READ UNCOMMITTED isolation for maximum throughput.

---

## 2. Business Logic

### 2.1 Dual Enablement Check

**What**: An instrument must pass two independent checks to be returned as tradable.

**Columns/Parameters Involved**: `Enabled`, `Tradable`, `OMEID`, `@InstanceNumber`

**Rules**:
- ProviderToInstrument.Enabled = 1: provider has enabled this instrument for trading
- InstrumentMetaData.Tradable = 1: instrument metadata allows trading
- Both conditions must be true for the instrument to be returned
- If @InstanceNumber IS NOT NULL: additionally filters by Trade.Instrument.OMEID = @InstanceNumber
- If @InstanceNumber IS NULL: returns all enabled+tradable instruments across all OME instances

**Diagram**:
```
Trade.ProviderToInstrument (Enabled=1)
  |
  INNER JOIN Trade.InstrumentMetaData (Tradable=1)
  |
  INNER JOIN Trade.Instrument (OMEID = @InstanceNumber, if provided)
  |
  Output: InstrumentID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstanceNumber | int | YES | NULL | CODE-BACKED | OME (Order Matching Engine) instance number to filter by. NULL returns all instances. Modified per TRAD-2888 to support nullable. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Instrument that is both enabled at a provider and tradable. FK to Trade.Instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.ProviderToInstrument | FROM | Provider-level enablement |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Tradability flag |
| InstrumentID, OMEID | Trade.Instrument | JOIN | OME instance assignment |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetEnabledAndListedInstruments (procedure)
+-- Trade.ProviderToInstrument (table)
+-- Trade.InstrumentMetaData (table)
+-- Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - provider enablement check |
| Trade.InstrumentMetaData | Table | JOIN - tradability check |
| Trade.Instrument | Table | JOIN - OME instance filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | Called by trading engine for instrument cache |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Uses SET TRAN ISOLATION LEVEL READ UNCOMMITTED for maximum throughput. Modified 27-Aug-2020 by Yitzchak per TRAD-2888 to support nullable @InstanceNumber.

---

## 8. Sample Queries

### 8.1 Get all enabled and listed instruments

```sql
EXEC Trade.GetEnabledAndListedInstruments;
```

### 8.2 Get instruments for a specific OME instance

```sql
EXEC Trade.GetEnabledAndListedInstruments @InstanceNumber = 1;
```

### 8.3 Direct query with instrument names

```sql
SELECT  p2i.InstrumentID, m.SymbolFull
FROM    Trade.ProviderToInstrument p2i WITH (NOLOCK)
INNER JOIN Trade.InstrumentMetaData m WITH (NOLOCK) ON p2i.InstrumentID = m.InstrumentID
INNER JOIN Trade.Instrument ti WITH (NOLOCK) ON p2i.InstrumentID = ti.InstrumentID
WHERE   p2i.Enabled = 1
        AND m.Tradable = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetEnabledAndListedInstruments | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetEnabledAndListedInstruments.sql*
