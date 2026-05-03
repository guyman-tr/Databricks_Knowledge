# BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube

> 36.8M-row Bronze export of fiktivo's AffiliateCommission.ClosedPositionVW, joining closed trading positions with affiliate attribution metadata. Rebuilt from scratch (DROP + COPY INTO from Parquet) on each SP_Marketing_Cube run, covering positions from start of last month to the run date. Used as an intermediate staging table for the Marketing Cube pipeline.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | fiktivo.AffiliateCommission.ClosedPositionVW (via SP_Create_fiktivo_AffiliateCommission_ClosedPosition, called by SP_Marketing_Cube) |
| **Refresh** | Daily full rebuild (DROP + COPY INTO) as part of SP_Marketing_Cube |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table is a Synapse-local materialization of the fiktivo AffiliateCommission closed-position view (ClosedPositionVW), which denormalizes position financial data from `AffiliateCommission.ClosedPosition` with affiliate attribution context from `AffiliateCommission.RegistrationMetaData`. It serves as an intermediate staging table within the Marketing Cube pipeline (SP_Marketing_Cube).

The table contains 36.8M rows spanning 2026-03-01 to 2026-04-27 (rolling window from start of last month). On each SP_Marketing_Cube execution, the table is dropped and rebuilt from Bronze-tier Parquet files exported from the fiktivo production database via the Generic Pipeline. The `etr_y`, `etr_ym`, `etr_ymd` columns are data lake partition keys auto-created by the COPY INTO command.

SP_Marketing_Cube joins this table with `External_fiktivo_AffiliateCommission_ClosedPositionCommission` to compute revenue-share commissions, chargebacks, CPA costs, and other commission types aggregated by affiliate, country, date, and customer. The table is also consumed by SP_DDR and compliance-related SPs.

72.4% of rows have Valid = True and IsProcessed = True; 27.6% are invalid/unprocessed positions. CountryID 218 is the most common (6.4M rows), followed by 79 (4.2M) and 102 (3.8M).

---

## 2. Business Logic

### 2.1 Commission Processing Pipeline

**What**: Each closed position passes through a pipeline from tracking to commission calculation.
**Columns Involved**: `IsProcessed`, `Valid`, `CommissionDate`, `TrackingDate`
**Rules**:
- Positions enter with IsProcessed = 0 (pending commission calculation)
- After commission calculation, IsProcessed is set to 1 and CommissionDate is updated
- Valid = 0 indicates a disqualified position (fraud, trade reversal, or affiliate terms violation)
- TrackingDate is when the position first entered the affiliate commission tracking system (may precede CommissionDate)

### 2.2 Provider Chain Attribution

**What**: Three provider IDs track the complete chain of position ownership for multi-entity brokerages.
**Columns Involved**: `ProviderID`, `OriginalProviderID`, `RealProviderID`
**Rules**:
- ProviderID: current provider responsible for the position
- OriginalProviderID: provider that originally opened the position (0 = same as ProviderID)
- RealProviderID: actual execution entity (relevant for white-label arrangements)

### 2.3 Customer Attribution Chain

**What**: CID and OriginalCID track customer ownership for copy-trading and sub-account scenarios.
**Columns Involved**: `CID`, `OriginalCID`
**Rules**:
- CID: customer who holds the position (from RegistrationMetaData)
- OriginalCID: original customer in copy-trading scenarios (NULL for independently opened positions)
- The ClosedPositionVW uses a UNION ALL with two join paths: CID-based (CID > 0, TrackingDate >= 2021-12-31) and legacy OriginalCID-based (CID = -1, pre-2021-12-31)

### 2.4 Rolling Window Rebuild

**What**: Table is fully rebuilt on each SP_Marketing_Cube run for a specific date window.
**Columns Involved**: `etr_y`, `etr_ym`, `etr_ymd`
**Rules**:
- SP_Create_fiktivo_AffiliateCommission_ClosedPosition drops the table and rebuilds via COPY INTO from Bronze Parquet files
- Date range is from @StartOfLastMonthForLoop to @Date (typically start of last month to yesterday)
- Parquet files are partitioned by year/month/day in the data lake path

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP storage. No indexes. Full table scans on every query. For large JOINs, consider filtering on CommissionDate first.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Revenue-share commissions by affiliate | JOIN with External_fiktivo_AffiliateCommission_ClosedPositionCommission on ClosedPositionID, filter Valid = 1 |
| Commission costs by country and date | GROUP BY CountryID, CONVERT(VARCHAR(8), CommissionDate, 112) |
| Campaign attribution analysis | GROUP BY AffiliateID, AffiliateCampaign WHERE Valid = 1 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| External_fiktivo_AffiliateCommission_ClosedPositionCommission | ClosedPositionID = ClosedPositionID | Get commission amounts and tiers per position |
| DWH_dbo.Dim_Affiliate | AffiliateID = AffiliateID | Resolve affiliate metadata |
| #NotValidCustomer (temp table in SP_Marketing_Cube) | OriginalCID = Optional3 | Exclude invalid/fake-FTD customers |

### 3.4 Gotchas

- Table is dropped and rebuilt daily — do not rely on it persisting between SP_Marketing_Cube runs
- All columns are nullable (COPY INTO with AUTO_CREATE_TABLE='ON' makes everything nullable regardless of source constraints)
- LabelID is always NULL — preserved for backward compatibility only
- OriginalCID serves double duty: customer attribution AND join key for #NotValidCustomer exclusion (as Optional3 = OriginalCID + 17 in the SP)
- etr_y/etr_ym/etr_ymd are string-typed partition keys, not date types — do not use for date arithmetic
- CountryID is bigint here (from production) vs int in many DWH dim tables — type mismatch on JOINs

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki |
| Tier 2 | ETL-computed or derived column, described from SP/view logic |
| Tier 3 | No upstream documentation found; described from DDL and context |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ClosedPositionID | bigint | YES | Unique identifier of the closed position. Matches the position ID from the trading system (ClosedPositionFromEtoro). PK with idempotency guard in InsertClosedPosition - duplicate inserts are silently ignored. (Tier 1 — AffiliateCommission.ClosedPosition) |
| 2 | CommissionDate | datetime2(7) | YES | Timestamp when the commission was calculated or last updated. Set initially during InsertClosedPosition and updated by SaveClosedPositionCommission when commissions are recalculated. Used for commission reporting periods. (Tier 1 — AffiliateCommission.ClosedPosition) |
| 3 | Amount | numeric(16,6) | YES | Gross commission amount for the position in USD. Represents the base commission before hedge adjustments. Can be 0 for positions that are valid but generate no commission (e.g., certain affiliate agreement types). (Tier 1 — AffiliateCommission.ClosedPosition) |
| 4 | HedgeCommission | numeric(16,6) | YES | Additional commission component from hedging activity on this position. Typically a fraction of the main Amount. Combined with Amount for total commission calculation. (Tier 1 — AffiliateCommission.ClosedPosition) |
| 5 | CID | bigint | YES | Customer ID of the trader who held the position. References the customer in the external customer system. Sourced from RegistrationMetaData via ClosedPositionVW. (Tier 1 — AffiliateCommission.RegistrationMetaData) |
| 6 | OriginalCID | bigint | YES | Original customer ID in copy-trading scenarios. When a position is copied from another trader, this holds the CID of the original trader. NULL for independently opened positions. Used in commission attribution to follow the referral chain. Sourced from RegistrationMetaData via ClosedPositionVW. (Tier 1 — AffiliateCommission.RegistrationMetaData) |
| 7 | AffiliateID | int | YES | The affiliate attributed with this customer's registration. Can change via re-attribution (tracked by system versioning). Sourced from RegistrationMetaData via ClosedPositionVW. (Tier 1 — AffiliateCommission.RegistrationMetaData) |
| 8 | AffiliateCampaign | varchar(max) | YES | Campaign tracking string from the affiliate link. May contain encoded tracking parameters. Empty string when no campaign context was captured. Sourced from RegistrationMetaData via ClosedPositionVW. (Tier 1 — AffiliateCommission.RegistrationMetaData) |
| 9 | ProviderID | bigint | YES | Current provider/entity responsible for the position. In multi-entity brokerage setups, identifies which regulated entity processes the position. Commonly 1 for the primary entity. (Tier 1 — AffiliateCommission.ClosedPosition) |
| 10 | OriginalProviderID | bigint | YES | Provider that originally opened the position. 0 indicates the position was opened directly (not transferred between providers). Used to track provider migrations and white-label attribution. (Tier 1 — AffiliateCommission.ClosedPosition) |
| 11 | RealProviderID | bigint | YES | Actual execution entity for the trade. In white-label arrangements, this identifies the real broker executing the trade while ProviderID represents the customer-facing entity. (Tier 1 — AffiliateCommission.ClosedPosition) |
| 12 | CountryID | bigint | YES | Country identifier for the customer's registration country. Used in commission rules that vary by geography (e.g., regulatory region-specific commission rates). (Tier 1 — AffiliateCommission.ClosedPosition) |
| 13 | NetProfit | float | YES | Net profit/loss of the position in USD. Negative values indicate a losing position. Used in commission calculations where commission may depend on position profitability. (Tier 1 — AffiliateCommission.ClosedPosition) |
| 14 | FunnelID | int | YES | Marketing funnel identifier. NULL when funnel tracking is not applicable or not configured for the affiliate. Sourced from RegistrationMetaData via ClosedPositionVW. (Tier 1 — AffiliateCommission.RegistrationMetaData) |
| 15 | LabelID | int | YES | Always NULL. Column preserved for backward compatibility with legacy consumers. Hardcoded as NULL in ClosedPositionVW. (Tier 1 — AffiliateCommission.ClosedPositionVW) |
| 16 | PlayerLevelID | int | YES | Player level classification at registration time. 1 = standard new player. May be updated as player progresses. Sourced from RegistrationMetaData via ClosedPositionVW. (Tier 1 — AffiliateCommission.RegistrationMetaData) |
| 17 | DownloadID | bigint | YES | Download/app install tracking ID. 0 = no download tracked. Links to app installation events. Sourced from RegistrationMetaData via ClosedPositionVW. (Tier 1 — AffiliateCommission.RegistrationMetaData) |
| 18 | LotCount | numeric(16,6) | YES | Size of the position in lots. Represents the traded volume, which may influence commission calculations for volume-based affiliate agreements. (Tier 1 — AffiliateCommission.ClosedPosition) |
| 19 | BannerID | int | YES | Banner that led to the registration. 0 = no banner tracked. References the banner/creative system. Sourced from RegistrationMetaData via ClosedPositionVW. (Tier 1 — AffiliateCommission.RegistrationMetaData) |
| 20 | Valid | bit | YES | Whether this position is eligible for commission payout. 1 = valid/eligible, 0 = disqualified. Positions may be invalidated if the underlying trade was reversed, the customer was flagged for fraud, or the affiliate violated terms. (Tier 1 — AffiliateCommission.ClosedPosition) |
| 21 | TrackingDate | datetime2(7) | YES | Timestamp when the position first entered the affiliate commission tracking system. May precede CommissionDate if the position was tracked before commissions were calculated. (Tier 1 — AffiliateCommission.ClosedPosition) |
| 22 | IsProcessed | bit | YES | Processing completion flag. 0 = pending commission calculation, 1 = commission has been calculated and saved. Set to 1 by SaveClosedPositionCommission and UpdateClosedPositionTracking. (Tier 1 — AffiliateCommission.ClosedPosition) |
| 23 | ValidFrom | datetime2(7) | YES | System versioning start time. When this version of the row became effective. Automatically set by SQL Server temporal tables. Sourced from RegistrationMetaData via ClosedPositionVW. (Tier 1 — AffiliateCommission.RegistrationMetaData) |
| 24 | UpdateDate | datetime2(7) | YES | Computed in ClosedPositionVW as GREATEST(CommissionDate, ValidFrom). Latest change timestamp — reflects whichever was more recent: the commission recalculation or the attribution change. Used by CDC/incremental consumers to detect changes. (Tier 2 — AffiliateCommission.ClosedPosition / AffiliateCommission.RegistrationMetaData) |
| 25 | AdditionalData | varchar(max) | YES | Extensible metadata field. Defaults to empty string. Allows additional attribution data without schema changes. Sourced from RegistrationMetaData via ClosedPositionVW. (Tier 1 — AffiliateCommission.RegistrationMetaData) |
| 26 | etr_y | varchar(max) | YES | Data lake partition key representing the year of the position date. Extracted from the Parquet file path by COPY INTO (e.g., etr_y=2026). (Tier 2 — SP_Create_fiktivo_AffiliateCommission_ClosedPosition) |
| 27 | etr_ym | varchar(max) | YES | Data lake partition key representing year-month (e.g., 2026-03). Extracted from the Parquet file path by COPY INTO. (Tier 2 — SP_Create_fiktivo_AffiliateCommission_ClosedPosition) |
| 28 | etr_ymd | varchar(max) | YES | Data lake partition key representing the full date (e.g., 2026-03-01). Extracted from the Parquet file path by COPY INTO. (Tier 2 — SP_Create_fiktivo_AffiliateCommission_ClosedPosition) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| ClosedPositionID | AffiliateCommission.ClosedPosition | ClosedPositionID | Passthrough |
| CommissionDate | AffiliateCommission.ClosedPosition | CommissionDate | Passthrough |
| Amount | AffiliateCommission.ClosedPosition | Amount | Passthrough |
| HedgeCommission | AffiliateCommission.ClosedPosition | HedgeCommission | Passthrough |
| CID | AffiliateCommission.RegistrationMetaData | CID | Passthrough |
| OriginalCID | AffiliateCommission.RegistrationMetaData | OriginalCID | Passthrough |
| AffiliateID | AffiliateCommission.RegistrationMetaData | AffiliateID | Passthrough |
| AffiliateCampaign | AffiliateCommission.RegistrationMetaData | AffiliateCampaign | Passthrough |
| ProviderID | AffiliateCommission.ClosedPosition | ProviderID | Passthrough |
| OriginalProviderID | AffiliateCommission.ClosedPosition | OriginalProviderID | Passthrough |
| RealProviderID | AffiliateCommission.ClosedPosition | RealProviderID | Passthrough |
| CountryID | AffiliateCommission.ClosedPosition | CountryID | Passthrough |
| NetProfit | AffiliateCommission.ClosedPosition | NetProfit | Passthrough |
| FunnelID | AffiliateCommission.RegistrationMetaData | FunnelID | Passthrough |
| LabelID | ClosedPositionVW | — | Hardcoded NULL |
| PlayerLevelID | AffiliateCommission.RegistrationMetaData | PlayerLevelID | Passthrough |
| DownloadID | AffiliateCommission.RegistrationMetaData | DownloadID | Passthrough |
| LotCount | AffiliateCommission.ClosedPosition | LotCount | Passthrough |
| BannerID | AffiliateCommission.RegistrationMetaData | BannerID | Passthrough |
| Valid | AffiliateCommission.ClosedPosition | Valid | Passthrough |
| TrackingDate | AffiliateCommission.ClosedPosition | TrackingDate | Passthrough |
| IsProcessed | AffiliateCommission.ClosedPosition | IsProcessed | Passthrough |
| ValidFrom | AffiliateCommission.RegistrationMetaData | ValidFrom | Passthrough |
| UpdateDate | ClosedPosition + RegistrationMetaData | CommissionDate, ValidFrom | GREATEST(CommissionDate, ValidFrom) |
| AdditionalData | AffiliateCommission.RegistrationMetaData | AdditionalData | Passthrough |
| etr_y | SP_Create_fiktivo_AffiliateCommission_ClosedPosition | — | Parquet partition key |
| etr_ym | SP_Create_fiktivo_AffiliateCommission_ClosedPosition | — | Parquet partition key |
| etr_ymd | SP_Create_fiktivo_AffiliateCommission_ClosedPosition | — | Parquet partition key |

### 5.2 ETL Pipeline

```
fiktivo.AffiliateCommission.ClosedPosition (production, fiktivo DB)
  + fiktivo.AffiliateCommission.RegistrationMetaData (production, fiktivo DB)
    |-- AffiliateCommission.ClosedPositionVW (view, JOIN on CID) ---|
    v
  Bronze Parquet files (data lake)
    Path: /internal-sources/Bronze/fiktivo/AffiliateCommission/ClosedPositionVW/
    Partitioned: etr_y / etr_ym / etr_ymd
    |-- SP_Create_fiktivo_AffiliateCommission_ClosedPosition (COPY INTO, daily) ---|
    v
  BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube (36.8M rows)
    |-- SP_Marketing_Cube (consumer — aggregates commissions for Marketing Cube) ---|
    v
  BI_DB_dbo.BI_DB_Marketing_Cube_* (downstream Marketing Cube tables)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ClosedPositionID | External_fiktivo_AffiliateCommission_ClosedPositionCommission | JOIN key for commission details per position |
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate metadata resolution |
| CountryID | DWH_dbo.Dim_Country | Country resolution (implicit, used in SP_Marketing_Cube context) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Relationship | Description |
|--------------|-------------|-------------|
| SP_Marketing_Cube | Consumer | JOINs with commission tables to compute cost aggregates |
| SP_DDR | Consumer | Referenced for DDR calculations |
| SP_W_Compliance_Vulnerability_Detection | Consumer | Compliance position analysis |

---

## 7. Sample Queries

### 7.1 Revenue-share commissions by affiliate for recent period

```sql
SELECT tblCommissions.AffiliateID,
       SUM(ISNULL(tblCommissions.Commission, 0)) AS TotalCommission,
       COUNT(*) AS PositionCount
FROM [BI_DB_dbo].[External_fiktivo_AffiliateCommission_ClosedPositionCommission] tblCommissions
INNER JOIN [BI_DB_dbo].[fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube] sale
    ON tblCommissions.ClosedPositionID = sale.ClosedPositionID
WHERE sale.Valid = 1
  AND sale.CommissionDate >= '2026-04-01'
  AND tblCommissions.Commission != 0
GROUP BY tblCommissions.AffiliateID
ORDER BY TotalCommission DESC;
```

### 7.2 Daily position volume and net profit by country

```sql
SELECT CONVERT(VARCHAR(10), CommissionDate, 120) AS CommissionDay,
       CountryID,
       COUNT(*) AS PositionCount,
       SUM(Amount) AS TotalAmount,
       SUM(NetProfit) AS TotalNetProfit
FROM [BI_DB_dbo].[fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube]
WHERE Valid = 1 AND IsProcessed = 1
GROUP BY CONVERT(VARCHAR(10), CommissionDate, 120), CountryID
ORDER BY CommissionDay DESC, PositionCount DESC;
```

### 7.3 Campaign attribution breakdown for a specific affiliate

```sql
SELECT AffiliateCampaign,
       COUNT(*) AS Positions,
       SUM(Amount) AS TotalAmount,
       SUM(LotCount) AS TotalLots
FROM [BI_DB_dbo].[fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube]
WHERE AffiliateID = 32504
  AND Valid = 1
GROUP BY AffiliateCampaign
ORDER BY TotalAmount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness — Jira phase skipped).

---

*Generated: 2026-04-30 | Quality: 8.5/10 | Phases: 12/14*
*Tiers: 22 T1, 6 T2, 0 T3, 0 T4, 0 T5 | Elements: 28/28, Logic: 8/10, Relationships: 7/10*
*Object: BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube | Type: Table | Production Source: fiktivo.AffiliateCommission.ClosedPositionVW*
