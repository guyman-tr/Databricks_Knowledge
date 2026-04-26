# Review Flags: BI_DB_Compliance_VP_Monthly_MI

## Flag 1 — "Monthly MI" Misnomer (SOFT)
Despite the table name including "Monthly MI", there is no monthly date filter in the SP. All historical trade actions are aggregated. The "monthly" refers to when Compliance presents this as MI, not a data window. Downstream consumers expecting monthly data will get all-time figures.

## Flag 2 — TradesExecuted Double-Counts (SOFT)
`TradesExecuted` aggregates both opens (ActionTypeID 1-3) and closes (ActionTypeID 4-6). A complete round-trip trade = 2 towards this count. Compliance consumers should be aware that `TradesExecuted / 2 ≈ approximate number of positions`. This is by design but not documented in SP comments.

## Flag 3 — Net Notional Sign Logic (SOFT)
`NotionalAmount_*` columns use a sign-reversal pattern: opens are negative, closes are positive, then summed. This produces a net flow metric, not gross volume. For a client with many open positions still running, the result may be negative (open notional > close notional). The business interpretation of "net notional = regulatory exposure vs. realized flow" is not documented. Verify with Compliance team that this is the intended calculation.

## Flag 4 — Fivetran External Table Dependency (SOFT)
Table content is entirely driven by `External_Fivetran_google_sheets_vp_monthly_mi`, a Google Sheets document. No SP-side validation of the CID list. If the Fivetran sync fails, the table is truncated and reloaded from stale data. If a CID is removed from the Google Sheets list, that customer disappears from the table permanently.

## Flag 5 — UpdateDate NOT NULL datetime (INFO)
Unlike most BI_DB surveillance tables where UpdateDate is `varchar(50) NULL`, this table's UpdateDate is `datetime NOT NULL`. This is the only column with a NOT NULL constraint. Treat as a reliable datetime column for filtering.

## Flag 6 — Commented-Out Columns (INFO)
The SP has multiple columns commented out: Email, GCID, CountryOfCitizenship, CountryOfResidence, Language, Manager, Club, HasOpenPositions. These JOINs still execute in the #Final step (Dim_Country, Dim_Language, BI_DB_CIDFirstDates, #OpenPositions are all joined but results discarded). If the commented-out columns are ever needed, the SP infrastructure already supports them — they just need to be uncommented and added to the DDL/INSERT.
