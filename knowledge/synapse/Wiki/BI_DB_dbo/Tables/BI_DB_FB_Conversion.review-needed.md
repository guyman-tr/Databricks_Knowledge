# Review Needed: BI_DB_dbo.BI_DB_FB_Conversion

Generated: 2026-04-22 | Reviewer: —

## Tier 4 Items (Unverified — Human Review Required)

None — all columns are Tier 2 (sourced from SP_FB_Perf_Conv and external table structure).

## Questions for SME

1. **Feed retirement intent**: The Fivetran Facebook Ads feed stopped after 2026-01-07 (last ETL run 2026-01-15). Is this a permanent retirement (Fivetran connector decommissioned) or a temporary outage? If permanent, should this table be deprecated and its UC migration status updated from `_Not_Migrated` to `_Deprecated`?

2. **V2 custom event ID stability**: The `V2` column maps to Facebook custom event ID `384730099048186` (`offsite_conversion.custom.384730099048186`). If the Facebook pixel is ever reconfigured, this ID would silently produce zero V2 counts without any ETL error. Is there a pixel configuration audit trail that ties this ID to the eToro L2 verification event permanently?

3. **`_1_d_view` intentionally excluded**: The source external table (`facebook_conversion_actions`) contains a `_1_d_view` (1-day view-through) column, but `SP_FB_Perf_Conv` only uses `_7_d_click`. Was the view-through attribution deliberately excluded from this table, or is it an oversight? (View-through attribution is commonly reported alongside click attribution for awareness campaigns.)

4. **45% zero-conversion rows**: Approximately 45% of the 238K rows have all three conversion columns at 0 (Registration=0, V2=0, FTD=0). These are ads that ran but generated no attributed conversions. Confirm this is expected and that these rows serve a purpose (e.g., as a denominator for CTR or spend calculations in `SP_FB_Report`) — or whether they should be filtered at INSERT to reduce table size.

5. **Joined to FB_Performance in SP_FB_Report via FULL OUTER JOIN**: The downstream `SP_FB_Report` uses a FULL OUTER JOIN between `BI_DB_FB_Conversion` and `BI_DB_FB_Performance`. Were there ad_id × date rows that appeared in one table but not the other (beyond the zero-conversion case)? A FULL OUTER JOIN suggests the two tables may have diverging coverage — is this by design or a defensive coding pattern?

## Corrections Log

No corrections applied.

## Pipeline Flags

- **UC Target**: `_Not_Migrated` — feed is INACTIVE; review whether migration or deprecation is appropriate.
- **Feed status**: Fivetran Facebook Ads conversion feed stopped 2026-01-07; last ETL run 2026-01-15.
- **Downstream consumer**: `SP_FB_Report` (FULL OUTER JOIN with `BI_DB_FB_Performance`) — if this report is no longer being refreshed, this table's effective end-of-life should be formally documented.
