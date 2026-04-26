# Lineage: BI_DB_dbo.BI_DB_Flare_Eligibility

**Generated**: 2026-04-22 | **Writer SP**: `BI_DB_dbo.SP_Flare_Eligibility` | **Schema**: BI_DB_dbo

## ETL Chain

```
BI_OUTPUT/Finance/Uploads/Flare_list_of_CIDs.csv  (Finance-uploaded candidate CID list)
  → BI_DB_dbo.External_Flare_CID3 (CID, IsOptOut)
DWH_dbo.Dim_Customer (RegulationID, PlayerStatusID, PlayerStatusSubReasonID,
                       AccountStatusID, CountryID, PlayerStatusReasonID)
DWH_dbo.Dim_PlayerStatus (PlayerStatusID) [JOIN for validity]
DWH_dbo.Dim_Country (RiskGroupID, CountryID)
  |-- SP_Flare_Eligibility (TRUNCATE + INSERT, no date param) ---|
  v
BI_DB_dbo.BI_DB_Flare_Eligibility
  (UC Target: Not Migrated)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | External_Flare_CID3 | CID | Passthrough (Finance-uploaded CSV) | Tier 1 |
| 2 | IsOptOut | External_Flare_CID3 | IsOptOut | Passthrough (Finance-uploaded CSV) | Tier 2 |
| 3 | Negative Target Market | Dim_Customer + Dim_Country | RiskGroupID, CountryID, RegulationID, PlayerStatusReasonID | CASE: 0 if RiskGroupID=1 OR CountryID IN (250,44) OR RegulationID=5 OR PlayerStatusReasonID=28; else 1 | Tier 2 |
| 4 | AML Status Restriction | Dim_Customer | PlayerStatusID, PlayerStatusSubReasonID | CASE: 0 if PlayerStatusID IN (2,9,15,4) OR PlayerStatusSubReasonID IN (25,33,31,32,26,30,51); else 1 | Tier 2 |
| 5 | Account status | Dim_Customer | AccountStatusID | CASE WHEN AccountStatusID=2 THEN 0 ELSE 1 | Tier 2 |
| 6 | Cash Equivalent | Dim_Customer + Dim_Country | CountryID, RegulationID | CASE: 0 if CountryID IN (67,167,148,79,63,105,96) OR RegulationID IN (6,7,8); else 1 | Tier 2 |
| 7 | IsEligible | Computed | All 4 flags + IsOptOut | CASE WHEN all flags=1 AND IsOptOut=0 THEN 1 ELSE 0 | Tier 2 |
| 8 | UpdateDate | ETL | — | GETDATE() at INSERT time | ETL_METADATA |

## Source Objects

| Object | Type | Role |
|--------|------|------|
| BI_DB_dbo.External_Flare_CID3 | External Table | Finance-uploaded candidate CID population (CSV from lake) |
| DWH_dbo.Dim_Customer | Table | Customer status, regulation, country, account attributes |
| DWH_dbo.Dim_PlayerStatus | Table | Player status lookup (joined for completeness) |
| DWH_dbo.Dim_Country | Table | Country-level risk group and country identifier |

## Key Constraints (from SP)

- **Base population**: Only CIDs present in Finance-uploaded `Flare_list_of_CIDs.csv` are assessed
- **No date filter**: Full TRUNCATE + INSERT on every run — snapshot of current eligibility
- **IsEligible = 1** requires ALL of: Negative Target Market=1, AML Status Restriction=1, Account status=1, Cash Equivalent=1, IsOptOut=0

## UC Target

Not Migrated
