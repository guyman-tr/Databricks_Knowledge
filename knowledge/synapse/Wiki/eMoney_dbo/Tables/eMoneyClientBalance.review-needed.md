# Review Needed: eMoney_dbo.eMoneyClientBalance

**Generated**: 2026-04-20 | **Batch**: 8 | **Object type**: Table

## Status

**FLAGGED**: SSDT DDL is stale (45 cols vs 72 live). Multiple NULL-population patterns require analyst awareness. All items are infrastructure/data-age related — no upstream source gaps.

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | **SSDT DDL stale — 45 cols in repo vs 72 live** | HIGH | The Dataplatform SSDT DDL (eMoney_dbo.eMoneyClientBalance.sql) has 45 columns. Live table has 72. The 27 additional columns (CrossExchangeRate, ExchangeRate, OpeningBalanceRepCur, OpeningPositiveBalanceRepCur, FX, PositiveFX, 16× {TxFlow}RepCur, ClosingBalanceCalcRepCur, ClosingBalanceGAPRepCur, ClosingNegativeBalanceBORepCur, NegativeBalanceMovementRepCur, ClosingPositiveBalanceBORepCur, ClosingPositiveBalanceCalcRepCur, ClosingPositiveBalanceGAPRepCur, PriceFX, FXGAP) were added via ALTER TABLE on 2026-01-20. Additionally, ClosingBalanceBORepCur has decimal(16,6) in SSDT but decimal(24,12) in live (DROP + re-ADD on 2026-01-20). Update SSDT DDL to reflect live schema before UC migration. |
| 2 | **~966M rows with NULL HolderCurrency, ReportingCurrency, and all RepCur columns** | MEDIUM | Rows loaded before 2026-01-20 have NULL for HolderCurrency, ReportingCurrency, and all 22 RepCur/FX columns. Entity is set for these rows (eToro Money Malta/UK), but the full RepCur data is absent. For time-series RepCur analysis, apply `WHERE BalanceDate >= '2026-01-20'`. Consider a backfill job to populate RepCur columns for historical rows if needed for long-term trend reporting. |
| 3 | **~966M rows with NULL IsTest** | LOW | IsTest was added to the table after initial load (~Sep 2025 per AUS entity launch). Rows from 2023-12-29 through ~Sep 2025 have NULL IsTest. The SP uses `ISNULL(COALESCE(IsTestAccount, ...), 0)`, so any newly loaded rows will be 0 or 1. Historical rows remain NULL. Analysts must use `ISNULL(IsTest, 0) = 0` to correctly filter for production accounts across the full date range. |
| 4 | **131 rows with Entity='New'** | LOW | 131 rows across the entire table have Entity='New', meaning their CurrencyIson was not found in eMoney_EntityByCurrencyISO_MappingStatic. These rows also have NULL HolderCurrency/ReportingCurrency. Investigate whether these represent a new currency/entity being piloted or orphaned legacy records. |
| 5 | TransOutOfDate systematically non-zero | INFO | Late-arriving transactions (TransactionDateTime date ≠ BalanceDate) contribute to ClosingBalanceGAP. This is expected behavior (Tribe files can have timing differences). The SP flags these in two separate alert SPs: SP_eMoney_Client_Balance_Check_Opening_Balance and SP_eMoney_Client_Balance_Check_Exceptions_Gap. No action needed unless GAP volumes are abnormal. |
| 6 | UpdateDate = GETDATE() — no BalanceDate-parameterized timestamp | INFO | UpdateDate is the SP execution timestamp, not the business date. For historical backfills, all rows in a backfill run will show the same UpdateDate regardless of their BalanceDate. This makes UpdateDate unreliable for change tracking in backfill scenarios. Confirm if this is acceptable for audit requirements. |

## Tier 4 Items

None — prior T4 flag on IsExistingUser resolved. Confirmed from SP line 706:
`CASE WHEN COALESCE(d.GCID, d1.GCID) IS NULL THEN 0 ELSE 1 END IsExistingUser`

All 72 columns are Tier 2 (derived from SP_eMoney_ClientBalance code).

## Reviewer Confirmation Needed

- [ ] **PRIORITY**: Update SSDT DDL to 72 columns before UC migration planning
- [ ] Confirm whether historical RepCur NULL backfill is needed for long-term FX trend reporting
- [ ] Confirm Entity='New' (131 rows) source — orphan or new currency pilot?
- [ ] Confirm ISNULL(IsTest, 0) pattern is standard in all downstream queries using this table
- [ ] Confirm SP_eMoney_ClientBalance is in the daily orchestration pipeline with correct dependency ordering (ETL stages must complete before SP runs)

*Sidecar generated: 2026-04-20 | Quality: 9.0/10 | Phases completed: P1, P2, P3, P8, P9, P10B, P11, P16*
