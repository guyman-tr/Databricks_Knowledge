# BackOffice.Customer

> BackOffice-specific customer profile extending Customer.CustomerStatic with operational state: regulatory assignment, KYC verification level, sales agent assignment, account classification, MiFID/ASIC/Seychelles categorization, AML flags, trading risk status, and SalesForce CRM identifiers. Fully audit-trailed via INSERT/UPDATE/DELETE triggers to History.BackOfficeCustomer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | CID (INT, CLUSTERED PK) |
| **Partition** | No (stored ON [MAIN] with DATA_COMPRESSION=PAGE) |
| **Indexes** | 6 active (1 clustered PK + 5 NC including 2 filtered) |

---

## 1. Business Meaning

BackOffice.Customer is the operational profile layer for every customer account on the platform. While Customer.CustomerStatic holds personal identity data (name, email, country), BackOffice.Customer holds the regulatory, compliance, and operational state: which regulation governs the account, what KYC verification level has been achieved, which sales agent is assigned, whether the account is an affiliate, what MiFID II categorization applies, and whether Enhanced Due Diligence is required.

This is eToro's primary customer governance table - the one that tells the BackOffice system how to treat each customer. It has 50 columns covering every dimension of customer state visible to BackOffice agents: regulatory (RegulationID, DesignatedRegulationID), compliance (VerificationLevelID, KycState, IsEDD, WorldCheckID, GDCCheckID, EvMatchStatus, EIDStatusID), sales (SalesStatusID, ManagerID, FTDPoolManagerID), product eligibility (AccountTypeID, FXEligibilityDate, HasWallet, IsCopyBlocked), and regulatory categorization (MifidCategorizationID, AsicClassificationID, SeychellesCategorizationID, TradingRiskStatusID).

**Scale**: 18.744M rows as of 2026-03-17 - one per CID. 99.3% are AccountTypeID=1 (real retail accounts). 46.9% are Verified. 47.1% have VerificationLevelID=3 (fully KYC'd). CySEC (39.4%) and BVI (38.9%) are the dominant regulations.

**Full audit trail**: Three triggers (CustomerHistoryInsert, CustomerHistoryUpdate, CustomerHistoryDelete) maintain a complete history in History.BackOfficeCustomer with ValidFrom/ValidTo timestamps. RegulationID changes also write to BackOffice.RegulationChangeLog.

---

## 2. Business Logic

### 2.1 Regulatory Assignment and TradingRiskStatusID

**What**: Each customer is assigned to one regulatory entity (RegulationID) which determines applicable leverage limits, investor protection rules, and compliance requirements. TradingRiskStatusID is a computed column deriving the effective trading risk tier from the regulation + categorization combination.

**Columns Involved**: `RegulationID`, `DesignatedRegulationID`, `MifidCategorizationID`, `AsicClassificationID`, `SeychellesCategorizationID`, `TradingRiskStatusID`

**Rules**:
- RegulationID distribution: CySEC=7.39M, BVI=7.30M, FCA=1.17M, None=0.85M, eToroUS=0.67M, FSA Seychelles=339K, ASIC=320K, ASIC&GAML=292K, FinCEN=121K, FinCEN+FINRA=105K, FINRAONLY=66K, NFA=61K, FSRA=47K, NYDFS+FINRA=4K, MAS=3.7K.
- DesignatedRegulationID: A secondary/override regulation for accounts subject to multiple jurisdictions (e.g., an Australian resident trading under CySEC but subject to DesignatedRegulationID=ASIC constraints).
- TradingRiskStatusID computed column logic (always evaluated, never stored manually):
  - Value 4 (lowest protection): QA/Demo databases (hardcoded), SeychellesCategorizationID=2, catch-all else clause.
  - Value 3 (standard retail): SeychellesCategorizationID=0, DesignatedRegulationID=11 (MAS?), some ASIC scenarios (AsicClassificationID NULL or =4), eToro EU/Cyprus Retail (RegulationID=1/2 with MifidCategorizationID=1).
  - Value 2 (professional): RegulationID=5 (FCA) with MifidCategorizationID=5, or eToro EU/Cyprus with MifidCategorizationID=5.
  - Value 1 (highest protection/eligible counterparty): MifidCategorizationID=4, or eToro EU/Cyprus with MifidCategorizationID=4.
- TradingRiskStatusID distribution: 3=88.3%, 4=9.3%, 1=2.4%, 2=0.01%.
- RegulationChangeDate: updated by trigger whenever RegulationID changes (tracks when the account moved between regulatory entities).

### 2.2 KYC Verification Levels

**What**: Each customer progresses through KYC stages that determine what financial services they can access.

**Columns Involved**: `VerificationLevelID`, `Verified`, `KycState`, `DocumentStatusID`, `PhoneVerifiedID`, `EIDStatusID`, `EvMatchStatus`

**Rules**:
- VerificationLevelID: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). FK to Dictionary.VerificationLevel.
- Verified bit: 1 if customer has passed identity verification. 46.9% verified. NOTE: a customer can have Verified=1 while VerificationLevelID<3 if they were verified under an older process.
- KycState: A state machine (DEFAULT 0) tracking the customer's current KYC process stage. Values defined in application layer.
- DocumentStatusID: Current state of the customer's document review queue.
- PhoneVerifiedID: Result of phone number verification.
- EIDStatusID: Electronic ID verification status (FK to Dictionary.EIDStatus).
- EvMatchStatus: Electronic verification match result (AI vendor matching score/decision).
- IsEDD: 1 if Enhanced Due Diligence is required (AML indicator). 23,944 customers (0.13%) have IsEDD=1.

### 2.3 MiFID II Categorization

**What**: Classifies customers under MiFID II investor protection rules, determining leverage limits, warning requirements, and product access.

**Columns Involved**: `MifidCategorizationID`, `TradingRiskStatusID`

**Rules**:
- MifidCategorizationID=1 (Retail): 97.3% of customers. Highest investor protection, lowest leverage, full disclosure requirements.
- MifidCategorizationID=4 (Eligible Counterparty): 2.6% - institutional clients. Least regulatory protection, professional treatment.
- MifidCategorizationID=5 (Professional): 0.03% - professionally assessed traders. Reduced protection, higher leverage.
- MifidCategorizationID=2, 3 (sub-categories or transitional states): 0.08% combined.
- FK to Dictionary.MifidCategorization. DEFAULT=1 (Retail).
- Drives TradingRiskStatusID computation (see Section 2.1).

### 2.4 Sales Agent Assignment

**What**: BackOffice agents are assigned to customers for relationship management and sales support.

**Columns Involved**: `ManagerID`, `PreviousManagerID`, `FTDPoolManagerID`, `SalesStatusID`

**Rules**:
- ManagerID: Current assigned sales/service agent. FK to BackOffice.Manager. NULL for unassigned customers.
- PreviousManagerID: Last assigned agent before the current reassignment. Preserved for audit trail.
- FTDPoolManagerID: The agent credited with the customer's first deposit (FTD). Used for sales compensation calculations.
- SalesStatusID: Current stage in the sales pipeline (FK to Dictionary.SalesStatus). DEFAULT=0.
- All three Manager FKs are WITH CHECK - only valid ManagerIDs accepted.

### 2.5 Complete Audit Trail via Three Triggers

**What**: All changes to BackOffice.Customer are recorded in History.BackOfficeCustomer for compliance and investigation.

**Rules**:
- CustomerHistoryInsert: On INSERT, writes the new row to History.BackOfficeCustomer with ValidFrom=GETUTCDATE(), ValidTo='30000101' (far-future sentinel = current record).
- CustomerHistoryDelete: On DELETE, closes the last History record (ValidTo=GETDATE()).
- CustomerHistoryUpdate: On UPDATE of any significant column:
  1. Closes the previous history record: UPDATE History.BackOfficeCustomer SET ValidTo=GETUTCDATE() WHERE CustomerHistoryID = last_version.
  2. Inserts a new current record: ValidFrom=GETUTCDATE(), ValidTo='30000101'.
  3. If RegulationID changed: updates RegulationChangeDate and inserts into BackOffice.RegulationChangeLog.
- Columns tracked by the UPDATE trigger: CID, SalesStatusID, ManagerID, IsAffiliate, Cleared, Verified, PreviousManagerID, FXEligibilityDate, AffiliateManagerID, CashoutFeeGroupID, AccountTypeID, MasterAccountCID, ManagerPermitID, ThirdPartyManagerComment, GuruStatusID, VerificationLevelID, RegulationID, AcceptanceStatusID, DocumentStatusID, PhoneVerifiedID, AcceptanceStatusChanginManagerID, GDCCheckID, SuitabilityTestStatusID, EvMatchStatus, Lei, MifidCategorizationID, DesignatedRegulationID, AMLComment, RiskClassificationID, HasWallet, SalesForceContactID, SalesForceAccountID, AsicClassificationID, SeychellesCategorizationID.

### 2.6 AMLComment Auto-Date Prefix

**What**: The CustomerHistoryUpdate trigger automatically prepends a date prefix to AMLComment entries that don't already start with a date.

**Rules**:
- When AMLComment is updated, the trigger checks if it already starts with a date pattern `20YYMMDD`.
- If not: prepends `YYYYMMDD ` (8-char date + space) to the comment using CONCAT(Format(GetUTCDate(),'yyyyMMdd '), ...).
- If the INSERT trigger accidentally sets a date-prefixed value, the UPDATE trigger strips the `#` character (the 9th char) from the comment.
- This creates a timestamped audit trail within the free-text AML comment field.
- AMLComment can hold up to 8,000 chars (varchar(8000)).

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows (2026-03-17) | 18.744M |
| AccountTypeID=1 (real) | 18.614M (99.3%) |
| Verified=1 | 8.797M (46.9%) |
| VerificationLevelID=3 (full KYC) | 8.829M (47.1%) |
| IsEDD=1 (Enhanced Due Diligence) | 23,944 (0.13%) |
| HasWallet=1 (eToro wallet) | 3,554 (0.019%) |
| IsAffiliate=1 | 22 |
| CopyBlocked=1 | 0 |
| Top regulation: CySEC | 7.394M (39.4%) |
| Second regulation: BVI | 7.304M (38.9%) |
| MifidCategorizationID=1 (Retail) | 18.239M (97.3%) |
| TradingRiskStatusID=3 (standard) | 16.548M (88.3%) |
| TradingRiskStatusID=1 (elite) | 458K (2.4%) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer account ID. Clustered PK. FK (WITH CHECK) to Customer.CustomerStatic(CID). One row per account. |
| 2 | SalesStatusID | int | NO | 0 | VERIFIED | Stage in the sales pipeline. FK (WITH CHECK) to Dictionary.SalesStatus. DEFAULT=0. |
| 3 | ManagerID | int | YES | - | VERIFIED | Currently assigned BackOffice sales/service agent. FK (WITH CHECK) to BackOffice.Manager. NULL = unassigned. Indexed with CID for agent-level customer queries. |
| 4 | IsAffiliate | bit | NO | 0 | VERIFIED | 1 if this customer account is also an affiliate (partner who refers other customers). Only 22 affiliate-customers exist on the platform. |
| 5 | Cleared | bit | NO | 0 | VERIFIED | Financial clearance flag indicating the customer's account has been reviewed and cleared for specific operations (e.g., withdrawal processing). |
| 6 | Verified | bit | NO | 0 | VERIFIED | Identity verification flag. 1 = customer has passed KYC identity check. 46.9% of accounts verified. May differ from VerificationLevelID (legacy field). |
| 7 | FTDPoolManagerID | int | YES | - | VERIFIED | BackOffice agent credited with this customer's first-time deposit (FTD) for sales attribution and compensation calculations. FK (WITH CHECK) to BackOffice.Manager. |
| 8 | PreviousManagerID | int | YES | - | VERIFIED | The agent assigned before the most recent reassignment. FK (WITH CHECK) to BackOffice.Manager. Preserved for audit. |
| 9 | FXEligibilityDate | datetime | YES | - | CODE-BACKED | Date when the customer became eligible for FX/leveraged product trading. NULL if not yet eligible or not applicable. |
| 10 | AffiliateManagerID | int | YES | - | VERIFIED | FK to Dictionary.UserGroup - the affiliate user group this customer was referred by. Despite the name, references UserGroup not Manager. |
| 11 | CashoutFeeGroupID | int | YES | - | VERIFIED | FK (WITH CHECK) to Dictionary.CashoutFeeGroup. Determines which withdrawal fee schedule applies to this customer. NULL = default fee group. |
| 12 | ChangePassword | bit | YES | - | NAME-INFERRED | Flag prompting the customer to change their password on next login. NULL treated as false. |
| 13 | RiskStatusID | int | YES | - | CODE-BACKED | Legacy single-value risk status. Distinct from the multi-row BackOffice.CustomerRisk (which allows multiple simultaneous risk flags). May reflect a legacy consolidated risk status code. |
| 14 | isEmployeeAccount | bit | YES | - | VERIFIED | 1 if this is an eToro employee's personal trading account. Flags employee accounts for special monitoring and compliance checks. |
| 15 | AccountTypeID | tinyint | NO | 1 | VERIFIED | Customer account classification. DEFAULT=1 (real retail account). Distribution: 1=18.614M, 0=44K, 2=37K, 6=17K, others <6K. The filtered NC index on AccountTypeID=9 suggests type 9 is a frequently-queried special account type. |
| 16 | MasterAccountCID | int | YES | - | VERIFIED | For sub-accounts: the CID of the master/parent account. NULL for standalone accounts. Supports multi-account hierarchies. |
| 17 | ManagerPermitID | int | NO | 1 | CODE-BACKED | Permission level governing what the assigned manager can do with this customer account. DEFAULT=1. Distinct from ManagerToPermission (which is agent-wide). |
| 18 | ThirdPartyManagerComment | varchar(255) | YES | - | CODE-BACKED | Free-text note about the customer's third-party management relationship (e.g., managed account arrangement). Visible in the BackOffice customer header (via GetCustomerHeader). |
| 19 | GuruStatusID | int | YES | - | VERIFIED | FK (WITH CHECK) to Dictionary.GuruStatus. eToro's Popular Investor/Guru program status - whether the customer is an active copy trading strategy provider. |
| 20 | RiskClassificationID | int | YES | - | VERIFIED | FK (WITH CHECK) to Dictionary.RiskClassification. Operational risk tier assigned by risk management. Tracked in UPDATE trigger audit. |
| 21 | AcceptanceStatusID | tinyint | NO | 0 | VERIFIED | FK (WITH CHECK) to Dictionary.AcceptanceStatus. Customer onboarding acceptance state (e.g., pending review, accepted, rejected). DEFAULT=0. |
| 22 | VerificationLevelID | int | NO | 0 | VERIFIED | KYC verification level. FK (WITH CHECK) to Dictionary.VerificationLevel. Values: 0=unverified (34.2%), 1=partial (12.4%), 2=intermediate (6.2%), 3=fully verified (47.1%). DEFAULT=0. Indexed for compliance reporting. |
| 23 | RegulationID | int | NO | 0 | VERIFIED | Regulatory entity governing this account. FK (WITH CHECK) to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update and RegulationChangeLog insert. DEFAULT=0. |
| 24 | DocumentStatusID | int | YES | - | VERIFIED | Current state of the customer's KYC document submission and review queue. NULL if no documents submitted. |
| 25 | PhoneVerifiedID | int | YES | - | CODE-BACKED | Result code of phone number verification process. NULL if not yet attempted. |
| 26 | AcceptanceStatusChanginManagerID | int | YES | - | CODE-BACKED | ManagerID of the BackOffice agent who last changed the AcceptanceStatus. Note: column name has a typo ("Changin" instead of "Changing"). |
| 27 | GDCCheckID | int | NO | 0 | VERIFIED | FK (WITH CHECK) to Dictionary.GDCCheck. Gambling/debt counselling check status. Required under some regulatory frameworks (e.g., South African FAIS). DEFAULT=0. |
| 28 | RegulationChangeDate | datetime | YES | - | VERIFIED | Timestamp when RegulationID was last changed. Updated automatically by the CustomerHistoryUpdate trigger on RegulationID changes. NULL if never changed since account creation. |
| 29 | IsCopyBlocked | bit | YES | - | VERIFIED | 1 if the customer is blocked from copy trading (copying other traders). 0 in all 18.744M current rows - feature exists but currently unused/not enforced. |
| 30 | SuitabilityTestStatusID | int | YES | - | VERIFIED | MiFID II appropriateness/suitability test result. NULL if test not completed. FK to Dictionary (implied). Required for complex product access under MiFID II. |
| 31 | WorldCheckID | tinyint | NO | 0 | VERIFIED | FK (WITH CHECK) to Dictionary.WorldCheck. Refinitiv/LSEG World-Check sanctions and PEP (Politically Exposed Person) screening result. DEFAULT=0. |
| 32 | KycState | int | NO | 0 | VERIFIED | KYC process state machine value. DEFAULT=0 (initial state). Application-side enum drives the states. |
| 33 | VerifiedBy | int | YES | - | CODE-BACKED | System or vendor ID that performed the identity verification (e.g., 1=manual BackOffice, 2=Onfido, 3=Au10tix). |
| 34 | VerifiedByProvider | int | YES | - | CODE-BACKED | Provider/entity under which the verification was performed. Distinguishes verification done under different regulatory entities. |
| 35 | IsEDD | bit | NO | 0 | VERIFIED | Enhanced Due Diligence required flag. 1 = customer requires deeper AML/KYC investigation (e.g., PEP, high-risk country, large transactions). 23,944 customers (0.13%) flagged. DEFAULT=0. |
| 36 | EvMatchStatus | int | YES | - | VERIFIED | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. |
| 37 | Lei | nvarchar(50) | YES | - | VERIFIED | Legal Entity Identifier for corporate accounts. ISO 17442 standard 20-character identifier. NULL for retail (natural person) accounts. Added 2017-11-15 for corporate account support (ticket 49513_OPS0351). |
| 38 | AMLComment | varchar(8000) | YES | - | VERIFIED | AML team free-text notes about this customer. Automatically date-prefixed by CustomerHistoryUpdate trigger when updated (prepends YYYYMMDD ). Contains investigation findings, source of funds notes, PEP status explanations. Up to 8,000 chars. |
| 39 | RiskComment | varchar(8000) | YES | - | CODE-BACKED | Risk team free-text notes. Similar to AMLComment but for risk (not AML) observations. NOT tracked by the UPDATE trigger (excluded from History). Up to 8,000 chars. |
| 40 | MifidCategorizationID | int | NO | 1 | VERIFIED | MiFID II investor classification. FK (WITH CHECK) to Dictionary.MifidCategorization. Values: 1=Retail (97.3%), 4=Eligible Counterparty (2.6%), 5=Professional (0.03%), 2/3=sub-categories. DEFAULT=1 (Retail). Key input to TradingRiskStatusID computation. |
| 41 | DesignatedRegulationID | int | YES | - | VERIFIED | FK (WITH CHECK) to Dictionary.Regulation. Secondary/override regulation for accounts subject to multiple jurisdictions. Used in TradingRiskStatusID computation (e.g., Australian residents under CySEC with DesignatedRegulationID=ASIC). |
| 42 | HasWallet | bit | YES | 0 | VERIFIED | 1 if the customer has an active eToro Money wallet linked to their trading account. DEFAULT=0. 3,554 customers (0.019%) have a wallet. Filtered NC index for wallet-holder queries. |
| 43 | SalesForceContactID | nvarchar(18) | YES | - | VERIFIED | Salesforce CRM Contact record ID (18-char Salesforce ID). Links the trading account to the SF Contact. NULL if not yet synced to SF. |
| 44 | SalesForceAccountID | nvarchar(18) | YES | - | VERIFIED | Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account (company/household). NULL if not yet synced. |
| 45 | AsicClassificationID | int | YES | - | VERIFIED | ASIC (Australian Securities & Investments Commission) customer classification. NULL for non-ASIC regulated accounts. Used in TradingRiskStatusID computation for Australian customers. |
| 46 | SeychellesCategorizationID | int | YES | - | VERIFIED | Customer classification under Seychelles FSA regulation. NULL for non-Seychelles accounts. Used in TradingRiskStatusID computation: 0=standard, 1=protected/retail, 2=non-protected. |
| 47 | TradingRiskStatusID | computed | NO | - | VERIFIED | **Computed (NEVER store directly)**. Derives effective trading risk tier from regulation + categorization. Values: 1=Eligible Counterparty/Elite (highest leverage, least protection), 2=Professional (reduced protection), 3=Standard Retail (88.3%), 4=Default/QA. Formula depends on DB name, SeychellesCategorizationID, DesignatedRegulationID, RegulationID, MifidCategorizationID, AsicClassificationID. Added 2022-08-11 (COINF-1394). |
| 48 | EIDStatusID | int | YES | - | VERIFIED | FK (WITH CHECK) to Dictionary.EIDStatus. Electronic ID verification status from identity document scanning vendors. NULL if not yet processed. |
| 49 | OnboardingRiskClassificationID | int | YES | - | CODE-BACKED | Risk classification assigned at the time of customer onboarding (initial risk assessment). May differ from RiskClassificationID (ongoing risk). |
| 50 | AcceptanceStatusID (tinyint) | - | - | - | - | *(see #21 above)* |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (WITH CHECK) | Account identity anchor |
| ManagerID | BackOffice.Manager | FK (WITH CHECK) | Currently assigned agent |
| PreviousManagerID | BackOffice.Manager | FK (WITH CHECK) | Previous assigned agent |
| FTDPoolManagerID | BackOffice.Manager | FK (WITH CHECK) | Agent credited with FTD |
| SalesStatusID | Dictionary.SalesStatus | FK (WITH CHECK) | Sales pipeline stage |
| AcceptanceStatusID | Dictionary.AcceptanceStatus | FK (WITH CHECK) | Onboarding acceptance state |
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup | FK (WITH CHECK) | Withdrawal fee tier |
| GuruStatusID | Dictionary.GuruStatus | FK (WITH CHECK) | Popular Investor program status |
| RiskClassificationID | Dictionary.RiskClassification | FK (WITH CHECK) | Risk tier |
| MifidCategorizationID | Dictionary.MifidCategorization | FK (WITH CHECK) | MiFID II investor category |
| RegulationID | Dictionary.Regulation | FK (WITH CHECK) | Primary regulatory entity |
| DesignatedRegulationID | Dictionary.Regulation | FK (WITH CHECK) | Secondary/override regulation |
| VerificationLevelID | Dictionary.VerificationLevel | FK (WITH CHECK) | KYC level achieved |
| GDCCheckID | Dictionary.GDCCheck | FK (WITH CHECK) | Debt counselling check result |
| WorldCheckID | Dictionary.WorldCheck | FK (WITH CHECK) | Sanctions/PEP screening result |
| AffiliateManagerID | Dictionary.UserGroup | FK (WITH CHECK) | Referring affiliate user group |
| EIDStatusID | Dictionary.EIDStatus | FK (WITH CHECK) | Electronic ID verification status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CustomerHistoryInsert trigger | CID | AUDIT WRITER | All INSERTs mirrored to History.BackOfficeCustomer |
| CustomerHistoryUpdate trigger | CID | AUDIT WRITER | All significant UPDATEs mirrored to History.BackOfficeCustomer |
| CustomerHistoryDelete trigger | CID | AUDIT WRITER | All DELETEs close History.BackOfficeCustomer records |
| History.BackOfficeCustomer | CID | AUDIT TARGET | Stores full change history with ValidFrom/ValidTo |
| BackOffice.RegulationChangeLog | CID | AUDIT TARGET | RegulationID change events |
| BackOffice.GetCustomerHeader | CID | READER | Customer overview panel - AccountTypeID, VerificationLevelID, RegulationID, ThirdPartyManagerComment |
| BackOffice.KYC.AddKYC | CID | MODIFIER | Updates RegulationID on KYC upsert |
| BackOffice.CustomerAcceptance | CID | MODIFIER | Updates AcceptanceStatusID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Customer (table)
- FK targets: Customer.CustomerStatic, BackOffice.Manager (x3), 14 Dictionary tables
- Triggers write to: History.BackOfficeCustomer, BackOffice.RegulationChangeLog
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK on CID - account identity anchor |
| BackOffice.Manager | Table | FK on ManagerID, PreviousManagerID, FTDPoolManagerID |
| Dictionary.SalesStatus | Table | FK on SalesStatusID |
| Dictionary.AcceptanceStatus | Table | FK on AcceptanceStatusID |
| Dictionary.CashoutFeeGroup | Table | FK on CashoutFeeGroupID |
| Dictionary.GuruStatus | Table | FK on GuruStatusID |
| Dictionary.RiskClassification | Table | FK on RiskClassificationID |
| Dictionary.MifidCategorization | Table | FK on MifidCategorizationID |
| Dictionary.Regulation | Table | FK on RegulationID and DesignatedRegulationID |
| Dictionary.VerificationLevel | Table | FK on VerificationLevelID |
| Dictionary.GDCCheck | Table | FK on GDCCheckID |
| Dictionary.WorldCheck | Table | FK on WorldCheckID |
| Dictionary.UserGroup | Table | FK on AffiliateManagerID |
| Dictionary.EIDStatus | Table | FK on EIDStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.BackOfficeCustomer | Table | Audit history - receives all changes via triggers |
| BackOffice.RegulationChangeLog | Table | Regulation change events |
| BackOffice.GetCustomerHeader | Procedure | READER - customer overview panel |
| BackOffice.CustomerAcceptance | Procedure | MODIFIER - acceptance status update |
| BackOffice.GetCustomerByCID | Procedure | READER |
| BackOffice.GetBlockedCustomers | Procedure | READER |
| BackOffice.GetRiskExposureReportPCIVersion | Procedure | READER |
| BackOffice.GetRegistrationReport | Procedure | READER |
| BackOffice.GetUnapprovedWithdrawRequests | Procedure | READER |
| BackOffice.GetWithdrawRequests | Procedure | READER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BCST | CLUSTERED PK | CID ASC | - | - | Active (FILLFACTOR=90, PAGE compressed, ON [MAIN]) |
| IDX_BOCust_AccountTypeID | NC | AccountTypeID ASC | CID | - | Active (FILLFACTOR=95, PAGE compressed) |
| Idx_BackOffice_Customer_ManagerID | NC | ManagerID ASC, CID ASC | - | - | Active (FILLFACTOR=90, PAGE compressed) |
| Idx_BackOffice_Customer_VerificationLevelID | NC | VerificationLevelID ASC | CID | - | Active (FILLFACTOR=90, PAGE compressed) |
| NonClusteredIndex-AccountType | NC (filtered) | AccountTypeID ASC | - | WHERE AccountTypeID=9 | Active (FILLFACTOR=95, uncompressed) |
| ix_BackOfficeCustomerHasWallet | NC (filtered) | HasWallet ASC | - | WHERE HasWallet=1 | Active (FILLFACTOR=95, PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BCST | PK | CID uniqueness |
| FK_CCST_BCST | FK (WITH CHECK) | CID -> Customer.CustomerStatic(CID) |
| FK_BMNG_BCST | FK (WITH CHECK) | ManagerID -> BackOffice.Manager |
| FK_BMNP_BCST | FK (WITH CHECK) | FTDPoolManagerID -> BackOffice.Manager |
| FK_BMNG_BCST_P | FK (WITH CHECK) | PreviousManagerID -> BackOffice.Manager |
| FK_DSLS_BCST | FK (WITH CHECK) | SalesStatusID -> Dictionary.SalesStatus |
| FK_DAS_BCST | FK (WITH CHECK) | AcceptanceStatusID -> Dictionary.AcceptanceStatus |
| BCDC | FK (WITH CHECK) | CashoutFeeGroupID -> Dictionary.CashoutFeeGroup |
| BOCGuruStatus | FK (WITH CHECK) | GuruStatusID -> Dictionary.GuruStatus |
| BOCRiskClassification | FK (WITH CHECK) | RiskClassificationID -> Dictionary.RiskClassification |
| FK_BCST_MifidCategorizationID | FK (WITH CHECK) | MifidCategorizationID -> Dictionary.MifidCategorization |
| FK_BC_RegulationID_P | FK (WITH CHECK) | RegulationID -> Dictionary.Regulation |
| FK_BC_DesignatedRegulationID | FK (WITH CHECK) | DesignatedRegulationID -> Dictionary.Regulation |
| FK_BC_VerificationLevelID_P | FK (WITH CHECK) | VerificationLevelID -> Dictionary.VerificationLevel |
| FK_BackOfficeCustomer_GDCCheckID | FK (WITH CHECK) | GDCCheckID -> Dictionary.GDCCheck |
| FK_Dic_WorldCheck | FK (WITH CHECK) | WorldCheckID -> Dictionary.WorldCheck |
| FK_DUGP_BCST | FK (WITH CHECK) | AffiliateManagerID -> Dictionary.UserGroup |
| FK_Customer_EIDStatusID | FK (WITH CHECK) | EIDStatusID -> Dictionary.EIDStatus |
| BCST_SALESSTATUS through multiple DEFAULTs | DEFAULT | SalesStatusID=0, IsAffiliate=0, Cleared=0, Verified=0, AccountTypeID=1, ManagerPermitID=1, AcceptanceStatusID=0, VerificationLevelID=0, RegulationID=0, GDCCheckID=0, WorldCheckID=0, KycState=0, IsEDD=0, MifidCategorizationID=1, HasWallet=0 |

### 7.3 Triggers

| Trigger | Event | Action |
|---------|-------|--------|
| CustomerHistoryInsert | INSERT | Mirrors new row to History.BackOfficeCustomer (ValidFrom=now, ValidTo='30000101') |
| CustomerHistoryUpdate | UPDATE | Closes previous History record (ValidTo=now), inserts new current record. Special handling: RegulationID changes -> updates RegulationChangeDate + inserts RegulationChangeLog. AMLComment auto-date-prefix logic. |
| CustomerHistoryDelete | DELETE | Closes last History.BackOfficeCustomer record (ValidTo=GETDATE()) |

---

## 8. Sample Queries

### 8.1 Get full BackOffice profile for a customer
```sql
SELECT
    bc.CID,
    dr.Name AS Regulation,
    dv.Name AS VerificationLevel,
    ds.Name AS SalesStatus,
    da.Name AS AcceptanceStatus,
    dm.MifidCategorizationName,
    bc.TradingRiskStatusID,
    bc.AccountTypeID,
    m.FirstName + ' ' + m.LastName AS AssignedAgent,
    bc.Verified,
    bc.IsEDD,
    bc.KycState,
    bc.AMLComment,
    bc.RegulationChangeDate,
    bc.SalesForceContactID
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Dictionary.Regulation dr WITH (NOLOCK) ON dr.ID = bc.RegulationID
JOIN Dictionary.VerificationLevel dv WITH (NOLOCK) ON dv.ID = bc.VerificationLevelID
JOIN Dictionary.SalesStatus ds WITH (NOLOCK) ON ds.SalesStatusID = bc.SalesStatusID
JOIN Dictionary.AcceptanceStatus da WITH (NOLOCK) ON da.AcceptanceStatusID = bc.AcceptanceStatusID
JOIN Dictionary.MifidCategorization dm WITH (NOLOCK) ON dm.MifidCategorizationID = bc.MifidCategorizationID
LEFT JOIN BackOffice.Manager m WITH (NOLOCK) ON m.ManagerID = bc.ManagerID
WHERE bc.CID = 12345
```

### 8.2 Find customers pending full KYC verification
```sql
SELECT
    bc.CID,
    dr.Name AS Regulation,
    bc.VerificationLevelID,
    bc.AcceptanceStatusID,
    bc.DocumentStatusID
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Dictionary.Regulation dr WITH (NOLOCK) ON dr.ID = bc.RegulationID
WHERE bc.VerificationLevelID < 3
  AND bc.Verified = 0
ORDER BY bc.CID
```

### 8.3 Regulation distribution summary
```sql
SELECT
    dr.Name AS Regulation,
    COUNT(*) AS CustomerCount,
    SUM(CASE WHEN bc.Verified = 1 THEN 1 ELSE 0 END) AS VerifiedCount,
    SUM(CASE WHEN bc.IsEDD = 1 THEN 1 ELSE 0 END) AS EDDCount
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Dictionary.Regulation dr WITH (NOLOCK) ON dr.ID = bc.RegulationID
GROUP BY dr.Name
ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

Jira: 49513_OPS0351 (2017-11-15 - Lei column for corporate accounts), ticket 51497 (2018-05-10 - MifidCategorizationID added by Ran Ovadia), RD-2128/2221 (2019-01 - AML comment audit to BI DB), RD-6902/8453 (2019-05-30 - removed automated date from AMLComment), COAIL-2262/2482 (2021-03-14 - Regulation Categorization), COINF-1394 (2022-08-11 - TradingRiskStatusID column added/updated by Yulia Kramer).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 9.4/10, Logic: 9.5/10, Relationships: 9.3/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 28 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: Jira tickets 49513, 51497, RD-2128, RD-6902, COAIL-2262, COINF-1394 | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Customer | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.Customer.sql*
