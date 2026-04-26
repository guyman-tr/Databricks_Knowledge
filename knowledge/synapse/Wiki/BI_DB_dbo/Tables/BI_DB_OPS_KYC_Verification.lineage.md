# Column Lineage: BI_DB_dbo.BI_DB_OPS_KYC_Verification

## Source Objects

| Source Object | Schema | Role | Join Condition |
|--------------|--------|------|---------------|
| DWH_dbo.Dim_Customer | DWH_dbo | Customer attributes — VL, PlayerStatus, FTD, GCID, IsValidCustomer filter | dc.RealCID = d.RealCID |
| DWH_dbo.Dim_Country | DWH_dbo | Region, RiskGroupID (filter NOT IN 1,2) | dc1.CountryID = dc.CountryID |
| DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name | dr.DWHRegulationID = dc.RegulationID |
| general.etoro_History_BackOfficeCustomer | general | VL date history (VL0/1/2/3, EvMatchStatus=2 dates) | hc.CID = cc.RealCID |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocument | BI_DB_dbo | KYC document uploads (POI/POA/etc.) | cd.CID = p.RealCID |
| BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType | BI_DB_dbo | Document type classification + review occurred date | cdt.DocumentID = cd.DocumentID |
| BI_DB_dbo.External_ComplianceStateDB_Dictionary_KYCFlowType | BI_DB_dbo | KYC flow type dictionary | ufd.KYCFlowTypeID = uf.KYCFlowID |
| BI_DB_dbo.External_ComplianceStateDB_Compliance_KycFlow | BI_DB_dbo | Current KYC flow per GCID | flw.GCID |
| BI_DB_dbo.External_ComplianceStateDB_History_KycFlow | BI_DB_dbo | Historical KYC flow (fallback when current=0) | flw.GCID, ROW_NUMBER DESC |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|--------------|-------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Passthrough |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough (filtered > 1) |
| PlayerStatusID | DWH_dbo.Dim_Customer | PlayerStatusID | Passthrough |
| PendingClosureStatusID | DWH_dbo.Dim_Customer | PendingClosureStatusID | Passthrough |
| PlayerStatusReasonID | DWH_dbo.Dim_Customer | PlayerStatusReasonID | Passthrough |
| EvMatchStatus | DWH_dbo.Dim_Customer | EvMatchStatus | Passthrough |
| Region | DWH_dbo.Dim_Country | Region | Dim-lookup passthrough via Dim_Customer.CountryID |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough via Dim_Customer.RegulationID |
| VerificationDate | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: MIN(ValidFrom) WHERE VerificationLevelID=3 |
| DaysToVerify | Multiple | EffectiveDate, VerificationDate | ETL-computed: DATEDIFF(day, EffectiveDate, VerificationDate), 0 when EVMatchStatusDate > VerificationDate, floor at 0 |
| IsDepositor | DWH_dbo.Dim_Customer | FirstDepositDate | ETL-computed: 1 when FirstDepositDate BETWEEN 2000-01-01 AND 2099-01-01, else 0 |
| EffectiveAddDate | Multiple | Multiple | ETL-computed: effective start date for SLA calculation — EVMatchStatusDate if EV-verified, DateAdded if no FTD, conditional on FTD vs doc vs verification ordering |
| EvMatchStatusDate | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: MIN(ValidFrom) WHERE EvMatchStatus=2 |
| RiskGroupID | DWH_dbo.Dim_Country | RiskGroupID | Dim-lookup passthrough via Dim_Customer.CountryID |
| VerificationMethod | Multiple | VerificationLevelID, EvMatchStatus, DateAdded | ETL-computed: CASE — 'EV' when VL=3 AND EvMatchStatus=2; 'Docs' when VL=3 AND DateAdded not null or EvMatchStatus<>2; 'NA' otherwise |
| HoursToVerify | Multiple | EffectiveDate, VerificationDate | ETL-computed: DATEDIFF(hour, EffectiveDate, VerificationDate), floor at 0 |
| MinutesToVerify | Multiple | EffectiveDate, VerificationDate | ETL-computed: DATEDIFF(minute, EffectiveDate, VerificationDate), floor at 0 |
| KYCFlow | ComplianceStateDB KYC flow tables | KYCFlowTypeID → Name | ETL-computed: current KYC flow name, fallback to latest historical if current=0 |
| RegisteredDate | DWH_dbo.Dim_Customer | RegisteredReal | Passthrough (renamed) |
| UpdateDate | — | — | ETL-computed: GETDATE() |
| VerificationLevel1Date | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: MIN(ValidFrom) WHERE VerificationLevelID=1 |
| VerificationLevel2Date | general.etoro_History_BackOfficeCustomer | ValidFrom | ETL-computed: MIN(ValidFrom) WHERE VerificationLevelID=2 |
| DateAdded | External_etoro_BackOffice_CustomerDocument | DateAdded | Passthrough — most recent document upload date (ROW_NUMBER DESC) |
| Occurred | External_etoro_BackOffice_CustomerDocumentToDocumentType | Occurred | Passthrough — document review occurred timestamp, sentinel 3000-01-01 when NULL |
| FirstReviewed | Multiple | Multiple | ETL-computed: effective first document review date — EVMatchStatusDate if EV-verified, Occurred if docs, conditional logic |
| FirstTouch | Multiple | Multiple | ETL-computed: DATEDIFF(day, EffectiveAddDate/DateAdded/VL2Date, FirstReviewed/Occurred/EVMatchStatusDate) — days from effective start to first review |
| FirstTouchHour | Multiple | Multiple | ETL-computed: same as FirstTouch but in hours |
| FirstTouchMinute | Multiple | Multiple | ETL-computed: same as FirstTouch but in minutes |
