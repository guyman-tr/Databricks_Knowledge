---
object: Dealing_Islamic_Daily_Spot_Price_Adjustment
schema: Dealing_dbo
review_status: Pending
batch: 14
---

# Review Checklist — Dealing_Islamic_Daily_Spot_Price_Adjustment

## Automated Confidence Flags

| Flag | Detail |
|------|--------|
| ⚠️ Fivetran dependency | SP skips entirely if External_Fivetran_dealing_overnight_fees missing — no retry/backfill. Alert written to Email table but depends on manual monitoring. |
| ⚠️ Sunday date shift | If @Date is Sunday, SP uses Friday's date instead. Risk of duplicate Friday rows if SP runs on both Sat and Monday. |
| ⚠️ 7 hardcoded instruments | InstrumentIDs 17, 22, 339–344 hardcoded in SP. New futures instruments require SP code change. |
| ℹ️ ExchangeID=0 | All rows have ExchangeID=0 (not joined from Dim_ExchangeInfo). This is intentional (Count_Fri applies universally), but differs from admin fee SP. |
| ℹ️ New table (2024) | Active since 2024-03-08 — no data before this date. Not a gap in data quality; the SP was new. |

## Questions for Reviewer

1. Is there a backfill mechanism when Fivetran data is missing? If Fivetran is down for a day, is that day's data permanently lost?
2. Who monitors `Dealing_Islamic_Daily_Spot_Price_Adjustment_Email`? Is it automated or manual?
3. Sunday date shift: is this deliberate to backfill Friday, or a scheduling artifact? Could it produce duplicate rows?
4. Process to add new futures instruments: is it always an SP code change, or is there a planned config table approach?
5. Fee_Type_ID=2 rows + Fee_Type_ID=1 rows for the same position: is there a combined fee table, or does client statement generation join both tables?

## Reviewer Corrections
<!-- Add corrections here. Format: FIELD: old value → new value. Mark [RESOLVED] when fixed. -->
