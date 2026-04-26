# BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument

> 36,671-row ESMA regulatory reporting table aggregating CFD client profitability by regulation AND instrument type over rolling 12-month windows, from Q1 2024 to Q2 2026. Companion to `BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months` — adds InstrumentTypeID and InstrumentType dimensions (Stocks, Currencies, Commodities, Indices, ETF, Crypto Currencies). Same SP writes both tables. Refreshed daily via `SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months` with delete-insert by StartDateID+EndDateID.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed from DWH_dbo.Fact_SnapshotCustomer + Dim_Position + Dim_Instrument + BI_DB_PositionPnL + Fact_CustomerAction via `SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months` |
| **Refresh** | Daily (delete-insert by StartDateID+EndDateID). Author: Yarden Sabadra, 2024-01-17. OpsDB: SB_Daily, Priority 0 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is the **instrument-level companion** to `BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months`. While the parent table aggregates CFD profitability at the regulation level, this table further breaks down the same metrics by instrument type (Stocks, Currencies, Commodities, Indices, ETF, Crypto Currencies).

The same SP (`SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months`) populates both tables in a single run. The instrument-level breakdown is produced by grouping on `InstrumentTypeID` and `InstrumentType` from `DWH_dbo.Dim_Instrument` instead of collapsing to regulation only.

The table has 36,671 rows — approximately 5.7x the parent table (6,430), reflecting the 6 instrument types creating multiple rows per regulation per window.

Key difference from the parent: A single customer may appear in multiple instrument type rows if they traded across multiple instrument types. Therefore, summing Total_Customers across instrument types for a regulation will overcount vs the parent table's Total_Customers.

All other logic (rolling 12-month window, PnL classification, population filters) is identical to the parent table. See `BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months.md` for full business logic documentation.

---

## 2. Business Logic

### 2.1 Rolling 12-Month Window

Same as parent table. See `BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months.md` Section 2.1.

### 2.2 Instrument Type Breakdown

**What**: Breaks down profitability metrics by the type of instrument traded.
**Columns Involved**: InstrumentTypeID, InstrumentType
**Rules**:
- Source: `DWH_dbo.Dim_Instrument` JOINed on InstrumentID from Dim_Position and BI_DB_PositionPnL
- 6 distinct instrument types: Stocks, Currencies, Commodities, Indices, ETF, Crypto Currencies
- GROUP BY includes InstrumentTypeID and InstrumentType in addition to RegulationID
- A customer trading Stocks and Currencies appears in BOTH rows (overcounts vs parent)

### 2.3 Customer PnL Classification

Same as parent table. See `BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months.md` Section 2.2. Applied per regulation × instrument type.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED COLUMNSTORE INDEX. Moderate size (36K rows). CCI provides good compression.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| % profitable by instrument for CySEC? | `SELECT InstrumentType, ProfitTotalPnL*100.0/NULLIF(Total_Customers,0) FROM ... WHERE Regulation='CySEC' AND EndDateID=(SELECT MAX(EndDateID) FROM ...)` |
| Which instrument has highest loss rate? | `SELECT InstrumentType, AVG(CAST(LossTotalPnL*100.0/NULLIF(Total_Customers,0) AS FLOAT)) FROM ... WHERE QuarterYear='2026-Q2' GROUP BY InstrumentType` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_M_ESMA_..._Last12Months | StartDateID + EndDateID + RegulationID | Compare instrument breakdown to regulation total |

### 3.4 Gotchas

- **Customer overcounting**: A customer trading multiple instrument types appears in multiple rows. Do NOT sum Total_Customers across instrument types to get regulation total — use the parent table for that
- **Same gotchas as parent**: Count columns as decimal, retail-only population, daily rolling windows. See parent table gotchas
- **Instrument types from Dim_Instrument**: The InstrumentType values come from DWH_dbo.Dim_Instrument. If new instrument types are added, they will appear automatically

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB docs) | Highest — verified against source system documentation |
| Tier 2 | SP code analysis | High — traced from ETL stored procedure logic |
| Tier 3 | Live data observation | Medium — inferred from data patterns |
| Tier 4 | Contextual inference | Lower — best available knowledge |
| Tier 5 | Standard ETL column | Canonical — well-known ETL metadata pattern |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | StartDate | date | NO | Start of the rolling 12-month reporting window. Computed as DATEADD(YEAR,-1,@Date). (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 2 | EndDate | date | NO | End of the rolling 12-month reporting window. Computed as DATEADD(DAY,-1,@Date). (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 3 | StartDateID | int | NO | Integer YYYYMMDD representation of StartDate. Part of the delete-insert key. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 4 | EndDateID | int | NO | Integer YYYYMMDD representation of EndDate. Part of the delete-insert key. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 5 | QuarterYear | varchar(10) | NO | Reporting quarter derived from EndDate in YYYY-QN format (e.g., "2024-Q1"). (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 6 | RegulationID | int | YES | Regulation ID from Fact_SnapshotCustomer. FK to Dim_Regulation.DWHRegulationID. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 7 | Regulation | varchar(50) | YES | Regulation name resolved from Dim_Regulation.Name. 14 distinct values across all windows. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 8 | InstrumentTypeID | int | YES | Instrument type ID from Dim_Instrument.InstrumentTypeID. Groups positions by asset class. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 9 | InstrumentType | varchar(50) | YES | Instrument type name from Dim_Instrument.InstrumentType. Values: Stocks, Currencies, Commodities, Indices, ETF, Crypto Currencies. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 10 | Total_Customers | int | YES | Count of retail customers with CFD activity in this instrument type for this regulation and window. NOTE: customers trading multiple instrument types are counted in each. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 11 | LossTotalPnL | decimal(16,4) | YES | Count of customers whose total PnL for this instrument type is negative. Stored as decimal despite being a whole-number count. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 12 | ZeroTotalPnL | decimal(16,4) | YES | Count of customers whose total PnL for this instrument type is exactly zero. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 13 | ProfitTotalPnL | decimal(16,4) | YES | Count of customers whose total PnL for this instrument type is positive. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 14 | TotalPnL | decimal(16,4) | YES | Sum of all customer-level total PnL amounts (dollars) for this instrument type and regulation. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 15 | NetProfit_CFD | decimal(16,4) | YES | Sum of closed position net profit for this instrument type. Dollar amount. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 16 | PnL_Change_CFD | decimal(16,4) | YES | Sum of open position PnL changes for this instrument type. Dollar amount. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 17 | RollOver | decimal(16,4) | YES | Sum of rollover/overnight fees for this instrument type. Dollar amount. Typically negative. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 18 | UpdateDate | datetime2(7) | NO | ETL metadata: timestamp when this row was inserted. Set to GETDATE(). (Tier 5 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |

---

## 5. Lineage

### 5.1 Production Sources

Same as `BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months` with additional InstrumentTypeID/InstrumentType from DWH_dbo.Dim_Instrument.

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | Passthrough via GROUP BY |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough |
| (all others) | See parent table lineage | — | Same logic, GROUP BY includes InstrumentType |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (retail pop)
  |-- #pop
  v
DWH_dbo.Dim_Position + Dim_Instrument (closed positions by instrument)
  |-- #NetProfit (CID × PositionID × InstrumentTypeID × NetProfit_CFD)
  v
BI_DB_dbo.BI_DB_PositionPnL + Dim_Instrument (open PnL by instrument)
  |-- #PnL_Change (CID × PositionID × InstrumentTypeID × PnL_Change_CFD)
  v
DWH_dbo.Fact_CustomerAction (RollOver by instrument)
  |-- #Roll_Over
  v
#Pop_Total_PnL (UNION ALL → GROUP BY CID, RegulationID, InstrumentTypeID)
  |-- #finalTableInstrument (GROUP BY RegulationID, InstrumentTypeID)
  v
BI_DB_dbo.BI_DB_M_ESMA_..._Instrument (DELETE + INSERT, ~80 rows/day)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| RegulationID | DWH_dbo.Dim_Regulation | Regulation dimension |
| InstrumentTypeID | DWH_dbo.Dim_Instrument | Instrument type dimension |
| NetProfit_CFD | DWH_dbo.Dim_Position | Closed position profit |
| PnL_Change_CFD | BI_DB_dbo.BI_DB_PositionPnL | Open position PnL |
| RollOver | DWH_dbo.Fact_CustomerAction | Rollover fees |

### 6.2 Referenced By (other objects point to this)

No known consumers. This table is the instrument-level detail for the regulation-level parent.

---

## 7. Sample Queries

### 7.1 ESMA Profitability by Instrument Type (Latest Window)

```sql
SELECT InstrumentType,
       SUM(Total_Customers) AS total_customers,
       SUM(CAST(ProfitTotalPnL AS INT)) AS profitable,
       ROUND(SUM(ProfitTotalPnL) * 100.0 / NULLIF(SUM(Total_Customers), 0), 1) AS pct_profitable
FROM BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument
WHERE EndDateID = (SELECT MAX(EndDateID) FROM BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument)
GROUP BY InstrumentType
ORDER BY total_customers DESC
```

### 7.2 Crypto vs Stocks Loss Rate for CySEC

```sql
SELECT InstrumentType, QuarterYear,
       AVG(CAST(LossTotalPnL * 100.0 / NULLIF(Total_Customers, 0) AS FLOAT)) AS avg_loss_pct
FROM BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument
WHERE Regulation = 'CySEC'
  AND InstrumentType IN ('Stocks', 'Crypto Currencies')
GROUP BY InstrumentType, QuarterYear
ORDER BY QuarterYear, InstrumentType
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 17 T2, 0 T3, 0 T4, 1 T5 | Elements: 18/18, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument | Type: Table | Production Source: SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months*
