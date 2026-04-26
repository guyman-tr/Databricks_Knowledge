# Lineage: BI_DB_dbo.Apex_UserProgramEnrolment_2024_01_25

**Generated**: 2026-04-23
**Schema**: BI_DB_dbo
**Object**: Apex_UserProgramEnrolment_2024_01_25
**Object Type**: Table — point-in-time snapshot (2024-01-25)
**Writer SP**: None — manual snapshot of External_USABroker_Apex_UserProgramEnrolment
**Production Source**: USABroker / Apex Clearing → Bronze lake → `Bronze/USABroker/apex/UserProgramEnrolment`
**Predecessor Table**: BI_DB_dbo.USABroker_Apex_UserProgramEnrolment_old
**Live Source**: BI_DB_dbo.External_USABroker_Apex_UserProgramEnrolment

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | GCID | External_USABroker_Apex_UserProgramEnrolment | GCID | Passthrough (snapshot) | Tier 3 |
| 2 | UserProgramEnrolmentStatusID | External_USABroker_Apex_UserProgramEnrolment | UserProgramEnrolmentStatusID | Passthrough (snapshot) | Tier 3 |
| 3 | UserProgramID | External_USABroker_Apex_UserProgramEnrolment | UserProgramID | Passthrough (snapshot) | Tier 3 |
| 4 | BeginTime | External_USABroker_Apex_UserProgramEnrolment | BeginTime | Passthrough (snapshot) | Tier 3 |
| 5 | EndTime | External_USABroker_Apex_UserProgramEnrolment | EndTime | Passthrough (snapshot) | Tier 3 |

## ETL Pipeline

```
USABroker / Apex Clearing (US broker production system)
  |-- Generic Pipeline (Bronze export, parquet) --|
  v
Bronze/USABroker/apex/UserProgramEnrolment (Data Lake)
  |-- External Table definition --|
  v
BI_DB_dbo.External_USABroker_Apex_UserProgramEnrolment (live external table, current state)
  |-- Manual snapshot (no SP — one-time CTAS/INSERT AS OF 2024-01-25) --|
  v
BI_DB_dbo.Apex_UserProgramEnrolment_2024_01_25 (13,649 rows — FROZEN as of 2024-01-25)
  |-- Referenced by SP_Crypto_NOP and SP_CMR_...Staking for historical analysis --|

Note: Active SPs (SP_Crypto_NOP, SP_CMR_Automation_RealCrypto_Main_CryptoNOP_ALLRegs_USA_Staking)
      use the LIVE External table, not this snapshot.

Predecessor: BI_DB_dbo.USABroker_UserProgramEnrolment_old (same schema, older snapshot)
```
