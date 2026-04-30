# BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType

> 18-row quarterly aggregation table summarizing total trading volume and USD value by investor type segment (Seychelles, EU, Other) for FSA Seychelles (RegulationID=9) regulated customers. Populated by `SP_Q_AML_FSA_Report` via DELETE+INSERT per quarter. Contains 6 quarterly snapshots (Q4 2024 through Q1 2026) with 3 rows per quarter.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position (trading data) + DWH_dbo.Fact_SnapshotCustomer (population/investor type) via `SP_Q_AML_FSA_Report` |
| **Refresh** | Quarterly (DELETE+INSERT per EndDateID) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_Q_AML_FSA_Report_end_InvestorType` is one of four companion tables produced by `SP_Q_AML_FSA_Report` for the FSA Seychelles quarterly AML regulatory report. While the sibling tables (`_end`, `_end_Positions`, `_end_Market_Value`) provide customer-level and instrument-level detail, this table aggregates total trading volume and USD-equivalent trading value at the investor type segment level — collapsing all individual customer activity into one row per investor type per quarter.

The population is restricted to FSA Seychelles regulated customers (RegulationID=9) who are verified depositors (IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3). Investor type is derived from the customer's country: Seychelles (CountryID=181), US (CountryID=219), EU (Dim_Country.EU=1), or Other (residual). The SP code also supports an 'Unclassified' bucket, but in practice only three segments appear: Seychelles, EU, and Other — no US or Unclassified rows exist in the current data.

As of 2026-04-29: 18 rows across 6 quarterly snapshots (20241231–20260331). TradingVolume ranges from ~165K to ~72B units; TradingValueUSD ranges from ~$22M to ~$2.9T, with the 'Other' segment dominating both metrics.

---

## 2. Business Logic

### 2.1 Investor Type Classification

**What**: Mutually exclusive investor type segments based on customer country, applied to the FSA Seychelles population.

**Columns Involved**: `Investor_Type`

**Rules**:
- Evaluated in priority order (first match wins):
  1. CountryID = 181 → 'Seychelles'
  2. CountryID = 219 → 'US'
  3. Dim_Country.EU = 1 → 'EU'
  4. None of the above → 'Other'
  5. No flags match → 'Unclassified' (never observed in live data)
- The same classification is used in the sibling `_start` and `_end` tables via `Is_Seychelles_Investor`, `Is_United_States_Investor`, `Is_EU_Investor`, `Is_Other_Country_Investor` flags
- Only 3 values currently present: Seychelles, EU, Other (no US investors under FSA Seychelles regulation observed)

### 2.2 Trading Volume Aggregation

**What**: Total units traded within the quarter, aggregated per investor type.

**Columns Involved**: `TradingVolume`

**Rules**:
- For position opens within the quarter: SUM(InitialUnits) from Dim_Position (excluding partial-close children: `ISNULL(IsPartialCloseChild,0) = 0`)
- For position closes within the quarter: SUM(AmountInUnitsDecimal) from Dim_Position
- TradingVolume = SUM(open units + close units) per investor type
- Units vary by instrument (shares, coins, lots) — not normalized across asset classes

### 2.3 Trading Value USD Aggregation

**What**: Total USD-equivalent value of trades within the quarter, aggregated per investor type.

**Columns Involved**: `TradingValueUSD`

**Rules**:
- For opens: SUM(InitialUnits * InitForexRate * InitConversionRate) — value at time of opening
- For closes: SUM(AmountInUnitsDecimal * EndForexRate * EndForex_USDConversionRate) — value at time of closing
- TradingValueUSD = SUM(open value + close value) per investor type
- Forex rates are historical (at trade time), not mark-to-market at quarter end

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — 18 rows total. Full table scan is trivial. No optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Trading value by investor type for latest quarter | `WHERE EndDateID = (SELECT MAX(EndDateID) FROM BI_DB_Q_AML_FSA_Report_end_InvestorType)` |
| Quarter-over-quarter trend by segment | `SELECT EndDateID, Investor_Type, TradingValueUSD FROM ... ORDER BY EndDateID, Investor_Type` |
| Total platform trading value per quarter | `SELECT EndDateID, SUM(TradingValueUSD) FROM ... GROUP BY EndDateID` |
| Seychelles share of total | `CASE WHEN Investor_Type = 'Seychelles' THEN TradingValueUSD END / SUM(TradingValueUSD) OVER (PARTITION BY EndDateID)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Q_AML_FSA_Report_end | `EndDateID = Report_End_Date` | Combine investor-type aggregates with customer-level detail (aggregated comparison only) |
| BI_DB_Q_AML_FSA_Report_end_Positions | `EndDateID = Report_End_Date` | Compare investor-type totals with per-CID instrument-level detail |
| BI_DB_Q_AML_FSA_Report_end_Market_Value | `EndDateID = End_DateID` | Combine trading activity with market value exposure |

### 3.4 Gotchas

- **EndDateID is int, not date**: Stored as YYYYMMDD integer (e.g., 20260331). Use `CAST(CAST(EndDateID AS VARCHAR) AS DATE)` for date functions.
- **No US or Unclassified rows**: Despite the SP supporting 5 investor type values, only 3 appear in live data. US investors under FSA Seychelles regulation are apparently absent.
- **TradingVolume units not normalized**: Volumes mix shares, crypto coins, and CFD lots. Do not compare TradingVolume across quarters without controlling for instrument mix.
- **TradingValueUSD uses historical FX rates**: Open values use InitForexRate/InitConversionRate at trade time; close values use EndForexRate/EndForex_USDConversionRate at close time. Not mark-to-market.
- **Money type columns**: TradingVolume and TradingValueUSD are money type (4 decimal places). Be aware of implicit rounding in arithmetic.
- **'Other' dominates**: The 'Other' segment contains the vast majority of trading activity, as most FSA Seychelles customers are from non-EU, non-Seychelles, non-US countries.
- **Multiple quarters in one table**: Always filter on `EndDateID` to avoid mixing snapshots.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 — SP code / ETL computed | `(Tier 2 — source)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Investor_Type | nvarchar(250) | YES | Investor segment classification for FSA Seychelles AML reporting. Values: 'Seychelles' (CountryID=181), 'US' (CountryID=219, not observed), 'EU' (Dim_Country.EU=1), 'Other' (residual), 'Unclassified' (fallback, not observed). Derived from Fact_SnapshotCustomer.CountryID and Dim_Country.EU flag via CASE priority order. (Tier 2 — Fact_SnapshotCustomer / Dim_Country) |
| 2 | EndDateID | int | YES | Quarter-end date as YYYYMMDD integer (e.g., 20260331). Identifies which quarterly snapshot this row belongs to. Computed from the @Date SP parameter. 6 distinct values from 20241231 to 20260331. (Tier 2 — SP_Q_AML_FSA_Report) |
| 3 | TradingVolume | money | YES | Total units traded during the quarter by all customers in this investor type segment. SUM of InitialUnits (opens, excl. partial-close children) + AmountInUnitsDecimal (closes) from Dim_Position. Units vary by instrument type (shares, coins, lots). (Tier 2 — Dim_Position) |
| 4 | TradingValueUSD | money | YES | Total USD-equivalent value of all trades during the quarter by this investor type segment. SUM of (InitialUnits * InitForexRate * InitConversionRate) for opens + (AmountInUnitsDecimal * EndForexRate * EndForex_USDConversionRate) for closes. Historical FX rates at trade time, not mark-to-market. (Tier 2 — Dim_Position) |
| 5 | UpdateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. All rows in a quarterly batch share the same value. (Tier 2 — SP_Q_AML_FSA_Report) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object(s) | Source Column(s) | Transform |
|---------------|-----------------|-----------------|-----------|
| Investor_Type | Fact_SnapshotCustomer, Dim_Country | CountryID, EU | CASE priority: 181→Seychelles, 219→US, EU=1→EU, else→Other |
| EndDateID | SP parameter | @EndDateID | Quarter-end YYYYMMDD int computed from @Date input |
| TradingVolume | Dim_Position | InitialUnits, AmountInUnitsDecimal | SUM(open units + close units) per investor segment |
| TradingValueUSD | Dim_Position | InitialUnits, InitForexRate, InitConversionRate, AmountInUnitsDecimal, EndForexRate, EndForex_USDConversionRate | SUM(USD-converted open + close values) per investor segment |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (RegulationID=9, IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3)
  + DWH_dbo.Dim_Country (EU flag, CountryID for investor type classification)
  + DWH_dbo.Dim_Range (DateRangeID → @EndDateID date filtering)
  + DWH_dbo.Dim_Regulation (RegulationID=9 = FSA Seychelles)
    └── #pop_end (qualified FSA Seychelles customer population)

DWH_dbo.Dim_Position (opens + closes within quarter date range)
  + #pop_end (CID filter to FSA population)
    └── #trade_events (per-position open/close units and USD values)
      └── #trading_cid (SUM per CID: TradingVolume, TradingValueUSD)
        + #pop_end (investor type flags)
          └── #investor_Type (SUM per Investor_Type segment)

  |-- SP_Q_AML_FSA_Report (quarterly DELETE+INSERT per EndDateID)
  v
BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType (18 rows, ROUND_ROBIN HEAP)
  |-- No UC target (Not_Migrated) --|
  v
(Quarterly FSA Seychelles AML regulatory report — investor type trading summary)
```

| Step | Object | Description |
|------|--------|-------------|
| Population | Fact_SnapshotCustomer + Dim_Range + Dim_Country + Dim_Regulation | Filter to FSA Seychelles verified depositors at quarter end |
| Trade Events | Dim_Position | Extract open/close units and USD values for positions within quarter |
| CID Aggregation | #trading_cid | SUM trading volume and value per CID |
| Segment Aggregation | #investor_Type | GROUP BY investor type (Seychelles/US/EU/Other) |
| Load | SP_Q_AML_FSA_Report | DELETE WHERE EndDateID = @EndDateID, then INSERT from #investor_Type |
| Target | BI_DB_Q_AML_FSA_Report_end_InvestorType | 3 rows per quarter (18 total across 6 quarters) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Investor_Type | DWH_dbo.Dim_Country (CountryID, EU) | Country-based investor classification |
| TradingVolume, TradingValueUSD | DWH_dbo.Dim_Position | Position open/close data |

### 6.2 Referenced By (other objects point to this)

| Consuming Object | Relationship |
|-----------------|-------------|
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end | Sibling table — same SP, customer-level detail |
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Positions | Sibling table — same SP, per-CID instrument-level trading |
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_Market_Value | Sibling table — same SP, market value by instrument type |
| BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start | Sibling table — same SP, start-of-quarter customer snapshot |

---

## 7. Sample Queries

### 7.1 Trading Value by Investor Type — Latest Quarter

```sql
SELECT
    Investor_Type,
    TradingVolume,
    TradingValueUSD,
    TradingValueUSD * 100.0 / SUM(TradingValueUSD) OVER () AS Pct_of_Total
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType
WHERE EndDateID = (SELECT MAX(EndDateID) FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType)
ORDER BY TradingValueUSD DESC
```

### 7.2 Quarter-over-Quarter Trading Value Trend

```sql
SELECT
    EndDateID,
    Investor_Type,
    TradingValueUSD,
    TradingValueUSD - LAG(TradingValueUSD) OVER (PARTITION BY Investor_Type ORDER BY EndDateID) AS QoQ_Change
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType
ORDER BY EndDateID, Investor_Type
```

### 7.3 Total Platform Trading Summary per Quarter

```sql
SELECT
    EndDateID,
    SUM(TradingVolume) AS Total_Volume,
    SUM(TradingValueUSD) AS Total_Value_USD,
    COUNT(DISTINCT Investor_Type) AS Segment_Count
FROM BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType
GROUP BY EndDateID
ORDER BY EndDateID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources identified for this object. (Phase 10 skipped — regen harness mode.)

---

*Generated: 2026-04-29 | Quality: 8.0/10 (★★★★☆) | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 5/5, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType | Type: Table | Production Source: DWH_dbo.Dim_Position + DWH_dbo.Fact_SnapshotCustomer via SP_Q_AML_FSA_Report*
