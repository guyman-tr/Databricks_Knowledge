---
object_fqn: main.bridgeclaw_permitted_data.appflyer_reports
object_type: VIEW
schema: bridgeclaw_permitted_data
generator: one-shot AppsFlyer deployment
column_count: 33
generated_at: '2026-06-10'
underlying_table: main.de_output.de_output_appsflyer_silver_reports
filter: dateid > 20260531
---

# bridgeclaw_permitted_data.appflyer_reports (VIEW)

> Permissioned PII-safe view over the AppsFlyer mobile-attribution silver fact. 33-column subset of `main.de_output.de_output_appsflyer_silver_reports`, filtered `dateid > 20260531`.

## Source

```sql
SELECT
  DateID, EtoroReport, EventSource,
  AppsFlyerID, CustomerUserID,
  EventTime, InstallTime,
  Partner, MediaSource, Channel,
  Campaign, CampaignID, Adset, AdsetID, Ad, AdID, AdType,
  Region, CountryCode,
  Platform, DeviceType, OSVersion, AppVersion,
  EventName, EventValue, EventRevenue, EventRevenueUSD,
  Date,
  CostModel, CostValue, CostCurrency,
  IsRetargeting, RetargetingConversionType
FROM main.de_output.de_output_appsflyer_silver_reports
WHERE dateid > 20260531;
```

## Columns excluded from the silver fact (and why it matters)

The view drops:
- **Location detail**: `State`, `City`, `PostalCode`, `DMA`, `IP` — likely PII redaction for permissioned consumers.
- **Device-network**: `WIFI`, `Operator`, `Carrier`, `Language`.
- **Sub-params**: all 5 `SubParam1..5`.
- **Most device IDs**: `AdvertisingID`, `IDFA`, `IDFV`, `AndroidID`, `IMEI` (only `AppsFlyerID` + `CustomerUserID` survive).
- **HTTP attribution metadata**: `HTTPReferrer`, `OriginalURL`, `UserAgent`, `IsReceiptValidated`, `AttributionLookback`, `ReengagementWindow`, `IsPrimaryAttribution`.
- **Multi-touch contributors**: all 15 `Contributor1/2/3*` columns.
- **eToro pipeline app fields**: `EtoroAppID`, `EtoroAppName` (Platform / AppID retained).
- **AppsFlyer SDK metadata**: `SDKVersion`, `AppID`, `AppName`, `BundleID`, `Keywords`.

## What this view IS suitable for

- KPI dashboards keyed on `MediaSource × Campaign × Date × Platform`
- Funnel counts by `EventName` (use `_S2S` suffix for revenue / FTD analytics)
- Cohort retention via `InstallTime` and `EventName`
- Per-CID rollups via the `CustomerUserID` direct join (no need for the `bronze_marketperformance_tracking_customer` bridge if the consumer can stomach the empty-on-Installs gap)

## What this view IS NOT suitable for

- Device-level cohorting (no `IDFA` / `IDFV` / `AdvertisingID` / `AndroidID`)
- Multi-touch / view-through attribution (no `Contributor1/2/3*`)
- Geo deep-dives (no `City` / `State` / `PostalCode` / `DMA` / `IP`)
- Cost-per-install analytics needing carrier / wifi context

For any of the above, use the underlying silver fact directly (where access permits).

## Filter contract: `dateid > 20260531`

The view definition hard-codes a forward-cutover guard. Per user instruction this is **a one-off setup** - someone preferred silver as the source for this permissioned face. Do **not** read it as a strategic deprecation of the gold mirror. Past dates remain queryable on `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports`.

*Generated 2026-06-10 - one-shot AppsFlyer deployment.*
