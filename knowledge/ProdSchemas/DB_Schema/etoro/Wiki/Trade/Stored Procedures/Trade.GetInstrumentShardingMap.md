# Trade.GetInstrumentShardingMap

> Returns the instrument-to-shard mapping for all active instruments, enabling services to route instrument-scoped operations to the correct database shard.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + ShardID from Trade.Instrument |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentShardingMap is a parameterless getter procedure that returns the shard assignment for every instrument with a positive ID. The eToro platform uses database sharding to distribute instrument-related workload across multiple database instances, and each instrument is assigned to a specific shard (ShardID). Services call this procedure at startup to build an in-memory routing map so they know which shard to query for each instrument.

This procedure exists because any service that needs to perform instrument-scoped operations on sharded databases (position management, order matching, price updates) must first know which shard hosts each instrument. The mapping is loaded once and cached.

The WHERE filter `InstrumentID > 0` excludes the system/sentinel instrument ID 0, which is not a real tradable instrument.

---

## 2. Business Logic

### 2.1 Shard Assignment for Instrument Routing

**What**: Maps each instrument to a database shard for distributed data routing.

**Columns/Parameters Involved**: `Trade.Instrument.InstrumentID`, `Trade.Instrument.ShardID`

**Rules**:
- Each instrument is assigned to exactly one shard (ShardID)
- InstrumentID > 0 excludes sentinel/system records
- The mapping is static (shard assignments do not change during normal operations)
- Services cache this map at startup for O(1) shard lookup per instrument

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.Instrument.InstrumentID | CODE-BACKED | Instrument identifier. PK of Trade.Instrument. Every tradable instrument (ID > 0) is returned. |
| R2 | ShardID | int | Trade.Instrument.ShardID | CODE-BACKED | Database shard identifier where this instrument's data resides. Used by services to route queries and writes to the correct sharded database instance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Instrument | Read (SELECT) | Core instrument table; reads InstrumentID and ShardID with NOLOCK |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application services) | (startup) | Consumer | Services load the shard map at initialization for database routing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentShardingMap (procedure)
+-- Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | SELECT WHERE InstrumentID > 0 - source of shard assignments |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application services | Various | Load shard map at startup for instrument-to-shard routing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get the full shard map

```sql
EXEC Trade.GetInstrumentShardingMap;
```

### 8.2 Count instruments per shard

```sql
SELECT  ShardID,
        COUNT(*) AS InstrumentCount
FROM    Trade.Instrument WITH (NOLOCK)
WHERE   InstrumentID > 0
GROUP BY ShardID
ORDER BY ShardID;
```

### 8.3 Find which shard hosts a specific instrument

```sql
SELECT  InstrumentID, ShardID
FROM    Trade.Instrument WITH (NOLOCK)
WHERE   InstrumentID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentShardingMap | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentShardingMap.sql*
