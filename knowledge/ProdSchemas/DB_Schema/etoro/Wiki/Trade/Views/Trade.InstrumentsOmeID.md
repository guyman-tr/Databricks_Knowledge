# Trade.InstrumentsOmeID

> CTE-based view that assigns OME (Order Matching Engine) pool IDs to tradable instruments using modular arithmetic over pool configuration.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.InstrumentsOmeID assigns each tradable instrument to an OME (Order Matching Engine) pool. It uses Trade.OMEPoolConfig to define pools with ExchangeID-based splits, then assigns each tradable instrument (where InstrumentMetaData.Tradable=1 AND ProviderToInstrument.Enabled=1) to a pool using modular arithmetic: InstrumentID % PoolSize + StartID. Instruments not explicitly mapped fall into default pools. Output includes InstrumentID, OMEID, PoolName, and PoolInstanceID.

This view exists because the trading platform distributes order matching across multiple OME instances for scalability. Each instrument must be routed to a specific OME pool. The assignment must be deterministic and load-balanced. Without this view, OME routing logic would need to replicate the pool configuration and assignment logic in multiple places.

The view uses CTEs to: (1) build pool definitions from OMEPoolConfig with ExchangeID splits, (2) identify tradable instruments from InstrumentMetaData and ProviderToInstrument, (3) assign each instrument to a pool via (InstrumentID % PoolSize) + StartID, (4) apply default pools for instruments not in explicit mappings. The result is one row per tradable instrument with its OME pool assignment.

---

## 2. Business Logic

### 2.1 OME Pool Assignment

**What**: Each tradable instrument is assigned to an OME pool using deterministic modular arithmetic.

**Columns/Parameters Involved**: InstrumentID, OMEID, PoolName, PoolInstanceID, PoolSize, StartID, ExchangeID

**Rules**:
- Tradable = InstrumentMetaData.Tradable = 1 AND ProviderToInstrument.Enabled = 1.
- Pool assignment: (InstrumentID % PoolSize) + StartID yields the OMEID within the pool's range.
- OMEPoolConfig defines pools with ExchangeID criteria; instruments are matched to pools by ExchangeID.
- Default pools catch instruments not in any ExchangeID-specific pool.
- Output: InstrumentID, OMEID, PoolName, PoolInstanceID.

**Diagram**:
```
Trade.OMEPoolConfig (pool defs) -> Pool definitions with PoolSize, StartID, ExchangeID
        |
        v
Trade.Instrument + Trade.InstrumentMetaData + Trade.ProviderToInstrument
        |
        v
Tradable instruments (Tradable=1, Enabled=1)
        |
        v
InstrumentID % PoolSize + StartID -> OMEID, PoolName, PoolInstanceID
```

---

## 3. Data Overview

Output does not mirror a single base table. Each row represents one tradable instrument with its OME pool assignment. InstrumentID identifies the instrument; OMEID is the assigned pool instance ID; PoolName and PoolInstanceID identify the pool. Row count equals the number of tradable (ProviderToInstrument.Enabled=1, InstrumentMetaData.Tradable=1) instruments.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Identifies the tradeable instrument. |
| 2 | OMEID | int | NO | - | CODE-BACKED | Assigned Order Matching Engine pool instance ID. Computed via (InstrumentID % PoolSize) + StartID. |
| 3 | PoolName | nvarchar | YES | - | CODE-BACKED | Name of the OME pool. From Trade.OMEPoolConfig. |
| 4 | PoolInstanceID | int | YES | - | CODE-BACKED | Pool instance identifier. From Trade.OMEPoolConfig. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | JOIN | Tradable instruments. |
| - | Trade.InstrumentMetaData | JOIN | Tradable=1 filter. |
| - | Trade.ProviderToInstrument | JOIN | Enabled=1 filter. |
| - | Trade.OMEPoolConfig | JOIN/CTE | Pool definitions, PoolSize, StartID, ExchangeID. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentsOmeID (view)
    |
    +-- Trade.OMEPoolConfig (table)
    +-- Trade.InstrumentMetaData (table)
    +-- Trade.Instrument (table)
    +-- Trade.ProviderToInstrument (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OMEPoolConfig | Table | Defines OME pools with PoolSize, StartID, ExchangeID. |
| Trade.InstrumentMetaData | Table | Tradable=1 filter. |
| Trade.Instrument | Table | Base instrument list, ExchangeID join. |
| Trade.ProviderToInstrument | Table | Enabled=1 filter for tradable instruments. |

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

### 8.1 Get OME assignment for instrument
```sql
SELECT InstrumentID, OMEID, PoolName, PoolInstanceID
FROM Trade.InstrumentsOmeID WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
```

### 8.2 Instruments in a specific OME pool
```sql
SELECT InstrumentID, OMEID, PoolName, PoolInstanceID
FROM Trade.InstrumentsOmeID WITH (NOLOCK)
WHERE OMEID = @OMEID
ORDER BY InstrumentID
```

### 8.3 Pool distribution summary
```sql
SELECT PoolName, PoolInstanceID, OMEID, COUNT(*) AS InstrumentCount
FROM Trade.InstrumentsOmeID WITH (NOLOCK)
GROUP BY PoolName, PoolInstanceID, OMEID
ORDER BY PoolName, OMEID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentsOmeID | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentsOmeID.sql*
