# DWH_dbo.Dim_Campaign

> **DEAD TABLE** — Campaign dimension with ETL commented out. Contains only a single N/A placeholder row (CampaignID = 0). The table structure exists but is not actively populated.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) — **INACTIVE** |
| **Key Identifier** | CampaignID (int NOT NULL, PK NOT ENFORCED) |
| **Row Count** | 1 row (N/A placeholder only) |
| **Distribution** | REPLICATE |
| **Index** | HEAP |

---

## 1. Business Meaning

`Dim_Campaign` was intended to store marketing campaign configuration for bonus and promotion tracking. The table structure includes campaign metadata (code, dates, bonus limits, participation counts) and has Dynamic Data Masking on `ParticipatedUsers` and `Description`.

**Current State**: The ETL INSERT logic in `SP_Dictionaries_DL_To_Synapse` is entirely **commented out**. The SP only executes `TRUNCATE TABLE` followed by an N/A placeholder row insertion, leaving the table permanently empty except for the single default row.

This table appears to be a relic from a legacy campaign management system that is no longer integrated into the Synapse DWH pipeline.

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE only (INSERT is commented out) |
| **Status** | **DEAD** — no active data ingestion |
| **N/A Row** | Single placeholder: CampaignID=0, Code='N/A', dates=1900-01-01 |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CampaignID | int | NO | Tier 3 | Primary key (NOT ENFORCED). Only value present: 0 (N/A placeholder). |
| 2 | CampaignGroupID | int | YES | Tier 3 | Campaign grouping identifier. NULL in the only row. |
| 3 | Code | varchar(15) | NO | Tier 3 | Campaign promotion code. Only value: "N/A". |
| 4 | MaxNumberOfUsers | int | NO | Tier 3 | Maximum participants allowed. Value: 0. |
| 5 | StartDate | datetime | NO | Tier 3 | Campaign start date. Value: 1900-01-01. |
| 6 | EndDate | datetime | NO | Tier 3 | Campaign end date. Value: 1900-01-01. |
| 7 | MaxBonusAmount | money | NO | Tier 3 | Maximum bonus per campaign. Value: 0. |
| 8 | IsActive | bit | NO | Tier 3 | Whether campaign is active. Value: False. |
| 9 | ParticipatedUsers | int | YES | Tier 3 | Count of users who participated. MASKED (Dynamic Data Masking). Value: 0. |
| 10 | Description | varchar(255) | YES | Tier 3 | Campaign description. MASKED (Dynamic Data Masking). Value: empty. |
| 11 | InsertDate | datetime | NO | Tier 2 | ETL load timestamp. |
| 12 | UpdateDate | datetime | YES | Tier 2 | ETL load timestamp. |

---

*Generated: 2026-03-18 | Quality: 6.5/10 (Elements: 6/10, Logic: 5/10, Relationships: 5/10, Sources: 8/10)*
*Confidence: 0 Tier 1, 2 Tier 2, 10 Tier 3, 0 Tier 4 [UNVERIFIED] | Phases: 1,2,8,11*
*Dead Table: ETL INSERT commented out in SP_Dictionaries_DL_To_Synapse*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_Campaign.sql*
