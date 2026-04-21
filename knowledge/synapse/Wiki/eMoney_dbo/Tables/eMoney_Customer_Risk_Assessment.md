---
object: eMoney_Customer_Risk_Assessment
schema: eMoney_dbo
database: Synapse DWH
type: Table
columns: 120
documented: 2026-04-21
batch: 9
quality_score: 9.0
---

# eMoney_dbo.eMoney_Customer_Risk_Assessment

| Property | Value |
|----------|-------|
| **Object** | `eMoney_dbo.eMoney_Customer_Risk_Assessment` |
| **Type** | Table (HEAP, HASH(CID)) |
| **Production Source** | SP_eMoney_Customer_Risk_Assessment (1,730 lines, 32 steps) |
| **Refresh Pattern** | Daily TRUNCATE TABLE + INSERT; runs separately after Group One pipeline |
| **Row Count** | 2,031,882 (as of 2026-04-12) |
| **Date Range** | 2024-07-17 — 2026-04-12 (ClientRiskDate) |
| **Grain** | One row per CID (current snapshot — full rebuild each run) |
| **Distribution** | HASH(CID) |
| **Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **Author** | eMoney & Wallet Data Analytics Team |
| **Created** | 2023-12-13 |

---

## 1. Business Meaning

`eMoney_Customer_Risk_Assessment` is the **daily AML/compliance risk scoring snapshot** for all eToro Money customers (2.03M as of April 2026). Each row contains the customer's current AML risk classification (Low / Medium / High / Error), a composite 32-parameter weighted numeric score, and the individual parameter responses used to derive that score.

The table powers compliance workflows: customers classified as High risk trigger enhanced due diligence; the PEP Override (201 customers) and Manual Override (1 customer) mechanisms allow the compliance team to override the automated score via Google Sheets without code changes.

This is a **current-state snapshot** — truncated and fully rebuilt daily. Point-in-time history is captured in the companion `eMoney_Customer_Risk_Assessment_History` table, which receives a new row only when a customer's risk *class* changes (not just score changes — reverted from score-change trigger on 2025-03-12 to limit Tribe system volume).

**Risk distribution (2026-04-12):** Low=76.3%, Medium=21.8%, High=1.7%, Error=0.1% (2,043 NULL-score rows).

---

## 2. Business Logic

### Risk Classification Engine (32 Steps)

1. **Input collection** (Steps 1–16): Pulls data from 29 source objects across DWH_dbo, eMoney_dbo, and BI_DB_dbo. Key inputs: KYC answers (Q10/Q11/Q14/Q15/Q18/Q26), country HRC risk mappings (Fivetran Google Sheets), document verification status, account activity (TP + IBAN).
2. **Parameter scoring** (Steps 17–26): For each of 32 parameters, a ResponseID is computed from input data and matched against the Fivetran classification table to retrieve `P_RiskID` (numeric) and `P_Response`/`P_Risk` (text).
3. **Composite score** (Step 28): `Risk_Final_Result = SUM(P_RiskID × P_Weight)` for all 32 parameters. NULL if any required classification lookup fails entirely.
4. **Risk classification** (Step 28): Low < @RiskLowerCut ≤ Medium ≤ @RiskUpperCut < High. Thresholds loaded at runtime from ParameterID=98/99 rows in the Fivetran classification table — **dynamic, can change without code changes**.
5. **Overrides** (Step 29):
   - **PEP Override**: ScreeningStatus='PEP' → ClientRisk='High', ClientRiskAssignmentType='PEP Override' (201 rows)
   - **Manual Override**: CID in Google Sheets manual override table → explicit risk class from compliance ops team (1 row)

### Parameter Groups (32 total)

| Group | Parameters | Description |
|-------|------------|-------------|
| Client Demography | P1 | Age category |
| Country Risk (HRC) | P2, P3, P4 | Address, Citizenship, POB country High Risk Country flag |
| KYC Answers | P5–P9, P30 | Annual income, assets, investment amount, income source, occupation, source of funds |
| Country Alignment | P28, P29 | Citizenship = POB, Citizenship = KYC Address Country |
| Document Status | P12, P13, P18, P19 | Source of income doc, Selfie, Proof of ID, Proof of Address |
| BackOffice Screening | P14, P15 | Screening Status (PEP/Sanctions), Electronic Verification result |
| TIN | P16, P17 | TIN Country HRC, TIN Country vs Address Country match |
| Business Duration | P11 | FTD tenure: <1yr / 1–3yr / >3yr |
| IBAN MIMO | P20–P26, P32 | Load/unload country diversity, HRC, total volume, HNWI threshold |
| TP + IBAN Income | P31 | Declared vs actual income match (TP deposits + IBAN loads vs KYC Q10) |
| VPN/TOR Usage | P27 | Percentage of logins via VPN/TOR |
| CANCELLED | P10 | Citizenship by Investment (Q46) — hardcoded NULL, weight=0 |

### Error Conditions

- **'Error' class** (2,043 rows, 0.1%): All parameter classification lookups fail → composite sum NULL → Risk_Final_Result=NULL → ClientRisk='Error'. Indicates data gaps or classification table coverage issues.
- **GCID deduplication**: Only customers with exactly one eTM account (GCID_Unique_Count=1 in eMoney_Dim_Account AND in Panel_FirstDates INNER JOIN) contribute eTM_* data. Multi-account customers and non-eTM customers have NULL eTM_* fields.
- **History insert condition**: `eMoney_Customer_Risk_Assessment_History` receives a new row only when `trg.CID IS NULL OR src.ClientRisk <> trg.ClientRisk` (class-change only, not score-change — reverted 2025-03-12).

---

## 3. Query Advisory

### Gotchas

| Gotcha | Detail |
|--------|--------|
| **P10 always NULL** | P10_Response and P10_Risk are NEVER populated (parameter cancelled in SP). Do not use in analysis. |
| **Dynamic thresholds** | Low/Medium/High class boundaries are in the Fivetran classification table (ParameterID=98/99), not hardcoded. Check the classification table before assuming threshold values. |
| **'Error' ≠ 'High'** | 'Error' class means the score could not be computed — it is not the same as High risk. Treat separately in compliance analysis. |
| **History is class-change only** | `eMoney_Customer_Risk_Assessment_History` does NOT capture every daily score change — only risk class changes (reverted 2025-03-12). |
| **CRA scores all TP customers** | All 2.03M TP customers are scored. IsValidETM=NULL/0 rows (~21%) have NULL eTM_* columns — their score uses TP-only inputs. |
| **UpdateDate is ETL timestamp** | UpdateDate = GETDATE() at Step 31 INSERT. Use ClientRiskDate for the risk classification effective date. |
| **ClientRiskDate lag** | ClientRiskDate is preserved from the previous run if risk class is unchanged; it is NOT the run date for stable customers. |

### Recommended Filters

```sql
-- Customers with a computed risk score (exclude Error)
WHERE ClientRisk IN ('Low', 'Medium', 'High')

-- eTM account holders only
WHERE IsValidETM = 1

-- High-risk PEP customers
WHERE ClientRisk = 'High' AND ClientRiskAssignmentType = 'PEP Override'

-- Customers whose risk class changed on the last run
WHERE ClientRisk <> PreviousClientRisk
  AND ClientRiskDate = CAST(GETDATE() AS DATE)
```

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | int | NOT NULL | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | NOT NULL | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. DWH note: NOT NULL in this table — customers without a GCID are excluded from CRA scoring. (Tier 1 — Customer.CustomerStatic) |
| 3 | ClientRiskDate | date | NULL | Effective date of the current risk classification. Preserved from the previous run if the risk class is unchanged; set to GETDATE() when a class change occurs or on first assignment. Updated immediately by Step 29 PEP/Manual overrides. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 4 | ClientRisk | varchar(10) | NULL | Current AML risk classification. Values: 'Low', 'Medium', 'High', 'Error'. Derived by comparing Risk_Final_Result against dynamic @RiskLowerCut/@RiskUpperCut thresholds. 'Error' when composite score is NULL (all parameter lookups failed). Overridden to 'High' for PEP customers in Step 29. Distribution: Low=76.3%, Medium=21.8%, High=1.7%, Error=0.1%. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 5 | ClientRiskAssignmentType | varchar(50) | NULL | Source of the risk classification. Values: 'Regular' (automated composite score, 99.99%), 'PEP Override' (ScreeningStatus='PEP', 201 rows), 'Manual Override' (compliance ops via Google Sheets, 1 row). (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 6 | Risk_Final_Result | float | NULL | Composite AML risk score (numeric). Sum of (P_RiskID × P_Weight) for all 32 parameters. NULL when any required classification table lookup fails entirely, resulting in ClientRisk='Error'. Threshold boundary values for Low/Medium/High are in the Fivetran classification table (ParameterID=98/99). (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 7 | PreviousClientRisk | varchar(10) | NULL | Risk classification from the most recent History row for this CID, read before today's run (Step 27: ROW_NUMBER() PARTITION BY CID ORDER BY ClientRiskDate DESC). NULL if no History row exists for this customer. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 8 | PreviousClientRiskDate | date | NULL | Effective date of the previous risk classification from History. Same Step 27 window function as PreviousClientRisk. NULL if no History row exists. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 9 | VerificationLevelID | int | NULL | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. (Tier 1 — BackOffice.Customer) |
| 10 | IsValidCustomer | int | NULL | DWH-computed flag: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used to filter non-standard customers in reporting. Passthrough from Dim_Customer (computed in that table's ETL). (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 11 | IsDepositor | int | NULL | DWH-computed flag: 1 if customer has made at least one deposit on the trading platform. Passthrough from Dim_Customer (updated post-load from FTD data). (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 12 | AccountType | varchar(50) | NULL | Trading platform account type name. Resolved via Dim_AccountType lookup on AccountTypeID from Dim_Customer. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 13 | Regulation | varchar(50) | NULL | Regulatory entity governing this customer's account. Resolved via Dim_Regulation lookup on RegulationID from Dim_Customer. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 14 | Club | varchar(50) | NULL | eToro Club / loyalty tier name. Resolved via Dim_PlayerLevel lookup on PlayerLevelID from Dim_Customer. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 15 | ClientAge | int | NULL | Customer age in years as of the ETL run date (DATEDIFF(YEAR, BirthDate, GETDATE())). Value 99999 indicates NULL BirthDate or implausible age (>120 or <=0). Used as input to P1 risk parameter. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 16 | DateOfBirth | date | NULL | Customer date of birth. Used in LinkedAccountHash1 for duplicate detection and in KYC age verification. DWH note: CAST(BirthDate AS DATE) — time component stripped. (Tier 1 — Customer.CustomerStatic) |
| 17 | DateOfReg | date | NULL | Account registration date (renamed from Registered). Default=getdate(). DWH note: CAST(RegisteredReal AS DATE) — time component stripped. (Tier 1 — Customer.CustomerStatic) |
| 18 | DateOfFTD | date | NULL | First trading platform deposit date. CAST(FirstDepositDate AS DATE) from Dim_Customer. NULL for non-depositors. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 19 | BusinessDuration | int | NULL | Categorical FTD tenure. Values: 1=<1 year since FTD, 2=1–3 years, 3=>3 years, 99999=no deposit or calculation error. Used as input to P11 risk parameter. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 20 | CountryAddress | varchar(50) | NULL | Country name for customer's registered address. Resolved via Dim_Country lookup on Dim_Customer.CountryID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 21 | CountryCitizenship | varchar(50) | NULL | Country name for customer's citizenship. Resolved via Dim_Country lookup on CitizenshipCountryID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 22 | CountryPOB | varchar(50) | NULL | Country name for customer's place of birth. Resolved via Dim_Country lookup on POBCountryID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 23 | CountryTIN | varchar(50) | NULL | Country associated with the customer's Tax Identification Number. Resolved from BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField (FieldId=6) with COALESCE priority: address-matching TIN country > HRC different TIN country > non-HRC different TIN country. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 24 | CountryAddress_IsHRC | int | NULL | High Risk Country flag for the address country. Values: 0=not HRC, 1=HRC per Fivetran Google Sheets country risk mapping, 99999=NULL country. Input to P2 risk parameter. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 25 | CountryCitizenship_IsHRC | int | NULL | High Risk Country flag for the citizenship country. Values: 0=not HRC, 1=HRC, 99999=NULL. Input to P3 risk parameter. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 26 | CountryPOB_IsHRC | int | NULL | High Risk Country flag for place of birth country. Values: 0=not HRC, 1=HRC, 99999=NULL. Input to P4 risk parameter. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 27 | CountryTIN_IsHRC | int | NULL | High Risk Country flag for the TIN country. Values: 0=not HRC, 1=HRC, 99999=NULL or no TIN data. Input to P16 risk parameter. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 28 | AccountStatus | varchar(50) | NULL | Trading platform account status name. Resolved via Dim_AccountStatus lookup on AccountStatusID from Dim_Customer. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 29 | PlayerStatus | varchar(50) | NULL | Trading platform player status name. Resolved via Dim_PlayerStatus lookup on PlayerStatusID from Dim_Customer. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 30 | PlayerStatusReason | varchar(50) | NULL | Reason for the player status. Resolved via Dim_PlayerStatusReasons lookup on PlayerStatusReasonID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 31 | PlayerStatusSubReason | varchar(50) | NULL | Sub-reason for the player status. Resolved via Dim_PlayerStatusSubReasons lookup on PlayerStatusSubReasonID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 32 | ScreeningStatus | varchar(255) | NULL | Sanctions/PEP screening status name. Resolved via Dim_ScreeningStatus lookup on ScreeningStatusID (ISNULL → 99999 before lookup). 'PEP' value triggers PEP Override classification in Step 29. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 33 | EVStatus | varchar(30) | NULL | Electronic verification (identity verification) status name. Resolved via Dim_EvMatchStatus lookup on EvMatchStatus (ISNULL → 99999 before lookup). Input to P15 risk parameter. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 34 | DocumentStatus | varchar(50) | NULL | Customer document verification status name. Resolved via Dim_DocumentStatus lookup on DocumentStatusID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 35 | PhoneStatus | varchar(50) | NULL | Phone verification status name. Resolved via Dim_PhoneVerified lookup on PhoneVerifiedID. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 36 | DocsOK | tinyint | NULL | Composite document verification OK flag. 1=all required documents accepted. Passthrough from Dim_Customer (computed in that table's ETL). (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 37 | IsIDProof | int | NULL | Identity proof document status indicator. ISNULL(dc.IsIDProof, 99999) applied — 99999 when no ID proof record. Input to P18 risk parameter. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 38 | IsAddressProof | int | NULL | Address proof document status indicator. ISNULL(dc.IsAddressProof, 99999) applied — 99999 when no address proof record. Input to P19 risk parameter. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 39 | IsPhoneVerified | bit | NULL | Phone verification flag. 1=phone verified. Passthrough from Dim_Customer. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 40 | IsValidETM | int | NULL | Composite flag: customer has exactly one valid eToro Money account (GCID_Unique_Count=1 in eMoney_Dim_Account AND matched in Panel_FirstDates INNER JOIN). NULL=no valid eTM account or multiple eTM accounts (20.9%), 0=invalid eTM account (0.06%), 1=valid single eTM account (79.0%). (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 41 | eTM_CurrencyBalanceID | int | NULL | eTM currency balance record identifier from eMoney_Dim_Account. NULL when IsValidETM is NULL or 0. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 42 | eTM_CurrencyBalanceCreateDate | date | NULL | Date the eTM currency balance was created. From eMoney_Dim_Account. NULL when no valid eTM account. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 43 | eTM_CurrencyBalanceStatus | varchar(50) | NULL | eTM currency balance status name (name-resolved in eMoney_Dim_Account ETL). NULL when no valid eTM account. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 44 | eTM_AccountID | int | NULL | eTM account identifier from eMoney_Dim_Account. NULL when no valid eTM account. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 45 | eTM_AccountCreateDate | date | NULL | Date the eTM account was created. From eMoney_Dim_Account. NULL when no valid eTM account. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 46 | eTM_AccountStatus | varchar(50) | NULL | eTM account status name (name-resolved in eMoney_Dim_Account ETL). NULL when no valid eTM account. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 47 | eTM_AccountProgram | varchar(50) | NULL | eTM account program name (0=Unknown, 1=Card, 2=IBAN; name-resolved in eMoney_Dim_Account ETL). NULL when no valid eTM account. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 48 | eTM_AccountSubProgram | varchar(50) | NULL | eTM account sub-program name (country-specific card/IBAN variant; name-resolved in eMoney_Dim_Account ETL). NULL when no valid eTM account. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 49 | eTM_HasCard | int | NULL | Flag: customer has a physical eTM card. From eMoney_Dim_Account. NULL when no valid eTM account. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 50 | eTM_CardStatus | varchar(50) | NULL | eTM card status name (name-resolved in eMoney_Dim_Account ETL). NULL when no valid eTM account or no card. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 51 | eTM_ProviderHolderID | int | NULL | eTM provider holder identifier (Tribe-side customer ID). From eMoney_Dim_Account. NULL when no valid eTM account. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 52 | eTM_FMI_Date | date | NULL | First Money In date for the eTM account (first IBAN load or card top-up). From eMoney_Panel_FirstDates. NULL when no eTM inbound activity. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 53 | eTM_FMI_Source | varchar(50) | NULL | Source of the first money-in event (e.g., IBAN transfer, card load). From eMoney_Panel_FirstDates. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 54 | eTM_FMO_Date | date | NULL | First Money Out date for the eTM account (first IBAN unload or card spend). From eMoney_Panel_FirstDates. NULL when no eTM outbound activity. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 55 | eTM_FMO_Target | varchar(50) | NULL | Target of the first money-out event. From eMoney_Panel_FirstDates. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 56 | P1_Response | varchar(255) | NULL | Parameter 1 (Client Age) response description from Fivetran classification table. ResponseID matched on ClientAge band. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 57 | P1_Risk | varchar(30) | NULL | Parameter 1 (Client Age) risk level text (e.g., 'Low', 'Medium', 'High'). (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 58 | P2_Response | varchar(255) | NULL | Parameter 2 (Address Country HRC flag) response description from Fivetran classification table. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 59 | P2_Risk | varchar(30) | NULL | Parameter 2 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 60 | P3_Response | varchar(255) | NULL | Parameter 3 (Citizenship Country HRC flag) response description from Fivetran classification table. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 61 | P3_Risk | varchar(30) | NULL | Parameter 3 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 62 | P4_Response | varchar(255) | NULL | Parameter 4 (Place of Birth Country HRC flag) response description from Fivetran classification table. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 63 | P4_Risk | varchar(30) | NULL | Parameter 4 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 64 | P5_Response | varchar(255) | NULL | Parameter 5 (KYC Q10 Annual Income) response description from Fivetran classification table. ResponseID matched on declared annual income band. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 65 | P5_Risk | varchar(30) | NULL | Parameter 5 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 66 | P6_Response | varchar(255) | NULL | Parameter 6 (KYC Q11 Total Assets) response description from Fivetran classification table. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 67 | P6_Risk | varchar(30) | NULL | Parameter 6 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 68 | P7_Response | varchar(255) | NULL | Parameter 7 (KYC Q14 Investment Amount) response description from Fivetran classification table. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 69 | P7_Risk | varchar(30) | NULL | Parameter 7 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 70 | P8_Response | varchar(255) | NULL | Parameter 8 (KYC Q15 Main Source of Income) response description from Fivetran classification table. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 71 | P8_Risk | varchar(30) | NULL | Parameter 8 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 72 | P9_Response | varchar(255) | NULL | Parameter 9 (KYC Q18 Occupation Category) response description from Fivetran classification table. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 73 | P9_Risk | varchar(30) | NULL | Parameter 9 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 74 | P10_Response | varchar(255) | NULL | Parameter 10 (Citizenship by Investment Program, Q46) — CANCELLED. Hardcoded NULL in SP. Weight=0 in classification table. Do not use. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 75 | P10_Risk | varchar(30) | NULL | Parameter 10 risk level text — CANCELLED. Always NULL. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 76 | P11_Response | varchar(255) | NULL | Parameter 11 (Business Duration / FTD Tenure) response description from Fivetran classification table. ResponseID matched on BusinessDuration categorical value (1/2/3/99999). (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 77 | P11_Risk | varchar(30) | NULL | Parameter 11 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 78 | P12_Response | varchar(255) | NULL | Parameter 12 (Source of Income document) response description. ResponseID: 1=document provided (DocType 16/17 accepted), 2=not provided and lifetime IBAN load <=50K, 3=not provided and lifetime IBAN load >50K. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 79 | P12_Risk | varchar(30) | NULL | Parameter 12 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 80 | P13_Response | varchar(255) | NULL | Parameter 13 (Selfie verification) response description. Accepted document types: 15 (selfie) or 18 (selfie variant) from BackOffice.CustomerDocument. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 81 | P13_Risk | varchar(30) | NULL | Parameter 13 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 82 | P14_Response | varchar(255) | NULL | Parameter 14 (Screening Status / PEP / Sanctions) response description. ResponseID matched on ScreeningStatusID from Dim_ScreeningStatus. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 83 | P14_Risk | varchar(30) | NULL | Parameter 14 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 84 | P15_Response | varchar(255) | NULL | Parameter 15 (Electronic Verification result) response description. ResponseID matched on EVStatusID from Dim_EvMatchStatus. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 85 | P15_Risk | varchar(30) | NULL | Parameter 15 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 86 | P16_Response | varchar(255) | NULL | Parameter 16 (TIN Country HRC flag) response description. ResponseID matched on CountryTIN_IsHRC value. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 87 | P16_Risk | varchar(30) | NULL | Parameter 16 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 88 | P17_Response | varchar(255) | NULL | Parameter 17 (TIN Country matches Address Country) response description. ResponseID: 1=TIN country matches address country, 0=mismatch, 99999=no TIN data in ExtendedUserField. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 89 | P17_Risk | varchar(30) | NULL | Parameter 17 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 90 | P18_Response | varchar(255) | NULL | Parameter 18 (Proof of Identity document) response description. ResponseID matched on IsIDProof value. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 91 | P18_Risk | varchar(30) | NULL | Parameter 18 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 92 | P19_Response | varchar(255) | NULL | Parameter 19 (Proof of Address document) response description. ResponseID matched on IsAddressProof value. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 93 | P19_Risk | varchar(30) | NULL | Parameter 19 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 94 | P20_Response | varchar(255) | NULL | Parameter 20 (IBAN Loads from Multiple Countries) response description. ResponseID: 11=no loads ever, 22=loads from 0 distinct countries, 33=1 country, 44=2–3 countries, 55=4+ countries. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 95 | P20_Risk | varchar(30) | NULL | Parameter 20 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 96 | P21_Response | varchar(255) | NULL | Parameter 21 (IBAN Load Country Matches KYC Country) response description. Checks if any load source country matches the customer's KYC address country. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 97 | P21_Risk | varchar(30) | NULL | Parameter 21 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 98 | P22_Response | varchar(255) | NULL | Parameter 22 (IBAN Load Country is HRC) response description. Checks if any load source country is a High Risk Country. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 99 | P22_Risk | varchar(30) | NULL | Parameter 22 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 100 | P23_Response | varchar(255) | NULL | Parameter 23 (IBAN Unloads to Multiple Countries) response description. Same structure as P20 but for outbound transactions (TxTypeID=8 unloads). (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 101 | P23_Risk | varchar(30) | NULL | Parameter 23 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 102 | P24_Response | varchar(255) | NULL | Parameter 24 (IBAN Unload Country Matches KYC Country) response description. Checks if any unload destination country matches the customer's KYC address country. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 103 | P24_Risk | varchar(30) | NULL | Parameter 24 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 104 | P25_Response | varchar(255) | NULL | Parameter 25 (IBAN Unload Country is HRC) response description. Checks if any unload destination country is a High Risk Country. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 105 | P25_Risk | varchar(30) | NULL | Parameter 25 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 106 | P26_Response | varchar(255) | NULL | Parameter 26 (High Net Worth Individual threshold) response description. ResponseID: 11=lifetime IBAN loads <=500K USD, 22=lifetime IBAN loads >500K USD. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 107 | P26_Risk | varchar(30) | NULL | Parameter 26 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 108 | P27_Response | varchar(255) | NULL | Parameter 27 (VPN/TOR Usage) response description. ResponseID: 11=>40% of logins detected as VPN/TOR in STS_User_Operations_Data_History, 22=<=40%, 99999=no login history. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 109 | P27_Risk | varchar(30) | NULL | Parameter 27 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 110 | P28_Response | varchar(255) | NULL | Parameter 28 (Citizenship matches Place of Birth Country) response description. ResponseID: 1=same country, 0=different country. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 111 | P28_Risk | varchar(30) | NULL | Parameter 28 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 112 | P29_Response | varchar(255) | NULL | Parameter 29 (Citizenship matches KYC Address Country) response description. ResponseID: 1=same country, 0=different country. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 113 | P29_Risk | varchar(30) | NULL | Parameter 29 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 114 | P30_Response | varchar(255) | NULL | Parameter 30 (KYC Q26 Source of Funds) response description from Fivetran classification table. ResponseID matched on Q26 answer. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 115 | P30_Risk | varchar(30) | NULL | Parameter 30 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 116 | P31_Response | varchar(255) | NULL | Parameter 31 (Declared vs Actual Income Match) response description. Actual income = total TP deposits (Fact_CustomerAction ActionTypeID=7/8, FundingTypeID<>33) + lifetime IBAN loads; compared against KYC Q10 declared maximum annual income band. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 117 | P31_Risk | varchar(30) | NULL | Parameter 31 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 118 | P32_Response | varchar(255) | NULL | Parameter 32 (Total IBAN Inflow Amount) response description. ResponseID: 11=lifetime IBAN loads <=10K USD, 22=10K–200K USD, 33=>200K USD. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 119 | P32_Risk | varchar(30) | NULL | Parameter 32 risk level text. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
| 120 | UpdateDate | datetime | NULL | Row insert timestamp (GETDATE() at Step 31 INSERT). Reflects ETL run time, not business date. Use ClientRiskDate for the risk classification effective date. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

---

## 5. Lineage

### ETL Sources

```
[Customer.CustomerStatic]   [BackOffice.Customer]   [BackOffice.CustomerDocument]
         |                          |                           |
         v                          v                           v
   [DWH_staging.etoro_*]   [DWH_staging.etoro_BO_*]  [BI_DB_dbo.External_etoro_BO_*]
         |                          |
         +------------+-------------+
                      |
              [DWH_dbo.Dim_Customer]          [DWH_dbo.Fact_CustomerAction]
                      |                        (TP deposits/cashouts)
         +------------+----+-------------------+
         |                 |
[eMoney_dbo.eMoney_Dim_Account]       [BI_DB_dbo.BI_DB_KYC_Questions_Answers]
[eMoney_dbo.eMoney_Panel_FirstDates]  [BI_DB_dbo.External_UserApiDB_ExtendedUserField]
[eMoney_dbo.eMoney_Dim_Transaction]   [DWH_dbo.STS_User_Operations_Data_History]
         |                            [DWH_dbo.Dim_Country / Dim_*Status dims]
         +---------- all inputs -------+
                      |
    [BI_DB_dbo.External_Fivetran_*_classification_table]  (weights, thresholds)
    [BI_DB_dbo.External_Fivetran_*_Manual_Override_Table] (compliance overrides)
    [BI_DB_dbo.External_Fivetran_*_cracountryriskmapping] (HRC country list)
                      |
                      v
      [SP_eMoney_Customer_Risk_Assessment]  (1,730 lines, 32 steps)
                      |
          +-----------+-----------+
          |                       |
          v                       v
[eMoney_Customer_Risk_Assessment]  [eMoney_Customer_Risk_Assessment_History]
(TRUNCATE + INSERT daily)          (class-change-only append; Step 32)
          ^                                ^
          +--Step 27: read prev risk-------+
```

### ETL Orchestration

- Runs **separately from Group One** — SP_eMoney_Execute_Group_One does not include CRA (all entries commented out). CRA is a standalone job that runs after Group One completes.
- **Change history**: 2023-12-13 created; 2024-07-22 changed DELETE→TRUNCATE (Step 30); 2025-02-25 History trigger changed to score-change; 2025-03-12 reverted to class-change-only; 2026-04-01 ExecutedDate format fix + classification table performance fix (Inessa/Shahar).

---

## 6. Relationships

| Relationship | Type | Join Key |
|-------------|------|----------|
| `DWH_dbo.Dim_Customer` | Source (TP customer profile) | CID = Dim_Customer.RealCID |
| `eMoney_dbo.eMoney_Dim_Account` | Source (eTM account identity) | GCID; GCID_Unique_Count=1 filter |
| `eMoney_dbo.eMoney_Panel_FirstDates` | Source (eTM FMI/FMO dates) | GCID INNER JOIN |
| `eMoney_dbo.eMoney_Dim_Transaction` | Source (IBAN MIMO data) | AccountID; TxTypeID IN (5,7,8) |
| `eMoney_dbo.eMoney_Customer_Risk_Assessment_History` | Self-referential (previous risk lookup) | CID; latest row by ClientRiskDate |
| `BI_DB_dbo.External_Fivetran_..._classification_table` | Fivetran (parameter weights and thresholds) | ParameterID + ResponseID |
| `BI_DB_dbo.External_Fivetran_..._Manual_Override_Table` | Fivetran (manual risk overrides) | CID |
| `BI_DB_dbo.External_Fivetran_..._cracountryriskmapping` | Fivetran (HRC country list) | ISO country code via eMoney_Country_Codes_Mapping_ISO |

---

## 7. Sample Queries

```sql
-- Risk class distribution
SELECT
    ClientRisk,
    ClientRiskAssignmentType,
    COUNT(*) AS Customers,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS Pct
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment
GROUP BY ClientRisk, ClientRiskAssignmentType
ORDER BY Customers DESC;

-- High-risk customers with key scoring drivers
SELECT
    CID,
    GCID,
    ClientRisk,
    ClientRiskAssignmentType,
    Risk_Final_Result,
    ScreeningStatus,
    CountryAddress,
    CountryAddress_IsHRC,
    P14_Response,   -- Screening Status
    P15_Response    -- Electronic Verification
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment
WHERE ClientRisk = 'High';

-- Customers whose risk class changed on the latest run
SELECT
    CID,
    ClientRisk           AS CurrentRisk,
    PreviousClientRisk,
    ClientRiskDate,
    PreviousClientRiskDate
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment
WHERE ClientRisk <> PreviousClientRisk
  AND ClientRiskDate = CAST(GETDATE() AS DATE);

-- eTM account holders: IBAN volume and HNW flag
SELECT
    CID,
    IsValidETM,
    eTM_AccountProgram,
    P20_Response,   -- IBAN load countries count
    P26_Response,   -- High Net Worth Individual
    P32_Response,   -- Total IBAN inflow
    ClientRisk
FROM eMoney_dbo.eMoney_Customer_Risk_Assessment
WHERE IsValidETM = 1;
```

---

## 8. Atlassian Knowledge Sources

| Source | Notes |
|--------|-------|
| SP_eMoney_Customer_Risk_Assessment header | 32-step algorithm documented inline in SP header comments (lines 1–80) |
| Fivetran Google Sheets classification table | Authoritative source for parameter weights and dynamic risk thresholds; synced via BI_DB_dbo.External_Fivetran_* tables |
| eMoney & Wallet Data Analytics Team | Original authors (2023-12-13); contact for P10 cancellation context and scoring model evolution |

---

## Tier Legend

| Tier | Meaning | Count |
|------|---------|-------|
| Tier 1 | Verbatim copy from upstream production DB wiki (no value transformation) | 5 |
| Tier 2 | Confirmed from SP source code and ETL column-to-source tracing | 115 |

---

## T1 Upstream Fidelity Verification (Phase 10.5b)

| Column | Upstream Source | Upstream Words | Wiki Words | Status |
|--------|----------------|---------------|-----------|--------|
| CID | Dim_Customer.RealCID → Customer.CustomerStatic | 21 | 21 | IDENTICAL (stats stripped: none) |
| GCID | Dim_Customer.GCID → Customer.CustomerStatic | 20 | 20 | IDENTICAL + DWH note added (NOT NULL constraint) |
| VerificationLevelID | Dim_Customer → BackOffice.Customer | 22 | 18 | IDENTICAL (stats stripped: 4 percentages) |
| DateOfBirth | Dim_Customer.BirthDate → Customer.CustomerStatic | 15 | 15 | IDENTICAL + DWH note added (CAST DATE) |
| DateOfReg | Dim_Customer.RegisteredReal → Customer.CustomerStatic | 7 | 7 | IDENTICAL + DWH note added (CAST DATE) |

PHASE 10.5b CHECKPOINT: PASS
- Tier 1 count: 5 / 120 columns
- Upstream wiki (Dim_Customer) has 107 columns; 5 confirmed Tier 1 passthroughs; remaining 115 are ETL-computed, lookup-resolved, or Fivetran-sourced (no upstream wiki for Fivetran tables)
- No HARD FAIL condition: upstream_matchable_columns = ~5 (only core identity/compliance fields pass through unchanged); Tier 1 count = 5 = 100% of matchable upstream columns
