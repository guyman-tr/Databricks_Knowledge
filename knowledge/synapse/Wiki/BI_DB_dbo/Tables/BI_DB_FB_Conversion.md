# BI_DB_dbo.BI_DB_FB_Conversion

> 238K-row Facebook Ads conversion tracking table capturing 7-day click attribution counts (registrations, V2 verifications, FTDs) per Facebook ad per date, covering Oct 2020–Jan 2026. Each row represents one unique ad_id × date combination with conversion counts pivoted from the Fivetran `facebook_conversion_actions` external feed. **Feed is inactive** — last data date is 2026-01-07 (last ETL run: 2026-01-15). Written by `SP_FB_Perf_Conv` via an 8-day rolling DELETE+INSERT to accommodate Facebook's 7-day attribution correction window.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Facebook Ads API via Fivetran (`External_Fivetran_facebook_cvr_facebook_conversion_actions`, Bronze lake: `Bronze/Fivetran/facebook_cvr/facebook_conversion_actions`) |
| **Refresh** | Daily (inactive since 2026-01-15) — DELETE 8-day rolling window + INSERT via `SP_FB_Perf_Conv` |
| **OpsDB Priority** | 20 (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_FB_Conversion` tracks **Facebook Ads conversion funnel metrics** — how many users who clicked on a Facebook ad within a 7-day window subsequently completed key milestones (registration, phone/KYC verification, first deposit). One row per ad_id × date, with three conversion count columns representing successive stages of the acquisition funnel.

The table is consumed by `SP_FB_Report` (FULL OUTER JOIN with `BI_DB_FB_Performance`) to build the Facebook Ads report combining ad spend/performance metrics with downstream conversion outcomes.

**Feed status**: The Fivetran Facebook Ads feed stopped providing new data after 2026-01-07 (last UpdateDate: 2026-01-15). This mirrors the Bing Ads feed cutoff (Oct 2025) — likely reflecting a change in marketing reporting infrastructure or Fivetran connector retirement.

**Grain**: One row per unique (date × ad_id) combination where at least one of the three action_types was filtered in the source. 11,907 distinct Facebook ad IDs observed. 45% of rows have all-zero conversion counts (ad ran but no attributed conversions).

**Attribution window**: Facebook's 7-day click attribution means a registration on day D+6 is attributed to a click on day D. The SP refreshes the last 8 days (`@date-7` to `@date+1`) to capture late-arriving attribution adjustments from Facebook's reporting API.

Total conversions across all time: 421K registrations, 107K V2 verifications, 75K FTDs.

---

## 2. Business Logic

### 2.1 PIVOT of action_type Into Conversion Columns

**What**: The external table has one row per (date, ad_id, action_type). The SP pivots three specific action_types into columns.

**Columns Involved**: Registration, V2, FTD

**Rules**:
- `Registration` = SUM(_7_d_click) WHERE action_type = 'complete_registration' — Facebook-reported completed registration event within 7-day click window
- `V2` = SUM(_7_d_click) WHERE action_type = 'offsite_conversion.custom.384730099048186' — eToro's custom conversion event ID `384730099048186` mapped to level-2 verification (V2/phone verification); long numeric ID is Facebook's custom event identifier
- `FTD` = SUM(_7_d_click) WHERE action_type = 'purchase' — Facebook standard 'purchase' event mapped to eToro's First Time Deposit event
- Rows with other action_types in the external table are excluded (filter: `action_type IN (...)`)
- ISNULL(..., 0) applied to all three columns — rows with no actions of a given type produce 0, not NULL

### 2.2 8-Day Rolling Refresh Window

**What**: The DELETE window is wider than a single day to accommodate Facebook's retroactive attribution corrections.

**Columns Involved**: date, (all columns via rolling delete)

**Rules**:
- `@FromDate = @date - 7 days`; `@Today = @date + 1 day`
- `DELETE WHERE date >= @FromDate AND date < @Today` — erases 8 days of data
- Facebook may revise conversion counts for up to 7 days after the original click as late events arrive
- This means each daily run re-materialises the last 8 days from the fresh Fivetran data

### 2.3 date_id Computation

**What**: date_id is a computed integer encoding of the date column using the schema's `DateToDateID` function.

**Columns Involved**: date_id, date

**Rules**:
- `date_id = BI_DB_dbo.DateToDateID([date])` — converts DATE to int in YYYYMMDD format
- date_id bigint (not int) — consistent with the schema's date key type for this family of tables
- date (DATE type) and date_id (bigint) carry redundant information; date_id is provided for JOIN compatibility with other BI_DB_dbo tables that use date_id as key

---

## 3. Query Advisory

### 3.1 Distribution and Index

- **ROUND_ROBIN + HEAP**: No clustered index; well-suited for this small-medium table (238K rows). Full scan is acceptable
- No distribution key optimisation needed for typical query patterns (date + ad_id filters)

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Conversion funnel by date | `WHERE date BETWEEN @start AND @end GROUP BY date SUM(Registration), SUM(V2), SUM(FTD)` |
| Top converting ads in a period | `WHERE date BETWEEN @start AND @end GROUP BY ad_id ORDER BY SUM(FTD) DESC` |
| Conversion rates (with FB_Performance) | FULL OUTER JOIN BI_DB_FB_Performance ON date=date AND ad_id=ad_id; Registration/clicks etc |
| FB conversion data availability check | `SELECT MAX(date), MAX(UpdateDate) FROM BI_DB_FB_Conversion` (last: 2026-01-07 / 2026-01-15) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_FB_Performance | date=date AND ad_id=ad_id | Combine conversion with spend/impressions/clicks for full campaign report |

### 3.4 Gotchas

- **Feed is inactive** — last data date 2026-01-07; do not expect new rows after Jan 2026
- **45% rows have all-zero conversion counts** — rows where the ad ran but no attributed conversions occurred (common for brand awareness campaigns)
- **V2 uses a custom event ID** — `offsite_conversion.custom.384730099048186` is eToro's internal Facebook custom conversion event for level-2 verification; this ID may change if the Facebook pixel is reconfigured
- **_7_d_click attribution** — all conversion counts use 7-day click window (not view-through); the source external table also has `_1_d_view` but it is NOT used in this table
- **Facebook may revise retroactively** — the 8-day rolling refresh means yesterday's data may differ from what was inserted during the original day's ETL run
- **ad_id is nvarchar(256)** — cast when joining to bigint-typed ad_id columns in other systems

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Upstream production wiki verbatim |
| Tier 2 | From SP code (`SP_FB_Perf_Conv`) and external table structure |
| Tier 3 | Inferred from column name and Facebook Ads data model context |
| Tier 4 | Best available — unverified |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | date | date | NOT NULL | Ad performance date (calendar date type). Range: 2020-10-20 to 2026-01-07. 1,897 distinct dates. (Tier 2 — SP_FB_Perf_Conv) |
| 2 | date_id | bigint | NOT NULL | Integer date key (YYYYMMDD) computed from `date` via `BI_DB_dbo.DateToDateID([date])`. Provided for JOIN compatibility with BI_DB_dbo date-keyed tables. (Tier 2 — SP_FB_Perf_Conv) |
| 3 | ad_id | nvarchar(256) | NOT NULL | Facebook Ads ad identifier (Facebook's unique numeric ID for individual ad creatives). High cardinality — 11,907 distinct values across 5+ years. (Tier 2 — SP_FB_Perf_Conv) |
| 4 | Registration | bigint | NOT NULL | Count of Facebook Ads complete_registration events attributed to this ad on this date within the 7-day click window. Total across all time: 421,099. (Tier 2 — SP_FB_Perf_Conv) |
| 5 | V2 | bigint | NOT NULL | Count of eToro's custom level-2 verification events (Facebook custom event ID: 384730099048186) attributed to this ad within the 7-day click window. Corresponds to phone/KYC verification completion. Total: 107,788. (Tier 2 — SP_FB_Perf_Conv) |
| 6 | FTD | bigint | NOT NULL | Count of 'purchase' events (eToro's Facebook mapping for First Time Deposit) attributed to this ad within the 7-day click window. Total: 75,243. (Tier 2 — SP_FB_Perf_Conv) |
| 7 | UpdateDate | datetime | NOT NULL | ETL timestamp set to GETDATE() at INSERT time. Range: 2021-11-08 to 2026-01-15 (last ETL run). (Tier 2 — SP_FB_Perf_Conv) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| date | External_Fivetran_facebook_cvr_facebook_conversion_actions | date | Direct passthrough |
| date_id | Computed | [date] | DateToDateID() function |
| ad_id | External_Fivetran_facebook_cvr_facebook_conversion_actions | ad_id | GROUP BY key |
| Registration | External_Fivetran_facebook_cvr_facebook_conversion_actions | _7_d_click | SUM CASE WHEN action_type='complete_registration' |
| V2 | External_Fivetran_facebook_cvr_facebook_conversion_actions | _7_d_click | SUM CASE WHEN action_type='offsite_conversion.custom.384730099048186' |
| FTD | External_Fivetran_facebook_cvr_facebook_conversion_actions | _7_d_click | SUM CASE WHEN action_type='purchase' |
| UpdateDate | ETL | GETDATE() | Set at INSERT |

### 5.2 ETL Pipeline

```
Facebook Ads API (Meta Business Manager)
  |-- Fivetran connector (facebook_cvr) ---|
  v
Bronze/Fivetran/facebook_cvr/facebook_conversion_actions  (lake, Parquet)
  |-- BI_DB_dbo.External_Fivetran_facebook_cvr_facebook_conversion_actions  (Synapse External Table)
  |-- SP_FB_Perf_Conv @date  (P20, SB_Daily)
  |   Filter: action_type IN ('complete_registration', 'offsite_conversion.custom.384730099048186', 'purchase')
  |   Filter: date >= @date-7 AND date < @date+1 (8-day rolling window)
  |   GROUP BY: date, date_id, ad_id
  |   PIVOT: SUM(_7_d_click) → Registration / V2 / FTD columns
  |-- DELETE (8-day rolling window) + INSERT
  v
BI_DB_dbo.BI_DB_FB_Conversion
  (238,486 rows | Oct 2020 – Jan 2026 | ROUND_ROBIN, HEAP)
  Feed INACTIVE since 2026-01-15
  UC: _Not_Migrated

Downstream consumer:
  BI_DB_dbo.SP_FB_Report → FULL OUTER JOIN with BI_DB_FB_Performance
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| date | (implicit) Dim_Date | Calendar date dimension |
| ad_id | Facebook Ads Platform | External ad identifier — no Synapse Dim for ads |
| (source) | External_Fivetran_facebook_cvr_facebook_conversion_actions | External table reading Fivetran Bronze lake data |

### 6.2 Referenced By

| Object | Reference | Usage |
|--------|-----------|-------|
| SP_FB_Report | FULL OUTER JOIN on date + ad_id | Joined with BI_DB_FB_Performance for full Facebook Ads report |

---

## 7. Sample Queries

### Conversion funnel by date (aggregated across all ads)

```sql
SELECT [date],
       SUM([Registration]) AS Registrations,
       SUM([V2])           AS V2Verifications,
       SUM([FTD])          AS FirstTimeDeposits
FROM [BI_DB_dbo].[BI_DB_FB_Conversion]
WHERE [date] BETWEEN '2025-01-01' AND '2026-01-07'
GROUP BY [date]
ORDER BY [date]
```

### Top 10 ads by FTD conversions in Q4 2025

```sql
SELECT TOP 10 [ad_id],
       SUM([Registration]) AS Registrations,
       SUM([V2])           AS V2Verifications,
       SUM([FTD])          AS FTDs
FROM [BI_DB_dbo].[BI_DB_FB_Conversion]
WHERE [date] BETWEEN '2025-10-01' AND '2025-12-31'
GROUP BY [ad_id]
ORDER BY SUM([FTD]) DESC
```

### Check data freshness

```sql
SELECT MAX([date]) AS LastDataDate, MAX([UpdateDate]) AS LastETLRun
FROM [BI_DB_dbo].[BI_DB_FB_Conversion]
-- Returns: 2026-01-07 / 2026-01-15 — feed inactive since Jan 2026
```

---

## 8. Atlassian Knowledge Sources

No dedicated Confluence or Jira pages found for this table. See `SP_FB_Report` for the downstream reporting context.

---

*Generated: 2026-04-22 | Quality: 9.0/10 | Phases: 14/14*
*Tiers: 0 T1, 7 T2, 0 T3, 0 T4, 0 T5 | Elements: 7/7, Logic: 9/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_FB_Conversion | Type: Table | Production Source: Facebook Ads API via Fivetran (INACTIVE since Jan 2026)*
