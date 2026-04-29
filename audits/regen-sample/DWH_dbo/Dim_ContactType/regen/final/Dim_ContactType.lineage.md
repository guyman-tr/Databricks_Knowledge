# Lineage: DWH_dbo.Dim_ContactType

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship | Evidence |
|---|---------------|------|--------|----------|-------------|----------|
| — | (none found) | — | — | — | — | No writer SP, no generic pipeline mapping, no upstream wiki. Table is dormant with 0 rows. |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier | Confidence Notes |
|---|------------|---------------|---------------|-----------|------|-----------------|
| 1 | ContactTypeID | Unknown | Unknown | Unknown | Tier 3 | No writer SP found. DDL defines as `int NOT NULL`, primary clustered index key. Name suggests a contact-type identifier. |
| 2 | Name | Unknown | Unknown | Unknown | Tier 3 | No writer SP found. DDL defines as `varchar(20) NULL`. Name suggests a human-readable contact type label. |
| 3 | DWHContactTypeID | Unknown | Unknown | Unknown | Tier 3 | No writer SP found. DDL defines as `int NOT NULL`. DWH-prefixed surrogate key pattern. |
| 4 | UpdateDate | Unknown | Unknown | Unknown | Tier 3 | No writer SP found. DDL defines as `datetime NULL`. Standard ETL audit column for last update timestamp. |
| 5 | InsertDate | Unknown | Unknown | Unknown | Tier 3 | No writer SP found. DDL defines as `datetime NULL`. Standard ETL audit column for initial insert timestamp. |
| 6 | StatusID | Unknown | Unknown | Unknown | Tier 3 | No writer SP found. DDL defines as `bit NULL`. Standard active/inactive flag pattern. |

---

*Generated: 2026-04-27 | Object: DWH_dbo.Dim_ContactType | Upstream bundle: no upstream found*
