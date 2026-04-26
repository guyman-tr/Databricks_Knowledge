# Lineage: BI_DB_dbo.BI_DB_AML_KYC_Process

## Writer SP

`BI_DB_dbo.SP_AML_KYC_Process` — TRUNCATE + INSERT pattern. Runs at OpsDB Priority 0 (base layer, no intra-schema dependencies). Full refresh on each run.

## Source Objects

| # | Source Object | Type | Role | Columns Contributed |
|---|--------------|------|------|---------------------|
| 1 | DWH_dbo.Dim_Customer | Dim | Primary population base; identity, compliance flags, document proof status | CID (RealCID), HasWallet, Has_POI (IsIDProof), POI_ExpiryDate (IsIDProofExpiryDate), Has_POA (IsAddressProof), POA_ExpiryDate (IsAddressProofExpiryDate), FirstDepositDate, FirstDepositAmount; filter on VerificationLevelID=3, IsValidCustomer=1, IsDepositor=1, EvMatchStatus≠2 |
| 2 | DWH_dbo.Dim_Regulation | Dim | Resolve regulation name | Regulation = Name |
| 3 | DWH_dbo.Dim_Country | Dim | Resolve country name | Country = Name |
| 4 | DWH_dbo.Dim_PlayerStatus | Dim | Resolve status name; filter excludes Blocked (2) and Blocked Upon Request (4) | PlayerStatus = Name |
| 5 | DWH_dbo.Dim_PlayerLevel | Dim | Resolve customer tier name | Club = Name |
| 6 | DWH_dbo.Dim_ScreeningStatus | Dim | Resolve AML screening result | ScreeningStatus = Name |
| 7 | DWH_dbo.Dim_AccountType | Dim | Resolve account category | AccountType = Name |
| 8 | DWH_dbo.Dim_EvMatchStatus | Dim | Resolve identity verification label | EvMatchStatusName |
| 9 | DWH_dbo.Dim_PlayerStatusReasons | Dim | Resolve player status reason label | PlayerStatusReason = Name |
| 10 | DWH_dbo.Dim_PlayerStatusSubReasons | Dim | Resolve player status sub-reason label | PlayerStatusSubReasonName |
| 11 | BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake | External Table | AML risk classification score | RiskScoreName (lake: DE_OUTPUT/Risk_Classification) |
| 12 | BI_DB_dbo.External_etoro_BackOffice_Customer | External Table | UAE Pass EID completion status for UAE Pass population | UAE_Pass_Status derived from EIDStatusID: NULL→'None', 1→'PartiallyCompleted', else→'Completed' |
| 13 | DWH_dbo.Fact_CustomerAction | Fact | All-time deposit total (ActionTypeID=7) | (used internally in #deposits temp table — not directly in final columns; Revenue sourced separately) |
| 14 | eMoney_dbo.eMoney_Dim_Account | Dim | eToro Money wallet presence | Has_eMoney = CASE WHEN CID found WHERE IsValidETM=1 AND IsTestAccount=0 AND CurrencyBalanceStatusID≠4 THEN 1 ELSE 0 END |
| 15 | DWH_dbo.V_Liabilities | View | Net equity snapshot as of yesterday | Equity = ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) WHERE DateID = yesterday |
| 16 | BI_DB_dbo.BI_DB_DailyCommisionReport | Table | All-time revenue from commissions and rollover fees | Revenue = SUM(FullCommissions + RollOverFee) — no date upper bound beyond GETDATE()-1 |
| 17 | BI_DB_dbo.BI_DB_DDR_Fact_AUM | Table | IBAN balance equity snapshot as of yesterday | Equiy_IBAN = IBANBalance WHERE DateID = yesterday |
| 18 | BI_DB_dbo.BI_DB_CIDFirstDates | Table | Verification milestone dates | VerificationLevel3Date |

## Data Flow

```
Population Sources (two segments):
  ─────────────────────────────────────────────────────────────────
  Main_POP (~923K):
    DWH_dbo.Dim_Customer (VerificationLevelID=3, IsValidCustomer=1, IsDepositor=1,
      PlayerStatusID NOT IN (2,4), EvMatchStatus≠2,
      (IsIDProofExpiryDate<=NOW OR IsIDProof=0/NULL) OR
      (IsAddressProofExpiryDate<=NOW OR IsAddressProof=0/NULL))
      └── JOIN Dim_Regulation, Dim_Country, Dim_PlayerStatus, Dim_PlayerLevel,
              Dim_ScreeningStatus, Dim_AccountType, Dim_EvMatchStatus,
              Dim_PlayerStatusReasons, Dim_PlayerStatusSubReasons
      └── LEFT JOIN External_RiskClassification → RiskScoreName
      └── LEFT JOIN BI_DB_CIDFirstDates → VerificationLevel3Date

  UAE_Pass_15K_Client (~92):
    DWH_dbo.Dim_Customer (FirstDepositAmount≥15000, VerificationLevelID=3,
      PlayerStatusID NOT IN (2,4), same basic filters)
      └── JOIN External_etoro_BackOffice_Customer (EIDStatusID≠2) → UAE_Pass_Status

  Enrichment Temp Tables:
    #deposits  ← Fact_CustomerAction (ActionTypeID=7)  [note: not used in final SELECT; Revenue from DailyCommisionReport]
    #eMoney    ← eMoney_dbo.eMoney_Dim_Account → Has_eMoney
    #equity    ← DWH_dbo.V_Liabilities (DateID=yesterday) → Equity
    #Commission ← BI_DB_dbo.BI_DB_DailyCommisionReport → Revenue
    #Equiy_IBAN ← BI_DB_dbo.BI_DB_DDR_Fact_AUM (DateID=yesterday) → Equiy_IBAN

  SP_AML_KYC_Process
    TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_KYC_Process
    INSERT ... FROM #final
         ↓
  BI_DB_dbo.BI_DB_AML_KYC_Process
```

## Population Segment Summary

| Ind | Description | Filter Logic | Row Count (2026-04-12) |
|-----|-------------|--------------|------------------------|
| Main_POP | VL3 depositors with missing/expired POI or POA and not EV-verified | VerificationLevelID=3, IsValidCustomer=1, IsDepositor=1, PlayerStatusID NOT IN (2,4), EvMatchStatus≠2, (expired/missing POI OR POA) | 923,169 |
| UAE_Pass_15K_Client | VL3 depositors with FTDA ≥ $15K and incomplete UAE Pass | FirstDepositAmount≥15000, same base criteria, EIDStatusID≠2 | 92 |

## UAE Pass Status Derivation

| EIDStatusID (BackOffice.Customer) | UAE_Pass_Status |
|-----------------------------------|-----------------|
| NULL | 'None' |
| 1 | 'PartiallyCompleted' |
| 2 | Excluded by filter (EIDStatusID≠2) |
| Other non-NULL/non-1 | 'Completed' |

## Derived / Computed Columns

| Column | Derivation |
|--------|-----------|
| Has_EV | `CASE WHEN dc.EvMatchStatus <> 2 THEN 0 ELSE 1 END` — all rows = 0 by population definition |
| Is_POI_Expired | `CASE WHEN POI_ExpiryDate <= GETDATE() THEN 1 ELSE 0 END` |
| Is_POA_Expired | `CASE WHEN POA_ExpiryDate <= GETDATE() THEN 1 ELSE 0 END` |
| Has_eMoney | `CASE WHEN CID IN #eMoney THEN 1 ELSE 0 END` |
| Ind | Hardcoded string: 'Main_POP' or 'UAE_Pass_15K_Client' |
| UpdateDate | `GETDATE()` at INSERT time |

## Known Data Issues

- **`Equiy_IBAN` column name typo**: DDL column is `[Equiy_IBAN]` (missing 'T'); should be `Equity_IBAN`. This typo originates in the SP code (`Equiy_IBAN` alias) and has been persisted to the DDL. The column stores IBANBalance from BI_DB_DDR_Fact_AUM.
- **#deposits temp table**: The SP builds a `#deposits` table from Fact_CustomerAction (ActionTypeID=7) but does NOT use it in the final INSERT — the Revenue column comes from `#Commission` (BI_DB_DailyCommisionReport), not from `#deposits`. The temp table appears to be a legacy artifact or unused staging construct.

---
*Generated: 2026-04-22 | Object: BI_DB_dbo.BI_DB_AML_KYC_Process | Writer SP: SP_AML_KYC_Process*
