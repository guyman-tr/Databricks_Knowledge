# Lineage: BI_DB_dbo.Client_Balance_Breakdown_Instrument_Level

**Writer SP**: `BI_DB_dbo.SP_Client_Balance_Breakdown`
**Author**: Guy Manova (2023-04-20)
**OpsDB Priority**: P20
**Refresh**: Daily (one @Date per run)
**UC Target**: _Not_Migrated

---

## Key Source Objects

| Source Object | Schema | Role |
|---------------|--------|------|
| Fact_CustomerAction | DWH_dbo | Open/close position events (ActionTypeID 1-6, 28, 39, 40) on @DateID |
| BI_DB_PositionPnL | BI_DB_dbo | Daily open position PnL snapshot (today and yesterday, for unrealized change) |
| Dim_Position | DWH_dbo | Position master: Leverage, IsBuy, IsAirDrop, NetProfit, Commission, FullCommission, CommissionOnClose, CommissionByUnits |
| Dim_PositionChangeLog | DWH_dbo | Partial close adjustments (ChangeTypeID=12 for same-day, ChangeTypeID=13 for prior-day) |
| Dim_Instrument | DWH_dbo | InstrumentTypeID, InstrumentType per position |
| Fact_SnapshotCustomer | DWH_dbo | Customer segmentation at @DateID and @DatePrevID (SCD2 via Dim_Range) |
| Dim_Range | DWH_dbo | SCD2 time-bounding for snapshot |
| Dim_Country | DWH_dbo | Country name, MarketingRegionManualName (Region) |
| Dim_State_and_Province | DWH_dbo | US state short name (RegionByIP_ID → ShortName) |
| Dim_Regulation | DWH_dbo | Regulation name via DWHRegulationID |
| Dim_AccountStatus | DWH_dbo | AccountStatusName |
| Dim_AccountType | DWH_dbo | AccountType name |
| Dim_MifidCategorization | DWH_dbo | MiFiDCategorization name |
| Dim_PlayerLevel | DWH_dbo | Club tier name |
| Dim_PlayerStatus | DWH_dbo | PlayerStatus name |
| Dim_Label | DWH_dbo | Label (brand) name |
| Dim_Customer | DWH_dbo | Used in #fsc2days join |
| V_Liabilities | DWH_dbo | LiabilitiesCryptoReal → IsGermanBaFin flag |
| BI_DB_Outliers_New | BI_DB_dbo | IsOutlier, Transition per RealCID on @DateID |
| BI_DB_Client_Balance_CID_Level_New | BI_DB_dbo | TanganyStatus (MAX per CID), IsDLTUser |
| Function_Revenue_TicketFeeByPercent | BI_DB_dbo | TicketFeeByPercent amounts and action (Open/Close) |
| Function_Instrument_Snapshot_Enriched | BI_DB_dbo | IsSQF flag, IsTicketFeePercentInstrument flag per @DateID |
| External_Bronze_etoro_Trade_AdminPositionLog | BI_DB_dbo | IsC2P (CompensationReasonID=134) |

---

## Column Lineage (Key Columns)

| # | Column | Primary Source | Transform |
|---|--------|---------------|-----------|
| 1 | DateID | ETL parameter | `CAST(CONVERT(CHAR(8),@Date,112) AS INT)` |
| 2 | Date | ETL parameter | `@Date` |
| 3 | IsSettled | Dim_Position | With IsSettledIsMirror override (close-day wins over open-day, hodl as fallback) |
| 4 | IsMirror | Dim_Position (MirrorID) | `CASE WHEN MirrorID > 0 THEN 1 ELSE 0` with same override |
| 5 | InstrumentID | Dim_Instrument | via Dim_Position.InstrumentID |
| 6-7 | InstrumentTypeID, InstrumentType | Dim_Instrument | passthrough |
| 8 | IsLeverage | Dim_Position (Leverage) | `CASE WHEN Leverage > 1 THEN 1 ELSE 0` |
| 9 | IsLeverageMoreThen20 | Dim_Position (Leverage) | `CASE WHEN Leverage > 20 THEN 1 ELSE 0` |
| 10 | IsAirDrop | Dim_Position | passthrough |
| 11 | SettlementTypeID | Dim_Position | passthrough |
| 12 | IsBuy | Dim_Position | passthrough |
| 13 | Regulation | Dim_Regulation | via FSC.RegulationID → Dim_Regulation.DWHRegulationID → Name |
| 14 | RegTransferDirection | ETL-computed | 1 for all; -1 added for reg-transfer customers (prior reg row) |
| 15 | IsCreditReportValidCB | Fact_SnapshotCustomer | passthrough |
| 16 | IsValidCustomer | Fact_SnapshotCustomer | passthrough |
| 17 | AccountStatusName | Dim_AccountStatus | via FSC.AccountStatusID |
| 18 | AccountType | Dim_AccountType | via FSC.AccountTypeID |
| 19 | Country | Dim_Country | via FSC.CountryID → Name |
| 20 | US_State | Dim_State_and_Province | `CASE WHEN CountryID=219 THEN ShortName ELSE ''` |
| 21 | Region | Dim_Country (MarketingRegionManualName) | via FSC.CountryID |
| 22 | MiFiDCategorization | Dim_MifidCategorization | via FSC.MifidCategorizationID |
| 23 | Club | Dim_PlayerLevel | via FSC.PlayerLevelID → Name |
| 24 | PlayerStatus | Dim_PlayerStatus | via FSC.PlayerStatusID |
| 25 | Label | Dim_Label | via FSC.LabelID |
| 26 | IsOutlier | BI_DB_Outliers_New | `CASE WHEN RealCID IN outliers THEN 1 ELSE 0` |
| 27 | Transition | BI_DB_Outliers_New | Transition string; "NoTransition" for non-outliers |
| 28 | IsGermanBaFIN | V_Liabilities + Dim_Country | `CASE WHEN HoldsCrypto=1 AND CountryID=79 THEN 1 ELSE 0` |
| 29 | IsEtoroTradingCID | ETL-computed | Hardcoded 7-CID list |
| 30 | IsGlenEagleAccount | ETL-computed | Hardcoded CID=14155290 |
| 31 | UnrealizedPnLChange | Fact_CustomerAction + BI_DB_PositionPnL | Sum of TotalUnrealizedPnLChangeFinal per group |
| 32 | RealizedPnL | Dim_Position (NetProfit) | Sum of TotalRealizedPnLFinal |
| 33 | TotalPnL | ETL-computed | UnrealizedPnLChange + RealizedPnL |
| 34 | UnrealizedCommissionChange | Fact_CustomerAction + Dim_Position | Commission transfer amounts for open positions |
| 35 | RealizedCommission | Fact_CustomerAction | CommissionOnClose for closed positions |
| 36-37 | UnrealizedFullCommissionChange, RealizedFullCommission | Same as 34-35 | FullCommission parallel track |
| 38-39 | CommissionOnOpen, FullCommissionOnOpen | Dim_Position | For newly opened positions (OpenDuringNotClosed, OpenDuringClosedDuring) |
| 40-41 | CommissionCloseAdjustment, FullCommissionCloseAdjustment | Dim_Position | CommissionOnClose - CommissionByUnits |
| 42-43 | TotalCommission, TotalFullCommission | ETL-computed | Realized + Unrealized |
| 44 | TotalZero | ETL-computed | Full commission + PnL balance check |
| 45 | UpdateDate | ETL-computed | `GETDATE()` |
| 46 | TanganyStatus | BI_DB_Client_Balance_CID_Level_New | MAX per CID per DateID |
| 47 | IsDLTUser | BI_DB_Client_Balance_CID_Level_New | MAX per CID per DateID |
| 48 | CommissionVersion | Dim_Position | passthrough |
| 49 | TicketFeeByPercentOnClose | Function_Revenue_TicketFeeByPercent | TicketFeeByPercent where Action='Close' |
| 50 | IsSQF | Function_Instrument_Snapshot_Enriched | IsSQF flag per @DateID |
| 51 | TicketFeeByPercentPositionType | ETL-computed | New/Legacy/NotRelevant CASE logic |
| 52 | TicketFeeByPercentOnOpen | Function_Revenue_TicketFeeByPercent | TicketFeeByPercent where Action='Open' |
| 53 | IsC2P | External_Bronze_etoro_Trade_AdminPositionLog | CompensationReasonID=134 |
