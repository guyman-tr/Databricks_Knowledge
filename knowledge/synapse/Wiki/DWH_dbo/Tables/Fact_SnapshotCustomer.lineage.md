# Lineage: DWH_dbo.Fact_SnapshotCustomer

> Column-level lineage from 6 source systems through staging Ext_FSC tables into the DWH customer snapshot.

## Source Chain

```
Customer Core (CC) → etoro_History_Customer_Customer (CDC)
  → DWH_dbo.Ext_FSC_Real_Customer_Customer

Back Office (BO) → etoro_History_BackOfficeCustomer (CDC)
  → DWH_dbo.Ext_FSC_BackOffice_Customer
  → DWH_dbo.Ext_FSC_BackOffice_RegulationChangeLog

FTD → CustomerFinanceDB_Customer_FirstTimeDeposits
  → DWH_dbo.Ext_FSC_Customer_FirstTimeDeposits

Phone → ContactVerification_Phone_Customer
  → DWH_dbo.Ext_FSC_PhoneCustomer

DLT/Tangany → UserApiDB_Customer_CustomerIdentification
  → DWH_dbo.Ext_Dim_Customer_CustomerIdentification_DLT

StocksLending → ComplianceStateDB_Compliance_StocksLending
  → DWH_dbo.Ext_FSC_StocksLending

[All sources via SP_Fact_SnapshotCustomer_DL_To_Synapse]
  -> SP_Fact_SnapshotCustomer(@dt)
  -> DWH_dbo.Fact_SnapshotCustomer [MERGE: close+reopen SCD2 rows]
  -> DWH_dbo.V_Fact_SnapshotCustomer_FromDateID [UC export view, generic_id=1115]
```

## Generic Pipeline Mapping

Not found for Fact_SnapshotCustomer directly. The table is exported to Databricks UC via the view V_Fact_SnapshotCustomer_FromDateID (generic_id=1115, daily Merge).

UC targets:
- `pii_data.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid` (unmasked PII)
- `dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` (Email/City/Address/Zip masked)

## Column Lineage

| # | DWH Column | Source System | Source Object | Source Column | Transform | Notes |
|---|-----------|--------------|---------------|---------------|-----------|-------|
| 1 | GCID | CC / DLT | Ext_FSC_Real_Customer_Customer / Ext_Dim_Customer_CustomerIdentification_DLT | GCID | COALESCE(CC.GCID, FSC.GCID, DLT.GCID, 0) | |
| 2 | RealCID | CC | Ext_FSC_Real_Customer_Customer | CID | Renamed to RealCID | Hash distribution key |
| 3 | DemoCID | — | NOT populated by current SP | — | LEGACY (DEFAULT NULL) | Was never/rarely populated |
| 4 | CustomerChangeTypeID | — | NOT populated by current SP | — | LEGACY (DEFAULT NULL) | Old SCD2 change type |
| 5 | CurentValue | — | NOT populated by current SP | — | LEGACY (DEFAULT NULL) | Typo: "Curent" |
| 6 | PreviousValue | — | NOT populated by current SP | — | LEGACY (DEFAULT NULL) | |
| 7 | CountryID | CC | Ext_FSC_Real_Customer_Customer | CountryID | COALESCE(CC, FSC, 0) | |
| 8 | LabelID | CC | Ext_FSC_Real_Customer_Customer | LabelID | COALESCE(CC, FSC, 0) | |
| 9 | LanguageID | CC | Ext_FSC_Real_Customer_Customer | LanguageID | COALESCE(CC, FSC, 0) | |
| 10 | VerificationLevelID | BO | Ext_FSC_BackOffice_Customer | VerificationLevelID | COALESCE(BO, FSC, 0) | DEFAULT -1 |
| 11 | DocsOK | — | NOT populated by current SP | — | LEGACY (DEFAULT 0) | |
| 12 | PlayerStatusID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusID | COALESCE(CC, FSC, 0) | |
| 13 | Bankruptcy | — | NOT populated by current SP | — | LEGACY (DEFAULT 0) | |
| 14 | RiskStatusID | BO | Ext_FSC_BackOffice_Customer | RiskStatusID | COALESCE(BO, FSC, 0) | |
| 15 | RiskClassificationID | BO | Ext_FSC_BackOffice_Customer | RiskClassificationID | COALESCE(BO, FSC, 0) | |
| 16 | CommunicationLanguageID | CC | Ext_FSC_Real_Customer_Customer | CommunicationLanguageID | COALESCE(CC, FSC, 0) | |
| 17 | PremiumAccount | — | NOT populated by current SP | — | LEGACY (DEFAULT 0) | |
| 18 | Evangelist | — | NOT populated by current SP | — | LEGACY (DEFAULT 0) | |
| 19 | GuruStatusID | BO | Ext_FSC_BackOffice_Customer | GuruStatusID | COALESCE(BO, FSC, 0) | |
| 20 | UpdateDate | ETL-computed | N/A | N/A | GETDATE() | Load timestamp |
| 21 | RegulationID | Regulation | Ext_FSC_BackOffice_RegulationChangeLog | ToRegulationID | COALESCE(RegChange, FSC.RegulationID, BO.RegulationID, 0) | End-of-day regulation |
| 22 | AccountStatusID | CC | Ext_FSC_Real_Customer_Customer | AccountStatusID | COALESCE(CC, FSC, 0) | |
| 23 | AccountManagerID | BO | Ext_FSC_BackOffice_Customer | AccountManagerID | COALESCE(BO, FSC, 0) | |
| 24 | PlayerLevelID | CC | Ext_FSC_Real_Customer_Customer | PlayerLevelID | COALESCE(CC, FSC, 0) | |
| 25 | AccountTypeID | BO | Ext_FSC_BackOffice_Customer | AccountTypeID | COALESCE(BO, FSC, 0) | |
| 26 | DateRangeID | ETL-computed | N/A | @date + year-end | convert(bigint, convert(varchar,@date,112) + right(convert(varchar,@largedate,112),4)) | SCD2 range key |
| 27 | IsDepositor | FTD | Ext_FSC_Customer_FirstTimeDeposits | CID | 1 if CID present | COALESCE(FTD.IsDepositor, FSC.IsDepositor, 0) |
| 28 | PendingClosureStatusID | CC | Ext_FSC_Real_Customer_Customer | PendingClosureStatusID | COALESCE(CC, FSC, 0) | |
| 29 | DocumentStatusID | BO | Ext_FSC_BackOffice_Customer | DocumentStatusID | COALESCE(BO, FSC, 0) | |
| 30 | SuitabilityTestStatusID | BO | Ext_FSC_BackOffice_Customer | SuitabilityTestStatusID | COALESCE(BO, FSC, 0) | |
| 31 | MifidCategorizationID | BO | Ext_FSC_BackOffice_Customer | MifidCategorizationID | COALESCE(BO, FSC, 0) | |
| 32 | IsEmailVerified | CC | Ext_FSC_Real_Customer_Customer | IsEmailVerified | COALESCE(CC, FSC, 0) | |
| 33 | IsValidCustomer | ETL-computed | N/A | PlayerLevelID, LabelID, CountryID | CASE: PlayerLevelID<>4 AND LabelID NOT IN (26,30) AND CountryID<>250 | See §2.2 in wiki |
| 34 | DesignatedRegulationID | BO | Ext_FSC_BackOffice_Customer | DesignatedRegulationID | COALESCE(BO, FSC, 0) | |
| 35 | EvMatchStatus | BO | Ext_FSC_BackOffice_Customer | EvMatchStatus | COALESCE(BO, FSC, 0) | |
| 36 | RegionID | CC | Ext_FSC_Real_Customer_Customer | RegionID | COALESCE(CC, FSC, 0) | |
| 37 | PlayerStatusReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusReasonID | COALESCE(CC, FSC, 0) | |
| 38 | IsCreditReportValidCB | ETL-computed | N/A | PlayerLevelID, AccountTypeID, LabelID, CountryID | CASE: complex CB eligibility rule | See §2.3 in wiki |
| 39 | AffiliateID | CC | Ext_FSC_Real_Customer_Customer | AffiliateID | COALESCE(CC, FSC, 0) | |
| 40 | Email | CC | Ext_FSC_Real_Customer_Customer | Email | COALESCE(CC, FSC, '') + GDPR masking | PII masked at DDL level |
| 41 | City | CC | Ext_FSC_Real_Customer_Customer | City | COALESCE(CC, FSC, '') + GDPR masking | PII masked at DDL level |
| 42 | Address | CC | Ext_FSC_Real_Customer_Customer | Address | COALESCE(CC, FSC, '') + GDPR masking | PII masked at DDL level |
| 43 | Zip | CC | Ext_FSC_Real_Customer_Customer | Zip | COALESCE(CC, FSC, '') + GDPR masking | PII masked at DDL level |
| 44 | PhoneNumber | Phone | Ext_FSC_PhoneCustomer | PhoneNumber | COALESCE(Phone, FSC, '') | GDPR: 'DelPhoneNumber_' + CID for erasures |
| 45 | IsPhoneVerified | Phone | Ext_FSC_PhoneCustomer | PhoneVerifiedID | CASE WHEN PhoneVerifiedID IN (1,2) THEN 1 ELSE 0 | |
| 46 | PhoneVerificationDateID | Phone | Ext_FSC_PhoneCustomer | PhoneVerificationDateID | COALESCE(Phone, FSC, ''); exclude 19000101 rows | varchar(8) YYYYMMDD |
| 47 | PlayerStatusSubReasonID | CC | Ext_FSC_Real_Customer_Customer | PlayerStatusSubReasonID | COALESCE(CC, FSC, 0) | |
| 48 | WeekendFeePrecentage | CC | Ext_FSC_Real_Customer_Customer | WeekendFeePrecentage | COALESCE(CC, FSC) | Typo in name |
| 49 | DltStatusID | DLT | UserApiDB_Customer_CustomerIdentification | DltStatusID | via Ext_Dim_Customer_CustomerIdentification_DLT | COALESCE(DLT, FSC, 0) |
| 50 | DltID | DLT | UserApiDB_Customer_CustomerIdentification | DltID | via Ext_Dim_Customer_CustomerIdentification_DLT | COALESCE(DLT, FSC, null); only rows where DltID IS NOT NULL |
| 51 | EquiLendID | StocksLending | ComplianceStateDB_Compliance_StocksLending | EquiLendID | via Ext_FSC_StocksLending | COALESCE(STL, FSC, null) |
| 52 | StocksLendingStatusID | StocksLending | ComplianceStateDB_Compliance_StocksLending | StocksLendingStatusID | via Ext_FSC_StocksLending | COALESCE(STL, FSC, null) |

## ETL SP Details

**Outer SP**: DWH_dbo.SP_Fact_SnapshotCustomer_DL_To_Synapse
**Inner SP**: DWH_dbo.SP_Fact_SnapshotCustomer
**Author**: Boris Slutski (2018-03-11); multiple contributors through 2025
**Pattern**: Daily MERGE — close existing SCD2 rows + INSERT new rows. Jan 1 special case: INSERT only (no MERGE, reopen for new year).
**Dim_Range maintenance**: SP also inserts new DateRangeID entries into Dim_Range after each MERGE cycle.
