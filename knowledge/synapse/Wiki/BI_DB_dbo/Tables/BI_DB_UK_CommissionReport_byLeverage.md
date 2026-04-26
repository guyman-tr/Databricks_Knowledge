# BI_DB_dbo.BI_DB_UK_CommissionReport_byLeverage

> 192,946-row monthly commission and trade-count breakdown table (January 2018 – March 2026, 99 months) aggregating all valid-customer close and open actions by region, regulation, leverage level, and instrument type. Written monthly by SP_M_UK_CommissionReport_byLeverage using a DELETE-month + INSERT pattern sourcing from Fact_CustomerAction joined to Dim_Position, Dim_Customer, Dim_Country, Dim_Regulation, and Dim_Instrument.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction (via SP_M_UK_CommissionReport_byLeverage) |
| **Refresh** | Monthly — SP_M_UK_CommissionReport_byLeverage @dd DATE; DELETE WHERE CalendarMonth=MONTH(@dd) AND CalendarYear=YEAR(@dd) + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CalendarYear ASC, CalendarMonth ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

192,946-row monthly aggregation table (January 2018 – March 2026, 99 months) tracking commission revenue and trade counts by the full cross-section of: geographic region × regulatory jurisdiction × leverage level × instrument type. Each row represents the total commission (in USD) and total number of actions (opens or closes) for one combination of those four dimensions within a calendar month.

Despite the "UK" prefix in the table name, this table covers **all regulations** (CySEC 27%, FCA 20%, ASIC 17%, ASIC & GAML 14%, FSA Seychelles 12%, BVI 7%, and 7 others) — the name reflects the team that commissioned it. The table provides the primary instrument-level leverage breakdown for commission analysis that standard commission tables lack.

The SP uses **two UNION branches**: close/expiry/rollover actions (ActionTypeID 4,5,6) use `FullCommissionOnClose - FullCommissionByUnits`; open/limit/stop actions (ActionTypeID 1,2,3) use `FullCommissionByUnits` (spread-based). Both branches filter `IsValidCustomer = 1`. The UNION is wrapped in an outer GROUP BY that collapses to the final grain.

Commission ranges from -790,193 (reversals/refunds) to 27,531,856 (large closed positions). Trades per group: 1 to 16,290,016.

---

## 2. Business Logic

### 2.1 Dual Commission Formula by Action Type

**What**: Two different commission calculation methods are applied depending on whether the action is an open or a close.

**Columns Involved**: `Commission`, data from Fact_CustomerAction.FullCommissionOnClose, FullCommissionByUnits

**Rules**:
- ActionTypeID IN(4,5,6) → close/expiry/rollover: `Commission = SUM(FullCommissionOnClose - FullCommissionByUnits)`
- ActionTypeID IN(1,2,3) → open/limit/stop: `Commission = SUM(FullCommissionByUnits)`
- The two streams are UNIONed before the outer aggregation GROUP BY
- Negative Commission values are valid (represent reversals or positions with refunded commission)

### 2.2 Month Rebuild Pattern

**What**: Each monthly run deletes and re-inserts the entire month being processed.

**Columns Involved**: `CalendarYear`, `CalendarMonth`, `EOMonth`

**Rules**:
- DELETE: `WHERE MONTH(@dd) = CalendarMonth AND YEAR(@dd) = CalendarYear`
- INSERT: DateID range = first day of month (EOMONTH(@dd,-1)+1) to end of month (EOMONTH(@dd))
- Re-running for the same month is safe (idempotent delete-insert)
- EOMonth = EOMONTH(Occurred) — confirms the month grouping date

### 2.3 Regulation at Open Time

**What**: Regulation reflects the customer's regulatory jurisdiction at position open time, not close time.

**Columns Involved**: `Regulation`

**Rules**:
- Sourced from `Dim_Position.RegulationIDOnOpen` → `Dim_Regulation.Name`
- Customers who changed regulation between open and close retain the open-time regulation in this table
- 14 distinct regulation values; 'None' (532 rows) = missing regulatory assignment

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no skew risk. CLUSTERED INDEX on (CalendarYear, CalendarMonth) makes time-range filtering efficient. For queries spanning multiple months, filtering on both CalendarYear and CalendarMonth outperforms filtering on EOMonth (index alignment). For most-recent-month analysis, use `WHERE CalendarYear = 2026 AND CalendarMonth = 3`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total FCA commission by instrument type for 2025 | `WHERE Regulation='FCA' AND CalendarYear=2025 GROUP BY InstrumentType` |
| Monthly commission trend by leverage | `GROUP BY CalendarYear, CalendarMonth, Leverage ORDER BY CalendarYear, CalendarMonth` |
| Regulation breakdown for a specific month | `WHERE CalendarYear=2026 AND CalendarMonth=3 GROUP BY Regulation SUM(Commission)` |
| Leverage distribution of Crypto trades | `WHERE InstrumentType='Crypto Currencies' GROUP BY Leverage` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| (self-aggregation) | CalendarYear, CalendarMonth | Monthly trend analysis |
| BI_DB_dbo.BI_DB_DailyCommisionReport | EOMonth | Cross-validate monthly commission totals |

### 3.4 Gotchas

- **"UK" is misleading**: All 14 regulations are present; this is not FCA-only data.
- **Negative Commission**: Valid — commission reversals create negative SUM values. Do not filter out negatives.
- **Two action types contribute**: Both opens (1,2,3) and closes (4,5,6) appear as `Trades`. Do not assume all trades are closed positions.
- **Regulation = 'None'**: 532 rows where regulation could not be assigned (NULL in Dim_Regulation or missing join). These represent ~0.3% of rows — exclude from regulation-specific analysis.
- **Leverage=1**: Includes stocks/ETF/crypto (non-leveraged positions). Do not assume Leverage=1 means "no leverage product".
- **Grain**: One row per month × region × regulation × leverage × instrumenttype. A position with 10x leverage on CySEC Commodities out of Spain counts separately from 5x leverage.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Copied verbatim from an upstream wiki (DWH_dbo dimension or production source) |
| Tier 2 | Derived from SP code — ETL-computed or aggregated from DWH source |
| Tier 3 | Inferred from data sampling and business context |
| Tier 4 | Best available knowledge; requires SME validation |
| Tier 5 | Cross-schema or domain-level canonical definition |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CalendarYear | int | NO | Calendar year of the actions aggregated in this row. Derived from YEAR(Fact_CustomerAction.Occurred). Used with CalendarMonth as the composite time key. (Tier 2 — SP_M_UK_CommissionReport_byLeverage) |
| 2 | CalendarMonth | int | NO | Calendar month (1–12) of the actions aggregated in this row. Derived from MONTH(Fact_CustomerAction.Occurred). (Tier 2 — SP_M_UK_CommissionReport_byLeverage) |
| 3 | Region | varchar(50) | NO | Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., "ROW", "Africa", "French", "Arabic Other"). Used for marketing campaign grouping. (Tier 1 — DWH_dbo.Dim_Country) |
| 4 | Regulation | varchar(50) | NO | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Reflects regulation at position open time (RegulationIDOnOpen). 14 distinct values: CySEC, FCA, ASIC, ASIC & GAML, FSA Seychelles, BVI, FSRA, None, FinCEN, FinCEN+FINRA, eToroUS, MAS, NFA, NYDFS+FINRA. (Tier 1 — Dictionary.Regulation) |
| 5 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. 11 distinct values: 1, 2, 5, 10, 20, 25, 30, 50, 100, 200, 400. Leverage=1 includes stocks/ETF/crypto (non-leveraged). (Tier 1 — Trade.PositionTbl) |
| 6 | InstrumentType | varchar(50) | NO | Text label for InstrumentTypeID -- DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display. 6 distinct values in this table. (Tier 1 — DWH_dbo.Dim_Instrument) |
| 7 | Commission | int | NO | Total commission (USD) for this dimension group and month. SUM of two formulas: ActionTypeID IN(4,5,6)→SUM(FullCommissionOnClose-FullCommissionByUnits); ActionTypeID IN(1,2,3)→SUM(FullCommissionByUnits). Negative values are valid (reversals). Range: -790,193 to 27,531,856. (Tier 2 — SP_M_UK_CommissionReport_byLeverage) |
| 8 | Trades | int | NO | Count of individual action rows (not positions) within this dimension group and month. Counts both open and close actions (ActionTypeID 1-6, IsValidCustomer=1). Range: 1 to 16,290,016. (Tier 2 — SP_M_UK_CommissionReport_byLeverage) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 2 — SP_M_UK_CommissionReport_byLeverage) |
| 10 | EOMonth | date | YES | End-of-month date for the calendar month being aggregated (e.g., 2026-03-31). Derived from EOMONTH(Fact_CustomerAction.Occurred). Useful for time-series joins and BI tools that expect date keys. (Tier 2 — SP_M_UK_CommissionReport_byLeverage) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|--------------|-----------|
| CalendarYear | DWH_dbo.Fact_CustomerAction | Occurred | YEAR(Occurred) |
| CalendarMonth | DWH_dbo.Fact_CustomerAction | Occurred | MONTH(Occurred) |
| Region | DWH_dbo.Dim_Country | Region | Passthrough via JOIN (Dim_Customer→Dim_Country on CountryID) |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough via JOIN (Dim_Position.RegulationIDOnOpen→Dim_Regulation.ID) |
| Leverage | DWH_dbo.Fact_CustomerAction | Leverage | Passthrough — GROUP BY key |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough via JOIN on InstrumentID |
| Commission | DWH_dbo.Fact_CustomerAction | FullCommissionOnClose, FullCommissionByUnits | SUM aggregate (two formulas by ActionTypeID) |
| Trades | DWH_dbo.Fact_CustomerAction | — | COUNT(1) |
| UpdateDate | — | — | GETDATE() |
| EOMonth | DWH_dbo.Fact_CustomerAction | Occurred | EOMONTH(Occurred) |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionTypeID 1-6, IsValidCustomer=1)
  + DWH_dbo.Dim_Position   (RegulationIDOnOpen)
  + DWH_dbo.Dim_Customer   (CountryID)
  + DWH_dbo.Dim_Country    (Region)
  + DWH_dbo.Dim_Regulation (Name)
  + DWH_dbo.Dim_Instrument (InstrumentType)
    |-- SP_M_UK_CommissionReport_byLeverage @dd DATE (Monthly) ---|
    |   DELETE WHERE CalendarMonth=MONTH(@dd) AND CalendarYear=YEAR(@dd)
    |   UNION two commission streams + outer GROUP BY
    v
BI_DB_dbo.BI_DB_UK_CommissionReport_byLeverage
  (192,946 rows, Jan 2018 – Mar 2026, ROUND_ROBIN)
  (UC: Not Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Regulation | DWH_dbo.Dim_Regulation | Regulation name (at position open) |
| Leverage | DWH_dbo.Fact_CustomerAction | Leverage multiplier from trade record |
| Region | DWH_dbo.Dim_Country | Geographic/marketing region |
| InstrumentType | DWH_dbo.Dim_Instrument | Instrument category label |

### 6.2 Referenced By

| Object | Reference Column | Description |
|--------|-----------------|-------------|
| (none identified) | — | No downstream consumers found in SSDT repo scan |

---

## 7. Sample Queries

### Monthly FCA Commission Trend by Instrument Type (2025)

```sql
SELECT
    CalendarMonth,
    InstrumentType,
    SUM(Commission) AS total_commission,
    SUM(Trades)     AS total_trades
FROM [BI_DB_dbo].[BI_DB_UK_CommissionReport_byLeverage]
WHERE CalendarYear = 2025
  AND Regulation = 'FCA'
GROUP BY CalendarMonth, InstrumentType
ORDER BY CalendarMonth, total_commission DESC;
```

### Leverage Distribution for Crypto Currencies (March 2026)

```sql
SELECT
    Leverage,
    SUM(Commission) AS commission,
    SUM(Trades)     AS trades
FROM [BI_DB_dbo].[BI_DB_UK_CommissionReport_byLeverage]
WHERE CalendarYear = 2026
  AND CalendarMonth = 3
  AND InstrumentType = 'Crypto Currencies'
GROUP BY Leverage
ORDER BY Leverage;
```

### Annual Commission by Regulation (All Years)

```sql
SELECT
    CalendarYear,
    Regulation,
    SUM(Commission) AS annual_commission,
    SUM(Trades)     AS annual_trades
FROM [BI_DB_dbo].[BI_DB_UK_CommissionReport_byLeverage]
WHERE Regulation <> 'None'
GROUP BY CalendarYear, Regulation
ORDER BY CalendarYear DESC, annual_commission DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this table. Author: Bradley Roberts (2020-02-12), updated 2021-09-23 to include RegulationOnOpen and Month (EOMonth) fields.

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 10/14*
*Tiers: 4 T1, 6 T2, 0 T3, 0 T4 | Elements: 10/10, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_UK_CommissionReport_byLeverage | Type: Table | Production Source: DWH_dbo.Fact_CustomerAction*
