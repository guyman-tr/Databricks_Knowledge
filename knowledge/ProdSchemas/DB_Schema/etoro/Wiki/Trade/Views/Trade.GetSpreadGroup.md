# Trade.GetSpreadGroup

> Denormalized view joining spread groups with their bid/ask spreads per provider and instrument for rate resolution and customer pricing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | SpreadGroupID, SpreadID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetSpreadGroup is a denormalized view that joins Trade.SpreadGroup, Trade.Spread, and Trade.SpreadToGroup to expose each spread group's name plus the Bid and Ask pip offsets for every linked (ProviderID, InstrumentID) pair. Each row represents one (SpreadGroupID, SpreadID) combination - i.e., "Spread Group X includes Spread Y with these Bid/Ask values." The view answers: "What bid/ask spreads apply for SpreadGroupID=N when quoting InstrumentID=M from ProviderID=P?"

This view exists because eToro assigns different spread tiers to customers (Default, Expert, One Pip Plus, etc.) and needs to resolve which Bid/Ask values apply at order and rate lookup time. Trade.GetForexRates joins on SpreadGroupID=0 for base forex rates. Trade.SI_GetSpreadGroup, Trade.HedgingCheckUsersEquity, Trade.GetMSLSpreadGroups, and History.GetOnePipValueDollar all consume this view. The view uses SCHEMABINDING for stability.

---

## 2. Business Logic

### 2.1 Spread Group to Spread Resolution

**What**: The view resolves the many-to-many relationship between spread groups and spread definitions via Trade.SpreadToGroup.

**Columns/Parameters Involved**: `SpreadGroupID`, `Name`, `SpreadID`, `ProviderID`, `InstrumentID`, `Bid`, `Ask`

**Rules**:
- TSPG (SpreadGroup) JOIN TS2G (SpreadToGroup) ON SpreadGroupID produces one row per (SpreadGroupID, SpreadID) pair
- TS2G JOIN TSPR (Spread) ON SpreadID produces ProviderID, InstrumentID, Bid, Ask for each pair
- SpreadGroupID=0 (Default) is used by Trade.GetForexRates for base forex spreads
- Same SpreadID can appear in multiple groups, producing multiple rows with same Bid/Ask but different SpreadGroupID/Name

**Diagram**:
```
Trade.SpreadGroup (SpreadGroupID, Name)
       | JOIN SpreadGroupID
       v
Trade.SpreadToGroup (SpreadGroupID, SpreadID)
       | JOIN SpreadID
       v
Trade.Spread (SpreadID, ProviderID, InstrumentID, Bid, Ask)
```

### 2.2 No WHERE Filter

**What**: The view has no WHERE clause - it returns all spread groups with their linked spreads.

**Rules**:
- Callers filter by SpreadGroupID (e.g., 0 for Default) or InstrumentID as needed
- Trade.GetForexRates filters on SpreadGroupID=0 and InstrumentID

---

## 3. Data Overview

| SpreadGroupID | Name | SpreadID | ProviderID | InstrumentID | Bid | Ask | Meaning |
|---------------|------|----------|------------|--------------|-----|-----|---------|
| 0 | Default | 1 | 1 | 1 | -2 | 1 | EUR/USD (Instrument 1) in Default group. Bid offset -2, Ask +1 pips. |
| 8 | CID=1025068 ( Gold 50 pips) | 1 | 1 | 1 | -2 | 1 | Same spread definition in custom group - customer-specific override. |
| 0 | Default | 2 | 1 | 2 | -2 | 2 | GBP/USD (Instrument 2) in Default. Slightly wider ask. |
| 4 | 1 pip discount on Instruments 1 & 6 | 2 | 1 | 2 | -2 | 2 | Instrument-specific discount group shares same spread. |
| 6 | Default + EUR/USD 2 pips | 2 | 1 | 2 | -2 | 2 | Custom group with same GBP spread. |

**Live sampling**: Top 5 rows show multiple spread groups (0, 4, 6, 8) sharing the same SpreadID values. Bid values -2; Ask 1-2. ProviderID=1 throughout.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Source Table | Description |
|---|---------|------|----------|---------|------------|--------------|-------------|
| 1 | SpreadGroupID | int | NO | - | CODE-BACKED | Trade.SpreadGroup (TSPG) | Spread tier identifier. 0=Default, 1=Expert, etc. Used by GetForexRates on 0 for base forex. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Trade.SpreadGroup (TSPG) | Human-readable spread group label (e.g., "Default", "Expert", "1 pip discount on Instruments 1 & 6"). |
| 3 | SpreadID | int | NO | - | CODE-BACKED | Trade.Spread (TSPR) | Unique spread definition. One row per (ProviderID, InstrumentID) in Trade.Spread. |
| 4 | ProviderID | int | NO | - | CODE-BACKED | Trade.Spread (TSPR) | Execution/liquidity provider. Typically 1. |
| 5 | InstrumentID | int | NO | - | CODE-BACKED | Trade.Spread (TSPR) | Tradeable instrument. Joins to GetCurrentPrice.InstrumentID in GetForexRates. |
| 6 | Bid | int | NO | - | CODE-BACKED | Trade.Spread (TSPR) | Pip offset for bid. Applied to raw bid in GetForexRates: Bid + Bid/power(10,Precision). |
| 7 | Ask | int | NO | - | CODE-BACKED | Trade.Spread (TSPR) | Pip offset for ask. Applied to raw ask in GetForexRates: Ask + Ask/power(10,Precision). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Base Table | Join Condition | Relationship Type | Description |
|------------|----------------|-------------------|-------------|
| Trade.SpreadGroup (TSPG) | FROM | Source | Spread tier definitions. |
| Trade.Spread (TSPR) | TSPR via TS2G | Source | Bid/Ask per ProviderID, InstrumentID. |
| Trade.SpreadToGroup (TS2G) | TSPG.SpreadGroupID = TS2G.SpreadGroupID AND TS2G.SpreadID = TSPR.SpreadID | Bridge | Many-to-many link. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Type | Role | Description |
|--------------|------|------|-------------|
| Trade.GetForexRates | Procedure | READER | JOINs on SpreadGroupID=0, InstrumentID for forex rate calculation. |
| Trade.SI_GetSpreadGroup | Procedure | READER | SELECT FROM GetSpreadGroup for spread lookup. |
| Trade.GetMSLSpreadGroups | Procedure | READER | Joins GetSpreadGroup to ProviderToInstrument. |
| Trade.HedgingCheckUsersEquity | Procedure | READER | LEFT JOIN GetSpreadGroup for hedging spread resolution. |
| History.GetOnePipValueDollar | Function | READER | Uses GetSpreadGroup for pip value calculation. |
| History.GetOnePipValueDollarForDealing | Function | READER | Same pip value logic. |
| History.GetOnePipValueDollarForDealing_2 | Function | READER | Same pip value logic. |
| Trade.GetSpreadGroupSafty | View | READER | SELECT FROM GetSpreadGroup for safety view. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetSpreadGroup (view)
├── Trade.SpreadGroup (table)
├── Trade.Spread (table)
└── Trade.SpreadToGroup (table)
      ├── Trade.SpreadGroup
      └── Trade.Spread
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SpreadGroup | Table | FROM - spread tier names. |
| Trade.Spread | Table | FROM via SpreadToGroup - Bid, Ask, ProviderID, InstrumentID. |
| Trade.SpreadToGroup | Table | FROM - bridge linking groups to spreads. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetForexRates | Procedure | JOIN for rate resolution |
| Trade.SI_GetSpreadGroup | Procedure | FROM |
| Trade.GetMSLSpreadGroups | Procedure | JOIN |
| Trade.HedgingCheckUsersEquity | Procedure | LEFT JOIN |
| History.GetOnePipValueDollar | Function | FROM |
| History.GetOnePipValueDollarForDealing | Function | FROM |
| History.GetOnePipValueDollarForDealing_2 | Function | FROM |
| Trade.GetSpreadGroupSafty | View | FROM |

---

## 7. Technical Details

### 7.1 DDL Summary

- View uses **SCHEMABINDING** - no schema changes to base tables without dropping the view first
- Old-style comma JOIN syntax: `FROM Trade.SpreadGroup TSPG, Trade.Spread TSPR, Trade.SpreadToGroup TS2G`
- No NOLOCK hint in view; callers typically add WITH (NOLOCK) when selecting

### 7.2 Column Mapping

| Output Column | Source |
|--------------|--------|
| SpreadGroupID | TSPG.SpreadGroupID |
| Name | TSPG.Name |
| SpreadID | TSPR.SpreadID |
| ProviderID | TSPR.ProviderID |
| InstrumentID | TSPR.InstrumentID |
| Bid | TSPR.Bid |
| Ask | TSPR.Ask |

---

## 8. Sample Queries

### 8.1 Get Default spread group spreads (SpreadGroupID=0)

```sql
SELECT SpreadGroupID,
       Name,
       SpreadID,
       ProviderID,
       InstrumentID,
       Bid,
       Ask
  FROM Trade.GetSpreadGroup WITH (NOLOCK)
 WHERE SpreadGroupID = 0
   AND ProviderID = 1
 ORDER BY InstrumentID
```

### 8.2 Resolve spread for specific instrument in Default group

```sql
SELECT SpreadGroupID,
       Name,
       Bid,
       Ask
  FROM Trade.GetSpreadGroup WITH (NOLOCK)
 WHERE SpreadGroupID = 0
   AND InstrumentID = 1
   AND ProviderID = 1
```

### 8.3 Count spreads per group

```sql
SELECT SpreadGroupID,
       Name,
       COUNT(*) AS SpreadCount
  FROM Trade.GetSpreadGroup WITH (NOLOCK)
 GROUP BY SpreadGroupID, Name
 ORDER BY SpreadGroupID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 7/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetSpreadGroup | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetSpreadGroup.sql*
