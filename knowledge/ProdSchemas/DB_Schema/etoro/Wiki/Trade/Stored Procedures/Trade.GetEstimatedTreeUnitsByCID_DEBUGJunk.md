# Trade.GetEstimatedTreeUnitsByCID_DEBUGJunk

> Debug-only procedure that estimates the copy-trading tree unit allocation for a given customer, instrument, and leverage - not for production use.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns tree of copiers with MirrorID, CID, Units, Ratio |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a **debug/diagnostic procedure** that simulates the CopyTrader tree expansion for a given customer (CID) when they open a position. It was written to investigate a specific copy-trading bug and is explicitly marked as not suitable for production trading. The procedure name contains "DEBUGJunk" to signal this.

When a leader on eToro opens a position, all active copiers (and their copiers, recursively) should also open proportional positions. This procedure estimates what that copy tree would look like - how many units each copier would receive - based on their equity, the copy ratio, leverage, and minimum position size rules.

The procedure traverses the `Trade.Mirror` hierarchy recursively using a CTE, calculating proportional units for each copier level. It filters out blocked/test players (PlayerStatusID NOT IN 2, 9), copiers with zero equity, copiers without sufficient funds, and inactive or paused mirrors.

---

## 2. Business Logic

### 2.1 Recursive Copy-Tree Unit Estimation

**What**: Calculates estimated units for each copier in the hierarchy when a leader opens a position.

**Columns/Parameters Involved**: `@CID`, `@Leverage`, `@Ratio`, `@Units`, `@InstrumentID`

**Rules**:
- Minimum position size is derived from Maintenance.Feature FeatureID=100 (MinDollars, in cents, divided by 100)
- MinUnits = MinDollars * Leverage / InstrumentUnitMargin
- Level 0 copiers: Units = copier's RealizedEquity * Leverage * Ratio / InstrumentUnitMargin
- Level N copiers: Units = parent's Ratio * copier's RealizedEquity * Leverage / InstrumentUnitMargin
- Only copiers with IsHedged=1 are included in the final result
- PlayerLevelID=4 customers get zero units (blocked from copy tree)

**Diagram**:
```
Leader (CID)
  +-- Copier L1 (Units = Equity * Leverage * Ratio / UnitMargin)
  |     +-- Copier L2 (Units = L1.Ratio * Equity * Leverage / UnitMargin)
  |     +-- Copier L2b ...
  +-- Copier L1b ...
        +-- Copier L2c ...
Filter: IsHedged=1, Active, Not Paused, Sufficient Funds
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the leader opening the position |
| 2 | @Leverage | INT | NO | - | CODE-BACKED | Leverage factor for the position (e.g., 1 for stocks, up to 30 for forex) |
| 3 | @Ratio | DECIMAL(12,8) | NO | - | CODE-BACKED | Proportion of the leader's equity allocated to this position |
| 4 | @Units | MONEY | NO | - | CODE-BACKED | Number of units the leader is opening (added to tree total) |
| 5 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument being traded; used to look up UnitMargin from Trade.ProviderToInstrument |

### Return Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorID | INT | NO | - | CODE-BACKED | Mirror relationship ID linking copier to their parent |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID of the copier |
| 3 | ParentCID | INT | NO | - | CODE-BACKED | Customer ID of this copier's direct parent in the copy tree |
| 4 | Level | INT | NO | - | CODE-BACKED | Depth in the copy tree (0 = direct copier of leader) |
| 5 | Units | DECIMAL(20,8) | NO | - | CODE-BACKED | Estimated units this copier would receive |
| 6 | Ratio | DECIMAL(20,8) | NO | - | CODE-BACKED | Copy ratio: copier's equity share relative to their parent |
| 7 | IsHedged | BIT | NO | - | CODE-BACKED | Whether the copier is hedged (only hedged copiers appear in results) |
| 8 | ParentUnits | MONEY | NO | - | CODE-BACKED | The leader's own unit count (passed through as @Units) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.ProviderToInstrument | Lookup | Retrieves UnitMargin for the instrument |
| FeatureID=100 | Maintenance.Feature | Lookup | Minimum position dollar amount in cents |
| @CID | Customer.Customer | Lookup | Checks PlayerLevelID to zero out units for level 4 |
| Recursive CTE | Trade.Mirror | JOIN | Traverses the copy-trading mirror hierarchy |
| Recursive CTE | Customer.Customer | JOIN | Gets RealizedEquity, PlayerStatusID, IsHedged for each copier |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Debug use only) | Manual execution | Ad-hoc | Not called by production code - debug diagnostic tool |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetEstimatedTreeUnitsByCID_DEBUGJunk (procedure)
  +-- Trade.ProviderToInstrument (table)
  +-- Maintenance.Feature (table)
  +-- Customer.Customer (table)
  +-- Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | SELECT UnitMargin WHERE InstrumentID |
| Maintenance.Feature | Table | SELECT Value WHERE FeatureID=100 (MinDollars) |
| Customer.Customer | Table | PlayerLevelID check + recursive CTE JOIN |
| Trade.Mirror | Table | Recursive CTE anchor and recursive member |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None) | - | Debug-only procedure, not called by other objects |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Estimate tree units for a customer
```sql
EXEC Trade.GetEstimatedTreeUnitsByCID_DEBUGJunk
    @CID = 12345678,
    @Leverage = 1,
    @Ratio = 0.05,
    @Units = 100,
    @InstrumentID = 1001;
```

### 8.2 Check minimum position dollar amount
```sql
SELECT  CONVERT(DECIMAL(20,8), Value) / 100 AS MinDollars
FROM    Maintenance.Feature WITH (NOLOCK)
WHERE   FeatureID = 100;
```

### 8.3 View active mirrors for a customer
```sql
SELECT  MirrorID, CID, ParentCID, Amount, RealizedEquity, IsActive, PauseCopy
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   ParentCID = 12345678
        AND IsActive = 1
        AND PauseCopy = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetEstimatedTreeUnitsByCID_DEBUGJunk | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetEstimatedTreeUnitsByCID_DEBUGJunk.sql*
