# BI_DB_CID_NPS_Panel — Lineage

> Column-level lineage for `BI_DB_dbo.BI_DB_CID_NPS_Panel`. Written by regen-harness (attempt 1).

---

## Source Objects

| # | Object | Schema | Type | Role |
|---|--------|--------|------|------|
| 1 | External_Fivetran_delighted_response | BI_DB_dbo | External Table (Fivetran/Delighted) | NPS survey response records (created_at, id, score, comment, person_id) |
| 2 | External_Fivetran_delighted_person | BI_DB_dbo | External Table (Fivetran/Delighted) | NPS respondent profile (name, email, properties_user_name) |
| 3 | Dim_Customer | DWH_dbo | Dimension Table | Customer identity for RealCID resolution; provides RegisteredReal and FirstDepositDate |
| 4 | Fact_SnapshotCustomer | DWH_dbo | Fact Table | Customer state snapshot — provides PlayerLevelID, PlayerStatusID, RegulationID, CountryID, MifidCategorizationID as of the survey date |
| 5 | Dim_Range | DWH_dbo | Dimension Table | Date-range lookup; used to filter Fact_SnapshotCustomer to rows active on survey date |
| 6 | Dim_PlayerLevel | DWH_dbo | Dimension Table | Resolves PlayerLevelID → ClubTier name |
| 7 | Dim_PlayerStatus | DWH_dbo | Dimension Table | Resolves PlayerStatusID → PlayerStatus name |
| 8 | Dim_Regulation | DWH_dbo | Dimension Table | Resolves RegulationID → Regulation name |
| 9 | Dim_Country | DWH_dbo | Dimension Table | Resolves CountryID → Country name |
| 10 | Dim_MifidCategorization | DWH_dbo | Dimension Table | Resolves MifidCategorizationID → MifCategory name |
| 11 | BI_DB_First5Actions | BI_DB_dbo | Table | Provides FirstAction (FirstActionTypeNew) and FirstActionDate per customer |

---

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|---------------|---------------|-----------|------|
| 1 | Date | External_Fivetran_delighted_response | created_at | `CAST(r.created_at AS DATETIME)` — survey submission timestamp cast to datetime | Tier 3 |
| 2 | DateID | SP computation | @Date parameter | `CAST(CONVERT(CHAR(8),@Date,112) AS INT)` — YYYYMMDD integer of the survey batch date | Tier 2 |
| 3 | RealCID | DWH_dbo.Dim_Customer | RealCID | `COALESCE(match by UserName, match by Email, match by UserName_Lower)` — three-pass identity resolution against Dim_Customer | Tier 2 |
| 4 | NPS_ID | External_Fivetran_delighted_response | id | Passthrough — Delighted platform survey response ID | Tier 3 |
| 5 | Score | External_Fivetran_delighted_response | score | Passthrough — NPS score 0–10 | Tier 3 |
| 6 | RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough | Tier 1 — Customer.CustomerStatic |
| 7 | FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough | Tier 1 — DWH_dbo.Dim_Customer |
| 8 | Country | DWH_dbo.Dim_Country | Name | Passthrough via Fact_SnapshotCustomer → Dim_Country join on CountryID | Tier 1 — Dictionary.Country |
| 9 | ClubTier | DWH_dbo.Dim_PlayerLevel | Name | Passthrough via Fact_SnapshotCustomer → Dim_PlayerLevel join on PlayerLevelID | Tier 1 — Dictionary.PlayerLevel |
| 10 | Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough via Fact_SnapshotCustomer → Dim_Regulation join on RegulationID | Tier 1 — Dictionary.Regulation |
| 11 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Passthrough via Fact_SnapshotCustomer → Dim_PlayerStatus join on PlayerStatusID | Tier 1 — Dictionary.PlayerStatus |
| 12 | MifCategory | DWH_dbo.Dim_MifidCategorization | Name | Passthrough via Fact_SnapshotCustomer → Dim_MifidCategorization join on MifidCategorizationID | Tier 1 — Dictionary.MifidCategorization |
| 13 | FirstAction | BI_DB_dbo.BI_DB_First5Actions | FirstActionTypeNew | Passthrough (aliased in INSERT list as `f5a.FirstActionTypeNew FirstAction`) | Tier 1 — BI_DB_dbo.BI_DB_First5Actions |
| 14 | FirstActionDate | BI_DB_dbo.BI_DB_First5Actions | FirstActionDate | Passthrough | Tier 1 — BI_DB_dbo.BI_DB_First5Actions |
| 15 | UpdateDate | SP computation | — | `GETDATE()` at INSERT execution time | Tier 2 |
| 16 | Comment | External_Fivetran_delighted_response | comment | Passthrough — free-text NPS verbatim comment | Tier 3 |

---

## ETL Pipeline

```
Delighted NPS Platform
  → Fivetran sync (daily)
  → BI_DB_dbo.External_Fivetran_delighted_response  (survey responses)
  → BI_DB_dbo.External_Fivetran_delighted_person    (respondent profile)
      |
      + DWH_dbo.Dim_Customer                         (identity resolution by Name/Email/UserName_Lower)
      + DWH_dbo.Fact_SnapshotCustomer + Dim_Range    (customer attributes on survey date)
        + DWH_dbo.Dim_PlayerLevel, Dim_PlayerStatus, Dim_Regulation, Dim_Country, Dim_MifidCategorization
      + BI_DB_dbo.BI_DB_First5Actions                (first trading action)
      |
  SP_CID_NPS_Panel(@Date)
    1. Build #nps — filter Fivetran responses for @Date window
    2. Build #dc  — Dim_Customer snapshot for identity matching
    3. Build #pop — resolve RealCID via COALESCE(UserName, Email, UserName_Lower) match
    4. Build #fsc — Fact_SnapshotCustomer attributes valid on DateID
    5. DELETE FROM BI_DB_CID_NPS_Panel WHERE DateID = @DateID
    6. INSERT enriched rows
  → BI_DB_dbo.BI_DB_CID_NPS_Panel
```

---

*Lineage generated: 2026-04-28 | Regen attempt 1 | Upstream bundle: 9 wikis resolved*
