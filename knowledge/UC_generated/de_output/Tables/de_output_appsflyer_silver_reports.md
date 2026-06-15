---
object_fqn: main.de_output.de_output_appsflyer_silver_reports
object_type: EXTERNAL
schema: de_output
generator: one-shot AppsFlyer deployment
framework: uc-pipeline-doc
table_type: EXTERNAL
column_count: 86
row_count: 133906852
date_range: 2022-10-25 to live (yesterday)
generated_at: '2026-06-10'
upstreams:
- AppsFlyer Raw Data Export API
downstreams:
- main.bridgeclaw_permitted_data.appflyer_reports
- main.bi_db.bronze_marketperformance_tracking_customer (CID bridge, joined on AppsflyerID)
pdf_source: proposals/AppsFlyer_Fields.pdf
---

# de_output_appsflyer_silver_reports

> Silver-tier AppsFlyer mobile-attribution fact for the eToro OneApp Android / OneApp iOS apps. Schema is exactly 1:1 with the AppsFlyer Raw Data Export API (81 vendor-documented fields + 5 eToro pipeline-added fields). 133.9M rows, dates 2022-10-25 -> live (yesterday).

| Property | Value |
|---|---|
| **UC FQN** | `main.de_output.de_output_appsflyer_silver_reports` |
| **Type** | EXTERNAL Delta |
| **Columns** | 86 (81 AppsFlyer-documented + 5 eToro pipeline) |
| **Rows** | ~133.9M |
| **Date range** | 2022-10-25 -> live |
| **Source-of-truth** | AppsFlyer Raw Data Export API documentation (`proposals/AppsFlyer_Fields.pdf`) |
| **Permissioned face** | `main.bridgeclaw_permitted_data.appflyer_reports` (33-col view, filter `dateid > 20260531`) |
| **CID bridge** | `main.bi_db.bronze_marketperformance_tracking_customer` on `AppsflyerID` (note vendor lowercase-f spelling) |
| **bi_db gold sibling** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports` (89 cols - drops `IP`, adds `UpdateDate` + `etr_y/ym/ymd` partition cols) |

---

## 1. Business meaning

AppsFlyer is eToro's mobile-measurement partner (MMP). The OneApp Android (`com.etoro.openbook`) and OneApp iOS (`id674984916`) apps embed the AppsFlyer SDK, supplemented by server-to-server (S2S) postbacks from the eToro backend. The joined feed lands here in silver as the AppsFlyer Raw Data Export schema, preserving every vendor-documented field including `IP` (which the bi_db gold mirror drops at SP-load time).

This table is the **per-event fact**: each row is a single AppsFlyer raw-data-export record - either an install or a post-install in-app event. The three event classes share the schema but are partitioned by `EtoroReport`:

| EtoroReport | What it is | Approx volume on bi_db mirror |
|---|---|---|
| `OrganicInstalls` | Installs with no attributable paid touch (organic + SKAdNetwork-restricted) | ~86.5M |
| `Installs` | Paid / attributable installs | ~7.0M |
| `InAppEvents` | Post-install business events (trades, registrations, FTDs, redeposits, KYC) | ~37.8M |

**Always filter `EtoroReport`** - the three classes never sum cleanly. Counting installs without `EtoroReport IN ('Installs','OrganicInstalls')` triple-counts via InAppEvents that share an `InstallTime`.

---

## 2. Anchor concepts

### 2.1 SDK vs S2S event source

`EventSource` distinguishes SDK-reported events (`'SDK'` - AppsFlyer SDK on device) from server-to-server postbacks (`'S2S'` - eToro backend posts directly to AppsFlyer). Prefer `_S2S` events (e.g. `Registration_S2S`, `FTD_S2S`, `Redeposit_S2S`) for revenue / FTD / registration analysis - they survive ad-blockers, SDK init failures, and ATT opt-out.

**Always filter `EventSource IN ('SDK','S2S')`**: ~1M rows carry malformed JSON-fragment values (`""af_revenue"":""0""}"`, `USD`, `""is_copy"":""False""`) leaked from an upstream AppsFlyer export bug.

### 2.2 Multi-touch attribution chain

`AttributedTouch*` is the **last** touch that earned the install credit. `Contributor1/2/3*` are up to three earlier touches that contributed but did not win the attribution model:

```
Contributor3 (oldest)  ->  Contributor2  ->  Contributor1  ->  AttributedTouch (winner)
```

Each contributor slot carries `Partner`, `MediaSource`, `Campaign`, `TouchType` (click / impression), `TouchTime`. Use these for view-through analysis ("how often did Facebook contribute to a Google-attributed install?") and for cross-channel-credit redistribution. AppsFlyer documents this as a frequency limitation: the export records the final attributed touch and **up to 3** prior contributing touchpoints - it does not provide a full impression log.

### 2.3 EventName taxonomy (InAppEvents)

Top-volume eToro event names from the bi_db mirror, in row-count order:

| EventName | ~Rows | Type |
|---|---:|---|
| `Open Trade` | 26.0M | Position opened (SDK + S2S) |
| `Redeposit_S2S` | 2.4M | Repeat deposit (server-to-server) |
| `Registration_S2S` | 2.2M | Account registration (S2S) |
| `registration` | 1.9M | SDK-side registration (lowercase) |
| `Verification Level - 1` | 1.5M | KYC step 1 |
| `Verification Level - 2` | 1.2M | KYC step 2 |
| `Redeposit` | 1.1M | SDK-side redeposit |
| `Verification Level - 3` | 0.7M | KYC step 3 (FTD-eligible) |
| `FTD_S2S` | 272k | First-time deposit (S2S) |
| `FTD` | 204k | First-time deposit (SDK) |
| `FTDE_S2S` | 132k | First-time deposit (e - exchange variant, S2S) |

### 2.4 CID resolution

`CustomerUserID` is a hashed CID - eToro passes a hashed customer identifier to the AppsFlyer SDK at registration / login, so it can link AppsFlyer events back to eToro user accounts. **NULL on `Installs` and `OrganicInstalls`** (no CID exists pre-registration); ~26% of total bi_db rows carry a populated value. For per-CID rollups, prefer the bridge join:

```sql
SELECT mp.CID, a.EventName, a.EventRevenueUSD, a.MediaSource, a.Date
FROM main.de_output.de_output_appsflyer_silver_reports a
JOIN main.bi_db.bronze_marketperformance_tracking_customer mp
  ON a.AppsFlyerID = mp.AppsflyerID  -- vendor-lowercase-f spelling on the bridge
WHERE a.EtoroReport = 'InAppEvents'
  AND a.EventName = 'FTD_S2S'
  AND a.Date >= DATE'2026-05-01';
```

### 2.5 iOS14 ATT framework + identifier decline

Apple's App Tracking Transparency framework (iOS 14.5+, released 2021-04) requires per-app opt-in for IDFA. ~8% of total rows / ~36% of iOS rows have a real IDFA on the bi_db mirror. For iOS install attribution use `AppsFlyerID` (vendor's privacy-safe install-level ID) - not IDFA - as the primary device key. The `MediaSource = 'restricted'` bucket (~2.5M rows) is SKAdNetwork-aggregated attribution from iOS opt-out users.

---

## 3. Critical filters

| Filter | Why |
|---|---|
| `EtoroReport IN ('Installs','OrganicInstalls')` for install counts | The three classes never sum cleanly. |
| `EtoroReport = 'InAppEvents'` for in-app event counts | Avoid mixing with install-class rows where `EventName = 'install'`. |
| `EventSource IN ('SDK','S2S')` | Drops the ~1M rows with malformed JSON-fragment values. |
| `Platform IN ('android','ios','None')` | ~3M rows have GUID-shaped strings in Platform (looks like an IDFA leaked into the wrong column). |
| Use `_S2S` event names for revenue / FTD / registration | SDK twins under-count systematically. |

---

## 4. Source vs sibling layers

| Layer | Object | What it carries |
|---|---|---|
| Vendor source | AppsFlyer Raw Data Export API | 81 documented fields per row |
| eToro raw landing | `BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext` (Synapse, 130M+ rows, all-varchar) | Same 81 + 5 eToro fields, no normalisation |
| eToro Synapse cleaned | `BI_DB_dbo.BI_DB_AppFlyer_Reports` -> `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports` | 89 cols: 80 of 81 vendor (drops `IP`) + 5 eToro + `UpdateDate` (always NULL) + `etr_y/ym/ymd` partitions |
| **eToro silver (this table)** | `main.de_output.de_output_appsflyer_silver_reports` | **86 cols: full 81 vendor (incl `IP`) + 5 eToro. Cleanest 1:1 with the AppsFlyer documented schema.** |
| Permissioned face | `main.bridgeclaw_permitted_data.appflyer_reports` (VIEW) | 33-col subset of silver, filtered `dateid > 20260531` |

The silver and gold layers exist side by side. They are not declared a successor / predecessor in this project; the bridgeclaw view's choice of silver as its source is treated as a one-off, not a deprecation signal.

---

## 5. Column reference

See the alter.sql at `knowledge/UC_generated/de_output/Tables/de_output_appsflyer_silver_reports.alter.sql` - every column carries its canonical AppsFlyer-documented description (Tier 1) merged with eToro-side operational notes where relevant. The 5 custom eToro fields (`DateID`, `Date`, `EtoroAppID`, `EtoroAppName`, `EtoroReport`) are tagged Tier 2.

Field-family map:

| Family | Cols | PDF section |
|---|---:|---|
| Attribution & Touch | 8 | 1a + Attribution & Touch |
| Campaign & Creative (incl SubParam1-5) | 16 | 1a + Campaign & Creative |
| Cost | 3 | Cost |
| Event & Revenue | 8 | Event & Revenue |
| URL & Referrer | 3 | URL & Referrer |
| Location (incl `IP`) | 8 | Location |
| Device & Network | 9 | Device & Network |
| Device Identifiers | 7 | Device Identifiers |
| App | 3 | App |
| Multi-Touch Contributors | 15 | 1b + Multi-Touch |
| Custom eToro Fields | 5 | Custom eToro Fields |
| **Total** | **86** | |

---

## 6. Common queries

### 6.1 Daily installs, organic vs paid

```sql
SELECT Date, EtoroReport, COUNT(*) AS rows
FROM main.de_output.de_output_appsflyer_silver_reports
WHERE EtoroReport IN ('Installs','OrganicInstalls')
  AND Date BETWEEN DATE'2026-05-01' AND DATE'2026-05-31'
GROUP BY Date, EtoroReport
ORDER BY Date;
```

### 6.2 Install -> FTD funnel by MediaSource (last 30 days, S2S only)

```sql
WITH inst AS (
  SELECT MediaSource, AppsFlyerID, MIN(InstallTime) AS install_ts
  FROM main.de_output.de_output_appsflyer_silver_reports
  WHERE EtoroReport IN ('Installs','OrganicInstalls')
    AND InstallTime >= current_timestamp() - INTERVAL 30 DAYS
  GROUP BY MediaSource, AppsFlyerID
),
ftd AS (
  SELECT AppsFlyerID, MIN(Date) AS ftd_date
  FROM main.de_output.de_output_appsflyer_silver_reports
  WHERE EtoroReport = 'InAppEvents'
    AND EventName = 'FTD_S2S'
    AND EventSource IN ('SDK','S2S')
  GROUP BY AppsFlyerID
)
SELECT inst.MediaSource,
       COUNT(*) AS installs,
       COUNT(ftd.AppsFlyerID) AS ftds,
       100.0 * COUNT(ftd.AppsFlyerID) / COUNT(*) AS pct
FROM inst LEFT JOIN ftd USING (AppsFlyerID)
GROUP BY inst.MediaSource
ORDER BY installs DESC;
```

### 6.3 SDK vs S2S coverage on FTD events

```sql
SELECT Platform, EventSource, COUNT(*) AS rows
FROM main.de_output.de_output_appsflyer_silver_reports
WHERE EtoroReport = 'InAppEvents'
  AND EventName IN ('FTD','FTD_S2S')
  AND EventSource IN ('SDK','S2S')
  AND Platform IN ('android','ios')
  AND Date >= current_date() - INTERVAL 30 DAYS
GROUP BY Platform, EventSource
ORDER BY Platform, EventSource;
```

---

## 7. Critical warnings

1. **Tier 0 - Always filter `EtoroReport`.** The fact mixes three event classes that should never be summed together. Counting installs without `EtoroReport IN ('Installs','OrganicInstalls')` triple-counts via InAppEvents that share an InstallTime.

2. **Tier 0 - Always filter `EventSource IN ('SDK','S2S')`.** ~1M rows carry malformed JSON-fragment values from an upstream AppsFlyer export bug.

3. **Tier 0 - Prefer `_S2S` events for revenue / FTD / registration.** `Registration_S2S` / `FTD_S2S` / `FTDE_S2S` / `Redeposit_S2S` survive ad-blockers, SDK init failures, and ATT opt-out. SDK twins under-count systematically.

4. **Tier 1 - `CustomerUserID` is empty on installs.** No CID exists pre-registration. Use `bronze_marketperformance_tracking_customer.AppsflyerID` for CID rollups.

5. **Tier 1 - iOS14 ATT killed IDFA.** ~8% IDFA coverage post-2021. Use `AppsFlyerID` as the primary iOS device key.

6. **Tier 1 - `Date` != `InstallTime` on InAppEvents.** `Date` is event date; `InstallTime` is when the device first installed the app. Filter `Date` for event-period analysis, `InstallTime` for install cohorts.

7. **Tier 1 - `IsRetargeting` is always `false` or empty.** Zero rows with `IsRetargeting = 'true'` as of 2026-06. eToro is not running retargeting / re-engagement campaigns through the MMP integration. Same for `RetargetingConversionType` and `ReengagementWindow`.

8. **Tier 1 - `Contributor1/2TouchTime` are STRING.** SP-upstream normalises `'None'` / `'USD'` / `'usd'` placeholder strings to NULL but stores the rest as varchar. Cast with `try_to_timestamp` before chronological ordering. (`Contributor3TouchTime` is also STRING here on silver; the bi_db gold mirror stores it as TIMESTAMP - the type-asymmetry is a known anomaly.)

9. **Tier 1 - `City` is DDM-masked on the bi_db gold mirror.** Verify whether the same masking applies on this silver path before exposing in user-facing dashboards.

10. **Tier 2 - `Platform` and `MediaSource` carry dirty values.** `Platform`: ~3M rows have GUID-shaped strings - filter `Platform IN ('android','ios','None')`. `MediaSource`: `'0.0'` (~1M rows) and pure-numeric strings appear due to upstream export bugs.

11. **Tier 2 - Naming: AppFlyer (no `s`) vs AppsFlyer (with `s`).** The vendor's product is **AppsFlyer**. eToro stores the bi_db Synapse mirror as **AppFlyer** (no `s`). This silver table uses **AppsFlyer** (with `s`) - aligned with vendor spelling. The bridge column is **AppsflyerID** (lowercase `f`).

12. **Tier 2 - `Region` is AppsFlyer's macro-region code (EU / AS / NA), not eToro's `newmarketingregion`.** Codes differ. Use `CountryCode` (ISO-2) for country-grain joins.

13. **Tier 2 - `EtoroAppID` vs `AppID` notation.** `AppID` uses dot notation (`'com.etoro.openbook'` / `'id674984916'`); `EtoroAppID` uses underscore notation (`'com_etoro_openbook'` / `'id674984916'`). Both identify the same app per platform.

---

## 8. Lineage

```
AppsFlyer Raw Data Export API
   |--- daily external feed --|
   v
[eToro raw landing - Synapse]
BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext (130M+ rows, all-varchar)
   |
   |---[SP_AppFlyer_Reports daily]--->  BI_DB_dbo.BI_DB_AppFlyer_Reports (Synapse cleansed)
   |                                       |
   |                                       v
   |                                   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports (89 cols, IP-DROPPED)
   |
   |---[silver pipeline]------------->  main.de_output.de_output_appsflyer_silver_reports (THIS TABLE, 86 cols, IP-PRESERVED)
                                            |
                                            v
                                        main.bridgeclaw_permitted_data.appflyer_reports (VIEW, 33-col subset, dateid > 20260531)
```

CID bridge (joins to either silver or gold on `AppsFlyerID`):
```
main.bi_db.bronze_marketperformance_tracking_customer (48M CIDs, 1 row per CID)
   |  carries CID, GCID, AppsflyerID, FirebaseID, IDFV, iOSAdTrackingPermissionID
```

---

*Generated 2026-06-10 - one-shot AppsFlyer deployment grounded in `proposals/AppsFlyer_Fields.pdf`.*
