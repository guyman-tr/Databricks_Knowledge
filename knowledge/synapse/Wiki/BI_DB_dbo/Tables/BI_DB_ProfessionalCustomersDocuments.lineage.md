# Column Lineage: BI_DB_dbo.BI_DB_ProfessionalCustomersDocuments

## Source Objects

| Source | Type | Role |
|--------|------|------|
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | External Table | Professional customer application documents (SuggestedDocumentTypeID=21) |
| DWH_dbo.Fact_SnapshotCustomer | Fact | Customer state: RealCID, AccountManagerID, PlayerLevelID, MifidCategorizationID, RegulationID, DateRangeID |
| DWH_dbo.Dim_Range | Dimension | DateRangeID decode for current-state filtering |
| DWH_dbo.Dim_Manager | Dimension | AccountManagerID-to-name resolution |
| DWH_dbo.Dim_PlayerLevel | Dimension | PlayerLevelID-to-Name resolution (ClubTier) |
| DWH_dbo.Dim_MifidCategorization | Dimension | MifidCategorizationID-to-Name resolution (ProfessionalStatus) |
| DWH_dbo.Dim_Regulation | Dimension | RegulationID-to-Name resolution |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | ETL | @Date parameter | Passthrough of SP input date |
| DateID | ETL | @DateID | CAST(CONVERT(CHAR(8),@Date,112) AS INT) |
| DocumentID | External_etoro_BackOffice_CustomerDocument | DocumentID | Passthrough (filtered SuggestedDocumentTypeID=21) |
| CID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough (aliased as CID) |
| AccountManagerID | DWH_dbo.Fact_SnapshotCustomer | AccountManagerID | Passthrough |
| AM | DWH_dbo.Dim_Manager | FirstName, LastName | Concatenation: FirstName + ' ' + LastName |
| ClubTier | DWH_dbo.Dim_PlayerLevel | Name | Passthrough (dim lookup) |
| ProfessionalStatus | DWH_dbo.Dim_MifidCategorization | Name | Passthrough (dim lookup) |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough (dim lookup) |
| UpdateDate | ETL | GETDATE() | ETL metadata timestamp |
