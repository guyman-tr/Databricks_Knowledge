# Review Needed — BI_DB_DailyCommisionReport_Yesterday

**Generated**: 2026-04-22 | **Batch**: 22 | **Reviewer**: TBD

## Tier 4 Items (Needs Confirmation)

1. **CommissionInRisk (ghost column)**: DDL has `[CommissionInRisk] [money] NULL` but the SP INSERT list at lines 1265–1289 does not include it. Verified as always NULL from live sample (2026-04-12: all CommissionInRisk values = empty/NULL). Tier 4 assigned. Reviewer should confirm this has never been populated and can be ignored in analysis.

## Open Questions for Reviewer

1. **CommissionInRisk intent**: Was CommissionInRisk added to Yesterday (and ThisMonth, ThisYear) DDL at the same time as Last2weeks/LastYear? If so, was it always intentionally excluded from the SP INSERT? Is there a planned future use?

2. **Single-date scope**: The table always holds exactly yesterday's data. Does the business use this for "today's preliminary" reporting or strictly for "previous close day" analysis? If the SP runs multiple times per day, the table reflects the latest run only.

3. **InstrumentType distribution variability**: Crypto was 53% of rows on 2026-04-12 — is this typical? Commodities at 36% seems high. Are there known high-activity days in these asset classes?

4. **UpdateDate NULL**: DDL allows NULL for UpdateDate (unlike MonthlyData which has NOT NULL). Has UpdateDate ever been NULL? Is there a historical window before GETDATE() was added to the INSERT?

## Auto-Confirmed Items

- All 26 DDL columns documented (25 active + 1 ghost CommissionInRisk)
- SP INSERT covers 24 active columns confirmed at lines 1265–1289
- Live data sampled: 2026-04-12, 76,089 rows, 70,131 CIDs
- CommissionInRisk confirmed NULL in live sample
- No downstream consumers in SSDT repo (terminal output)
- Mifid distribution confirmed: Retail (66%), Retail Pending (33%), Pending+Professional (<1%)
