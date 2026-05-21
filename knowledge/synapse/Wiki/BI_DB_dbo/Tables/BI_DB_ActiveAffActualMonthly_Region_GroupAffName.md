# BI_DB_dbo.BI_DB_ActiveAffActualMonthly_Region_GroupAffName

> 55,724-row monthly affiliate performance aggregation table tracking actual registrations, First Time Deposits (FTDs), and deposit amounts by Desk × Region × Affiliate Group Name from 2017-01 to 2026-03. Each row represents one combination of month × desk × region × affiliate group, populated monthly by `SP_M_Active_Aff_Monthly_Region_GroupAff` using a DELETE+INSERT per-month pattern.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_CIDFirstDates + DWH_dbo.Dim_Affiliate (via SP_M_Active_Aff_Monthly_Region_GroupAff) |
| **Refresh** | Monthly — DELETE WHERE Date = @StartDate + INSERT. Parameterized by @date. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_ActiveAffActualMonthly_Region_GroupAffName` is a monthly affiliate performance summary table. Each row represents one combination of **calendar month × sales desk × marketing region × affiliate group name**, and provides the following actual performance metrics:

- **New affiliates** who brought their *first-ever* customer registration or FTD in that month (`NewAffWithRegistretActual`, `NewAffWithFTDActual`)
- **Total active affiliates** who brought any registration or FTD in that month (`TotalActiveAffRegistretActual`, `TotalActiveAffFTDActual`)
- **Volume metrics**: total registrations, total FTDs, and total deposit amount

The table covers 2017-01-01 through 2026-03-01 (109 months), refreshed monthly with 55,724 rows across 13 distinct desk segments. It is authored by Eti Rozolio and was created in April 2020.

The ETL filters affiliate channels exclusively: only affiliates with `Channel IN ('Affiliate', 'Introducing Agents')` from `DWH_dbo.Dim_Channel` are included. This excludes direct, organic, and paid social channels.

**Grain**: One row per `(Date, Desk, Region, AffiliatesGroupsName)`. Note that `Date` = first day of the month (e.g., 2024-03-01 = March 2024 data). `YearMonth` is the year-month of the actual registration/FTD event (may lag the Date period in edge cases due to FULL OUTER JOIN logic).

---

## 2. Business Logic

### 2.1 "New Affiliate" vs "Total Active" Distinction

**What**: Distinguishes between affiliates appearing for the first time in the period vs. all affiliates with any activity.

**Columns Involved**: `NewAffWithRegistretActual`, `NewAffWithFTDActual`, `TotalActiveAffRegistretActual`, `TotalActiveAffFTDActual`

**Rules**:
- **New** = COUNT(DISTINCT AffiliateID) WHERE their very first-ever registration (MIN of all-time registered) OR first-ever FTD (MIN of all-time FirstDepositDate) falls within the target month. Filter: `YEAR(MIN(date)) >= YEAR(@StartDate)` constrains to affiliates who started in or after @StartDate's year.
- **Total Active** = COUNT(DISTINCT AffiliateID) WHERE that affiliate brought ≥1 registration or ≥1 FTD during the month (not necessarily first-time).
- New ≤ Total Active always. A new affiliate is always also total active.

### 2.2 FULL OUTER JOIN Registration+FTD Pattern

**What**: Combines registration data and FTD data with FULL OUTER JOIN so a Desk/Region/Group appears even if it only had registrations or only had FTDs in the month.

**Columns Involved**: All columns. `NewAffWithRegistretActual`, `NewAffWithFTDActual` can be NULL.

**Rules**:
- `#FTDs` (monthly FTD stats) and `#Regs` (monthly registration stats) are built independently, then FULL OUTER JOINed.
- `ISNULL(r.YearMonth_Reg, f.YearMonth_FTD)` coalesces to whichever stream has data.
- If an affiliate group had FTDs but no registrations that month: `TotalRegistretActual = 0`, `TotalFTDsActual > 0`, `NewAffWithRegistretActual = NULL`.
- If an affiliate group had registrations but no FTDs that month: vice versa.

### 2.3 Desk/Region Mapping

**What**: Geographic desk and marketing region dimensions are resolved from BI_DB_CIDFirstDates.Region via a Dim_Country lookup.

**Columns Involved**: `Desk`, `Region`

**Rules**:
- `SELECT DISTINCT Region, Desk FROM DWH_dbo.Dim_Country` is joined on `bdcd.Region = dco.Region`.
- This means only customers whose `Region` matches a known `Dim_Country.Region` value are included.
- Desk reflects the sales/support team assignment for that marketing region (13 desks: ROW, Other EU, Asia, Arabic, French, UK, South & Central America, German, USA, Spain, Australia, Italian, Unknown).

### 2.4 "Registret" Typo in Column Names

**What**: Column names contain "Registret" instead of "Registered" — a deliberate or historical typo preserved across all schema versions.

**Columns Involved**: `NewAffWithRegistretActual`, `TotalActiveAffRegistretActual`, `TotalRegistretActual`

**Rules**: This typo is embedded in the DDL and must be matched exactly in all queries. There is no "Registered" variant.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — no distribution advantage. Any column can be used for filters without shuffle concerns.
- **Index**: CLUSTERED on `Date` ASC — queries filtering on the `Date` column (month selection) will benefit from the clustered index scan.
- **Best practice**: Always filter on `Date` (first day of month) for period-specific queries. Avoid GROUP BY on multiple high-cardinality columns simultaneously.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly FTD volume by desk for last 12 months | `WHERE Date >= DATEADD(MONTH,-12,GETDATE()) GROUP BY Desk, Date` |
| Which affiliate groups are generating the most new affiliates? | `GROUP BY AffiliatesGroupsName ORDER BY SUM(NewAffWithFTDActual) DESC` |
| YoY affiliate acquisition trend by region | `GROUP BY Region, YEAR(Date), MONTH(Date)` |
| Affiliate performance for a specific desk in a quarter | `WHERE Desk = 'UK' AND Date BETWEEN '2025-01-01' AND '2025-03-01'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual | `Date = Date AND Desk = Desk` | Actual vs planned affiliate KPIs |
| DWH_dbo.Dim_Affiliate | (No direct FK — AffiliatesGroupsName is a string group label, not AffiliateID) | Extended affiliate metadata if needed |
| DWH_dbo.Dim_Country | `Region = Region` | Resolve Region to CountryID-level attributes |

### 3.4 Gotchas

- **"Registret" typo**: Column names use `Registret` not `Registered`. Autocomplete tools may suggest the wrong name.
- **NULL metrics vs zero**: `NewAffWithRegistretActual = NULL` means no registration stream for that combination (FULL OUTER JOIN). `NewAffWithRegistretActual = 0` means the stream existed but yielded zero. Check for both NULL and zero when computing totals.
- **YearMonth ≠ CONVERT(VARCHAR(7), Date, 126)** in some rows: `YearMonth` is derived from the event date (registration/FTD actual date), while `Date` is the first day of the target month parameter. In most cases they match, but edge cases (late month data) may differ.
- **Desk = 'Unknown' (89 rows)**: Affiliate registrations where the Region had no Desk mapping in Dim_Country. Treat as uncategorized.
- **Monthly not daily**: `Date` always equals the first day of the month. Never query for an interior date within a month.
- **"New" affiliate filter year restriction**: `YEAR(MIN(date)) >= YEAR(@StartDate)` means "new affiliates" excludes historical records where the affiliate first appeared before @StartDate's year. This may under-count for the first months of a new year.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream documented wiki (DWH_dbo layer) |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | Inferred from column name, data patterns, or indirect evidence |
| Tier 4 | Best-available guess — low confidence, flagged for review |
| Tier 5 | Canonical ETL infrastructure column (propagation table) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | First day of the reporting month (e.g., 2024-03-01 = March 2024 metrics). Set from @StartDate = DATEADD(MONTH,0, first-day-of-month(@date)). Filter by this column for period selection. (Tier 2 — SP_M_Active_Aff_Monthly_Region_GroupAff) |
| 2 | YearMonth | varchar(7) | YES | Year-month string (YYYY-MM format) of the registration or FTD event. Derived from ISNULL(YearMonth_Reg, YearMonth_FTD) — coalesces to whichever event stream exists. In most cases equals CONVERT(VARCHAR(7), Date, 126), but may differ in edge cases. (Tier 2 — SP_M_Active_Aff_Monthly_Region_GroupAff) |
| 3 | Desk | varchar(50) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join (a.MarketingRegionID = b.RegionID). Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no desk mapping for this marketing region. Passthrough GROUP BY dimension from DWH_dbo.Dim_Country. (Tier 3 — DWH_dbo.Dim_Country) |
| 4 | Region | varchar(50) | YES | Marketing region label for this country. Loaded from Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. Up to 21 distinct values (e.g., "ROW", "Africa", "French", "Arabic"). Used for marketing campaign grouping. |
| 5 | AffiliatesGroupsName | varchar(50) | YES | Marketing group the affiliate belongs to. From DWH_dbo.Dim_Affiliate.AffiliatesGroupsName. Filtered to Channel IN ('Affiliate', 'Introducing Agents'). Values include individual affiliate manager names (e.g., "Paul Familiaran") and group labels (e.g., "South East Asia", "Archive / dead Affiliates"). Passthrough GROUP BY dimension from DWH_dbo.Dim_Affiliate. (Tier 2 — DWH_dbo.Dim_Affiliate) |
| 6 | NewAffWithRegistretActual | int | YES | Count of distinct affiliates whose very first customer registration occurred during this month (MIN registration date falls within @StartDate). Note: "Registret" is a historical typo in the column name. NULL if this Desk/Region/Group had FTDs but no registrations that month (FULL OUTER JOIN artefact). Range: 0–5,888. (Tier 2 — SP_M_Active_Aff_Monthly_Region_GroupAff) |
| 7 | NewAffWithFTDActual | int | YES | Count of distinct affiliates whose very first customer FTD (First Time Deposit) occurred during this month (MIN FirstDepositDate falls within @StartDate). NULL if this Desk/Region/Group had registrations but no FTDs that month (FULL OUTER JOIN artefact). Range: 0–52. (Tier 2 — SP_M_Active_Aff_Monthly_Region_GroupAff) |
| 8 | TotalActiveAffRegistretActual | int | YES | Count of distinct affiliates who brought ≥1 customer registration during this month (any registration, not just first-time). COUNT(DISTINCT AffiliateID WHERE REGs>0). Note: "Registret" is a historical typo. Range: 0–6,054. (Tier 2 — SP_M_Active_Aff_Monthly_Region_GroupAff) |
| 9 | TotalActiveAffFTDActual | int | YES | Count of distinct affiliates who brought ≥1 customer FTD during this month (any FTD). COUNT(DISTINCT AffiliateID WHERE FTD>0). Range: 0–159. (Tier 2 — SP_M_Active_Aff_Monthly_Region_GroupAff) |
| 10 | TotalRegistretActual | int | YES | Total count of customer registrations brought by all affiliates in this month. SUM of individual affiliate registration counts. Note: "Registret" is a historical typo. Range: 0–30,498. (Tier 2 — SP_M_Active_Aff_Monthly_Region_GroupAff) |
| 11 | TotalFTDsActual | int | YES | Total count of customer First Time Deposits generated by affiliates in this month. SUM of individual affiliate FTD counts. Range: 0–9,149. (Tier 2 — SP_M_Active_Aff_Monthly_Region_GroupAff) |
| 12 | Amount_FTDs | money | YES | Total first deposit amount (USD) generated by affiliates in this month. SUM(FirstDepositAmount) from BI_DB_CIDFirstDates. Includes all FTDs in this Desk/Region/Group for the month. (Tier 2 — SP_M_Active_Aff_Monthly_Region_GroupAff) |
| 13 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — canonical propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | SP parameter | @date | DATEADD(MONTH,0, first-day-of-month(@date)) |
| YearMonth | BI_DB_CIDFirstDates | registered / FirstDepositDate | CONVERT(VARCHAR(7), date, 126) — ISNULL(Reg,FTD) |
| Desk | DWH_dbo.Dim_Country | Desk | Passthrough via Region join |
| Region | DWH_dbo.Dim_Country | Region | Passthrough GROUP BY |
| AffiliatesGroupsName | DWH_dbo.Dim_Affiliate | AffiliatesGroupsName | Passthrough GROUP BY |
| NewAffWithRegistretActual | BI_DB_CIDFirstDates | registered | COUNT DISTINCT first-reg affiliates |
| NewAffWithFTDActual | BI_DB_CIDFirstDates | FirstDepositDate | COUNT DISTINCT first-FTD affiliates |
| TotalActiveAffRegistretActual | BI_DB_CIDFirstDates | registered | COUNT DISTINCT active-reg affiliates |
| TotalActiveAffFTDActual | BI_DB_CIDFirstDates | FirstDepositDate | COUNT DISTINCT active-FTD affiliates |
| TotalRegistretActual | BI_DB_CIDFirstDates | registered | SUM registrations |
| TotalFTDsActual | BI_DB_CIDFirstDates | FirstDepositDate | SUM FTDs |
| Amount_FTDs | BI_DB_CIDFirstDates | FirstDepositAmount | SUM FTD amounts |
| UpdateDate | ETL | GETDATE() | Insert-time timestamp |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_CIDFirstDates (registered, SerialID, FirstDepositDate, FirstDepositAmount, Region)
  |
  |-- JOIN DWH_dbo.Dim_Affiliate (SerialID = AffiliateID) [filter: Channel IN ('Affiliate','Introducing Agents')]
  |-- JOIN DWH_dbo.Dim_Channel (SubChannelID)
  |-- JOIN DWH_dbo.Dim_Country (Region → Desk)
  |
  |-- [SP_M_Active_Aff_Monthly_Region_GroupAff @date — Monthly, SB_Daily process, Priority 20]
  |-- [5 temp tables: #FTDs → #Regs → #TotalsRegsFTDs → #FirstFTDsRaw → #FirstRegRaw]
  |-- [DELETE WHERE Date = @StartDate + INSERT]
  v
BI_DB_dbo.BI_DB_ActiveAffActualMonthly_Region_GroupAffName
  (55,724 rows | 2017-01 to 2026-03 | Monthly grain)
  |
  v [UC Target: _Not_Migrated]
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AffiliatesGroupsName | DWH_dbo.Dim_Affiliate | Group label sourced from Dim_Affiliate; no FK constraint |
| Desk | DWH_dbo.Dim_Country | Desk value from Dim_Country.Desk |
| Region | DWH_dbo.Dim_Country | Region label from Dim_Country.Region |
| (implicit) | BI_DB_dbo.BI_DB_CIDFirstDates | All count/amount metrics are derived from CIDFirstDates |

### 6.2 Referenced By (other objects point to this)

| Object | Reference |
|--------|-----------|
| BI_DB_dbo.BI_DB_ActiveAffiliatesPlanned_Actual | Likely joined for planned vs actual comparisons (same Desk/Date grain) |

---

## 7. Sample Queries

### Monthly FTDs by Desk for Last 12 Months

```sql
SELECT
    Date,
    Desk,
    SUM(TotalFTDsActual)           AS TotalFTDs,
    SUM(Amount_FTDs)               AS TotalFTDAmount,
    SUM(TotalActiveAffFTDActual)   AS ActiveAffiliates
FROM [BI_DB_dbo].[BI_DB_ActiveAffActualMonthly_Region_GroupAffName]
WHERE Date >= DATEADD(MONTH, -12, DATEADD(DAY, 1-DAY(GETDATE()), CAST(GETDATE() AS date)))
GROUP BY Date, Desk
ORDER BY Date DESC, TotalFTDs DESC
```

### Top Affiliate Groups by New Affiliate Acquisition (YTD)

```sql
SELECT
    AffiliatesGroupsName,
    SUM(ISNULL(NewAffWithFTDActual, 0))       AS NewAffWithFTD,
    SUM(ISNULL(NewAffWithRegistretActual, 0)) AS NewAffWithReg,
    SUM(TotalFTDsActual)                       AS TotalFTDs
FROM [BI_DB_dbo].[BI_DB_ActiveAffActualMonthly_Region_GroupAffName]
WHERE Date >= '2026-01-01'
  AND Desk <> 'Unknown'
GROUP BY AffiliatesGroupsName
ORDER BY NewAffWithFTD DESC
```

### Activation Rate by Region (FTD Conversion)

```sql
SELECT
    Region,
    SUM(TotalRegistretActual)          AS TotalRegs,
    SUM(TotalFTDsActual)               AS TotalFTDs,
    CAST(SUM(TotalFTDsActual) * 100.0
         / NULLIF(SUM(TotalRegistretActual), 0)
         AS decimal(5,1))              AS FTDConversionPct
FROM [BI_DB_dbo].[BI_DB_ActiveAffActualMonthly_Region_GroupAffName]
WHERE Date >= '2025-01-01'
GROUP BY Region
ORDER BY TotalFTDs DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources were scanned in this session (Atlassian MCP not connected). The table was authored by Eti Rozolio (SP header comment, 2020-04-21). No additional context sources identified.

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 13/14 (P10 Atlassian skipped)*
*Tiers: 3 T1, 9 T2, 0 T3, 0 T4, 1 T5 | Elements: 13/13, Logic: 4 subsections*
*Object: BI_DB_dbo.BI_DB_ActiveAffActualMonthly_Region_GroupAffName | Type: Table | Source: BI_DB_CIDFirstDates + DWH_dbo dimensions*
