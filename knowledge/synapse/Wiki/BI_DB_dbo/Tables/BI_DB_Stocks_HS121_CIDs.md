# BI_DB_dbo.BI_DB_Stocks_HS121_CIDs

> 32.75B-row daily CID-level stock and ETF position aggregation across 10 hedge servers (HS121, HS125, HS126, HS112, HS130, HS128, HS9, HS3, HS102, HS124) for Finance/Regulation Tableau reporting. Built by SP_Stocks_HS125 (Amir Gurewitz, 2019) from BI_DB_PositionPnL joined with Dim_Instrument, Dim_Customer, Dim_Regulation, and Fact_CurrencyPriceWithSplit. Daily DELETE+INSERT by Date. Data from May 2020 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_Stocks_HS125 (BI_DB_dbo) — Amir Gurewitz, 2019 |
| **Refresh** | Daily — DELETE+INSERT by Date |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_stocks_hs121_cids` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

This table provides a daily per-customer per-instrument aggregation of stock and ETF positions across multiple hedge servers used by different regulatory entities. It is the CID-level detail view (sibling of BI_DB_Stocks_HS125 which is instrument-level without CID).

Each row represents one customer's aggregated position for a specific instrument on a specific hedge server and settlement status (settled vs CFD) for one day. The data captures total units held, position value (NOP), closing price, position count, and equity.

The hedge servers represent different regulatory execution venues:
- HS121, HS125: Primary stock/ETF execution
- HS126, HS112: Additional venues (CySEC, FCA)
- HS130, HS128, HS9, HS3: Extended venues (added Sep 2022)
- HS102, HS124: Additional venues (added Feb 2023)

Only InstrumentTypeID 5 (Stocks) and 6 (ETF) are included. Valid customers only (IsValidCustomer=1).

With ~6 years of daily data across thousands of instruments and millions of customer-instrument combinations per day, the table holds approximately 32.75 billion rows — one of the largest BI_DB tables.

---

## 2. Business Logic

### 2.1 Hedge Server Scope

**What**: Covers 10 hedge servers across regulatory entities.
**Columns Involved**: HedgeServerID
**Rules**:
- HedgeServerID IN (121, 125, 126, 112, 130, 128, 9, 3, 102, 124)
- Expanded over time: original (121,125), then 126/112, then 130/128/9/3 (Sep 2022), then 102/124 (Feb 2023)

### 2.2 Position Aggregation

**What**: Aggregates individual positions to CID × Instrument × HedgeServer × IsSettled level.
**Columns Involved**: TotalUnits, PositionValue, CountPositions, Equity
**Rules**:
- TotalUnits = SUM(AmountInUnitsDecimal) — fractional shares
- PositionValue = SUM(NOP) — net open position in USD
- CountPositions = COUNT(PositionID) — number of open positions
- Equity = SUM(Amount + PositionPnL) — total position equity including unrealized P&L
- GROUP BY CID, HedgeServerID, InstrumentID, InstrumentDisplayName, IsSettled, Regulation, ClosingPrice

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on [Date]. **Extremely large table (32.75B rows)**. Always include Date filter.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's stock holdings today | `WHERE Date = '2026-04-12' AND CID = X` |
| Instrument exposure by regulation | `WHERE Date = '2026-04-12' GROUP BY Regulation, InstrumentDisplayName` |
| Hedge server position split | `WHERE Date = '2026-04-12' GROUP BY HedgeServerID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer attributes |
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument details |
| BI_DB_dbo.BI_DB_Stocks_HS125 | Date + HedgeServerID + InstrumentID + IsSettled | Instrument-level aggregate |

### 3.4 Gotchas

- **32.75B rows**: Always filter by Date — full scan will timeout
- **SP name is SP_Stocks_HS125**: Despite the table being named HS121_CIDs, the SP handles both BI_DB_Stocks_HS125 (instrument-level) and BI_DB_Stocks_HS121_CIDs (CID-level)
- **ClosingPrice is Bid**: From Fact_CurrencyPriceWithSplit, not a true "closing" price — it's the bid price at the date's snapshot
- **IsSettled distinguishes real vs CFD**: 1=real/settled asset, 0=CFD — same instrument can have both rows
- **Equity can differ from PositionValue**: Equity = Amount + PositionPnL (unrealized equity), PositionValue = NOP (net open position based on current price × units)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest |
| Tier 2 | SP code analysis | High |
| Tier 5 | ETL metadata | Standard |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NOT NULL | Reporting date. Clustered index key. Daily snapshots from May 2020 to present. (Tier 2 — SP_Stocks_HS125) |
| 2 | CID | int | YES | Customer ID holding the positions. References Dim_Customer.RealCID. Filtered to IsValidCustomer=1. (Tier 2 — SP_Stocks_HS125) |
| 3 | HedgeServerID | int | YES | Hedge server executing the positions. Values: 121, 125, 126, 112, 130, 128, 9, 3, 102, 124. Determines execution venue and regulatory routing. (Tier 2 — SP_Stocks_HS125) |
| 4 | InstrumentID | int | YES | Instrument identifier. FK to Dim_Instrument. Only InstrumentTypeID 5 (Stocks) and 6 (ETF). (Tier 2 — SP_Stocks_HS125) |
| 5 | InstrumentDisplayName | varchar(250) | YES | User-facing instrument display name from Dim_Instrument. More descriptive than Symbol (e.g., "Snowflake Inc.", "Micron Technology, Inc."). Passthrough from Dim_Instrument. (Tier 2 — SP_Stocks_HS125) |
| 6 | IsSettled | tinyint | YES | 1 = real/settled asset, 0 = CFD. Same instrument can appear with both values. (Tier 5 — Expert Review) |
| 7 | Regulation | varchar(50) | YES | Regulatory authority name. Passthrough from Dim_Regulation.Name via Dim_Customer.RegulationID. Values: CySEC, FCA, FinCEN+FINRA, ASIC&GAML, etc. (Tier 1 — Dictionary.Regulation) |
| 8 | ClosingPrice | float | YES | Bid price from Fact_CurrencyPriceWithSplit for the instrument on this date. Used for NOP calculation context. (Tier 2 — SP_Stocks_HS125) |
| 9 | TotalUnits | decimal(30,8) | YES | Total fractional shares/units held. SUM(AmountInUnitsDecimal) across all positions for this CID × instrument × HS × IsSettled grouping. (Tier 2 — SP_Stocks_HS125) |
| 10 | PositionValue | money | YES | Net open position value in USD. SUM(NOP) across positions. (Tier 2 — SP_Stocks_HS125) |
| 11 | CountPositions | int | YES | Number of individual positions in this grouping. COUNT(PositionID). (Tier 2 — SP_Stocks_HS125) |
| 12 | UpdateDate | datetime | YES | ETL metadata: row insert timestamp (GETDATE()). (Tier 5 — ETL metadata) |
| 13 | Equity | decimal(16,4) | YES | Total position equity including unrealized P&L. SUM(Amount + PositionPnL). Can differ from PositionValue due to different calculation basis. (Tier 2 — SP_Stocks_HS125) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID, HedgeServerID, InstrumentID, IsSettled | BI_DB_PositionPnL | Various | GROUP BY keys |
| InstrumentDisplayName | Dim_Instrument | InstrumentDisplayName | Passthrough |
| Regulation | Dictionary.Regulation | Name | Dim-lookup |
| ClosingPrice | Fact_CurrencyPriceWithSplit | Bid | Passthrough |
| TotalUnits | BI_DB_PositionPnL | AmountInUnitsDecimal | SUM |
| PositionValue | BI_DB_PositionPnL | NOP | SUM |
| CountPositions | BI_DB_PositionPnL | PositionID | COUNT |
| Equity | BI_DB_PositionPnL | Amount + PositionPnL | SUM |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (daily position snapshot)
DWH_dbo.Dim_Instrument (instrument display name)
DWH_dbo.Dim_Customer (valid customer filter)
DWH_dbo.Dim_Regulation (regulation name)
DWH_dbo.Fact_CurrencyPriceWithSplit (closing bid price)
  |-- SP_Stocks_HS125 @Date (DELETE+INSERT by Date) ---|
  v
BI_DB_dbo.BI_DB_Stocks_HS121_CIDs (32.75B rows)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_stocks_hs121_cids
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument dimension |
| Date | DWH_dbo.Dim_Date | Calendar dimension |

### 6.2 Referenced By (other objects point to this)

Used by Tableau Finance/Regulation stock holdings reports.

---

## 7. Sample Queries

### 7.1 Customer Stock Holdings Today

```sql
SELECT InstrumentDisplayName, IsSettled, Regulation, TotalUnits, PositionValue, Equity
FROM BI_DB_dbo.BI_DB_Stocks_HS121_CIDs
WHERE Date = '2026-04-12' AND CID = 6867552
ORDER BY PositionValue DESC
```

### 7.2 Top Instruments by Regulation

```sql
SELECT Regulation, InstrumentDisplayName,
       SUM(PositionValue) AS total_value, SUM(CountPositions) AS total_positions
FROM BI_DB_dbo.BI_DB_Stocks_HS121_CIDs
WHERE Date = '2026-04-12'
GROUP BY Regulation, InstrumentDisplayName
ORDER BY total_value DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 1 T1, 10 T2, 0 T3, 0 T4, 2 T5 | Elements: 13/13, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_Stocks_HS121_CIDs | Type: Table | Production Source: SP_Stocks_HS125*
