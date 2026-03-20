# Lineage: DWH_dbo.Dim_Customer

## Classification

| Property | Value |
|----------|-------|
| **Lineage Type** | DWH-Aggregated (14+ production sources consolidated into single dimension) |
| **Primary Sources** | Customer.CustomerStatic, BackOffice.Customer, History.Customer, History.BackOfficeCustomer |
| **Enrichment Sources** | 10+ additional microservice tables (2FA, Phone, Avatar, FTD, Screening, SF, Documents, Tangany, DLT, StocksLending) |
| **UC Targets** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` (masked), `main.pii_data.gold_sql_dp_prod_we_dwh_dbo_dim_customer` (unmasked) |
| **Copy Strategy** | Override |
| **Frequency** | Daily (1440 min) |
| **ETL SPs** | SP_Dim_Customer_DL_To_Synapse → SP_Dim_Customer |

## Source Chain

```
Production Microservices              DWH Staging (Ext_ tables)              DWH Synapse
──────────────────────              ────────────────────────              ───────────
Customer.CustomerStatic  ───►  Ext_Dim_Customer_Customer (cc)    ─┐
BackOffice.Customer      ───►  Ext_Dim_Customer_BOCustomer (bc)  ─┤
History.Customer         ───►  (inline subquery for SCD)          │  JOIN + CDC
History.BackOfficeCustomer ──►  (inline subquery for SCD)          │       │
                                                                   ▼       ▼
                                                              #customer → #full_list
                                                                   │
                                                                   ▼ DELETE+INSERT (TRAN)
                                                              Dim_Customer
                                                                   │
                                          ┌──────────── POST-LOAD UPDATEs ──────────────┐
STS_Audit_UserOperationsData  ──► Ext_2FA ─────────────────────► 2FA                    │
ContactVerification_Phone     ──► Ext_PhoneCustomer ───────────► Phone*, IsPhoneVerified│
UserApiDB_Customer_Avatars    ──► Ext_Avatars ─────────────────► HasAvatar               │
CustomerFinanceDB_FTDs        ──► Ext_FTD ─────────────────────► IsDepositor, FTD fields │
ScreeningService_UserScreening ──► Ext_ScreeningStatus ────────► ScreeningStatusID       │
SalesForce_DB_IdMapTopology   ──► Ext_SF_ID ───────────────────► SalesForceAccountID     │
BackOffice_CustomerDocument   ──► Ext_Document ────────────────► IsAddressProof, IsIDProof│
Customer_CustomerStatic       ──► Ext_CustomerStatic ──────────► ApexID                  │
UserApiDB_CustomerIdentification ► Ext_CustomerIdentification ─► TanganyID, DltID        │
ComplianceStateDB_StocksLending ► Ext_StocksLending ───────────► EquiLendID              │
Ext_Dim_SubChannel_UnifyCode  ──────────────────────────────────► SubChannelID            │
                                          └───────────────────────────────────────────────┘
                                                                   │
                                                              UC Override (daily)
                                                           ┌───────┴───────┐
                                                     masked (dwh)    unmasked (pii_data)
```

## Column Lineage Summary

| Category | Count | Source | Description |
|----------|-------|--------|-------------|
| Direct passthrough (Customer_Customer) | 40 | Customer.CustomerStatic | Core profile fields, some with ISNULL(history, current) pattern |
| Direct passthrough (BackOffice_Customer) | 20 | BackOffice.Customer | Compliance/admin attributes with history version preference |
| Post-load enrichment | 20 | Multiple ext tables | Avatar, FTD, screening, SF, documents, phone, Tangany, DLT, stocks lending |
| DWH-Computed | 5 | ETL logic | IsValidCustomer, IsCreditReportValidCB, UpdateDate, UserName_Lower, ModificationDateID (implicit) |
| Renamed | 5 | Multiple | RealCID←CID, AffiliateID←SerialID, AccountManagerID←ManagerID, EmployeeAccount←isEmployeeAccount, RegisteredReal←Registered |
| Source unclear | 5 | Unknown | RegisteredDemo, NumOfGurus, NumOfCopiers, NumOfRAF, DocsOK, Bankruptcy |
| **Total** | **~107** | | |

## Upstream Wiki Coverage

| Source Table | Wiki Available | Wiki Quality | Path |
|-------------|---------------|-------------|------|
| Customer.CustomerStatic | Yes | 9.7/10 | `DB_Schema/etoro/Wiki/Customer/Tables/Customer.CustomerStatic.md` |
| BackOffice.Customer | Yes | — | `DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.Customer.md` |
| History.Customer | No | — | Not yet documented |
