# Review Needed — Dealing_Marex_Recon_EODHoldings

**Generated**: 2026-03-21
**Quality Score**: 7.3/10

## Items for Human Review

1. **Google Sheets mapping table update process** — `External_Bronze_Fivetran_google_sheets_marex_mapping_table` is the source of InstrumentID for all Marex contracts. Confirm who maintains this sheet, how frequently it is reviewed for new contracts, and what the escalation process is when unmapped contracts appear in production.

2. **LP_EdnF_CorePosition vs LP_EdnF_CoreBalance** — Both tables are referenced by SP_Marex_Recon. Confirm the exact role of each: which provides net position (units), which provides balance/value, and whether they share the same Account + Contract granularity.

3. **Temporal netting history** — eToro side uses `etoro_Hedge_Netting` for current config and `History_Netting_History` for historical records. Confirm the exact join logic (date range or effective date) and whether there are cases where no netting record exists for a given date (e.g., new instruments).

4. **DateToDateID() UDF** — SP uses a custom `DateToDateID()` function for date conversion. Confirm this function is stable and has no edge-case behaviour around month boundaries, quarter ends, or public holidays that could affect reconciliation dates.

5. **Column name `Currency` vs `CurrencyPrimary`** — This table uses `Currency` while all other LP recon tables use `CurrencyPrimary`. Confirm whether this is intentional and whether cross-LP queries in dashboards account for the column name difference.

## Reviewer Corrections

_None yet._
