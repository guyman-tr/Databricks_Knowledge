# BI_DB_dbo.BI_DB_AML_Periodic_Review_HR

> Daily full-refresh AML periodic review table (103K rows) restricted to **High-Risk** eToro customers with first deposit older than 1 year — enriched with the same KYC, screening, and SOF fields as the AR base table, plus a `Final_Decision` traffic-light classification (Red/Orange/Green) indicating the AML review priority for each customer.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Column Count** | 46 |
| **Row Count** | 103,004 (as of 2026-04-12) |
| **Grain** | One row per CID — High-risk depositing VL3 customers, FTD > 1 year ago |
| **Refresh** | Daily (OpsDB Priority 0 — base layer) |
| **Writer SP** | `BI_DB_dbo.SP_AML_Periodic_Review @Date [DATE]` |
| **ETL Pattern** | TRUNCATE + INSERT (full refresh) |
| **PII Columns** | CID, GCID, Age |
| **UC Target** | Not Migrated |

---

## 1. Business Meaning

`BI_DB_AML_Periodic_Review_HR` is the **High Risk** (HR) output of the AML Periodic Review SP. It is a filtered, decisioned subset of the AR base table, restricted to customers who are:

1. Scored as **RiskScoreName = 'High'** by the AML risk classification engine
2. In **PlayerStatus 'Normal' or 'Warning'** (not blocked or deleted)
3. Had their **first deposit more than 1 year ago** (long-tenure accounts — recently joined high-risk customers are not yet in scope)

The HR table adds `Final_Decision` — a traffic-light AML review outcome that prioritises which High-Risk customers need immediate action. This is the primary input for AML analysts performing periodic reviews of the high-risk customer population.

### Relationship to companion tables

| Table | Population | Has Final_Decision |
|-------|-----------|-------------------|
| `BI_DB_AML_Periodic_Review_AR` | ALL depositing VL3 (no risk filter, ~4.65M) | No |
| `BI_DB_AML_Periodic_Review_HR` | High Risk, FTD > 1 year ago (~103K) | Yes |
| `BI_DB_AML_Periodic_Review_MR` | High Risk, FTD > 3 years ago (subset of HR) | Yes |

All three are produced by `SP_AML_Periodic_Review` in a single run from shared temp tables.

---

## 2. Business Logic

### 2.1 Population Filter (HR-specific)

**What**: High-risk long-tenure depositing customers under active accounts.

**Rules** (applied on top of AR base population):
- `RiskScoreName = 'High'` — only High-scored customers from the AML risk engine
- `PlayerStatus IN ('Normal', 'Warning')` — active accounts only; blocked/deleted excluded
- `Original_FTD <= DATEADD(YEAR, -1, @Date)` — FTD must be at least 1 year before the SP run date

**Result**: 103,004 customers as of 2026-04-12. FTD range: 2008-05-12 to 2025-04-11.

**PlayerStatus distribution**: Normal 99.5% (102,497), Warning 0.5% (507).

**Regulation distribution**: CySEC 29.7% (30,571), FSA Seychelles 22.1% (22,773), FCA 21.2% (21,865), FinCEN+FINRA 17.4% (17,974), FinCEN 7.5% (7,765), FSRA 1.4% (1,390), ASIC & GAML 0.5% (552), ASIC 0.1% (114).

### 2.2 Final_Decision — Traffic Light Classification

**What**: AML review priority outcome for each High-Risk customer, determining urgency of action.

**Logic** (priority order — first matching condition wins):

```
CASE
  WHEN Is_POI_ExpiryDate = 1 OR Is_POA_ExpiryDate = 1          → 'Orange'
  WHEN IsHighRisk_Screening = 1
    OR (Is_High_Risk_SOF = 1 AND Has_Proof_Of_Income_FromLastYear = 0)
    OR Is_High_MOP_Deposit = 1                                  → 'Red'
  ELSE                                                          → 'Green'
END
```

**Orange** (43.1%, 44,430) — customer has expired identity or address documents. Requires document renewal before deeper AML assessment. Orange takes priority over Red — a customer with expired documents AND a sanctions hit will be Orange, not Red.

**Green** (43.3%, 44,654) — no document expiry and no active risk triggers. High-risk by overall score but no immediate action flags. Periodic review is still required (quarterly/annual cadence) but no escalation.

**Red** (13.5%, 13,920) — active risk signal requiring investigation:
- `IsHighRisk_Screening = 1`: sanctions, PEP, or risk match from screening provider
- `Is_High_Risk_SOF = 1 AND Has_Proof_Of_Income_FromLastYear = 0`: high-risk SOF declaration without recent income proof on file
- `Is_High_MOP_Deposit = 1`: deposit via high-risk payment method

**Important**: `Is_High_Risk_SOF = 1` alone does NOT guarantee Red — if `Has_Proof_Of_Income_FromLastYear = 1`, the customer receives Green (income proof mitigates the SOF risk). Confirmed in data: 461 rows with Is_High_Risk_SOF=1, no expiry/screening/MOP → Green.

### 2.3 Shared Business Logic

All 44 non-Final_Decision columns share the same source logic as `BI_DB_AML_Periodic_Review_AR`. See AR wiki for:
- Age Group classification (§2.2)
- AML Country Risk / CountryRank (§2.3)
- Enhanced Verification status (§2.4)
- Sanctions & PEP Screening (§2.5)
- SOF Risk Indicators (§2.6)
- Identity Document Expiry Flags (§2.7)
- Occupation Risk Flag (§2.8)
- High-Risk Payment Method Flag (§2.9)
- Identity Verification (§2.10)

---

## 3. Query Advisory

### 3.1 Filter by Final_Decision first

For Red-priority review queue:
```sql
WHERE Final_Decision = 'Red'                            -- 13,920 rows
ORDER BY IsHighRisk_Screening DESC, Is_High_Risk_SOF DESC
```

For expired-document remediation (Orange):
```sql
WHERE Final_Decision = 'Orange'                         -- 44,430 rows
ORDER BY Is_POI_ExpiryDate DESC, Is_POA_ExpiryDate DESC
```

### 3.2 All rows are High-risk

This table contains only `RiskScoreName = 'High'` customers — no need to filter on RiskScoreName.

### 3.3 FTD window — customers who joined > 1 year ago only

Newest FTD is 2025-04-11 (approximately 1 year before the SP run date). No customers who first deposited within the last year appear in this table.

### 3.4 ROUND_ROBIN HEAP — full scan

No hash distribution key. At 103K rows, full scans are fast but avoid cross-joins with large tables.

### 3.5 ReasonType spelling errors

Same as AR — see AR wiki §3.3.

---

## 4. Elements

### Confidence Tier Legend

Same as `BI_DB_AML_Periodic_Review_AR`. All columns 1–43 and 45–46 are identical in source and tier.

| # | Column | Type | Tier | Source | Description |
|---|--------|------|------|--------|-------------|
| 1 | CID | int | T1 | `DWH_dbo.Dim_Customer.RealCID` | Customer ID — platform-internal primary key. Assigned at registration. Universal customer identifier across all DWH tables. (Tier 1 — DWH_dbo.Dim_Customer.RealCID) |
| 2 | GCID | int | T1 | `DWH_dbo.Dim_Customer.GCID` | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — DWH_dbo.Dim_Customer.GCID) |
| 3 | Age | int | T2 | `SP_AML_Periodic_Review, Dim_Customer.BirthDate` | Customer age in years as of SP run date. `DATEDIFF(YEAR, BirthDate, GETDATE())`. May be off by 1 year for customers whose birthday has not yet occurred in the current year. (Tier 2 — SP_AML_Periodic_Review, Dim_Customer.BirthDate) |
| 4 | Age_Group | varchar(250) | T2 | `SP_AML_Periodic_Review CASE on Age` | AML age-band classification: '18-21 Age' (1,902, 1.8%), 'Over 75' (779, 0.8%), 'No Risk Age' (100,323, 97.4%). (Tier 2 — SP_AML_Periodic_Review CASE on Age) |
| 5 | Original_FTD | datetime | T1 | `DWH_dbo.Dim_Customer.FirstDepositDate` | Date of customer's first deposit. Range: 2008-05-12 to 2025-04-11 — all FTDs are older than 1 year (population gate). (Tier 1 — DWH_dbo.Dim_Customer.FirstDepositDate) |
| 6 | Regulation | nvarchar(8000) | T1 | `DWH_dbo.Dim_Regulation.Name` | Short code for the regulatory jurisdiction. CySEC (29.7%), FSA Seychelles (22.1%), FCA (21.2%), FinCEN+FINRA (17.4%), FinCEN (7.5%), others. (Tier 1 — DWH_dbo.Dim_Regulation.Name) |
| 7 | Country | varchar(250) | T1 | `DWH_dbo.Dim_Country.Name` | Full country name in English for the customer's country of residence. (Tier 1 — DWH_dbo.Dim_Country.Name) |
| 8 | POB_Country | varchar(250) | T2 | `DWH_dbo.Dim_Customer.CountryOfBirth (resolved)` | Country of birth (resolved to country name). Empty string for many legacy accounts where birth country was not captured. (Tier 2 — DWH_dbo.Dim_Customer, birth country resolved) |
| 9 | aml_compliance_POB | nvarchar(8000) | T3 | `External_Fivetran_google_sheets_grc_list` | AML compliance classification for the customer's birth country from the GRC Google Sheet. NULL or empty when POB_Country is not in the GRC list. (Tier 3 — External_Fivetran_google_sheets_grc_list via POB_Country) |
| 10 | CountryRank | int | T3 | `External_Fivetran_google_sheets_grc_list` | AML risk tier of the customer's country of residence from the GRC list. 0=no tier assigned (majority), 1=highest-risk jurisdictions, 2–4=intermediate risk tiers. (Tier 3 — External_Fivetran_google_sheets_grc_list) |
| 11 | aml_compliance | varchar(250) | T3 | `External_Fivetran_google_sheets_grc_list` | AML compliance status label for the customer's country of residence from the GRC Google Sheet. NULL when country is not in the GRC list. Examples: 'AML', 'COMPLIANCE'. (Tier 3 — External_Fivetran_google_sheets_grc_list via Country) |
| 12 | PlayerStatus | varchar(250) | T1 | `DWH_dbo.Dim_PlayerStatus.Name` | Account restriction state. HR population is restricted to 'Normal' (99.5%) and 'Warning' (0.5%) only — all other statuses are excluded by the population gate. (Tier 1 — DWH_dbo.Dim_PlayerStatus.Name) |
| 13 | Club | varchar(250) | T1 | `DWH_dbo.Dim_PlayerLevel.Name` | Customer experience tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. (Tier 1 — DWH_dbo.Dim_PlayerLevel.Name) |
| 14 | EvMatchStatusName | nvarchar(8000) | T3 | `External_UserApiDB_Ev_CustomerResult` | Enhanced Verification match status name from the latest EV event per GCID. 'None' if no EV performed. Examples: 'Verified', 'NotVerified'. (Tier 3 — External_UserApiDB_Ev_CustomerResult) |
| 15 | EvStatusId | int | T3 | `External_UserApiDB_Ev_CustomerResult` | Numeric status code for the latest EV result per GCID. NULL if no EV performed. (Tier 3 — External_UserApiDB_Ev_CustomerResult) |
| 16 | EV_Date | datetime | T3 | `External_UserApiDB_Ev_CustomerResult.OccurredAt` | Timestamp of the most recent Enhanced Verification event per GCID. NULL if no EV performed. (Tier 3 — External_UserApiDB_Ev_CustomerResult.OccurredAt) |
| 17 | ScreeningStatus | nvarchar(8000) | T3 | `External_RiskClassification_dbo_V_RiskClassificationDataLake` | Sanctions and PEP screening result. NoMatch (majority), PendingInvestigation, PEP, RiskMatch, SanctionsMatch. (Tier 3 — External_RiskClassification_dbo_V_RiskClassificationDataLake) |
| 18 | RiskScoreName | nvarchar(8000) | T3 | `External_RiskClassification_dbo_V_RiskClassificationDataLake` | AML risk score band. **All rows = 'High'** — this is a population gate for this table. (Tier 3 — External_RiskClassification_dbo_V_RiskClassificationDataLake) |
| 19 | RiskScore_Explanation | nvarchar(8000) | T3 | `External_RiskClassification_dbo_V_RiskClassificationDataLake` | Comma-separated list of risk factors contributing to the High risk score. Examples: 'Occupation,Annual Income,Total Cash And Liquid Assets', 'Country of Residence, Onboarding,NFTF'. (Tier 3 — External_RiskClassification_dbo_V_RiskClassificationDataLake) |
| 20 | HasWallet | int | T2 | `DWH_dbo.Dim_Customer.HasWallet` | 1 if customer has an active eToroMoney wallet; 0 otherwise. (Tier 2 — DWH_dbo.Dim_Customer.HasWallet) |
| 21 | AccountProgram | nvarchar(500) | T2 | `DWH_dbo.Dim_Customer.AccountProgram` | Payment account program type: NULL=standard account, 'iban'=bank-account-linked, 'card'=card-linked. (Tier 2 — DWH_dbo.Dim_Customer.AccountProgram) |
| 22 | IsHighRisk_Screening | int | T2 | `SP_AML_Periodic_Review, External_RiskClassification` | 1 when ScreeningStatus is not 'NoMatch' or 'Unknown'. One of three Red triggers in Final_Decision. (Tier 2 — SP_AML_Periodic_Review derived from ScreeningStatus) |
| 23 | IsEDD | int | T2 | `DWH_dbo.Dim_Customer.IsEDD` | 1 if the customer is subject to Enhanced Due Diligence. (Tier 2 — DWH_dbo.Dim_Customer.IsEDD) |
| 24 | POI_ExpiryDate | datetime | T2 | `DWH_dbo.Dim_Customer.IsIDProofExpiryDate` | Expiry datetime of the customer's Proof of Identity document. NULL if no POI document or expiry date not set. (Tier 2 — DWH_dbo.Dim_Customer.IsIDProofExpiryDate) |
| 25 | POA_ExpiryDate | datetime | T2 | `DWH_dbo.Dim_Customer.IsAddressProofExpiryDate` | Expiry datetime of the customer's Proof of Address document. NULL if no POA document or expiry date not set. (Tier 2 — DWH_dbo.Dim_Customer.IsAddressProofExpiryDate) |
| 26 | Is_POI_ExpiryDate | int | T2 | `SP_AML_Periodic_Review derived from POI_ExpiryDate` | 1 if POI document is expired. **Orange trigger** in Final_Decision — takes priority over Red signals. (Tier 2 — SP_AML_Periodic_Review derived from POI_ExpiryDate) |
| 27 | Is_POA_ExpiryDate | int | T2 | `SP_AML_Periodic_Review derived from POA_ExpiryDate` | 1 if POA document is expired. **Orange trigger** in Final_Decision — takes priority over Red signals. (Tier 2 — SP_AML_Periodic_Review derived from POA_ExpiryDate) |
| 28 | Is_High_Risk_SOF | int | T2 | `SP_AML_Periodic_Review, BI_DB_dbo.BI_DB_KYC_Panel.Q26_AnswerText` | 1 if Q26 answer includes 'Family financial support' or 'Social Security'. Contributes to Red when combined with Has_Proof_Of_Income_FromLastYear=0. (Tier 2 — SP_AML_Periodic_Review derived from BI_DB_dbo.BI_DB_KYC_Panel.Q26_AnswerText) |
| 29 | SOF_Q26_Answer | nvarchar(8000) | T1 | `BI_DB_dbo.BI_DB_KYC_Panel.Q26_AnswerText` | STRING_AGG of all selected Q26 fund source answer texts. NULL if customer has not answered Q26. (Tier 1 — BI_DB_dbo.BI_DB_KYC_Panel.Q26_AnswerText) |
| 30 | Is_High_MOP_Deposit | int | T2 | `SP_AML_Periodic_Review, Fact_CustomerAction.FundingTypeID` | 1 if any deposit after 2023-01-01 used a non-standard payment method. **Red trigger** in Final_Decision. (Tier 2 — SP_AML_Periodic_Review, DWH_dbo.Fact_CustomerAction) |
| 31 | Occupation_Answer | nvarchar(500) | T1 | `BI_DB_dbo.BI_DB_KYC_Panel.Q18_AnswerText` | Customer's Q18 occupation category text. NULL if customer has not answered Q18. (Tier 1 — BI_DB_dbo.BI_DB_KYC_Panel.Q18_AnswerText) |
| 32 | Is_HighRisk_Occupation | int | T2 | `SP_AML_Periodic_Review derived from Occupation_Answer` | 1 if Occupation_Answer IN ('None', 'Gambling Industry', 'Gaming/Casino/Card Club', 'Student'). (Tier 2 — SP_AML_Periodic_Review derived from BI_DB_KYC_Panel.Q18_AnswerText) |
| 33 | ReasonType | nvarchar(8000) | T1 | `BI_DB_dbo.BI_DB_AML_KYC_SOF.ReasonType` | SOF reason category from BI_DB_AML_KYC_SOF. Values contain stored spelling errors — match exactly: 'Normal', 'More then decleared deposit', 'Less then 15% left', 'HNWI'. (Tier 1 — BI_DB_dbo.BI_DB_AML_KYC_SOF.ReasonType) |
| 34 | HasBusinessPotential | int | T1 | `BI_DB_dbo.BI_DB_AML_KYC_SOF.HasBusinessPotential` | 1 if ≥85% of the customer's Q14 planned investment ceiling has not yet been deposited. (Tier 1 — BI_DB_dbo.BI_DB_AML_KYC_SOF.HasBusinessPotential) |
| 35 | HasSOFLast6Months | int | T1 | `BI_DB_dbo.BI_DB_AML_KYC_SOF.HasSOFLast6Months` | 1 if a qualifying Proof of Income document was submitted within the last 6 months. (Tier 1 — BI_DB_dbo.BI_DB_AML_KYC_SOF.HasSOFLast6Months) |
| 36 | Is_SOF_needed | int | T2 | `SP_AML_Periodic_Review derived from BI_DB_AML_KYC_SOF.SOF_Predication` | 1 when SOF_Predication != 'Do not check SOF'. (Tier 2 — SP_AML_Periodic_Review derived from BI_DB_dbo.BI_DB_AML_KYC_SOF.SOF_Predication) |
| 37 | Planned_Invested_Amount_Q14 | nvarchar(8000) | T1 | `BI_DB_dbo.BI_DB_KYC_Panel.Q14_AnswerText` | Customer's Q14 planned annual investment amount bracket answer text. (Tier 1 — BI_DB_dbo.BI_DB_KYC_Panel.Q14_AnswerText) |
| 38 | Total_Withdraw | money | T2 | `SP_AML_Periodic_Review, DWH_dbo.Fact_CustomerAction ActionTypeID=8` | All-time total cashout amount in USD (WITH NOLOCK). (Tier 2 — SP_AML_Periodic_Review, DWH_dbo.Fact_CustomerAction) |
| 39 | Login_Rank1_2023 | int | T2 | `SP_AML_Periodic_Review, Fact_CustomerAction login events` | Count of login events from Rank-1 AML countries after 2023-01-01. (Tier 2 — SP_AML_Periodic_Review, DWH_dbo.Fact_CustomerAction login) |
| 40 | Has_Open_AML_SF_Case | int | T2 | `SP_AML_Periodic_Review, BI_DB_dbo.BI_DB_SF_Cases_Panel` | 1 if customer has an open AML-type Salesforce case. (Tier 2 — SP_AML_Periodic_Review, BI_DB_dbo.BI_DB_SF_Cases_Panel) |
| 41 | Has_Proof_Of_Income | int | T3 | `External_etoro_BackOffice_CustomerDocument` | 1 if a 'Proof of Income' document is on file in BackOffice. (Tier 3 — External_etoro_BackOffice_CustomerDocument) |
| 42 | Has_Selfie | int | T3 | `External_etoro_BackOffice_CustomerDocument` | 1 if an approved selfie or liveness check document is on file in BackOffice. (Tier 3 — External_etoro_BackOffice_CustomerDocument) |
| 43 | Has_Passed_VI_or_BI | int | T3 | `SolarisBankIdentDb / VideoIdentDb` | 1 if customer passed bank identification (GlobalStatus='successful') OR video identification (Status='Success'). (Tier 3 — SolarisBankIdentDb / VideoIdentDb) |
| 44 | Final_Decision | nvarchar(8000) | T2 | `SP_AML_Periodic_Review CASE on risk flags` | AML periodic review traffic-light outcome. Values: 'Green' (43.3%, no flags), 'Orange' (43.1%, expired documents — higher priority than Red), 'Red' (13.5%, active risk signal). Orange takes precedence over Red. (Tier 2 — SP_AML_Periodic_Review CASE on Is_POI_ExpiryDate, Is_POA_ExpiryDate, IsHighRisk_Screening, Is_High_Risk_SOF, Has_Proof_Of_Income_FromLastYear, Is_High_MOP_Deposit) |
| 45 | UpdateDate | datetime | Propagation | ETL metadata | SP execution timestamp: `GETDATE()` at INSERT time. All rows share the same value per daily run. (Propagation) |
| 46 | Has_Proof_Of_Income_FromLastYear | int | T3 | `External_etoro_BackOffice_CustomerDocument` | 1 if a qualifying Proof of Income document was submitted within the last calendar year. **SOF Red mitigator** — when Is_High_Risk_SOF=1 but this=1, customer is Green not Red. (Tier 3 — External_etoro_BackOffice_CustomerDocument) |

**Tier summary**: 9 T1 | 22 T2 | 13 T3 | 1 Propagation (identical to AR plus 1 additional T2 for Final_Decision = 10 T1 | 23 T2 | 13 T3 | 1 Propagation total)

Wait — corrected: Final_Decision is a new T2 column unique to HR.  
**Final tier summary**: 9 T1 | 23 T2 | 13 T3 | 1 Propagation

---

## 5. Data Shape and Distributions

| Metric | Value |
|--------|-------|
| Total rows | 103,004 (2026-04-12) |
| Distinct customers | 103,004 (one row per CID) |
| RiskScoreName | 'High' (100% — population gate) |
| UpdateDate | 2026-04-12 05:56:27 |
| FTD range | 2008-05-12 to 2025-04-11 |

### Final_Decision

| Value | Count | % | Meaning |
|-------|-------|---|---------|
| Green | 44,654 | 43.3% | No active flags |
| Orange | 44,430 | 43.1% | Expired documents |
| Red | 13,920 | 13.5% | Active risk signal |

### Regulation

| Regulation | Count | % |
|-----------|-------|---|
| CySEC | 30,571 | 29.7% |
| FSA Seychelles | 22,773 | 22.1% |
| FCA | 21,865 | 21.2% |
| FinCEN+FINRA | 17,974 | 17.4% |
| FinCEN | 7,765 | 7.5% |
| FSRA | 1,390 | 1.4% |
| ASIC & GAML | 552 | 0.5% |
| ASIC | 114 | 0.1% |

### Final_Decision signal breakdown (top combinations)

| Is_POI_Expiry | Is_POA_Expiry | Screening | SOF | MOP | Decision | Count |
|---|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 | Green | 44,193 |
| 0 | 1 | 0 | 0 | 0 | Orange | 22,290 |
| 0 | 0 | 0 | 1 | 0 | Red | 12,238 |
| 1 | 1 | 0 | 0 | 0 | Orange | 11,237 |
| 0 | 1 | 0 | 1 | 0 | Orange | 4,815 |
| 0 | 0 | 0 | 0 | 1 | Red | 834 |
| 1 | 0 | 0 | 0 | 0 | Orange | 1,978 |
| 0 | 0 | 1 | 0 | 0 | Red | 652 |
| 0 | 0 | 0 | 1 | 0 | Green | 461 |

*Note the last row (461): Is_High_Risk_SOF=1 with no expiry/screening/MOP → Green. These customers have Has_Proof_Of_Income_FromLastYear=1, which mitigates the SOF risk.*

### Age Group

| Age_Group | Count | % |
|-----------|-------|---|
| No Risk Age | 100,323 | 97.4% |
| 18-21 Age | 1,902 | 1.8% |
| Over 75 | 779 | 0.8% |
