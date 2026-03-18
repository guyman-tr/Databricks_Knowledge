# DWH_dbo.Dim_ContactType

> **DEAD TABLE** — Contact type dimension with zero rows. No active ETL exists. The table structure is defined but never populated.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) — **INACTIVE** |
| **Key Identifier** | ContactTypeID (int NOT NULL, CLUSTERED INDEX) |
| **Row Count** | 0 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on ContactTypeID ASC |

---

## 1. Business Meaning

`Dim_ContactType` was intended to classify customer contact methods (phone, email, etc.) but was never populated with data. No ETL process exists in `SP_Dictionaries_DL_To_Synapse` or any other stored procedure.

---

## 2. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | ContactTypeID | int | NO | Tier 3 | Contact type identifier. No data. |
| 2 | Name | varchar(20) | YES | Tier 3 | Contact type name. No data. |
| 3 | DWHContactTypeID | int | NO | Tier 3 | Redundant copy of ContactTypeID. Legacy DWH pattern. |
| 4 | UpdateDate | datetime | YES | Tier 3 | ETL timestamp. No data. |
| 5 | InsertDate | datetime | YES | Tier 3 | ETL timestamp. No data. |
| 6 | StatusID | bit | YES | Tier 3 | Status flag. No data. |

---

*Generated: 2026-03-18 | Quality: 5.5/10 | Dead Table: 0 rows, no ETL | Phases: 1,2,8,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_ContactType.sql*
