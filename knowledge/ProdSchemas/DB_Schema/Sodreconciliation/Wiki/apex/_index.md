# apex Schema - Sodreconciliation

> Apex Clearing broker-dealer extract/feed tables. Stores daily SOD (Start-of-Day) file data from Apex Clearing Corporation, including account master, trade activity, position activity, cash activity, security master, corporate actions, and various regulatory and operational reports.

## Metrics

| Metric | Value |
|--------|-------|
| **Total Objects** | 31 |
| **Documented** | 31 (100%) |
| **Pending** | 0 |
| **Last Updated** | 2026-04-11 |

---

## Tables (30)

| Object | Quality | Status |
|--------|---------|--------|
| [apex.SodFiles](Tables/apex.SodFiles.md) | 9.4 | Done (Batch 1) |
| [apex.EXT001_EasyToBorrowList](Tables/apex.EXT001_EasyToBorrowList.md) | 8.4 | Done (Batch 1) |
| [apex.EXT1027_TaxLotDetail](Tables/apex.EXT1027_TaxLotDetail.md) | 8.0 | Done (Batch 1) |
| [apex.EXT1032_DistributionAdjustments](Tables/apex.EXT1032_DistributionAdjustments.md) | 8.0 | Done (Batch 1) |
| [apex.EXT1033_RMDReport](Tables/apex.EXT1033_RMDReport.md) | 8.0 | Done (Batch 1) |
| [apex.EXT1034_NewAccountFinancialInformation](Tables/apex.EXT1034_NewAccountFinancialInformation.md) | 8.0 | Done (Batch 1) |
| [apex.EXT1035_IRABeneficiary](Tables/apex.EXT1035_IRABeneficiary.md) | 8.0 | Done (Batch 1) |
| [apex.EXT1036_W8Recertification](Tables/apex.EXT1036_W8Recertification.md) | 8.0 | Done (Batch 1) |
| [apex.EXT1043_LargeTraderIds](Tables/apex.EXT1043_LargeTraderIds.md) | 8.0 | Done (Batch 1) |
| [apex.EXT1047_RevenueReports](Tables/apex.EXT1047_RevenueReports.md) | 8.0 | Done (Batch 1) |
| [apex.EXT235_MandatoryCorporateActions](Tables/apex.EXT235_MandatoryCorporateActions.md) | 8.0 | Done (Batch 1) |
| [apex.EXT236_VoluntaryCorporateActions](Tables/apex.EXT236_VoluntaryCorporateActions.md) | 8.0 | Done (Batch 1) |
| [apex.EXT250_MarginCallReport](Tables/apex.EXT250_MarginCallReport.md) | 8.0 | Done (Batch 1) |
| [apex.EXT538_ClosedAccounts](Tables/apex.EXT538_ClosedAccounts.md) | 8.0 | Done (Batch 1) |
| [apex.EXT590_DailyExerciseAssignmentFile](Tables/apex.EXT590_DailyExerciseAssignmentFile.md) | 8.0 | Done (Batch 1) |
| [apex.EXT596_TradesMovedToAnErrorAccount](Tables/apex.EXT596_TradesMovedToAnErrorAccount.md) | 8.0 | Done (Batch 1) |
| [apex.EXT747_SecurityMaster](Tables/apex.EXT747_SecurityMaster.md) | 8.4 | Done (Batch 1) |
| [apex.EXT765_AccountMaster](Tables/apex.EXT765_AccountMaster.md) | 8.0 | Done (Batch 1) |
| [apex.EXT869_CashActivity](Tables/apex.EXT869_CashActivity.md) | 8.0 | Done (Batch 1) |
| [apex.EXT870_StockActivity](Tables/apex.EXT870_StockActivity.md) | 8.0 | Done (Batch 1) |
| [apex.EXT871_PositionActivity](Tables/apex.EXT871_PositionActivity.md) | 8.4 | Done (Batch 1) |
| [apex.EXT872_TradeActivity](Tables/apex.EXT872_TradeActivity.md) | 8.4 | Done (Batch 1) |
| [apex.EXT901_BalanceCashAndBalanceMarginDumpReport](Tables/apex.EXT901_BalanceCashAndBalanceMarginDumpReport.md) | 8.0 | Done (Batch 1) |
| [apex.EXT902_SecurityOverride](Tables/apex.EXT902_SecurityOverride.md) | 8.0 | Done (Batch 1) |
| [apex.EXT922_DividendReport](Tables/apex.EXT922_DividendReport.md) | 8.0 | Done (Batch 1) |
| [apex.EXT981_BuyPowerSummary](Tables/apex.EXT981_BuyPowerSummary.md) | 8.0 | Done (Batch 1) |
| [apex.EXT982_BuyPowerDetail](Tables/apex.EXT982_BuyPowerDetail.md) | 8.0 | Done (Batch 1) |
| [apex.EXT986_DailyPostMasterReturnedMail](Tables/apex.EXT986_DailyPostMasterReturnedMail.md) | 8.0 | Done (Batch 1) |
| [apex.EXT989_DailyElectronicCommunicationPreferenceExtract](Tables/apex.EXT989_DailyElectronicCommunicationPreferenceExtract.md) | 8.0 | Done (Batch 1) |
| [apex.EXT997_AmountAvailableDetail](Tables/apex.EXT997_AmountAvailableDetail.md) | 8.0 | Done (Batch 1) |

## Stored Procedures (1)

| Object | Quality | Status |
|--------|---------|--------|
| [apex.GetClosedAccounts](Stored%20Procedures/apex.GetClosedAccounts.md) | 8.0 | Done (Batch 1) |

## Cross-Schema Dependencies

| Object | Schema | Quality | Status |
|--------|--------|---------|--------|
| [dict.SodFileProcessingStatuses](../dict/Tables/dict.SodFileProcessingStatuses.md) | dict | 9.2 | Done (Batch 1) |
