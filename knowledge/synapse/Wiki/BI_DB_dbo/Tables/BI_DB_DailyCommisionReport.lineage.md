# BI_DB_dbo.BI_DB_DailyCommisionReport — Column Lineage

**Generated**: 2026-04-21 | **Writer SP**: SP_DailyCommisionReport | **Batch**: 20

## Summary

Daily DELETE WHERE DateID=@DateID + INSERT incremental commission and trading revenue report. Grain: RealCID × Date × InstrumentID × IsSettled × IsMirror × IsBuy × IsLeverage × IsLeverageMoreThen20 × IsAirDrop × SettlementTypeID × IsMarginTrade. Population sourced from BI_DB_Client_Balance_CID_Level_New (customer dimensions as of @DateID). Revenue metrics computed through foundation-layer TVFs: Function_Revenue_FullCommissions, Function_Revenue_Commissions, Function_Revenue_RolloverFee, Function_Revenue_TicketFee, Function_Revenue_TicketFeeByPercent, Function_Revenue_AdminFee, Function_Revenue_SpotAdjustFee, Function_Revenue_SDRT, Function_Trading_Volume. Key dependency for all DDR satellite tables and downstream user-segment/equity/deposit snapshots.

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | CID | Direct — platform RealCID. Primary customer key. Hash distribution key in #pop. | Tier 2 — SP_DailyCommisionReport |
| 2 | UserName | DWH_dbo.Dim_Customer | UserName | dc1.UserName via JOIN Dim_Customer ON fsc.RealCID = dc1.RealCID in #pop step. | Tier 2 — SP_DailyCommisionReport |
| 3 | InstrumentID | BI_DB_dbo.Function_Revenue_FullCommissions | InstrumentID | Instrument key from revenue/volume TVFs via #allMetrics COALESCE chain. | Tier 2 — SP_DailyCommisionReport |
| 4 | Instrument | DWH_dbo.Dim_Instrument | Name | di1.Name AS Instrument via JOIN Dim_Instrument in each revenue temp table. | Tier 2 — SP_DailyCommisionReport |
| 5 | InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | Instrument type key from Dim_Instrument, propagated through revenue TVFs. | Tier 2 — SP_DailyCommisionReport |
| 6 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Instrument type label (Currencies, Commodities, Indices, Stocks, Crypto Currencies, etc.) from Dim_Instrument. | Tier 2 — SP_DailyCommisionReport |
| 7 | CountryID | DWH_dbo.Fact_SnapshotCustomer | CountryID | fsc.CountryID — integer country key from Fact_SnapshotCustomer as of @DateID. | Tier 2 — SP_DailyCommisionReport |
| 8 | Country | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Country | bdcbcln.Country — full country name sourced through BI_DB_Client_Balance_CID_Level_New (traces to Dim_Country.Name). | Tier 2 — SP_DailyCommisionReport |
| 9 | Region | DWH_dbo.Dim_Country | MarketingRegionManualName | dc.MarketingRegionManualName AS Region — marketing region label via JOIN Dim_Country ON fsc.CountryID = dc.CountryID. | Tier 2 — SP_DailyCommisionReport |
| 10 | Manager | DWH_dbo.Dim_Manager | FirstName, LastName | dm.FirstName + ' ' + dm.LastName via JOIN Dim_Manager ON fsc.AccountManagerID = dm.ManagerID. | Tier 2 — SP_DailyCommisionReport |
| 11 | Club | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Club | bdcbcln.Club — customer club tier label (Diamond, Platinum, Gold, Silver, etc.) as of @DateID. | Tier 2 — SP_DailyCommisionReport |
| 12 | FullDate | @Date parameter | — | Direct assignment of SP @Date input. Reporting date. | Tier 2 — SP_DailyCommisionReport |
| 13 | DateID | @Date parameter | — | CAST(CONVERT(CHAR(8),@Date,112) AS INT) — YYYYMMDD int. Clustering and DELETE key. | Tier 2 — SP_DailyCommisionReport |
| 14 | Commissions | BI_DB_dbo.Function_Revenue_Commissions | TotalCommission | SUM(TotalCommission) per grain from Function_Revenue_Commissions(@DateID,@DateID,0). Net commission: Commission on open actions + CommissionOnClose minus unit adjustment on close. | Tier 2 — SP_DailyCommisionReport |
| 15 | FullCommissions | BI_DB_dbo.Function_Revenue_FullCommissions | TotalFullCommission | SUM(TotalFullCommission) per grain from Function_Revenue_FullCommissions(@DateID,@DateID,0). Gross full commission used for regulatory/MIFID revenue reporting. | Tier 2 — SP_DailyCommisionReport |
| 16 | VolumeOnOpen | BI_DB_dbo.Function_Trading_Volume | VolumeOpen | SUM(VolumeOpen) from Function_Trading_Volume(@DateID,@DateID,0). USD trading volume for positions opened on @DateID. | Tier 2 — SP_DailyCommisionReport |
| 17 | VolumeOnClose | BI_DB_dbo.Function_Trading_Volume | VolumeClose | SUM(VolumeClose) from Function_Trading_Volume. USD trading volume for positions closed on @DateID. | Tier 2 — SP_DailyCommisionReport |
| 18 | UpdateDate | — | — | GETDATE() at ETL execution time. | Tier 2 — SP_DailyCommisionReport |
| 19 | RollOverFee | BI_DB_dbo.Function_Revenue_RolloverFee | RolloverFee | SUM(RolloverFee) from Function_Revenue_RolloverFee(@DateID,@DateID,0). Daily overnight position carry fees. | Tier 2 — SP_DailyCommisionReport |
| 20 | FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | dc1.FirstDepositDate — customer's very first deposit date. Used for cohort analysis (FTD Year in Instrument_Agg). | Tier 2 — SP_DailyCommisionReport |
| 21 | Regulation | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | ToRegulation | bdcbcln.ToRegulation AS Regulation — regulatory jurisdiction label as of @DateID. | Tier 2 — SP_DailyCommisionReport |
| 22 | Mifid | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | MifidCategory | bdcbcln.MifidCategory AS Mifid — MiFID categorization label (Retail, Professional, Retail Pending, etc.). | Tier 2 — SP_DailyCommisionReport |
| 23 | IsSettled | DWH_dbo.Fact_CustomerAction | IsSettled | IsSettled from revenue TVFs (sourced from Fact_CustomerAction via Dim_Position). True=real/settled position; False=CFD. | Tier 2 — SP_DailyCommisionReport |
| 24 | IsMirror | DWH_dbo.Fact_CustomerAction | MirrorID | CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END — copy-trading vs manual. Derived from Fact_CustomerAction in revenue TVFs. | Tier 2 — SP_DailyCommisionReport |
| 25 | CommissionOnOpen | BI_DB_dbo.Function_Revenue_Commissions | Commission | SUM(Commission) for ActionTypeID IN (1,2,3,39) — commission earned when opening positions on @DateID. | Tier 2 — SP_DailyCommisionReport |
| 26 | CommissionOnCloseAdjustment | BI_DB_dbo.Function_Revenue_Commissions | CommissionCloseAdjustment | SUM(CommissionOnClose - CommissionByUnits) for close actions — commission adjustment net of unit-based component. | Tier 2 — SP_DailyCommisionReport |
| 27 | FullCommissionOnOpen | BI_DB_dbo.Function_Revenue_FullCommissions | FullCommissionOnOpen | SUM(FullCommission) for open actions — gross full commission on new positions. | Tier 2 — SP_DailyCommisionReport |
| 28 | FullCommissionOnCloseAdjustment | BI_DB_dbo.Function_Revenue_FullCommissions | FullCommissionCloseAdjustment | SUM(FullCommissionOnClose - FullCommissionByUnits) for close actions — gross commission adjustment on close. | Tier 2 — SP_DailyCommisionReport |
| 29 | RegulationID | DWH_dbo.Fact_SnapshotCustomer | RegulationID | fsc.RegulationID — integer regulation key from Fact_SnapshotCustomer as of @DateID. | Tier 2 — SP_DailyCommisionReport |
| 30 | PlayerLevelID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID | fsc.PlayerLevelID — integer player level key (1=Silver, 2=Gold, 3=Platinum, 4=Demo, etc.). | Tier 2 — SP_DailyCommisionReport |
| 31 | MifidCategorizationID | DWH_dbo.Fact_SnapshotCustomer | MifidCategorizationID | fsc.MifidCategorizationID — integer MiFID categorization key. | Tier 2 — SP_DailyCommisionReport |
| 32 | IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | fsc.IsValidCustomer — bit flag: 1 if customer meets eToro's "valid customer" criteria (non-demo, depositor, active). | Tier 2 — SP_DailyCommisionReport |
| 33 | IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | fsc.IsCreditReportValidCB — bit flag for credit report validity (US CB reporting). | Tier 2 — SP_DailyCommisionReport |
| 34 | Label | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Label | bdcbcln.Label — customer segment label as of @DateID (e.g., 'Proprietary', internal classification). | Tier 2 — SP_DailyCommisionReport |
| 35 | PlayerStatusID | DWH_dbo.Fact_SnapshotCustomer | PlayerStatusID | fsc.PlayerStatusID — integer player status key. | Tier 2 — SP_DailyCommisionReport |
| 36 | PlayerStatus | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | PlayerStatus | bdcbcln.PlayerStatus — player status name (Normal, Blocked, etc.) as of @DateID. | Tier 2 — SP_DailyCommisionReport |
| 37 | AccountStatusID | DWH_dbo.Fact_SnapshotCustomer | AccountStatusID | fsc.AccountStatusID — integer account status key. | Tier 2 — SP_DailyCommisionReport |
| 38 | AccountStatusName | DWH_dbo.Dim_AccountStatus | AccountStatusName | das.AccountStatusName via LEFT JOIN Dim_AccountStatus ON fsc.AccountStatusID. | Tier 2 — SP_DailyCommisionReport |
| 39 | AccountTypeID | DWH_dbo.Fact_SnapshotCustomer | AccountTypeID | fsc.AccountTypeID — integer account type key (1=Personal, 2=Corporate, 14=SMSF, etc.). | Tier 2 — SP_DailyCommisionReport |
| 40 | AccountType | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | AccountType | bdcbcln.AccountType — account type name as of @DateID. | Tier 2 — SP_DailyCommisionReport |
| 41 | IsOutlier | — | — | **Always NULL** — legacy column, not populated since 2025-07-16 overhaul. | Tier 4 — Legacy/Deprecated |
| 42 | Transition | — | — | **Always NULL** — legacy column, not populated. | Tier 4 — Legacy/Deprecated |
| 43 | IsGermanBaFIN | — | — | **Always NULL** — legacy column, not populated. | Tier 4 — Legacy/Deprecated |
| 44 | IsEtoroTradingCID | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | IsEtoroTradingCID | bdcbcln.IsEtoroTradingCID — flag for internal eToro trading/housekeeping accounts. | Tier 2 — SP_DailyCommisionReport |
| 45 | IsGlenEagleAccount | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | IsGlenEagleAccount | bdcbcln.IsGlenEagleAccount — flag for Glen Eagle Securities subsidiary accounts. | Tier 2 — SP_DailyCommisionReport |
| 46 | eToroTradingGroupUser | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | eToroTradingGroupUser | bdcbcln.eToroTradingGroupUser — eToro trading group identifier string. | Tier 2 — SP_DailyCommisionReport |
| 47 | RegulationIDPrev | — | — | **Always NULL** — legacy column for previous-regulation tracking, not populated since overhaul. | Tier 4 — Legacy/Deprecated |
| 48 | RegulationPrev | — | — | **Always NULL** — legacy column for previous-regulation name, not populated. | Tier 4 — Legacy/Deprecated |
| 49 | IsCreditReportValidCBPrev | — | — | **Always NULL** — legacy column, not populated. | Tier 4 — Legacy/Deprecated |
| 50 | US_State | DWH_dbo.Dim_State_and_Province | ShortName | dsap.ShortName — US state/province short name via LEFT JOIN Dim_State_and_Province ON fsc.RegionID = dsap.RegionByIP_ID AND dsap.CountryID=219 (US only). NULL for non-US customers. | Tier 2 — SP_DailyCommisionReport |
| 51 | CommissionOnClose | BI_DB_dbo.Function_Revenue_Commissions | CommissionOnClose | SUM(CommissionOnClose) for close actions (ActionTypeID IN 4,5,6,28,40). Raw close commission before unit adjustment. | Tier 2 — SP_DailyCommisionReport |
| 52 | CommissionByUnitsAtClose | — | — | **Always NULL** — computed in intermediate step but explicitly set NULL in INSERT. Legacy from prior SP version. | Tier 4 — Legacy/Deprecated |
| 53 | UnrealizedCommissionNew | — | — | **Always NULL** — explicitly set NULL in INSERT since 2025-07-16 overhaul. Legacy unrealized decomposition. | Tier 4 — Legacy/Deprecated |
| 54 | UnrealizedCommissionOldClosing | — | — | **Always NULL** — explicitly set NULL in INSERT since overhaul. Legacy unrealized decomposition. | Tier 4 — Legacy/Deprecated |
| 55 | RealizedCommission | — | — | **Always NULL** — computed in #allMetrics as SUM(CommissionOnClose) but explicitly set NULL in INSERT. Legacy decomposition. | Tier 4 — Legacy/Deprecated |
| 56 | UnrealizedCommissionChange | DWH_dbo.Fact_CustomerAction | Commission, CommissionByUnits | Daily change in unrealized spread commission: (CommissionOnOpen for new opens) - (CommissionByUnitsAtClose for closes) via #addUnrealizedChange. Accounts for the spread-based commission embedded in open positions. | Tier 2 — SP_DailyCommisionReport |
| 57 | FullCommissionOnClose | BI_DB_dbo.Function_Revenue_FullCommissions | FullCommissionOnClose | SUM(FullCommissionOnClose) for close actions — gross full commission on closed positions. | Tier 2 — SP_DailyCommisionReport |
| 58 | FullCommissionByUnitsAtClose | — | — | **Always NULL** — explicitly set NULL in INSERT. Legacy gross unrealized decomposition. | Tier 4 — Legacy/Deprecated |
| 59 | UnrealizedFullCommissionNew | — | — | **Always NULL** — explicitly set NULL in INSERT. Legacy gross unrealized decomposition. | Tier 4 — Legacy/Deprecated |
| 60 | UnrealizedFullCommissionOldClosing | — | — | **Always NULL** — explicitly set NULL in INSERT. Legacy gross unrealized decomposition. | Tier 4 — Legacy/Deprecated |
| 61 | RealizedFullCommission | BI_DB_dbo.Function_Revenue_FullCommissions | FullCommissionOnClose | SUM(FullCommissionOnClose) per grain from #FullComm. Gross realized full commission for closed positions. | Tier 2 — SP_DailyCommisionReport |
| 62 | UnealizedFullCommissionChange | — | — | **Always NULL** — explicitly set NULL in INSERT. **"Un*e*alized" is a persisted typo from the original DDL; actual DDL column name contains the typo.** Legacy gross unrealized change. | Tier 4 — Legacy/Deprecated |
| 63 | IsBuy | DWH_dbo.Dim_Position | IsBuy | dp.IsBuy — 1=long (buy) position, 0=short (sell) position. From Dim_Position via revenue TVFs. | Tier 2 — SP_DailyCommisionReport |
| 64 | IsLeverage | DWH_dbo.Dim_Position | Leverage | CASE WHEN Leverage > 1 THEN 1 ELSE 0 END — leveraged position flag. | Tier 2 — SP_DailyCommisionReport |
| 65 | IsLeverageMoreThen20 | DWH_dbo.Dim_Position | Leverage | CASE WHEN Leverage > 20 THEN 1 ELSE 0 END — high-leverage position flag (regulatory significance under ESMA/MiFID rules). | Tier 2 — SP_DailyCommisionReport |
| 66 | IsAirDrop | DWH_dbo.Dim_Position | IsAirDrop | dp.IsAirDrop — 1 for positions created via crypto airdrop distributions. | Tier 2 — SP_DailyCommisionReport |
| 67 | SettlementTypeID | DWH_dbo.Dim_Position | SettlementTypeID | Settlement type key: CASE WHEN SettlementTypeID IS NULL THEN IsSettled ELSE SettlementTypeID END. 1=real, 5=margin trade, etc. | Tier 2 — SP_DailyCommisionReport |
| 68 | RollOverFee_SDRT | BI_DB_dbo.Function_Revenue_SDRT | SDRT | SUM(SDRT) from Function_Revenue_SDRT(@DateID,@DateID,0). UK Stamp Duty Reserve Tax on UK equity transactions. Added 2023-10-31. | Tier 2 — SP_DailyCommisionReport |
| 69 | TradingFees | BI_DB_dbo.Function_Revenue_* | AdminFee, SpotAdjustFee, TicketFee, TicketFeeByPercent | ISNULL(AdminFee,0) + ISNULL(SpotAdjustFee,0) + ISNULL(TicketFee,0) + ISNULL(TicketFeeByPercent,0). Composite trading fees total. Added 2024-02-25. | Tier 2 — SP_DailyCommisionReport |
| 70 | IsDLTUser | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | IsDLTUser | bdcbcln.IsDLTUser — Distributed Ledger Technology user flag. Added 2024-07-30. | Tier 2 — SP_DailyCommisionReport |
| 71 | TicketFee | BI_DB_dbo.Function_Revenue_TicketFee | TicketFee | SUM(TicketFee) per grain from Function_Revenue_TicketFee(@DateID,@DateID,0). Per-ticket transaction fee. | Tier 2 — SP_DailyCommisionReport |
| 72 | TicketFeeByPercent | BI_DB_dbo.Function_Revenue_TicketFeeByPercent | TicketFeeByPercent | SUM(TicketFeeByPercent) per grain from Function_Revenue_TicketFeeByPercent. Percentage-based ticket fee (alternative fee structure). | Tier 2 — SP_DailyCommisionReport |
| 73 | AdminFee | BI_DB_dbo.Function_Revenue_AdminFee | AdminFee | SUM(AdminFee) from Function_Revenue_AdminFee. Islamic finance / administration fee charged to Islamic-compliant accounts (swap-free). | Tier 2 — SP_DailyCommisionReport |
| 74 | SpotAdjustFee | BI_DB_dbo.Function_Revenue_SpotAdjustFee | SpotAdjustFee | SUM(SpotAdjustFee) from Function_Revenue_SpotAdjustFee. Spot price adjustment fee on settled/real positions. | Tier 2 — SP_DailyCommisionReport |
| 75 | InvestedAmountOpen | BI_DB_dbo.Function_Trading_Volume | InvestedAmountOpen | SUM(InvestedAmountOpen) — USD invested amount for positions opened on @DateID. | Tier 2 — SP_DailyCommisionReport |
| 76 | CountUU | BI_DB_dbo.Function_Trading_Volume | CID (DISTINCT) | COUNT(DISTINCT CID) per grain from Function_Trading_Volume. Unique user count with trading activity in this dimension combination. | Tier 2 — SP_DailyCommisionReport |
| 77 | IsMarginTrade | DWH_dbo.Fact_CustomerAction | SettlementTypeID | CASE WHEN SettlementTypeID=5 THEN 1 ELSE 0 END from Fact_CustomerAction. Identifies margin-funded positions. Added 2025-10-23. | Tier 2 — SP_DailyCommisionReport |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (@DateID)     ← customer dimensions + regulation/club/labels
  + DWH_dbo.Fact_SnapshotCustomer (DateRangeID via Dim_Range join)
  + DWH_dbo.Dim_Manager, Dim_Customer, Dim_Country, Dim_AccountStatus, Dim_State_and_Province
  → #pop (customer universe for @DateID)

BI_DB_dbo.Function_Revenue_FullCommissions (@DateID, @DateID, 0)   → #FullComm
BI_DB_dbo.Function_Revenue_Commissions    (@DateID, @DateID, 0)    → #Comm
BI_DB_dbo.Function_Revenue_RolloverFee    (@DateID, @DateID, 0)    → #Rollovers
BI_DB_dbo.Function_Revenue_TicketFee      (@DateID, @DateID, 0)    → #TicketFee
BI_DB_dbo.Function_Revenue_TicketFeeByPercent (@DateID,@DateID,0)  → #TicketFeeByPercent
BI_DB_dbo.Function_Revenue_AdminFee       (@DateID, @DateID, 0)    → #AdminFee
BI_DB_dbo.Function_Revenue_SpotAdjustFee  (@DateID, @DateID, 0)    → #SpotAdjustFee
BI_DB_dbo.Function_Revenue_SDRT           (@DateID, @DateID, 0)    → #sdrt
BI_DB_dbo.Function_Trading_Volume         (@DateID, @DateID, 0)    → #volumes
DWH_dbo.Fact_CustomerAction + Dim_Position + Dim_Instrument        → #unrealizedCommChange

All metrics → FULL OUTER JOIN → #allMetrics (COALESCE grain resolution)

#pop LEFT JOIN #allMetrics (WHERE NOT all metrics NULL) → #final

  |-- SP_DailyCommisionReport @Date
  |     DELETE FROM BI_DB_DailyCommisionReport WHERE DateID = @DateID
  |     + INSERT FROM #final
  |     + DELETE FROM BI_DB_DailyCommisionReport_Instrument_Agg WHERE DateID = @DateID
  |     + INSERT INTO BI_DB_DailyCommisionReport_Instrument_Agg (grouped by instrument)
  v
BI_DB_dbo.BI_DB_DailyCommisionReport
  (2018-01-01 to 2026-04-12 | 3,024 distinct dates | ~179K rows/date | CLUSTERED INDEX DateID,RealCID | ROUND_ROBIN)
  |-- UC Target: _Not_Migrated ---|

BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg  ← also written by same SP execution
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 65 | RealCID, UserName, InstrumentID, Instrument, InstrumentTypeID, InstrumentType, CountryID, Country, Region, Manager, Club, FullDate, DateID, Commissions, FullCommissions, VolumeOnOpen, VolumeOnClose, UpdateDate, RollOverFee, FirstDepositDate, Regulation, Mifid, IsSettled, IsMirror, CommissionOnOpen, CommissionOnCloseAdjustment, FullCommissionOnOpen, FullCommissionOnCloseAdjustment, RegulationID, PlayerLevelID, MifidCategorizationID, IsValidCustomer, IsCreditReportValidCB, Label, PlayerStatusID, PlayerStatus, AccountStatusID, AccountStatusName, AccountTypeID, AccountType, IsEtoroTradingCID, IsGlenEagleAccount, eToroTradingGroupUser, US_State, CommissionOnClose, UnrealizedCommissionChange, FullCommissionOnClose, RealizedFullCommission, IsBuy, IsLeverage, IsLeverageMoreThen20, IsAirDrop, SettlementTypeID, RollOverFee_SDRT, TradingFees, IsDLTUser, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee, InvestedAmountOpen, CountUU, IsMarginTrade |
| Tier 3 | 0 | — |
| Tier 4 | 12 | IsOutlier, Transition, IsGermanBaFIN, RegulationIDPrev, RegulationPrev, IsCreditReportValidCBPrev, CommissionByUnitsAtClose, UnrealizedCommissionNew, UnrealizedCommissionOldClosing, RealizedCommission, FullCommissionByUnitsAtClose, UnrealizedFullCommissionNew, UnrealizedFullCommissionOldClosing, UnealizedFullCommissionChange [always NULL] |
