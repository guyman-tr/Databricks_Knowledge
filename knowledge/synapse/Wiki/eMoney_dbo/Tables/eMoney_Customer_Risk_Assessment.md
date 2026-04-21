# eMoney_dbo.eMoney_Customer_Risk_Assessment

> Daily per-customer AML/KYC risk snapshot for the eToro Money programme: 2,031,882 rows (one per active eTM customer), each holding a weighted risk score across 32 configurable parameters, a Low/Medium/High/Error classification, and the full set of raw attributes used to derive it; populated daily via TRUNCATE + INSERT by SP_eMoney_Customer_Risk_Assessment.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Daily Snapshot) |
| **Production Sources** | DWH_dbo.Dim_Customer; eMoney_dbo.eMoney_Dim_Account; Fivetran classification/override tables; BI_DB_dbo KYC/BackOffice externals |
| **Refresh** | Daily TRUNCATE + INSERT (Step 30-31 of SP_eMoney_Customer_Risk_Assessment; @Date = today) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **Row Count** | 2,031,882 (sampled 2026-04-12) |
| **Date Range** | ClientRiskDate: 2024-07-17 → 2026-04-12 |
| **Writer SP** | SP_eMoney_Customer_Risk_Assessment (1,729 lines; 32 steps) |
| **UC Target** | `emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment` |

---

## 1. Business Meaning

`eMoney_Customer_Risk_Assessment` is the central AML/KYC risk output table for the eToro Money (eTM) fiat banking programme. Each row represents the **current risk profile of one eTM customer**, evaluated across 32 weighted parameters spanning identity, KYC declarations, country risk, transaction behaviour, and document verification.

The risk engine works as follows:

1. **Population**: All customers with an active eTM account (seeded from `eMoney_Dim_Account`).
2. **Data assembly**: 26 steps compile customer identity, KYC Q&A, TIN registration, BackOffice documents, IBAN money flows, TP deposits/cashouts, VPN usage, and country risk flags.
3. **Scoring**: Each of 32 parameters is matched against a Fivetran-synced classification table (`emoney_customer_risk_assessment_classification_table`) that maps response values to a RiskID and Weight. `Risk_Final_Result = SUM(P{n}_RiskID × P{n}_Weight)` for all 32 parameters.
4. **Classification**: The score is compared against two dynamic thresholds (`@RiskLowerCut`, `@RiskUpperCut`) read from ParameterID=98/99 in the same classification table. Below lower cut = Low; between = Medium; at/above upper cut = High; unresolvable = Error.
5. **Override logic**: PEP-flagged customers are forced to High; a manual override Google Sheet can set any CID to a specific risk class.
6. **History**: A class-change event (ClientRisk different from the last history row) triggers an INSERT into `eMoney_Customer_Risk_Assessment_History`. Both tables share identical DDL.

**Key operating characteristics**:
- **P10 is permanently cancelled**: KYC Q46 (Citizenship By Investment Program) was cancelled; `P10_Response` and `P10_Risk` are always NULL and `P10_RiskID=0, P10_Weight=0`.
- **Thresholds are dynamic**: `@RiskLowerCut` and `@RiskUpperCut` are not hardcoded — they read from the Fivetran classification table ParameterID 98/99 on each SP run. Changing the sheet changes the thresholds overnight.
- **99999 sentinel**: Used throughout for "unknown/not applicable" (e.g., age >120, missing TIN, no country registered). The classification table has explicit entries for ResponseID=99999.
- **TRUNCATE + INSERT pattern**: The snapshot is fully rebuilt daily (changed from DELETE FROM on 2024-07-22 by EitanLi for performance).
- **History insert is class-change-only**: Reverted to `WHERE trg.CID IS NULL OR src.ClientRisk <> trg.ClientRisk` on 2025-03-12 (Ofir Ovadia). A brief period from 2025-02-25 used score-change trigger — those rows exist in History but represent a different threshold.

**Observed distributions** (2026-04-12):
- ClientRisk: Low 76.3%, Medium 21.8%, High 1.7%, Error 0.1%
- PEP Overrides: ~201 rows; Manual Overrides: ~1 row
- IsValidETM: 1=79.0%, NULL=20.9%, 0=0.1%
- Regulation: CySEC 62.8%, FCA 28.5%, BVI 6.6%, ASIC+GAML 1.9%
- Top eTM programs: iban/IBAN EU Green=1,032,758; iban/IBAN Standard UK=445,810; NULL=424,582

---

## 2. Business Logic

### 2.1 Risk Score Formula

**What**: A single weighted score summarising the customer's risk level across all 32 parameters.

**Column**: `Risk_Final_Result` (float)

**Formula**:
```
Risk_Final_Result = 
  (P1_RiskID × P1_Weight) + (P2_RiskID × P2_Weight) + … + (P32_RiskID × P32_Weight)
```
- RiskID and Weight are looked up from `#risk_classification_table` by matching `ParameterID` and `ResponseID`
- P10 always contributes 0 (RiskID=0, Weight=0 — permanently cancelled)
- Missing/unresolvable parameters use ResponseID=99999 (sentinel row in classification table)

### 2.2 Classification Thresholds

**What**: The Low/Medium/High boundary is dynamic, controlled via the classification table.

**Columns**: `ClientRisk`, `@RiskLowerCut` (ParameterID=98), `@RiskUpperCut` (ParameterID=99)

**Rules**:
- `ClientRisk = 'Low'` when `Risk_Final_Result ≤ @RiskLowerCut`
- `ClientRisk = 'Medium'` when `Risk_Final_Result > @RiskLowerCut AND ≤ @RiskUpperCut`
- `ClientRisk = 'High'` when `Risk_Final_Result ≥ @RiskUpperCut`
- `ClientRisk = 'Error'` in all other cases (NULL scores, unmatched logic)
- ParameterWeight for ParameterID 98/99 is multiplied by 100 to produce the threshold value

### 2.3 Override Hierarchy

**What**: Two override mechanisms can supersede the algorithm-derived risk class.

**Columns**: `ClientRisk`, `ClientRiskAssignmentType`, `ClientRiskDate`

**Rules** (applied in order — later overrides win):
1. **Regular** (default): algorithm output; `ClientRiskAssignmentType = 'Regular'`
2. **Manual Override** (applied first): CID-level overrides from `eMoney_Customer_Risk_Assessment_Manual_Override_Table` (Google Sheets); `ClientRiskAssignmentType = 'Manual Override'`
3. **PEP Override** (applied last, always wins): any customer with `ScreeningStatus = 'PEP'` is forced to `ClientRisk = 'High'`; `ClientRiskAssignmentType = 'PEP Override'`; `ClientRiskDate = ISNULL(last history date, @Date)`

### 2.4 ClientRiskDate Semantics

**What**: The date the current risk class was first assigned — preserved across daily runs while the class is unchanged.

**Column**: `ClientRiskDate` (date)

**Rules**:
- If today's `ClientRisk` equals the previous history row's `ClientRisk` → `ClientRiskDate = hst.ClientRiskDate` (preserved)
- If today's `ClientRisk` differs (or no history exists) → `ClientRiskDate = @Date` (today)
- PEP Override: `ClientRiskDate = ISNULL(hst.ClientRiskDate, @Date)`
- Manual Override: `ClientRiskDate = ExecutedDate` from the override sheet

### 2.5 32-Parameter Structure

**What**: Each of the 32 parameters maps a business concept to a response ID, which is then looked up in the classification table to get a risk tier label and numeric weight.

| Group | Parameters | Topic |
|-------|-----------|-------|
| Customer Info | P1, P2, P3, P4, P11, P28, P29 | Age, address/citizenship/POB/TIN country HRC flags, business duration, country match flags |
| KYC Declarations | P5, P6, P7, P8, P9, P10, P30 | Annual income, total assets, planned investment, source of income, occupation, [P10=cancelled], source of funds |
| Documents | P12, P13 | Source of income document provided, selfie provided |
| BackOffice | P14, P15, P18, P19 | Screening status, EV status, proof of identity, proof of address |
| TIN | P16, P17 | TIN country HRC, TIN country = address country |
| IBAN MIMO | P20, P21, P22, P23, P24, P25, P26, P32 | IBAN load/unload country diversity and HRC, high net worth, total IBAN money in |
| TP MIMO | P31 | Total ecosystem money vs declared income |
| Behavioural | P27 | VPN/TOR usage ratio |

**Response ID sentinel**: 99999 is used when a parameter cannot be evaluated (missing country, no TIN, no IBAN transactions, no KYC answer). The classification table contains explicit risk entries for 99999.

### 2.6 Country High-Risk Flag (_IsHRC Columns)

**What**: Binary flag (0=safe, 1=high-risk, 99999=unknown) for each country dimension.

**Columns**: `CountryAddress_IsHRC`, `CountryCitizenship_IsHRC`, `CountryPOB_IsHRC`, `CountryTIN_IsHRC`

**Rules**:
- Source: `BI_DB_dbo.External_Fivetran_google_sheet_cracountryriskmapping` (IsHighRiskCountry per eToroDWHCountryID)
- 0 = not high risk; 1 = high risk; 99999 = no entry in the mapping table (country not classified)
- These values feed directly into ParameterID 2, 3, 4, 16 as ResponseIDs

### 2.7 IBAN MIMO Parameter Logic

**What**: IBAN money-in/out transactions (TxTypeID=5=card_load, 7=IBAN_load, 8=IBAN_unload) are analysed for country diversity, country risk, and volume.

**Parameters**: P20 (load countries), P21 (load country=KYC), P22 (load HRC), P23 (unload countries), P24 (unload country=KYC), P25 (unload HRC), P26 (high net worth >500K), P32 (total IBAN in volume)

**Response ID encoding** (P20/P23 country count):
- 11 = no IBAN transactions; 22 = 0 countries (data gap); 33 = 1 country; 44 = 2-3 countries; 55 = ≥4 countries; 99999 = error

### 2.8 History Insert Logic

**What**: The History table (`eMoney_Customer_Risk_Assessment_History`) records class-change events only.

**Rule** (Step 32): INSERT when `trg.CID IS NULL` (new customer, no history) OR `src.ClientRisk <> trg.ClientRisk` (class changed from last history row)

**Important**: From 2025-02-25 to 2025-03-12 the trigger used score-change (`Risk_Final_Result <>`) instead of class-change. Rows inserted during this period represent score movements within the same class — they are in History but do not represent actual class transitions.

---

## 3. Query Advisory

### 3.1 Distribution & Index

Distributed on `HASH(CID)`. Most joins to this table are CID-based (to trading-side DWH tables), so data movement is minimised. No clustered index (HEAP) — full scans are common; filter early.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current risk distribution | SELECT ClientRisk, COUNT(*) GROUP BY ClientRisk |
| High-risk customers for review | WHERE ClientRisk='High' AND ClientRiskAssignmentType='Regular' |
| PEP customers | WHERE ClientRiskAssignmentType='PEP Override' |
| Risk class change history | Query eMoney_Customer_Risk_Assessment_History, filter by CID range |
| Risk by regulation | GROUP BY Regulation, ClientRisk |
| CRA attributes for eTM analytics | JOIN eMoney_Dim_Account ON CID (use GCID_Unique_Count=1 in account table) |
| Parameter contribution analysis | Sum P{n}_RiskID × known weight from classification table |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Dim_Account | ON cra.CID = da.CID AND da.GCID_Unique_Count=1 | eTM account details |
| DWH_dbo.Dim_Customer | ON cra.CID = dc.RealCID | Full trading platform profile |
| eMoney_dbo.eMoney_Customer_Risk_Assessment_History | ON cra.CID = h.CID | Risk history per customer |
| DWH_dbo.Dim_Regulation | ON cra.Regulation (text match not recommended — use VerificationLevelID join path) | Regulation name |

### 3.4 Gotchas

- **P10 is always NULL**: Do not use P10_Response or P10_Risk in analysis — they are always NULL by design (Q46 cancelled).
- **99999 sentinel is a valid response value**: NULL means the parameter was fully absent; 99999 means "unknown but classified". These produce different risk scores.
- **Risk_Final_Result reflects overridden label inconsistency**: A PEP-overridden customer retains the algorithm-computed Risk_Final_Result (which may be Low) but has ClientRisk='High'. These disagree by design.
- **ClientRiskDate is not today's date** for stable customers: It reflects when the current class was first assigned. Do not use as a recency filter.
- **UpdateDate = GETDATE()** at SP execution time — not a business date.
- **VerificationLevelID near-100% at level 3**: In the sampled data, virtually all CRA customers are fully verified (VerificationLevelID=3). This is expected — only verified eTM customers are active.
- **History period gap (2025-02-25 → 2025-03-12)**: Score-change rows exist. If comparing history row counts before/after these dates, note the different trigger logic.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (Customer.CustomerStatic or BackOffice.Customer via Dim_Customer.md) |
| Tier 2 | Description written from ETL SP code analysis (SP_eMoney_Customer_Risk_Assessment) |
| Tier 4 | Best available — limited evidence |

### 4.1 Identity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. DWH note: column renamed from RealCID (Dim_Customer) for eMoney context; joins back via CID=RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | NO | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |

### 4.2 Risk Classification Output

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 3 | ClientRiskDate | date | YES | Date the current ClientRisk class was first assigned. Preserved across daily runs while class is unchanged; reset to @Date (today) when class changes. For PEP overrides: ISNULL(last history date, @Date). For manual overrides: ExecutedDate from override sheet. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 4 | ClientRisk | varchar(10) | YES | Customer AML risk classification. Values: Low (score ≤ @RiskLowerCut), Medium (> LowerCut ≤ UpperCut), High (≥ @RiskUpperCut), Error (unresolvable). Thresholds are dynamic (ParameterID=98/99 in Fivetran classification table). Overridden to 'High' for PEP customers; overridden to custom value for manual override CIDs. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 5 | ClientRiskAssignmentType | varchar(50) | YES | Method by which ClientRisk was assigned. Values: 'Regular' (algorithm), 'PEP Override' (ScreeningStatus='PEP'), 'Manual Override' (CID in override Google Sheet). Override types take precedence over Regular in that order. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 6 | Risk_Final_Result | float | YES | Weighted risk score: SUM(P1_RiskID×P1_Weight + P2_RiskID×P2_Weight + … + P32_RiskID×P32_Weight). P10 always contributes 0 (cancelled). Missing parameters contribute 99999-code row from classification table. Used to derive ClientRisk via threshold comparison. NOT modified by override logic — a PEP-forced customer retains the algorithm score. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 7 | PreviousClientRisk | varchar(10) | YES | ClientRisk from the most recent row in eMoney_Customer_Risk_Assessment_History (latest ClientRiskDate DESC). ISNULL→'None' for customers with no history. Used in ClientRiskDate preservation logic and History insert filter. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 8 | PreviousClientRiskDate | date | YES | ClientRiskDate from the most recent row in eMoney_Customer_Risk_Assessment_History. NULL for customers with no history. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.3 Customer Profile

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 9 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. (Tier 1 — BackOffice.Customer) |
| 10 | IsValidCustomer | int | YES | DWH-computed validity flag from Dim_Customer. 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and CountryID≠250. Used for filtering non-standard customer profiles. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 11 | IsDepositor | int | YES | 1 if the customer has made at least one deposit on the eToro trading platform. Sourced from Dim_Customer. Used in certain eTM analytics filters. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 12 | AccountType | varchar(50) | YES | Trading platform account type display name, resolved from DWH_dbo.Dim_AccountType via AccountTypeID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 13 | Regulation | varchar(50) | YES | Regulatory jurisdiction display name, resolved from DWH_dbo.Dim_Regulation via RegulationID. Top values: CySEC, FCA, BVI, ASIC, GAML. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 14 | Club | varchar(50) | YES | eToro Club tier display name, resolved from DWH_dbo.Dim_PlayerLevel via PlayerLevelID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.4 Demographics & Dates

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 15 | ClientAge | int | YES | Customer's age in years at SP execution date, computed as DATEDIFF(YEAR, BirthDate, @Date). Sentinel 99999 used when age > 120, ≤ 0, or BirthDate is NULL. This integer value feeds into P1 classification. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 16 | DateOfBirth | date | YES | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. DWH note: CAST from datetime to date (time component removed); column renamed from BirthDate. (Tier 1 — Customer.CustomerStatic) |
| 17 | DateOfReg | date | YES | Account registration date (renamed from Registered). Default=getdate(). DWH note: CAST from datetime to date; column renamed from RegisteredReal in Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 18 | DateOfFTD | date | YES | Date of first trading platform deposit. CAST(FirstDepositDate AS DATE) from Dim_Customer. Sentinel '19000101' for non-depositors. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 19 | BusinessDuration | int | YES | Bucketed tenure as eToro depositor, based on years since DateOfFTD. Values: 99999 (no FTD or sentinel '19000101'), 1 (<1 year), 2 (1–3 years), 3 (>3 years). Feeds into P11 classification. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.5 Country Attributes

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 20 | CountryAddress | varchar(50) | YES | KYC address country display name, resolved from #dim_country (Dim_Country) via CountryID. Reflects the customer's declared residential country. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 21 | CountryCitizenship | varchar(50) | YES | Citizenship country display name, resolved from #dim_country via CitizenshipCountryID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 22 | CountryPOB | varchar(50) | YES | Place of birth country display name, resolved from #dim_country via POBCountryID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 23 | CountryTIN | varchar(50) | YES | Tax identification number (TIN) country display name. Resolved via a prioritised lookup: address-matching country > HRC country > non-HRC country from BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField (FieldId=6). NULL when no TIN country is registered. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 24 | CountryAddress_IsHRC | int | YES | High-risk country flag for the KYC address country. 0=not high risk, 1=high risk, 99999=not classified in CRA mapping. Sourced from Fivetran country risk map. Feeds into P2 classification. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 25 | CountryCitizenship_IsHRC | int | YES | High-risk country flag for the citizenship country. 0=not high risk, 1=high risk, 99999=not classified. Feeds into P3 classification. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 26 | CountryPOB_IsHRC | int | YES | High-risk country flag for the place of birth country. 0=not high risk, 1=high risk, 99999=not classified. Feeds into P4 classification. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 27 | CountryTIN_IsHRC | int | YES | High-risk country flag for the TIN country. 0=not high risk, 1=high risk, 99999=not classified or no TIN. Feeds into P16 classification. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.6 Account & Player Status

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 28 | AccountStatus | varchar(50) | YES | Trading platform account lifecycle status display name, resolved from DWH_dbo.Dim_AccountStatus via AccountStatusID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 29 | PlayerStatus | varchar(50) | YES | Trading platform compliance status display name, resolved from DWH_dbo.Dim_PlayerStatus via PlayerStatusID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 30 | PlayerStatusReason | varchar(50) | YES | Reason for the PlayerStatus (e.g., account closure reason), resolved from DWH_dbo.Dim_PlayerStatusReasons via PlayerStatusReasonID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 31 | PlayerStatusSubReason | varchar(50) | YES | Sub-reason providing further granularity below PlayerStatusReason, resolved from DWH_dbo.Dim_PlayerStatusSubReasons via PlayerStatusSubReasonID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 32 | ScreeningStatus | varchar(255) | YES | AML/sanctions screening status display name, resolved from DWH_dbo.Dim_ScreeningStatus. Source ID is ISNULL(ScreeningStatusID, 99999) before lookup. 'PEP' value triggers PEP Override logic. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 33 | EVStatus | varchar(30) | YES | Electronic verification (identity check) status display name, resolved from DWH_dbo.Dim_EvMatchStatus. Source ID is ISNULL(EvMatchStatus, 99999) before lookup. Feeds into P15 classification. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 34 | DocumentStatus | varchar(50) | YES | KYC document verification status display name, resolved from DWH_dbo.Dim_DocumentStatus via DocumentStatusID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 35 | PhoneStatus | varchar(50) | YES | Phone verification status display name, resolved from DWH_dbo.Dim_PhoneVerified via PhoneVerifiedID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.7 KYC Document Flags

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 36 | DocsOK | tinyint | YES | Composite flag from Dim_Customer indicating all required KYC documents are accepted. Business definition follows Dim_Customer logic. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 37 | IsIDProof | int | YES | Proof of identity status from Dim_Customer. ISNULL(raw value, 99999). Feeds into P18 classification. 99999=not available/unknown. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 38 | IsAddressProof | int | YES | Proof of address status from Dim_Customer. ISNULL(raw value, 99999). Feeds into P19 classification. 99999=not available/unknown. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 39 | IsPhoneVerified | bit | YES | 1 if the customer's phone number has been verified. Sourced from Dim_Customer. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.8 eToro Money Account

*Sourced from eMoney_Dim_Account (primary account row, RN_Duplicates=1) and eMoney_Panel_FirstDates.*

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 40 | IsValidETM | int | YES | eToro Money validity flag from eMoney_Dim_Account. 1 when IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0. NULL when the customer has no eTM account (LEFT JOIN). (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 41 | eTM_CurrencyBalanceID | int | YES | eTM currency balance identifier (FiatCurrencyBalances.Id). Primary key of the customer's eTM money account. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 42 | eTM_CurrencyBalanceCreateDate | date | YES | Date the eTM currency balance was created. Sourced from eMoney_Dim_Account.CurrencyBalanceCreateDate. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 43 | eTM_CurrencyBalanceStatus | varchar(50) | YES | Current status of the eTM currency balance (e.g., Active, Suspended). Sourced from eMoney_Dim_Account.CurrencyBalanceStatus. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 44 | eTM_AccountID | int | YES | eTM fiat account identifier (FiatAccount.Id). Parent account of the currency balance. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 45 | eTM_AccountCreateDate | date | YES | Date the eTM fiat account was created. Sourced from eMoney_Dim_Account.AccountCreateDate. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 46 | eTM_AccountStatus | varchar(50) | YES | Current lifecycle status of the eTM fiat account (e.g., Active, Deleted). Sourced from eMoney_Dim_Account.AccountStatus. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 47 | eTM_AccountProgram | varchar(50) | YES | eTM account programme type (e.g., iban, card). Sourced from eMoney_Dim_Account.AccountProgram. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 48 | eTM_AccountSubProgram | varchar(50) | YES | eTM account sub-programme variant (e.g., IBAN EU Green, IBAN Standard UK). Sourced from eMoney_Dim_Account.AccountSubProgram. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 49 | eTM_HasCard | int | YES | 1 if the customer has an associated eTM card; 0 otherwise. Sourced from eMoney_Dim_Account.HasCard. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 50 | eTM_CardStatus | varchar(50) | YES | Current card status (e.g., Activated, Blocked). Sourced from eMoney_Dim_Account.CardStatus. NULL if HasCard=0. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 51 | eTM_ProviderHolderID | int | YES | Provider-side customer holder identifier (Tribe payment provider). Sourced from eMoney_Dim_Account.ProviderHolderID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 52 | eTM_FMI_Date | date | YES | Date of the customer's first money-in (FMI) transaction on the eTM platform. Sourced from eMoney_Panel_FirstDates via AccountID JOIN. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 53 | eTM_FMI_Source | varchar(50) | YES | Transaction type (channel) of the first money-in event. Sourced from eMoney_Panel_FirstDates.FMI_Source. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 54 | eTM_FMO_Date | date | YES | Date of the customer's first money-out (FMO) transaction on the eTM platform. Sourced from eMoney_Panel_FirstDates.FMO_Date. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 55 | eTM_FMO_Target | varchar(50) | YES | Transaction type (channel) of the first money-out event. Sourced from eMoney_Panel_FirstDates.FMO_Target. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.9 P1–P4: Country & Age Risk Parameters

*Each P{n}_Response holds the human-readable description of the matched classification row; P{n}_Risk holds the risk tier text (e.g., Low/Medium/High). Both are NULL if no classification row matched.*

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 56 | P1_Response | varchar(255) | YES | Classification response description for P1 (Client Age). ResponseID = ClientAge integer. Matched from Fivetran classification table ParameterID=1. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 57 | P1_Risk | varchar(30) | YES | Risk tier label for P1 (Client Age). Contributes P1_RiskID × P1_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 58 | P2_Response | varchar(255) | YES | Classification response description for P2 (Address Country High Risk). ResponseID = CountryAddress_IsHRC (0/1/99999). ParameterID=2. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 59 | P2_Risk | varchar(30) | YES | Risk tier label for P2 (Address Country High Risk). Contributes P2_RiskID × P2_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 60 | P3_Response | varchar(255) | YES | Classification response description for P3 (Citizenship Country High Risk). ResponseID = CountryCitizenship_IsHRC. ParameterID=3. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 61 | P3_Risk | varchar(30) | YES | Risk tier label for P3 (Citizenship Country High Risk). Contributes P3_RiskID × P3_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 62 | P4_Response | varchar(255) | YES | Classification response description for P4 (Place of Birth Country High Risk). ResponseID = CountryPOB_IsHRC. ParameterID=4. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 63 | P4_Risk | varchar(30) | YES | Risk tier label for P4 (Place of Birth Country High Risk). Contributes P4_RiskID × P4_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.10 P5–P11: KYC Declarations & Business Duration

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 64 | P5_Response | varchar(255) | YES | Classification response description for P5 (Annual Income — KYC Q10). ResponseID = Q10_AnswerID. ParameterID=5. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 65 | P5_Risk | varchar(30) | YES | Risk tier label for P5 (Annual Income). Contributes P5_RiskID × P5_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 66 | P6_Response | varchar(255) | YES | Classification response description for P6 (Total Assets — KYC Q11). ResponseID = Q11_AnswerID. ParameterID=6. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 67 | P6_Risk | varchar(30) | YES | Risk tier label for P6 (Total Assets). Contributes P6_RiskID × P6_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 68 | P7_Response | varchar(255) | YES | Classification response description for P7 (Planned Investment Amount — KYC Q14). ResponseID = Q14_AnswerID. ParameterID=7. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 69 | P7_Risk | varchar(30) | YES | Risk tier label for P7 (Planned Investment Amount). Contributes P7_RiskID × P7_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 70 | P8_Response | varchar(255) | YES | Classification response description for P8 (Main Source of Income — KYC Q15). ResponseID = Q15_AnswerID. ParameterID=8. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 71 | P8_Risk | varchar(30) | YES | Risk tier label for P8 (Main Source of Income). Contributes P8_RiskID × P8_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 72 | P9_Response | varchar(255) | YES | Classification response description for P9 (Occupation Category — KYC Q18). ResponseID = Q18_AnswerID. ParameterID=9. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 73 | P9_Risk | varchar(30) | YES | Risk tier label for P9 (Occupation Category). Contributes P9_RiskID × P9_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 74 | P10_Response | varchar(255) | YES | ALWAYS NULL. Parameter 10 (KYC Q46 Citizenship By Investment Program) was permanently cancelled. P10_RiskID=0 and P10_Weight=0; this parameter contributes nothing to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 75 | P10_Risk | varchar(30) | YES | ALWAYS NULL. P10 is permanently cancelled — see P10_Response. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 76 | P11_Response | varchar(255) | YES | Classification response description for P11 (Business Duration as eToro depositor). ResponseID = BusinessDuration bucket (99999/1/2/3). ParameterID=11. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 77 | P11_Risk | varchar(30) | YES | Risk tier label for P11 (Business Duration). Contributes P11_RiskID × P11_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.11 P12–P13: Document Verification

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 78 | P12_Response | varchar(255) | YES | Classification response description for P12 (Source of Income Document). ResponseID: 1=document provided, 2=absent with IBAN MoneyIn ≤50K, 3=absent with IBAN MoneyIn >50K. ParameterID=12. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 79 | P12_Risk | varchar(30) | YES | Risk tier label for P12 (Source of Income Document). Contributes P12_RiskID × P12_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 80 | P13_Response | varchar(255) | YES | Classification response description for P13 (Selfie Verification Document). ResponseID: 1=selfie provided (DocType 15 or 18, no rejection), 0=not provided. ParameterID=13. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 81 | P13_Risk | varchar(30) | YES | Risk tier label for P13 (Selfie Verification). Contributes P13_RiskID × P13_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.12 P14–P19: BackOffice & TIN Risk

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 82 | P14_Response | varchar(255) | YES | Classification response description for P14 (AML Screening Status). ResponseID = ScreeningStatusID (ISNULL→99999). ParameterID=14. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 83 | P14_Risk | varchar(30) | YES | Risk tier label for P14 (Screening Status). Contributes P14_RiskID × P14_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 84 | P15_Response | varchar(255) | YES | Classification response description for P15 (Electronic Verification / EV Match Status). ResponseID = EvMatchStatus (ISNULL→99999). ParameterID=15. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 85 | P15_Risk | varchar(30) | YES | Risk tier label for P15 (Electronic Verification). Contributes P15_RiskID × P15_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 86 | P16_Response | varchar(255) | YES | Classification response description for P16 (TIN Country High Risk). ResponseID = CountryTIN_IsHRC (0/1/99999). ParameterID=16. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 87 | P16_Risk | varchar(30) | YES | Risk tier label for P16 (TIN Country High Risk). Contributes P16_RiskID × P16_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 88 | P17_Response | varchar(255) | YES | Classification response description for P17 (TIN Country matches KYC Address Country). ResponseID: 1=match, 0=mismatch, 99999=no TIN. ParameterID=17. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 89 | P17_Risk | varchar(30) | YES | Risk tier label for P17 (TIN Country Match). Contributes P17_RiskID × P17_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 90 | P18_Response | varchar(255) | YES | Classification response description for P18 (Proof of Identity). ResponseID = IsIDProof (ISNULL→99999). ParameterID=18. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 91 | P18_Risk | varchar(30) | YES | Risk tier label for P18 (Proof of Identity). Contributes P18_RiskID × P18_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 92 | P19_Response | varchar(255) | YES | Classification response description for P19 (Proof of Address). ResponseID = IsAddressProof (ISNULL→99999). ParameterID=19. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 93 | P19_Risk | varchar(30) | YES | Risk tier label for P19 (Proof of Address). Contributes P19_RiskID × P19_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.13 P20–P26, P32: IBAN MIMO Risk

*IBAN transactions sourced from eMoney_Dim_Transaction (TxTypeID=5=card_load, 7=IBAN_load, 8=IBAN_unload; IsTxSettled=1). Country matched via TxLocalCountryNumericISO → ISO_CountryNumericCode → #dim_country.*

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 94 | P20_Response | varchar(255) | YES | Classification response description for P20 (IBAN Load — Number of Source Countries). ResponseID encoded: 11=no IBAN loads, 33=1 country, 44=2-3 countries, 55=≥4 countries. ParameterID=20. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 95 | P20_Risk | varchar(30) | YES | Risk tier label for P20 (IBAN Load Country Diversity). Contributes P20_RiskID × P20_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 96 | P21_Response | varchar(255) | YES | Classification response description for P21 (Last IBAN Load Country matches KYC Address Country). ResponseID: 11=no loads, 22=match, 33=mismatch, 44=missing country data. ParameterID=21. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 97 | P21_Risk | varchar(30) | YES | Risk tier label for P21 (IBAN Load Country vs KYC). Contributes P21_RiskID × P21_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 98 | P22_Response | varchar(255) | YES | Classification response description for P22 (Last IBAN Load Country is High Risk). ResponseID: 11=no loads, 22=not HRC, 33=HRC, 44=missing HRC data. ParameterID=22. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 99 | P22_Risk | varchar(30) | YES | Risk tier label for P22 (IBAN Load Country HRC). Contributes P22_RiskID × P22_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 100 | P23_Response | varchar(255) | YES | Classification response description for P23 (IBAN Unload — Number of Destination Countries). Same ResponseID encoding as P20. ParameterID=23. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 101 | P23_Risk | varchar(30) | YES | Risk tier label for P23 (IBAN Unload Country Diversity). Contributes P23_RiskID × P23_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 102 | P24_Response | varchar(255) | YES | Classification response description for P24 (Last IBAN Unload Country matches KYC Address Country). Same encoding as P21. ParameterID=24. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 103 | P24_Risk | varchar(30) | YES | Risk tier label for P24 (IBAN Unload Country vs KYC). Contributes P24_RiskID × P24_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 104 | P25_Response | varchar(255) | YES | Classification response description for P25 (Last IBAN Unload Country is High Risk). Same encoding as P22. ParameterID=25. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 105 | P25_Risk | varchar(30) | YES | Risk tier label for P25 (IBAN Unload Country HRC). Contributes P25_RiskID × P25_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 106 | P26_Response | varchar(255) | YES | Classification response description for P26 (High Net Worth Individual). ResponseID: 11=MoneyIn_IBAN ≤500K USD, 22=>500K USD. ParameterID=26. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 107 | P26_Risk | varchar(30) | YES | Risk tier label for P26 (High Net Worth). Contributes P26_RiskID × P26_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 118 | P32_Response | varchar(255) | YES | Classification response description for P32 (Total IBAN Money In Volume). ResponseID: 11=≤$10K, 22=>$10K–$200K, 33=>$200K. MoneyIn_IBAN = sum of TxTypeID=5 and TxTypeID=7 amounts. ParameterID=32. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 119 | P32_Risk | varchar(30) | YES | Risk tier label for P32 (IBAN Total Volume). Contributes P32_RiskID × P32_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.14 P27–P31: Behavioural & Cross-Platform Risk

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 108 | P27_Response | varchar(255) | YES | Classification response description for P27 (VPN/TOR Usage). ResponseID: 11=VPN/TOR ratio >40% of logins, 22=≤40%, 99999=no login history. Sourced from STS_User_Operations_Data_History (login events). ParameterID=27. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 109 | P27_Risk | varchar(30) | YES | Risk tier label for P27 (VPN/TOR Usage). Contributes P27_RiskID × P27_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 110 | P28_Response | varchar(255) | YES | Classification response description for P28 (Citizenship Country = Place of Birth Country). ResponseID: 1=match, 0=mismatch, 99999=missing data. ParameterID=28. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 111 | P28_Risk | varchar(30) | YES | Risk tier label for P28 (Citizenship = POB). Contributes P28_RiskID × P28_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 112 | P29_Response | varchar(255) | YES | Classification response description for P29 (Citizenship Country = KYC Address Country). ResponseID: 1=match, 0=mismatch, 99999=missing data. ParameterID=29. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 113 | P29_Risk | varchar(30) | YES | Risk tier label for P29 (Citizenship = Address). Contributes P29_RiskID × P29_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 114 | P30_Response | varchar(255) | YES | Classification response description for P30 (Source of Funds — KYC Q26). ResponseID = Q26_AnswerID. ParameterID=30. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 115 | P30_Risk | varchar(30) | YES | Risk tier label for P30 (Source of Funds). Contributes P30_RiskID × P30_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 116 | P31_Response | varchar(255) | YES | Classification response description for P31 (Total Ecosystem Money In vs Declared Max Income). MoneyIn_Total = TP deposits (Fact_CustomerAction) + IBAN loads. Compared against Q10_AnswerID-derived max declared income. ResponseID: 11=within/under declared, 22=up to 130% of declared, 33=exceeds 130% of declared. ParameterID=31. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 117 | P31_Risk | varchar(30) | YES | Risk tier label for P31 (Ecosystem Money vs Declared). Contributes P31_RiskID × P31_Weight to Risk_Final_Result. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

### 4.15 Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 120 | UpdateDate | datetime | YES | SP execution timestamp (GETDATE() at INSERT time). Not a business date; marks when the daily refresh ran. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

---

_Generated by DWH Semantic Documentation Pipeline · Batch 10 · 2026-04-21_
_Writer SP: `eMoney_dbo.SP_eMoney_Customer_Risk_Assessment` · Lineage: `eMoney_Customer_Risk_Assessment.lineage.md`_
