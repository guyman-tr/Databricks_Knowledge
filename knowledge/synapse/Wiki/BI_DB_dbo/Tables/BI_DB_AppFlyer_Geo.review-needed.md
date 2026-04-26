---
table: BI_DB_dbo.BI_DB_AppFlyer_Geo
review_priority: low
generated: 2026-04-22
batch: 51
---

# Review Notes: BI_DB_AppFlyer_Geo

## Items Requiring Human Verification

### 1. Date Range — Possible Truncation
**Status:** Uncertain  
**Detail:** Live table date range is 2022-10-29 → 2023-09-17. The SP was originally authored in 2016, suggesting AppFlyer data may have been collected for much longer. It's unclear whether earlier data was purged, migrated, or simply not re-loaded after a schema change. A marketing stakeholder should confirm the expected historical depth.

### 2. UK vs GB Country Code
**Status:** Confirmed quirk, no action needed unless downstream impact  
**Detail:** `Country = 'UK'` appears in the data; `BI_DB_AppFlyer_Reports` applies a `CASE WHEN 'UK' THEN 'GB'` transformation but `BI_DB_AppFlyer_Geo` does not. This means UK-attributed geo rows may not join correctly with ISO-standard country lookups. Verify with marketing analytics whether this inconsistency is known and acceptable.

### 3. redepositSalesinUSD — Commented-out CASE block
**Status:** Resolved in current SP, but worth flagging  
**Detail:** In SP_AppFlyer_Geo, `redepositSalesinUSD` had a commented-out CASE block in what appears to be a development draft. The final INSERT does include this column. All observed values in the sample are 0 — unclear if this column genuinely captures redeposit USD revenue or is always 0. Verify with AppFlyer reporting team whether this metric is populated in the raw export.

### 4. LoyalUsers Definition
**Status:** Assumed from AppFlyer standard, not confirmed from internal docs  
**Detail:** The wiki states "loyal users = users with more than 3 sessions." This follows AppFlyer's standard loyalty definition. If eToro's AppFlyer configuration uses a custom loyalty threshold, the description should be updated.

### 5. Aggregate vs User-Level Reconciliation
**Status:** Informational  
**Detail:** This table is aggregate geo-level data. There is no known join key between `BI_DB_AppFlyer_Geo` (aggregate) and `BI_DB_AppFlyer_Reports` (user-level). Confirm with the marketing analytics team whether the two tables are expected to reconcile on `EtoroDateID + EtoroAppID + MediaSource + Country`, or whether the aggregation logic differs.

## No Action Required

- Column descriptions are Tier 3 (derived from SP code and AppFlyer platform knowledge). No upstream wiki exists for this third-party source.
- OpsDB entry confirmed: Priority 0, daily, no downstream consumers.
- Three-file write complete.
