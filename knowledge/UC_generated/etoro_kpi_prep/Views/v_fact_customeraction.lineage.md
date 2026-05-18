# Column Lineage: main.etoro_kpi_prep.v_fact_customeraction

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_fact_customeraction` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_fact_customeraction.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_fact_customeraction.json` (rows: 79, mismatches: 11) |
| **Primary upstream** | `main.trading.bronze_etoro_history_positionchangelog` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.trading.bronze_etoro_history_positionchangelog` | Primary (FROM) | ✓ `knowledge\ProdSchemas\DB_Schema\etoro\Wiki\History\Views\History.PositionChangeLog.md` |
| `main.dwh.dim_position` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |

## Lineage Chain

```
main.trading.bronze_etoro_history_positionchangelog   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   (JOIN)
  + main.dwh.dim_position   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_fact_customeraction   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `HistoryID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `HistoryID` | `passthrough` | (Tier 5 — domain expert) | fca.HistoryID |
| 2 | `GCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `GCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fca.GCID |
| 3 | `RealCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `RealCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | fca.RealCID |
| 4 | `DemoCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DemoCID` | `passthrough` | (Tier 3 — ETL-assigned) | fca.DemoCID |
| 5 | `Occurred` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `Occurred` | `passthrough` | (Tier 1 — source-dependent) | fca.Occurred |
| 6 | `IPNumber` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IPNumber` | `passthrough` | (Tier 1 — STS/Billing.Login) | fca.IPNumber |
| 7 | `IsReal` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IsReal` | `passthrough` | (Tier 3 — ETL-assigned) | fca.IsReal |
| 8 | `ActionTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `ActionTypeID` | `passthrough` | (Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads) | fca.ActionTypeID |
| 9 | `PlatformTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `PlatformTypeID` | `passthrough` | (Tier 3 — ETL-assigned) | fca.PlatformTypeID |
| 10 | `InstrumentID` | `main.dwh.dim_position / main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(dp.InstrumentID, fca.InstrumentID) AS InstrumentID |
| 11 | `Amount` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `Amount` | `passthrough` | (Tier 1 — Trade.PositionTbl / History.Credit) | fca.Amount |
| 12 | `Leverage` | `main.dwh.dim_position / main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(dp.Leverage, fca.Leverage) AS Leverage |
| 13 | `NetProfit` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `NetProfit` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.NetProfit |
| 14 | `Commission` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `Commission` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.Commission |
| 15 | `PositionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `case` | — | CASE WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID IN (117, 118) THEN TRY_CAST(REVERSE(SUBSTRING(REVERSE(fca.Description), 1, LOCA |
| 16 | `CampaignID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `CampaignID` | `passthrough` | (Tier 5 — domain expert) | fca.CampaignID |
| 17 | `BonusTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `BonusTypeID` | `passthrough` | (Tier 5 — domain expert) | fca.BonusTypeID |
| 18 | `FundingTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `FundingTypeID` | `passthrough` | (Tier 1 — History.Credit) | fca.FundingTypeID |
| 19 | `LoginID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `LoginID` | `passthrough` | (Tier 1 — Billing.Login) | fca.LoginID |
| 20 | `MirrorID` | `main.dwh.dim_position / main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `case` | — | CASE WHEN fca.Occurred > dm.Occurred THEN 0 ELSE COALESCE(mc.PitMirrorID, dp.MirrorID, fca.MirrorID) END AS MirrorID |
| 21 | `WithdrawID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `WithdrawID` | `passthrough` | (Tier 1 — History.Credit) | fca.WithdrawID |
| 22 | `DurationInSeconds` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DurationInSeconds` | `passthrough` | (Tier 1 — Billing.Login) | fca.DurationInSeconds |
| 23 | `PostID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `PostID` | `passthrough` | (Tier 1 — Social platform) | fca.PostID |
| 24 | `CaseID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `CaseID` | `passthrough` | (Tier 1 — CRM) | fca.CaseID |
| 25 | `UpdateDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `UpdateDate` | `passthrough` | (Tier 2 — SP_Fact_CustomerAction) | fca.UpdateDate |
| 26 | `DateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DateID` | `passthrough` | (Tier 2 — SP_Fact_CustomerAction) | fca.DateID |
| 27 | `TimeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `TimeID` | `passthrough` | (Tier 2 — SP_Fact_CustomerAction) | fca.TimeID |
| 28 | `StatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `StatusID` | `passthrough` | (Tier 3 — ETL-assigned) | fca.StatusID |
| 29 | `PreviousOccurred` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `PreviousOccurred` | `passthrough` | (Tier 5 — domain expert) | fca.PreviousOccurred |
| 30 | `CompensationReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `CompensationReasonID` | `passthrough` | (Tier 1 — History.Credit, updated wiki 2025-12) | fca.CompensationReasonID |
| 31 | `WithdrawPaymentID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `WithdrawPaymentID` | `passthrough` | (Tier 1 — History.Credit) | fca.WithdrawPaymentID |
| 32 | `CommissionOnClose` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `CommissionOnClose` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.CommissionOnClose |
| 33 | `IsPlug` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IsPlug` | `passthrough` | (Tier 5 — domain expert) | fca.IsPlug |
| 34 | `DepositID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DepositID` | `passthrough` | (Tier 1 — History.Credit) | fca.DepositID |
| 35 | `PostRootID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `PostRootID` | `passthrough` | (Tier 1 — Social platform) | fca.PostRootID |
| 36 | `FullCommission` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `FullCommission` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.FullCommission |
| 37 | `FullCommissionOnClose` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `FullCommissionOnClose` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.FullCommissionOnClose |
| 38 | `RedeemID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `RedeemID` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.RedeemID |
| 39 | `RedeemStatus` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `RedeemStatus` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.RedeemStatus |
| 40 | `SessionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `SessionID` | `passthrough` | (Tier 1 — STS) | fca.SessionID |
| 41 | `IsRedeem` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IsRedeem` | `passthrough` | (Tier 2 — SP_Fact_CustomerAction) | fca.IsRedeem |
| 42 | `RegulationIDOnOpen` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `RegulationIDOnOpen` | `passthrough` | (Tier 2 — SP_Dim_Position_DL_To_Synapse) | fca.RegulationIDOnOpen |
| 43 | `PlatformID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `PlatformID` | `passthrough` | (Tier 5 — domain expert) | fca.PlatformID |
| 44 | `ReopenForPositionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `ReopenForPositionID` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.ReopenForPositionID |
| 45 | `IsReOpen` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IsReOpen` | `passthrough` | (Tier 2 — SP_Dim_Position_DL_To_Synapse) | fca.IsReOpen |
| 46 | `CommissionOnCloseOrig` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `CommissionOnCloseOrig` | `passthrough` | (Tier 2 — SP_Dim_Position_DL_To_Synapse) | fca.CommissionOnCloseOrig |
| 47 | `FullCommissionOnCloseOrig` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `FullCommissionOnCloseOrig` | `passthrough` | (Tier 2 — SP_Dim_Position_DL_To_Synapse) | fca.FullCommissionOnCloseOrig |
| 48 | `OriginalPositionID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `OriginalPositionID` | `passthrough` | (Tier 2 — SP_Dim_Position_DL_To_Synapse) | fca.OriginalPositionID |
| 49 | `IsPartialCloseParent` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IsPartialCloseParent` | `passthrough` | (Tier 5 — domain expert, SP_Fact_CustomerAction_IsParitalCloseParent) | fca.IsPartialCloseParent |
| 50 | `IsPartialCloseChild` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IsPartialCloseChild` | `passthrough` | (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) | fca.IsPartialCloseChild |
| 51 | `InitialUnits` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `InitialUnits` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.InitialUnits |
| 52 | `PaymentStatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `PaymentStatusID` | `passthrough` | (Tier 5 — domain expert) | fca.PaymentStatusID |
| 53 | `IsDiscounted` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IsDiscounted` | `passthrough` | (Tier 1 — Trade.PositionTbl) | fca.IsDiscounted |
| 54 | `IsSettled` | `main.dwh.dim_position / main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(dp.IsSettled, fca.IsSettled) AS IsSettled |
| 55 | `CommissionByUnits` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `CommissionByUnits` | `passthrough` | (Tier 1 — Trade.Position) | fca.CommissionByUnits |
| 56 | `FullCommissionByUnits` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `FullCommissionByUnits` | `passthrough` | (Tier 1 — Trade.Position) | fca.FullCommissionByUnits |
| 57 | `IsFTD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IsFTD` | `passthrough` | (Tier 2 — SP_Fact_CustomerAction) | fca.IsFTD |
| 58 | `CountryIDByIP` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `CountryIDByIP` | `passthrough` | (Tier 5 — domain expert) | fca.CountryIDByIP |
| 59 | `IsAnonymousIP` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IsAnonymousIP` | `passthrough` | (Tier 1 — IP geolocation service) | fca.IsAnonymousIP |
| 60 | `ProxyType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `ProxyType` | `passthrough` | (Tier 1 — STS) | fca.ProxyType |
| 61 | `IsFeeDividend` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `IsFeeDividend` | `passthrough` | (Tier 2 — SP_Fact_CustomerAction) | fca.IsFeeDividend |
| 62 | `IsAirDrop` | `main.dwh.dim_position / main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(dp.IsAirDrop, fca.IsAirDrop) AS IsAirDrop |
| 63 | `DividendID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DividendID` | `passthrough` | (Tier 1 — Trade.Positions/dividends lineage) | fca.DividendID |
| 64 | `MoveMoneyReasonID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `MoveMoneyReasonID` | `passthrough` | (Tier 1 — History.Credit) | fca.MoveMoneyReasonID |
| 65 | `SettlementTypeID` | `main.dwh.dim_position / main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(dp.SettlementTypeID, fca.SettlementTypeID) AS SettlementTypeID |
| 66 | `etr_y` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `etr_y` | `passthrough` | — | fca.etr_y |
| 67 | `etr_ym` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `etr_ym` | `passthrough` | — | fca.etr_ym |
| 68 | `etr_ymd` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `etr_ymd` | `passthrough` | — | fca.etr_ymd |
| 69 | `DLTOpen` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DLTOpen` | `passthrough` | (Tier 2 — SP_Dim_Position_DL_To_Synapse) | fca.DLTOpen |
| 70 | `DLTClose` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `DLTClose` | `passthrough` | (Tier 2 — SP_Dim_Position_DL_To_Synapse) | fca.DLTClose |
| 71 | `OpenMarkupByUnits` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `OpenMarkupByUnits` | `passthrough` | (Tier 1 — Trade.Position) | fca.OpenMarkupByUnits |
| 72 | `Description` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `Description` | `passthrough` | (Tier 1 — History.Credit) | fca.Description |
| 73 | `IsBuy` | `main.dwh.dim_position / main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `coalesce` | — | COALESCE(dp.IsBuy, fca.IsBuy) AS IsBuy |
| 74 | `CreditID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `CreditID` | `passthrough` | (Tier 1 — History.Credit) | fca.CreditID |
| 75 | `OpenDateID` | `main.dwh.dim_position` | `OpenDateID` | `cast` | — | cast to INT — CAST(dp.OpenDateID AS INT) AS OpenDateID |
| 76 | `CloseDateID` | `main.dwh.dim_position` | `CloseDateID` | `cast` | — | cast to INT — CAST(dp.CloseDateID AS INT) AS CloseDateID |
| 77 | `VolumeOnOpen` | `—` | `—` | `unknown` | — | CAST(NULL AS DECIMAL(38, 6)) AS VolumeOnOpen |
| 78 | `VolumeOnClose` | `—` | `—` | `unknown` | — | CAST(NULL AS DECIMAL(38, 6)) AS VolumeOnClose |
| 79 | `TicketFeeAction` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | `—` | `case` | — | CASE WHEN fca.Description = 'OpenTotalFees' THEN 'Open' WHEN fca.Description = 'CloseTotalFees' THEN 'Close' ELSE NULL END AS TicketFeeActio |

## Cross-check vs system.access.column_lineage

- Total target columns: **79**
- OK: **68**, WARN: **0**, ERROR: **11**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `InstrumentID` | — | `main.dwh.dim_position.instrumentid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.instrumentid` | ERROR |
| `Leverage` | — | `main.dwh.dim_position.leverage`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.leverage` | ERROR |
| `PositionID` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.compensationreasonid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.description`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.positionid` | ERROR |
| `MirrorID` | — | `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.occurred`, `main.trading.bronze_etoro_history_positionchangelog.changetypeid`, `main.trading.bronze_etoro_history_positionchangelog.mirrorid`, `main.trading.bronze_etoro_history_positionchangelog.occurred`, `main.trading.bronze_etoro_history_positionchangelog.positionid` | ERROR |
| `IsSettled` | — | `main.dwh.dim_position.issettled`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.issettled` | ERROR |
| `IsAirDrop` | — | `main.dwh.dim_position.isairdrop`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.isairdrop` | ERROR |
| `SettlementTypeID` | — | `main.dwh.dim_position.settlementtypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.settlementtypeid` | ERROR |
| `IsBuy` | — | `main.dwh.dim_position.isbuy`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.isbuy` | ERROR |
| `VolumeOnOpen` | — | `main.dwh.dim_position.volume` | ERROR |
| `VolumeOnClose` | — | `main.dwh.dim_position.volumeonclose` | ERROR |
| `TicketFeeAction` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.description` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **3**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.dwh.dim_position AS dp ON CASE WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID IN (117, 118) THEN TRY_CAST(REVERSE(SUBSTRING(REVERSE(fca.Description), 1, LOCATE(' ', REVERSE(fca.Description)) - 1)) AS BIGINT) ELSE fca
- `LEFT JOIN` — LEFT JOIN (SELECT PositionID, MAX(Occurred) AS Occurred FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction WHERE ActionTypeID = 19 GROUP BY PositionID) AS dm ON fca.PositionID = dm.PositionID
- `LEFT JOIN` — LEFT JOIN mirror_changelog AS mc ON CASE WHEN fca.ActionTypeID = 36 AND fca.CompensationReasonID IN (117, 118) THEN TRY_CAST(REVERSE(SUBSTRING(REVERSE(fca.Description), 1, LOCATE(' ', REVERSE(fca.Description)) - 1)) AS BIGINT) ELSE fca.Posi
- `LEFT JOIN` — LEFT JOIN main.dwh.dim_position AS dp ON fca.PositionID = dp.PositionID
