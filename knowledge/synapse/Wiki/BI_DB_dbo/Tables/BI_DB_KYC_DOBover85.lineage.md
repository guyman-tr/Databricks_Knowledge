# BI_DB_dbo.BI_DB_KYC_DOBover85 — Column Lineage

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform | Tier |
|----------------|-------------|---------------|-----------|------|
| CID | DWH_dbo.Dim_Customer | RealCID | Passthrough (renamed) | Tier 1 |
| BirthDate | DWH_dbo.Dim_Customer | BirthDate | CAST to DATE | Tier 1 |
| Registered | DWH_dbo.Dim_Customer | RegisteredReal | CAST to DATE (renamed) | Tier 1 |
| Age | SP_KYC_DOBover85 | Computed | DATEDIFF(year, BirthDate, GETDATE()) | Tier 2 |
| AgeAtReg | SP_KYC_DOBover85 | Computed | DATEDIFF(year, BirthDate, RegisteredReal) | Tier 2 |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough (always 3 due to filter) | Tier 1 |
| FTDDate | DWH_dbo.Dim_Customer | FirstDepositDate | CAST to DATE (renamed) | Tier 2 |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN lookup on RegulationID | Tier 2 |
| Country | DWH_dbo.Dim_Country | Name | JOIN lookup on CountryID | Tier 2 |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | JOIN lookup on PlayerStatusID (always 'Normal' due to filter) | Tier 2 |
| IsAddressProof | DWH_dbo.Dim_Customer | IsAddressProof | Passthrough | Tier 2 |
| IsIDProof | DWH_dbo.Dim_Customer | IsIDProof | Passthrough | Tier 2 |
| EvMatchStatusName | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | JOIN lookup on EvMatchStatus | Tier 2 |
| IsSelfielivelinessProof | SP_KYC_DOBover85 | Computed | CASE WHEN External BackOffice CustomerDocument (DocumentTypeID=18) NOT found THEN 1 ELSE 0 | Tier 2 |
| UpdateDate | SP_KYC_DOBover85 | GETDATE() | ETL timestamp | Tier 5 |

## Source Objects

| Source Object | Role | Schema |
|---------------|------|--------|
| DWH_dbo.Dim_Customer | Primary source — customer demographics, verification, registration | DWH_dbo |
| DWH_dbo.Dim_PlayerStatus | Player status name lookup | DWH_dbo |
| DWH_dbo.Dim_Regulation | Regulation name lookup | DWH_dbo |
| DWH_dbo.Dim_Country | Country name lookup | DWH_dbo |
| DWH_dbo.Dim_EvMatchStatus | Electronic verification match status name lookup | DWH_dbo |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | Customer document records (selfie/liveliness check) | BI_DB_dbo (External) |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType | Document-to-type mapping (DocumentTypeID=18 = SelfieLiveliness) | BI_DB_dbo (External) |
