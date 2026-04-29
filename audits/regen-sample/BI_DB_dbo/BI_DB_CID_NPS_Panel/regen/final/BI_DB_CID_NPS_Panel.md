# BI_DB_dbo.BI_DB_CID_NPS_Panel

> NPS (Net Promoter Score) survey response panel — one row per Delighted survey response, enriched with the respondent's matched eToro customer identity, snapshot attributes as of the survey date, and first trading action. Primary source for customer satisfaction analysis and NPS trend reporting.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Delighted NPS platform via Fivetran (`External_Fivetran_delighted_response` + `External_Fivetran_delighted_person`), enriched from DWH_dbo.Dim_Customer, DWH_dbo.Fact_SnapshotCustomer, and BI_DB_dbo.BI_DB_First5Actions |
| **Refresh** | Daily incremental — DELETE + INSERT per DateID via SP_CID_NPS_Panel(@Date) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **Row Count** | ~159,441 (as of 2025-07-10) |
| **Date Range** | 2021-01-01 to 2025-07-10 |
| **Distinct Customers** | ~134,122 (some customers appear on multiple survey dates) |
| **UC Status** | Not migrated |

---

## 1. Business Meaning

`BI_DB_CID_NPS_Panel` is the central NPS analytics table for eToro. It stores every Net Promoter Score survey response collected through the Delighted platform, enriched with a cross-section of customer attributes drawn from the DWH at the time of the survey.

NPS measures customer loyalty: respondents rate their likelihood to recommend eToro on a scale of 0–10. Scores group into three segments:
- **Promoters (9–10)**: Loyal enthusiasts. 38.7% of responses.
- **Passives (7–8)**: Satisfied but vulnerable. 35.9% of responses.
- **Detractors (0–6)**: Unhappy customers. 25.4% of responses.

The NPS score is `% Promoters − % Detractors`.

Each row links a Delighted survey response to the matched eToro customer's RealCID (resolved via username/email matching against `Dim_Customer`). Attributes such as country, club tier, regulation, and player status reflect the customer's state on the survey date (via a Fact_SnapshotCustomer point-in-time join), not their current state. `FirstAction` captures what asset class the customer traded first, providing segmentation for "does activation pattern affect NPS?"

~0.4% of rows (630) have NULL RealCID — these are respondents where name/email/username matching against Dim_Customer failed (e.g., deleted accounts, email changes, typos in the Delighted form).

---

## 2. Business Logic

### 2.1 Customer Identity Resolution

The SP attempts to match each NPS respondent to an eToro RealCID using three successive lookups against Dim_Customer:
```
COALESCE(
  match by Dim_Customer.UserName = response.Name   (case-sensitive COLLATE Latin1_General_100_BIN),
  match by Dim_Customer.Email    = response.Email  (case-sensitive COLLATE Latin1_General_100_BIN),
  match by Dim_Customer.UserName_Lower = LOWER(response.UserName)
)
```
The first successful match wins. If none match, RealCID is NULL (unresolved respondent). Approximately 630 rows have NULL RealCID, which also causes NULL for all DWH-enriched columns (RegisteredReal, FirstDepositDate, Country, ClubTier, Regulation, PlayerStatus, MifCategory).

### 2.2 Point-in-Time Customer Attribute Snapshot

Customer attributes (ClubTier, PlayerStatus, MifCategory, Country, Regulation) are fetched from `Fact_SnapshotCustomer` filtered to the survey date using `Dim_Range`:
```sql
WHERE dr1.FromDateID <= DateID
  AND dr1.ToDateID   >= DateID
```
This ensures the attributes reflect the customer's state on the day they submitted the NPS survey, not today's state. The result is grouped by RealCID (selecting one row per customer per date), so if a customer has multiple snapshot rows active on the survey date, they are collapsed.

### 2.3 Daily DELETE + INSERT Pattern

The SP is idempotent: it deletes all existing rows for `@DateID` before inserting fresh data. This means re-running the SP for the same date is safe and will produce a clean replacement. The table is NOT truncated on each run — historical dates are preserved.

### 2.4 NPS Score Grouping

| Score | Segment | Count | % |
|-------|---------|-------|---|
| 0–6 | Detractors | 39,200 | 24.6% |
| 7–8 | Passives | 59,242 | 37.1% |
| 9–10 | Promoters | 60,999 | 38.3% |

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution means no data skew but JOINs on RealCID require data movement. The CLUSTERED INDEX on Date supports time-range queries well. For customer-level analysis, consider filtering by Date range first to reduce scan size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| NPS score by country for a time period | `GROUP BY Country, CASE WHEN Score>=9 THEN 'Promoter' WHEN Score>=7 THEN 'Passive' ELSE 'Detractor' END WHERE Date BETWEEN @from AND @to` |
| NPS by first action type | `GROUP BY FirstAction` with promoter/detractor calc |
| NPS by club tier | `GROUP BY ClubTier` — filter `ClubTier IS NOT NULL` to exclude unmatched |
| NPS trend (monthly) | `GROUP BY YEAR(Date), MONTH(Date)` on NPS score groupings |
| Identify detractor comments | `WHERE Score <= 6 AND Comment IS NOT NULL` |
| Customers who responded multiple times | `GROUP BY RealCID HAVING COUNT(*) > 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON RealCID = RealCID | Enrich with current customer attributes |
| BI_DB_dbo.BI_DB_First5Actions | ON RealCID = CID | Cross-reference activation metrics |

### 3.4 Gotchas

- **NULL RealCID rows**: ~630 rows have NULL RealCID (unmatched respondents). All DWH-enriched columns will also be NULL. Filter `WHERE RealCID IS NOT NULL` for customer-matched analysis.
- **Attributes are point-in-time**: Country, ClubTier, Regulation, PlayerStatus, MifCategory all reflect the survey date, not today. Do not join to Dim_Customer for these — they will return the current value, not the historical one.
- **A customer can appear on multiple dates**: The table is not unique by RealCID. Aggregate at the appropriate granularity.
- **Comment NULLs**: ~51,415 rows (32.2%) have no Comment — NPS respondents can submit a score without a verbatim comment.
- **NULL FirstAction**: ~2,505 rows (1.6%) have NULL FirstAction, meaning the customer's RealCID was not found in BI_DB_First5Actions (e.g., non-depositor or no recorded trading action).
- **Score range**: 0–10, never NULL (the Score column is NOT NULL in practice — no NULL scores observed in data).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag | Source |
|------|-----|--------|
| Tier 1 | `(Tier 1 — [source])` | Verbatim from upstream wiki |
| Tier 2 | `(Tier 2 — SP_CID_NPS_Panel)` | Derived from SP source code or DDL |
| Tier 3 | `(Tier 3 — Fivetran/Delighted, no upstream wiki)` | From live data sampling and DDL; no wiki for Fivetran source |

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | Date | datetime | YES | NPS survey submission timestamp. Cast from `External_Fivetran_delighted_response.created_at` to datetime. Represents the moment the respondent submitted the survey in the Delighted platform. Range: 2021-01-01 to 2025-07-10. (Tier 3 — Fivetran/Delighted, no upstream wiki) |
| 2 | DateID | int | YES | Integer date key of the survey batch in YYYYMMDD format. Computed as `CAST(CONVERT(CHAR(8),@Date,112) AS INT)` where @Date is the daily SP parameter. All responses ingested on the same run share this DateID. Used for DELETE+INSERT idempotency. (Tier 2 — SP_CID_NPS_Panel) |
| 3 | RealCID | int | YES | Resolved eToro customer ID for the NPS respondent. Determined by three-pass COALESCE matching against DWH_dbo.Dim_Customer: (1) by UserName, (2) by Email, (3) by UserName_Lower. NULL if no match found (~630 rows, ~0.4%). When NULL all DWH-enriched attributes are also NULL. (Tier 2 — SP_CID_NPS_Panel) |
| 4 | NPS_ID | bigint | NO | Delighted platform survey response ID. Source: `External_Fivetran_delighted_response.id`. Primary key of the survey response in the Delighted system. Unique per response. (Tier 3 — Fivetran/Delighted, no upstream wiki) |
| 5 | Score | int | YES | NPS score given by the respondent on a 0–10 scale. Source: `External_Fivetran_delighted_response.score`. Grouping: 0–6=Detractor (24.6%), 7–8=Passive (37.1%), 9–10=Promoter (38.3%). Never NULL in practice. (Tier 3 — Fivetran/Delighted, no upstream wiki) |
| 6 | RegisteredReal | datetime | YES | Account registration date (renamed from Registered). Default=getdate(). NULL when RealCID is unresolved. (Tier 1 — Customer.CustomerStatic) |
| 7 | FirstDepositDate | datetime | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. NULL when RealCID is unresolved. (Tier 1 — DWH_dbo.Dim_Customer) |
| 8 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Reflects the customer's registered country as of the survey date (sourced from Fact_SnapshotCustomer → Dim_Country). NULL when RealCID is unresolved or Fact_SnapshotCustomer has no active row for the survey date. Top values: United Kingdom (26,857), Germany (15,658), Italy (15,038). (Tier 1 — Dictionary.Country) |
| 9 | ClubTier | varchar(50) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Reflects loyalty tier as of the survey date. Distribution: Bronze 60.1%, Gold 13.8%, Silver 13.4%, Platinum 6.7%, Platinum Plus 5.2%, Diamond 0.5%. NULL when unresolved. (Tier 1 — Dictionary.PlayerLevel) |
| 10 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Reflects the customer's regulatory jurisdiction as of the survey date. Top values: CySEC (55.5%), FCA (30.0%), ASIC & GAML (8.4%). NULL when unresolved. (Tier 1 — Dictionary.Regulation) |
| 11 | PlayerStatus | varchar(50) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data — apply RTRIM() for string comparisons. Reflects status as of the survey date. 97.0% of matched rows are Normal. (Tier 1 — Dictionary.PlayerStatus) |
| 12 | MifCategory | varchar(50) | YES | Human-readable classification label. Used in compliance dashboards and regulatory reports. Reflects MiFID II categorization as of the survey date. Distribution: Retail 51.1%, Retail Pending 46.1%, Pending 2.2%, Elective Professional 0.2%. NULL when unresolved. (Tier 1 — Dictionary.MifidCategorization) |
| 13 | FirstAction | nvarchar(50) | YES | First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy Fund', 'Copy'. Merges Indices into Stocks bucket vs. legacy. NULL when customer has no recorded first position (~1.6% of rows). Distribution: Stocks/ETFs/Indices 37.9%, Crypto 36.9%, Copy 15.8%, FX/Commodities 6.8%, Copy Fund 1.2%. (Tier 1 — BI_DB_dbo.BI_DB_First5Actions) |
| 14 | FirstActionDate | datetime | YES | Datetime of 1st open position. From BI_DB_CustomerCross PIVOT (rn=1, MAX(Occurred)). NULL when customer has no recorded first position. (Tier 1 — BI_DB_dbo.BI_DB_First5Actions) |
| 15 | UpdateDate | datetime | NO | ETL load timestamp. Set to GETDATE() at INSERT execution time by SP_CID_NPS_Panel. Reflects the time the SP ran, not when the survey was submitted. (Tier 2 — SP_CID_NPS_Panel) |
| 16 | Comment | varchar(max) | YES | Free-text verbatim NPS comment submitted by the respondent. Source: `External_Fivetran_delighted_response.comment`. NULL when respondent submitted a score without a text comment (~32.2% of rows). Can contain any language. (Tier 3 — Fivetran/Delighted, no upstream wiki) |

---

## 5. Lineage

See `BI_DB_CID_NPS_Panel.lineage.md` for full column-level lineage.

### ETL Pipeline Summary

```
Delighted NPS Platform
  → Fivetran (daily sync)
  → BI_DB_dbo.External_Fivetran_delighted_response   (survey responses)
  → BI_DB_dbo.External_Fivetran_delighted_person     (respondent profile)
      ├── #nps  — filter to @Date window
      ├── #dc   — Dim_Customer snapshot for identity matching
      ├── #pop  — resolve RealCID (3-pass username/email/username_lower match)
      ├── #fsc  — Fact_SnapshotCustomer attributes on survey date
      |            (+ Dim_Range, Dim_PlayerLevel, Dim_PlayerStatus,
      |               Dim_Regulation, Dim_Country, Dim_MifidCategorization)
      └── BI_DB_First5Actions — FirstActionTypeNew, FirstActionDate
          ↓
  SP_CID_NPS_Panel(@Date)
  DELETE FROM BI_DB_CID_NPS_Panel WHERE DateID = @DateID
  INSERT INTO BI_DB_CID_NPS_Panel ...
  ↓
  BI_DB_dbo.BI_DB_CID_NPS_Panel
```

| Step | Object | Description |
|------|--------|-------------|
| Source | External_Fivetran_delighted_response | Fivetran-synced Delighted survey responses |
| Source | External_Fivetran_delighted_person | Fivetran-synced Delighted respondent profiles |
| Enrichment | DWH_dbo.Dim_Customer | Customer identity + RegisteredReal + FirstDepositDate |
| Enrichment | DWH_dbo.Fact_SnapshotCustomer | Point-in-time customer attributes on survey date |
| Enrichment | DWH_dbo.BI_DB_First5Actions | First trading action classification |
| ETL SP | BI_DB_dbo.SP_CID_NPS_Panel | Daily incremental: DELETE+INSERT per DateID (Author: Ofir Chloe Gal, 2023-02-05 rename) |
| Target | BI_DB_dbo.BI_DB_CID_NPS_Panel | NPS panel table (~159K rows, 2021–2025) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID (resolution) | DWH_dbo.Dim_Customer | Identity match by UserName / Email / UserName_Lower |
| RegisteredReal, FirstDepositDate | DWH_dbo.Dim_Customer | Passthrough customer dates |
| ClubTier, PlayerStatus, Regulation, Country, MifCategory | DWH_dbo.Fact_SnapshotCustomer | Point-in-time customer attributes |
| ClubTier name | DWH_dbo.Dim_PlayerLevel | Dim lookup via PlayerLevelID |
| PlayerStatus name | DWH_dbo.Dim_PlayerStatus | Dim lookup via PlayerStatusID |
| Regulation name | DWH_dbo.Dim_Regulation | Dim lookup via RegulationID |
| Country name | DWH_dbo.Dim_Country | Dim lookup via CountryID |
| MifCategory name | DWH_dbo.Dim_MifidCategorization | Dim lookup via MifidCategorizationID |
| FirstAction, FirstActionDate | BI_DB_dbo.BI_DB_First5Actions | Passthrough of FirstActionTypeNew / FirstActionDate |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_DepositUsersFirstTouchPoints | (documented in BI_DB_First5Actions wiki) | Downstream activation analysis SP references BI_DB_First5Actions which feeds this table |

---

## 7. Sample Queries

### 7.1 Monthly NPS score (promoter % minus detractor %)

```sql
SELECT
    YEAR(Date)  AS survey_year,
    MONTH(Date) AS survey_month,
    COUNT(*)    AS total_responses,
    ROUND(100.0 * SUM(CASE WHEN Score >= 9 THEN 1 ELSE 0 END) / COUNT(*), 1) AS promoter_pct,
    ROUND(100.0 * SUM(CASE WHEN Score <= 6 THEN 1 ELSE 0 END) / COUNT(*), 1) AS detractor_pct,
    ROUND(100.0 * SUM(CASE WHEN Score >= 9 THEN 1 ELSE 0 END) / COUNT(*)
        - 100.0 * SUM(CASE WHEN Score <= 6 THEN 1 ELSE 0 END) / COUNT(*), 1) AS nps_score
FROM [BI_DB_dbo].[BI_DB_CID_NPS_Panel]
WHERE RealCID IS NOT NULL
GROUP BY YEAR(Date), MONTH(Date)
ORDER BY survey_year, survey_month;
```

### 7.2 NPS by first action type (last 12 months)

```sql
SELECT
    ISNULL(FirstAction, 'No Trade') AS first_action,
    COUNT(*) AS responses,
    ROUND(100.0 * SUM(CASE WHEN Score >= 9 THEN 1 ELSE 0 END) / COUNT(*), 1) AS promoter_pct,
    ROUND(100.0 * SUM(CASE WHEN Score <= 6 THEN 1 ELSE 0 END) / COUNT(*), 1) AS detractor_pct
FROM [BI_DB_dbo].[BI_DB_CID_NPS_Panel]
WHERE Date >= DATEADD(MONTH, -12, GETDATE())
  AND RealCID IS NOT NULL
GROUP BY FirstAction
ORDER BY responses DESC;
```

### 7.3 Detractor verbatim comments for triage

```sql
SELECT TOP 100
    Date,
    RealCID,
    Score,
    Country,
    ClubTier,
    Comment
FROM [BI_DB_dbo].[BI_DB_CID_NPS_Panel]
WHERE Score <= 6
  AND Comment IS NOT NULL
  AND Date >= DATEADD(DAY, -30, GETDATE())
ORDER BY Date DESC;
```

### 7.4 NPS by regulation and club tier (current year)

```sql
SELECT
    Regulation,
    ClubTier,
    COUNT(*) AS responses,
    AVG(CAST(Score AS FLOAT)) AS avg_score
FROM [BI_DB_dbo].[BI_DB_CID_NPS_Panel]
WHERE YEAR(Date) = YEAR(GETDATE())
  AND RealCID IS NOT NULL
  AND Regulation IS NOT NULL
GROUP BY Regulation, ClubTier
ORDER BY Regulation, AVG(CAST(Score AS FLOAT)) DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP search performed for this object. The SP change log (2023-02-05: Ofir Chloe Gal — table rename to BI_DB_CID_NPS_Panel) is the primary revision context available.

---

*Generated: 2026-04-28 | Regen attempt 1 | Quality: pending judge evaluation*
*Tiers: 9 T1, 3 T2, 4 T3, 0 T4 | Elements: 16/16*
*Object: BI_DB_dbo.BI_DB_CID_NPS_Panel | Type: Table | Production Source: Delighted/Fivetran + DWH enrichment*
