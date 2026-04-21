# Column Lineage — eMoney_dbo.eMoney_Customer_Risk_Assessment_History

**Generated**: 2026-04-21 | **Writer SP**: SP_eMoney_Customer_Risk_Assessment Step 32 (1,730 lines)
**ETL Pattern**: Conditional INSERT (class-change-only: `WHERE trg.CID IS NULL OR src.ClientRisk <> trg.ClientRisk`)
**Source**: eMoney_Customer_Risk_Assessment (same-session snapshot values from Step 31)
**Distribution**: HASH(CID) | **Index**: HEAP

---

## Source Objects

Same 29 source objects as eMoney_Customer_Risk_Assessment — all inputs flow through the snapshot table, which is the immediate source for History rows.

| Source Object | Role | Schema |
|---------------|------|--------|
| `eMoney_dbo.eMoney_Customer_Risk_Assessment` | Immediate source (Step 32 reads Step 31 INSERT result) | eMoney_dbo |
| `DWH_dbo.Dim_Customer` | Upstream source of identity, compliance, date columns | DWH_dbo |
| `eMoney_dbo.eMoney_Dim_Account` | Upstream source of eTM account columns | eMoney_dbo |
| `eMoney_dbo.eMoney_Panel_FirstDates` | Upstream source of FMI/FMO date columns | eMoney_dbo |
| `BI_DB_dbo.External_Fivetran_*_classification_table` | Upstream source of P*_Response / P*_Risk columns | BI_DB_dbo |
| *(22 additional upstream objects — same as CRA snapshot)* | See eMoney_Customer_Risk_Assessment.lineage.md | multiple |

---

## Column Lineage

All 120 columns are sourced from the same-session snapshot row (Step 31 INSERT into eMoney_Customer_Risk_Assessment) via the Step 32 conditional INSERT. Tier assignments are identical to the snapshot table.

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | DWH_dbo.Dim_Customer | RealCID | Passthrough from snapshot | Tier 1 |
| 2 | GCID | DWH_dbo.Dim_Customer | GCID | Passthrough from snapshot | Tier 1 |
| 3 | ClientRiskDate | ETL-computed | — | GETDATE() at time of class change (or first appearance); carried from snapshot | Tier 2 |
| 4 | ClientRisk | ETL-computed | — | Risk class at time of class change event | Tier 2 |
| 5 | ClientRiskAssignmentType | ETL-computed | — | Assignment type at time of class change | Tier 2 |
| 6 | Risk_Final_Result | ETL-computed | — | Composite score at time of class change | Tier 2 |
| 7 | PreviousClientRisk | eMoney_Customer_Risk_Assessment_History | ClientRisk | Latest History row BEFORE this class change (Step 27 window) | Tier 2 |
| 8 | PreviousClientRiskDate | eMoney_Customer_Risk_Assessment_History | ClientRiskDate | Date of previous class state (Step 27 window) | Tier 2 |
| 9 | VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | Passthrough from snapshot | Tier 1 |
| 10 | IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | Passthrough from snapshot | Tier 2 |
| 11 | IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Passthrough from snapshot | Tier 2 |
| 12 | AccountType | DWH_dbo.Dim_AccountType | Name | Name lookup passthrough from snapshot | Tier 2 |
| 13 | Regulation | DWH_dbo.Dim_Regulation | Name | Name lookup passthrough from snapshot | Tier 2 |
| 14 | Club | DWH_dbo.Dim_PlayerLevel | Name | Name lookup passthrough from snapshot | Tier 2 |
| 15 | ClientAge | ETL-computed | — | Age as of the ETL run when the class change occurred | Tier 2 |
| 16 | DateOfBirth | DWH_dbo.Dim_Customer | BirthDate | CAST to DATE passthrough from snapshot | Tier 1 |
| 17 | DateOfReg | DWH_dbo.Dim_Customer | RegisteredReal | CAST to DATE passthrough from snapshot | Tier 1 |
| 18 | DateOfFTD | DWH_dbo.Dim_Customer | FirstDepositDate | CAST to DATE passthrough from snapshot | Tier 2 |
| 19 | BusinessDuration | ETL-computed | — | Categorical tenure passthrough from snapshot | Tier 2 |
| 20 | CountryAddress | DWH_dbo.Dim_Country | CountryName | Name lookup passthrough from snapshot | Tier 2 |
| 21 | CountryCitizenship | DWH_dbo.Dim_Country | CountryName | Name lookup passthrough from snapshot | Tier 2 |
| 22 | CountryPOB | DWH_dbo.Dim_Country | CountryName | Name lookup passthrough from snapshot | Tier 2 |
| 23 | CountryTIN | ETL-computed | — | TIN country passthrough from snapshot | Tier 2 |
| 24 | CountryAddress_IsHRC | ETL-computed | — | HRC flag passthrough from snapshot | Tier 2 |
| 25 | CountryCitizenship_IsHRC | ETL-computed | — | HRC flag passthrough from snapshot | Tier 2 |
| 26 | CountryPOB_IsHRC | ETL-computed | — | HRC flag passthrough from snapshot | Tier 2 |
| 27 | CountryTIN_IsHRC | ETL-computed | — | HRC flag passthrough from snapshot | Tier 2 |
| 28 | AccountStatus | DWH_dbo.Dim_AccountStatus | AccountStatusName | Name lookup passthrough from snapshot | Tier 2 |
| 29 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Name lookup passthrough from snapshot | Tier 2 |
| 30 | PlayerStatusReason | DWH_dbo.Dim_PlayerStatusReasons | Name | Name lookup passthrough from snapshot | Tier 2 |
| 31 | PlayerStatusSubReason | DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Name lookup passthrough from snapshot | Tier 2 |
| 32 | ScreeningStatus | DWH_dbo.Dim_ScreeningStatus | Name | Name lookup passthrough from snapshot | Tier 2 |
| 33 | EVStatus | DWH_dbo.Dim_EvMatchStatus | EvMatchStatusName | Name lookup passthrough from snapshot | Tier 2 |
| 34 | DocumentStatus | DWH_dbo.Dim_DocumentStatus | DocumentStatusName | Name lookup passthrough from snapshot | Tier 2 |
| 35 | PhoneStatus | DWH_dbo.Dim_PhoneVerified | PhoneVerifiedName | Name lookup passthrough from snapshot | Tier 2 |
| 36 | DocsOK | DWH_dbo.Dim_Customer | DocsOK | Passthrough from snapshot | Tier 2 |
| 37 | IsIDProof | DWH_dbo.Dim_Customer | IsIDProof | ISNULL passthrough from snapshot | Tier 2 |
| 38 | IsAddressProof | DWH_dbo.Dim_Customer | IsAddressProof | ISNULL passthrough from snapshot | Tier 2 |
| 39 | IsPhoneVerified | DWH_dbo.Dim_Customer | IsPhoneVerified | Passthrough from snapshot | Tier 2 |
| 40 | IsValidETM | eMoney_dbo.eMoney_Dim_Account | IsValidETM | Passthrough from snapshot | Tier 2 |
| 41 | eTM_CurrencyBalanceID | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceID | Passthrough from snapshot | Tier 2 |
| 42 | eTM_CurrencyBalanceCreateDate | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceCreateDate | Passthrough from snapshot | Tier 2 |
| 43 | eTM_CurrencyBalanceStatus | eMoney_dbo.eMoney_Dim_Account | CurrencyBalanceStatus | Passthrough from snapshot | Tier 2 |
| 44 | eTM_AccountID | eMoney_dbo.eMoney_Dim_Account | AccountID | Passthrough from snapshot | Tier 2 |
| 45 | eTM_AccountCreateDate | eMoney_dbo.eMoney_Dim_Account | AccountCreateDate | Passthrough from snapshot | Tier 2 |
| 46 | eTM_AccountStatus | eMoney_dbo.eMoney_Dim_Account | AccountStatus | Passthrough from snapshot | Tier 2 |
| 47 | eTM_AccountProgram | eMoney_dbo.eMoney_Dim_Account | AccountProgram | Passthrough from snapshot | Tier 2 |
| 48 | eTM_AccountSubProgram | eMoney_dbo.eMoney_Dim_Account | AccountSubProgram | Passthrough from snapshot | Tier 2 |
| 49 | eTM_HasCard | eMoney_dbo.eMoney_Dim_Account | HasCard | Passthrough from snapshot | Tier 2 |
| 50 | eTM_CardStatus | eMoney_dbo.eMoney_Dim_Account | CardStatus | Passthrough from snapshot | Tier 2 |
| 51 | eTM_ProviderHolderID | eMoney_dbo.eMoney_Dim_Account | ProviderHolderID | Passthrough from snapshot | Tier 2 |
| 52 | eTM_FMI_Date | eMoney_dbo.eMoney_Panel_FirstDates | FMI_Date | Passthrough from snapshot | Tier 2 |
| 53 | eTM_FMI_Source | eMoney_dbo.eMoney_Panel_FirstDates | FMI_Source | Passthrough from snapshot | Tier 2 |
| 54 | eTM_FMO_Date | eMoney_dbo.eMoney_Panel_FirstDates | FMO_Date | Passthrough from snapshot | Tier 2 |
| 55 | eTM_FMO_Target | eMoney_dbo.eMoney_Panel_FirstDates | FMO_Target | Passthrough from snapshot | Tier 2 |
| 56 | P1_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 57 | P1_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 58 | P2_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 59 | P2_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 60 | P3_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 61 | P3_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 62 | P4_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 63 | P4_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 64 | P5_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 65 | P5_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 66 | P6_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 67 | P6_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 68 | P7_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 69 | P7_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 70 | P8_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 71 | P8_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 72 | P9_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 73 | P9_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 74 | P10_Response | ETL-hardcoded NULL | — | Always NULL (cancelled); passthrough from snapshot | Tier 2 |
| 75 | P10_Risk | ETL-hardcoded NULL | — | Always NULL (cancelled); passthrough from snapshot | Tier 2 |
| 76 | P11_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 77 | P11_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 78 | P12_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 79 | P12_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 80 | P13_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 81 | P13_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 82 | P14_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 83 | P14_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 84 | P15_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 85 | P15_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 86 | P16_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 87 | P16_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 88 | P17_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 89 | P17_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 90 | P18_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 91 | P18_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 92 | P19_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 93 | P19_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 94 | P20_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 95 | P20_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 96 | P21_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 97 | P21_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 98 | P22_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 99 | P22_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 100 | P23_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 101 | P23_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 102 | P24_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 103 | P24_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 104 | P25_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 105 | P25_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 106 | P26_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 107 | P26_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 108 | P27_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 109 | P27_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 110 | P28_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 111 | P28_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 112 | P29_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 113 | P29_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 114 | P30_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 115 | P30_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 116 | P31_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 117 | P31_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 118 | P32_Response | Fivetran risk classification table | ResponseDescription | Passthrough from snapshot | Tier 2 |
| 119 | P32_Risk | Fivetran risk classification table | RiskText | Passthrough from snapshot | Tier 2 |
| 120 | UpdateDate | ETL-computed | — | GETDATE() at INSERT time (Step 32 INSERT) | Tier 2 |

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 5 | CID, GCID, VerificationLevelID, DateOfBirth, DateOfReg |
| Tier 2 | 115 | All remaining columns (passthrough from snapshot or ETL-computed) |

---

## Key Lineage Notes

- **Append-only table**: Step 32 INSERTs (never TRUNCATE or DELETE). Rows accumulate indefinitely.
- **Class-change-only trigger**: History receives a new row only when `trg.CID IS NULL OR src.ClientRisk <> trg.ClientRisk` (reverted 2025-03-12 from score-change trigger; original class-change policy reinstated).
- **Immediate source is the snapshot**: Step 31 writes the full rebuild to eMoney_Customer_Risk_Assessment; Step 32 reads that same-session data and conditionally inserts to History. All column values in History reflect the state AT THE TIME OF THE CLASS CHANGE EVENT.
- **Self-referential read**: Step 27 reads this History table to find PreviousClientRisk before computing the current snapshot. History feeds the snapshot, and the snapshot writes back to History.
- **P10 always NULL**: Same as snapshot — P10_Response and P10_Risk are hardcoded NULL/0 in the SP.
- **UpdateDate semantics**: Same as snapshot — reflects ETL run time, not business date.
