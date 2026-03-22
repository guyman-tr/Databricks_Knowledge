---
object: Dealing_EquityFees
schema: Dealing_dbo
review_status: Pending
batch: 14
---

# Review Checklist — Dealing_EquityFees

## Automated Confidence Flags

| Flag | Detail |
|------|--------|
| ⚠️ NULL InstrumentID | Recent rows (2026-03-09) have NULL InstrumentID — ISIN/SEDOL not matching Dim_Instrument. Is this a growing gap? |
| ⚠️ HedgeServerID IN (2,101) | Client NOP limited to CBH-hedged clients only. Confirm 2=CBH-US and 101=CBH-EU or similar. Other hedged clients excluded. |
| ⚠️ "Fianancing" typo | 4 column names contain typo from LP report. Confirm all downstream consumers (reports, dashboards) are using the typo spelling. |
| ⚠️ ISIN dedup | SP deduplicates by ISIN+Currency. If same stock listed in multiple currencies, only one entry per currency is retained — confirm this is correct behavior. |
| ℹ️ LP data availability | Table depends on Dealing_staging LP files. Late or missing LP drops will leave gaps. Confirm monitoring. |

## Questions for Reviewer

1. What are HedgeServerID 2 and 101 specifically? CBH-US and CBH-EU, or something else?
2. NULL InstrumentID rate: what percentage of rows have NULL InstrumentID, and is it increasing? Is this a mapping gap in Dim_Instrument?
3. Are there instruments where JP Morgan covers but GS does not (or vice versa)? Is a NULL on one side expected or a data quality issue?
4. "Fianancing" typo: are all reports, dashboards, and downstream queries using the typo spelling? Has anyone accidentally used "Financing" (correct) which would break joins?
5. Are there instruments with the same ISIN but different currencies where the dedup might incorrectly drop valid rows?

## Reviewer Corrections
<!-- Add corrections here. Format: FIELD: old value → new value. Mark [RESOLVED] when fixed. -->
