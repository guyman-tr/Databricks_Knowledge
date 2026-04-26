# BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual

Generated: 2026-04-21 | Writer SP: SP_M_Active_Affiliate_Monthly | Batch 13 #2

## Business Meaning

Monthly affiliate performance summary combining **planned targets** with **actual results**, reported at two aggregation levels within a single table. The `Indicator` column discriminates the row type:

- **'Desk'** (697 rows): Desk-level aggregation. Planned target columns (NewAffWithFTDPlaaned, TotalActiveAffPlaaned, ChurnPlaaned, TotalFTDsPlaaned) are populated via LEFT JOIN to BI_DB_ActiveAffiliatesPlanned.
- **'NewMarketingRegion'** (1,131 rows): Marketing-region-level aggregation added in July 2021. Planned columns are NULL — no planned targets exist at this grain.
- **NULL** (507 rows): Historical rows predating the July 2021 UNION restructuring. Functionally equivalent to Desk-level rows.

Affiliates are sourced exclusively from channels 'Affiliate' and 'Introducing Agents' (via Dim_Channel filter). The SP loads data for the **previous** month on each run.

**Row count**: 2,335 | **Date range**: 2015-12-01 to 2026-03-01 | **Grain**: Month × Indicator × (Desk or NewMarketingRegion)

---

## Business Logic

### Month-lag Design
The SP parameter `@date` resolves to the first day of the **previous** month: `DATEADD(MONTH, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0))`. Running the SP in April loads March data. `YearMonth` = `CONVERT(VARCHAR(7), @StartDate, 126)`.

### Two Aggregation Branches (UNION)
1. **Branch 1 — Desk-level**: Groups BI_DB_CIDFirstDates events by Desk (derived via Dim_Country.Region → Desk join), aggregates actual metrics, then LEFT JOINs BI_DB_ActiveAffiliatesPlanned on Desk + YearMonth to attach planned targets. Sets `Indicator = 'Desk'`.
2. **Branch 2 — NewMarketingRegion-level** (added 2021-07): Groups by NewMarketingRegion directly from BI_DB_CIDFirstDates. Planned columns hard-coded to NULL. Sets `Indicator = 'NewMarketingRegion'`.

Both branches are UNIONed and inserted after a DELETE of the target month's rows.

### New Affiliate Logic
An affiliate is "new" in a month if the minimum registration date (for Reg counts) or minimum FTD date (for FTD counts) falls within the target year: `HAVING YEAR(MIN(date)) >= YEAR(@StartDate)`. Test affiliates (`AffiliatesGroupsName LIKE '%test%'`) are excluded from New* subqueries only — they may appear in TotalActive* counts.

### Planned Target Join
Planned columns are populated for 'Desk' rows by LEFT JOIN to BI_DB_ActiveAffiliatesPlanned on (Desk, YearMonth). Any Desk with no plan record receives NULL planned values. All planned columns are NULL for 'NewMarketingRegion' rows.

---

## Query Advisory

- **Always filter on `Indicator`** when selecting one aggregation level. Mixing rows without a filter double-counts the affiliate base — 'Desk' and 'NewMarketingRegion' rows cover the same underlying affiliates for any given month.
- **Include NULL Indicator rows as Desk-equivalent** if historical coverage is required: `WHERE Indicator = 'Desk' OR Indicator IS NULL`.
- **Planned columns are only valid for Indicator = 'Desk'** — avoid aggregating planned columns across both row types.
- **ROUND_ROBIN distribution, CLUSTERED INDEX on Date** — range predicates on `Date` are efficient; point queries on `Desk` or `Indicator` benefit from a `Date` range predicate to avoid full scans.

---

## Elements

| # | Column | Type | Description | Tier |
|---|--------|------|-------------|------|
| 1 | Desk | VARCHAR(50) | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join (a.MarketingRegionID = b.RegionID). Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no desk mapping for this marketing region. | Tier 1 — DWH_dbo.Dim_Country |
| 2 | Date | DATE | First day of the target (previous) month. Derived as DATEADD(MONTH,-1, first-day-of-current-month). The SP always loads data for the prior month. | Tier 2 |
| 3 | YearMonth | VARCHAR(7) | ISO year-month string (e.g. "2026-03") derived from @StartDate via CONVERT(VARCHAR(7), @StartDate, 126). | Tier 2 |
| 4 | NewAffWithRegistretActual | INT | Count of distinct affiliates whose first-ever registration (BI_DB_CIDFirstDates.registered) falls within the target month. Test affiliates excluded. Legacy typo "Registret" preserved from DDL. | Tier 2 |
| 5 | NewAffWithFTDActual | INT | Count of distinct affiliates whose first-ever FTD (BI_DB_CIDFirstDates.FirstDepositDate) falls within the target month. Test affiliates excluded. | Tier 2 |
| 6 | TotalActiveAffRegistretActual | INT | Count of distinct affiliates with at least one registration from an affiliate-sourced client in the target month. Test affiliates NOT excluded (see review notes). Legacy typo "Registret" preserved from DDL. | Tier 2 |
| 7 | TotalActiveAffFTDActual | INT | Count of distinct affiliates with at least one FTD from an affiliate-sourced client in the target month. Test affiliates NOT excluded. | Tier 2 |
| 8 | TotalRegistretActual | INT | Sum of total registrations from clients sourced by affiliates in the target month. Legacy typo "Registret" preserved from DDL. | Tier 2 |
| 9 | TotalFTDsActual | INT | Sum of total First Time Deposits from clients sourced by affiliates in the target month. | Tier 2 |
| 10 | NewAffWithFTDPlaaned | INT | Planned target: count of new affiliates with FTD for this Desk and month. Sourced from BI_DB_ActiveAffiliatesPlanned via LEFT JOIN. NULL for Indicator='NewMarketingRegion'. Legacy typo "Plaaned" preserved from DDL. | Tier 2 |
| 11 | TotalActiveAffPlaaned | INT | Planned target: count of total active affiliates for this Desk and month. Sourced from BI_DB_ActiveAffiliatesPlanned via LEFT JOIN. NULL for Indicator='NewMarketingRegion'. Legacy typo "Plaaned" preserved from DDL. | Tier 2 |
| 12 | ChurnPlaaned | FLOAT | Planned churn rate for this Desk and month. Sourced from BI_DB_ActiveAffiliatesPlanned via LEFT JOIN. NULL for Indicator='NewMarketingRegion'. FLOAT type (unlike other INT planned columns — likely a ratio). Legacy typo "Plaaned" preserved from DDL. | Tier 2 |
| 13 | TotalFTDsPlaaned | INT | Planned target: total FTDs for this Desk and month. Sourced from BI_DB_ActiveAffiliatesPlanned via LEFT JOIN. NULL for Indicator='NewMarketingRegion'. Legacy typo "Plaaned" preserved from DDL. | Tier 2 |
| 14 | UpdateDate | DATETIME | ETL metadata: timestamp when the row was inserted, set via GETDATE() at INSERT time. | Tier 5 |
| 15 | Indicator | VARCHAR(20) | Row type discriminator. 'Desk' = desk-level aggregation with planned targets; 'NewMarketingRegion' = marketing-region-level aggregation (added 2021-07); NULL = historical rows predating the UNION restructuring (507 rows, functionally Desk-level). | Tier 2 |
| 16 | NewMarketingRegion | VARCHAR(50) | Marketing region name for 'NewMarketingRegion' indicator rows (29 distinct values). NULL for 'Desk' rows. Sourced directly from BI_DB_CIDFirstDates.NewMarketingRegion. | Tier 2 |

**Tier legend**: Tier 1 = value/description inherited verbatim from upstream DWH_dbo wiki. Tier 2 = derived by SP/ETL logic. Tier 5 = canonical ETL metadata column (UpdateDate, ETL timestamp).

---

## Lineage

See [BI_DB_ActiveAffiliatesPlanned_Actual.lineage.md](BI_DB_ActiveAffiliatesPlanned_Actual.lineage.md) for full ETL chain, column lineage table, and source objects.

```
BI_DB_CIDFirstDates + Dim_Affiliate + Dim_Channel + Dim_Country
  |-- UNION [Branch 1: Desk-level + LEFT JOIN BI_DB_ActiveAffiliatesPlanned]
  |-- UNION [Branch 2: NewMarketingRegion-level, planned=NULL]
  v
SP_M_Active_Affiliate_Monthly (@date — Monthly, SB_Daily, Priority 20)
  DELETE WHERE Date = @StartDate → INSERT
  v
BI_DB_ActiveAffiliatesPlanned_Actual (2,335 rows)
  v [UC Target: _Not_Migrated]
```

**Distribution**: ROUND_ROBIN | **Index**: CLUSTERED (Date ASC) | **UC Target**: _Not_Migrated

---

## Relationships

| Object | Schema | Type | Join Key | Purpose |
|--------|--------|------|----------|---------|
| BI_DB_CIDFirstDates | BI_DB_dbo | Source | SerialID → AffiliateID | Primary event data: registration/FTD dates, Region, NewMarketingRegion |
| Dim_Affiliate | DWH_dbo | Dimension | SerialID = AffiliateID | SubChannelID (channel filter), AffiliatesGroupsName (test exclusion) |
| Dim_Channel | DWH_dbo | Filter | SubChannelID | Channel IN ('Affiliate', 'Introducing Agents') |
| Dim_Country | DWH_dbo | Dimension | Region / MarketingRegionManualName | Desk mapping for Branch 1; NMR label for Branch 2 |
| BI_DB_ActiveAffiliatesPlanned | BI_DB_dbo | Planned targets | Desk + YearMonth | NewAffWithFTD, TotalActiveAff, Churn, TotalFTDs planned values (Desk rows only) |

---

## Sample Queries

```sql
-- Desk-level actual vs planned for a specific month
SELECT
    Desk,
    TotalFTDsActual,
    TotalFTDsPlaaned,
    CASE WHEN TotalFTDsPlaaned > 0
         THEN CAST(TotalFTDsActual AS FLOAT) / TotalFTDsPlaaned
         ELSE NULL END AS FTD_Achievement_Rate
FROM BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual
WHERE Date = '2026-03-01'
  AND Indicator = 'Desk'
ORDER BY TotalFTDsActual DESC;

-- NewMarketingRegion breakdown (actuals only, no planned)
SELECT
    NewMarketingRegion,
    TotalFTDsActual,
    TotalActiveAffFTDActual
FROM BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual
WHERE Date = '2026-03-01'
  AND Indicator = 'NewMarketingRegion'
ORDER BY TotalFTDsActual DESC;

-- Monthly trend: FTDs by Desk (including historical NULL Indicator rows)
SELECT
    Date,
    Desk,
    TotalFTDsActual
FROM BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual
WHERE Date >= DATEADD(MONTH, -12, '2026-03-01')
  AND (Indicator = 'Desk' OR Indicator IS NULL)
ORDER BY Date DESC, TotalFTDsActual DESC;
```

---

## Atlassian

**Confluence**: No dedicated page identified.
**Jira**: No open tickets identified.

---

Quality: 8.5/10
