---
table: BI_DB_dbo.BI_DB_AppFlyer_Reports
review_priority: medium
generated: 2026-04-22
batch: 51
---

# Review Notes: BI_DB_AppFlyer_Reports

## Items Requiring Human Verification

### 1. CustomerUserID Hashing — Mapping Table
**Status:** Unknown — needs confirmation  
**Detail:** The wiki states `CustomerUserID` is a "hashed eToro customer identifier." From the sample data it appears to be a SHA-256 or similar hash (40-char hex strings). It's unclear whether:
- This is eToro's own hashing of the CID, or AppFlyer's internal anonymization
- A CID↔CustomerUserID mapping table exists in BI_DB_dbo or DWH_dbo
- The hash is deterministic (same user always → same hash)

Without confirming this, the join path from AppFlyer events to eToro users is unverifiable. Ask the marketing analytics or data engineering team.

### 2. EventSource Garbled Values
**Status:** Data quality issue — ~1.1M rows affected  
**Detail:** `EventSource` has ~639K rows with value `"af_revenue":"0"}"` and ~434K rows with value `USD`. These look like fragments of the `EventValue` JSON that bled into the wrong column in the AppFlyer raw export. Whether this is being investigated/remediated upstream (by AppFlyer or the lake ingestion team) is unknown. These rows should be excluded from aggregations.

### 3. Contributor3TouchTime Type Inconsistency
**Status:** Confirmed architectural anomaly — low impact  
**Detail:** `Contributor1TouchTime` and `Contributor2TouchTime` are `varchar(4000)` while `Contributor3TouchTime` is `datetime`. The SP applies similar NULL-cleanup logic but casts Contributor3 to datetime, leaving 1/2 as varchar. This means malformed strings (unlikely but possible) would cause insert failures for Contributor3 but not for 1/2. Confirmed from DDL — no action needed unless queries fail on Contributor3TouchTime.

### 4. IDFA / iOS Attribution Post-ATT
**Status:** Informational — known Apple privacy change  
**Detail:** Since iOS 14.5 (April 2021), IDFA requires explicit user opt-in (ATT framework). Most iOS users decline, so IDFA is empty for the majority of recent iOS rows. This means iOS attribution relies on Probabilistic Matching or SKAdNetwork. The wiki notes this but marketing stakeholders should be aware this significantly limits iOS attribution precision.

### 5. UpdateDate — DDL Artifact
**Status:** Confirmed as always NULL — no action needed  
**Detail:** Verified from SP code: UpdateDate is not in the INSERT column list. It is a DDL artifact from the original table design. Do not use for ETL freshness tracking.

### 6. EtoroReport Column Coverage
**Status:** Confirmed 3 values — verify if complete  
**Detail:** Live distribution shows exactly 3 EtoroReport values: `OrganicInstalls`, `InAppEvents`, `Installs`. Confirm with AppFlyer team that no additional report types have been added to the export since 2022 and not yet loaded.

### 7. SP_Marketing_Cube Dependency
**Status:** Informational  
**Detail:** `SP_Marketing_Cube` is a downstream consumer. Its output tables (`BI_DB_MarketingDailyRawData`, `BI_DB_MarketingMonthlyRawData`) should be documented in subsequent batches. The dependency ensures AppFlyer_Reports must be fully loaded before Marketing_Cube runs each day.

## Column Descriptions Confidence

- Attribution/campaign columns: **High confidence** — standard AppFlyer field semantics
- Event columns (EventName, EventValue): **High confidence** — confirmed from live sample data
- Contributor columns: **Medium confidence** — multi-touch attribution logic assumed from AppFlyer documentation
- CustomerUserID semantics: **Low confidence** — hash type/mapping unknown (see item 1 above)

## Three-File Write

Complete. Lineage, wiki, and review-needed sidecar all written.
