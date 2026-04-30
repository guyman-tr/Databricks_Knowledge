# Trade.GetInstrumentToFeeConfiguration

> Returns overnight and end-of-week fee rates for all instruments, separated by leverage type (leveraged vs non-leveraged) and direction (buy vs sell), for the fee calculation engine.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 11 fee columns from Trade.InstrumentToFeeConfigV2 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentToFeeConfiguration returns the complete fee matrix for all instruments from Trade.InstrumentToFeeConfigV2. The fee structure is multidimensional: each instrument has separate overnight and end-of-week fees for four combinations of leverage type (leveraged/non-leveraged) and direction (buy/sell). The FeeCalculationTypeID and SettlementTypeID columns determine which fee formula applies.

This procedure exists because the fee calculation engine needs to look up the correct fee rate based on the position's leverage, direction, and settlement type. Different fee rates apply to CFD positions (leveraged) vs real stock positions (non-leveraged), and buy-side vs sell-side positions.

---

## 2. Business Logic

### 2.1 Fee Matrix by Leverage and Direction

**What**: Four separate fee configurations per instrument covering all leverage/direction combinations.

**Columns/Parameters Involved**: All 8 fee rate columns + `FeeCalculationTypeID`, `SettlementTypeID`

**Rules**:
- NonLeveraged* fees apply to real stock positions (SettlementType=Real, leverage=1)
- Leveraged* fees apply to CFD positions (any leverage > 1)
- Buy vs Sell rates differ because overnight financing costs depend on position direction
- EOW (End of Week) fees are charged weekly; OverNight fees are charged daily
- FeeCalculationTypeID determines the fee formula variant
- SettlementTypeID determines which settlement context these fees apply to

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | InstrumentToFeeConfigV2 | CODE-BACKED | Instrument identifier. |
| R2 | NonLeveragedSellEndOfWeekFee | decimal | InstrumentToFeeConfigV2 | CODE-BACKED | Weekly fee rate for non-leveraged (real stock) sell/short positions. |
| R3 | NonLeveragedBuyEndOfWeekFee | decimal | InstrumentToFeeConfigV2 | CODE-BACKED | Weekly fee rate for non-leveraged buy/long positions. |
| R4 | NonLeveragedBuyOverNightFee | decimal | InstrumentToFeeConfigV2 | CODE-BACKED | Daily overnight fee for non-leveraged buy/long positions. |
| R5 | NonLeveragedSellOverNightFee | decimal | InstrumentToFeeConfigV2 | CODE-BACKED | Daily overnight fee for non-leveraged sell/short positions. |
| R6 | LeveragedSellEndOfWeekFee | decimal | InstrumentToFeeConfigV2 | CODE-BACKED | Weekly fee rate for leveraged (CFD) sell/short positions. |
| R7 | LeveragedBuyEndOfWeekFee | decimal | InstrumentToFeeConfigV2 | CODE-BACKED | Weekly fee rate for leveraged buy/long positions. |
| R8 | LeveragedBuyOverNightFee | decimal | InstrumentToFeeConfigV2 | CODE-BACKED | Daily overnight fee for leveraged buy/long positions. |
| R9 | LeveragedSellOverNightFee | decimal | InstrumentToFeeConfigV2 | CODE-BACKED | Daily overnight fee for leveraged sell/short positions. |
| R10 | FeeCalculationTypeID | int | InstrumentToFeeConfigV2 | CODE-BACKED | Determines which fee calculation formula applies to this instrument. |
| R11 | SettlementTypeID | int | InstrumentToFeeConfigV2 | CODE-BACKED | Settlement type context for these fees. See [Settlement Type](_glossary.md#settlement-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.InstrumentToFeeConfigV2 | Read (SELECT) | V2 fee configuration table with per-instrument fee matrix |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Fee calculation engine | (application) | Consumer | Looks up fee rates for overnight/EOW fee processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentToFeeConfiguration (procedure)
+-- Trade.InstrumentToFeeConfigV2 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentToFeeConfigV2 | Table | SELECT - source of all fee configuration data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Fee calculation engine | Application | Reads fee rates for overnight and EOW processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all fee configurations

```sql
EXEC Trade.GetInstrumentToFeeConfiguration;
```

### 8.2 Find instruments with highest leveraged overnight fees

```sql
SELECT  TOP 10 c.InstrumentID, imd.InstrumentDisplayName,
        c.LeveragedBuyOverNightFee, c.LeveragedSellOverNightFee
FROM    Trade.InstrumentToFeeConfigV2 c WITH (NOLOCK)
        INNER JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON c.InstrumentID = imd.InstrumentID
ORDER BY c.LeveragedBuyOverNightFee DESC;
```

### 8.3 Compare leveraged vs non-leveraged fees

```sql
SELECT  c.InstrumentID,
        c.LeveragedBuyOverNightFee AS LevBuyON,
        c.NonLeveragedBuyOverNightFee AS NonLevBuyON,
        c.LeveragedBuyOverNightFee - c.NonLeveragedBuyOverNightFee AS FeeDiff
FROM    Trade.InstrumentToFeeConfigV2 c WITH (NOLOCK)
WHERE   c.LeveragedBuyOverNightFee <> c.NonLeveragedBuyOverNightFee
ORDER BY FeeDiff DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentToFeeConfiguration | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentToFeeConfiguration.sql*
