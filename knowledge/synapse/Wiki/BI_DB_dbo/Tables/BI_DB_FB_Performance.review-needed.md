# Review Needed: BI_DB_dbo.BI_DB_FB_Performance

Generated: 2026-04-22 | Reviewer: —

## Tier 4 Items (Unverified — Human Review Required)

None — all columns are Tier 2 (sourced from SP_FB_Perf_Conv and external table structure).

## Questions for SME

1. **device_platform deliberately excluded**: The source external table `External_Fivetran_facebook_facebook_preformance_new` contains a `device_platform` column (e.g., mobile_app, desktop, unknown), but `SP_FB_Perf_Conv` does NOT include it in the GROUP BY — all device rows are aggregated into a single row per (date × ad × campaign × account). Was this a deliberate decision to simplify the grain, or was device-level breakdown never required for the reporting use case? Any analytics need for device-split performance data must go to the external table directly.

2. **`eToro Account` excluded from SP_FB_Report**: The table stores 186K rows (31%) for `account_name = 'eToro Account'` (account_id: 106616956125095, $3.9M spend), but `SP_FB_Report` explicitly filters to `'eToro ALL 2 (Smartly)'` only. Is the `eToro Account` data still relevant? Was it superseded by the Smartly-managed account? Should the SP_FB_Perf_Conv ETL be updated to exclude the secondary account, or is there a separate reporting need for it?

3. **nvarchar(4000) → nvarchar(256) narrowing**: Five name columns (`ad_id`, `ad_name`, `adset_name`, `campaign_name`, `account_name`) are defined as nvarchar(4000) in the external table but narrowed to nvarchar(256) in this table. No truncation was observed in the live data, but if ad/campaign names exceed 256 characters in the future (e.g., after a naming convention change), data would be silently truncated without error. Should these be widened to nvarchar(512) or nvarchar(max) to be safe?

4. **Campaign name parsing fragility in SP_FB_Report**: `SP_FB_Report` derives Country and Funnel from `campaign_name` using `CHARINDEX('_', ...)` string splitting. If a campaign name has no underscore (CHARINDEX returns 0), the `ABS(0-1)` produces a LEFT(name, 1) result — a single character. If the naming convention changes (e.g., hyphens instead of underscores, or country code embedded elsewhere), all Country/Funnel derivations would silently produce incorrect values. Is there a formal campaign naming convention document or governance process?

5. **Feed retirement and reporting gap**: Both `BI_DB_FB_Performance` and `BI_DB_FB_Conversion` stopped updating after 2026-01-07. Given that `SP_FB_Report` and `BI_DB_FB_Report` are the downstream consumers, has Facebook Ads reporting been migrated to a new data source (e.g., direct API, new Fivetran connector, or Databricks)? If so, update UC Target from `_Not_Migrated` to `_Deprecated` and link to the replacement pipeline.

## Corrections Log

No corrections applied.

## Pipeline Flags

- **UC Target**: `_Not_Migrated` — feed is INACTIVE; review whether migration or deprecation is appropriate.
- **Feed status**: Fivetran Facebook Ads performance feed stopped 2026-01-07; last ETL run 2026-01-15.
- **Sibling table**: `BI_DB_FB_Conversion` written by block 2 of the same SP; both tables share the same lifecycle.
- **Downstream consumer**: `SP_FB_Report` uses Smartly account only (filter: account_name = 'eToro ALL 2 (Smartly)') — 31% of table rows (eToro Account) are effectively unused by the report.
