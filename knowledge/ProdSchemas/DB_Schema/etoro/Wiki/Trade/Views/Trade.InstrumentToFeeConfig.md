# Trade.InstrumentToFeeConfig

> **DEPRECATED** backward-compatibility view that flattens overnight and weekend fee rates per instrument from the V2 settlement-type-aware configuration, merging AllOther, Futures, and CFD fee schedules into a single result set.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID (from Trade.InstrumentToFeeConfigV2) |
| **Partition** | N/A |
| **Indexes** | N/A |
| **Status** | **OBSOLETE** - use Trade.InstrumentToFeeConfigV2 instead |

---

## 1. Business Meaning

Trade.InstrumentToFeeConfig is a backward-compatibility view that presents overnight and weekend holding fee rates per instrument. These fees (also called rollover fees or swap fees) are charged to customers who hold leveraged positions overnight or over weekends. The view exists because the original fee configuration was settlement-type-agnostic, but the newer Trade.InstrumentToFeeConfigV2 table introduced per-settlement-type fee rates (separate configs for CFD, Real, Futures, etc.).

Without this view, legacy consumers that expect the old single-row-per-instrument format would break. The view source code explicitly states: "This view is obsolete and created for backward compatibility. Will be removed in the future."

The view uses a UNION ALL of three CTEs: AllOther (non-CFD, non-futures settlement types), Futures (SettlementTypeID=4), and CfdForBackwardComp (CFD SettlementTypeID=0, excluding instruments that have futures configs). The CFD CTE also adjusts NonLeveragedBuy fees based on instrument type via Trade.GetInstrumentTypeIDsForCFDFee.

---

## 2. Business Logic

### 2.1 Settlement Type Flattening

**What**: Merges separate settlement-type fee configurations into a single backward-compatible result per instrument.

**Columns/Parameters Involved**: All fee columns, `SettlementTypeID` (from V2 source)

**Rules**:
- AllOther CTE: Takes V2 rows where SettlementTypeID NOT IN (0,4,5) - everything except CFD, Futures, and Margin Trade. Sets NonLeveragedBuyCFDOverNightFee=0.
- Futures CTE: Takes V2 rows where SettlementTypeID=4 (Real Futures). Sets NonLeveragedBuyCFDOverNightFee=0.
- CFD CTE: Takes V2 rows where SettlementTypeID=0 (CFD), but EXCLUDES instruments that also have a Futures config (LEFT JOIN to avoid duplicates).
- CfdForBackwardComp: Adjusts CFD buy fees based on instrument type. For instrument types returned by Trade.GetInstrumentTypeIDsForCFDFee, NonLeveragedBuyEndOfWeekFee and NonLeveragedBuyOverNightFee are zeroed, and instead NonLeveragedBuyCFDOverNightFee gets the buy overnight value.
- UNION ALL merges all three result sets

### 2.2 Fee Rate Types

**What**: Each instrument has 8 fee rates covering all combinations of leveraged/non-leveraged and buy/sell for overnight and weekend periods.

**Columns/Parameters Involved**: All fee columns

**Rules**:
- Overnight fees: charged daily for positions held past market close
- Weekend fees: charged Friday for positions held over the weekend (typically 3x overnight)
- Leveraged vs Non-Leveraged: different rate structures for positions with and without leverage
- Buy vs Sell: different rates for long and short positions (reflects underlying interest rate differentials)
- Negative fee values (e.g., LeveragedSellOverNightFee=-1): indicates the customer receives a credit instead of being charged

---

## 3. Data Overview

| InstrumentID | NonLeveragedBuyON | NonLeveragedSellON | LeveragedBuyON | LeveragedSellON | CFDBuyON | UpdatedByUser | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | 0.0001 | 0.01116 | 0.07467 | -1.00 | 0 | ops user | Primary instrument (likely EUR/USD). Sell overnight leveraged fee is -1 meaning short sellers receive a daily credit. Updated by ops. |
| 200001 | 0 | 0 | 0 | 0 | 0 | (none) | All fees zeroed - likely a crypto or special instrument with no overnight fees |
| 200002 | 0.07274 | 0.00452 | 0.02425 | 0.00151 | 0 | ops user | Standard instrument with positive fees on all combinations. Buy rates higher than sell rates. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Trading instrument identifier. From Trade.InstrumentToFeeConfigV2.InstrumentID. Each instrument appears once (after settlement type flattening). |
| 2 | NonLeveragedSellEndOfWeekFee | decimal | YES | - | CODE-BACKED | Weekend holding fee rate for non-leveraged sell (short) positions. From V2. Applied Friday for weekend carry. |
| 3 | NonLeveragedBuyEndOfWeekFee | decimal | YES | - | CODE-BACKED | Weekend holding fee rate for non-leveraged buy (long) positions. From V2. Zeroed for CFD instruments where GetInstrumentTypeIDsForCFDFee matches the instrument type. |
| 4 | NonLeveragedBuyOverNightFee | decimal | YES | - | CODE-BACKED | Daily overnight fee rate for non-leveraged buy positions. From V2. Zeroed for specific CFD instrument types (redirected to NonLeveragedBuyCFDOverNightFee). |
| 5 | NonLeveragedSellOverNightFee | decimal | YES | - | CODE-BACKED | Daily overnight fee rate for non-leveraged sell positions. From V2. |
| 6 | LeveragedSellEndOfWeekFee | decimal | YES | - | CODE-BACKED | Weekend holding fee rate for leveraged sell (short) positions. From V2. |
| 7 | LeveragedBuyEndOfWeekFee | decimal | YES | - | CODE-BACKED | Weekend holding fee rate for leveraged buy (long) positions. From V2. |
| 8 | LeveragedBuyOverNightFee | decimal | YES | - | CODE-BACKED | Daily overnight fee rate for leveraged buy positions. From V2. Core fee for leveraged long positions - typically the most significant fee. |
| 9 | LeveragedSellOverNightFee | decimal | YES | - | CODE-BACKED | Daily overnight fee rate for leveraged sell positions. From V2. Negative values mean the customer RECEIVES a credit (e.g., -1 for EUR/USD shorts due to interest rate differential). |
| 10 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when this fee configuration was last applied or became effective. From V2. |
| 11 | UpdatedByUser | varchar | YES | - | CODE-BACKED | Identity of the back-office operator or system that last updated this fee configuration. "ops user" for manual updates. NULL for system-generated. |
| 12 | BeginTime | datetime | YES | - | CODE-BACKED | Start of the validity window for this fee configuration. From V2. Fee configs are time-windowed; BeginTime marks when the rate starts applying. |
| 13 | EndTime | datetime | YES | - | CODE-BACKED | End of the validity window. Value of 9999-12-31 indicates the current/active fee config. From V2. When a new rate is set, the old rate's EndTime is updated and a new row begins. |
| 14 | NonLeveragedBuyCFDOverNightFee | decimal | YES | - | CODE-BACKED | Special overnight fee for non-leveraged buy CFD positions on specific instrument types. Computed in the CfdForBackwardComp CTE: equals the V2 NonLeveragedBuyOverNightFee for instruments where GetInstrumentTypeIDsForCFDFee matches, otherwise 0. Separates CFD buy fees from real stock buy fees for backward compatibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All fee columns | Trade.InstrumentToFeeConfigV2 | FROM (CTE source) | Primary data source - all fee rates come from V2, filtered and transformed by settlement type |
| InstrumentID | Trade.InstrumentMetaData | INNER JOIN | Used in CfdForBackwardComp CTE to get InstrumentTypeID for CFD fee adjustment |
| (function) | Trade.GetInstrumentTypeIDsForCFDFee | LEFT JOIN (function) | Returns instrument type IDs that qualify for special CFD fee handling |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CalcOverNightFeeRates | - | Reader | Calculates actual fee amounts using rates from this view |
| Trade.CalcOverNightFeeRates_TRDOPS | - | Reader | TRDOPS variant of fee rate calculation |
| Trade.GetInstrumentToFeeConfiguration | - | Reader | Returns fee config for API/UI consumption |
| Trade.RolloverFeesAlertIfNeeded | - | Reader | Monitors fee configuration for anomalies |
| Trade.CheckValidInstruments | - | Reader | Validates instrument fee setup completeness |
| Trade.GetPositionsForFeeBulkGeneral | - | Reader | Bulk fee processing reads fee rates |
| Trade.CalculatePositionOvernightFee | - | Reader | Per-position fee calculation function |
| Trade.SplitHoldingFees | - | Reader | Fee splitting logic |
| Trade.UpdateInstrumentToFeeConfigTable | - | Reader/Writer | Updates fee configuration (reads current, writes new) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentToFeeConfig (view)
+-- Trade.InstrumentToFeeConfigV2 (table)
+-- Trade.InstrumentMetaData (table)
+-- Trade.GetInstrumentTypeIDsForCFDFee (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentToFeeConfigV2 | Table | FROM - all fee rate data via CTEs filtered by SettlementTypeID |
| Trade.InstrumentMetaData | Table | INNER JOIN - InstrumentTypeID for CFD fee type determination |
| Trade.GetInstrumentTypeIDsForCFDFee | Function | LEFT JOIN - identifies instrument types with special CFD fee handling |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CalcOverNightFeeRates | Stored Procedure | Reader - uses fee rates for overnight fee calculation |
| Trade.GetInstrumentToFeeConfiguration | Stored Procedure | Reader - API/UI fee config display |
| Trade.RolloverFeesAlertIfNeeded | Stored Procedure | Reader - fee alert monitoring |
| Trade.CheckValidInstruments | Stored Procedure | Reader - instrument validation |
| Trade.GetPositionsForFeeBulkGeneral | Stored Procedure | Reader - bulk fee processing |
| Trade.CalculatePositionOvernightFee | Function | Reader - per-position fee calculation |
| Trade.SplitHoldingFees | Stored Procedure | Reader - fee splitting |
| Trade.UpdateInstrumentToFeeConfigTable | Stored Procedure | Reader/Writer - fee config updates |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Show fee configuration for a specific instrument
```sql
SELECT  *
FROM    Trade.InstrumentToFeeConfig WITH (NOLOCK)
WHERE   InstrumentID = 1;
```

### 8.2 Find instruments with negative overnight fees (customer credits)
```sql
SELECT  InstrumentID,
        LeveragedSellOverNightFee,
        LeveragedBuyOverNightFee
FROM    Trade.InstrumentToFeeConfig WITH (NOLOCK)
WHERE   LeveragedSellOverNightFee < 0
        OR LeveragedBuyOverNightFee < 0
ORDER BY InstrumentID;
```

### 8.3 Compare leveraged vs non-leveraged buy fees
```sql
SELECT  InstrumentID,
        NonLeveragedBuyOverNightFee   AS NonLevBuyON,
        LeveragedBuyOverNightFee      AS LevBuyON,
        NonLeveragedBuyCFDOverNightFee AS CFDBuyON
FROM    Trade.InstrumentToFeeConfig WITH (NOLOCK)
WHERE   LeveragedBuyOverNightFee > 0
ORDER BY LeveragedBuyOverNightFee DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. The view's DDL contains an explicit deprecation notice: "This view is obsolete and created for backward compatibility. Will be removed in the future. Use Trade.InstrumentToFeeConfigV2 instead."

---

*Generated: 2026-03-15 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentToFeeConfig | Type: View | Source: etoro/etoro/Trade/Views/Trade.InstrumentToFeeConfig.sql*
