# BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube

> 36.8M-row affiliate commission staging table holding closed-position trading data exported from the fiktivo production database (`AffiliateCommission.ClosedPositionVW`) via Bronze lake Parquet files. Covers commission dates from 2026-03-01 to 2026-04-27 (rolling window, rebuilt daily). Consumed by `SP_Marketing_Cube` for marketing cost and revenue aggregations. No upstream wiki documentation available.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | fiktivo.AffiliateCommission.ClosedPositionVW via SP_Create_fiktivo_AffiliateCommission_ClosedPosition |
| **Refresh** | Daily — DROP + COPY INTO loop from start of last month to @Date, called by SP_Marketing_Cube |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A (lake Parquet partitioned by etr_y/etr_ym/etr_ymd) |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a staging copy of closed trading positions from the fiktivo affiliate commission system. It serves as an intermediate dataset for `SP_Marketing_Cube`, which aggregates commission costs, revenues, chargebacks, and CPA fees by affiliate, country, and date.

The data originates from `fiktivo.AffiliateCommission.ClosedPositionVW`, a production view that combines:
- **ClosedPositionFromEtoro** — raw trading data ingested via Service Broker from the etoro trading platform (ClosedPositionID, CID, Commission, NetProfit, Lots).
- **RegistrationMetaData** — affiliate attribution metadata per CID (AffiliateID, AffiliateCampaign, FunnelID, PlayerLevelID, DownloadID).

The ETL pattern is destructive reload: `SP_Create_fiktivo_AffiliateCommission_ClosedPosition` drops the table, then loops day-by-day from the start of last month to `@Date`, executing `COPY INTO` from Parquet files at `internal-sources/Bronze/fiktivo/AffiliateCommission/ClosedPositionVW/`. The table is rebuilt each daily run of `SP_Marketing_Cube`.

Current data: ~36.8M rows covering 2026-03-01 to 2026-04-26 (2 months, 1 year partition). Approximately 72% of positions are valid (`Valid=1`) and processed (`IsProcessed=1`).

---

## 2. Business Logic

### 2.1 Commission Eligibility

**What**: Determines whether a closed position is eligible for affiliate commission calculation.
**Columns Involved**: Valid, IsProcessed, Amount, HedgeCommission
**Rules**:
- `Valid=1` (True) indicates the position is eligible for commission; `Valid=0` (False) means disqualified.
- `IsProcessed=1` (True) indicates the commission has been calculated; `IsProcessed=0` (False) means pending.
- Net revenue per position in SP_Marketing_Cube: `Amount - ISNULL(HedgeCommission, 0)`.

### 2.2 Customer Attribution Chain

**What**: Links each closed position to the affiliate responsible for the customer acquisition.
**Columns Involved**: CID, OriginalCID, AffiliateID, AffiliateCampaign, BannerID
**Rules**:
- `OriginalCID` is the customer identifier used as the primary attribution key (`Optional3` in SP_Marketing_Cube).
- `AffiliateID` identifies the affiliate credited with this customer's registration.
- Customers in `#NotValidCustomer` (IsValidCustomer != 1 or fake FTD Aug 2025) are excluded from all aggregations via `LEFT JOIN ... WHERE cc.Optional3 IS NULL`.

### 2.3 Provider Entity Tracking

**What**: Tracks the regulated entity / provider associated with each position.
**Columns Involved**: ProviderID, OriginalProviderID, RealProviderID
**Rules**:
- `ProviderID` is the current provider entity. Sample data shows value `1` (primary entity) for all sampled rows.
- `OriginalProviderID` value `0` indicates the position was opened directly (not transferred).
- `RealProviderID` represents the actual regulated provider after any transfers.

### 2.4 Lake Partitioning

**What**: Parquet file path partitioning columns for the Bronze lake export.
**Columns Involved**: etr_y, etr_ym, etr_ymd
**Rules**:
- `etr_y` = year of the tracking date (e.g., `2026`).
- `etr_ym` = year-month (e.g., `2026-03`).
- `etr_ymd` = full date (e.g., `2026-03-01`).
- These are derived from the COPY INTO file path structure, not from table columns.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** distribution with **HEAP** storage (no clustered index).
- Table is rebuilt daily — no persistent indexes exist.
- Queries should filter on `CommissionDate` or `etr_ymd` to limit scan scope.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Total commission cost by affiliate for a month | Filter `CommissionDate` range, JOIN to `External_fiktivo_AffiliateCommission_ClosedPositionCommission` on `ClosedPositionID`, GROUP BY `AffiliateID` |
| Revenue by country | `SUM(Amount - ISNULL(HedgeCommission,0))` grouped by `CountryID`, filter `Valid = 1` |
| Positions pending commission processing | `WHERE IsProcessed = 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| External_fiktivo_AffiliateCommission_ClosedPositionCommission | ClosedPositionID = ClosedPositionID | Get commission amounts and tiers per position |
| DWH_dbo.Dim_Affiliate | AffiliateID = AffiliateID | Resolve affiliate name, channel, contract type |
| DWH_dbo.Dim_Customer | OriginalCID+17 = Optional3 OR RealCID = CID | Validate customer, check IsValidCustomer, get FirstDepositDate |
| DWH_dbo.Dim_Country | CountryID = CountryID | Resolve country name and region |
| DWH_dbo.Dim_Funnel | FunnelID = FunnelID | Resolve funnel and platform |

### 3.4 Gotchas

- **Table is rebuilt daily** — the entire table is DROP + COPY INTO each run. Do not rely on row stability across runs.
- **LabelID is always NULL** — hardcoded NULL in ClosedPositionVW. Do not filter or join on this column.
- **OriginalCID offset** — SP_Marketing_Cube uses `OriginalCID+17` as `Optional3` for customer matching. This is a legacy mapping convention.
- **AffiliateCampaign encoding** — contains URL-encoded strings with `&amp;` entities and pipe-delimited tracking parameters. Use `COLLATE Latin1_General_Bin` for comparisons as SP_Marketing_Cube does.
- **Fake FTD exclusion** — Customers with `FirstDepositDate` between 2025-08-19 and 2025-08-22 and `FirstDepositAmount = 1` are excluded as fake FTDs.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (none available for this object) |
| Tier 2 | Derived from SP code, view logic, or ETL transform |
| Tier 3 | No upstream wiki; grounded in DDL type, column name, and data sample |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ClosedPositionID | bigint | YES | Unique identifier of the closed trading position from the fiktivo affiliate commission system. Used as the primary join key to `External_fiktivo_AffiliateCommission_ClosedPositionCommission` for commission lookups. Sourced from `ClosedPositionFromEtoro` via Service Broker. (Tier 3 — no upstream wiki, grounded in DDL + SP JOIN pattern) |
| 2 | CommissionDate | datetime2(7) | YES | Timestamp when the commission event occurred or was recorded for this closed position. Used in SP_Marketing_Cube for date-range filtering (`CommissionDate >= @StartOfLastMonthForLoop AND CommissionDate < @Date1`) and date-based aggregation via `CONVERT(VARCHAR(8), CommissionDate, 112)`. (Tier 3 — no upstream wiki, grounded in DDL + SP usage) |
| 3 | Amount | numeric(16,6) | YES | Gross commission amount for the closed position. Combined with HedgeCommission in SP_Marketing_Cube as `Amount - ISNULL(HedgeCommission, 0)` to compute net revenues. Can be 0.000000 for positions that generate no commission. (Tier 3 — no upstream wiki, grounded in DDL + SP arithmetic) |
| 4 | HedgeCommission | numeric(16,6) | YES | Hedge commission component associated with this position. Subtracted from Amount in SP_Marketing_Cube (`Amount - ISNULL(HedgeCommission, 0)`) and also aggregated separately via `SUM(ISNULL(HedgeCommission, 0))`. Typically ~10% of Amount based on sample data. (Tier 3 — no upstream wiki, grounded in DDL + SP arithmetic) |
| 5 | CID | bigint | YES | Customer ID of the trader who held the closed position. References the customer in the etoro trading system. Distinct from OriginalCID in copy-trading scenarios. (Tier 3 — no upstream wiki, grounded in DDL + column naming convention) |
| 6 | OriginalCID | bigint | YES | Original customer ID used as the primary affiliate attribution key. In SP_Marketing_Cube, `OriginalCID` is used directly as `Optional3` (and `OriginalCID+17` for NotValidCustomer matching). In copy-trading, this is the CID of the original account holder. (Tier 3 — no upstream wiki, grounded in DDL + SP usage) |
| 7 | AffiliateID | int | YES | Identifier of the affiliate credited with this customer's acquisition. Joined to `DWH_dbo.Dim_Affiliate` in SP_Marketing_Cube. Sourced from `RegistrationMetaData` via ClosedPositionVW. (Tier 3 — no upstream wiki, grounded in DDL + SP JOIN) |
| 8 | AffiliateCampaign | varchar(max) | YES | Campaign tracking string from the affiliate registration. Contains pipe-delimited tracking parameters (e.g., `CAMP_xxx|AG_xxx|KW_xxx`) or URLs (e.g., `https://www.etoro.com/accounts/sign-up`). Empty string when no campaign context was captured. Compared using `COLLATE Latin1_General_Bin` in SP_Marketing_Cube. (Tier 3 — no upstream wiki, grounded in DDL + sample data + SP collation usage) |
| 9 | ProviderID | bigint | YES | Current provider/entity identifier for the position. Sample data shows value `1` for all rows (primary entity). (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 10 | OriginalProviderID | bigint | YES | Provider that originally opened the position. Value `0` indicates the position was opened directly (not transferred between providers). (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 11 | RealProviderID | bigint | YES | Actual regulated provider identifier after any provider transfers or migrations. Sample data shows value `1` for all rows. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 12 | CountryID | bigint | YES | Country identifier for the customer's registered country. FK to `DWH_dbo.Dim_Country`. Used in SP_Marketing_Cube for country-level aggregation via `ISNULL(CountryID, 0)`. Over 15 distinct values (top: 218, 79, 102, 74, 191). (Tier 3 — no upstream wiki, grounded in DDL + SP usage + distribution) |
| 13 | NetProfit | float | YES | Net profit/loss of the closed position. Aggregated in SP_Marketing_Cube via `SUM(ISNULL(NetProfit, 0))`. Computed in ClosedPositionVW from underlying position economics. Can be negative (loss) or positive (profit). (Tier 2 — ClosedPositionVW) |
| 14 | FunnelID | int | YES | Registration funnel identifier. Joined to `DWH_dbo.Dim_Funnel` (then to `Dim_Platform`) in SP_Marketing_Cube to resolve the acquisition platform. Sourced from `RegistrationMetaData` via ClosedPositionVW. (Tier 3 — no upstream wiki, grounded in DDL + SP JOIN chain) |
| 15 | LabelID | int | YES | Label identifier. Hardcoded NULL in ClosedPositionVW — 100% of 36.8M rows are NULL. Not used in any downstream aggregation in SP_Marketing_Cube. (Tier 2 — ClosedPositionVW, hardcoded NULL) |
| 16 | PlayerLevelID | int | YES | Player level classification of the customer. Values observed: 1, 2, 3, 5, 6 (5 distinct levels). Sourced from `RegistrationMetaData` via ClosedPositionVW. Used in SP_Marketing_Cube for player level 4 filtering logic. (Tier 3 — no upstream wiki, grounded in DDL + distribution + SP reference) |
| 17 | DownloadID | bigint | YES | Download/install tracking identifier. Value `0` indicates no tracked download. Sourced from `RegistrationMetaData` via ClosedPositionVW. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 18 | LotCount | numeric(16,6) | YES | Number of lots (trade size) for the closed position. Sourced from `ClosedPositionFromEtoro` (mapped as `Lots` in the production schema). (Tier 3 — no upstream wiki, grounded in DDL + Confluence "Trading Metadata" page) |
| 19 | BannerID | int | YES | Identifier of the marketing banner associated with the affiliate campaign. Value `0` indicates no banner attribution. Used as a grouping dimension in SP_Marketing_Cube aggregations. (Tier 3 — no upstream wiki, grounded in DDL + SP GROUP BY + sample data) |
| 20 | Valid | bit | YES | Commission eligibility flag computed in ClosedPositionVW. 1=eligible for commission calculation (72.5%, 26.7M rows), 0=disqualified from commission (27.5%, 10.1M rows). Positions with `Valid=1` are included in revenue and commission aggregations. (Tier 2 — ClosedPositionVW) |
| 21 | TrackingDate | datetime2(7) | YES | Date when the customer's registration was tracked for affiliate attribution. Per SP changelog (2023-04-30): "Take TrackingDate instead of RegistrationDate from [AffiliateCommission].[Registration] Fiktivo table." (Tier 3 — no upstream wiki, grounded in DDL + SP changelog) |
| 22 | IsProcessed | bit | YES | Commission processing status flag computed in ClosedPositionVW. 1=commission has been calculated (72.5%, 26.7M rows), 0=pending commission calculation (27.5%, 10.1M rows). (Tier 2 — ClosedPositionVW) |
| 23 | ValidFrom | datetime2(7) | YES | System-generated audit timestamp indicating when this record version became valid. Microsecond precision (e.g., `2026-03-24 10:35:07.891008`). Generated by the fiktivo system, not by the Synapse ETL. (Tier 2 — ClosedPositionVW) |
| 24 | UpdateDate | datetime2(7) | YES | System-generated timestamp of the last update to this record. Set by the fiktivo system upon commission recalculation or metadata refresh. (Tier 2 — ClosedPositionVW) |
| 25 | AdditionalData | varchar(max) | YES | Free-text field for supplementary data attached to the closed position. Empty string in all sampled rows. (Tier 3 — no upstream wiki, grounded in DDL + sample data) |
| 26 | etr_y | varchar(max) | YES | Lake partitioning column — year component extracted from the Bronze Parquet file path (`etr_y=YEAR(@date)`). Example: `2026`. (Tier 2 — SP_Create_fiktivo_AffiliateCommission_ClosedPosition) |
| 27 | etr_ym | varchar(max) | YES | Lake partitioning column — year-month component extracted from the Bronze Parquet file path (`etr_ym=LEFT(CAST(@date),7)`). Example: `2026-03`. (Tier 2 — SP_Create_fiktivo_AffiliateCommission_ClosedPosition) |
| 28 | etr_ymd | varchar(max) | YES | Lake partitioning column — full date extracted from the Bronze Parquet file path (`etr_ymd=@date`). Example: `2026-03-01`. (Tier 2 — SP_Create_fiktivo_AffiliateCommission_ClosedPosition) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| ClosedPositionID | fiktivo.AffiliateCommission.ClosedPositionFromEtoro | ClosedPositionID | Passthrough via ClosedPositionVW |
| CID | fiktivo.AffiliateCommission.ClosedPositionFromEtoro | CID | Passthrough via ClosedPositionVW |
| OriginalCID | fiktivo.AffiliateCommission.ClosedPositionFromEtoro | OriginalCID | Passthrough via ClosedPositionVW |
| NetProfit | fiktivo.AffiliateCommission.ClosedPositionFromEtoro | NetProfit | Computed in ClosedPositionVW |
| AffiliateID | fiktivo.AffiliateCommission.RegistrationMetaData | AffiliateID | Joined via CID in ClosedPositionVW |
| AffiliateCampaign | fiktivo.AffiliateCommission.RegistrationMetaData | AffiliateCampaign | Joined via CID in ClosedPositionVW |
| FunnelID | fiktivo.AffiliateCommission.RegistrationMetaData | FunnelID | Joined via CID in ClosedPositionVW |
| PlayerLevelID | fiktivo.AffiliateCommission.RegistrationMetaData | PlayerLevelID | Joined via CID in ClosedPositionVW |
| DownloadID | fiktivo.AffiliateCommission.RegistrationMetaData | DownloadID | Joined via CID in ClosedPositionVW |
| etr_y, etr_ym, etr_ymd | Lake path | File path components | Generated by SP_Create_fiktivo_AffiliateCommission_ClosedPosition |

### 5.2 ETL Pipeline

```
fiktivo.AffiliateCommission.ClosedPositionFromEtoro (Service Broker from etoro)
  + fiktivo.AffiliateCommission.RegistrationMetaData (affiliate metadata)
  |
  v
fiktivo.AffiliateCommission.ClosedPositionVW (production view, combines both)
  |-- Generic Pipeline (Bronze export, daily) ---|
  v
internal-sources/Bronze/fiktivo/AffiliateCommission/ClosedPositionVW/
  etr_y=YYYY/etr_ym=YYYY-MM/etr_ymd=YYYY-MM-DD/*.parquet
  |-- SP_Create_fiktivo_AffiliateCommission_ClosedPosition (COPY INTO, day loop) ---|
  v
BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube (36.8M rows)
  |-- SP_Marketing_Cube (daily, reads + aggregates) ---|
  v
BI_DB_dbo.Marketing_Cube (final marketing reporting table)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate dimension lookup |
| CountryID | DWH_dbo.Dim_Country | Country dimension lookup |
| FunnelID | DWH_dbo.Dim_Funnel | Funnel dimension lookup |
| ClosedPositionID | External_fiktivo_AffiliateCommission_ClosedPositionCommission | Commission details per position |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| (table) | BI_DB_dbo.SP_Marketing_Cube | Reads table for revenue, cost, and chargeback aggregations |

---

## 7. Sample Queries

### 7.1 Monthly Commission Revenue by Affiliate

```sql
SELECT
    sale.AffiliateID,
    CONVERT(VARCHAR(7), sale.CommissionDate, 120) AS Month,
    SUM(sale.Amount - ISNULL(sale.HedgeCommission, 0)) AS NetRevenue,
    COUNT(*) AS PositionCount
FROM [BI_DB_dbo].[fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube] sale
WHERE sale.Valid = 1
  AND sale.CommissionDate >= '2026-03-01'
  AND sale.CommissionDate < '2026-04-01'
GROUP BY sale.AffiliateID, CONVERT(VARCHAR(7), sale.CommissionDate, 120)
ORDER BY NetRevenue DESC;
```

### 7.2 Commission Details with Affiliate Name

```sql
SELECT TOP 100
    sale.ClosedPositionID,
    sale.CommissionDate,
    sale.Amount,
    sale.HedgeCommission,
    comm.Commission,
    comm.Tier,
    aff.AffiliateName
FROM [BI_DB_dbo].[fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube] sale
INNER JOIN [BI_DB_dbo].[External_fiktivo_AffiliateCommission_ClosedPositionCommission] comm
    ON sale.ClosedPositionID = comm.ClosedPositionID
INNER JOIN [DWH_dbo].[Dim_Affiliate] aff
    ON comm.AffiliateID = aff.AffiliateID
WHERE sale.CommissionDate >= '2026-04-01'
ORDER BY sale.CommissionDate DESC;
```

### 7.3 Pending vs Processed Position Breakdown by Country

```sql
SELECT
    sale.CountryID,
    dc.CountryName,
    SUM(CASE WHEN sale.IsProcessed = 1 THEN 1 ELSE 0 END) AS Processed,
    SUM(CASE WHEN sale.IsProcessed = 0 THEN 1 ELSE 0 END) AS Pending,
    SUM(ISNULL(sale.NetProfit, 0)) AS TotalNetProfit
FROM [BI_DB_dbo].[fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube] sale
LEFT JOIN [DWH_dbo].[Dim_Country] dc ON sale.CountryID = dc.CountryID
WHERE sale.CommissionDate >= '2026-03-01'
GROUP BY sale.CountryID, dc.CountryName
ORDER BY Processed DESC;
```

---

## 8. Atlassian Knowledge Sources

- [Affiliate Commissions: Trading Metadata](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11886723662) — Documents the ClosedPositionFromEtoro schema and Service Broker data flow.
- [Affiliate Commissions: Separate Meta data from tracking tables](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11888099425) — Explains the separation of FunnelID, PlayerLevelID, DownloadID, AffiliateCampaign into RegistrationMetaData.
- [Affiliate - Data migration](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/11643322541) — Migration context for AffiliateCommission tables from legacy to fiktivo.
- [Affiliate Commission - Trading Data using Data Lake - HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12414222337) — Architecture for importing trading data from etoro to fiktivo via Data Lake.

---

PHASE GATE — BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (no views reference this table)
  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 13/14 (P7 skipped — no view dependencies, P16 deferred to judge)*
*Tiers: 0 T1, 9 T2, 19 T3, 0 T4, 0 T5 | Elements: 28/28, Logic: 7/10, Lineage: 8/10*
*Object: BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube | Type: Table | Production Source: fiktivo.AffiliateCommission.ClosedPositionVW (dormant — no upstream wiki)*
