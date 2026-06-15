# Column Lineage: main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics

| Property | Value |
|----------|-------|
| **UC Object** | `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/de_output_etoro_kpi_fact_customeraction_w_metrics.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `GCID` | `—` | `—` | `runtime_lineage` |
| 2 | `RealCID` | `—` | `—` | `runtime_lineage` |
| 3 | `Occurred` | `—` | `—` | `runtime_lineage` |
| 4 | `ActionTypeID` | `—` | `—` | `runtime_lineage` |
| 5 | `PlatformTypeID` | `—` | `—` | `runtime_lineage` |
| 6 | `InstrumentID` | `—` | `—` | `runtime_lineage` |
| 7 | `Amount` | `—` | `—` | `runtime_lineage` |
| 8 | `Leverage` | `—` | `—` | `runtime_lineage` |
| 9 | `NetProfit` | `—` | `—` | `runtime_lineage` |
| 10 | `Commission` | `—` | `—` | `runtime_lineage` |
| 11 | `PositionID` | `—` | `—` | `runtime_lineage` |
| 12 | `FundingTypeID` | `—` | `—` | `runtime_lineage` |
| 13 | `MirrorID` | `—` | `—` | `runtime_lineage` |
| 14 | `WithdrawID` | `—` | `—` | `runtime_lineage` |
| 15 | `DateID` | `—` | `—` | `runtime_lineage` |
| 16 | `CompensationReasonID` | `—` | `—` | `runtime_lineage` |
| 17 | `WithdrawPaymentID` | `—` | `—` | `runtime_lineage` |
| 18 | `CommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 19 | `DepositID` | `—` | `—` | `runtime_lineage` |
| 20 | `FullCommission` | `—` | `—` | `runtime_lineage` |
| 21 | `FullCommissionOnClose` | `—` | `—` | `runtime_lineage` |
| 22 | `RedeemID` | `—` | `—` | `runtime_lineage` |
| 23 | `RedeemStatus` | `—` | `—` | `runtime_lineage` |
| 24 | `IsRedeem` | `—` | `—` | `runtime_lineage` |
| 25 | `ReopenForPositionID` | `—` | `—` | `runtime_lineage` |
| 26 | `IsReOpen` | `—` | `—` | `runtime_lineage` |
| 27 | `CommissionOnCloseOrig` | `—` | `—` | `runtime_lineage` |
| 28 | `FullCommissionOnCloseOrig` | `—` | `—` | `runtime_lineage` |
| 29 | `OriginalPositionID` | `—` | `—` | `runtime_lineage` |
| 30 | `IsPartialCloseParent` | `—` | `—` | `runtime_lineage` |
| 31 | `IsPartialCloseChild` | `—` | `—` | `runtime_lineage` |
| 32 | `PaymentStatusID` | `—` | `—` | `runtime_lineage` |
| 33 | `IsDiscounted` | `—` | `—` | `runtime_lineage` |
| 34 | `IsSettled` | `—` | `—` | `runtime_lineage` |
| 35 | `CommissionByUnits` | `—` | `—` | `runtime_lineage` |
| 36 | `FullCommissionByUnits` | `—` | `—` | `runtime_lineage` |
| 37 | `IsFTD` | `—` | `—` | `runtime_lineage` |
| 38 | `IsFeeDividend` | `—` | `—` | `runtime_lineage` |
| 39 | `IsAirDrop` | `—` | `—` | `runtime_lineage` |
| 40 | `DividendID` | `—` | `—` | `runtime_lineage` |
| 41 | `MoveMoneyReasonID` | `—` | `—` | `runtime_lineage` |
| 42 | `SettlementTypeID` | `—` | `—` | `runtime_lineage` |
| 43 | `etr_y` | `—` | `—` | `runtime_lineage` |
| 44 | `etr_ym` | `—` | `—` | `runtime_lineage` |
| 45 | `etr_ymd` | `—` | `—` | `runtime_lineage` |
| 46 | `DLTOpen` | `—` | `—` | `runtime_lineage` |
| 47 | `DLTClose` | `—` | `—` | `runtime_lineage` |
| 48 | `OpenMarkupByUnits` | `—` | `—` | `runtime_lineage` |
| 49 | `Description` | `—` | `—` | `runtime_lineage` |
| 50 | `IsBuy` | `—` | `—` | `runtime_lineage` |
| 51 | `CreditID` | `—` | `—` | `runtime_lineage` |
| 52 | `OpenDateID` | `—` | `—` | `runtime_lineage` |
| 53 | `CloseDateID` | `—` | `—` | `runtime_lineage` |
| 54 | `TicketFeeAction` | `—` | `—` | `runtime_lineage` |
| 55 | `RollOverFee` | `—` | `—` | `runtime_lineage` |
| 56 | `Dividend` | `—` | `—` | `runtime_lineage` |
| 57 | `SDRT` | `—` | `—` | `runtime_lineage` |
| 58 | `AdminFee` | `—` | `—` | `runtime_lineage` |
| 59 | `SpotAdjustFee` | `—` | `—` | `runtime_lineage` |
| 60 | `ConversionFeeDeposit` | `—` | `—` | `runtime_lineage` |
| 61 | `ConversionFeeWithdraw` | `—` | `—` | `runtime_lineage` |
| 62 | `ConversionFeeReversal` | `—` | `—` | `runtime_lineage` |
| 63 | `CashoutFeeExludingRedeem` | `—` | `—` | `runtime_lineage` |
| 64 | `TransferCoinFee` | `—` | `—` | `runtime_lineage` |
| 65 | `DormantFee` | `—` | `—` | `runtime_lineage` |
| 66 | `ShareLendingFeeEtoroShare` | `—` | `—` | `runtime_lineage` |
| 67 | `ShareLendingFeeUserShare` | `—` | `—` | `runtime_lineage` |
| 68 | `ShareLendingFeeBrokerShare` | `—` | `—` | `runtime_lineage` |
| 69 | `ShareLendingGrossAmount` | `—` | `—` | `runtime_lineage` |
| 70 | `CashoutAdjustment` | `—` | `—` | `runtime_lineage` |
| 71 | `NewCopyAmount` | `—` | `—` | `runtime_lineage` |
| 72 | `StopCopyAmount` | `—` | `—` | `runtime_lineage` |
| 73 | `AddToCopyAmount` | `—` | `—` | `runtime_lineage` |
| 74 | `RemoveFromCopyAmount` | `—` | `—` | `runtime_lineage` |
| 75 | `CryptoToPosition` | `—` | `—` | `runtime_lineage` |
| 76 | `BonusCompensation` | `—` | `—` | `runtime_lineage` |
| 77 | `PnLAdjustment` | `—` | `—` | `runtime_lineage` |
| 78 | `InvestedAmountIn` | `—` | `—` | `runtime_lineage` |
| 79 | `InvestedAmountOut` | `—` | `—` | `runtime_lineage` |
| 80 | `VolumeOpen` | `—` | `—` | `runtime_lineage` |
| 81 | `VolumeClose` | `—` | `—` | `runtime_lineage` |
| 82 | `TicketFeeOpen` | `—` | `—` | `runtime_lineage` |
| 83 | `TicketFeeClose` | `—` | `—` | `runtime_lineage` |
| 84 | `FullCommissionCloseAdjustment` | `—` | `—` | `runtime_lineage` |
| 85 | `CommissionCloseAdjustment` | `—` | `—` | `runtime_lineage` |
| 86 | `FullCommissionTotal` | `—` | `—` | `runtime_lineage` |
| 87 | `CommissionTotal` | `—` | `—` | `runtime_lineage` |
| 88 | `IsActiveTrade` | `—` | `—` | `runtime_lineage` |
| 89 | `IsSQF` | `—` | `—` | `runtime_lineage` |
| 90 | `Is_245_Instrument` | `—` | `—` | `runtime_lineage` |
| 91 | `IsCopyFund` | `—` | `—` | `runtime_lineage` |
| 92 | `ParentCID` | `—` | `—` | `runtime_lineage` |
| 93 | `ParentUserName` | `—` | `—` | `runtime_lineage` |
| 94 | `IsOpenFromIBAN` | `—` | `—` | `runtime_lineage` |
| 95 | `IsClosedToIBAN` | `—` | `—` | `runtime_lineage` |
| 96 | `IsRecurring` | `—` | `—` | `runtime_lineage` |
| 97 | `IsC2P` | `—` | `—` | `runtime_lineage` |
| 98 | `UpdateDate` | `—` | `—` | `runtime_lineage` |
