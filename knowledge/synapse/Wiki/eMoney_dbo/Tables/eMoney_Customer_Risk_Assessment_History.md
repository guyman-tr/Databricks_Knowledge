# eMoney_dbo.eMoney_Customer_Risk_Assessment_History

> Append-only audit log of AML/KYC risk class-change events for eToro Money customers: 8,113,383 rows (avg 3.99 events per customer), one row inserted per customer each time their Low/Medium/High/Error classification changes, sharing the identical 120-column schema as eMoney_Customer_Risk_Assessment but with no TRUNCATE — it grows continuously.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Append-Only Event Log) |
| **Production Sources** | Same as eMoney_Customer_Risk_Assessment (see CRA wiki) |
| **Refresh** | Append-only INSERT at Step 32 of SP_eMoney_Customer_Risk_Assessment (class-change trigger) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **Row Count** | 8,113,383 (sampled 2026-04-12) |
| **Rows per CID** | avg 3.99; 26.1% with 1 row; max 387 rows |
| **Writer SP** | SP_eMoney_Customer_Risk_Assessment (Step 32 only) |
| **UC Target** | `emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_customer_risk_assessment_history` |

---

## 1. Business Meaning

`eMoney_Customer_Risk_Assessment_History` is the **class-change audit log** for the eToro Money AML/KYC risk engine. Where `eMoney_Customer_Risk_Assessment` holds exactly one current-state row per customer (rebuilt daily via TRUNCATE + INSERT), History accumulates one row for each time a customer's risk class (`ClientRisk`) changes.

The same 120-column schema is shared across both tables, including all parameter scores (P1–P32) and supporting customer attributes. Each History row is a complete snapshot of the customer's state at the moment of the class change — not just a diff.

**When a History row is inserted** (Step 32 of SP_eMoney_Customer_Risk_Assessment):
- First time the customer appears in CRA (no prior History row for this CID)
- The customer's `ClientRisk` class changes from the last History row (e.g., Low → Medium)

**When a History row is NOT inserted**:
- The customer's class is unchanged from the last History row (Low stays Low)
- Note: even if `Risk_Final_Result` changes (score movement within a class), no row is inserted

**Self-referential loop** (important for understanding both tables):
1. Step 27 reads History (latest row per CID) to populate `PreviousClientRisk` / `PreviousClientRiskDate` and determine `ClientRiskDate` preservation
2. Step 30: TRUNCATE snapshot table (CRA)
3. Step 31: INSERT new snapshot (CRA)
4. Step 32: INSERT new History rows (WHERE class changed vs Step 27 read)

This means the History comparison is always against the **previous SP run's** final state — even if the snapshot was just truncated.

**Schema anomaly period**: From 2025-02-25 to 2025-03-12, the History insert trigger was changed to score-change (`Risk_Final_Result <>`). Rows inserted during this period represent score movements within the same class and DO NOT represent actual class transitions. Reverted 2025-03-12 by Ofir Ovadia.

**Key statistics** (2026-04-12):
- 8,113,383 total History rows
- 26.1% of customers have only 1 History row (class assigned once, never changed)
- Max 387 History rows for a single CID
- Average 3.99 History rows per customer

---

## 2. Business Logic

### 2.1 Insert Condition

**What**: The History table only grows when a class-change event occurs.

**Rule** (Step 32 WHERE clause):
```sql
WHERE trg.CID IS NULL             -- new customer: no prior History
   OR (src.ClientRisk <> trg.ClientRisk)  -- class changed from last History row
```
`trg` = latest History row per CID (from Step 27 ROW_NUMBER PARTITION BY CID ORDER BY ClientRiskDate DESC = 1)

### 2.2 Relationship to CRA Snapshot

**What**: History and CRA share identical DDL. The CRA snapshot always reflects the most recent SP run; History reflects all past class transitions.

**Pattern to get class duration**: 
```sql
-- Time spent at each class level per customer
SELECT h.CID, h.ClientRisk, h.ClientRiskDate,
       LEAD(h.ClientRiskDate) OVER (PARTITION BY h.CID ORDER BY h.ClientRiskDate) AS NextClassDate
FROM eMoney_Customer_Risk_Assessment_History h
```

### 2.3 Score-Change Anomaly Period

**What**: Rows inserted 2025-02-25 to 2025-03-12 used score-change trigger, not class-change.

**Impact**: History row counts are inflated for customers whose score changed intra-class during this window. If analysing class stability or transition frequency, exclude or handle this 16-day window separately.

### 2.4 32-Parameter Scores in History

**What**: All P{n}_Response and P{n}_Risk columns are populated in History rows exactly as in CRA, reflecting the full scoring state at the time of class change.

**P10 Note**: Always NULL in History rows for the same reason as CRA (permanently cancelled).

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current risk classification | Use eMoney_Customer_Risk_Assessment (faster — single row per CID) |
| First time customer went High | WHERE ClientRisk='High', MIN(ClientRiskDate) GROUP BY CID |
| Class upgrade/downgrade events | Self-join or LEAD/LAG on CID ORDER BY ClientRiskDate |
| Customers who improved from High to Low | Filter consecutive rows: prev='High' AND curr='Low' |
| History row count per customer | GROUP BY CID COUNT(*) — identifies complex risk trajectories |
| Score-change period anomaly | WHERE ClientRiskDate BETWEEN '2025-02-25' AND '2025-03-12' |

### 3.2 JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Customer_Risk_Assessment | ON h.CID = cra.CID | Current state alongside historical events |
| DWH_dbo.Dim_Customer | ON h.CID = dc.RealCID | Trading platform enrichment |

### 3.3 Gotchas

- **No grain constraint**: Multiple rows per CID are normal and expected. Do not use without GROUP BY or windowing.
- **Score-change rows (2025-02-25 → 2025-03-12)**: These rows do not represent class transitions. Filter by ClientRiskDate range to exclude.
- **P10 always NULL**: See CRA wiki. Same behaviour in History.
- **PreviousClientRisk in History**: Reflects the class BEFORE the change event recorded in the row. `PreviousClientRisk='Low'` + `ClientRisk='Medium'` = upgraded row.
- **UpdateDate = GETDATE()** at SP execution time — marks when the row was inserted, not the business event date. Use ClientRiskDate for the business event.
- **CID NOT NULL**: Both CID and GCID are NOT NULL in DDL. All History rows have valid customer identifiers.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (Customer.CustomerStatic or BackOffice.Customer via Dim_Customer.md) |
| Tier 2 | Description written from ETL SP code analysis (SP_eMoney_Customer_Risk_Assessment) |

*All column descriptions are identical to eMoney_Customer_Risk_Assessment.md per cross-object consistency rule. Business semantics of each column in History rows are the same as in the CRA snapshot — they represent the customer's state at the time of the class-change event.*

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
| 10 | IsValidCustomer | int | YES | DWH-computed validity flag from Dim_Customer. 1 when not Internal (PlayerLevelID≠4), not label 30/26, and CountryID≠250. Used for filtering non-standard customer profiles. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |
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

*Sourced from eMoney_Dim_Account (primary account row, RN_Duplicates=1) and eMoney_Panel_FirstDates. Reflects eTM state at the time the class-change row was generated.*

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
| 120 | UpdateDate | datetime | YES | SP execution timestamp (GETDATE() at INSERT time). Not a business date; marks when the class-change row was inserted. (Tier 2 — SP_eMoney_Customer_Risk_Assessment) |

---

_Generated by DWH Semantic Documentation Pipeline · Batch 10 · 2026-04-21_
_Writer SP: `eMoney_dbo.SP_eMoney_Customer_Risk_Assessment` · Lineage: `eMoney_Customer_Risk_Assessment_History.lineage.md`_
