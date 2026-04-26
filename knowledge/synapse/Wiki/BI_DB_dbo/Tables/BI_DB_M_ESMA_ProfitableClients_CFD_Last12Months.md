# BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months

> 6,430-row ESMA regulatory reporting table aggregating CFD client profitability by regulation over rolling 12-month windows, from Q1 2024 to Q2 2026. Each row represents one regulation for one daily-rolling window, showing total customers, loss/zero/profit breakdowns, and PnL components (closed position profit, open position PnL change, rollover fees). Refreshed daily via `SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months` with delete-insert by StartDateID+EndDateID.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed from DWH_dbo.Fact_SnapshotCustomer + Dim_Position + BI_DB_PositionPnL + Fact_CustomerAction via `SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months` |
| **Refresh** | Daily (delete-insert by StartDateID+EndDateID). Author: Yarden Sabadra, 2024-01-17. OpsDB: SB_Daily, Priority 0 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table supports ESMA (European Securities and Markets Authority) regulatory reporting requirements for CFD (Contract for Difference) client profitability disclosure. Under ESMA regulations, brokers must disclose the percentage of retail clients who lose money trading CFDs.

The SP calculates a **rolling 12-month window** from `@Date` back one year. For each daily window and regulation, it computes:

1. **Net Profit from Closed Positions** (`NetProfit_CFD`): Sum of `Dim_Position.NetProfit` for positions closed within the window (IsSettled=0)
2. **PnL Change on Open Positions** (`PnL_Change_CFD`): Difference between position PnL at window end vs window start-1 day, from `BI_DB_PositionPnL`
3. **Rollover Fees** (`RollOver`): Sum of overnight fee amounts from `Fact_CustomerAction` where ActionTypeID=35 and IsFeeDividend IN (1,2)

Total PnL per customer = NetProfit_CFD + PnL_Change_CFD + RollOver. Customers are then classified as Loss (TotalPnL < 0), Zero (= 0), or Profit (> 0).

Population: All valid customers (IsValidCustomer=1) excluding MifidCategorizationID IN (2=Professional, 3=Eligible Counterparty) — only retail clients.

The table has 6,430 rows with 14 distinct regulations. CySEC, FCA, FSA Seychelles, ASIC, BVI, FSRA, and ASIC & GAML each have 762 rows (one per daily run). Smaller regulations have fewer rows.

**Companion table**: `BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument` provides the same breakdown further split by instrument type.

---

## 2. Business Logic

### 2.1 Rolling 12-Month Window

**What**: Defines the reporting period as exactly 12 months before the run date.
**Columns Involved**: StartDate, EndDate, StartDateID, EndDateID, QuarterYear
**Rules**:
- StartDate = DATEADD(YEAR, -1, @Date)
- EndDate = DATEADD(DAY, -1, @Date)
- QuarterYear = YYYY-QN based on EndDate (e.g., "2024-Q1")
- Each daily run creates one set of rows per regulation

### 2.2 Customer PnL Classification

**What**: Classifies each customer's total PnL over the rolling window.
**Columns Involved**: LossTotalPnL, ZeroTotalPnL, ProfitTotalPnL, TotalPnL
**Rules**:
- Total_PnL per customer = SUM(NetProfit_CFD) + SUM(PnL_Change_CFD) + SUM(RollOver) at CID level
- Loss = Total_PnL < 0 (COUNT of customers)
- Zero = Total_PnL = 0 (COUNT of customers)
- Profit = Total_PnL > 0 (COUNT of customers)
- Total_Customers = Loss + Zero + Profit

### 2.3 PnL Change Calculation

**What**: Computes the change in open position value over the window.
**Columns Involved**: PnL_Change_CFD
**Rules**:
- For each open position (IsSettled=0), get PositionPnL at @endDateID and @startDate_minusOneID from BI_DB_PositionPnL
- PnL_Change = PositionPnL_EndDate - PositionPnL_StartDate_Minus1
- ISNULL handling: missing PnL values treated as 0

### 2.4 Rollover Fee Inclusion

**What**: Includes overnight/weekend holding fees in total PnL.
**Columns Involved**: RollOver
**Rules**:
- Source: Fact_CustomerAction where ActionTypeID=35 (Rollover) and IsFeeDividend IN (1, 2)
- Aggregated per position, then per customer
- LEFT JOIN — positions without rollover fees contribute 0

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED COLUMNSTORE INDEX. Small table (6,430 rows) — CCI provides good compression. No distribution key needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| % profitable clients for latest quarter? | `SELECT Regulation, ProfitTotalPnL*100.0/Total_Customers FROM ... WHERE QuarterYear = '2026-Q2' AND EndDateID = (SELECT MAX(EndDateID) FROM ... WHERE QuarterYear = '2026-Q2')` |
| Loss rate trend by regulation? | `SELECT QuarterYear, Regulation, AVG(LossTotalPnL*1.0/NULLIF(Total_Customers,0)) FROM ... GROUP BY QuarterYear, Regulation` |
| Total PnL by regulation for a specific window? | `SELECT * FROM ... WHERE StartDateID = 20250412 AND EndDateID = 20260411` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_M_ESMA_..._Instrument | StartDateID + EndDateID + RegulationID | Break down by instrument type |

### 3.4 Gotchas

- **Daily granularity with rolling windows**: Each row is a daily-sliding 12-month window, NOT a fixed quarterly snapshot. Use MAX(EndDateID) per QuarterYear for the latest window in each quarter
- **LossTotalPnL/ZeroTotalPnL/ProfitTotalPnL are COUNTS, not amounts**: Despite the PnL suffix, these are customer counts, not dollar amounts. The dollar amount is in TotalPnL
- **Retail only**: MifidCategorization Professional and Eligible Counterparty are excluded. This table is NOT for all customers
- **Companion table**: The `_Instrument` variant provides the same data broken down by InstrumentType. The totals across instrument types for a given regulation+window should roughly match this table (not exactly, due to customers trading multiple instrument types)

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
| 3 | StartDateID | int | NO | Integer YYYYMMDD representation of StartDate. Used for partition-aligned JOINs. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 4 | EndDateID | int | NO | Integer YYYYMMDD representation of EndDate. Part of the delete-insert key (StartDateID+EndDateID). (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 5 | QuarterYear | varchar(10) | NO | Reporting quarter derived from EndDate in YYYY-QN format (e.g., "2024-Q1", "2026-Q2"). Useful for quarterly aggregation of daily rolling windows. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 6 | RegulationID | int | YES | Regulation ID from Fact_SnapshotCustomer via Dim_Regulation. FK to Dim_Regulation.DWHRegulationID. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 7 | Regulation | varchar(50) | YES | Regulation name resolved from Dim_Regulation.Name. Values: CySEC, FCA, FSA Seychelles, ASIC, ASIC & GAML, BVI, FSRA, FinCEN+FINRA, MAS, FinCEN, eToroUS, NYDFS+FINRA, None, FINRAONLY. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 8 | Total_Customers | int | YES | Total count of retail customers with CFD activity in the rolling 12-month window for this regulation. Equals LossTotalPnL + ZeroTotalPnL + ProfitTotalPnL. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 9 | LossTotalPnL | decimal(16,4) | YES | Count of customers whose total PnL (NetProfit + PnL Change + RollOver) is negative over the rolling window. Despite the decimal type, values are whole numbers (customer counts). (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 10 | ZeroTotalPnL | decimal(16,4) | YES | Count of customers whose total PnL is exactly zero over the rolling window. Typically very small (single digits per regulation). (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 11 | ProfitTotalPnL | decimal(16,4) | YES | Count of customers whose total PnL is positive over the rolling window. The ESMA-required "% profitable" = ProfitTotalPnL / Total_Customers. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 12 | TotalPnL | decimal(16,4) | YES | Sum of all customer-level total PnL amounts (in dollars) across the regulation for the window. This IS a dollar amount, unlike Loss/Zero/Profit which are counts. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 13 | NetProfit_CFD | decimal(16,4) | YES | Sum of Dim_Position.NetProfit for all closed positions (IsSettled=0) within the rolling window, aggregated across all customers in this regulation. Dollar amount. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 14 | PnL_Change_CFD | decimal(16,4) | YES | Sum of open position PnL changes (end-of-window PnL minus start-of-window PnL) from BI_DB_PositionPnL, aggregated across all customers in this regulation. Dollar amount. (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 15 | RollOver | decimal(16,4) | YES | Sum of rollover/overnight fee amounts from Fact_CustomerAction (ActionTypeID=35, IsFeeDividend IN (1,2)) within the rolling window, aggregated across all customers. Dollar amount. Typically negative (fees paid). (Tier 2 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |
| 16 | UpdateDate | datetime2(7) | NO | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| StartDate | (computed) | @startDate | DATEADD(YEAR,-1,@Date) |
| EndDate | (computed) | @endDate | DATEADD(DAY,-1,@Date) |
| StartDateID | (computed) | @startDateID | INT YYYYMMDD |
| EndDateID | (computed) | @endDateID | INT YYYYMMDD |
| QuarterYear | (computed) | @quarterYear | YYYY-QN from EndDate |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN |
| Total_Customers | (computed) | COUNT(CID) | Aggregated |
| LossTotalPnL | (computed) | SUM(CASE) | Customer count |
| ZeroTotalPnL | (computed) | SUM(CASE) | Customer count |
| ProfitTotalPnL | (computed) | SUM(CASE) | Customer count |
| TotalPnL | (computed) | SUM | Aggregated dollar |
| NetProfit_CFD | DWH_dbo.Dim_Position | NetProfit | SUM, closed positions |
| PnL_Change_CFD | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | Delta calculation |
| RollOver | DWH_dbo.Fact_CustomerAction | Amount | SUM, ActionType=35 |
| UpdateDate | (computed) | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Range (retail pop, MifidCat NOT IN 2,3)
  |-- #pop (RealCID, RegulationID, IsDepositor)
  v
DWH_dbo.Dim_Position + Dim_Instrument (closed positions, IsSettled=0)
  |-- #NetProfit (CID × PositionID × NetProfit_CFD)
  v
BI_DB_dbo.BI_DB_PositionPnL (open position PnL at window boundaries)
  |-- #PnL_Change (CID × PositionID × PnL_Change_CFD)
  v
DWH_dbo.Fact_CustomerAction (ActionTypeID=35, IsFeeDividend IN 1,2)
  |-- #Roll_Over (CID × PositionID × RollOver)
  v
#Pop_Total_PnL (UNION ALL → GROUP BY CID, RegulationID)
  |-- #finalTable (GROUP BY RegulationID → regulation-level aggregates)
  v
BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months (DELETE + INSERT, ~14 rows/day)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| RegulationID | DWH_dbo.Dim_Regulation | Regulation dimension lookup |
| NetProfit_CFD | DWH_dbo.Dim_Position | Closed position profitability |
| PnL_Change_CFD | BI_DB_dbo.BI_DB_PositionPnL | Open position PnL tracking |
| RollOver | DWH_dbo.Fact_CustomerAction | Rollover fee amounts |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship |
|---|---|
| BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument | Companion table — same data broken down by InstrumentType. Same SP writes both. |

---

## 7. Sample Queries

### 7.1 ESMA Profitable Client Percentage by Regulation (Latest Window)

```sql
SELECT Regulation,
       Total_Customers,
       CAST(ProfitTotalPnL AS INT) AS profitable_clients,
       CAST(LossTotalPnL AS INT) AS loss_clients,
       ROUND(ProfitTotalPnL * 100.0 / NULLIF(Total_Customers, 0), 1) AS pct_profitable
FROM BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months
WHERE EndDateID = (SELECT MAX(EndDateID) FROM BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months)
ORDER BY Total_Customers DESC
```

### 7.2 Quarterly Profitability Trend for CySEC

```sql
SELECT QuarterYear,
       MAX(EndDate) AS latest_window_end,
       AVG(CAST(ProfitTotalPnL * 100.0 / NULLIF(Total_Customers, 0) AS FLOAT)) AS avg_pct_profitable
FROM BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months
WHERE Regulation = 'CySEC'
GROUP BY QuarterYear
ORDER BY QuarterYear
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 15 T2, 0 T3, 0 T4, 1 T5 | Elements: 16/16, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months | Type: Table | Production Source: SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months*
