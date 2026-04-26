# AML_InstrumentMetaData_Daily_Email — Review Notes

**Generated**: 2026-04-23
**Reviewer**: —

## Items Needing Human Verification

1. **Row count accuracy**: Sample taken 2026-04-23 showed 12,124 rows. Verify this is representative of the typical daily volume and not an anomaly.

2. **OpsDB orchestration**: Listed as P0 (base layer). Confirm exact daily frequency and whether the SP runs on weekends/holidays.

3. **ISIN validity filter completeness**: The SP filters `TRIM(LOWER(ISINCode)) NOT IN ('', 'null', '0', 'na', 'n.a', 'n.a.')`. Confirm this list is exhaustive — no other known invalid patterns?

4. **InstrumentDisplayName NULL rate**: The DDL allows NULL. Confirm whether any rows in practice have NULL InstrumentDisplayName (no live NULL count taken — COUNT(*) without column breakdown).

5. **Downstream consumers**: Only the AML daily email process and sibling DayToDay_Changes table were identified. Confirm no other BI reports, Power BI dashboards, or Salesforce integrations consume this table.

6. **ISIN sharing upper bound**: Up to 4 instruments per ISIN observed. Confirm this is the expected maximum or document any exceptions.

## Quality Score

9.0/10 — Simple 3-column reference table. All columns Tier 1 from DWH_dbo.Dim_Instrument wiki. Business meaning clear and specific. Data evidence strong (12,124 rows, ISIN distribution, SP filter documented). Minor deductions: no Confluence documentation found; downstream consumer list may be incomplete.
