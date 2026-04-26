# Review Notes: BI_DB_dbo.BI_DB_RollOverFee_ByInstrument

**Generated**: 2026-04-22 | **Batch**: 34 | **Quality**: 8.8/10

## Tier 4 / Uncertain Items

None — all 19 columns traced to known sources in SP_DailyCommisionReport and parent table BI_DB_DailyCommisionReport.

## Questions for SME Review

1. **TradingFees definition**: SP change history says "TradingFee = Ticket Fee + Islamic Fee" (2024-02-25 Artyom Bogomolsky). The wiki says "TradingFee = TicketFee + AdminFee" based on column semantics. Is AdminFee the same as the "Islamic Fee" referenced in the SP comment? Or is Islamic Fee a distinct concept from AdminFee?

2. **RollOverFee_SDRT**: Is this only for FCA/UK-regulated stock positions, or does it apply to other regulations as well? Sample shows it's near-zero for non-FCA rows, but clarification would strengthen the documentation.

3. **NA InstrumentType**: 32 rows with InstrumentType='NA' found in 2026 YTD. Are these expected (legacy instruments) or an ETL bug to investigate?

4. **No downstream consumers**: OpsDB and SSDT scan found no SPs referencing `BI_DB_RollOverFee_ByInstrument`. Confirmed as a reporting leaf. If there are dashboard/BI tool consumers not visible in SSDT, they should be noted.

## Corrections Applied

- None required. All columns confirmed from SP code.

## Ghost Columns

None identified. All 19 DDL columns are present in the SP INSERT list.
