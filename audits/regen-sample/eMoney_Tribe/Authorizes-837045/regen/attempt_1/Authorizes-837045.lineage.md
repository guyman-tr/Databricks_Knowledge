# Lineage: eMoney_Tribe.Authorizes-837045

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship | Evidence |
|---|---|---|---|---|---|---|
| 1 | Tribe Data Lake (XML files) | External | — | — | Raw ingestion source | @FileName contains XML file paths: `authorizes-11-15967860899208-10079563-{date}-SubFile-{N}.xml` |
| 2 | SP_eMoney_Reconciliation_ETLs | Stored Procedure | eMoney_dbo | Synapse | Reader — uses this table as parent for Authorize ETL | Lines 541–545: FROM [eMoney_Tribe].[Authorizes-837045] aa INNER JOIN Authorizes_Authorize-312243 |
| 3 | Authorizes_Authorize-312243 | Table | eMoney_Tribe | Synapse | Sibling — child records joined on @Id | SP line 542: INNER JOIN on aa.[@Id] = aaa.[@Id] |
| 4 | Authorizes_RiskActions-796100 | Table | eMoney_Tribe | Synapse | Sibling — risk action child records joined on @Id | SP line 543: LEFT JOIN on aar.[@Id] = aaa.[@Id] |
| 5 | Authorizes_SecurityChecks-30662 | Table | eMoney_Tribe | Synapse | Sibling — security check child records joined on @Id | SP line 544: LEFT JOIN on aas.[@Id] = aaa.[@Id] |
| 6 | ETL_Authorize | Table | eMoney_dbo | Synapse | Target — receives joined output from this table + siblings | SP line 450: INSERT INTO [eMoney_dbo].[ETL_Authorize] |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | @Created | Tribe Data Lake (XML) | Created | Ingested as-is from XML metadata | Tier 3 |
| 2 | @Id | Tribe Data Lake (XML) | Id | Ingested as-is; UUID primary key for JOIN linkage | Tier 3 |
| 3 | @FileName | Tribe Data Lake (XML) | FileName | Ingested as-is; source XML file path | Tier 3 |
| 4 | etr_y | Generic Pipeline | — | Year partition marker from data lake export; 99.8% NULL | Tier 3 |
| 5 | etr_ym | Generic Pipeline | — | Year-month partition marker from data lake export; 99.8% NULL | Tier 3 |
| 6 | etr_ymd | Generic Pipeline | — | Year-month-day partition marker from data lake export; 99.8% NULL | Tier 3 |
| 7 | SynapseUpdateDate | Generic Pipeline | — | DWH housekeeping timestamp set at ingestion time | Tier 3 |
| 8 | partition_date | Generic Pipeline | — | Date-level partition key; aligns with @Created date | Tier 3 |
| 9 | Created | Tribe Data Lake (XML) | Created | Alternate creation timestamp; ~11% NULL in recent data | Tier 3 |
