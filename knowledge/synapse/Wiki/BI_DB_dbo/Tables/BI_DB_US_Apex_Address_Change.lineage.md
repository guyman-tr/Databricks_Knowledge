# BI_DB_dbo.BI_DB_US_Apex_Address_Change — Column Lineage

## Source Objects

| Source Object | Type | Role |
|---|---|---|
| DWH_dbo.Fact_SnapshotCustomer | Table | Primary — customer snapshot history with address/city/region changes |
| DWH_dbo.Dim_Customer | Table | GCID, FirstName, LastName lookup |
| DWH_dbo.Dim_Range | Table | DateRangeID to date conversion |
| DWH_dbo.Dim_Regulation | Table | RegulationID to regulation name |
| DWH_dbo.Dim_State_and_Province | Table | RegionByIP_ID to state name |
| BI_DB_dbo.External_USABroker_Apex_ApexData | External Table | Apex account ID and status |
| BI_DB_dbo.External_USABroker_Dictionary_ApexStatus | External Table | Apex status name lookup |
| BI_DB_dbo.External_USABroker_Apex_UserData | External Table | Apex approver info |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---|---|---|---|
| CID | Fact_SnapshotCustomer | RealCID | Rename (RealCID → CID) |
| GCID | Dim_Customer | GCID | Passthrough via JOIN on RealCID |
| FirstName | Dim_Customer | FirstName | Passthrough (PII) |
| LastName | Dim_Customer | LastName | Passthrough (PII) |
| RegulationAtChange | Dim_Regulation | Name | JOIN on fsc.RegulationID = dr1.DWHRegulationID. Always 'FinCEN+FINRA' (filtered to RegulationID=8) |
| ChangeDate | Dim_Range | FromDateID | CONVERT(date, CONVERT(char(8), dr.FromDateID)) — MIN per group |
| DateID | Dim_Range | FromDateID | MIN per group |
| Previous_Address | Fact_SnapshotCustomer | Address | LAG(Address, 1, NULL) OVER(PARTITION BY RealCID ORDER BY UpdateDate) |
| Address | Fact_SnapshotCustomer | Address | Current snapshot address |
| PreviousCity | Fact_SnapshotCustomer | City | LAG(City, 1, NULL) OVER(PARTITION BY RealCID ORDER BY UpdateDate) |
| City | Fact_SnapshotCustomer | City | Current snapshot city |
| PreviousState | Dim_State_and_Province | Name | LAG(d.Name, 1, NULL) OVER(PARTITION BY RealCID ORDER BY UpdateDate) |
| State | Dim_State_and_Province | Name | JOIN on RegionByIP_ID + CountryID |
| ApexID | External_USABroker_Apex_ApexData | ApexID | Passthrough via CID JOIN |
| ApexStatus | External_USABroker_Dictionary_ApexStatus | Name | JOIN on StatusID |
| ApproverName | External_USABroker_Apex_UserData | ApproverName | Passthrough via GCID JOIN |
| ApprovedByDate | External_USABroker_Apex_UserData | ApprovedByDate | Passthrough via GCID JOIN |
| UpdateDate | ETL | GETDATE() | Insert timestamp |

## Lineage Notes

- **Change detection**: Uses LAG() window function on Fact_SnapshotCustomer partitioned by RealCID, ordered by UpdateDate to detect address/city changes. Only rows where Previous_Address != Address OR PreviousCity != City are included.
- **US-only filter**: WHERE VerificationLevelID=3 AND RegulationID=8 (FinCEN+FINRA regulated, fully verified customers).
- **Apex enrichment**: LEFT JOIN to USABroker external tables adds the customer's Apex brokerage account status and approver info.
