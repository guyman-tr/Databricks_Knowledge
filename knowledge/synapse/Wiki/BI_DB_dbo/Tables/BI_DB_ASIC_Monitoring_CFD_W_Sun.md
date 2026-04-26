# BI_DB_dbo.BI_DB_ASIC_Monitoring_CFD_W_Sun

| Attribute | Value |
|-----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_ASIC_Monitoring_CFD_W_Sun |
| **Refresh Pattern** | DELETE WHERE Date=@Date + INSERT (weekly Sunday append — full history retained) |
| **Frequency** | Weekly Sunday |
| **UC Target** | `_Not_Migrated` |
| **Distribution** | HASH (RealCID) |
| **Index** | CLUSTERED INDEX (Date ASC) |
| **Row Count** | ~375,976 rows per weekly snapshot (2026-04-11 sample) |
| **Columns** | 24 |

---

## Summary

Weekly Sunday snapshot of ASIC and FCA-regulated retail CFD customer risk profiles, computed for ASIC regulatory monitoring purposes. Each weekly run appends one snapshot date (always a Sunday) with one row per customer. The table tracks six ASIC compliance alert indicators (A1–A6) plus financial position metrics (equity, P&L, net deposits) to support regulatory risk monitoring of the FCA+ASIC population eligible for CFD trading.

Grain: one row per customer per snapshot date (RealCID + Date). History is fully retained — the table grows by ~375K rows each Sunday.

---

## Business Context

Supports ASIC and FCA regulatory obligations for CFD suitability monitoring. The six alert indicators map to specific ASIC-defined risk thresholds:

| Alert | Description | Threshold |
|-------|-------------|-----------|
| **A1 — Concentration Risk** | Manual CFD equity exceeds 50% of total equity (7-day average) | FinalAvgEquity > 0.5 |
| **A2 — Loss/Investment Ratio** | Manual CFD positions with loss > 50% of invested in last 6 months | ABS(NetProfit)/Amount > 0.5 |
| **A4 — BSL Close Reason** | Positions closed by margin call (stop-out) in last 6 months | ClosePositionReasonID = 16 |
| **A5 — Negative Balance** | Negative balance compensation event in last 6 months | Fact_CustomerAction CompensationReasonID = 11 |
| **A6 — High Leverage Trading** | Majority of manual CFD positions traded at maximum leverage | Per-instrument leverage caps: Crypto≥2×, FX≥30×, Commodities/Indices≥20×, Stocks/ETF≥5× |

**Population**: FCA (RegulationID=4) + ASIC (RegulationID=10) customers with `Fact_SnapshotCustomer` records on the snapshot date who are CFD-eligible (BI_DB_Scored_Appropriateness_Negative_Market.CFD_Status is NULL or 'CFD_Allowed').

**Note**: Alert #3 is absent — the SP skips from A2 to A4, suggesting A3 was either not implemented or handled elsewhere.

**Scale (2026-04-11)**: ~375,976 customers per weekly snapshot. The table covers both FCA and ASIC, hence substantially larger than ASIC-only tables (~82K).

---

## ETL / Refresh

**Pattern**: DELETE WHERE Date=@Date followed by INSERT — idempotent weekly append. Running the SP twice for the same date replaces that week's snapshot cleanly.

**Lookback windows**:
- Alert A1: Last 7 days of daily position equity (BI_DB_PositionPnL)
- Alerts A2, A4, A6: Last 6 months of closed manual CFD positions (Dim_Position)
- Alert A5: Last 6 months of customer actions with CompensationReasonID=11 (Fact_CustomerAction)
- TotalNetProfit / TotalManualCFD_NetProfit: All closed positions to date (unbounded)
- PnL/Equity at date: Open positions on snapshot date (BI_DB_PositionPnL)
- NetDeposits: All deposits/withdrawals to date (unbounded)

---

## Column Catalog

| # | Column | Type | Tier | Description |
|---|--------|------|------|-------------|
| 1 | Date | date NOT NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Snapshot date — the Sunday ETL run date (@Date parameter). All rows inserted in a single run share this date. Always a Sunday given the weekly schedule. |
| 2 | RealCID | int NOT NULL | T1 — Customer.CustomerStatic | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. |
| 3 | RegisteredReal | datetime NULL | T1 — Customer.CustomerStatic | Account registration date (renamed from Registered). Default=getdate(). |
| 4 | Country | varchar(50) NULL | T1 — Dictionary.Country | Full country name in English. Resolved from Fact_SnapshotCustomer.CountryID via Dim_Country JOIN. |
| 5 | Club | varchar(50) NULL | T1 — Dictionary.PlayerLevel | Player level tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Resolved from Fact_SnapshotCustomer.PlayerLevelID via Dim_PlayerLevel JOIN. Used in BackOffice reporting JOINs and customer-facing UI. |
| 6 | AccountManager | nvarchar(50) NULL | T1 — BackOffice.Manager | Assigned account manager display name. Concatenated from Dim_Manager.FirstName + ' ' + Dim_Manager.LastName. LastName='*' denotes a functional/shared account. |
| 7 | Is_PI | bit NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Popular Investor flag: 1 when Fact_SnapshotCustomer.GuruStatusID >= 2 (active PI or higher status), 0 otherwise. Used to track Popular Investor exposure in CFD monitoring. |
| 8 | A1_ConcentrationRisk_Ind | bit NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Alert A1 indicator: 1 when the customer's 7-day average equity in manual CFD positions exceeds 50% of their total equity (A1_FinalAvgEquity > 0.5). Signals over-concentration in manual CFD trades relative to total portfolio. |
| 9 | A1_FinalAvgEquity | decimal(16,4) NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Alert A1 metric: ratio of average manual CFD equity to average total equity over the past 7 days. Computed as AVG(EquityManualCFD) / AVG(TotalEquity) per customer from BI_DB_PositionPnL. Equity = Amount + PositionPnL for open positions. Range: 0.0 to 1.0 (0 if no equity). |
| 10 | A2_LossInvestmentRatio_Ind | bit NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Alert A2 indicator: 1 if any closed manual CFD position in the last 6 months had a loss-to-investment ratio exceeding 50% (ABS(NetProfit)/Amount > 0.5 where NetProfit < 0). |
| 11 | A2_LossInvestmentRatio_CountPos | int NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Alert A2 count: number of closed manual CFD positions in the last 6 months where the loss-to-investment ratio exceeded 50%. Companion to A2_LossInvestmentRatio_Ind for severity assessment. |
| 12 | A4_Last_BSL_Date_Ind | bit NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Alert A4 indicator: 1 if any manual CFD position was closed by a margin call / stop-out (ClosePositionReasonID=16 = BSL) in the last 6 months. |
| 13 | A4_Last_BSL_Date_MaxDate | date NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Alert A4 date: most recent CloseOccurred date for a position closed by BSL (margin call) in the last 6 months. Defaults to 1999-01-01 when no BSL event occurred (sentinel value). |
| 14 | A5_NegativeBalance_Ind | bit NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Alert A5 indicator: 1 if the customer received a negative balance compensation (Fact_CustomerAction.CompensationReasonID=11) in the last 6 months. |
| 15 | A5_Last_NegativeBalance_Date_MaxDate | date NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Alert A5 date: most recent date of a negative balance compensation event in the last 6 months. Sourced from MAX(Fact_CustomerAction.DateID) where CompensationReasonID=11, cast from YYYYMMDD integer. Defaults to 1999-01-01 when no event occurred (sentinel value). |
| 16 | A6_HighLeverageTrading_Ind | bit NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Alert A6 indicator: 1 if over 50% of the customer's closed manual CFD positions in the last 6 months were opened at maximum regulatory leverage. Leverage caps by instrument: Crypto (ID=10)≥2×, FX (ID=1)≥30×, Commodities (ID=2)≥20×, Indices (ID=4)≥20×, Stocks/ETF (ID=5,6)≥5×. |
| 17 | TotalNetProfit | decimal(16,4) NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Cumulative net profit in USD from ALL closed positions (all asset types, all time, including Copy positions) as of the snapshot date. SUM(Dim_Position.NetProfit) where CloseDateID < @DateID. |
| 18 | TotalManualCFD_NetProfit | decimal(16,4) NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Cumulative net profit in USD from closed manual non-settled CFD positions (MirrorID=0, IsSettled=0) all time. Subset of TotalNetProfit isolating non-copy, non-stock positions. |
| 19 | PnLManualCFD | decimal(16,4) NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Unrealized P&L in USD for open manual CFD positions (IsSettled=0, MirrorID=0) at the snapshot date. SUM(BI_DB_PositionPnL.PositionPnL) for these positions. |
| 20 | TotalPnL | decimal(16,4) NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Total unrealized P&L in USD for ALL open positions at the snapshot date. SUM(BI_DB_PositionPnL.PositionPnL) regardless of asset type or copy mode. |
| 21 | EquityManualCFD | decimal(16,4) NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Equity value in USD of open manual CFD positions at the snapshot date. SUM(Amount + PositionPnL) for positions where IsSettled=0 and MirrorID=0. Used in A1 concentration ratio calculation. |
| 22 | TotalEquity | decimal(16,4) NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Total equity value in USD of ALL open positions at the snapshot date. SUM(Amount + PositionPnL) regardless of asset type or copy mode. Denominator in A1 ratio. |
| 23 | NetDeposits | decimal(16,4) NULL | T2 — SP_ASIC_Monitoring_CFD_W_Sun | Lifetime net deposits in USD: SUM(deposits, ActionTypeID=7) minus SUM(withdrawals, ActionTypeID=8) from Fact_CustomerAction, all time up to and including the snapshot date. |
| 24 | LastUpdateDate | datetime NULL | Propagation | ETL metadata: timestamp when this row was inserted by the ETL pipeline. |

---

## Data Quality / Known Issues

### Sentinel Date Values (1999-01-01)

`A4_Last_BSL_Date_MaxDate` and `A5_Last_NegativeBalance_Date_MaxDate` use `1999-01-01` as a sentinel value when no qualifying event occurred in the lookback window (rather than NULL). Downstream consumers must filter or handle this sentinel — do not interpret 1999-01-01 as an actual event date.

### Alert A3 Missing

The SP implements alerts A1, A2, A4, A5, A6 but skips A3. No column named `A3_*` exists. Whether A3 is implemented in a separate table or was never built is undocumented.

### Population Includes FCA (not ASIC-only)

Despite the table name suggesting ASIC, the population filter is `RegulationID IN (4,10)` — FCA (4) and ASIC (10). Approximately 375K customers per snapshot (vs ~82K for ASIC-only tables). Consumers should filter on RegulationID if ASIC-only analysis is needed.

---

## Lineage

Full column-level lineage: [BI_DB_ASIC_Monitoring_CFD_W_Sun.lineage.md](./BI_DB_ASIC_Monitoring_CFD_W_Sun.lineage.md)

**Tier Summary**: 5 Tier 1, 18 Tier 2, 1 Propagation

**Upstream sources**:
- `DWH_dbo.Fact_SnapshotCustomer` → population (RealCID, CountryID, PlayerLevelID, GuruStatusID, RegulationID, AccountManagerID)
- `DWH_dbo.Dim_Customer` → RegisteredReal
- `DWH_dbo.Dim_Country` → Country name
- `DWH_dbo.Dim_PlayerLevel` → Club name
- `DWH_dbo.Dim_Manager` → AccountManager (FirstName+LastName)
- `BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market` → CFD eligibility exclusion
- `BI_DB_dbo.BI_DB_PositionPnL` → equity, PnL, A1 metrics
- `DWH_dbo.Dim_Position` → A2, A4, A6 alerts + TotalNetProfit
- `DWH_dbo.Fact_CustomerAction` → A5 alert + NetDeposits
