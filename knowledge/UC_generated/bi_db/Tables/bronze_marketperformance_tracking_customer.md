---
object_fqn: main.bi_db.bronze_marketperformance_tracking_customer
object_type: EXTERNAL
schema: bi_db
generator: one-shot AppsFlyer deployment
column_count: 11
row_count: 48021494
distinct_cids: 48021494
generated_at: '2026-06-10'
upstreams:
- marketperformance pipeline (DataPlatform)
downstreams:
- main.de_output.de_output_appsflyer_silver_reports (joined on AppsflyerID)
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports (joined on AppsflyerID)
needs_review:
- DeviceTypeID enum (1 / 2 / 3 - mapping unknown)
- PartitionCol semantics (0-9 + one -1; presumed hash)
- UserUniqueIdentifierCookie (web cookie ID? sparse 18%)
- AdditionalData (sparse 2%, content schema unknown)
- iOSAdTrackingPermissionID full enum (only 0 / 1 observed)
---

# bronze_marketperformance_tracking_customer

> CID-to-mobile-device-identity bridge for AppsFlyer attribution. 48M rows, 1 row per CID. Joins to the AppsFlyer fact (silver or gold) on AppsflyerID = AppsFlyerID (note vendor lowercase-f spelling on this side).

## Why this table exists

On the AppsFlyer fact tables, `CustomerUserID` is **null on Installs and OrganicInstalls** because no CID exists pre-registration. To roll mobile-attributed events up to a CID across the full lifecycle (install -> registration -> KYC -> FTD), join through this bridge on `AppsflyerID`.

## Coverage

| Field | Populated rows | % of 48M CIDs |
|---|---:|---:|
| `AppsflyerID` | 20.9M | 43% (CIDs who registered via OneApp mobile) |
| `FirebaseID` | 9.3M | 19% |
| `UserUniqueIdentifierCookie` | 8.9M | 18% |
| `IDFV` | 1.4M | 3% (iOS-only post-ATT) |
| `iOSAdTrackingPermissionID = 1` | 1.3M | 3% (ATT-Authorized share) |
| `AdditionalData` | 1.0M | 2% (sparse) |

## Five fields that need review

The user explicitly requested no speculation on these. Comments capture only observed values:

- **`DeviceTypeID`** (INT) — three values: 1 (~27M), 2 (~10.1M), 3 (~10.9M). The split does NOT match the AppsFlyer Platform split (~75% Android / ~23% iOS), so it's NOT a one-to-one Platform code.
- **`PartitionCol`** (INT) — 0-9 (~4.8M each) + one `-1` row. Looks like upstream hash distribution metadata.
- **`UserUniqueIdentifierCookie`** (STRING) — sparse 18% population. Name suggests a web-tracking cookie ID for cross-device CID resolution.
- **`AdditionalData`** (STRING) — sparse 2% population. Content schema unknown.
- **`iOSAdTrackingPermissionID`** (INT) — only `0` (97%) and `1` (3%) observed; the 4-value Apple ATTrackingManager enum (NotDetermined / Restricted / Denied / Authorized) is not represented at this storage grain.

## Canonical join

```sql
SELECT mp.CID, mp.GCID, a.EventName, a.EventRevenueUSD, a.MediaSource, a.Date
FROM main.de_output.de_output_appsflyer_silver_reports a
JOIN main.bi_db.bronze_marketperformance_tracking_customer mp
  ON a.AppsFlyerID = mp.AppsflyerID
WHERE a.EtoroReport = 'InAppEvents'
  AND a.EventSource IN ('SDK','S2S')
  AND a.EventName IN ('FTD_S2S','Registration_S2S','Open Trade')
  AND a.Date >= DATE'2026-05-01';
```

*Generated 2026-06-10 - one-shot AppsFlyer deployment grounded in `proposals/AppsFlyer_Fields.pdf`. Five columns flagged NEEDS REVIEW per user instruction.*
