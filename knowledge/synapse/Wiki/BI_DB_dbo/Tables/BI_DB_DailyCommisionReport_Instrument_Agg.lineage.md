# BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg — Column Lineage

**Generated**: 2026-04-22 | **Writer SP**: SP_DailyCommisionReport | **Batch**: 21

## Summary

Daily DELETE WHERE DateID=@DateID + INSERT incremental instrument-level aggregation of BI_DB_DailyCommisionReport. Grain: InstrumentID × Date × Region × Club × FTD_Year × PlayerStatus × AccountStatus × AccountType × Label × position-type flags (IsBuy, IsLeverage, IsLeverageMoreThen20, IsAirDrop, SettlementTypeID, IsSettled, IsMarginTrade) × customer flags (IsValidCustomer, IsCreditReportValidCB, Regulation, IsDLTUser, IsEtoroTradingCID, IsGlenEagleAccount, eToroTradingGroupUser, US_State) — NO individual CID. All commission and volume metrics are SUM() aggregations from the parent table. Dimension columns are GROUP BY pass-throughs. Written by the same SP execution immediately after the parent BI_DB_DailyCommisionReport insert. UC target: general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg (Append strategy).

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | InstrumentID | BI_DB_dbo.BI_DB_DailyCommisionReport | InstrumentID | GROUP BY pass-through — instrument integer key. | Tier 2 — SP_DailyCommisionReport |
| 2 | Instrument | BI_DB_dbo.BI_DB_DailyCommisionReport | Instrument | GROUP BY pass-through — instrument name (e.g., AAPL, BTC/USD). | Tier 2 — SP_DailyCommisionReport |
| 3 | InstrumentTypeID | BI_DB_dbo.BI_DB_DailyCommisionReport | InstrumentTypeID | GROUP BY pass-through — instrument type integer key. | Tier 2 — SP_DailyCommisionReport |
| 4 | InstrumentType | BI_DB_dbo.BI_DB_DailyCommisionReport | InstrumentType | GROUP BY pass-through — instrument type label (Currencies, Commodities, Indices, Stocks, Crypto Currencies, ETF). | Tier 2 — SP_DailyCommisionReport |
| 5 | Region | BI_DB_dbo.BI_DB_DailyCommisionReport | Region | GROUP BY pass-through — marketing region label. | Tier 2 — SP_DailyCommisionReport |
| 6 | Club | BI_DB_dbo.BI_DB_DailyCommisionReport | Club | GROUP BY pass-through — customer club tier (Diamond, Platinum Plus, Platinum, Gold, Silver, Bronze, etc.). | Tier 2 — SP_DailyCommisionReport |
| 7 | FullDate | BI_DB_dbo.BI_DB_DailyCommisionReport | FullDate | GROUP BY pass-through — reporting date. | Tier 2 — SP_DailyCommisionReport |
| 8 | DateID | BI_DB_dbo.BI_DB_DailyCommisionReport | DateID | GROUP BY pass-through — YYYYMMDD integer. DELETE key for incremental reload. | Tier 2 — SP_DailyCommisionReport |
| 9 | FTD Year | BI_DB_dbo.BI_DB_DailyCommisionReport | FirstDepositDate | YEAR(FirstDepositDate) — customer cohort year. Unique to Instrument_Agg; not present in other satellite tables. | Tier 2 — SP_DailyCommisionReport |
| 10 | VolumeOnOpen | BI_DB_dbo.BI_DB_DailyCommisionReport | VolumeOnOpen | SUM(ISNULL(VolumeOnOpen,0)) — aggregated USD trading volume for positions opened on DateID. | Tier 2 — SP_DailyCommisionReport |
| 11 | VolumeOnClose | BI_DB_dbo.BI_DB_DailyCommisionReport | VolumeOnClose | SUM(ISNULL(VolumeOnClose,0)) — aggregated USD trading volume for positions closed on DateID. | Tier 2 — SP_DailyCommisionReport |
| 12 | RollOverFee | BI_DB_dbo.BI_DB_DailyCommisionReport | RollOverFee | SUM(ISNULL(RollOverFee,0)) — aggregated overnight rollover/carry fee. | Tier 2 — SP_DailyCommisionReport |
| 13 | FullCommissions | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions | SUM(ISNULL(FullCommissions,0)) — gross full commission (MIFID regulatory reporting). | Tier 2 — SP_DailyCommisionReport |
| 14 | Commissions | BI_DB_dbo.BI_DB_DailyCommisionReport | Commissions | SUM(ISNULL(Commissions,0)) — net eToro commission (net-to-company figure). | Tier 2 — SP_DailyCommisionReport |
| 15 | UpdateDate | — | — | GETDATE() at ETL execution time. | Tier 2 — SP_DailyCommisionReport |
| 16 | Label | BI_DB_dbo.BI_DB_DailyCommisionReport | Label | GROUP BY pass-through — customer segment label (e.g., 'eToro', 'Proprietary'). | Tier 2 — SP_DailyCommisionReport |
| 17 | PlayerStatusID | BI_DB_dbo.BI_DB_DailyCommisionReport | PlayerStatusID | GROUP BY pass-through — integer player status key. | Tier 2 — SP_DailyCommisionReport |
| 18 | PlayerStatus | BI_DB_dbo.BI_DB_DailyCommisionReport | PlayerStatus | GROUP BY pass-through — player status name (Normal, Blocked, etc.). | Tier 2 — SP_DailyCommisionReport |
| 19 | AccountStatusID | BI_DB_dbo.BI_DB_DailyCommisionReport | AccountStatusID | GROUP BY pass-through — integer account status key. | Tier 2 — SP_DailyCommisionReport |
| 20 | AccountStatusName | BI_DB_dbo.BI_DB_DailyCommisionReport | AccountStatusName | GROUP BY pass-through — account status label. | Tier 2 — SP_DailyCommisionReport |
| 21 | AccountTypeID | BI_DB_dbo.BI_DB_DailyCommisionReport | AccountTypeID | GROUP BY pass-through — integer account type key (1=Personal, 2=Corporate, 14=SMSF, etc.). | Tier 2 — SP_DailyCommisionReport |
| 22 | AccountType | BI_DB_dbo.BI_DB_DailyCommisionReport | AccountType | GROUP BY pass-through — account type name. | Tier 2 — SP_DailyCommisionReport |
| 23 | IsOutlier | — | — | **Always NULL** — legacy column inherited from parent. Grouping key has no effect. | Tier 4 — Legacy/Deprecated |
| 24 | Transition | — | — | **Always NULL** — legacy column inherited from parent. | Tier 4 — Legacy/Deprecated |
| 25 | IsGermanBaFIN | — | — | **Always NULL** — legacy column inherited from parent. | Tier 4 — Legacy/Deprecated |
| 26 | IsEtoroTradingCID | BI_DB_dbo.BI_DB_DailyCommisionReport | IsEtoroTradingCID | GROUP BY pass-through — flag for internal eToro housekeeping accounts. | Tier 2 — SP_DailyCommisionReport |
| 27 | IsGlenEagleAccount | BI_DB_dbo.BI_DB_DailyCommisionReport | IsGlenEagleAccount | GROUP BY pass-through — flag for Glen Eagle Securities subsidiary accounts. | Tier 2 — SP_DailyCommisionReport |
| 28 | eToroTradingGroupUser | BI_DB_dbo.BI_DB_DailyCommisionReport | eToroTradingGroupUser | GROUP BY pass-through — eToro trading group identifier string. | Tier 2 — SP_DailyCommisionReport |
| 29 | RegulationIDPrev | — | — | **Always NULL** — legacy column inherited from parent. | Tier 4 — Legacy/Deprecated |
| 30 | RegulationPrev | — | — | **Always NULL** — legacy column inherited from parent. | Tier 4 — Legacy/Deprecated |
| 31 | IsCreditReportValidCBPrev | — | — | **Always NULL** — legacy column inherited from parent. | Tier 4 — Legacy/Deprecated |
| 32 | US_State | BI_DB_dbo.BI_DB_DailyCommisionReport | US_State | GROUP BY pass-through — US state/province short name. NULL for non-US customers. | Tier 2 — SP_DailyCommisionReport |
| 33 | CommissionOnClose | BI_DB_dbo.BI_DB_DailyCommisionReport | CommissionOnClose | SUM(CommissionOnClose) — aggregated raw commission on closed positions. | Tier 2 — SP_DailyCommisionReport |
| 34 | CommissionByUnitsAtClose | — | — | **Always NULL** — SUM of a NULL column in parent. Legacy decomposition. | Tier 4 — Legacy/Deprecated |
| 35 | UnrealizedCommissionNew | — | — | **Always NULL** — SUM of a NULL column in parent. Legacy decomposition. | Tier 4 — Legacy/Deprecated |
| 36 | UnrealizedCommissionOldClosing | — | — | **Always NULL** — SUM of a NULL column in parent. Legacy decomposition. | Tier 4 — Legacy/Deprecated |
| 37 | RealizedCommission | — | — | **Always NULL** — SUM of a NULL column in parent. Legacy decomposition. | Tier 4 — Legacy/Deprecated |
| 38 | UnrealizedCommissionChange | BI_DB_dbo.BI_DB_DailyCommisionReport | UnrealizedCommissionChange | SUM(UnrealizedCommissionChange) — aggregated daily change in unrealized spread commission. | Tier 2 — SP_DailyCommisionReport |
| 39 | FullCommissionOnClose | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissionOnClose | SUM(FullCommissionOnClose) — aggregated gross full commission on closed positions. | Tier 2 — SP_DailyCommisionReport |
| 40 | FullCommissionByUnitsAtClose | — | — | **Always NULL** — SUM of a NULL column in parent. Legacy decomposition. | Tier 4 — Legacy/Deprecated |
| 41 | UnrealizedFullCommissionNew | — | — | **Always NULL** — SUM of a NULL column in parent. Legacy decomposition. | Tier 4 — Legacy/Deprecated |
| 42 | UnrealizedFullCommissionOldClosing | — | — | **Always NULL** — SUM of a NULL column in parent. Legacy decomposition. | Tier 4 — Legacy/Deprecated |
| 43 | RealizedFullCommission | BI_DB_dbo.BI_DB_DailyCommisionReport | RealizedFullCommission | SUM(RealizedFullCommission) — aggregated gross realized full commission. | Tier 2 — SP_DailyCommisionReport |
| 44 | UnealizedFullCommissionChange | — | — | **Always NULL** — SUM of a NULL column in parent. **DDL typo: "Un*e*alized"** (missing 'r'). Legacy. | Tier 4 — Legacy/Deprecated |
| 45 | IsBuy | BI_DB_dbo.BI_DB_DailyCommisionReport | IsBuy | GROUP BY pass-through — 1=long (buy), 0=short (sell). | Tier 2 — SP_DailyCommisionReport |
| 46 | IsLeverage | BI_DB_dbo.BI_DB_DailyCommisionReport | IsLeverage | GROUP BY pass-through — 1 if position Leverage > 1. | Tier 2 — SP_DailyCommisionReport |
| 47 | IsLeverageMoreThen20 | BI_DB_dbo.BI_DB_DailyCommisionReport | IsLeverageMoreThen20 | GROUP BY pass-through — 1 if position Leverage > 20. High-leverage flag. | Tier 2 — SP_DailyCommisionReport |
| 48 | IsAirDrop | BI_DB_dbo.BI_DB_DailyCommisionReport | IsAirDrop | GROUP BY pass-through — 1 for airdrop-created crypto positions. | Tier 2 — SP_DailyCommisionReport |
| 49 | SettlementTypeID | BI_DB_dbo.BI_DB_DailyCommisionReport | SettlementTypeID | GROUP BY pass-through — position settlement type (0=CFD, 1=Real, 5=Margin trade). | Tier 2 — SP_DailyCommisionReport |
| 50 | IsValidCustomer | BI_DB_dbo.BI_DB_DailyCommisionReport | IsValidCustomer | GROUP BY pass-through — valid customer flag. | Tier 2 — SP_DailyCommisionReport |
| 51 | IsCreditReportValidCB | BI_DB_dbo.BI_DB_DailyCommisionReport | IsCreditReportValidCB | GROUP BY pass-through — credit bureau validity flag. | Tier 2 — SP_DailyCommisionReport |
| 52 | Regulation | BI_DB_dbo.BI_DB_DailyCommisionReport | Regulation | GROUP BY pass-through — regulatory jurisdiction label. | Tier 2 — SP_DailyCommisionReport |
| 53 | IsSettled | BI_DB_dbo.BI_DB_DailyCommisionReport | IsSettled | GROUP BY pass-through — 1=real/settled position, 0=CFD. | Tier 2 — SP_DailyCommisionReport |
| 54 | RollOverFee_SDRT | BI_DB_dbo.BI_DB_DailyCommisionReport | RollOverFee_SDRT | SUM(ISNULL(RollOverFee_SDRT,0)) — aggregated UK Stamp Duty Reserve Tax. | Tier 2 — SP_DailyCommisionReport |
| 55 | TradingFees | BI_DB_dbo.BI_DB_DailyCommisionReport | TradingFees | SUM(ISNULL(TradingFees,0)) — aggregated composite trading fees (AdminFee + SpotAdjustFee + TicketFee + TicketFeeByPercent). | Tier 2 — SP_DailyCommisionReport |
| 56 | IsDLTUser | BI_DB_dbo.BI_DB_DailyCommisionReport | IsDLTUser | GROUP BY pass-through — DLT user flag. | Tier 2 — SP_DailyCommisionReport |
| 57 | TicketFee | BI_DB_dbo.BI_DB_DailyCommisionReport | TicketFee | SUM(ISNULL(TicketFee,0)) — aggregated per-ticket transaction fee. | Tier 2 — SP_DailyCommisionReport |
| 58 | TicketFeeByPercent | BI_DB_dbo.BI_DB_DailyCommisionReport | TicketFeeByPercent | SUM(ISNULL(TicketFeeByPercent,0)) — aggregated percentage-based ticket fee. | Tier 2 — SP_DailyCommisionReport |
| 59 | AdminFee | BI_DB_dbo.BI_DB_DailyCommisionReport | AdminFee | SUM(ISNULL(AdminFee,0)) — aggregated Islamic finance/administration fee. | Tier 2 — SP_DailyCommisionReport |
| 60 | SpotAdjustFee | BI_DB_dbo.BI_DB_DailyCommisionReport | SpotAdjustFee | SUM(ISNULL(SpotAdjustFee,0)) — aggregated spot price adjustment fee. | Tier 2 — SP_DailyCommisionReport |
| 61 | InvestedAmountOpen | BI_DB_dbo.BI_DB_DailyCommisionReport | InvestedAmountOpen | SUM(InvestedAmountOpen) — aggregated USD invested amount for positions opened on DateID. | Tier 2 — SP_DailyCommisionReport |
| 62 | CountUU | BI_DB_dbo.BI_DB_DailyCommisionReport | CountUU | SUM(CountUU) — sum of unique-user counts from parent rows. Represents total customer-activity events in this instrument×segment combination. | Tier 2 — SP_DailyCommisionReport |
| 63 | IsMarginTrade | BI_DB_dbo.BI_DB_DailyCommisionReport | IsMarginTrade | GROUP BY pass-through — 1=margin-funded position (SettlementTypeID=5). Added 2025-10-23. | Tier 2 — SP_DailyCommisionReport |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_DailyCommisionReport (@DateID)
  — customer×instrument×position-type grain — ~179K rows/date
  |
  | SP_DailyCommisionReport @Date (same execution, runs immediately after parent insert)
  |   DELETE FROM BI_DB_DailyCommisionReport_Instrument_Agg WHERE DateID = @DateID
  |   INSERT INTO BI_DB_DailyCommisionReport_Instrument_Agg
  |     SELECT ... SUM(commissions/volumes) GROUP BY Instrument × CustomerSegments (no CID)
  v
BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
  (~430K rows/date | 2026-YTD: 43.9M rows | CLUSTERED INDEX DateID | ROUND_ROBIN)
  |-- Generic Pipeline (Append, daily) ---|
  v
general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg
  (Unity Catalog Gold — delta format)
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 49 | InstrumentID, Instrument, InstrumentTypeID, InstrumentType, Region, Club, FullDate, DateID, FTD Year, VolumeOnOpen, VolumeOnClose, RollOverFee, FullCommissions, Commissions, UpdateDate, Label, PlayerStatusID, PlayerStatus, AccountStatusID, AccountStatusName, AccountTypeID, AccountType, IsEtoroTradingCID, IsGlenEagleAccount, eToroTradingGroupUser, US_State, CommissionOnClose, UnrealizedCommissionChange, FullCommissionOnClose, RealizedFullCommission, IsBuy, IsLeverage, IsLeverageMoreThen20, IsAirDrop, SettlementTypeID, IsValidCustomer, IsCreditReportValidCB, Regulation, IsSettled, RollOverFee_SDRT, TradingFees, IsDLTUser, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee, InvestedAmountOpen, CountUU, IsMarginTrade |
| Tier 3 | 0 | — |
| Tier 4 | 14 | IsOutlier, Transition, IsGermanBaFIN, RegulationIDPrev, RegulationPrev, IsCreditReportValidCBPrev, CommissionByUnitsAtClose, UnrealizedCommissionNew, UnrealizedCommissionOldClosing, RealizedCommission, FullCommissionByUnitsAtClose, UnrealizedFullCommissionNew, UnrealizedFullCommissionOldClosing, UnealizedFullCommissionChange |
