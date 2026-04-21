# EXW_dbo.EXW_AML_Users_Report

> AML compliance reporting table for eToro Wallet users. One row per user per AML provider (699,852 rows, 699,692 distinct GCIDs). Integrates player status, country risk rank, screening results, crypto transfer activity, and an automated IsAMLProblematic flag that consolidates 7 risk conditions. Rebuilt daily by SP_EXW_UserSettingsWalletAllowance alongside EXW_UserSettingsWalletAllowance. Primary data source for the AML team's daily risk review.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (AML Compliance Report) |
| **Production Source** | DWH_dbo.Dim_Customer + EXW_DimUser_Enriched + EXW_UserSettingsWalletAllowance + BI_DB sources |
| **Writer SP** | EXW_dbo.SP_EXW_UserSettingsWalletAllowance |
| **Refresh** | Daily; TRUNCATE + INSERT (full rebuild, co-written with EXW_UserSettingsWalletAllowance) |
| **Row Count** | 699,852 total; 699,692 distinct GCIDs (160 GCIDs appear twice — AML provider fan-out) |
| **Date Range** | UpdateDate: 2026-04-13; FirstTxDate/LastTxDate: varies |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_AML_Users_Report is the daily AML (Anti-Money Laundering) compliance snapshot for all eToro Wallet users. It is the primary dataset for the AML team's daily risk review workflow and external compliance reporting.

The table answers: **which Wallet users present AML risk today?** The `IsAMLProblematic` flag (1=risky, 0=clear) consolidates seven independent risk signals — player status, country risk rank, screening status, automated risk score, risk classification, wallet allowance, and age — into a single boolean. As of April 2026: 225,962 users (32.2%) are flagged as AML-problematic.

The table is primarily a wide denormalized view combining:
- **Identity and status** from EXW_DimUser_Enriched and Dim_Customer
- **Wallet access decision** from EXW_UserSettingsWalletAllowance
- **AML provider registration** from EXW_AMLProviderID
- **Country risk ranking** from Dim_Country.RiskGroupID
- **Crypto transaction activity** from EXW_FactTransactions
- **Automated risk score** from BI_DB_dbo.BI_DB_RiskClassification
- **Occupation and KYC data** from BI_DB_dbo.BI_DB_KYC_Panel
- **BackOffice CRM notes** from External_etoro_BackOffice_Customer
- **External screening service** from External_ScreeningService_Screening_UserScreening

No consuming SPs found in SSDT — this table is queried directly by AML team via reporting tools and ad-hoc queries.

**Key distributions** (as of April 2026):
- IsRealUser: RealUser=698,819 (99.9%), eTorian=901, TestUser=132
- IsAMLProblematic: 0=473,890 (67.8%), 1=225,962 (32.2%)
- CountryRankDescription: Open=659,246 (94.3%), No Business Allowed=20,079, High Risk EDD=10,930, Open For Existing=7,641
- RiskScoreName: Medium=507,152, NULL=145,442, High=37,721, Low=9,537
- CurrentPlayerStatus: Normal=591,025 (84.5%), Blocked=61,009, Blocked Upon Request=30,575
- ScreeningStatus (DWH): NoMatch=690,692 (98.8%), PendingInvestigation=7,875, RiskMatch=187, PEP=180

---

## 2. Business Logic

### 2.1 IsAMLProblematic Flag

**What**: Single composite AML risk flag. 1 = the user triggers at least one of seven AML risk conditions; 0 = clean across all conditions.

**Columns Involved**: IsAMLProblematic, PlayerStatusID, CountryRankID, ScreeningStatusID, RiskScoreName, RiskClassificationID, UserWalletAllowance, Age

**Rules** (OR logic — any single condition triggers 1):
| Condition | Values That Trigger Problematic |
|-----------|--------------------------------|
| PlayerStatusID | NOT IN (5=Normal, 1=Active, 12=Pending) |
| CountryRankID | ≠ 0 (any non-Open country rank) |
| ScreeningStatusID | NOT IN (0=NoMatch, 1=Cleared) |
| RiskScoreName | NOT IN ('Low', 'Medium') — i.e., High or NULL |
| RiskClassificationID | NOT IN (1, 2) |
| UserWalletAllowance | ≠ 'Allowed' (ReadOnly or NotAllowed) |
| Age | ≤ 25 OR ≥ 65 |

### 2.2 IsRealUser Classification

**What**: Categorizes each Wallet user into three mutually exclusive user types for AML scope filtering.

**Columns Involved**: IsRealUser, IsTestAccount (from EXW_DimUser), IsValidCustomer

**Rules**:
| Priority | IsRealUser | Condition |
|----------|-----------|-----------|
| 1 | TestUser | EXW_DimUser.IsTestAccount = 1 (132 users) |
| 2 | eTorian | Dim_Customer.IsValidCustomer = 0 (901 users) |
| 3 | RealUser | All other Wallet users (698,819 users) |

AML team should filter `IsRealUser = 'RealUser'` for production compliance reviews.

### 2.3 Country Risk Rank (CountryRankID / CountryRankDescription)

**What**: Country-level risk classification from Dim_Country.RiskGroupID, mapped to a human-readable description.

**Columns Involved**: CountryRankID, CountryRankDescription

**Rules**:
| CountryRankID | CountryRankDescription | User Count | Implication |
|--------------|----------------------|------------|-------------|
| 0 | Open | 659,246 | Standard country — no enhanced due diligence |
| 1 | No Business Allowed | 20,079 | EDD required; new business prohibited |
| 2 | Open For Existing Customers | 7,641 | Grandfathered existing customers only |
| 3 | High Risk clients flow -EDD | 10,930 | Enhanced Due Diligence required |
| NULL | NA | 1,956 | No RiskGroupID mapping found |

### 2.4 IsUS Flag

**What**: Binary indicator whether the user is subject to US regulatory requirements.

**Columns Involved**: IsUS, CountryID (from Dim_Customer)

**Rules**:
- `IsUS = 'Y'` when Dim_Customer.RegulationID IN (6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA) OR CountryID=219
- `IsUS = 'No'` otherwise
- Y=91,026 users (13.0%), No=608,826 (87.0%)

Note: CountryID=219 is Tuvalu — mapped to US for regulatory purposes (historical legacy encoding).

### 2.5 Activity Flags (HasCryptoTransfer, HasPayments, HasRiskCountryLogins)

**What**: Three binary flags capturing transaction and login risk signals from EXW_FactTransactions and Fact_CustomerAction.

**Columns Involved**: HasCryptoTransfer, HasPayments, HasRiskCountryLogins

**Rules**:
- `HasCryptoTransfer = 1`: GCID has at least one completed outbound crypto redeem (TranStatusID=2, IsRedeem=1, SenderAddress='0x5be786ad38f5846f605a8003550074cdfd4899a1', TransactionTypeID NOT IN 10/13). ~149,524 users (21.4%)
- `HasPayments = 1`: GCID has at least one completed payment transaction (IsPayment=1, TranStatusID=2). ~7,586 users (1.1%)
- `HasRiskCountryLogins = 1`: RealCID has a login (Fact_CustomerAction ActionTypeID=14) from a high-risk country (Dim_Country.IsHighRiskCountry=1) within the last 60 days. ~22,449 users (3.2%)

Note: HasCryptoTransfer uses a specific SenderAddress filter (0x5be786...) — this is a hardcoded wallet address filtering out pre-2021 Beta wallets. Only outbound transfers through this address are counted.

### 2.6 RelatedCIDs — Linked Account Detection

**What**: Identifies users who share the same biometric key combination, indicating potential linked or duplicate accounts.

**Columns Involved**: RelatedCIDs

**Rules**:
- Key = CONCAT(FirstName, LastName, BirthDate, Gender, Zip, CountryID) — same key across multiple GCIDs suggests the same person with multiple accounts
- RelatedCIDs = semicolon-concatenated GCID list of other users sharing the same key
- NULL when the user has no matches (most users)
- Not shown in AML report directly — used internally by the AML team to investigate account clusters

### 2.7 AML Provider Fan-Out (Non-1:1 GCID Rows)

**What**: The LEFT JOIN to EXW_AMLProviderID produces multiple rows for users registered with more than one AML provider.

**Columns Involved**: AMLProviderID, ProviderUserID, ProviderUserIDNormalized

**Impact**: 160 GCIDs have 2 rows (one per AML provider). Total rows = 699,852 vs 699,692 distinct GCIDs. Always use `SELECT DISTINCT GCID` or `GROUP BY GCID` when computing user-level counts from this table.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) / HEAP. Co-located with EXW_DimUser_Enriched and EXW_UserSettingsWalletAllowance (both HASH(GCID)). No CCI — avoid full table scans; filter on GCID or small aggregations.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Count of AML-problematic real users | `WHERE IsRealUser='RealUser' AND IsAMLProblematic=1` |
| High-risk country users with wallet access | `WHERE CountryRankID IN (1,3) AND UserWalletAllowance='Allowed'` |
| Users with PEP screening flag | `WHERE ScreeningStatus='PEP'` |
| Active high-risk score users | `WHERE RiskScoreName='High' AND PlayerStatusID IN (5,1,12)` |
| Users with crypto activity in high-risk countries | `WHERE HasCryptoTransfer=1 AND HasRiskCountryLogins=1` |
| User-level count (avoiding AML provider fan-out) | Always `COUNT(DISTINCT GCID)` not `COUNT(*)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | `EXW_DimUser.GCID = EXW_AML_Users_Report.GCID` | Supplement with full EXW user dimension |
| EXW_dbo.EXW_UserSettingsWalletAllowance | `GCID` | Cross-check wallet allowance with ClosingProject |

### 3.4 Gotchas

- **NOT 1:1 GCID**: 160 GCIDs appear twice (users with 2 AML providers). Never use `COUNT(*)` for user counts — always `COUNT(DISTINCT GCID)`
- **Two ScreeningStatus columns**: `ScreeningStatus` (col 20) = DWH internal screening from Dim_Customer.ScreeningStatusID; `ScreeningStatusExt` (col 51) = external screening service (BI_DB). They are different systems with different StatusIDs and may disagree
- **IsAMLProblematic includes age flags**: Users aged ≤25 or ≥65 are flagged as problematic regardless of other risk signals. This produces significant volume — young users are a large portion of the 225,962 flagged
- **HasCryptoTransfer SenderAddress hardcode**: Only transactions from address 0x5be786... are counted. This filters Beta pre-2021 legacy wallets. Cross-system comparisons should account for this filter
- **AMLComment/RiskComment are free text**: BackOffice CRM notes — may contain PII, non-standardized text, or legacy entries. Not suitable for automated categorization
- **Age is computed at INSERT time**: Age is DATEDIFF(YEAR, BirthDate, GETDATE()) — calculated once daily. Users who have a birthday between daily runs will have incorrect Age until the next run
- **HasRiskCountryLogins is 60-day rolling**: Based on Fact_CustomerAction.DateID ≥ GETDATE()-60 — window shifts daily; a user can move from 1 to 0 without any action if 60 days have passed
- **RiskScore NULL = not scored, not low**: NULL in RiskScoreName is counted as "NOT IN ('Low','Medium')" in IsAMLProblematic — 145,442 unscored users are therefore flagged as problematic
- **UpdateDate is truncate-and-insert timestamp**: All rows share the same UpdateDate per daily run

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki (Customer.CustomerStatic or BackOffice.Customer via Dim_Customer) |
| Tier 2 | Derived from SP code (computed, join-derived, renamed, or passthrough from a T2 intermediate) |
| Tier 3 | Inferred from column name, type, and context |
| Tier 4 | Best available — limited lineage confidence |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. HASH distribution key for this table. (Tier 1 — Customer.CustomerStatic) |
| 2 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 3 | Country | nvarchar(540) | YES | Denormalized country of residence text label from EXW_DimUser_Enriched.Country (Dim_Country.Name, joined on CountryID). Use CountryID for joins. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 4 | IsValidCustomer | int | YES | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used to distinguish real customers from eToro employees/interns (eTorians). (Tier 2 — SP_Dim_Customer) |
| 5 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. (Tier 1 — BackOffice.Customer) |
| 6 | JoinDate | date | YES | Date of first Wallet allocation. Derived as MIN(Allocated) per GCID from EXW_WalletInventory in SP_EXW_DimUser_Enriched. CAST to DATE. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 7 | PlayerStatusID | int | YES | Current player account status. FK to Dictionary.PlayerStatus. 1=Active, 5=Normal, 12=Pending. Values NOT IN (5,1,12) contribute to IsAMLProblematic=1. (Tier 1 — Customer.CustomerStatic) |
| 8 | CurrentPlayerStatus | varchar(100) | NOT NULL | Human-readable player status label from Dim_PlayerStatus.Name. Values: Normal (591,025), Blocked (61,009), Blocked Upon Request (30,575), Trade & MIMO Blocked (8,031), Block Deposit & Trading (6,752). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 9 | StatusChangeDate | datetime | YES | Date of most recent PlayerStatusID change, derived from LAG-based snapshot comparison in SP_EXW_DimUser_Enriched. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 10 | CountryByIP | varchar(100) | YES | Country of last known IP address from Dim_Country.Name, joined on Dim_Customer.CountryIDByIP. May differ from Country (country of residence). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 11 | PlayerStatusReason | varchar(540) | YES | Reason for the current player status change. From Dim_PlayerStatusReasons.Name joined on Dim_Customer.PlayerStatusReasonID. NULL if no reason recorded. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 12 | PlayerStatusSubReason | varchar(540) | YES | Sub-reason for the player status change. From Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName. NULL if no sub-reason recorded. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 13 | Regulation | varchar(100) | YES | Regulatory entity name from Dim_Regulation.Name, joined on EXW_DimUser_Enriched.RegulationID via DWHRegulationID. Use RegulationID for joins. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 14 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework. (Tier 1 — Customer.CustomerStatic) |
| 15 | RiskClassificationID | int | YES | Operational risk tier assigned by risk management. FK to Dictionary.RiskClassification. Values NOT IN (1,2) contribute to IsAMLProblematic=1. (Tier 1 — BackOffice.Customer) |
| 16 | IsUS | varchar(2) | NOT NULL | Y if user is subject to US regulatory requirements: RegulationID IN (6,7,8) OR CountryID=219. No otherwise. Y=91,026 users (13.0%). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 17 | Age | int | YES | Customer age in full years computed as DATEDIFF(YEAR, BirthDate, GETDATE()) at INSERT time. Age ≤25 or ≥65 contributes to IsAMLProblematic=1. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 18 | BirthDate | date | YES | Customer date of birth. CAST(BirthDate AS DATE) from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 19 | RiskStatus | varchar(540) | YES | Risk status label from Dim_RiskStatus.Name, joined on Dim_Customer.RiskStatusID. Legacy single-value risk status (distinct from multi-row BackOffice.CustomerRisk). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 20 | ScreeningStatus | varchar(540) | YES | DWH internal compliance screening status label from Dim_ScreeningStatus.Name. Values: NoMatch (690,692), PendingInvestigation (7,875), RiskMatch (187), PEP (180). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 21 | ScreeningStatusID | int | YES | DWH internal compliance screening status ID from Dim_Customer. Values NOT IN (0,1) contribute to IsAMLProblematic=1. Updated from ScreeningService in SP_Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 22 | RiskClassificationName | varchar(100) | YES | Operational risk classification label from Dim_RiskClassification.RiskClassificationName. Values: Medium (585,499), High (61,186), Low (26,214), Unacceptable (24). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 23 | ProviderUserIDNormalized | varchar(540) | YES | Base64-encoded GCID string with trailing '=' padding stripped. Used as external identifier for AML provider matching. NULL for users not registered with any AML provider (493,445 users). (Tier 2 — SP_EXW_AMLProviderID) |
| 24 | ProviderUserID | varchar(540) | YES | Raw base64-encoded GCID string (with '=' padding). Full AML provider user ID. NULL if not in EXW_AMLProviderID. (Tier 2 — SP_EXW_AMLProviderID) |
| 25 | AMLProviderID | int | YES | AML compliance provider identifier. Values: 1 (166,322 users), 3 (27,381), 4 (12,704), NULL (493,445 — not registered). Same GCID may appear twice if registered with 2 providers. (Tier 2 — SP_EXW_AMLProviderID) |
| 26 | IsRealUser | varchar(8) | NOT NULL | User type classification. Values: 'RealUser' (698,819), 'eTorian' (901), 'TestUser' (132). CASE logic: TestUser if IsTestAccount=1; eTorian if IsValidCustomer=0; else RealUser. Filter IsRealUser='RealUser' for production AML reviews. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 27 | UserWalletAllowance | nchar(50) | YES | Resolved Wallet access decision from EXW_UserSettingsWalletAllowance. Values: Allowed/ReadOnly/NotAllowed. UserWalletAllowance≠'Allowed' contributes to IsAMLProblematic=1. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 28 | AccountStatus | varchar(50) | YES | Account status label from Dim_AccountStatus.AccountStatusName, joined on Dim_Customer.AccountStatusID. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 29 | AccountType | varchar(50) | YES | Account type label from Dim_AccountType.Name, joined on Dim_Customer.AccountTypeID. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 30 | Club | varchar(50) | YES | Customer loyalty level label from Dim_PlayerLevel.Name, joined on Dim_Customer.PlayerLevelID. Values: Bronze, Silver, Gold, Platinum, Diamond. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 31 | FirstDepositDate | datetime | YES | Date of first deposit. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic in SP_Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 32 | EvMatchStatus | int | YES | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 — BackOffice.Customer) |
| 33 | ClosingProject | varchar(100) | YES | Wallet closure project identifier from EXW_UserSettingsWalletAllowance.Project (renamed). Project letters map to country-closure batches (A=31, B=35, C=15, D=4, etc.). NULL if user is not compensated. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 34 | CountryRankID | int | YES | Country risk rank ID from Dim_Country.RiskGroupID for the user's CountryID. 0=Open, 1=No Business Allowed, 2=Open For Existing, 3=High Risk EDD, NULL=not mapped. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 35 | AMLComment | varchar(8000) | YES | Free-text AML flag note from BackOffice CRM (External_etoro_BackOffice_Customer.AMLComment, joined on RealCID). NULL if no comment recorded. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 36 | RiskComment | varchar(8000) | YES | Free-text risk note from BackOffice CRM (External_etoro_BackOffice_Customer.RiskComment, joined on RealCID). NULL if no comment recorded. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 37 | CountryRankDescription | varchar(27) | NOT NULL | Human-readable country risk category. CASE on CountryRankID: 0=Open (659,246), 1=No Business Allowed (20,079), 2=Open For Existing Customers (7,641), 3=High Risk clients flow -EDD (10,930), else=NA (1,956). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 38 | Occupation | nvarchar(250) | YES | Customer's declared occupation from KYC Question 18 (Q18_AnswerText from BI_DB_KYC_Panel). Free-text field; NULL if the question was not answered. Excludes test accounts. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 39 | HasCryptoTransfer | int | NOT NULL | 1 if the user has a completed outbound crypto redemption via the designated Wallet address (TranStatusID=2, IsRedeem=1, SenderAddress='0x5be786...', TransactionTypeID NOT IN 10/13); 0 otherwise. ~149,524 users (21.4%). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 40 | HasPayments | int | NOT NULL | 1 if the user has at least one completed Wallet payment transaction (IsPayment=1, TranStatusID=2); 0 otherwise. ~7,586 users (1.1%). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 41 | HasRiskCountryLogins | int | NOT NULL | 1 if the user has logged in from a high-risk country (Dim_Country.IsHighRiskCountry=1) via Fact_CustomerAction (ActionTypeID=14) in the last 60 days; 0 otherwise. ~22,449 users (3.2%). 60-day rolling window. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 42 | IsAMLProblematic | int | NOT NULL | Composite AML risk flag. 1 if any of 7 conditions triggered: PlayerStatusID NOT IN (5,1,12), CountryRankID≠0, ScreeningStatusID NOT IN (0,1), RiskScoreName NOT IN ('Low','Medium'), RiskClassificationID NOT IN (1,2), UserWalletAllowance≠'Allowed', Age≤25 or Age≥65. 225,962 users (32.2%) flagged. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 43 | RelatedCIDs | nvarchar(max) | YES | Concatenated GCID list of users sharing the same biometric key (First+Last+BirthDate+Gender+Zip+CountryID). Indicates potential linked or duplicate accounts. NULL if no matches. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 44 | UpdateDate | datetime | NOT NULL | ETL timestamp set to GETDATE() at INSERT. All rows share the same UpdateDate per daily run. Current value: 2026-04-13. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 45 | RiskScore | int | YES | Automated AML risk score integer from BI_DB_dbo.BI_DB_RiskClassification (joined on RealCID). NULL if not yet scored (145,442 users). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 46 | RiskScore_Explanation | nvarchar(max) | YES | Free-text explanation of the automated AML risk score from BI_DB_RiskClassification. NULL if not scored. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 47 | RiskScoreName | varchar(56) | YES | Categorical label for the automated risk score: Low (9,537), Medium (507,152), High (37,721), NULL (145,442 — not scored). NULL treated as high-risk in IsAMLProblematic logic. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 48 | FirstTxDate | date | YES | Date of user's first successful crypto transaction through the designated Wallet sender address (MIN TranDate, TranStatusID=2, IsRedeem=1 filter). NULL if no qualifying transactions. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 49 | LastTxDate | date | YES | Date of user's most recent qualifying crypto transaction (MAX TranDate, same filter as FirstTxDate). NULL if no qualifying transactions. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 50 | ScreeningStatusID_Ext | int | YES | External screening service status ID from BI_DB_dbo.External_ScreeningService_Screening_UserScreening. Separate from the DWH internal ScreeningStatusID (col 21) — different system, different ID space. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 51 | ScreeningStatusExt | varchar(128) | YES | Human-readable label for ScreeningStatusID_Ext from Dim_ScreeningStatus.Name. Label for the external screening provider's result (not the DWH internal screening). (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 52 | ScreeningBeginTime_Ext | datetime | YES | Timestamp when the external screening session began for this user, from External_ScreeningService_Screening_UserScreening.BeginTime. (Tier 2 — SP_EXW_UserSettingsWalletAllowance) |
| 53 | WalletBalanceUSD | decimal(38,18) | YES | Total Wallet balance in USD from EXW_DimUser_Enriched.TotalBalanceUSD (SUM of BalanceUSD at max BalanceDateID from EXW_FinanceReportsBalancesNew). NULL if no balance record. (Tier 2 — SP_EXW_DimUser_Enriched) |

---

## 5. Lineage

See [`EXW_AML_Users_Report.lineage.md`](EXW_AML_Users_Report.lineage.md) for full column-level lineage.

**Tier Summary**: 8 Tier 1 | 45 Tier 2 | 0 Tier 3 | 0 Tier 4

| Source Object | Columns Sourced |
|---------------|----------------|
| EXW_dbo.EXW_DimUser_Enriched | GCID (T1), RealCID (T1), Country, IsValidCustomer, VerificationLevelID (T1), JoinDate, StatusChangeDate, WalletBalanceUSD |
| DWH_dbo.Dim_Customer | PlayerStatusID (T1), CountryID (T1), BirthDate (T1), EvMatchStatus (T1), RiskClassificationID (T1), ScreeningStatusID, FirstDepositDate, AccountStatusID, AccountTypeID, PlayerLevelID, RegulationID, CountryIDByIP, RiskStatusID |
| EXW_dbo.EXW_UserSettingsWalletAllowance | UserWalletAllowance, ClosingProject |
| EXW_dbo.EXW_AMLProviderID | ProviderUserIDNormalized, ProviderUserID, AMLProviderID |
| DWH_dbo.Dim_PlayerStatus | CurrentPlayerStatus |
| DWH_dbo.Dim_Country | CountryByIP, CountryRankID |
| DWH_dbo.Dim_Regulation | Regulation |
| DWH_dbo.Dim_RiskStatus | RiskStatus |
| DWH_dbo.Dim_ScreeningStatus | ScreeningStatus, ScreeningStatusExt |
| DWH_dbo.Dim_PlayerStatusReasons | PlayerStatusReason |
| DWH_dbo.Dim_PlayerStatusSubReasons | PlayerStatusSubReason |
| DWH_dbo.Dim_RiskClassification | RiskClassificationName |
| DWH_dbo.Dim_AccountStatus | AccountStatus |
| DWH_dbo.Dim_AccountType | AccountType |
| DWH_dbo.Dim_PlayerLevel | Club |
| BI_DB_dbo.External_etoro_BackOffice_Customer | AMLComment, RiskComment |
| BI_DB_dbo.BI_DB_KYC_Panel | Occupation |
| BI_DB_dbo.BI_DB_RiskClassification | RiskScore, RiskScore_Explanation, RiskScoreName |
| EXW_dbo.EXW_FactTransactions | HasCryptoTransfer, HasPayments, FirstTxDate, LastTxDate |
| DWH_dbo.Fact_CustomerAction + DWH_dbo.Dim_Country | HasRiskCountryLogins |
| BI_DB_dbo.External_ScreeningService_Screening_UserScreening | ScreeningStatusID_Ext, ScreeningBeginTime_Ext |
| (computed) | Age, IsUS, IsRealUser, CountryRankDescription, IsAMLProblematic, RelatedCIDs, UpdateDate |

---

## 6. Relationships

### Upstream (Sources)

| Object | Relationship |
|--------|-------------|
| EXW_dbo.EXW_DimUser | GCID/RealCID scope base via #user CTE |
| EXW_dbo.EXW_DimUser_Enriched | Main enrichment source (18+ columns) via LEFT JOIN on GCID |
| DWH_dbo.Dim_Customer | Customer master via #dim (WHERE HasWallet=1), INNER JOIN on RealCID |
| EXW_dbo.EXW_UserSettingsWalletAllowance | UserWalletAllowance + ClosingProject via LEFT JOIN on GCID |
| EXW_dbo.EXW_AMLProviderID | AML provider data via LEFT JOIN on GCID (fan-out risk for multi-provider users) |
| EXW_dbo.EXW_FactTransactions | Transaction activity via #txprep → #tx, #payment, #redeem CTEs |
| DWH_dbo.Fact_CustomerAction | Login history via #login → #riskCountryLogins |
| BI_DB_dbo.BI_DB_RiskClassification | Automated risk score via #riskscore (JOIN on RealCID) |
| BI_DB_dbo.BI_DB_KYC_Panel | Occupation from KYC Q18 via #occupation (JOIN on RealCID) |
| BI_DB_dbo.External_etoro_BackOffice_Customer | AML/Risk CRM notes via #amlcomment (JOIN on RealCID) |
| BI_DB_dbo.External_ScreeningService_Screening_UserScreening | External screening session via #UserScreening (JOIN on GCID) |
| DWH_dbo.Dim_* (10 tables) | Label resolution for player status, risk, account, country, regulation, etc. |

### Downstream (Consumers)

| Object | Relationship |
|--------|-------------|
| AML team — direct queries | No SSDT-tracked consuming SPs; table is queried directly via reporting tools and ad-hoc SQL |

### Co-written by Same SP

| Object | Relationship |
|--------|-------------|
| EXW_dbo.EXW_UserSettingsWalletAllowance | Written by the same SP (SP_EXW_UserSettingsWalletAllowance) before AML report part |

---

## 7. Sample Queries

```sql
-- AML risk profile: count real users by problematic flag and risk score tier
SELECT
    IsRealUser,
    IsAMLProblematic,
    RiskScoreName,
    COUNT(DISTINCT GCID) AS UserCount   -- DISTINCT to avoid AMLProvider fan-out
FROM EXW_dbo.EXW_AML_Users_Report
GROUP BY IsRealUser, IsAMLProblematic, RiskScoreName
ORDER BY IsRealUser, IsAMLProblematic DESC, UserCount DESC;
```

```sql
-- High-priority AML review list: real users with wallet access in high-risk countries
SELECT
    GCID,
    RealCID,
    Country,
    CountryRankDescription,
    UserWalletAllowance,
    RiskScoreName,
    ScreeningStatus,
    IsAMLProblematic,
    AMLComment
FROM EXW_dbo.EXW_AML_Users_Report
WHERE IsRealUser = 'RealUser'
  AND CountryRankID IN (1, 3)                     -- No Business Allowed or High Risk EDD
  AND UserWalletAllowance = 'Allowed'
  AND AMLProviderID IS NOT NULL
ORDER BY CountryRankID DESC, RiskScoreName DESC;
```

```sql
-- PEP and risk screening flags for compliance review
SELECT
    GCID,
    RealCID,
    Country,
    ScreeningStatus,
    ScreeningStatusExt,
    RiskClassificationName,
    PlayerStatusReason,
    WalletBalanceUSD
FROM EXW_dbo.EXW_AML_Users_Report
WHERE ScreeningStatus IN ('PEP', 'RiskMatch')
   OR ScreeningStatusExt IN ('PEP', 'RiskMatch')
ORDER BY WalletBalanceUSD DESC;
```

```sql
-- Users with crypto transfer activity and high-risk country logins (combined risk)
SELECT
    GCID,
    RealCID,
    Country,
    CountryByIP,
    HasCryptoTransfer,
    HasPayments,
    HasRiskCountryLogins,
    FirstTxDate,
    LastTxDate,
    RiskScoreName,
    IsAMLProblematic
FROM EXW_dbo.EXW_AML_Users_Report
WHERE HasCryptoTransfer = 1
  AND HasRiskCountryLogins = 1
  AND IsRealUser = 'RealUser'
ORDER BY LastTxDate DESC;
```

---

## 8. Atlassian

No Atlassian MCP results available for this object. Refer to Confluence for AML review workflow documentation, country risk rank definitions (CountryRankID groupings), and BI_DB_RiskClassification scoring methodology.
