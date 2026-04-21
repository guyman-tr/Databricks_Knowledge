# eMoney_dbo.eMoney_Dim_Country_Rollout

> 34-row static dimension listing the 34 countries where eToro Money (eMoney) is currently live, with each country's official rollout date, geographic region, and sales desk. Populated daily by `SP_eMoney_Dim_Country_Rollout` from `DWH_dbo.Dim_Country` using hardcoded CASE expressions; only countries whose rollout date has already passed are stored.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Country (filtered to 34 eMoney-eligible countries, rollout dates hardcoded in SP) |
| **Refresh** | Daily — DELETE + INSERT full refresh via SP_eMoney_Dim_Country_Rollout |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override strategy, daily) |

---

## 1. Business Meaning

`eMoney_Dim_Country_Rollout` is the authoritative reference table for the eToro Money (eMoney) geographic rollout: it lists every country that has gone live on the platform and the date it did so. As of 2026-04-12 there are **34 rows** covering rollouts from 2020-11-01 (United Kingdom, the first market) through 2025-10-15 (Australia, the most recent addition). The table is replicated across all Synapse distributions and refreshed daily. Downstream SPs — including the Acquisition Funnel, Card Monthly Snapshot, and AM Target reports — JOIN to this table to determine which customers are in active eToro Money markets. Only countries whose rollout date has already passed appear in the table; future rollout dates coded in the SP are suppressed until that date arrives.

Key business facts:
- 34 active countries across 9 regions and 7 sales desks
- UK launched first (2020-11-01); Australia joined latest (2025-10-15)
- Countries are filtered by `IsCountryOpen = CASE WHEN RolloutDate <= GETDATE()` — future rollouts are coded but not yet visible

---

## 2. Business Logic

### 2.1 Country Eligibility Filter

**What**: Only countries whose rollout date has passed are stored. This gives a "currently live" snapshot rather than a full schedule.
**Columns Involved**: RolloutDate
**Rules**:
- SP computes `IsCountryOpen = CASE WHEN RolloutDate <= @TodayDate THEN 1 ELSE 0 END`
- Only rows where `IsCountryOpen = 1` are inserted
- Future rollout dates can be coded into the SP; they will appear in the table once the date passes

### 2.2 Rollout Date Encoding

**What**: RolloutDate is duplicated as an integer YYYYMMDD key for joining to Dim_Date.
**Columns Involved**: RolloutDate, RolloutDateID
**Rules**:
- `RolloutDateID = CAST(CONVERT(VARCHAR(8), RolloutDate, 112) AS INT)`
- Example: 2020-11-01 → 20201101
- Used by downstream SPs to join to `DWH_dbo.Dim_Date` for date dimension enrichment

### 2.3 Region / Desk Hierarchy

**What**: Countries are tagged with a geographic region and a sales desk, inherited from DWH_dbo.Dim_Country.
**Columns Involved**: Region, Desk
**Rules**:
- Region is broader (9 values: UK, French, Spanish, Italian, Eastern Europe, North Europe, German, ROE, Australia)
- Desk is the sales team responsible (7 values: UK, French, Spanish, Italian, Other EU, German, Australia)
- Countries in "French" region (France, Monaco, Luxembourg, Belgium) share the "French" desk
- "Eastern Europe" (11 countries) and "North Europe" (6 countries) both map to "Other EU" desk
- "ROE" (Rest of Europe) also maps to "Other EU" desk (3 countries)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution means this table is fully copied to every Synapse distribution node. With only 34 rows this is optimal — no data movement for any JOIN. HEAP index is appropriate for a small static lookup.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which countries are live on eToro Money? | `SELECT CountryName, RolloutDate, Region, Desk FROM eMoney_dbo.eMoney_Dim_Country_Rollout ORDER BY RolloutDate` |
| How many countries per region? | `SELECT Region, COUNT(*) FROM eMoney_dbo.eMoney_Dim_Country_Rollout GROUP BY Region` |
| Join customers to their eMoney country status | `INNER JOIN eMoney_dbo.eMoney_Dim_Country_Rollout dcr ON customer.CountryID = dcr.CountryID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `Dim_Customer.CountryID = eMoney_Dim_Country_Rollout.CountryID` | Filter customers in active eMoney markets |
| DWH_dbo.Dim_Date | `Dim_Date.DateKey = eMoney_Dim_Country_Rollout.RolloutDateID` | Enrich rollout date with calendar dimensions |

### 3.4 Gotchas

- **Future rollout dates suppressed**: Australia (CountryID=12) rollout date 2025-10-15 was coded by Shachar Rubin; it appeared in the table only after that date. If you need to see future planned rollouts, you must read the SP directly — the table never shows upcoming entries.
- **No IsActive flag**: There is no column explicitly marking a country as inactive. Every row in this table IS active by definition (the filter was applied at insert time).
- **CountryID is eToro's internal ID**: Not ISO 3166 — joins should go through DWH_dbo.Dim_Country or eMoney_Country_Codes_Mapping_ISO for ISO mapping.
- **UpdateDate is batch-level**: All rows share the same UpdateDate (GETDATE() at SP execution). It reflects the last full refresh, not individual country updates.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived or computed by ETL SP — no direct production source column |
| Tier 4 | Passthrough from DWH_dbo.Dim_Country — source undocumented (no wiki for Dim_Country yet) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | YES | eToro internal country identifier. Passthrough from DWH_dbo.Dim_Country.CountryID. Filtered by SP to 34 eMoney-eligible countries. FK usage: JOIN to DWH_dbo.Dim_Customer.CountryID. (Tier 4 — DWH_dbo.Dim_Country) |
| 2 | CountryName | varchar(50) | YES | Country display name. Sourced from DWH_dbo.Dim_Country.Name (renamed CountryName by SP). Examples: United Kingdom, Cyprus, Ireland, Romania. (Tier 4 — DWH_dbo.Dim_Country) |
| 3 | RolloutDate | date | YES | Official launch date when eToro Money became available in this country. Hardcoded in SP_eMoney_Dim_Country_Rollout as a CASE expression per CountryID (34 entries). UK first at 2020-11-01, Australia most recent at 2025-10-15. Only dates ≤ today are present. (Tier 2 — SP_eMoney_Dim_Country_Rollout) |
| 4 | RolloutDateID | int | YES | Integer YYYYMMDD encoding of RolloutDate. Computed as CAST(CONVERT(VARCHAR(8), RolloutDate, 112) AS INT). Used for joining to DWH_dbo.Dim_Date. Example: 2020-11-01 → 20201101. (Tier 2 — SP_eMoney_Dim_Country_Rollout) |
| 5 | Region | varchar(50) | YES | Broad geographic grouping. 9 values: UK, French, Spanish, Italian, Eastern Europe, North Europe, German, ROE, Australia. Passthrough from DWH_dbo.Dim_Country.Region. (Tier 4 — DWH_dbo.Dim_Country) |
| 6 | Desk | varchar(50) | YES | Sales desk responsible for the country. 7 values: UK, French, Spanish, Italian, Other EU, German, Australia. Eastern Europe, North Europe, and ROE regions all map to "Other EU" desk. Passthrough from DWH_dbo.Dim_Country.Desk. (Tier 4 — DWH_dbo.Dim_Country) |
| 7 | UpdateDate | datetime | YES | Timestamp of the most recent SP execution. Set to GETDATE() at insert time; all 34 rows share the same value per refresh. Last observed: 2026-04-12 06:24:35. (Tier 2 — SP_eMoney_Dim_Country_Rollout) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CountryID | DWH_dbo.Dim_Country | CountryID | Passthrough, filtered to 34 countries |
| CountryName | DWH_dbo.Dim_Country | Name | Renamed: Name → CountryName |
| RolloutDate | SP_eMoney_Dim_Country_Rollout | — | Hardcoded CASE per CountryID |
| RolloutDateID | SP_eMoney_Dim_Country_Rollout | — | CAST(CONVERT(VARCHAR(8), RolloutDate, 112) AS INT) |
| Region | DWH_dbo.Dim_Country | Region | Passthrough |
| Desk | DWH_dbo.Dim_Country | Desk | Passthrough |
| UpdateDate | SP_eMoney_Dim_Country_Rollout | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Country (cross-schema source, all countries)
  + Hardcoded rollout dates CASE per CountryID (34 entries in SP)
  + IsCountryOpen filter: WHERE RolloutDate <= GETDATE()
    |-- SP_eMoney_Dim_Country_Rollout (DELETE + INSERT, daily) ---|
    v
eMoney_dbo.eMoney_Dim_Country_Rollout (34 rows, REPLICATE HEAP)
    |-- Generic Pipeline (Override, delta, daily) ---|
    v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_country_rollout
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country | Source country dimension — SP reads Name, Region, Desk by CountryID |
| RolloutDateID | DWH_dbo.Dim_Date | Integer YYYYMMDD date key for calendar dimension enrichment |

### 6.2 Referenced By

| Object | Join Column | Description |
|--------|------------|-------------|
| SP_eMoney_Reports_Daily | CountryID | AcquisitionFunnel and ClubUpgrade reports filter customers by eMoney-eligible countries |
| SP_eMoney_Card_Monthly_Snapshot | CountryID | Card metrics scoped to eMoney markets |
| SP_eMoney_Daily_MIMO | CountryID | Daily MIMO activity filtered to eMoney countries |
| SP_eMoney_AM_Target | CountryID | AM target calculations for eMoney markets |

---

## 7. Sample Queries

### Countries by rollout wave

```sql
SELECT CountryName, RolloutDate, Region, Desk,
       DATEDIFF(MONTH, RolloutDate, GETDATE()) AS MonthsSinceRollout
FROM [eMoney_dbo].[eMoney_Dim_Country_Rollout]
ORDER BY RolloutDate ASC;
```

### Customers in active eMoney markets

```sql
SELECT dc.RealCID, dc.CountryID, dcr.CountryName, dcr.Region, dcr.Desk
FROM [DWH_dbo].[Dim_Customer] dc
INNER JOIN [eMoney_dbo].[eMoney_Dim_Country_Rollout] dcr
    ON dc.CountryID = dcr.CountryID
WHERE dc.IsValidCustomer = 1;
```

### Country count by desk

```sql
SELECT Desk, COUNT(*) AS CountryCount,
       MIN(RolloutDate) AS FirstRollout,
       MAX(RolloutDate) AS LastRollout
FROM [eMoney_dbo].[eMoney_Dim_Country_Rollout]
GROUP BY Desk
ORDER BY CountryCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-21 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 0 T1, 3 T2, 0 T3, 4 T4, 0 T5 | Elements: 7/7, Logic: 8/10, Completeness: 9/10*
*Object: eMoney_dbo.eMoney_Dim_Country_Rollout | Type: Table | Production Source: DWH_dbo.Dim_Country (SP_eMoney_Dim_Country_Rollout)*
