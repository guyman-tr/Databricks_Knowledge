# BI_DB_dbo.BI_DB_AML_High_Risk_Wallet — Column Lineage

**Generated**: 2026-04-22  
**Schema**: BI_DB_dbo  
**Object**: BI_DB_AML_High_Risk_Wallet  
**Writer SP**: SP_AML_High_Risk_Wallet  
**Load Pattern**: TRUNCATE + INSERT (full daily rebuild, no date parameter)  

---

## ETL Pipeline

```
Population base (Step 01 — #pop):
  DWH_dbo.Dim_Customer
    WHERE IsValidCustomer=1 AND VerificationLevelID=3 (fully verified only)
    INNER JOIN Dim_PlayerStatus NOT IN (2=Blocked, 4=BUR)
    INNER JOIN External_RiskClassification WHERE RiskScoreName='High'
    → Only fully-verified, High-AML-Risk, non-blocked customers

Dimension enrichment (#pop):
  Dim_Regulation          → Regulation name (INNER JOIN)
  Dim_Country             → Country name + RiskGroupID (INNER JOIN)
  Dim_PlayerStatus        → PlayerStatus name (INNER JOIN, excludes 2=Blocked, 4=BUR)
  Dim_PlayerLevel         → Club name (INNER JOIN)
  Dim_ScreeningStatus     → ScreeningStatus name (LEFT JOIN)
  External_RiskClassification_dbo_V_RiskClassificationDataLake:
    RiskScoreName, RiskScore_Explanation, PreviousRiskUpdateDate, GCID
  From Dim_Customer directly:
    RealCID (→CID), GCID, BirthDate (→Age), FirstDepositDate, HasWallet, IsDepositor
  Computed: Age = DATEDIFF(YEAR, BirthDate, GETDATE())

FirstWalletDate (Step 02 — #joinDate):
  EXW_Wallet.CustomerWalletsView (cwv)
    JOIN #pop ON pp.GCID = cwv.Gcid
    MIN(cwv.Occurred) per GCID → FirstWalletDate (first eToro Money wallet enrollment date)
  LEFT JOIN from #pop — NULL when no wallet enrollment

Occupation_Answer (Step 03 — #occupation):
  BI_DB_dbo.BI_DB_KYC_Panel
    JOIN #pop ON RealCID = CID
    Q18_AnswerText → Occupation_Answer (KYC self-declared occupation)
  INNER JOIN — NULL when customer has no KYC panel record

Risk_before_Wallet (Step 04 — #final computed):
  CASE WHEN PreviousRiskUpdateDate IS NULL AND FirstWalletDate >= FirstDepositDate THEN 1
       WHEN FirstWalletDate IS NOT NULL AND FirstWalletDate >= PreviousRiskUpdateDate THEN 1
       ELSE 0 END
  → 1 = customer was High Risk at or before wallet enrollment
  → 0 = customer joined wallet before risk escalated to High, or no wallet

TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_High_Risk_Wallet
INSERT SELECT #final + GETDATE() AS UpdateDate
```

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough (alias) | T1 |
| 2 | GCID | DWH_dbo.Dim_Customer | GCID | Passthrough | T1 |
| 3 | Age | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(YEAR, BirthDate, GETDATE()) — recalculated daily | T2 |
| 4 | Regulation | DWH_dbo.Dim_Regulation | Name | Lookup via Dim_Customer.RegulationID; INNER JOIN | T1 |
| 5 | Country | DWH_dbo.Dim_Country | Name | Lookup via Dim_Customer.CountryID; INNER JOIN | T1 |
| 6 | RiskGroupID | DWH_dbo.Dim_Country | RiskGroupID | Lookup via Dim_Customer.CountryID; same INNER JOIN as Country | T1 |
| 7 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Lookup via Dim_Customer.PlayerStatusID; INNER JOIN (excludes 2=Blocked, 4=BUR) | T1 |
| 8 | Club | DWH_dbo.Dim_PlayerLevel | Name | Lookup via Dim_Customer.PlayerLevelID; INNER JOIN | T1 |
| 9 | ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Name | Lookup via Dim_Customer.ScreeningStatusID; LEFT JOIN (NULL = no screening record) | T3 |
| 10 | RiskScoreName | BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScoreName | Passthrough; INNER JOIN filter: always = 'High' in this table | T1 |
| 11 | RiskScore_Explanation | BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | RiskScore_Explanation | Passthrough; comma-separated list of non-zero risk parameter names | T1 |
| 12 | PreviousRiskUpdateDate | BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | PreviousRiskUpdateDate | CAST to DATE; date when prior (pre-High) risk score was set | T1 |
| 13 | FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | CAST to DATE; passthrough from Dim_Customer | T2 |
| 14 | HasWallet | DWH_dbo.Dim_Customer | HasWallet | Passthrough | T1 |
| 15 | IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Passthrough; computed by SP_Dim_Customer | T2 |
| 16 | Risk_before_Wallet | — | FirstWalletDate + PreviousRiskUpdateDate + FirstDepositDate | SP-computed CASE flag; 1 = High Risk at/before wallet enrollment, 0 = risk escalated after wallet or no wallet | T2 |
| 17 | Occupation_Answer | BI_DB_dbo.BI_DB_KYC_Panel | Q18_AnswerText | Passthrough (renamed); KYC Q18 = self-declared occupation | T2 |
| 18 | UpdateDate | — | — | GETDATE() at INSERT time | Propagation blacklist |
| 19 | FirstWalletDate | EXW_Wallet.CustomerWalletsView (via EXW_dbo schema) | Occurred | MIN(Occurred) per GCID — first eToro Money wallet enrollment date; CAST to DATE; NULL if no wallet | T2 |

---

## UC External Lineage

**UC Target**: Not migrated — AML compliance workbench for High Risk wallet customers.

---

## Source Objects

| Object | Type | Notes |
|--------|------|-------|
| DWH_dbo.Dim_Customer | Dimension | Population base (IsValidCustomer=1, VerificationLevelID=3); CID, GCID, BirthDate, FirstDepositDate, HasWallet, IsDepositor |
| DWH_dbo.Dim_Regulation | Dimension | Regulation name (INNER JOIN) |
| DWH_dbo.Dim_Country | Dimension | Country name and RiskGroupID (INNER JOIN) |
| DWH_dbo.Dim_PlayerStatus | Dimension | PlayerStatus name (INNER JOIN, excludes Blocked/BUR) |
| DWH_dbo.Dim_PlayerLevel | Dimension | Club/loyalty tier name (INNER JOIN) |
| DWH_dbo.Dim_ScreeningStatus | Dimension | Screening outcome name (LEFT JOIN) |
| BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | External Table | INNER JOIN on RiskScoreName='High'; provides RiskScoreName, RiskScore_Explanation, PreviousRiskUpdateDate, GCID |
| EXW_Wallet.CustomerWalletsView | View (EXW schema) | First wallet enrollment date (MIN(Occurred) per GCID) |
| BI_DB_dbo.BI_DB_KYC_Panel | Table | KYC Q18 occupation answer (INNER JOIN on RealCID) |
