# EXW_dbo.EXW_DimUser_Enriched

> 699,692-row enriched Wallet user view combining EXW_DimUser attributes with compliance scores (PEP, WorldCheck, EvMatch), KYC investment-capacity limits (UpperLimit, IsOverLimit), current balance (TotalBalanceUSD), player status history (CurrentStatus, PreviousStatus, StatusChangeDate), and last-login geography. Built daily by SP_EXW_DimUser_Enriched via TRUNCATE+INSERT from seven source tables spanning DWH, EXW, and BI_DB schemas.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table (Enriched Dimension) |
| **Production Source** | etoro.Customer.CustomerStatic + BackOffice.Customer (via DWH_dbo.Dim_Customer and EXW_DimUser) |
| **Writer SP** | `EXW_dbo.SP_EXW_DimUser_Enriched` |
| **Refresh** | Daily; TRUNCATE + INSERT (full rebuild) |
| **Row Count** | 699,692 (as of April 2026) |
| **Date Range** | JoinDate: 2019-06-11 to 2026-04-12; UpdateDate: 2026-04-12 |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_DimUser_Enriched is the "wide view" of a Wallet user, designed for AML analysts and compliance teams who need a single-row-per-user profile combining identity, regulation, compliance risk scores, KYC investment capacity limits, current balance, and account lifecycle status. It is not a slowly-changing dimension — it is rebuilt fresh daily by a full TRUNCATE+INSERT, so it always reflects the current state.

The table starts from the 699,692 Wallet users in EXW_DimUser (scoped by CustomerWalletsView) and enriches them with:

1. **Compliance scores** from DWH_dbo.Dim_Customer: PEPStatusID (screening status), WorldCheckID (sanctions), EvMatchStatus (e-ID verification vendors: Onfido, Au10tix), DocumentStatusID.
2. **KYC investment-capacity limits**: UpperLimit derived from KYC Question 14 (declared net worth bracket — 8 USD thresholds from $1K to $1M); RealizedEquity from DWH_dbo.V_Liabilities at prior day; IsOverLimit flag when equity exceeds declared cap.
3. **Player status history**: CurrentStatus and PreviousStatus computed via LAG() over DWH_dbo.Fact_SnapshotCustomer, capturing the most recent status change date.
4. **Geography enrichment**: Country, CountryByIP, RegisterState, IPState (resolved to text names), and LastLoginCountry from latest Wallet FCA login event.
5. **Balance snapshot**: TotalBalanceUSD = sum of all crypto balances at the most recent balance date from EXW_FinanceReportsBalancesNew.

All 699,692 users are included — including closed-wallet users (SP_DimUser's DELETE step is commented out, so users removed from CustomerWalletsView persist in EXW_DimUser and hence in this table).

User type breakdown: **RealUser 698,659** / eTorian (invalid/internal) 901 / TestAccount 132.

---

## 2. Business Logic

### 2.1 UserType Classification

**What**: Each user is classified into one of three types based on test status and validity.

**Columns Involved**: UserType, IsTestAccount, IsValidCustomer

**Rules**:
- `UserType = 'TestAccount'` when `IsTestAccount = 1` (GCID in EXW_TestUsers)
- `UserType = 'eTorian'` when `IsTestAccount = 0` AND `IsValidCustomer = 0` (internal/invalid accounts: Popular Investor / LabelID 26/30 / CountryID 250)
- `UserType = 'RealUser'` otherwise
- Priority: TestAccount check comes first (overrides eTorian even if IsValidCustomer=0)

### 2.2 KYC Investment Capacity Limit

**What**: Every Wallet user has a declared net worth bracket from KYC Question 14, which maps to a USD investment cap. The SP computes whether the user's realized equity exceeds that cap.

**Columns Involved**: AnswerText, UpperLimit, RealizedEquity, TotalUnderTheLimit, IsOverLimit

**Rules**:
- UpperLimit comes from the latest KYC Q14 answer per GCID: AnswerID 39=1,000 / 40=5,000 / 41,141=20,000 / 58=50,000 / 42,48=100,000 / 59=200,000 / 60=500,000 / 61,62=1,000,000
- UpperLimit distribution: 20K=51% (358K users), 1K=17% (119K), 5K=13% (94K), 50K=11% (74K)
- `TotalUnderTheLimit = ISNULL(UpperLimit,0) - ISNULL(RealizedEquity,0)` — can be negative
- `IsOverLimit = 1` when `TotalUnderTheLimit < 0`; 0 otherwise
- NULL UpperLimit (50 users) → treated as 0 in computation → IsOverLimit=0 unless RealizedEquity > 0

### 2.3 Player Status Change History

**What**: The table surfaces the most recent player status transition per user, not just the current status.

**Columns Involved**: CurrentStatus, PreviousStatus, StatusChangeDate, PlayerStatusID

**Rules**:
- Source: DWH_dbo.Fact_SnapshotCustomer joined to Dim_Range, filtered to users in this population
- LAG(PlayerStatusID) OVER(PARTITION BY RealCID ORDER BY FromDateID ASC) detects changes
- Only rows where `PlayerStatusID <> Previous_PlayerStatusID` are kept
- ROW_NUMBER OVER(PARTITION BY RealCID ORDER BY Change_Date DESC) picks the latest transition
- If Previous_PlayerStatusID = 0 (first snapshot), CurrentStatus = PreviousStatus (no prior status)
- NULL CurrentStatus / PreviousStatus = user has no status change history in Fact_SnapshotCustomer

### 2.4 State/Province Enrichment

**What**: RegisterState and IPState are resolved country states, populated mainly for US, Canada, and Australia.

**Columns Involved**: RegisterState, IPState

**Rules**:
- RegisterState ← Dim_State_and_Province.Name JOIN on Dim_Customer.RegionID = Dim_State_and_Province.RegionByIP_ID
- IPState ← Dim_State_and_Province.Name JOIN on Dim_Customer.RegionByIP_ID
- NULL for 535,731 users (76.6%) — most non-US/AU/CA users have no state mapping

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) on a HEAP table. All EXW fact tables are also HASH(GCID), so JOINs to EXW_FactBalance, EXW_AMLProviderID, and EXW_WalletRegulation are co-located. However, the HEAP means no columnstore compression — aggregate queries over 699K rows are lightweight. Full scans are fast for this size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Users over their investment limit | `WHERE IsOverLimit = 1` |
| KYC limit by tier | `GROUP BY UpperLimit ORDER BY UpperLimit` |
| AML: users above KYC cap | `WHERE IsOverLimit = 1 AND UserType = 'RealUser' AND IsTestAccount = 0` |
| Current vs prior status changes | `WHERE CurrentStatus <> PreviousStatus` |
| Users with no compliance screening | `WHERE PEPStatusID IS NULL` or `WHERE WorldCheckID = 0` |
| Compliance by regulation | `GROUP BY RegulationID, DesignatedRegulationID` |
| Last login outside registration country | `WHERE Country <> LastLoginCountry AND LastLoginCountry IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_DimUser | `EXW_DimUser_Enriched.GCID = EXW_DimUser.GCID` | Extend with CountryID, RegulationID FK integers |
| EXW_dbo.EXW_AMLProviderID | `EXW_AMLProviderID.GCID = EXW_DimUser_Enriched.GCID` | Add AML provider submission data |
| EXW_dbo.EXW_FactBalance | `EXW_FactBalance.GCID = EXW_DimUser_Enriched.GCID` | Detailed daily balances (but TotalBalanceUSD is already here) |
| DWH_dbo.Dim_Customer | `Dim_Customer.GCID = EXW_DimUser_Enriched.GCID` | Additional attributes not in this table |
| EXW_dbo.EXW_UserSettingsWalletAllowance | `EXW_UserSettingsWalletAllowance.GCID = EXW_DimUser_Enriched.GCID` | Regulatory allowance and compensation status |

### 3.4 Gotchas

- **HEAP on a daily full rebuild**: TRUNCATE+INSERT every day; no CCI. Aggregate queries are row-scan based. For repeated heavy analytics, consider materializing intermediate results.
- **UpperLimit NULL ≠ no limit**: NULL UpperLimit means the user hasn't answered KYC Q14. The ISNULL(UpperLimit,0) in the SP treats NULL as 0, meaning TotalUnderTheLimit = -RealizedEquity → IsOverLimit=1 if the user has any realized equity. This may over-count over-limit users if Q14 is incomplete.
- **CurrentStatus NULL means no transition, not unknown status**: If a user's PlayerStatusID never changed (no row in snapshot where PlayerStatusID ≠ Previous), CurrentStatus is NULL. The user may still be Active — check PlayerStatusID (col 21) for the raw status ID.
- **TotalBalanceUSD NULL vs 0**: NULL (10,318 users) means no FinanceReportsBalancesNew record exists. 0 means the record exists but all crypto balances are zero. Different business implications.
- **RegisterState/IPState 76.6% NULL**: Normal — these are only populated for users with US/Canada/Australia IP geo-mapping. Do not treat NULL as data quality issue.
- **UserType='eTorian'** includes internal eToro employees and invalid accounts — always filter `UserType = 'RealUser'` and `IsTestAccount = 0` for user-facing analytics.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki (BackOffice.Customer or Customer.CustomerStatic via Dim_Customer) |
| Tier 2 | Derived from SP code (computed, join-resolved, or passthrough of a DWH-computed column) |
| Tier 3 | Inferred from column name, type, and context |
| Tier 4 | Best available — limited lineage confidence |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. HASH distribution key for this table. (Tier 1 — Customer.CustomerStatic) |
| 2 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 3 | PlayerLevelID | int | YES | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Bronze; 4=Internal; 7=Diamond. Determines available features and risk limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 4 | VerificationLevelID | int | YES | KYC verification level. FK to Dictionary.VerificationLevel. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Default=0. (Tier 1 — BackOffice.Customer) |
| 5 | Country | varchar(50) | YES | Denormalized country name from DWH_dbo.Dim_Country, resolved via Dim_Customer.CountryID. Text label for readability; use CountryID from EXW_DimUser for joins. Populated for all 699,692 users. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 6 | Region | varchar(50) | YES | Marketing region name from DWH_dbo.Dim_Country.Region, derived from CountryID. Text label for the user's geographic marketing grouping (UK, Eastern Europe, Arabic GCC, etc.). Use RegionID for aggregation. (Tier 2 — SP_DimUser) |
| 7 | CountryByIP | varchar(50) | YES | Country name (from Dim_Country) detected from the customer's IP address at registration, via Dim_Customer.CountryIDByIP. Used for mismatch detection with Country. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 8 | RegisterState | varchar(50) | YES | State or province of registration, resolved from DWH_dbo.Dim_State_and_Province on Dim_Customer.RegionID = RegionByIP_ID. NULL for 76.6% of users — populated mainly for US, Canada, and Australia. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 9 | IPState | varchar(50) | YES | State or province detected from registration IP, resolved from Dim_State_and_Province on Dim_Customer.RegionByIP_ID. Same NULL pattern as RegisterState. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 10 | IsTestAccount | int | YES | 1 if this user's GCID appears in EXW_dbo.EXW_TestUsers (internal/beta test accounts); 0 otherwise. Always filter IsTestAccount=0 in production analytics. 132 test accounts in current data. (Tier 2 — SP_DimUser) |
| 11 | CreditReportValid | int | YES | DWH-computed: similar to IsValidCustomer but with additional AccountTypeID≠2 exclusion and specific CID exceptions for CountryID=250. Renamed from Dim_Customer.IsCreditReportValidCB. (Tier 2 — SP_Dim_Customer) |
| 12 | IsValidCustomer | int | YES | DWH-computed: 1 when not Internal (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. (Tier 2 — SP_Dim_Customer) |
| 13 | 2FA | int | YES | Two-factor authentication status. 0=disabled, 1=enabled. Derived from STS_Audit_UserOperationsData login type events. Preserves previous value when no new 2FA event exists. (Tier 2 — SP_Dim_Customer) |
| 14 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Changes trigger RegulationChangeDate update. Values in EXW: 1=CySEC (311K), 2=FCA (196K), 8=FinCEN+FINRA (61K), 5=BVI (32K), 9=FSA Seychelles (31K), 10=ASIC & GAML (27K), 6=eToroUS (17K), 7=FinCEN (12K), 11=FSRA (8K), 4=ASIC (3K). (Tier 1 — BackOffice.Customer) |
| 15 | DesignatedRegulationID | int | YES | Secondary/override regulation for accounts subject to multiple jurisdictions. FK to Dictionary.Regulation. (Tier 1 — BackOffice.Customer) |
| 16 | PEPStatusID | int | YES | Compliance screening status from PEP/sanctions screening service, renamed from Dim_Customer.ScreeningStatusID. Updated via ScreeningService through SP_Dim_Customer. NULL indicates not yet screened. (Tier 2 — SP_Dim_Customer) |
| 17 | WorldCheckID | int | YES | Refinitiv/LSEG World-Check sanctions and PEP screening result. FK to Dictionary.WorldCheck. Default=0. (Tier 1 — BackOffice.Customer) |
| 18 | WorldCheckResultsUpdated | datetime | YES | When World-Check results were last updated. Preserved from previous row. (Tier 2 — SP_Dim_Customer) |
| 19 | EvMatchStatus | int | YES | Electronic verification match result. Score or decision from automated identity verification vendors (Onfido, Au10tix). NULL if not yet processed. (Tier 1 — BackOffice.Customer) |
| 20 | DocumentStatusID | int | YES | Current state of the customer KYC document submission and review queue. NULL if no documents submitted. (Tier 1 — BackOffice.Customer) |
| 21 | PlayerStatusID | int | YES | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Normal; other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 22 | AccountStatusID | int | YES | Account operational status. Default=1 (Active/Normal). 2=Closed or Restricted. (Tier 1 — Customer.CustomerStatic) |
| 23 | UserType | varchar(50) | YES | EXW-computed user classification. TestAccount if IsTestAccount=1; eTorian if IsValidCustomer=0 (internal/non-standard); RealUser otherwise. Distribution: RealUser=698,659, eTorian=901, TestAccount=132. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 24 | CurrentStatus | varchar(50) | YES | Most recent player status name at the time of the last status change, resolved from DWH_dbo.Dim_PlayerStatus via LAG() over Fact_SnapshotCustomer history. NULL for users with no status transition detected. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 25 | PreviousStatus | varchar(50) | YES | Player status name immediately before the most recent status change. If the user has never changed status (Previous_PlayerStatusID=0), this equals CurrentStatus. Resolved from Dim_PlayerStatus. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 26 | StatusChangeDate | datetime | YES | Date of the most recent player status change, derived from DWH_dbo.Dim_Range.FromDateID for the Fact_SnapshotCustomer row where status changed. NULL if no status transition in snapshot history. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 27 | LastLoginCountry | varchar(50) | YES | Country name of the most recent Wallet login (EXW_FCA_UserLogin, PlatformIDs 118-120), resolved from DWH_dbo.Dim_Country via CountryIDByIP. NULL for 107,646 users (15.4%) with no qualifying login. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 28 | JoinDate | datetime | YES | Earliest Wallet allocation date from EXW_dbo.EXW_WalletInventory (MIN of Allocated per GCID, WHERE GCID > 0). Represents when the user first had a crypto balance allocation — effective Wallet join date. Range: 2019-06-11 to 2026-04-12. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 29 | TotalBalanceUSD | money | YES | Total USD-equivalent Wallet balance at the most recent balance date from EXW_FinanceReportsBalancesNew (SUM across all cryptos at MAX BalanceDateID). NULL for 10,318 users (1.5%) with no balance record. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 30 | POIExpireDate | datetime | YES | Expiry date of the Proof of Identity (ID) document, renamed from Dim_Customer.IsIDProofExpiryDate. NULL if no ID document reviewed or no expiry captured. (Tier 2 — SP_Dim_Customer) |
| 31 | POAExpireDate | datetime | YES | Expiry date of the Proof of Address document, renamed from Dim_Customer.IsAddressProofExpiryDate. NULL if no address proof reviewed or no expiry captured. (Tier 2 — SP_Dim_Customer) |
| 32 | AnswerText | nvarchar(200) | YES | Text of the user's answer to KYC Question 14 (net worth / investment capacity), sourced from BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (latest per GCID). NULL if user has not completed Q14. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 33 | UpperLimit | int | YES | USD investment capacity cap derived from KYC Q14 AnswerID: 39=1,000; 40=5,000; 41/141=20,000; 58=50,000; 42/48=100,000; 59=200,000; 60=500,000; 61/62=1,000,000. Distribution: 20K=51%, 1K=17%, 5K=13%, 50K=11%. NULL if Q14 not answered. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 34 | RealizedEquity | money | YES | Customer's realized equity in USD from DWH_dbo.V_Liabilities as of the prior trading day. Used alongside UpperLimit for IsOverLimit detection. NULL for 48,774 users (7%) with no position history. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 35 | TotalUnderTheLimit | money | YES | Remaining investment capacity: ISNULL(UpperLimit,0) - ISNULL(RealizedEquity,0). Negative when user's equity exceeds declared net worth cap (IsOverLimit=1). (Tier 2 — SP_EXW_DimUser_Enriched) |
| 36 | IsOverLimit | int | YES | 1 if TotalUnderTheLimit < 0 (user's realized equity exceeds declared KYC Q14 investment capacity); 0 otherwise. NULL UpperLimit treated as 0 — users who skipped Q14 with any realized equity may flag as over-limit. (Tier 2 — SP_EXW_DimUser_Enriched) |
| 37 | UpdateDate | datetime | YES | ETL timestamp set to GETDATE() at INSERT by SP_EXW_DimUser_Enriched (full daily TRUNCATE+INSERT). Reflects SP execution time, not user's original join date. Last value: 2026-04-12. (Tier 2 — SP_EXW_DimUser_Enriched) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| GCID | etoro.Customer.CustomerStatic | GCID | Passthrough via EXW_DimUser |
| RealCID | etoro.Customer.CustomerStatic | RealCID | Passthrough via EXW_DimUser |
| PlayerLevelID | etoro.Customer.CustomerStatic | PlayerLevelID | Passthrough via Dim_Customer |
| VerificationLevelID | etoro.BackOffice.Customer | VerificationLevelID | Passthrough via Dim_Customer |
| Country | DWH_dbo.Dim_Country | Name | JOIN on Dim_Customer.CountryID |
| Region | EXW_dbo.EXW_DimUser | Region | Passthrough (already join-resolved) |
| CountryByIP | DWH_dbo.Dim_Country | Name | JOIN on Dim_Customer.CountryIDByIP |
| RegisterState | DWH_dbo.Dim_State_and_Province | Name | JOIN on Dim_Customer.RegionID |
| IPState | DWH_dbo.Dim_State_and_Province | Name | JOIN on Dim_Customer.RegionByIP_ID |
| IsTestAccount | EXW_dbo.EXW_DimUser | IsTestAccount | Passthrough |
| CreditReportValid | DWH_dbo.Dim_Customer | IsCreditReportValidCB | Renamed |
| IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | Passthrough (DWH-computed) |
| 2FA | DWH_dbo.Dim_Customer | 2FA | Passthrough |
| RegulationID | etoro.BackOffice.Customer | RegulationID | Passthrough via Dim_Customer |
| DesignatedRegulationID | etoro.BackOffice.Customer | DesignatedRegulationID | Passthrough via Dim_Customer |
| PEPStatusID | DWH_dbo.Dim_Customer | ScreeningStatusID | Renamed |
| WorldCheckID | etoro.BackOffice.Customer | WorldCheckID | Passthrough via Dim_Customer |
| WorldCheckResultsUpdated | DWH_dbo.Dim_Customer | WorldCheckResultsUpdated | Passthrough (preserved) |
| EvMatchStatus | etoro.BackOffice.Customer | EvMatchStatus | Passthrough via Dim_Customer |
| DocumentStatusID | etoro.BackOffice.Customer | DocumentStatusID | Passthrough via Dim_Customer |
| PlayerStatusID | etoro.Customer.CustomerStatic | PlayerStatusID | Passthrough via Dim_Customer |
| AccountStatusID | etoro.Customer.CustomerStatic | AccountStatusID | Passthrough via Dim_Customer |
| UserType | (computed) | — | CASE: TestAccount/eTorian/RealUser |
| CurrentStatus | DWH_dbo.Dim_PlayerStatus | Name | LAG-based most recent status transition |
| PreviousStatus | DWH_dbo.Dim_PlayerStatus | Name | Previous status at last transition |
| StatusChangeDate | DWH_dbo.Dim_Range | FromDateID | CONVERT(DATE) at last PlayerStatusID change |
| LastLoginCountry | DWH_dbo.Dim_Country | Name | JOIN on EXW_FCA_UserLogin.CountryIDByIP |
| JoinDate | EXW_dbo.EXW_WalletInventory | Allocated | MIN(Allocated) per GCID |
| TotalBalanceUSD | EXW_dbo.EXW_FinanceReportsBalancesNew | BalanceUSD | SUM at MAX BalanceDateID per GCID |
| POIExpireDate | DWH_dbo.Dim_Customer | IsIDProofExpiryDate | Renamed |
| POAExpireDate | DWH_dbo.Dim_Customer | IsAddressProofExpiryDate | Renamed |
| AnswerText | BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | Latest answer for QuestionID=14 |
| UpperLimit | BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data | AnswerID | CASE: AnswerID → USD threshold |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | As of DateID = yesterday |
| TotalUnderTheLimit | (computed) | — | ISNULL(UpperLimit,0) - ISNULL(RealizedEquity,0) |
| IsOverLimit | (computed) | — | CASE WHEN TotalUnderTheLimit < 0 THEN 1 ELSE 0 |
| UpdateDate | (computed) | — | GETDATE() at INSERT |

### 5.2 ETL Pipeline

```
etoro.Customer.CustomerStatic + BackOffice.Customer (production OLTP)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Customer_CustomerStatic (→ DWH_dbo.Dim_Customer)
  |-- SP_Dim_Customer_DL_To_Synapse ---|
  v
DWH_dbo.Dim_Customer (central DWH dimension, 107 cols)
  |
  |-- SP_DimUser (daily) → EXW_dbo.EXW_DimUser (699,692 users)
  |
  +-- SP_EXW_DimUser_Enriched (daily, TRUNCATE+INSERT):
      JOIN: EXW_DimUser + Dim_Customer + Dim_Country + Dim_State_and_Province
            + Fact_SnapshotCustomer + Dim_Range + Dim_PlayerStatus
            + EXW_FCA_UserLogin + EXW_WalletInventory
            + EXW_FinanceReportsBalancesNew
            + BI_DB_KYC_Questions_Answers_Row_Data
            + V_Liabilities
      v
EXW_dbo.EXW_DimUser_Enriched (699,692 rows, HASH(GCID), HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID, RealCID | EXW_dbo.EXW_DimUser | Primary Wallet user dimension; EXW_DimUser_Enriched is a superset enrichment |
| GCID | DWH_dbo.Dim_Customer | Join on GCID for additional DWH attributes |
| RegulationID, DesignatedRegulationID | DWH_dbo dimension tables | Dictionary.Regulation lookup |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus | Player status name resolution |
| DocumentStatusID | DWH_dbo dimension tables | KYC document status lookup |

### 6.2 Referenced By (other objects point to this)

| Object | How it references this table | SP |
|--------|------------------------------|-----|
| EXW_dbo.EXW_UserSettingsWalletAllowance | JOINs to EXW_DimUser_Enriched for user metadata and compliance closure | SP_EXW_UserSettingsWalletAllowance |
| EXW_dbo.EXW_FirstTimeWalletsAndUsers | JOINs to EXW_DimUser_Enriched for user type and regulation attributes | SP_EXW_FirstTimeWalletsAndUsers |

---

## 7. Sample Queries

### Users Over Their KYC Investment Limit

```sql
SELECT
    GCID,
    RealCID,
    Country,
    RegulationID,
    UpperLimit,
    RealizedEquity,
    TotalUnderTheLimit,
    AnswerText
FROM [EXW_dbo].[EXW_DimUser_Enriched]
WHERE IsOverLimit = 1
  AND UserType = 'RealUser'
  AND IsTestAccount = 0
ORDER BY TotalUnderTheLimit ASC  -- most over-limit first
```

### Player Status Change Analysis

```sql
SELECT
    CurrentStatus,
    PreviousStatus,
    COUNT(*) AS user_count,
    MIN(StatusChangeDate) AS earliest_change,
    MAX(StatusChangeDate) AS latest_change
FROM [EXW_dbo].[EXW_DimUser_Enriched]
WHERE CurrentStatus <> PreviousStatus
  AND CurrentStatus IS NOT NULL
GROUP BY CurrentStatus, PreviousStatus
ORDER BY user_count DESC
```

### Compliance Risk Profile by Regulation

```sql
SELECT
    RegulationID,
    COUNT(*) AS total_users,
    SUM(CASE WHEN EvMatchStatus = 0 THEN 1 ELSE 0 END) AS ev_not_processed,
    SUM(CASE WHEN WorldCheckID > 0 THEN 1 ELSE 0 END) AS world_check_flagged,
    SUM(CASE WHEN PEPStatusID IS NOT NULL AND PEPStatusID > 0 THEN 1 ELSE 0 END) AS pep_screened,
    SUM(CASE WHEN IsOverLimit = 1 THEN 1 ELSE 0 END) AS over_kyc_limit,
    AVG(CAST(TotalBalanceUSD AS float)) AS avg_balance_usd
FROM [EXW_dbo].[EXW_DimUser_Enriched]
WHERE UserType = 'RealUser'
  AND IsTestAccount = 0
GROUP BY RegulationID
ORDER BY total_users DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira records retrieved for EXW_DimUser_Enriched in this pipeline run. The SP header attributes authorship to the eMoney & Wallet Data Analytics Team (created 2022-11-16, migrated to Synapse 2024-03-21 by Inessa Kontorovich / Guy Manova). A 2024-05-16 update by Inessa fixed PreviousStatus logic for users with no status change history.

---

*Generated: 2026-04-20 | Quality: 8.6/10 | Phases: 13/14*
*Tiers: 11 T1, 26 T2, 0 T3, 0 T4, 0 T5 | Elements: 37/37, Logic: 4 subsections*
*Object: EXW_dbo.EXW_DimUser_Enriched | Type: Table (Enriched Dimension) | Production Source: Customer.CustomerStatic + BackOffice.Customer via Dim_Customer*
