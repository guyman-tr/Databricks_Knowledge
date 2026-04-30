# Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection

> Returns the unit margin for an instrument and aggregated position units grouped by leverage tier and direction for a customer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 2 result sets: unit margin and leverage-tier aggregation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides two pieces of information needed for leverage-based margin calculations: (1) the unit margin for the instrument from Trade.CurrencyPrice, and (2) the customer's open position units broken down by leverage tier and direction (buy/sell). This supports the "max leverage by net open tiers" feature where different leverage levels have different margin requirements.

The procedure exists to support real-time margin and leverage validation. When a customer opens or modifies a position, the system needs to know how their existing exposure is distributed across leverage tiers to calculate whether additional margin capacity exists.

Data flows from Trade.CurrencyPrice (unit margin for the instrument) and Trade.PositionTbl (open positions aggregated by leverage and direction).

---

## 2. Business Logic

### 2.1 Leverage Tier Aggregation

**What**: Open positions are grouped by leverage level and direction to show exposure distribution.

**Columns/Parameters Involved**: `Leverage`, `AmountInUnitsDecimal`, `IsBuy`, `StatusID`

**Rules**:
- Only open positions (StatusID = 1) are included
- Positions are grouped by Leverage tier and IsBuy direction
- TotalUnits = SUM(AmountInUnitsDecimal) per leverage/direction group
- @GetBothDirections flag allows querying single direction (IsBuy = @IsBuy) or both directions simultaneously
- Leverage X1 positions are included (despite the comment about excluding them - the exclusion is in the calling layer, not in this SP)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to check leverage tiers for. |
| 2 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument to analyze leverage distribution for. |
| 3 | @IsBuy | BIT | NO | - | CODE-BACKED | Direction filter: 1=Buy/Long, 0=Sell/Short. Ignored if @GetBothDirections=1. |
| 4 | @GetBothDirections | BIT | YES | 0 | CODE-BACKED | When 1, returns tiers for both Buy and Sell directions. When 0 (default), only @IsBuy direction. |

**Result Set 1 - Unit Margin:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument ID from Trade.CurrencyPrice. |
| 6 | UnitMargin | DECIMAL | NO | - | CODE-BACKED | Margin required per unit for this instrument. ISNULL defaults to 1 if NULL. |

**Result Set 2 - Leverage Tiers:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 7 | LeverageTier | INT | NO | - | CODE-BACKED | Leverage level (e.g., 1, 2, 5, 10, 20). |
| 8 | TotalUnits | DECIMAL | NO | - | CODE-BACKED | Sum of AmountInUnitsDecimal for all open positions at this leverage tier. |
| 9 | Direction | BIT | NO | - | CODE-BACKED | 1=Buy/Long, 0=Sell/Short for this tier grouping. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM RS1 | Trade.CurrencyPrice | Direct Read | Reads unit margin for the instrument |
| FROM RS2 | Trade.PositionTbl | Direct Read | Reads open positions for leverage aggregation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection (procedure)
├── Trade.CurrencyPrice (table)
└── Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CurrencyPrice | Table | SELECT - unit margin |
| Trade.PositionTbl | Table | SELECT - open positions for tier aggregation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get leverage tiers for a customer on an instrument (buy direction)

```sql
EXEC Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection
    @CID = 12345678,
    @InstrumentID = 1001,
    @IsBuy = 1;
```

### 8.2 Get both directions

```sql
EXEC Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection
    @CID = 12345678,
    @InstrumentID = 1001,
    @IsBuy = 1,
    @GetBothDirections = 1;
```

### 8.3 Check unit margin for an instrument

```sql
SELECT  InstrumentID,
        ISNULL(UnitMargin, 1) AS UnitMargin
FROM    Trade.CurrencyPrice WITH (NOLOCK)
WHERE   InstrumentID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection.sql*
