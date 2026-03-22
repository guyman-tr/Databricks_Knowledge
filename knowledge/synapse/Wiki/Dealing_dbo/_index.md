---
schema: Dealing_dbo
database: Synapse DWH
total_objects: 238
documented: 231
blacklisted: 3
failed: 0
last_batch: 20
skipped: 22
last_updated: "2026-03-21"
quality_avg: 7.8
---

# Dealing_dbo — Schema Documentation Index

## Schema Documentation Progress

| Metric | Value |
|--------|-------|
| **Schema** | Dealing_dbo |
| **Total Objects** | 238 |
| **Tables** | 232 |
| **Views** | 6 |
| **Documented** | 231 (97.1%) |
| **Blacklisted** | 3 (`*_HOLD` tables — decommissioned) |
| **Failed** | 0 |
| **Skipped** | 19 |
| **Last Updated** | 2026-03-21 |

---

## Next Batch

**SCHEMA COMPLETE** — All 240 objects (234 tables + 6 views) documented. 19 tables intentionally skipped.

---

### Batch 20 — Final Views: CEP Audit + Dashboard + Duco + Best Execution (6 views, completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [V_Dealing_CEPDailyAudit_CP_Last180Days](Views/V_Dealing_CEPDailyAudit_CP_Last180Days.md) | View | 7.0 | Done ✅ 180-day rolling filter over CEPDailyAudit_CP |
| 2 | [V_Dealing_CEPDailyAudit_Conditions_Last180Days](Views/V_Dealing_CEPDailyAudit_Conditions_Last180Days.md) | View | 7.0 | Done ✅ 180-day rolling filter over CEPDailyAudit_Conditions |
| 3 | [V_Dealing_CEPDailyAudit_Rules_Last180Days](Views/V_Dealing_CEPDailyAudit_Rules_Last180Days.md) | View | 7.0 | Done ✅ 180-day rolling filter over CEPDailyAudit_Rules |
| 4 | [V_Dealing_DealingDashboard_Clients](Views/V_Dealing_DealingDashboard_Clients.md) | View | 7.5 | Done ✅ NOLOCK + DateID>20211231; SP_Regime_Flags consumer |
| 5 | [V_Dealing_Duco_EODRecon](Views/V_Dealing_Duco_EODRecon.md) | View | 7.5 | Done ✅ DISTINCT + BuyOrSell alias; Duco platform entry point |
| 6 | [V_RequestViewForBestExecution](Views/V_RequestViewForBestExecution.md) | View | 7.5 | Done ✅ UNION HedgeServer+EMS; MiFID Best Execution |

---

### Batch 19 — Final Tables: FactSet Export + Interest Rates + Overnight Fees + Marex Mapping (4 objects, completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_FactSet_Management_Export](Tables/Dealing_FactSet_Management_Export.md) | External Table | 7.5 | Done ✅ Gold layer staging for FactSet PI export; SP drops/recreates daily; 4 cols |
| 2 | [Dealing_etoro_history_interestrate](Tables/Dealing_etoro_history_interestrate.md) | External Table | 7.5 | Done ✅ Bronze layer SCD2 interest rate config history; 13 cols; used by Islamic fee SPs |
| 3 | [External_Fivetran_dealing_overnight_fees](Tables/External_Fivetran_dealing_overnight_fees.md) | Table | 8.0 | Done ✅ active, Fivetran Bloomberg futures prices; 9 cols; critical input for Islamic spot price adjustment |
| 4 | [External_Gold_Dealing_Marex_Trader_OrderID](Tables/External_Gold_Dealing_Marex_Trader_OrderID.md) | External Table | 8.2 | Done ✅ active to 2026-03-21, Gold layer Trader↔OrderID mapping; 8 cols; used by SP_Marex_Recon for futures recon |

---

### Batch 17 — SAXO Recon Suite + Spreads + Holdings + US Regulatory Reports (11 objects, completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_SAXORecon_EODHoldings](Tables/Dealing_SAXORecon_EODHoldings.md) | Table | 7.5 | Done ✅ active (to 2026-03-10) — 1.86M rows; 3-way recon SAXO vs eToro vs Clients; 29 cols; [Reality-Supposed] primary metric; eToro_AmounUSD typo preserved |
| 2 | [Dealing_SAXORecon_Trades](Tables/Dealing_SAXORecon_Trades.md) | Table | 7.5 | Done ✅ active (to 2026-03-10) — 1.0M rows; SP_SAXO_Recon; trade-flow recon; [SAXO-eToro_AmountUSD] primary; eToro_AmounUSD typo preserved |
| 3 | [Dealing_SAXORecon_Hedging](Tables/Dealing_SAXORecon_Hedging.md) | Table | 4.5 | Done ⛔ ORPHANED — no writer SP; stale since 2023-05-17; hedging section removed during Synapse migration (SR-220795 Dec 2023); 42.7K rows |
| 4 | [Dealing_SaxoRecon_FXnCommed_EODHoldings](Tables/Dealing_SaxoRecon_FXnCommed_EODHoldings.md) | Table | 7.0 | Done ✅ active (to 2026-03-10) — 195.7K rows; SP_SAXO_Recon_FXnCommed; FX/Commodities accounts; data only from Apr 2024 |
| 5 | [Dealing_SaxoRecon_FXnCommed_Trades](Tables/Dealing_SaxoRecon_FXnCommed_Trades.md) | Table | 4.0 | Done ⛔ ORPHANED — no writer SP; stale since 2023-12-05; Trades section removed SR-282666 Nov 2024; 4.2K rows |
| 6 | [Dealing_SpreadsMST](Tables/Dealing_SpreadsMST.md) | Table | 8.0 | Done ✅ active (to 2026-03-10) — 8.2M rows; SP_SpreadsMST; bid/ask vs MST threshold audit; 'PrecentageSpread' typo from source Dictionary (89% of rows) |
| 7 | [Dealing_Holdings_RealStocks](Tables/Dealing_Holdings_RealStocks.md) | Table | 8.0 | Done ✅ active (to 2026-03-10) — 12.2M rows; SP_Holdings_RealStocks; BNY Mellon custodian daily holdings; Real HS (3,9,102,128,112,125,126) vs CFD HS (2,101,129) |
| 8 | [Dealing_US_DailyTradeBlotter](Tables/Dealing_US_DailyTradeBlotter.md) | Table | 6.5 | Done ⚠️ STALE since 2025-01-13 — 408.7M rows; SP_USTradeReports; FINRA daily blotter; IsCopy 74.4%; HASH(CID) |
| 9 | [Dealing_US_DailyTradeBlotter_DailyCSV](Tables/Dealing_US_DailyTradeBlotter_DailyCSV.md) | Table | 6.5 | Done ⚠️ STALE since 2025-01-13 — 1.16M rows; SP_USTradeReports; TRUNCATE pattern (single day snapshot); CSV export format |
| 10 | [Dealing_US_OriginalEntryTradeTicket](Tables/Dealing_US_OriginalEntryTradeTicket.md) | Table | 6.5 | Done ⚠️ STALE since 2025-01-13 — 587.6M rows; SP_USTradeReports; FINRA original-entry ticket; 8 hardcoded regulatory constants |
| 11 | [Dealing_US_Stocks_SmartPortfolio](Tables/Dealing_US_Stocks_SmartPortfolio.md) | Table | 7.5 | Done ✅ active (to 2026-03-10) — 252.6K rows; SP_US_Stocks_SmartPortfolio; AccountTypeID=9 NOP concentration; >5% email alert |

**Notes**: Batch 17 spans four functional families. (1) **SAXO Reconciliation** (5 tables): SP_SAXO_Recon writes EODHoldings+Trades — 3-way daily reconciliation between SAXO LP files, eToro hedge netting (temporal UNION), and client positions; Fivetran HS mapping (SR-282189 Nov 2024) replaced hardcoded IDs. SAXORecon_Hedging is orphaned (hedging section removed SR-220795 Dec 2023). SP_SAXO_Recon_FXnCommed writes only FXnCommed_EODHoldings (SR-282666 Nov 2024 removed Trades section); FXnCommed_Trades is orphaned. Both orphaned tables are STALE with no plan for decommission. Key data quality: `eToro_AmounUSD` typo (missing 't') preserved in both active SAXO recon tables. (2) **SpreadsMST** (1 table): SP_SpreadsMST — simple JOIN from 4 source tables; 'PrecentageSpread' typo (89% of rows) originates in External_Etoro_Dictionary_SpreadType.Name — preserved as-is. FeedID=1 filter (primary feed only). SpreadThresholdTypeID always 1 in current data. VisibleInternallyOnly=1 for 23.5% of rows (internal Dealing instruments). (3) **Holdings** (1 table): SP_Holdings_RealStocks for BNY Mellon custodian reporting; temporal UNION of etoro_Hedge_Netting + history; Real vs CFD classification by hardcoded HS IDs; Amount_USD via multi-step FX conversion. (4) **US Regulatory Reports** (4 tables): SP_USTradeReports (FINRA/SEC compliance) — all 3 main tables STALE since 2025-01-13 (EMS Orders feed stopped). TRUNCATE pattern for DailyCSV; DELETE/INSERT for others. All regulatory constants hardcoded (Agency='Agency', Solicited='Unsolicited', etc.). IsCopy=1 (74.4% of blotter rows) for mirror/copy trades. SP_US_Stocks_SmartPortfolio active — SmartPortfolio-specific NOP monitoring. Quality avg: 6.8/10.

---

### Batch 18 — Market Manipulation + LP Fees + FactSet History + Regime Flags + CMT Fees + Crypto Rebate + PriceLocks + Stocks Override + MCS Model + RiskMatrix + 6 Views (16 objects, completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_Market_Manipulation_OutstandingsharesHigherthan005](Tables/Dealing_Market_Manipulation_OutstandingsharesHigherthan005.md) | Table | 7.5 | Done ✅ active (to 2026-03-10) — 2.2K rows; SP_Market_Manipulation_OutstandingsharesHigherthan005; dual-threshold: eToro LP flow >0.5% outstanding shares + CID >0.25%; NULL sentinel on breach-free days; migrated Databricks SR-244356 |
| 2 | [Dealing_Supposed_LPFees](Tables/Dealing_Supposed_LPFees.md) | Table | 3.5 | Done ⛔ ORPHANED — no writer SP; stale since 2023-09-11; 603K rows; REPLICATE; LP fee estimates (IB/SAXO/JP) vs actual invoices; fee methodology unverifiable |
| 3 | [Dealing_FactSet_NewPIs_History](Tables/Dealing_FactSet_NewPIs_History.md) | Table | 6.5 | Done ⚠️ STALE since 2024-06-04 — 4.8M rows; TRUNCATE/INSERT; FactSet new-PI portfolio snapshot; LastNightRiskScore 1–10 StdDev ladder; HistorySendFlag=1 gate; feed discontinued |
| 4 | [Dealing_Regime_Flags](Tables/Dealing_Regime_Flags.md) | Table | 6.0 | Done ⚠️ STALE since 2025-01-19 — 17.9M rows; SP_Regime_Flags; 4 measures (Zero/Volume/NOP Change/Price Change Rate); rolling Z-scores + percentiles; full DELETE+INSERT; NOT in OpsDB |
| 5 | [Dealing_WeeklyCMT_Fees](Tables/Dealing_WeeklyCMT_Fees.md) | Table | 4.5 | Done ⛔ STALE since 2023-04-09 — 54.2K rows; SP_Crypto_CMT_Fees; Sunday-only; legacy leveraged crypto OpenDateID≤20210108; StopRate≤pip filter; program discontinued |
| 6 | [Dealing_Unrealized_Open_CryptoRebate](Tables/Dealing_Unrealized_Open_CryptoRebate.md) | Table | 8.0 | Done ✅ active (to 2026-02-28) — 63.5K rows; SP_M_CryptoRebateOpenUnrealized; monthly; Diamond (PlayerLevelID=7) open crypto Leverage=1; tiered rebate 0.15%/0.25%/0.50%; $5 min; UPdatedate typo |
| 7 | [Dealing_PriceLocks](Tables/Dealing_PriceLocks.md) | Table | 7.5 | Done ✅ active (to 2026-03-10) — 6.9M rows; SP_PriceLocks; SpreadLock(45%)/VolatilityLock(43%)/TimeOut(9%)/CrossSpread/CircuitBreaker; TotalInFist15Min typo; migrated Databricks SR-244984 |
| 8 | [StocksOverrideRateLog](Tables/StocksOverrideRateLog.md) | Table | 8.0 | Done ✅ active (to 2026-03-10) — 6.5M rows; SP_StocksOverrideRateLog; daily snapshot of interest rate overrides; Active(EndTime=NULL)/Historical; Total_Buy=Interest+Markup; Dim_Instrument join for metadata |
| 9 | [Dealing_MCS_Model_Report](Tables/Dealing_MCS_Model_Report.md) | Table | 8.0 | Done ✅ active (to 2026-03-10) — 1.1B rows; SP_MCS_Model_Report; HASH(PositionID); InstrTypeID IN (5,6) Stocks+ETF only; opened+closed today positions; Volume_Open/Close and Click_Open/Close attribution; Gil Cholev 2014 |
| 10 | [Dealing_RiskMatrix_V2](Tables/Dealing_RiskMatrix_V2.md) | Table | 4.0 | Done ⚠️ STALE — single snapshot 2024-06-02; 87.6K rows; HEAP; no writer SP; 26-scenario NOP stress test (+1% to +900%, -1% to -100%); ad-hoc snapshot; Real Stocks+ETF hedge book |
| 11 | [V_Dealing_CEPDailyAudit_CP_Last180Days](Tables/V_Dealing_CEPDailyAudit_CP_Last180Days.md) | View | 7.0 | Done ✅ — thin filter wrapper; SELECT * FROM Dealing_CEPDailyAudit_CP WHERE Date >= GETDATE()-180; rolling 180-day window |
| 12 | [V_Dealing_CEPDailyAudit_Conditions_Last180Days](Tables/V_Dealing_CEPDailyAudit_Conditions_Last180Days.md) | View | 7.0 | Done ✅ — thin filter wrapper; SELECT * FROM Dealing_CEPDailyAudit_Conditions WHERE Date >= GETDATE()-180; rolling 180-day window |
| 13 | [V_Dealing_CEPDailyAudit_Rules_Last180Days](Tables/V_Dealing_CEPDailyAudit_Rules_Last180Days.md) | View | 7.0 | Done ✅ — thin filter wrapper; SELECT * FROM Dealing_CEPDailyAudit_Rules WHERE Date >= GETDATE()-180; rolling 180-day window |
| 14 | [V_Dealing_DealingDashboard_Clients](Tables/V_Dealing_DealingDashboard_Clients.md) | View | 7.0 | Done ✅ — thin filter wrapper; SELECT * FROM Dealing_DealingDashboard_Clients WITH(NOLOCK) WHERE DateID > 20211231; static 2022+ cutoff |
| 15 | [V_Dealing_Duco_EODRecon](Tables/V_Dealing_Duco_EODRecon.md) | View | 7.5 | Done ✅ — DISTINCT dedup + BuyOrSell alias for [Buy/Sell]; Date >= '2023-01-01'; primary entry point for broker recon queries |
| 16 | [V_RequestViewForBestExecution](Tables/V_RequestViewForBestExecution.md) | View | 7.0 | Done ✅ — UNION of RequestExecutionLog (last 24h) + EMSOrders (HedgeExecutionModeID≠3); 8 columns; best execution compliance view |

**Notes**: Batch 18 spans six functional families plus all 6 Dealing_dbo views. (1) **Market Surveillance** (1 table): Dealing_Market_Manipulation_OutstandingsharesHigherthan005 — dual-threshold real stocks manipulation detection; instrument-level (>0.5% outstanding shares via eToro LP flow) + client-level (>0.25% outstanding shares via CID realized volume); sibling Email table TRUNCATE+INSERT; migrated from Databricks Dec 2024. (2) **LP Fee Tracking** (1 table): Dealing_Supposed_LPFees — ORPHANED; no writer SP; ~30 months stale; theoretical LP fee estimates (IB/SAXO/JP) with no verifiable calculation methodology; REPLICATE distribution. (3) **FactSet External Feed** (1 table): Dealing_FactSet_NewPIs_History — TRUNCATE/INSERT single-day snapshot; gold lake parquet (FactSet_PositionPnL_stg) + DWH dims; HistorySendFlag=1 gate; LastNightRiskScore is 10-bucket StdDev ladder; FactSet feed stopped June 2024. (4) **Statistical Regime Detection** (1 table): Dealing_Regime_Flags — 4 measure streams × Z-score × rolling windows (5-day/10-day); hardcoded normal CDF lookup; full history rebuild every run (expensive DELETE+INSERT from 2019); crypto weekend-inclusive; NOT in OpsDB. (5) **Legacy + Active Crypto Programs** (3 tables): Dealing_WeeklyCMT_Fees — Sunday-only SP; pre-2021 leveraged long crypto; StopRate≤pip threshold; discontinued since Apr 2023. Dealing_Unrealized_Open_CryptoRebate — active monthly; Diamond non-FCA; 9-country exclusion; bracket rebate (0.15/0.25/0.50%); UPdatedate DDL typo. (6) **Price Operations** (2 tables): Dealing_PriceLocks — daily lock-event log; 5 event types; time-window breakdowns (First10Min/First15Min/Last5Min); TotalInFist15Min DDL typo. StocksOverrideRateLog — daily override config snapshot; NULL=Active sentinel convention; interest+markup separation. (7) **Views** (6): Three CEP audit views are identical thin wrappers (GETDATE()-180 rolling filter over CEPDailyAudit_CP/Conditions/Rules). V_Dealing_DealingDashboard_Clients is a NOLOCK filtered view (DateID > 20211231). V_Dealing_Duco_EODRecon adds DISTINCT dedup + BuyOrSell alias (avoids bracket quoting for [Buy/Sell] column) + Date >= 2023-01-01 filter — primary Duco recon entry point. V_RequestViewForBestExecution is a UNION of two staging sources: RequestExecutionLog (last 24h) + EMSOrders (HedgeExecutionModeID≠3 joined to CopyFromLake.PriceLog_History_CurrencyPrice) — best execution compliance view. Quality avg: 6.5/10.

---

## Completed Batches

### Batch 15 — Intraday Commodity + Copier Analytics + Crypto Volume + ESMA + Employees + Equity Fees + FactSet (10 objects, completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_CommoditiesIntraHour_Clients](Tables/Dealing_CommoditiesIntraHour_Clients.md) | Table | 8.5 | Done ✅ active (to 2026-03-10) — 11.9M rows, minute-grain, 5 commodity instruments (17/18/19/22/96), HS=225 since Apr 2025 |
| 2 | [Dealing_CommoditiesIntraHour_Etoro](Tables/Dealing_CommoditiesIntraHour_Etoro.md) | Table | 7.0 | Done ✅ active (to 2026-03-10) — 12.6M rows, LP-side companion, per-LP NOP/value by minute |
| 3 | [Dealing_CopierAnalysis](Tables/Dealing_CopierAnalysis.md) | Table | 8.0 | Done ✅ active (to 2026-03-10) — 633M rows, HASH(ParentCID), dual-side demographics; FirstName/Email always NULL |
| 4 | [Dealing_CryptoVolume](Tables/Dealing_CryptoVolume.md) | Table | 3.0 | Done ✅ ⚠️ STALE since 2024-04-02 — no active writer SP found; hourly grain; CLUSTERED COLUMNSTORE |
| 5 | [Dealing_CryptoVolume_ByDirection](Tables/Dealing_CryptoVolume_ByDirection.md) | Table | 7.5 | Done ✅ active (to 2026-03-10) — 775K rows, daily crypto by direction; IsBuy inverted for closes |
| 6 | [Dealing_ESMANetLoss](Tables/Dealing_ESMANetLoss.md) | Table | 8.0 | Done ✅ active (to 2026-03-10) — 118.6K rows, loss≥95% filter, NoRestrictionNetProfit/DeltaLoss stop-protection fields |
| 7 | [Dealing_Employees_Report](Tables/Dealing_Employees_Report.md) | Table | 7.5 | Done ✅ active (to 2026-03-10) — 231.4M rows, HASH(CID), AccountTypeID IN (7,13); CopyTarde+previos typos |
| 8 | [Dealing_EquityFees](Tables/Dealing_EquityFees.md) | Table | 8.0 | Done ✅ active (to 2026-03-09) — 3.8M rows, JP Morgan+Goldman Sachs LP financing vs client NOP (HedgeServerID IN 2,101); Fianancing typo preserved |
| 9 | [Dealing_FactSet_Daily](Tables/Dealing_FactSet_Daily.md) | Table | 6.5 | Done ✅ ⚠️ STALE since 2024-06-04 — 425.6K rows, TRUNCATE pattern, PI/CP daily portfolio for FactSet feed |
| 10 | [Dealing_FactSet_Management](Tables/Dealing_FactSet_Management.md) | Table | 7.5 | Done ✅ ⚠️ STALE since 2024-06-04 — 4K rows, control table for FactSet PI send tracking |

**Notes**: Batch 15 spans four functional families. (1) **Intraday Commodity IntraHour** (2 tables): SP_IntraHourCommodityReport writes both Clients and Etoro sides in same run. 5 commodity instruments (Oil=17, Gold=18, NatGas=19, Silver=22, Copper=96). HS=225 hardcoded since SR-310993 Apr 2025. IDs 150/151 price from Gold (22). Forward-fill via LAG for weekend/gap price smoothing. (2) **Copier Analytics + Crypto** (3 tables): Dealing_CopierAnalysis is the largest in batch (633M rows, HASH(ParentCID)); FirstName/Email always NULL by design. Dealing_CryptoVolume is STALE since Apr 2024 — no writer SP found in SSDT; Dealing_CryptoVolume_ByDirection is the active replacement (daily grain, IsBuy-inverted for closes). (3) **Regulatory/Compliance** (2 tables): Dealing_ESMANetLoss captures extreme loss positions (≥95% loss, ClosePositionReasonID=1); DeltaLoss = stop-protection benefit; uses PriceLog for NoProtectionRate. Dealing_Employees_Report tracks employee positions (AccountTypeID 7/13, IsValidCustomer=0); 3-way DailyPnL logic; two DDL typos (CopyTarde, previos). (4) **Equity Fees + FactSet** (3 tables): Dealing_EquityFees joins JP Morgan (EOD + availability) + Goldman Sachs + client NOP (HedgeServerID IN 2,101=CBH); "Fianancing" typo in 4 columns preserved from LP report. FactSet integration STALE since Jun 2024 — Daily uses TRUNCATE (single snapshot), Management is UPSERT control table (HistorySendFlag manually managed). Quality avg: 7.5/10.

---

### Batch 16 — Rollover Assurance + US Staking Full Suite + Islamic Fees (9 objects, completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_Rollover_Assurance](Tables/Dealing_Rollover_Assurance.md) | Table | 8.5 | Done ✅ active (to 2026-03-10) — 46.4M rows, HASH(CID+InstrID), rollover fee discrepancy audit; 4 breakdown categories; 21:00 UTC cutoff |
| 2 | [Dealing_Staking_Position_US](Tables/Dealing_Staking_Position_US.md) | Table | 8.5 | Done ✅ active (to 2026-03) — 592K rows, 3 instruments (ADA/ETH/SOL), position-level CS support; IsPI/IsOptedIn_ETH always NULL |
| 3 | [Dealing_Staking_Results_US](Tables/Dealing_Staking_Results_US.md) | Table | 8.0 | Done ✅ active (to 2026-03) — 122K rows, CID-level rewards, $1 min threshold, 6 ClubCategory buckets |
| 4 | [Dealing_Staking_Summary_US](Tables/Dealing_Staking_Summary_US.md) | Table | 8.0 | Done ✅ active (to 2026-03) — 14 rows (3 instruments × ~5 months), EtoroYield formula, MonthlyPool, IntroDays |
| 5 | [Dealing_Staking_OptedOut_PerCID_US](Tables/Dealing_Staking_OptedOut_PerCID_US.md) | Table | 8.0 | Done ✅ active, 10.1M rows, 4 instruments (ADA/ETH/SOL/SUI); Country column = US state name (legacy naming) |
| 6 | [Dealing_Staking_OptedOut_US](Tables/Dealing_Staking_OptedOut_US.md) | Table | 8.0 | Done ✅ active; daily aggregate, LiquidityBuffer, Units_AvailableForStaking = OptedInUnits × buffer |
| 7 | [Dealing_Staking_Parameters_US](Tables/Dealing_Staking_Parameters_US.md) | Table | 8.5 | Done ✅ 4-row config (ADA/ETH/SOL/SUI); ETH IntroDays=60 (regulatory), SUI Distribution_StartDate=2026-04-01 (future) |
| 8 | [Dealing_Islamic_Daily_Administrative_Fee](Tables/Dealing_Islamic_Daily_Administrative_Fee.md) | Table | 8.5 | Done ✅ active (to 2026-03-10) — 17.6M rows, 6 instrument types, 22:00 UTC cutoff, triple-day Wed/Thu/Fri, Germany Crypto exclusion |
| 9 | [Dealing_Islamic_Daily_Spot_Price_Adjustment](Tables/Dealing_Islamic_Daily_Spot_Price_Adjustment.md) | Table | 8.5 | Done ✅ active (to 2026-03-09) — 392K rows, 7 futures instruments (XTI/XNG/EuroOIL/metals), Fee_Type_ID=2, Fivetran feed, fee can be positive |

**Notes**: Batch 16 covers two functional families. (1) **Rollover Assurance** (1 table): SP_Rev_Assurance writes three tables (Rollover_Assurance, Commission_Assurance, Commission_Assurance_By_Position). Rollover_Assurance audits rollover fee discrepancies with 4 mutually exclusive breakdown categories ([Calculated RO], [Islamic], [Closed after cutoff], [Fee updated], [Other]). Only stores positions where ABS(diff) > 1 USD. 21:00 UTC cutoff. Triple-day on Wed (FX/Commodities/Indices) or Fri (Stocks/ETF/Crypto). (2) **US Staking complete suite** (6 tables): SP_Staking_US writes Results_US + Summary_US + Position_US; SP_Staking_DailyPool_US writes OptedOut_PerCID_US + OptedOut_US + DailyPool_US. Parameters_US is manually maintained 4-row config. Key US-specific facts: IntroDays gate (ETH=60d, ADA=9d, SOL/SUI=7d), RegulationID=8 (FinCEN+FINRA), GCID-based, External_USABroker enrollment tables, excluded states (CA/MD/NJ/WI/WA/NY/NV/HI), SUI added Feb 2026 with Distribution_StartDate=2026-04-01 still future. Country column in OptedOut_PerCID_US stores US state names despite column name. (3) **Islamic fee tables** (2 tables): SP_Islamic_Administrative_Fee (Fee_Type_ID=1, always ≤0, 22:00 UTC cutoff, grace period, triple-day, Germany Crypto lever-1 exclusion, 25 suspended instruments blacklist) and SP_Islamic_Spot_Price_Adjustment (Fee_Type_ID=2, futures roll cost, can be positive, 7 instruments, skips weekends, Fivetran dependency with email alert). Quality avg: 8.3/10.

---

### Batch 14 — Client Analytics + Manual Execution + Surveillance + ADV Monitoring + NOP/Risk (24 objects, completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_ClientDataFinal](Tables/Dealing_ClientDataFinal.md) | Table | 8.5 | Done ✅ active (to 2026-03-06) — weekly Sat, 18,151 rows, Stocks/Indices/Commodities only |
| 2 | [Dealing_ClientDataRecurring](Tables/Dealing_ClientDataRecurring.md) | Table | 8.0 | Done ✅ active (to 2026-03-06) — weekly, recurring trader PercentageOfReturn metrics |
| 3 | [Dealing_ClientDataTop50](Tables/Dealing_ClientDataTop50.md) | Table | 8.0 | Done ✅ active (to 2026-03-06) — weekly, 786,704 rows, top 50 CIDs by volume per instrument |
| 4 | [Dealing_ClientsDataChange_3Months](Tables/Dealing_ClientsDataChange_3Months.md) | Table | 8.0 | Done ✅ active (to 2026-03-06) — weekly, 3-month volume/leverage delta |
| 5 | [Dealing_ClientsDataChange_6Months](Tables/Dealing_ClientsDataChange_6Months.md) | Table | 8.0 | Done ✅ active (to 2026-03-06) — weekly, 6-month volume/leverage delta |
| 6 | [Dealing_Commission_Assurance](Tables/Dealing_Commission_Assurance.md) | Table | 8.0 | Done ✅ active (2026-03) — monthly MTD, 612 rows; Stocks Manual ratio ~0.98 expected |
| 7 | [Dealing_Commission_Assurance_By_Position](Tables/Dealing_Commission_Assurance_By_Position.md) | Table | 8.5 | Done ✅ active — 90M+ rows, position-level detail; same SP as #6 |
| 8 | [Dealing_ClientCountry](Tables/Dealing_ClientCountry.md) | Table | 8.0 | Done ✅ active (to 2026-03-10) — daily NOP by client country, domestic instruments only |
| 9 | [Dealing_ClientCountry_Reg](Tables/Dealing_ClientCountry_Reg.md) | Table | 8.0 | Done ✅ active (to 2026-03-10) — daily regulation×region alignment count |
| 10 | [Dealing_CME_Reporting](Tables/Dealing_CME_Reporting.md) | Table | 8.0 | Done ✅ active (to 2026-02-28) — monthly, 690 rows, 24 hardcoded CME instruments |
| 11 | [Dealing_CapitalGuarantee](Tables/Dealing_CapitalGuarantee.md) | Table | 8.0 | Done ✅ active post-expiry (to 2026-03-10) ⚠️ promo expired 2025-01-01, SP still running |
| 12 | [Dealing_ManualPositionClose](Tables/Dealing_ManualPositionClose.md) | Table | 8.5 | Done ✅ active (to 2026-03-10) — crisis-flow positions; US_Client CountryIDs hardcoded; tree structure via MirrorID |
| 13 | [Dealing_Manual_Exec](Tables/Dealing_Manual_Exec.md) | Table | 8.0 | Done ✅ ⚠️ STALE since 2024-11-02 — 3 exec types (Manual/Automatic/HBC_PI); USD volume with FX conversion |
| 14 | [Dealing_Manual_Exec_Trade](Tables/Dealing_Manual_Exec_Trade.md) | Table | 8.5 | Done ✅ active (to 2026-03-10) — signed units (±1×IsBuy); RequestTypeID IN (0,3) |
| 15 | [Dealing_Manual_Exec_Trade_Summary](Tables/Dealing_Manual_Exec_Trade_Summary.md) | Table | 8.5 | Done ✅ active — NOP_Start/End from netting; Zero from BI_DB_DailyZero_TreeSize_NEW |
| 16 | [Dealing_SuspiciousActivityTrading_24H](Tables/Dealing_SuspiciousActivityTrading_24H.md) | Table | 9.0 | Done ✅ active (to 2026-03-10) — 3-min window, ≥5 trades AND >$3K profit; NULL sentinels on empty days |
| 17 | [Dealing_PreviouslyIdentifiedAbusers](Tables/Dealing_PreviouslyIdentifiedAbusers.md) | Table | 8.5 | Done ✅ active (to 2026-03-10) ⚠️ SENSITIVE — ~120 hardcoded FirstName+LastName pairs; NULL sentinels |
| 18 | [Dealing_SelfCopyingPI](Tables/Dealing_SelfCopyingPI.md) | Table | 7.5 | Done ✅ ⛔ DECOMMISSIONED — HOLD_20240416 prefix; last data 2023-09-03 |
| 19 | [Dealing_Monitoring_ADV](Tables/Dealing_Monitoring_ADV.md) | Table | 8.5 | Done ✅ active (to 2026-03-10) — 29M rows, Real Stocks+ETFs only; special-char columns; CopyFromLake ExecutionLog |
| 20 | [Dealing_Monitoring_ADV_MoreThanPercent](Tables/Dealing_Monitoring_ADV_MoreThanPercent.md) | Table | 8.0 | Done ✅ active — companion to ADV; per-CID PercentfromADV threshold alerts |
| 21 | [Dealing_NOP_Report](Tables/Dealing_NOP_Report.md) | Table | 8.0 | Done ✅ active (to 2026-03-09) — ~54K rows; multi-LP (GS/IB/JP/SAXO/BNY/Marex/IronBeam/FXCM/UBS); skips Saturday |
| 22 | [Dealing_MAXLeverageByNOP](Tables/Dealing_MAXLeverageByNOP.md) | Table | 8.5 | Done ✅ active (to 2026-03-11) — 6.3M rows; JSON tiers from External_SettingsDB; no @Date param |
| 23 | [Dealing_MaxNOPLimitSettings](Tables/Dealing_MaxNOPLimitSettings.md) | Table | 8.0 | Done ✅ active (to 2026-03-10) — 3M rows; EXW_Settings schema; CID-level overrides via TagType='Customer' |
| 24 | [Dealing_MaxPositionUnits](Tables/Dealing_MaxPositionUnits.md) | Table | 8.0 | Done ✅ active (to 2026-03-10) — 5.7M rows; DWH_staging.ProviderToInstrument; special-char [MaxPositionUnitsXaip.LastPrice] |

**Notes**: Batch 14 spans five functional families. (1) **Client Analytics** (7 tables): SP_W_Sat_WeeklyClientData (5 tables — InstrumentTypeID scope varies; Change tables use types 2,4 only), SP_ClientCountry (2 tables — same SP execution; Exchange→country CASE mapping hardcoded). Plus SP_Rev_Assurance (2 tables — monthly MTD, 90M+ row position-detail), SP_M_CME_Reporting (1 table — 24 hardcoded CME instruments), SP_CapitalGuarantee (1 table — promo expired 2025-01-01, SP still running). (2) **Manual Execution** (4 tables): SP_ManualPositionClose (crisis-flow, US_Client via 6 hardcoded CountryIDs), SP_Manual_Exec (STALE since Nov 2024, 3 exec types, complex FX conversion with InstrumentID 19/22 multipliers), SP_Manual_Exec_Trade (active, signed units, also writes Summary with NOP netting). (3) **Surveillance/Abuse** (3 tables): SP_SuspiciousActivityTrading_24H (3-min burst + copy-trade detection, NULL sentinels on empty days, IsImportantPI >10 copiers threshold), SP_PreviouslyIdentifiedAbusers (⚠️ ~120 hardcoded name pairs — SENSITIVE, NULL sentinels), SelfCopyingPI (⛔ DECOMMISSIONED April 2024 via HOLD prefix, last data Sep 2023). (4) **ADV Monitoring** (2 tables): SP_Monitoring_ADV writes both in same execution; InstrumentTypeID IN (5,6) = Real Stocks+ETFs; 29M row parent + per-CID PercentfromADV child; CopyFromLake ExecutionLog added Dec 2024 (SR-289246). (5) **NOP/Risk Configuration** (4 tables): NOP_Report (ProcessType 3 SQL&TIME, skips Saturday, Sunday→Friday, 10 LPs, 21K-token SP), MAXLeverageByNOP (JSON_VALUE from BI_DB_dbo.External_SettingsDB, GETDATE() only, 5 NOP tiers), MaxNOPLimitSettings (EXW_Settings schema — different from External_SettingsDB; CID overrides via TagType='Customer'), MaxPositionUnits (DWH_staging.ProviderToInstrument, Tradable=1 filter, [MaxPositionUnitsXaip.LastPrice] = units × price). Quality avg: 8.2/10. Key findings: (1) **Weekly client data family** (5 tables all from one 1,239-line SP): InstrumentTypeID scope varies — ClientDataFinal/Top50/Recurring use types 4,2,1 (Stocks/Indices/Commodities); Change tables use types 2,4 only. ClientDataRecurring tracks PercentageOfReturn for recurring traders (2+ weeks); ClientDataTop50 ranks the top 50 CIDs by volume per instrument per week. (2) **Commission Assurance family**: Commission_Assurance (612 rows) is the monthly summary; Commission_Assurance_By_Position (90M+ rows) is position-level detail. Stocks/Manual ratio ~0.98 is expected behavior (zero-commission real stock trading model). Max Rev Lost = NoCommission_Positions × $0.005 is a conservative proxy, not actual. (3) **SP_ClientCountry** writes both ClientCountry and ClientCountry_Reg in a single execution — domestic NOP filter (instrument country = client country) and regulation-region alignment respectively. Exchange→country mapping is hardcoded CASE in SP (requires SP update for new exchanges). (4) **CME Reporting**: Monthly regulatory obligation, instrument list hardcoded (24 IDs + crude oil name pattern), crude oil variants normalized to 'Crude Oil Future'. SR-303463 added 3 instruments Mar 2025. (5) **CapitalGuarantee**: GainersQtr promotion (ParentCID=4657429, 2023-09-26 to 2023-11-20 copier window). Guarantee expired 2025-01-01 but SP still runs daily — decommission pending. Eligibility_Ratio = cumulative product of daily withdrawal ratios. Quality avg: 8.1/10.

---

### Batch 13 — Latency + Spreads + Extended Hours (17 objects, completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_Daily_Latency](Tables/Dealing_Daily_Latency.md) | Table | 8.5 | Done ✅ ⚠️ STALE since Jan 2025 (CopyFromLake feed) |
| 2 | [Dealing_Daily_Latency_StatusUpdateTime](Tables/Dealing_Daily_Latency_StatusUpdateTime.md) | Table | 7.5 | Done ✅ ⚠️ 3-month window only (Jul–Oct 2024) |
| 3 | [Dealing_Daily_Latency_AllPositions](Tables/Dealing_Daily_Latency_AllPositions.md) | Table | 8.5 | Done ✅ ⚠️ STALE since Jan 2025, 295M rows |
| 4 | [Dealing_Daily_Latency_AllPositions_StatusUpdateTime](Tables/Dealing_Daily_Latency_AllPositions_StatusUpdateTime.md) | Table | 7.5 | Done ✅ ⚠️ 3-month window (Jul–Oct 2024), 56.9M rows |
| 5 | [Dealing_Daily_Latency_ClientOrder_WithDelay](Tables/Dealing_Daily_Latency_ClientOrder_WithDelay.md) | Table | 8.5 | Done ✅ ⚠️ STALE since Jan 2025, 26.4M rows |
| 6 | [Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime](Tables/Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime.md) | Table | 7.5 | Done ✅ ⚠️ 3-month window (Jul–Oct 2024), 5.1M rows |
| 7 | [Dealing_Daily_Latency_Compensation_StatusUpdateTime](Tables/Dealing_Daily_Latency_Compensation_StatusUpdateTime.md) | Table | 8.0 | Done ✅ ⚠️ 3-month window, 34 cols incl. SlippageInDollar, WithinFirst5Min |
| 8 | [Dealing_OccurredAtProvider_Latency_Instrument](Tables/Dealing_OccurredAtProvider_Latency_Instrument.md) | Table | 8.0 | Done ✅ ⚠️ STALE since Jan 2025 (PriceLog feed) |
| 9 | [Dealing_OccurredAtProvider_Latency_LiquidityAccountID](Tables/Dealing_OccurredAtProvider_Latency_LiquidityAccountID.md) | Table | 7.5 | Done ✅ ⚠️ STALE since Jan 2025, later start (Oct 2022) |
| 10 | [Dealing_OccurredAtProvider_Latency_PCSID](Tables/Dealing_OccurredAtProvider_Latency_PCSID.md) | Table | 7.0 | Done ✅ ⚠️ STALE since Jan 2025, most-aggregated |
| 11 | [Dealing_Latency_SuspiciousCIDs](Tables/Dealing_Latency_SuspiciousCIDs.md) | Table | 8.5 | Done ✅ ACTIVE (to 2026-03-10) ⚠️ NULL sentinel rows on empty days |
| 12 | [Dealing_DailySpread_ModeFrequency](Tables/Dealing_DailySpread_ModeFrequency.md) | Table | 8.0 | Done ✅ ACTIVE (to 2026-03-10) — char(50) padding on key cols |
| 13 | [Dealing_DailySpreadsAggregated](Tables/Dealing_DailySpreadsAggregated.md) | Table | 7.5 | Done ✅ ⚠️ STALE since Feb 2025 — AvgAskAt23 naming misleading |
| 14 | [Dealing_DailySpreadsAggregatedFX](Tables/Dealing_DailySpreadsAggregatedFX.md) | Table | 7.0 | Done ✅ ⚠️ STALE since Apr 2024 — FX branch removed from SP |
| 15 | [Dealing_DailyVariableSpread](Tables/Dealing_DailyVariableSpread.md) | Table | 8.0 | Done ✅ ACTIVE (to 2026-03-10) — FullDate not Date |
| 16 | [Dealing_Extented_Hours_NewCID](Tables/Dealing_Extented_Hours_NewCID.md) | Table | 7.5 | Done ✅ ⚠️ ~7 months stale (last Aug 2025) — typo in name |
| 17 | [Dealing_Extented_Hours_Volume](Tables/Dealing_Extented_Hours_Volume.md) | Table | 8.0 | Done ✅ ⚠️ ~7 months stale — HASH(PositionID) distribution, OverNight_Session added Mar 2025 |

**Notes**: Batch 13 covers three functional families: (1) **Latency family** (11 tables from SP_Latency_Report and SP_Latency_Report_StatusUpdateTime): All latency tables stopped Jan 11, 2025 due to CopyFromLake.eToroLogs_Real_Hedge_EMSOrders feed disruption. The _StatusUpdateTime family (5 tables) covers only Jul–Oct 2024 — a 3-month experimental window using "Routed" EMS events instead of "Filled". Key naming confusion: `ClientToExecutionLatency` measures routing latency (not fill) in all _StatusUpdateTime tables. (2) **OccurredAtProvider family** (3 tables from SP_OccurredAtProvider_Latency): Measures price feed delivery latency from LPs (OccurredOnProvider→ReceivedOnPriceServer in seconds, filter ≥3s). Also stopped Jan 2025 (PriceLog feed). Three granularity levels: Instrument (most detailed) → LiquidityAccountID → PCSID (most aggregated). (3) **Spreads + Extended Hours** (3 spread tables active/stale, 2 extended hours tables ~7 months stale): DailySpreadsAggregated stopped Feb 2025 (PricesFromProvider feed), FX variant stopped Apr 2024 (FX branch removed from SP). DailySpread_ModeFrequency and DailyVariableSpread remain active. Extended hours tables ("Extented" typo preserved in all objects) stopped Aug 2025 despite OpsDB Priority 0 tracking. OverNight_Session category added to Volume table Mar 2025 — not backfilled. Quality avg: 7.9/10.

---

### Batch 12 — CommissionsAndFails continuation + PlayerLevel + Staking core (10 objects, completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_FailReasons_PIs](Tables/Dealing_FailReasons_PIs.md) | Table | 8.5 | Done ✅ active (to 2026-03-10) |
| 2 | [Dealing_Fails_PI](Tables/Dealing_Fails_PI.md) | Table | 8.0 | Done ✅ active, 3.97B rows — use COUNT_BIG |
| 3 | [Dealing_Fails_PI_ErrorCodes](Tables/Dealing_Fails_PI_ErrorCodes.md) | Table | 7.5 | Done ✅ static lookup (234 rows, no automated ETL) |
| 4 | [Dealing_PlayerLevel_Data](Tables/Dealing_PlayerLevel_Data.md) | Table | 8.5 | Done ✅ active (Dec 2023–Mar 2026) |
| 5 | [Dealing_PlayerLevel_Data_PIs](Tables/Dealing_PlayerLevel_Data_PIs.md) | Table | 8.5 | Done ✅ active — Diamond/Platinum Plus only |
| 6 | [Dealing_PlayerLevel_Fails](Tables/Dealing_PlayerLevel_Fails.md) | Table | 9.0 | Done ✅ active |
| 7 | [Dealing_PlayerLevel_Fails_PIs](Tables/Dealing_PlayerLevel_Fails_PIs.md) | Table | 7.5 | Done ✅ active — sparse, "Other" dominates |
| 8 | [Dealing_Staking_Position](Tables/Dealing_Staking_Position.md) | Table | 8.0 | Done ✅ active, 159.5M rows ⚠️ malformed StakingMonthID (2025030, 2024100) |
| 9 | [Dealing_Staking_Results](Tables/Dealing_Staking_Results.md) | Table | 8.5 | Done ✅ active, 20.4M rows ⚠️ malformed IDs |
| 10 | [Dealing_Staking_Summary](Tables/Dealing_Staking_Summary.md) | Table | 8.5 | Done ✅ active, 158 rows (9 instruments × months) ⚠️ malformed ID |

**Notes**: Batch 12 covers the CommissionsAndFails PI extensions and the three core Staking pipeline tables. Key findings: (1) `Dealing_Fails_PI` contains ALL position fails (not just PIs) despite the name — the IsPI column flags PI clients inline; 3.97B rows requires COUNT_BIG(*); (2) `Dealing_Fails_PI_ErrorCodes` is a 234-row static reference with no automated ETL — must be manually maintained to keep Generic_FailReason populated; (3) All three PlayerLevel tables show only Diamond and Platinum Plus for PI population (PIs are high-tier by definition); (4) SP_CommissionsAndFails_PerCID and SP_Fails_PI use different source paths (CopyFromLake vs Dealing_staging) for the same production PositionFail data; (5) Staking pipeline: Position (159.5M rows, eligibility + pool) → Results (20.4M rows, per-CID awards + airdrop) → Summary (158 rows, instrument×month overview for finance/management); (6) StakingMonthID bug: malformed 7-digit IDs 2025030/2024100/2025100 corrupt MAX() and ORDER BY — always use StakingYear+StakingMonth for temporal ordering; (7) ETH staking is opt-in OFF by default; all other coins (ADA/SOL/TRX/etc.) are opt-in ON by default; (8) PIs are excluded from staking rewards. Quality avg: 8.3/10.

---

### Batch 11 — 10 objects (completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_Execution_Slippage](Tables/Dealing_Execution_Slippage.md) | Table | 8.0 | Done ✅ ⚠️ STALE since Oct 2024 (Kusto feed broken) |
| 2 | [Dealing_Execution_Slippage_AssetType](Tables/Dealing_Execution_Slippage_AssetType.md) | Table | 8.5 | Done ✅ ⚠️ STALE since Oct 2024 |
| 3 | [Dealing_Execution_Slippage_AssetType_RequestTime](Tables/Dealing_Execution_Slippage_AssetType_RequestTime.md) | Table | 8.5 | Done ✅ ⚠️ gap since Jan 2025 (SP scheduling) |
| 4 | [Dealing_Execution_Slippage_RequestTime](Tables/Dealing_Execution_Slippage_RequestTime.md) | Table | 8.5 | Done ✅ ⚠️ gap since Jan 2025 (SP scheduling) |
| 5 | [Dealing_Daily_Slippage_Positions_TriggerVSReceived](Tables/Dealing_Daily_Slippage_Positions_TriggerVSReceived.md) | Table | 8.0 | Done ✅ ⚠️ gap since Jan 2025 (SP scheduling) |
| 6 | [Dealing_Daily_Slippage_Totals](Tables/Dealing_Daily_Slippage_Totals.md) | Table | 8.5 | Done ✅ ⚠️ gap since Jan 2025 (SP scheduling) |
| 7 | [Dealing_Daily_Slippage_Totals_TriggerVSReceived](Tables/Dealing_Daily_Slippage_Totals_TriggerVSReceived.md) | Table | 8.5 | Done ✅ ⚠️ gap since Jan 2025 (SP scheduling) |
| 8 | [Dealing_CIDs_CommissionsAndFails](Tables/Dealing_CIDs_CommissionsAndFails.md) | Table | 8.5 | Done ✅ active (to 2026-03-10) |
| 9 | [Dealing_CIDs_CommissionsAndFails_PIs](Tables/Dealing_CIDs_CommissionsAndFails_PIs.md) | Table | 9.0 | Done ✅ active (to 2026-03-10) |
| 10 | [Dealing_FailReasons](Tables/Dealing_FailReasons.md) | Table | 9.0 | Done ✅ active (to 2026-03-10) |

**Notes**: Batch 11 covers the Execution Quality & Commission Monitoring family. Key findings: (1) The 4 Execution_Slippage tables use SP_Execution_Slippage — SendTime variants (no suffix / _AssetType) are STALE since Oct 2024 due to broken Kusto LP price feed (CopyFromLake.PricesFromProvider_MarketCurrencyPrice); _RequestTime variants stopped Jan 2025 (SP scheduling gap); (2) SP_Slippage_Report writes to 6 tables — Totals/Positions + TVR variants; all stopped Jan 2025 (SP scheduling); (3) TVR (Trigger-vs-Received) method uses eToro market price at request arrival time (from PriceLog CROSS APPLY on ReceivedOnPriceServer) rather than the static customer-chosen order rate, providing more accurate slippage attribution for SL/TP events; (4) Dealing_Daily_Slippage_Totals_TriggerVSReceived lacks WithinFirst5Minutes_MarketHours/IsSettled columns added to the non-TVR Totals table in Sep-Oct 2024; (5) CommissionsAndFails/PIs tables are actively updated (to Mar 2026), covering only TOP 20 CIDs by commission per day; GuruStatusID IN (5,6) = Popular Investor filter for PIs table; (6) Dealing_FailReasons has population-wide fail counts (100K+/day for Min Position Amount); HedgeServerID NULL means platform-level rejection before server routing. Quality avg: 8.5/10.

---

### Batch 10 — 10 objects (completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_Staking_Club](Tables/Dealing_Staking_Club.md) | Table | 8.0 | Done ✅ active |
| 2 | [Dealing_Staking_Club_US](Tables/Dealing_Staking_Club_US.md) | Table | 8.0 | Done ✅ active |
| 3 | [Dealing_Staking_Compensation](Tables/Dealing_Staking_Compensation.md) | Table | 8.0 | Done ✅ ⚠️ malformed IDs (2025030, 2024100) |
| 4 | [Dealing_Staking_Compensation_US](Tables/Dealing_Staking_Compensation_US.md) | Table | 7.5 | Done ✅ active (14 rows) |
| 5 | [Dealing_Staking_DailyPool](Tables/Dealing_Staking_DailyPool.md) | Table | 8.0 | Done ✅ active |
| 6 | [Dealing_Staking_DailyPool_US](Tables/Dealing_Staking_DailyPool_US.md) | Table | 7.8 | Done ✅ active |
| 7 | [Dealing_Staking_Emails_New](Tables/Dealing_Staking_Emails_New.md) | Table | 8.0 | Done ✅ ⚠️ same malformed IDs |
| 8 | [Dealing_Staking_Emails_US](Tables/Dealing_Staking_Emails_US.md) | Table | 7.5 | Done ✅ active |
| 9 | [Dealing_Staking_OptedOut](Tables/Dealing_Staking_OptedOut.md) | Table | 8.5 | Done ✅ active |
| 10 | [Dealing_Staking_OptedOut_PerCID](Tables/Dealing_Staking_OptedOut_PerCID.md) | Table | 8.5 | Done ✅ active ⚠️ 590M rows |

**Notes**: Batch 10 documents the Staking family (non-US and US variants). Key findings: (1) SP_Staking and SP_Staking_US write to parallel non-US/US table pairs — non-US uses row-store indexes, US uses COLUMNSTORE except for email tables; (2) All US tables started Oct 2025 (or Aug 2025 for DailyPool pre-seeding), much newer than non-US (Sep 2023); (3) US staking has only 3 crypto currencies (ADA, SOL, ETH) vs 9 non-US; (4) Critical data quality issue: malformed StakingMonthID (2025030, 2024100) in Dealing_Staking_Compensation and Dealing_Staking_Emails_New caused by LEFT(7) bug in older SP version — needs data correction; (5) Dealing_Staking_OptedOut_PerCID is the largest table in Dealing_dbo at 590M rows — no retention policy documented; (6) SP_Staking triggers when Fivetran_google_sheets_platform_rewards is updated, SP_Staking_Emails triggers when etoro_Trade_AdminPositionLog receives airdrop results; (7) OpsDB does not track SP_Staking → Dealing_Staking_Club (monitoring gap). Quality avg: 8.0/10.

---

### Batch 9 — 10 objects (completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_IGReconEODHolding](Tables/Dealing_IGReconEODHolding.md) | Table | 7.8 | Done ✅ active |
| 2 | [Dealing_IGReconTrades](Tables/Dealing_IGReconTrades.md) | Table | 7.8 | Done ✅ active |
| 3 | [Dealing_JPMReconEODHolding](Tables/Dealing_JPMReconEODHolding.md) | Table | 7.8 | Done ✅ active |
| 4 | [Dealing_JPMReconTrades](Tables/Dealing_JPMReconTrades.md) | Table | 7.8 | Done ✅ active |
| 5 | [Dealing_VisionRecon_EODHoldings](Tables/Dealing_VisionRecon_EODHoldings.md) | Table | 7.5 | Done ✅ active |
| 6 | [Dealing_VisionRecon_Trades](Tables/Dealing_VisionRecon_Trades.md) | Table | 7.5 | Done ✅ active |
| 7 | [Dealing_Marex_Recon_EODHoldings](Tables/Dealing_Marex_Recon_EODHoldings.md) | Table | 7.3 | Done ✅ active |
| 8 | [Dealing_Marex_Recon_Trades](Tables/Dealing_Marex_Recon_Trades.md) | Table | 7.3 | Done ✅ active |
| 9 | [Dealing_Marex_Recon_EODHoldings_Futures](Tables/Dealing_Marex_Recon_EODHoldings_Futures.md) | Table | 7.0 | Done ✅ active (added May 2025) |
| 10 | [Dealing_Marex_Recon_Trades_Futures](Tables/Dealing_Marex_Recon_Trades_Futures.md) | Table | 7.0 | Done ✅ active (added May 2025) |

**Notes**: Batch 9 completes the LP Reconciliation family for IG, JPM, Vision, and Marex. Key findings: (1) IG recon uses parquet COPY INTO from data lake and a ~25-instrument #MarketNameToID hardcoded lookup; (2) JPM recon covers NA/EMEA/ASIA regions via 3 regional trade summary tables; HS 9 requires special ISIN+DisplayName join (no InstrumentID); (3) Vision recon uses CUSIP (not ISIN) as join key and includes etoro_Hedge_InstrumentBoundaries tolerance bands; Reality-Supposed/Reality-Client naming is unique to Vision; (4) Marex standard recon uses Google Sheets-backed Fivetran mapping (External_Bronze_Fivetran_google_sheets_marex_mapping_table) for contract→InstrumentID; etoro_Hedge_Netting is temporally versioned; (5) Marex Futures tables (added May 2025) operate at CID granularity, use lot-based reconciliation, and have legacy all-caps-with-space column names from Marex LP file; ADJ FX columns added Jul 2025; (6) Trades_Futures is unique in having a 3-way recon (Marex vs eToro vs Clients) while EODHoldings_Futures only compares Marex vs Clients. Quality avg: 7.5/10.

---

### Batch 8 — 13 objects (completed 2026-03-21, redone from bad template)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_CEPDailyAudit_CPToRule](Tables/Dealing_CEPDailyAudit_CPToRule.md) | Table | 8.0 | Done ✅ active (redone) |
| 2 | [Dealing_CEPDailyAudit_ConditionToCP](Tables/Dealing_CEPDailyAudit_ConditionToCP.md) | Table | 7.8 | Done ✅ active (redone) |
| 3 | [Dealing_CEPDailyAudit_Conditions](Tables/Dealing_CEPDailyAudit_Conditions.md) | Table | 8.0 | Done ✅ active (redone) |
| 4 | [Dealing_CEPDailyAudit_ListCIDMapping](Tables/Dealing_CEPDailyAudit_ListCIDMapping.md) | Table | 7.5 | Done ✅ active (redone) |
| 5 | [Dealing_CEPDailyAudit_NameLists](Tables/Dealing_CEPDailyAudit_NameLists.md) | Table | 7.5 | Done ✅ active (redone) |
| 6 | [Dealing_CEPDailyAudit_Rules](Tables/Dealing_CEPDailyAudit_Rules.md) | Table | 8.5 | Done ✅ active (redone) |
| 7 | [Dealing_CEPWeeklyAudit_CP](Tables/Dealing_CEPWeeklyAudit_CP.md) | Table | 8.0 | Done ✅ active (redone) |
| 8 | [Dealing_CEPWeeklyAudit_CPToRule](Tables/Dealing_CEPWeeklyAudit_CPToRule.md) | Table | 7.8 | Done ✅ active (redone) |
| 9 | [Dealing_CEPWeeklyAudit_ConditionToCP](Tables/Dealing_CEPWeeklyAudit_ConditionToCP.md) | Table | 7.8 | Done ✅ active (redone) |
| 10 | [Dealing_CEPWeeklyAudit_Conditions](Tables/Dealing_CEPWeeklyAudit_Conditions.md) | Table | 8.0 | Done ✅ active (redone) |
| 11 | [Dealing_CEPWeeklyAudit_ListCIDMapping](Tables/Dealing_CEPWeeklyAudit_ListCIDMapping.md) | Table | 7.5 | Done ✅ active (redone) |
| 12 | [Dealing_CEPWeeklyAudit_NameLists](Tables/Dealing_CEPWeeklyAudit_NameLists.md) | Table | 7.5 | Done ⚠️ SP bug flagged — NameLists insert JOIN may be incorrect (redone) |
| 13 | [Dealing_CEPWeeklyAudit_Rules](Tables/Dealing_CEPWeeklyAudit_Rules.md) | Table | 8.5 | Done ✅ active (redone) |

**Notes**: Batch 8 redone — originally generated with wrong template (YAML frontmatter, separate Tier column, wrong section headers). All 13 files regenerated with correct Phase 11 template (8 sections, inline tier suffixes, Confidence Tier Legend). CEP audit family: 2 SPs (SP_CEPDailyAudit daily, SP_W_CEPWeeklyAudit weekly) × 7 tables each. Quality avg: 7.9/10.

---

## Completed Batches

### Batch 7 — 10 objects (completed 2026-03-21, redone from bad template)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | ~~Daily_Slippage_Positions_HOLD~~ | Table (HOLD) | — | ⛔ Blacklisted (`*_HOLD` pattern — decommissioned) |
| 2 | [Dealing_015Min_AllTrades](Tables/Dealing_015Min_AllTrades.md) | Table | 6.5 | Done ⚠️ stale pipeline (frozen Apr 2024) (redone) |
| 3 | [Dealing_Apex_PnL](Tables/Dealing_Apex_PnL.md) | Table | 7.5 | Done ⚠️ stale pipeline (frozen Jun 2024) (redone) |
| 4 | [Dealing_Apex_PnL_Daily](Tables/Dealing_Apex_PnL_Daily.md) | Table | 7.5 | Done ⚠️ stale pipeline (frozen Jun 2024) (redone) |
| 5 | [Dealing_Apex_PnL_EE](Tables/Dealing_Apex_PnL_EE.md) | Table | 7.5 | Done ⚠️ stale pipeline (frozen Jun 2024) (redone) |
| 6 | [Dealing_Apex_PnL_EE_Daily](Tables/Dealing_Apex_PnL_EE_Daily.md) | Table | 7.5 | Done ⚠️ stale pipeline (frozen Jun 2024) (redone) |
| 7 | ~~Dealing_Best_Execution_Compensation_CBH_HOLD~~ | Table (HOLD) | — | ⛔ Blacklisted (`*_HOLD` pattern — decommissioned) |
| 8 | ~~Dealing_Best_Execution_Compensation_HBC_HOLD~~ | Table (HOLD) | — | ⛔ Blacklisted (`*_HOLD` pattern — decommissioned) |
| 9 | [Dealing_Boundary_Cost_H_Indices](Tables/Dealing_Boundary_Cost_H_Indices.md) | Table (Historical) | 6.5 | Done ⚠️ decommissioned (frozen Mar 2023) (redone) |
| 10 | [Dealing_CEPDailyAudit_CP](Tables/Dealing_CEPDailyAudit_CP.md) | Table | 8.0 | Done ✅ active (redone) |

**Notes**: Batch 7 redone — originally generated with wrong template (YAML frontmatter, separate Tier column, wrong section headers). All 10 files regenerated with correct Phase 11 template (8 sections, inline tier suffixes, Confidence Tier Legend). Contains decommissioned pipelines (HOLD/stale) + 1 active CEP table.

### Batch 5 — 10 objects (completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_dbo.Dealing_Staking_WelcomeEmail_Temp](Tables/Dealing_Staking_WelcomeEmail_Temp.md) | Table | 5.5 | Done |
| 2 | [Dealing_dbo.Dealing_DailyZeroPnL_Stocks](Tables/Dealing_DailyZeroPnL_Stocks.md) | Table | 8.0 | Done |
| 3 | [Dealing_dbo.Dealing_Duco_EODRecon](Tables/Dealing_Duco_EODRecon.md) | Table | 8.5 | Done |
| 4 | [Dealing_dbo.Dealing_Duco_ActivityRecon](Tables/Dealing_Duco_ActivityRecon.md) | Table | 8.5 | Done |
| 5 | [Dealing_dbo.Dealing_Daily_Latency_Compensation](Tables/Dealing_Daily_Latency_Compensation.md) | Table | 7.0 | Done ⚠️ pipeline decommissioned |
| 6 | [Dealing_dbo.Dealing_Daily_Slippage_Positions](Tables/Dealing_Daily_Slippage_Positions.md) | Table | 7.0 | Done ⚠️ pipeline decommissioned |
| 7 | [Dealing_dbo.Dealing_ApexRecon_TradeActivity](Tables/Dealing_ApexRecon_TradeActivity.md) | Table | 8.0 | Done |
| 8 | [Dealing_dbo.Dealing_Best_Execution_Compensation_CBH](Tables/Dealing_Best_Execution_Compensation_CBH.md) | Table | 7.0 | Done ⚠️ pipeline decommissioned |
| 9 | [Dealing_dbo.Dealing_Best_Execution_Compensation_HBC](Tables/Dealing_Best_Execution_Compensation_HBC.md) | Table | 7.0 | Done ⚠️ pipeline decommissioned |
| 10 | [Dealing_dbo.Dealing_CloseOnly_Recon](Tables/Dealing_CloseOnly_Recon.md) | Table | 7.8 | Done |

**Notes**: Batch 5 reveals a potentially decommissioned best-execution pipeline: Dealing_Daily_Latency_Compensation, Dealing_Daily_Slippage_Positions, Dealing_Best_Execution_Compensation_CBH/HBC all have max_date 2025-01-11. Dealing_Duco_EODRecon and ActivityRecon are critical foundations for 11+ LP recon tables.

### Batch 6 — 10 objects (completed 2026-03-21)

| # | Object | Type | Quality | Status |
|---|--------|------|---------|--------|
| 1 | [Dealing_BNY_Citadel_ReconTrades](Tables/Dealing_BNY_Citadel_ReconTrades.md) | Table | 7.5 | Done |
| 2 | [Dealing_BNY_Detailed](Tables/Dealing_BNY_Detailed.md) | Table | 7.0 | Done |
| 3 | [Dealing_BNY_VIRTU_ReconEODHolding](Tables/Dealing_BNY_VIRTU_ReconEODHolding.md) | Table | 7.5 | Done |
| 4 | [Dealing_BNY_VIRTU_ReconTrades](Tables/Dealing_BNY_VIRTU_ReconTrades.md) | Table | 7.5 | Done |
| 5 | [Dealing_GSReconEODHolding](Tables/Dealing_GSReconEODHolding.md) | Table | 7.5 | Done |
| 6 | [Dealing_GSReconTrades](Tables/Dealing_GSReconTrades.md) | Table | 7.8 | Done |
| 7 | [Dealing_IBRecon_EODHoldings](Tables/Dealing_IBRecon_EODHoldings.md) | Table | 7.8 | Done |
| 8 | [Dealing_IBRecon_EODHoldings_CFD](Tables/Dealing_IBRecon_EODHoldings_CFD.md) | Table | 7.0 | Done |
| 9 | [Dealing_IBRecon_Trades](Tables/Dealing_IBRecon_Trades.md) | Table | 6.5 | Done ⚠️ stale pipeline (last row 2025-08-22) |
| 10 | [Dealing_IBRecon_Trades_CFD](Tables/Dealing_IBRecon_Trades_CFD.md) | Table | 5.5 | Done ⚠️ effectively abandoned (1 row, 2025-03-28) |

**Notes**: All 10 objects are LP reconciliation tables at dependency depth 2. Three writer SPs: SP_BNY_VIRTU_Recon (4 tables), SP_GSRecon (2 tables), SP_IB_Recon (4 tables). IBRecon_Trades is stale (7+ months); IBRecon_Trades_CFD has a single row and appears abandoned. Both warrant operational investigation by the Dealing team.

### Batch 1 — 10 objects (completed 2026-03-21)

| # | Object | Type | Quality | Files |
|---|--------|------|---------|-------|
| 1 | Dealing_dbo.DSC_HedgeOnIndices | Table | 7.2/10 | .md, .lineage.md, .review-needed.md |
| 2 | Dealing_dbo.DSC_HedgeOnIndices_H | Table | 7.0/10 | .md, .lineage.md, .review-needed.md |
| 3 | Dealing_dbo.Dealing_ClientsCapitalAdequacy | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 4 | Dealing_dbo.Dealing_LP_StocksNOP | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 5 | Dealing_dbo.Dealing_NOP_LPandClients | Table | 7.8/10 | .md, .lineage.md, .review-needed.md |
| 6 | Dealing_dbo.Dealing_CFDs_Stocks_Credit_Risk | Table | 8.0/10 | .md, .lineage.md, .review-needed.md |
| 7 | Dealing_dbo.Dealing_CopyPortfolio_Allocation | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 8 | Dealing_dbo.Dealing_DailyAvgSpread | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 9 | Dealing_dbo.Dealing_DealingDashboard_Clients | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 10 | Dealing_dbo.Dealing_Employee_Zero_StocksETFs | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |

### Batch 2 — 10 objects (completed 2026-03-21)

| # | Object | Type | Quality | Files |
|---|--------|------|---------|-------|
| 1 | Dealing_dbo.Dealing_NumberofPositionsOpened_Agg | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 2 | Dealing_dbo.Dealing_GS_Credit_Risk | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 3 | Dealing_dbo.Dealing_JP_Credit_Risk | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 4 | Dealing_dbo.Dealing_Max_NOP | Table | 7.0/10 | .md, .lineage.md, .review-needed.md |
| 5 | Dealing_dbo.Dealing_MIMO_Zero | Table | 8.0/10 | .md, .lineage.md, .review-needed.md |
| 6 | Dealing_dbo.Dealing_NOPDistribution | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 7 | Dealing_dbo.Dealing_OfferedInstruments | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 8 | Dealing_dbo.Dealing_RolloverCommissionSplit | Table | 8.0/10 | .md, .lineage.md, .review-needed.md |
| 9 | Dealing_dbo.Dealing_IndiciesIntraHour_Clients | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 10 | Dealing_dbo.Dealing_IndiciesIntraHour_Etoro | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |

### Batch 3 — 15 objects (completed 2026-03-21)

| # | Object | Type | Quality | Files |
|---|--------|------|---------|-------|
| 1 | Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown | Table | 7.8/10 | .md, .lineage.md, .review-needed.md |
| 2 | Dealing_dbo.Dealing_Failures | Table | 7.2/10 | .md, .lineage.md, .review-needed.md |
| 3 | Dealing_dbo.Dealing_Failures_Rate | Table | 7.0/10 | .md, .lineage.md, .review-needed.md |
| 4 | Dealing_dbo.Dealing_overnight_fees | Table | 6.0/10 | .md, .lineage.md, .review-needed.md |
| 5 | Dealing_dbo.Dealing_CEP_ExecutionMonitoring | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 6 | Dealing_dbo.Dealing_PDT | Table | 7.0/10 | .md, .lineage.md, .review-needed.md |
| 7 | Dealing_dbo.Dealing_MarketMakerAllTrade | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 8 | Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX | Table (HOLD) | 5.0/10 | .md, .lineage.md, .review-needed.md |
| 9 | Dealing_dbo.Dealing_MarketMakerBoundaries_CFD | Table | 7.2/10 | .md, .lineage.md, .review-needed.md |
| 10 | Dealing_dbo.Dealing_MarketMakerBoundaries_Real | Table | 7.2/10 | .md, .lineage.md, .review-needed.md |
| 11 | Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 12 | Dealing_dbo.Dealing_Islamic_Instruments_Groups | Table | 6.5/10 | .md, .lineage.md, .review-needed.md |
| 13 | Dealing_dbo.Dealing_Islamic_Units_Per_Contract | Table | 6.5/10 | .md, .lineage.md, .review-needed.md |
| 14 | Dealing_dbo.Dealing_Staking_Emails | Table | 6.8/10 | .md, .lineage.md, .review-needed.md |
| 15 | Dealing_dbo.Dealing_Staking_Parameters | Table | 6.5/10 | .md, .lineage.md, .review-needed.md |

### Batch 4 — 10 objects (completed 2026-03-21)

| # | Object | Type | Quality | Files |
|---|--------|------|---------|-------|
| 1 | Dealing_dbo.Dealing_Boundary_Cost | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 2 | Dealing_dbo.Dealing_HedgeCost | Table | 7.8/10 | .md, .lineage.md, .review-needed.md |
| 3 | Dealing_dbo.Dealing_ManipulationReport_RealStocks | Table | 7.5/10 | .md, .lineage.md, .review-needed.md |
| 4 | Dealing_dbo.Dealing_ManipulationReport_RealStocks_CID | Table | 7.8/10 | .md, .lineage.md, .review-needed.md |
| 5 | Dealing_dbo.Dealing_Market_Manipulation_Report | Table | 7.6/10 | .md, .lineage.md, .review-needed.md |
| 6 | Dealing_dbo.Dealing_Market_Manipulation_Report_FCA | Table | 7.2/10 | .md, .lineage.md, .review-needed.md |
| 7 | Dealing_dbo.Dealing_AbuseAPI | Table | 7.8/10 | .md, .lineage.md, .review-needed.md |
| 8 | Dealing_dbo.Dealing_AbusersCIDs | Table | 8.2/10 | .md, .lineage.md, .review-needed.md |
| 9 | Dealing_dbo.Dealing_ApexRecon_Hedging | Table | 7.4/10 | .md, .lineage.md, .review-needed.md |
| 10 | Dealing_dbo.Dealing_ApexRecon_Holdings | Table | 7.6/10 | .md, .lineage.md, .review-needed.md |

## Tables (232)

| Object | Quality | Status |
|--------|---------|--------|
| Dealing_dbo.DSC_HedgeOnIndices | 7.2/10 | Done (Batch 1) |
| Dealing_dbo.DSC_HedgeOnIndices_H | 7.0/10 | Done (Batch 1) |
| ~~Dealing_dbo.Daily_Slippage_Positions_HOLD~~ | — | ⛔ Blacklisted (`*_HOLD`) |
| [Dealing_dbo.Dealing_015Min_AllTrades](Tables/Dealing_015Min_AllTrades.md) | 6.5 | Done (Batch 7) ⚠️ stale |
| Dealing_dbo.Dealing_AbuseAPI | 7.8/10 | Done (Batch 4) |
| Dealing_dbo.Dealing_AbusersCIDs | 8.2/10 | Done (Batch 4) |
| Dealing_dbo.Dealing_ApexRecon_Hedging | 7.4/10 | Done (Batch 4) |
| Dealing_dbo.Dealing_ApexRecon_Holdings | 7.6/10 | Done (Batch 4) |
| [Dealing_dbo.Dealing_ApexRecon_TradeActivity](Tables/Dealing_ApexRecon_TradeActivity.md) | 8.0 | Done (Batch 5) |
| [Dealing_dbo.Dealing_Apex_PnL](Tables/Dealing_Apex_PnL.md) | 7.5 | Done (Batch 7) ⚠️ stale (Jun 2024) |
| [Dealing_dbo.Dealing_Apex_PnL_Daily](Tables/Dealing_Apex_PnL_Daily.md) | 7.5 | Done (Batch 7) ⚠️ stale (Jun 2024) |
| [Dealing_dbo.Dealing_Apex_PnL_EE](Tables/Dealing_Apex_PnL_EE.md) | 7.5 | Done (Batch 7) ⚠️ stale (Jun 2024) |
| [Dealing_dbo.Dealing_Apex_PnL_EE_Daily](Tables/Dealing_Apex_PnL_EE_Daily.md) | 7.5 | Done (Batch 7) ⚠️ stale (Jun 2024) |
| [Dealing_dbo.Dealing_BNY_Citadel_ReconTrades](Tables/Dealing_BNY_Citadel_ReconTrades.md) | 7.5 | Done (Batch 6) |
| [Dealing_dbo.Dealing_BNY_Detailed](Tables/Dealing_BNY_Detailed.md) | 7.0 | Done (Batch 6) |
| [Dealing_dbo.Dealing_BNY_VIRTU_ReconEODHolding](Tables/Dealing_BNY_VIRTU_ReconEODHolding.md) | 7.5 | Done (Batch 6) |
| [Dealing_dbo.Dealing_BNY_VIRTU_ReconTrades](Tables/Dealing_BNY_VIRTU_ReconTrades.md) | 7.5 | Done (Batch 6) |
| [Dealing_dbo.Dealing_Best_Execution_Compensation_CBH](Tables/Dealing_Best_Execution_Compensation_CBH.md) | 7.0 | Done (Batch 5) |
| ~~Dealing_dbo.Dealing_Best_Execution_Compensation_CBH_HOLD~~ | — | ⛔ Blacklisted (`*_HOLD`) |
| [Dealing_dbo.Dealing_Best_Execution_Compensation_HBC](Tables/Dealing_Best_Execution_Compensation_HBC.md) | 7.0 | Done (Batch 5) |
| ~~Dealing_dbo.Dealing_Best_Execution_Compensation_HBC_HOLD~~ | — | ⛔ Blacklisted (`*_HOLD`) |
| Dealing_dbo.Dealing_Boundary_Cost | 7.5/10 | Done (Batch 4) |
| [Dealing_dbo.Dealing_Boundary_Cost_H_Indices](Tables/Dealing_Boundary_Cost_H_Indices.md) | 6.5 | Done (Batch 7) ⚠️ decommissioned (Mar 2023) |
| [Dealing_dbo.Dealing_CEPDailyAudit_CP](Tables/Dealing_CEPDailyAudit_CP.md) | 8.0 | Done (Batch 7) |
| [Dealing_dbo.Dealing_CEPDailyAudit_CPToRule](Tables/Dealing_CEPDailyAudit_CPToRule.md) | 8.0 | Done (Batch 8) |
| [Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP](Tables/Dealing_CEPDailyAudit_ConditionToCP.md) | 7.8 | Done (Batch 8) |
| [Dealing_dbo.Dealing_CEPDailyAudit_Conditions](Tables/Dealing_CEPDailyAudit_Conditions.md) | 8.0 | Done (Batch 8) |
| [Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping](Tables/Dealing_CEPDailyAudit_ListCIDMapping.md) | 7.5 | Done (Batch 8) |
| [Dealing_dbo.Dealing_CEPDailyAudit_NameLists](Tables/Dealing_CEPDailyAudit_NameLists.md) | 7.5 | Done (Batch 8) |
| [Dealing_dbo.Dealing_CEPDailyAudit_Rules](Tables/Dealing_CEPDailyAudit_Rules.md) | 8.5 | Done (Batch 8) |
| [Dealing_dbo.Dealing_CEPWeeklyAudit_CP](Tables/Dealing_CEPWeeklyAudit_CP.md) | 8.0 | Done (Batch 8) |
| [Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule](Tables/Dealing_CEPWeeklyAudit_CPToRule.md) | 7.8 | Done (Batch 8) |
| [Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP](Tables/Dealing_CEPWeeklyAudit_ConditionToCP.md) | 7.8 | Done (Batch 8) |
| [Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions](Tables/Dealing_CEPWeeklyAudit_Conditions.md) | 8.0 | Done (Batch 8) |
| [Dealing_dbo.Dealing_CEPWeeklyAudit_ListCIDMapping](Tables/Dealing_CEPWeeklyAudit_ListCIDMapping.md) | 7.5 | Done (Batch 8) |
| [Dealing_dbo.Dealing_CEPWeeklyAudit_NameLists](Tables/Dealing_CEPWeeklyAudit_NameLists.md) | 7.5 | Done (Batch 8) ⚠️ SP bug flagged |
| [Dealing_dbo.Dealing_CEPWeeklyAudit_Rules](Tables/Dealing_CEPWeeklyAudit_Rules.md) | 8.5 | Done (Batch 8) |
| Dealing_dbo.Dealing_CEP_ExecutionMonitoring | 7.5/10 | Done (Batch 3) |
| Dealing_dbo.Dealing_CFDs_Stocks_Credit_Risk | 8.0/10 | Done (Batch 1) |
| [Dealing_dbo.Dealing_CIDs_CommissionsAndFails](Tables/Dealing_CIDs_CommissionsAndFails.md) | 8.5 | Done (Batch 11) ✅ active |
| [Dealing_dbo.Dealing_CIDs_CommissionsAndFails_PIs](Tables/Dealing_CIDs_CommissionsAndFails_PIs.md) | 9.0 | Done (Batch 11) ✅ active |
| [Dealing_dbo.Dealing_CME_Reporting](Tables/Dealing_CME_Reporting.md) | 8.0 | Done (Batch 14) ✅ active (to 2026-02-28) — monthly, 690 rows, 24 hardcoded CME instruments |
| [Dealing_dbo.Dealing_CapitalGuarantee](Tables/Dealing_CapitalGuarantee.md) | 8.0 | Done (Batch 14) ✅ active post-expiry (to 2026-03-10) ⚠️ promo expired 2025-01-01 |
| Dealing_dbo.Dealing_Clicks_OpenClose_Breakdown | 7.8/10 | Done (Batch 3) |
| [Dealing_dbo.Dealing_ClientCountry](Tables/Dealing_ClientCountry.md) | 8.0 | Done (Batch 14) ✅ active (to 2026-03-10) — daily NOP by client country, domestic instruments only |
| [Dealing_dbo.Dealing_ClientCountry_Reg](Tables/Dealing_ClientCountry_Reg.md) | 8.0 | Done (Batch 14) ✅ active (to 2026-03-10) — daily regulation×region alignment count |
| [Dealing_dbo.Dealing_ClientDataFinal](Tables/Dealing_ClientDataFinal.md) | 8.5 | Done (Batch 14) ✅ active (to 2026-03-06) — weekly Sat, 18,151 rows, Stocks/Indices/Commodities only |
| [Dealing_dbo.Dealing_ClientDataRecurring](Tables/Dealing_ClientDataRecurring.md) | 8.0 | Done (Batch 14) ✅ active (to 2026-03-06) — weekly, recurring trader PercentageOfReturn metrics |
| [Dealing_dbo.Dealing_ClientDataTop50](Tables/Dealing_ClientDataTop50.md) | 8.0 | Done (Batch 14) ✅ active (to 2026-03-06) — weekly, 786,704 rows, top 50 CIDs by volume per instrument |
| Dealing_dbo.Dealing_ClientsCapitalAdequacy | 7.5/10 | Done (Batch 1) |
| [Dealing_dbo.Dealing_ClientsDataChange_3Months](Tables/Dealing_ClientsDataChange_3Months.md) | 8.0 | Done (Batch 14) ✅ active (to 2026-03-06) — weekly, 3-month volume/leverage delta |
| [Dealing_dbo.Dealing_ClientsDataChange_6Months](Tables/Dealing_ClientsDataChange_6Months.md) | 8.0 | Done (Batch 14) ✅ active (to 2026-03-06) — weekly, 6-month volume/leverage delta |
| [Dealing_dbo.Dealing_CloseOnly_Recon](Tables/Dealing_CloseOnly_Recon.md) | 7.8 | Done (Batch 5) |
| [Dealing_dbo.Dealing_Commission_Assurance](Tables/Dealing_Commission_Assurance.md) | 8.0 | Done (Batch 14) ✅ active (2026-03) — monthly MTD, 612 rows; Stocks Manual ratio ~0.98 expected |
| [Dealing_dbo.Dealing_Commission_Assurance_By_Position](Tables/Dealing_Commission_Assurance_By_Position.md) | 8.5 | Done (Batch 14) ✅ active — 90M+ rows, position-level detail |
| [Dealing_dbo.Dealing_CommoditiesIntraHour_Clients](Tables/Dealing_CommoditiesIntraHour_Clients.md) | 8.5 | Done (Batch 15) ✅ active, 11.9M rows, minute-grain commodity, HS=225 |
| [Dealing_dbo.Dealing_CommoditiesIntraHour_Etoro](Tables/Dealing_CommoditiesIntraHour_Etoro.md) | 7.0 | Done (Batch 15) ✅ active, 12.6M rows, LP-side companion, per-LP NOP by minute |
| [Dealing_dbo.Dealing_CopierAnalysis](Tables/Dealing_CopierAnalysis.md) | 8.0 | Done (Batch 15) ✅ active, 633M rows, HASH(ParentCID), dual-side copier+PI analytics |
| Dealing_dbo.Dealing_CopiersAnalysis_AdHoc | - | Skipped ⛔ ad-hoc analysis (2023 data, frozen Feb 2024, 75M rows) |
| Dealing_dbo.Dealing_CopiersAnalysis_AdHoc_2 | - | Skipped ⛔ ad-hoc (1 row — empty sequel) |
| Dealing_dbo.Dealing_CopyPortfolio_Allocation | 7.5/10 | Done (Batch 1) |
| [Dealing_dbo.Dealing_CryptoVolume](Tables/Dealing_CryptoVolume.md) | 3.0 | Done (Batch 15) ⚠️ STALE since 2024-04-02, no writer SP, 8.5M rows, COLUMNSTORE |
| [Dealing_dbo.Dealing_CryptoVolume_ByDirection](Tables/Dealing_CryptoVolume_ByDirection.md) | 7.5 | Done (Batch 15) ✅ active, 775K rows, daily crypto by direction, IsBuy inverted for closes |
| Dealing_dbo.Dealing_DailyAvgSpread | 7.5/10 | Done (Batch 1) |
| [Dealing_dbo.Dealing_DailySpread_ModeFrequency](Tables/Dealing_DailySpread_ModeFrequency.md) | 8.0 | Done (Batch 13) ✅ active |
| [Dealing_dbo.Dealing_DailySpreadsAggregated](Tables/Dealing_DailySpreadsAggregated.md) | 7.5 | Done (Batch 13) ⚠️ STALE Feb 2025 |
| [Dealing_dbo.Dealing_DailySpreadsAggregatedFX](Tables/Dealing_DailySpreadsAggregatedFX.md) | 7.0 | Done (Batch 13) ⚠️ STALE Apr 2024 |
| [Dealing_dbo.Dealing_DailyVariableSpread](Tables/Dealing_DailyVariableSpread.md) | 8.0 | Done (Batch 13) ✅ active |
| [Dealing_dbo.Dealing_DailyZeroPnL_Stocks](Tables/Dealing_DailyZeroPnL_Stocks.md) | 8.0 | Done (Batch 5) |
| [Dealing_dbo.Dealing_Daily_Latency](Tables/Dealing_Daily_Latency.md) | 8.5 | Done (Batch 13) ⚠️ STALE Jan 2025 |
| [Dealing_dbo.Dealing_Daily_Latency_AllPositions](Tables/Dealing_Daily_Latency_AllPositions.md) | 8.5 | Done (Batch 13) ⚠️ STALE Jan 2025, 295M rows |
| [Dealing_dbo.Dealing_Daily_Latency_AllPositions_StatusUpdateTime](Tables/Dealing_Daily_Latency_AllPositions_StatusUpdateTime.md) | 7.5 | Done (Batch 13) ⚠️ 3-month window Jul–Oct 2024 |
| [Dealing_dbo.Dealing_Daily_Latency_ClientOrder_WithDelay](Tables/Dealing_Daily_Latency_ClientOrder_WithDelay.md) | 8.5 | Done (Batch 13) ⚠️ STALE Jan 2025 |
| [Dealing_dbo.Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime](Tables/Dealing_Daily_Latency_ClientOrder_WithDelay_StatusUpdateTime.md) | 7.5 | Done (Batch 13) ⚠️ 3-month window |
| [Dealing_dbo.Dealing_Daily_Latency_Compensation](Tables/Dealing_Daily_Latency_Compensation.md) | 7.0 | Done (Batch 5) |
| [Dealing_dbo.Dealing_Daily_Latency_Compensation_StatusUpdateTime](Tables/Dealing_Daily_Latency_Compensation_StatusUpdateTime.md) | 8.0 | Done (Batch 13) ⚠️ 3-month window |
| [Dealing_dbo.Dealing_Daily_Latency_StatusUpdateTime](Tables/Dealing_Daily_Latency_StatusUpdateTime.md) | 7.5 | Done (Batch 13) ⚠️ 3-month window |
| [Dealing_dbo.Dealing_Daily_Slippage_Positions](Tables/Dealing_Daily_Slippage_Positions.md) | 7.0 | Done (Batch 5) |
| [Dealing_dbo.Dealing_Daily_Slippage_Positions_TriggerVSReceived](Tables/Dealing_Daily_Slippage_Positions_TriggerVSReceived.md) | 8.0 | Done (Batch 11) ⚠️ gap since Jan 2025 |
| [Dealing_dbo.Dealing_Daily_Slippage_Totals](Tables/Dealing_Daily_Slippage_Totals.md) | 8.5 | Done (Batch 11) ⚠️ gap since Jan 2025 |
| [Dealing_dbo.Dealing_Daily_Slippage_Totals_TriggerVSReceived](Tables/Dealing_Daily_Slippage_Totals_TriggerVSReceived.md) | 8.5 | Done (Batch 11) ⚠️ gap since Jan 2025 |
| Dealing_dbo.Dealing_DealingDashboard_Clients | 7.5/10 | Done (Batch 1) |
| Dealing_dbo.Dealing_DealingDashboard_Clients_20221019 | - | Skipped ⛔ archive snapshot (Oct 2022, 665M rows) |
| Dealing_dbo.Dealing_DealingDashboard_Clients_old | - | Skipped ⛔ archive backup (638M rows) |
| [Dealing_dbo.Dealing_Duco_ActivityRecon](Tables/Dealing_Duco_ActivityRecon.md) | 8.5 | Done (Batch 5) |
| [Dealing_dbo.Dealing_Duco_EODRecon](Tables/Dealing_Duco_EODRecon.md) | 8.5 | Done (Batch 5) |
| [Dealing_dbo.Dealing_ESMANetLoss](Tables/Dealing_ESMANetLoss.md) | 8.0 | Done (Batch 15) ✅ active, 118.6K rows, loss≥95%, DeltaLoss = stop-protection measure |
| Dealing_dbo.Dealing_Employee_Zero_StocksETFs | 7.5/10 | Done (Batch 1) |
| [Dealing_dbo.Dealing_Employees_Report](Tables/Dealing_Employees_Report.md) | 7.5 | Done (Batch 15) ✅ active, 231.4M rows, HASH(CID), AccountTypeID 7/13, CopyTarde+previos typos |
| [Dealing_dbo.Dealing_EquityFees](Tables/Dealing_EquityFees.md) | 8.0 | Done (Batch 15) ✅ active, 3.8M rows, JPM+GS LP fees vs CBH client NOP, Fianancing typo |
| [Dealing_dbo.Dealing_etoro_history_interestrate](Tables/Dealing_etoro_history_interestrate.md) | 7.5 | Done (Batch 19) ✅ Bronze SCD2 interest rate history; 13 cols |
| [Dealing_dbo.Dealing_Execution_Slippage](Tables/Dealing_Execution_Slippage.md) | 8.0 | Done (Batch 11) ⚠️ STALE since Oct 2024 |
| [Dealing_dbo.Dealing_Execution_Slippage_AssetType](Tables/Dealing_Execution_Slippage_AssetType.md) | 8.5 | Done (Batch 11) ⚠️ STALE since Oct 2024 |
| [Dealing_dbo.Dealing_Execution_Slippage_AssetType_RequestTime](Tables/Dealing_Execution_Slippage_AssetType_RequestTime.md) | 8.5 | Done (Batch 11) ⚠️ gap since Jan 2025 |
| [Dealing_dbo.Dealing_Execution_Slippage_RequestTime](Tables/Dealing_Execution_Slippage_RequestTime.md) | 8.5 | Done (Batch 11) ⚠️ gap since Jan 2025 |
| [Dealing_dbo.Dealing_Extented_Hours_NewCID](Tables/Dealing_Extented_Hours_NewCID.md) | 7.5 | Done (Batch 13) ⚠️ ~7 months stale |
| [Dealing_dbo.Dealing_Extented_Hours_Volume](Tables/Dealing_Extented_Hours_Volume.md) | 8.0 | Done (Batch 13) ⚠️ ~7 months stale, HASH dist |
| [Dealing_dbo.Dealing_FactSet_Daily](Tables/Dealing_FactSet_Daily.md) | 6.5 | Done (Batch 15) ⚠️ STALE since 2024-06-04, TRUNCATE pattern, 425.6K rows, FactSet PI portfolio |
| [Dealing_dbo.Dealing_FactSet_Management](Tables/Dealing_FactSet_Management.md) | 7.5 | Done (Batch 15) ⚠️ STALE since 2024-06-04, 4K rows, UPSERT control table for FactSet PI tracking |
| [Dealing_dbo.Dealing_FactSet_Management_Export](Tables/Dealing_FactSet_Management_Export.md) | 7.5 | Done (Batch 19) ✅ Gold layer staging for FactSet PI export |
| [Dealing_dbo.Dealing_FactSet_NewPIs_History](Tables/Dealing_FactSet_NewPIs_History.md) | 6.5 | Done (Batch 18) ⚠️ STALE since 2024-06-04, 4.8M rows, TRUNCATE/INSERT FactSet new-PI snapshot, HistorySendFlag=1 gate |
| [Dealing_dbo.Dealing_FailReasons](Tables/Dealing_FailReasons.md) | 9.0 | Done (Batch 11) ✅ active |
| [Dealing_dbo.Dealing_FailReasons_PIs](Tables/Dealing_FailReasons_PIs.md) | 8.5 | Done (Batch 12) ✅ active |
| Dealing_dbo.Dealing_FailReasons_Top20 | - | Skipped ⛔ subset artifact of Dealing_FailReasons (3.8K rows) |
| Dealing_dbo.Dealing_FailReasons_Top20_PIs | - | Skipped ⛔ subset artifact (401 rows) |
| Dealing_dbo.Dealing_Fails_P | - | Skipped ⛔ empty/abandoned (1 row) |
| [Dealing_dbo.Dealing_Fails_PI](Tables/Dealing_Fails_PI.md) | 8.0 | Done (Batch 12) ✅ active, 3.97B rows |
| Dealing_dbo.Dealing_Fails_PI1 | - | Skipped ⛔ deprecated variant of Dealing_Fails_PI (3.2K rows) |
| [Dealing_dbo.Dealing_Fails_PI_ErrorCodes](Tables/Dealing_Fails_PI_ErrorCodes.md) | 7.5 | Done (Batch 12) ✅ static lookup (234 rows) |
| Dealing_dbo.Dealing_Failures | 7.2/10 | Done (Batch 3) |
| Dealing_dbo.Dealing_Failures_Rate | 7.0/10 | Done (Batch 3) |
| [Dealing_dbo.Dealing_GSReconEODHolding](Tables/Dealing_GSReconEODHolding.md) | 7.5 | Done (Batch 6) |
| [Dealing_dbo.Dealing_GSReconTrades](Tables/Dealing_GSReconTrades.md) | 7.8 | Done (Batch 6) |
| Dealing_dbo.Dealing_GS_Credit_Risk | 7.5/10 | Done (Batch 2) |
| Dealing_dbo.Dealing_GS_Dividends_Recon | - | Skipped ⛔ empty/never-populated (1 row) |
| Dealing_dbo.Dealing_HedgeCost | 7.8/10 | Done (Batch 4) |
| [Dealing_dbo.Dealing_Holdings_RealStocks](Tables/Dealing_Holdings_RealStocks.md) | 8.0 | Done (Batch 17) ✅ active (to 2026-03-10) — 12.2M rows; BNY Mellon custodian report; Real HS (3,9,102,128,112,125,126) vs CFD HS (2,101,129) |
| [Dealing_dbo.Dealing_IBRecon_EODHoldings](Tables/Dealing_IBRecon_EODHoldings.md) | 7.8 | Done (Batch 6) |
| [Dealing_dbo.Dealing_IBRecon_EODHoldings_CFD](Tables/Dealing_IBRecon_EODHoldings_CFD.md) | 7.0 | Done (Batch 6) |
| [Dealing_dbo.Dealing_IBRecon_Trades](Tables/Dealing_IBRecon_Trades.md) | 6.5 | Done (Batch 6) ⚠️ stale |
| [Dealing_dbo.Dealing_IBRecon_Trades_CFD](Tables/Dealing_IBRecon_Trades_CFD.md) | 5.5 | Done (Batch 6) ⚠️ abandoned |
| [Dealing_dbo.Dealing_IGReconEODHolding](Tables/Dealing_IGReconEODHolding.md) | 7.8 | Done (Batch 9) |
| [Dealing_dbo.Dealing_IGReconTrades](Tables/Dealing_IGReconTrades.md) | 7.8 | Done (Batch 9) |
| Dealing_dbo.Dealing_IndiciesIntraHour_Clients | 7.5/10 | Done (Batch 2) |
| Dealing_dbo.Dealing_IndiciesIntraHour_Etoro | 7.5/10 | Done (Batch 2) |
| Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group | 7.5/10 | Done (Batch 3) |
| [Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee](Tables/Dealing_Islamic_Daily_Administrative_Fee.md) | 8.5 | Done (Batch 16) ✅ active (to 2026-03-10) — 17.6M rows, Fee_Type_ID=1, 22:00 UTC cutoff, triple-day logic, Germany Crypto exclusion |
| [Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment](Tables/Dealing_Islamic_Daily_Spot_Price_Adjustment.md) | 8.5 | Done (Batch 16) ✅ active (to 2026-03-09) — 392K rows, Fee_Type_ID=2, 7 futures instruments, Fivetran feed, fee can be positive |
| Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment_Email | - | Skipped ⛔ email staging buffer (1K rows) |
| Dealing_dbo.Dealing_Islamic_Instruments_Groups | 6.5/10 | Done (Batch 3) |
| Dealing_dbo.Dealing_Islamic_Units_Per_Contract | 6.5/10 | Done (Batch 3) |
| [Dealing_dbo.Dealing_JPMReconEODHolding](Tables/Dealing_JPMReconEODHolding.md) | 7.8 | Done (Batch 9) |
| [Dealing_dbo.Dealing_JPMReconTrades](Tables/Dealing_JPMReconTrades.md) | 7.8 | Done (Batch 9) |
| Dealing_dbo.Dealing_JP_Credit_Risk | 7.5/10 | Done (Batch 2) |
| Dealing_dbo.Dealing_LP_StocksNOP | 7.5/10 | Done (Batch 1) |
| [Dealing_dbo.Dealing_Latency_SuspiciousCIDs](Tables/Dealing_Latency_SuspiciousCIDs.md) | 8.5 | Done (Batch 13) ✅ active ⚠️ NULL sentinel rows |
| Dealing_dbo.Dealing_Latency_SuspiciousCIDs_Email | - | Skipped ⛔ email staging buffer (1K rows) |
| [Dealing_dbo.Dealing_MAXLeverageByNOP](Tables/Dealing_MAXLeverageByNOP.md) | 8.5 | Done (Batch 14) ✅ active (to 2026-03-11) — 6.3M rows; JSON tiers from External_SettingsDB |
| [Dealing_dbo.Dealing_MCS_Model_Report](Tables/Dealing_MCS_Model_Report.md) | 8.0 | Done (Batch 18) ✅ active (to 2026-03-10) — 1.1B rows; HASH(PositionID); Real Stocks+ETF only; opened+closed positions; Volume/Click attribution |
| Dealing_dbo.Dealing_MIMO_Zero | 8.0/10 | Done (Batch 2) |
| Dealing_dbo.Dealing_MIMO_Zero_Old_20230626 | - | Skipped ⛔ archive backup of Dealing_MIMO_Zero (Jun 2023, 92K rows) |
| Dealing_dbo.Dealing_ManipulationReport_RealStocks | 7.5/10 | Done (Batch 4) |
| Dealing_dbo.Dealing_ManipulationReport_RealStocks_CID | 7.8/10 | Done (Batch 4) |
| [Dealing_dbo.Dealing_ManualPositionClose](Tables/Dealing_ManualPositionClose.md) | 8.5 | Done (Batch 14) ✅ active (to 2026-03-10) — crisis-flow positions; tree structure via MirrorID |
| [Dealing_dbo.Dealing_Manual_Exec](Tables/Dealing_Manual_Exec.md) | 8.0 | Done (Batch 14) ✅ ⚠️ STALE since 2024-11-02 — 3 exec types; USD FX conversion |
| [Dealing_dbo.Dealing_Manual_Exec_Trade](Tables/Dealing_Manual_Exec_Trade.md) | 8.5 | Done (Batch 14) ✅ active (to 2026-03-10) — signed units (±1×IsBuy) |
| [Dealing_dbo.Dealing_Manual_Exec_Trade_Summary](Tables/Dealing_Manual_Exec_Trade_Summary.md) | 8.5 | Done (Batch 14) ✅ active — NOP_Start/End from netting |
| [Dealing_dbo.Dealing_Marex_Recon_EODHoldings](Tables/Dealing_Marex_Recon_EODHoldings.md) | 7.3 | Done (Batch 9) |
| [Dealing_dbo.Dealing_Marex_Recon_EODHoldings_Futures](Tables/Dealing_Marex_Recon_EODHoldings_Futures.md) | 7.0 | Done (Batch 9) |
| [Dealing_dbo.Dealing_Marex_Recon_Trades](Tables/Dealing_Marex_Recon_Trades.md) | 7.3 | Done (Batch 9) |
| [Dealing_dbo.Dealing_Marex_Recon_Trades_Futures](Tables/Dealing_Marex_Recon_Trades_Futures.md) | 7.0 | Done (Batch 9) |
| Dealing_dbo.Dealing_MarketMakerAllTrade | 7.5/10 | Done (Batch 3) |
| Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX | 5.0/10 | Done (Batch 3) — HOLD/Deprecated |
| Dealing_dbo.HOLD_Dealing_MarketMakerAllTradeEtoroX | - | Skipped ⛔ HOLD backup of MarketMakerAllTradeEtoroX (pre-deprecation backup) |
| Dealing_dbo.Dealing_MarketMakerBoundaries_CFD | 7.2/10 | Done (Batch 3) |
| Dealing_dbo.Dealing_MarketMakerBoundaries_CFD  | - | Skipped ⛔ duplicate entry (trailing space — same as documented table above) |
| Dealing_dbo.Dealing_MarketMakerBoundaries_Real | 7.2/10 | Done (Batch 3) |
| [Dealing_dbo.Dealing_Market_Manipulation_OutstandingsharesHigherthan005](Tables/Dealing_Market_Manipulation_OutstandingsharesHigherthan005.md) | 7.5 | Done (Batch 18) ✅ active to 2026-03-10, 2.2K rows, dual-threshold surveillance: eToro LP flow >0.5% + CID >0.25% outstanding shares |
| Dealing_dbo.Dealing_Market_Manipulation_OutstandingsharesHigherthan005_Email | - | Skipped ⛔ email staging buffer (1K rows) |
| Dealing_dbo.Dealing_Market_Manipulation_Report | 7.6/10 | Done (Batch 4) |
| Dealing_dbo.Dealing_Market_Manipulation_Report_FCA | 7.2/10 | Done (Batch 4) |
| [Dealing_dbo.Dealing_MaxNOPLimitSettings](Tables/Dealing_MaxNOPLimitSettings.md) | 8.0 | Done (Batch 14) ✅ active (to 2026-03-10) — 3M rows; EXW_Settings schema; CID-level overrides |
| [Dealing_dbo.Dealing_MaxPositionUnits](Tables/Dealing_MaxPositionUnits.md) | 8.0 | Done (Batch 14) ✅ active (to 2026-03-10) — 5.7M rows; DWH_staging.ProviderToInstrument |
| Dealing_dbo.Dealing_Max_NOP | 7.0/10 | Done (Batch 2) |
| [Dealing_dbo.Dealing_Monitoring_ADV](Tables/Dealing_Monitoring_ADV.md) | 8.5 | Done (Batch 14) ✅ active (to 2026-03-10) — 29M rows, Real Stocks+ETFs; CopyFromLake ExecutionLog |
| [Dealing_dbo.Dealing_Monitoring_ADV_MoreThanPercent](Tables/Dealing_Monitoring_ADV_MoreThanPercent.md) | 8.0 | Done (Batch 14) ✅ active — per-CID PercentfromADV threshold alerts |
| Dealing_dbo.Dealing_NOPDistribution | 7.5/10 | Done (Batch 2) |
| Dealing_dbo.Dealing_NOP_LPandClients | 7.8/10 | Done (Batch 1) |
| [Dealing_dbo.Dealing_NOP_Report](Tables/Dealing_NOP_Report.md) | 8.0 | Done (Batch 14) ✅ active (to 2026-03-09) — ~54K rows; 10 LPs; skips Saturday |
| Dealing_dbo.Dealing_NumberofPositionsOpened_Agg | 7.5/10 | Done (Batch 2) |
| [Dealing_dbo.Dealing_OccurredAtProvider_Latency_Instrument](Tables/Dealing_OccurredAtProvider_Latency_Instrument.md) | 8.0 | Done (Batch 13) ⚠️ STALE Jan 2025 |
| [Dealing_dbo.Dealing_OccurredAtProvider_Latency_LiquidityAccountID](Tables/Dealing_OccurredAtProvider_Latency_LiquidityAccountID.md) | 7.5 | Done (Batch 13) ⚠️ STALE Jan 2025 |
| [Dealing_dbo.Dealing_OccurredAtProvider_Latency_PCSID](Tables/Dealing_OccurredAtProvider_Latency_PCSID.md) | 7.0 | Done (Batch 13) ⚠️ STALE Jan 2025 |
| Dealing_dbo.Dealing_OfferedInstruments | 7.5/10 | Done (Batch 2) |
| Dealing_dbo.Dealing_PDT | 7.0/10 | Done (Batch 3) |
| [Dealing_dbo.Dealing_PlayerLevel_Data](Tables/Dealing_PlayerLevel_Data.md) | 8.5 | Done (Batch 12) ✅ active |
| [Dealing_dbo.Dealing_PlayerLevel_Data_PIs](Tables/Dealing_PlayerLevel_Data_PIs.md) | 8.5 | Done (Batch 12) ✅ active — Diamond/Platinum Plus only |
| [Dealing_dbo.Dealing_PlayerLevel_Fails](Tables/Dealing_PlayerLevel_Fails.md) | 9.0 | Done (Batch 12) ✅ active |
| [Dealing_dbo.Dealing_PlayerLevel_Fails_PIs](Tables/Dealing_PlayerLevel_Fails_PIs.md) | 7.5 | Done (Batch 12) ✅ active — sparse |
| [Dealing_dbo.Dealing_PreviouslyIdentifiedAbusers](Tables/Dealing_PreviouslyIdentifiedAbusers.md) | 8.5 | Done (Batch 14) ✅ active (to 2026-03-10) ⚠️ SENSITIVE — ~120 hardcoded name pairs; NULL sentinels |
| Dealing_dbo.Dealing_PreviouslyIdentifiedAbusers_Email | - | Skipped ⛔ email staging buffer (1K rows) |
| [Dealing_dbo.Dealing_PriceLocks](Tables/Dealing_PriceLocks.md) | 7.5 | Done (Batch 18) ✅ active to 2026-03-10, 6.9M rows, SpreadLock/VolatilityLock events; TotalInFist15Min DDL typo |
| [Dealing_dbo.Dealing_Regime_Flags](Tables/Dealing_Regime_Flags.md) | 6.0 | Done (Batch 18) ⚠️ STALE since 2025-01-19, 17.9M rows, 4-measure Z-score/percentile history, full DELETE+INSERT, NOT in OpsDB |
| [Dealing_dbo.Dealing_RiskMatrix_V2](Tables/Dealing_RiskMatrix_V2.md) | 4.0 | Done (Batch 18) ⚠️ STALE — single snapshot 2024-06-02; 87.6K rows; HEAP; no writer SP; 26-scenario NOP stress test |
| Dealing_dbo.Dealing_RolloverCommissionSplit | 8.0/10 | Done (Batch 2) |
| [Dealing_dbo.Dealing_Rollover_Assurance](Tables/Dealing_Rollover_Assurance.md) | 8.5 | Done (Batch 16) ✅ active (to 2026-03-10) — 46.4M rows, HASH(CID+InstrID), rollover discrepancy audit; 4 breakdown categories |
| [Dealing_dbo.Dealing_SAXORecon_EODHoldings](Tables/Dealing_SAXORecon_EODHoldings.md) | 7.5 | Done (Batch 17) ✅ active (to 2026-03-10) — 1.86M rows; SP_SAXO_Recon; 3-way recon SAXO vs eToro vs Clients; 29 cols; [Reality-Supposed] primary metric |
| [Dealing_dbo.Dealing_SAXORecon_Hedging](Tables/Dealing_SAXORecon_Hedging.md) | 4.5 | Done (Batch 17) ⛔ ORPHANED — no writer SP; stale since 2023-05-17; 42.7K rows; superceded by EODHoldings |
| [Dealing_dbo.Dealing_SAXORecon_Trades](Tables/Dealing_SAXORecon_Trades.md) | 7.5 | Done (Batch 17) ✅ active (to 2026-03-10) — 1.0M rows; SP_SAXO_Recon; trade-flow recon; [SAXO-eToro_AmountUSD] primary metric |
| [Dealing_dbo.Dealing_SaxoRecon_FXnCommed_EODHoldings](Tables/Dealing_SaxoRecon_FXnCommed_EODHoldings.md) | 7.0 | Done (Batch 17) ✅ active (to 2026-03-10) — 195.7K rows; SP_SAXO_Recon_FXnCommed; FX/Commed accounts; data from Apr 2024 |
| [Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades](Tables/Dealing_SaxoRecon_FXnCommed_Trades.md) | 4.0 | Done (Batch 17) ⛔ ORPHANED — no writer SP; stale since 2023-12-05; 4.2K rows |
| [Dealing_dbo.Dealing_SelfCopyingPI](Tables/Dealing_SelfCopyingPI.md) | 7.5 | Done (Batch 14) ✅ ⛔ DECOMMISSIONED — HOLD_20240416 prefix; last data 2023-09-03 |
| Dealing_dbo.HOLD_20240416_Dealing_SelfCopyingPI | - | Skipped ⛔ HOLD backup of Dealing_SelfCopyingPI (archived 2024-04-16) |
| [Dealing_dbo.Dealing_SpreadsMST](Tables/Dealing_SpreadsMST.md) | 8.0 | Done (Batch 17) ✅ active (to 2026-03-10) — 8.2M rows; SP_SpreadsMST; bid/ask vs MST threshold audit; 'PrecentageSpread' typo in source Dictionary |
| [Dealing_dbo.Dealing_Staking_Club](Tables/Dealing_Staking_Club.md) | 8.0/10 | Done (Batch 10) |
| [Dealing_dbo.Dealing_Staking_Club_US](Tables/Dealing_Staking_Club_US.md) | 8.0/10 | Done (Batch 10) |
| [Dealing_dbo.Dealing_Staking_Compensation](Tables/Dealing_Staking_Compensation.md) | 8.5/10 | Done (Batch 10) |
| [Dealing_dbo.Dealing_Staking_Compensation_US](Tables/Dealing_Staking_Compensation_US.md) | 8.0/10 | Done (Batch 10) |
| [Dealing_dbo.Dealing_Staking_DailyPool](Tables/Dealing_Staking_DailyPool.md) | 8.5/10 | Done (Batch 10) |
| [Dealing_dbo.Dealing_Staking_DailyPool_US](Tables/Dealing_Staking_DailyPool_US.md) | 8.0/10 | Done (Batch 10) |
| Dealing_dbo.Dealing_Staking_Emails | 6.8/10 | Done (Batch 3) |
| [Dealing_dbo.Dealing_Staking_Emails_New](Tables/Dealing_Staking_Emails_New.md) | 8.5/10 | Done (Batch 10) |
| [Dealing_dbo.Dealing_Staking_Emails_US](Tables/Dealing_Staking_Emails_US.md) | 8.0/10 | Done (Batch 10) |
| [Dealing_dbo.Dealing_Staking_OptedOut](Tables/Dealing_Staking_OptedOut.md) | 8.5/10 | Done (Batch 10) |
| [Dealing_dbo.Dealing_Staking_OptedOut_PerCID](Tables/Dealing_Staking_OptedOut_PerCID.md) | 8.5/10 | Done (Batch 10) |
| [Dealing_dbo.Dealing_Staking_OptedOut_PerCID_US](Tables/Dealing_Staking_OptedOut_PerCID_US.md) | 8.0 | Done (Batch 16) ✅ active, 10.1M rows, 4 instruments; Country = US state name (legacy naming quirk) |
| [Dealing_dbo.Dealing_Staking_OptedOut_US](Tables/Dealing_Staking_OptedOut_US.md) | 8.0 | Done (Batch 16) ✅ active; daily aggregate, Units_AvailableForStaking = OptedInUnits × LiquidityBuffer |
| Dealing_dbo.Dealing_Staking_Parameters | 6.5/10 | Done (Batch 3) |
| [Dealing_dbo.Dealing_Staking_Parameters_US](Tables/Dealing_Staking_Parameters_US.md) | 8.5 | Done (Batch 16) ✅ 4-row config (ADA/ETH/SOL/SUI); ETH IntroDays=60; SUI Distribution_StartDate=2026-04-01 (future) |
| [Dealing_dbo.Dealing_Staking_Position](Tables/Dealing_Staking_Position.md) | 8.0 | Done (Batch 12) ✅ active, 159.5M rows ⚠️ malformed StakingMonthID |
| [Dealing_dbo.Dealing_Staking_Position_US](Tables/Dealing_Staking_Position_US.md) | 8.5 | Done (Batch 16) ✅ active, 592K rows, 3 instruments (ADA/ETH/SOL); IsPI/IsOptedIn_ETH always NULL |
| [Dealing_dbo.Dealing_Staking_Results](Tables/Dealing_Staking_Results.md) | 8.5 | Done (Batch 12) ✅ active, 20.4M rows ⚠️ malformed IDs |
| [Dealing_dbo.Dealing_Staking_Results_US](Tables/Dealing_Staking_Results_US.md) | 8.0 | Done (Batch 16) ✅ active, 122K rows, CID-level rewards, $1 minimum threshold, 6 ClubCategory buckets |
| Dealing_dbo.Dealing_Staking_Results_exported_FIXED | - | Skipped ⛔ one-off export fix artifact (1K rows) |
| [Dealing_dbo.Dealing_Staking_Summary](Tables/Dealing_Staking_Summary.md) | 8.5 | Done (Batch 12) ✅ active, 158 rows ⚠️ malformed ID |
| [Dealing_dbo.Dealing_Staking_Summary_US](Tables/Dealing_Staking_Summary_US.md) | 8.0 | Done (Batch 16) ✅ active, 14 rows (3 instruments × ~5 months), EtoroYield formula, MonthlyPool, IntroDays |
| [Dealing_dbo.Dealing_Staking_WelcomeEmail_Temp](Tables/Dealing_Staking_WelcomeEmail_Temp.md) | 5.5 | Done (Batch 5) |
| [Dealing_dbo.Dealing_Supposed_LPFees](Tables/Dealing_Supposed_LPFees.md) | 3.5 | Done (Batch 18) ⛔ ORPHANED — no writer SP; stale since 2023-09-11, 603K rows, REPLICATE, theoretical LP fee estimates |
| [Dealing_dbo.Dealing_SuspiciousActivityTrading_24H](Tables/Dealing_SuspiciousActivityTrading_24H.md) | 9.0 | Done (Batch 14) ✅ active (to 2026-03-10) — 3-min window, ≥5 trades AND >$3K profit |
| Dealing_dbo.Dealing_SuspiciousActivityTrading_24H_Email | - | Skipped ⛔ email staging buffer (1K rows) |
| [Dealing_dbo.Dealing_US_DailyTradeBlotter](Tables/Dealing_US_DailyTradeBlotter.md) | 6.5 | Done (Batch 17) ⚠️ STALE since 2025-01-13 — 408.7M rows; SP_USTradeReports; FINRA daily blotter; Filled-only; HASH(CID); PII ([Client Name]) |
| [Dealing_dbo.Dealing_US_DailyTradeBlotter_DailyCSV](Tables/Dealing_US_DailyTradeBlotter_DailyCSV.md) | 6.5 | Done (Batch 17) ⚠️ STALE since 2025-01-13 — 1.16M rows; TRUNCATE pattern (single day); includes Partial fills; CSV export format |
| [Dealing_dbo.Dealing_US_OriginalEntryTradeTicket](Tables/Dealing_US_OriginalEntryTradeTicket.md) | 6.5 | Done (Batch 17) ⚠️ STALE since 2025-01-13 — 587.6M rows; SP_USTradeReports; FINRA original-entry ticket; HASH(CID); PII ([Client Name]); 8 hardcoded constants |
| [Dealing_dbo.Dealing_US_Stocks_SmartPortfolio](Tables/Dealing_US_Stocks_SmartPortfolio.md) | 7.5 | Done (Batch 17) ✅ active (to 2026-03-10) — 252.6K rows; SP_US_Stocks_SmartPortfolio; SmartPortfolio (AccountTypeID=9) NOP concentration; >5% triggers email alert |
| [Dealing_dbo.Dealing_Unrealized_Open_CryptoRebate](Tables/Dealing_Unrealized_Open_CryptoRebate.md) | 8.0 | Done (Batch 18) ✅ active to 2026-02-28, 63.5K rows, monthly Diamond crypto rebate; tiered 0.15/0.25/0.50%; UPdatedate DDL typo |
| [Dealing_dbo.Dealing_VisionRecon_EODHoldings](Tables/Dealing_VisionRecon_EODHoldings.md) | 7.5 | Done (Batch 9) |
| [Dealing_dbo.Dealing_VisionRecon_Trades](Tables/Dealing_VisionRecon_Trades.md) | 7.5 | Done (Batch 9) |
| [Dealing_dbo.Dealing_WeeklyCMT_Fees](Tables/Dealing_WeeklyCMT_Fees.md) | 4.5 | Done (Batch 18) ⛔ STALE since 2023-04-09, 54.2K rows, Sunday-only; legacy leveraged crypto pre-2021; program discontinued |
| Dealing_dbo.Dealing_overnight_fees | 6.0/10 | Done (Batch 3) |
| [Dealing_dbo.External_Fivetran_dealing_overnight_fees](Tables/External_Fivetran_dealing_overnight_fees.md) | 8.0 | Done (Batch 19) ✅ active, Fivetran Bloomberg futures prices |
| [Dealing_dbo.External_Gold_Dealing_Marex_Trader_OrderID](Tables/External_Gold_Dealing_Marex_Trader_OrderID.md) | 8.2 | Done (Batch 19) ✅ active, Gold layer Trader-OrderID mapping for Marex recon |
| [Dealing_dbo.StocksOverrideRateLog](Tables/StocksOverrideRateLog.md) | 8.0 | Done (Batch 18) ✅ active to 2026-03-10, 6.5M rows, daily interest rate override snapshot; NULL=Active; Total_Buy/Sell = Interest+Markup |

## Views (6)

| Object | Quality | Status |
|--------|---------|--------|
| [Dealing_dbo.V_Dealing_CEPDailyAudit_CP_Last180Days](Views/V_Dealing_CEPDailyAudit_CP_Last180Days.md) | 7.0 | Done (Batch 20) ✅ 180-day filter over CEPDailyAudit_CP |
| [Dealing_dbo.V_Dealing_CEPDailyAudit_Conditions_Last180Days](Views/V_Dealing_CEPDailyAudit_Conditions_Last180Days.md) | 7.0 | Done (Batch 20) ✅ 180-day filter over CEPDailyAudit_Conditions |
| [Dealing_dbo.V_Dealing_CEPDailyAudit_Rules_Last180Days](Views/V_Dealing_CEPDailyAudit_Rules_Last180Days.md) | 7.0 | Done (Batch 20) ✅ 180-day filter over CEPDailyAudit_Rules |
| [Dealing_dbo.V_Dealing_DealingDashboard_Clients](Views/V_Dealing_DealingDashboard_Clients.md) | 7.5 | Done (Batch 20) ✅ NOLOCK + DateID>20211231 filter; consumed by SP_Regime_Flags |
| [Dealing_dbo.V_Dealing_Duco_EODRecon](Views/V_Dealing_Duco_EODRecon.md) | 7.5 | Done (Batch 20) ✅ DISTINCT + BuyOrSell alias; Duco recon platform entry point |
| [Dealing_dbo.V_RequestViewForBestExecution](Views/V_RequestViewForBestExecution.md) | 7.5 | Done (Batch 20) ✅ UNION HedgeServer + EMS; MiFID Best Execution regulatory view |
