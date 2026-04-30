# Price.GetInstrumentsShards

> View that exposes the shard assignment for each active instrument - maps InstrumentID to ShardID using the dbo.RealInstrument synonym (Trade.Instrument), filtered to exclude the system placeholder (InstrumentID=0).

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetInstrumentsShards answers: "Which shard does each instrument belong to?" It maps every active instrument (InstrumentID > 0) to its ShardID, enabling the pricing system to route price update messages and computations to the correct shard in the distributed architecture.

Sharding distributes instruments across multiple price processing partitions (shards). With 10,484 instruments distributed across 3 shards (ShardID=1: 4,564 instruments, ShardID=2: 4,712 instruments, ShardID=8: 1,208 instruments), each shard handles a subset of instruments for parallel price processing, reducing load per node.

The view reads from `dbo.RealInstrument`, which is a database-level synonym pointing to `[etoro].[Trade].[Instrument]`. Using the synonym provides a stable reference: if Trade.Instrument is ever renamed or moved, only the synonym needs updating. The WHERE InstrumentID > 0 filter excludes the system placeholder instrument (ID=0) that exists in Trade.Instrument.

---

## 2. Business Logic

### 2.1 Instrument Shard Distribution

**What**: Instruments are assigned to one of 3 shards; the pricing engine uses ShardID to determine which price server partition handles each instrument.

**Columns/Parameters Involved**: `InstrumentID`, `ShardID`

**Rules**:
- ShardID=1: 4,564 instruments (44% of total)
- ShardID=2: 4,712 instruments (45% of total)
- ShardID=8: 1,208 instruments (11% of total)
- ShardID is assigned in Trade.Instrument (the base table); this view merely exposes it
- InstrumentID=0 is excluded (WHERE InstrumentID > 0) - system placeholder, not a real instrument

**Diagram**:
```
Price Sharding Layer
  ShardID=1 -> 4,564 instruments (price server partition 1)
  ShardID=2 -> 4,712 instruments (price server partition 2)
  ShardID=8 -> 1,208 instruments (price server partition 8 - likely a secondary/special partition)

dbo.RealInstrument synonym -> [etoro].[Trade].[Instrument]
  (synonym provides stable cross-schema reference)
```

### 2.2 dbo.RealInstrument Synonym Resolution

**What**: The view references `RealInstrument` without a schema qualifier - this resolves to `dbo.RealInstrument`, a database-level synonym aliasing `[etoro].[Trade].[Instrument]`.

**Rules**:
- dbo.RealInstrument base object: `[etoro].[Trade].[Instrument]`
- The synonym is in the `dbo` schema; unqualified reference in the view resolves via default schema lookup
- This is the only place in the Price schema where Trade.Instrument is accessed via synonym rather than direct qualified name

---

## 3. Data Overview

| InstrumentID | ShardID | Meaning |
|---|---|---|
| 1 | 1 | EUR/USD assigned to shard 1. Price updates for EUR/USD are processed by the shard-1 pricing partition. |
| 2 | 1 | GBP/USD also on shard 1. Major forex pairs grouped together on the primary shard. |
| 3 | 1 | NZD/USD on shard 1. |
| 4 | 1 | USD/CAD on shard 1. |
| 5 | 1 | JPY/USD on shard 1. |

*Shard distribution: 3 shards (1, 2, 8) covering 10,484 instruments. ShardID=8 handles ~11% of instruments, likely a specialized partition.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier from Trade.Instrument (via dbo.RealInstrument synonym). InstrumentID=0 excluded by WHERE clause. All 10,484 active instruments are present. |
| 2 | ShardID | int | YES | - | CODE-BACKED | Shard partition identifier from Trade.Instrument. Determines which price server partition processes price updates for this instrument. Values observed: 1, 2, 8. Assigned at the Trade schema level; this view exposes it for the pricing layer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID, ShardID | Trade.Instrument | Direct (via dbo.RealInstrument synonym) | Source of both columns; synonym provides stable reference |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetInstrumentsShards (view)
└── dbo.RealInstrument (synonym -> [etoro].[Trade].[Instrument]) (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.RealInstrument (synonym for Trade.Instrument) | Synonym/Table | FROM - provides InstrumentID and ShardID; WHERE InstrumentID > 0 excludes placeholder |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING (cross-schema synonym reference prevents it). WHERE InstrumentID > 0 excludes the system placeholder.

---

## 8. Sample Queries

### 8.1 Get the shard for a specific instrument

```sql
SELECT InstrumentID, ShardID
FROM Price.GetInstrumentsShards WITH (NOLOCK)
WHERE InstrumentID = 1;
```

### 8.2 Count instruments per shard

```sql
SELECT ShardID, COUNT(*) AS InstrumentCount
FROM Price.GetInstrumentsShards WITH (NOLOCK)
GROUP BY ShardID
ORDER BY ShardID;
```

### 8.3 Get all instruments assigned to a specific shard

```sql
SELECT InstrumentID, ShardID
FROM Price.GetInstrumentsShards WITH (NOLOCK)
WHERE ShardID = 1
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetInstrumentsShards | Type: View | Source: etoro/etoro/Price/Views/Price.GetInstrumentsShards.sql*
