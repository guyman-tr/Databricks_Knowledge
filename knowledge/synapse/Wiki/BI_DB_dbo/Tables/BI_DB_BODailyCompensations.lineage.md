# Lineage: BI_DB_dbo.BI_DB_BODailyCompensations

**Generated**: 2026-04-23
**Writer SP**: `SP_BI_DB_BODailyCompensations`
**Load Pattern**: DELETE + INSERT (daily window replace — deletes Occurred >= @Date AND < @Date+1, re-inserts from source)
**UC Target**: `_Not_Migrated`

## ETL Pipeline

```
etoro.History.Credit (Bronze lake, filtered: CreditTypeID=6, Occurred = @Date)
  └── External_etoro_history_credit_Pavlina
        |
etoro.BackOffice.CompensationReason (Bronze lake)
  └── External_etoro_BackOffice_CompensationReason
        |
DWH_dbo.Dim_Manager (LEFT JOIN on ManagerID)
        |
DWH_dbo.Dim_Customer ──► DWH_dbo.Dim_Country (via CountryID)
                     └──► DWH_dbo.Dim_Regulation (via DesignatedRegulationID)
        |
        v
SP_BI_DB_BODailyCompensations(@Date) [DELETE + INSERT]
        |
        v
BI_DB_dbo.BI_DB_BODailyCompensations (22,392,972 rows)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | ID | ETL pipeline | — | IDENTITY — auto-incremented at INSERT | Propagation |
| 2 | CID | etoro.History.Credit | CID | passthrough | Tier 2 |
| 3 | CreditID | etoro.History.Credit | CreditID | passthrough | Tier 2 |
| 4 | Occurred | etoro.History.Credit | Occurred | passthrough (filtered to @Date window) | Tier 2 |
| 5 | Payment | etoro.History.Credit | Payment | passthrough | Tier 2 |
| 6 | Description | etoro.History.Credit | Description | passthrough | Tier 2 |
| 7 | Manager | DWH_dbo.Dim_Manager | FirstName, LastName | computed: FirstName + ' ' + LastName (NULL when no manager) | Tier 2 |
| 8 | Category | etoro.BackOffice.CompensationReason | Name | passthrough via JOIN on CompensationReasonID | Tier 2 |
| 9 | Country | DWH_dbo.Dim_Country | Name | passthrough via Dim_Customer.CountryID | Tier 2 |
| 10 | Regulation | DWH_dbo.Dim_Regulation | Name | passthrough via Dim_Customer.DesignatedRegulationID | Tier 2 |
| 11 | UpdateDate | ETL pipeline | — | GETDATE() at INSERT time | Propagation |

## Source Objects

| Object | Type | Role |
|--------|------|------|
| etoro.History.Credit | External Table | Primary — compensation credit records (CreditTypeID=6) |
| etoro.BackOffice.CompensationReason | External Table | Lookup — maps CompensationReasonID to human-readable Category name |
| DWH_dbo.Dim_Manager | Table | Dimension — resolves ManagerID to FirstName + LastName |
| DWH_dbo.Dim_Customer | Table | Dimension — maps CID to CountryID and DesignatedRegulationID |
| DWH_dbo.Dim_Country | Table | Dimension — resolves CountryID to country Name |
| DWH_dbo.Dim_Regulation | Table | Dimension — resolves DesignatedRegulationID to regulation Name |

## Notes

- SP is parameterized by @Date; caller controls the date window (typically previous business day)
- `SP_Create_External_etoro_history_credit` is called first to refresh the external table before the DELETE/INSERT
- `CreditTypeID=6` is hardcoded in the source filter — selects only Compensation credits, excluding all other credit types
- Manager is a LEFT JOIN — system-automated compensations (e.g., Interest Payment, Staking rules) have no assigned manager; Manager is NULL in those cases (~39% of recent rows)
- ID is an IDENTITY column — has no upstream business identity; assigned by Synapse at INSERT time
- No upstream wiki available for etoro.History.Credit or etoro.BackOffice.CompensationReason
