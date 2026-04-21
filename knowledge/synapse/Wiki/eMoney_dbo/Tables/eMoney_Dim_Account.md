# eMoney_dbo.eMoney_Dim_Account

> One row per eToro Money fiat currency balance, consolidating currency-balance identity, customer DWH enrichment, bank account and card details, account program history, and change-detection flags from FiatDwhDB and DWH_dbo sources. 2,034,012 rows; currency balances created 2020-11-09 to 2026-04-13; refreshed daily via DELETE + INSERT.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table (Dimension) |
| **Production Source** | FiatDwhDB (eToro Money fiat platform DWH) via SP_eMoney_Dim_Account |
| **Refresh** | Daily DELETE + INSERT (Step 3 of SP_eMoney_Execute_Group_One; @Date = yesterday) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CurrencyBalanceID ASC); NCI (CID ASC) |
| **Row Count** | 2,034,012 (sampled 2026-04-13) |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Dim_Account` is the central account dimension for eToro Money (eTM), the fiat banking product. Each row represents one **currency balance** — the fundamental money-holding unit in the fiat platform. A single customer (GCID) can have multiple currency balances (e.g., EUR and GBP), so this table is at currency-balance grain, not customer grain.

The table consolidates three layers of data:
1. **FiatDwhDB identity** — currency balance, fiat account, bank account, card, and current status fields sourced from FiatDwhDB tables (FiatCurrencyBalances, FiatAccount, FiatBankAccount, FiatCards, FiatCardStatuses, FiatAccountStatuses, FiatAccountsProperties, FiatCurrencyBalancesStatuses)
2. **DWH customer enrichment** — club, regulation, country, and player status attributes from DWH_dbo.Dim_Customer and registration-time snapshots from Fact_SnapshotCustomer, joined via GCID
3. **DWH-computed fields** — IsValidETM composite flag, change-detection flags, seniority months, entity mapping

The ETL SP (`SP_eMoney_Dim_Account`) runs daily in an 11-step pipeline. It builds temp tables for each source cluster, filters to the primary currency balance per GCID (`GCID_Unique_Count=1`) for DWH enrichment joins, then performs a full DELETE + INSERT. Rows with `GCID_Unique_Count > 1` are secondary accounts and will have NULL customer attributes (CID, ClubID, RegulationID, etc.).

**Entity distribution** (2026-04-13): Malta 66.6%, UK 31.4%, AUS 2.0%.
**Account program distribution**: IBAN 95.3%, card 4.7%.
**Note on GCID=0**: Cancelled accounts are recorded with GCID=0; `IsCancelledAccount` = 1 for these rows.

---

## 2. Business Logic

### 2.1 Currency Balance Grain

**What**: The table is at currency-balance grain, not customer grain. One GCID can appear on multiple rows (one per currency balance / account type).

**Columns Involved**: `CurrencyBalanceID`, `AccountID`, `GCID`, `GCID_Unique_Count`

**Rules**:
- `CurrencyBalanceID` = `FiatCurrencyBalances.Id` — the primary key of this table's logical entity
- `AccountID` = `FiatAccount.Id` — one account can hold multiple currency balances
- `GCID_Unique_Count` = `ROW_NUMBER() PARTITION BY GCID ORDER BY AccountCreateTime DESC` — rank 1 = most recently created eMoney account for this customer
- Customer enrichment (CID, ClubID, RegulationID, etc.) is populated only for rows with `GCID_Unique_Count = 1`; secondary accounts have NULL for all DWH customer attributes

### 2.2 Primary Account Identification (GCID_Unique_Count=1 Rule)

**What**: DWH customer attributes are only available for the primary eMoney account per customer.

**Columns Involved**: `GCID_Unique_Count`, `CID`, `ClubID`, `RegulationID`, `CountryID`, `PlayerStatusID`, and all `Reg*` snapshot columns

**Rules**:
- Only rows where `GCID_Unique_Count = 1` are joined to `DWH_dbo.Dim_Customer` and `Fact_SnapshotCustomer`
- Rows with `GCID_Unique_Count > 1` have NULL in all customer-DWH enrichment columns
- `GCID_Unique_Count` itself is always populated (not NULL) — it indicates rank, not count
- Use `WHERE GCID_Unique_Count = 1` when joining to trading-side CID-based analysis

### 2.3 Current vs Registration-Time Attributes

**What**: The table captures two time points for club, regulation, country, player status, and account program: the current state and the state at eMoney account creation.

**Columns Involved**: `ClubID`/`RegClubID`, `RegulationID`/`RegRegulationID`, `CountryID`/`RegCountryID`, `PlayerStatusID`/`RegPlayerStatusID`, `AccountProgramID`/`RegAccountProgramID`, `AccountSubProgramID`/`RegAccountSubProgramID`

**Rules**:
- `Reg*` columns come from `Fact_SnapshotCustomer` joined at the `AccountCreateDateID` range — they represent the customer's attributes at the time they opened their eMoney account
- Current columns (no prefix) come from current `Dim_Customer` values
- Change flags (`HasClubChanged`, `HasRegulationChanged`, etc.) are 1 when the corresponding current and reg values differ

### 2.4 IsValidETM Composite Flag

**What**: Composite flag combining trading-side validity, test account exclusion, and cancelled account exclusion.

**Columns Involved**: `IsValidETM`, `IsValidCustomer`, `IsTestAccount`, `IsCancelledAccount`

**Rules**:
- `IsValidETM = 1` when ALL three conditions hold: `IsValidCustomer=1`, `IsTestAccount=0`, `IsCancelledAccount=0`
- `IsValidCustomer` is sourced from `Dim_Customer` (excludes Popular Investors, label 30/26 accounts, and CountryID=250)
- `IsTestAccount=1` when GCID appears in the Fivetran Google Sheets test-user list (`eMoney_google_sheets.emoney_test_users`)
- `IsCancelledAccount=1` when `GCID=0` (cancelled accounts stored with a zero GCID)
- Use `IsValidETM = 1` as the standard filter for production eMoney analytics

### 2.5 Account Program and Sub-Program (Current vs Registration)

**What**: The `AccountProgramID`/`AccountSubProgramID` reflect the customer's current program; the `RegAccountProgramID`/`RegAccountSubProgramID` reflect what was assigned at account creation.

**Columns Involved**: `AccountProgramID`, `AccountSubProgramID`, `RegAccountProgramID`, `RegAccountSubProgramID`, `CountAccountProgramChanges`, `CountAccountSubProgramChanges`

**Rules**:
- Current program: `ISNULL(latest FiatAccountsProperties record, original FiatAccount value)` — ensures latest program change is reflected
- `CountAccountProgramChanges`: number of distinct program values seen; set to 0 if the count was ≤1 (i.e., never changed; 0 = never changed, N≥2 = changed N times)
- Sub-programs (16 active: 1=Card Premium UK through 16=IBAN Black DKK) map region and tier

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The table is distributed on `HASH(CID)`. Most analytics joins are `CID`-based (eToro trading platform joins), so shuffle is minimized. However, `CurrencyBalanceID` is the clustered index key, making point lookups by currency balance ID efficient.

The NCI on `CID` speeds up `WHERE CID = N` predicates common in user-level queries.

**Note**: For eMoney-only analysis (without trading-side JOIN), consider joining on `GCID` — but GCID is not the distribution key, so cross-joins will cause data movement. Filter to `GCID_Unique_Count = 1` first to reduce scan size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| eTM KPIs by entity/club/regulation | Filter `IsValidETM=1 AND GCID_Unique_Count=1`, GROUP BY Entity, RegulationID, ClubID |
| Account program distribution | GROUP BY AccountProgram WHERE GCID_Unique_Count=1 |
| Customers with card | WHERE HasCard=1 AND GCID_Unique_Count=1 |
| AUS entity onboarding funnel | WHERE Entity='AUS', filter by AccountCreateDate range |
| Regulation migrations | WHERE HasRegulationChanged=1 AND RegulationID <> RegRegulationID |
| UK IBAN holders | WHERE Entity='UK' AND AccountProgramID=2 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON da.CID = dc.RealCID | Full trading profile for eTM customer |
| eMoney_dbo.eMoney_Dim_Transaction | ON da.CID = dt.CID | Transaction history for this account |
| eMoney_dbo.eMoney_Fact_Transaction_Status | ON da.CID = fts.CID | All transaction status events |
| eMoney_dbo.eMoneyClientBalance | ON da.CurrencyBalanceID = cb.CurrencyBalanceID | Daily balance reconciliation |
| DWH_dbo.Dim_Country | ON da.CountryID = c.CountryID | Country name/region lookup |
| DWH_dbo.Dim_Regulation | ON da.RegulationID = r.DWHRegulationID | Regulation name |

### 3.4 Gotchas

- **GCID_Unique_Count > 1 rows have NULL customer attributes**: Joining without filtering GCID_Unique_Count=1 will cause inflated counts and NULL-rich result sets.
- **GCID=0 rows**: Cancelled accounts appear with GCID=0. Use `IsCancelledAccount=0` to exclude them.
- **CID is NULL for secondary accounts**: `CID` is NULL when GCID_Unique_Count > 1; cannot use CID for cross-table JOINs on those rows.
- **UpdateDate = GETDATE() at INSERT time**: Not a business timestamp; it marks when the daily refresh ran.
- **BankAccountIBAN, BankAccountNumber, BankAccountName** are PII fields — masked in analytics environments (Synapse DDM enforced at FiatDwhDB source; may be masked in UC gold copy too).
- **NULL bank account fields**: Card-program accounts have no bank account linkage; BankAccountID and all BankAccount* columns will be NULL.
- **NULL card fields**: IBAN-only accounts may have HasCard=0 and NULL card columns.
- **TP_FTDDate sentinel**: Dim_Customer.FirstDepositDate defaults to '19000101' for non-depositors; TP_FTDDate will reflect that sentinel value (cast to date).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (FiatDwhDB or DWH_dbo) |
| Tier 2 | Description written from ETL SP code analysis (SP_eMoney_Dim_Account) |
| Tier 3 | Description inferred from column name and surrounding context |
| Tier 4 | Best available — limited evidence |
| Tier 5 | Name only — no description available |

### 4.1 Currency Balance Identity

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CurrencyBalanceID | int | YES | Auto-incrementing surrogate PK. Referenced by FiatTransactions, FiatCurrencyBalancesStatuses, CurrencyBalancesProvidersMapping, PaymentSpecifications, FiatBankAccount, and BalanceReports. (Tier 1 — dbo.FiatCurrencyBalances) |
| 2 | AccountID | int | YES | Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. (Tier 1 — dbo.FiatAccount) |
| 3 | GCID | int | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 — dbo.FiatAccount) |

### 4.2 DWH Customer Enrichment (Primary Account Only)

*Columns 4–19 are populated only for rows where `GCID_Unique_Count = 1`. NULL for secondary accounts.*

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 4 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 5 | ClubID | int | YES | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard; 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. Renamed from PlayerLevelID. (Tier 1 — Customer.CustomerStatic) |
| 6 | Club | varchar(50) | YES | Player level display name resolved from DWH_dbo.Dim_PlayerLevel. (Tier 2 — SP_eMoney_Dim_Account) |
| 7 | ClubCategory | varchar(50) | YES | Grouped player level bucket. NoClub=PlayerLevelID 1; LowClub=3 or 5; HighClub=2, 6, or 7; Internal=4; Error=unmapped values. (Tier 2 — SP_eMoney_Dim_Account) |
| 8 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC=7.39M, BVI=7.30M, FCA=1.17M. Changes trigger RegulationChangeDate update. (Tier 1 — BackOffice.Customer) |
| 9 | Regulation | varchar(50) | YES | Regulation display name resolved from DWH_dbo.Dim_Regulation. (Tier 2 — SP_eMoney_Dim_Account) |
| 10 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 11 | Country | varchar(50) | YES | Country display name resolved from DWH_dbo.Dim_Country. (Tier 2 — SP_eMoney_Dim_Account) |
| 12 | Region | varchar(50) | YES | Geographic region from DWH_dbo.Dim_Country.Region, resolved via CountryID. (Tier 2 — SP_eMoney_Dim_Account) |
| 13 | PlayerStatusID | int | YES | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered; other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 14 | PlayerStatus | varchar(50) | YES | Player status display name resolved from DWH_dbo.Dim_PlayerStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 15 | IsValidETM | int | YES | eToro Money validity flag. 1 when IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0. Standard filter for eTM production analytics. (Tier 2 — SP_eMoney_Dim_Account) |
| 16 | IsValidCustomer | int | YES | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. Passthrough from Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 17 | IsTestAccount | int | YES | 1 if GCID appears in the Fivetran Google Sheets test-user list (eMoney_google_sheets.emoney_test_users); 0 otherwise. Exclude from all production analytics. (Tier 2 — SP_eMoney_Dim_Account) |
| 18 | IsCancelledAccount | int | YES | 1 when GCID=0 (cancelled accounts are recorded with a zero GCID in FiatDwhDB). (Tier 2 — SP_eMoney_Dim_Account) |
| 19 | GCID_Unique_Count | int | YES | Rank of this currency balance account for its GCID, ordered by AccountCreateTime DESC. 1 = most recently created eMoney account for this customer (the primary account). Customer DWH enrichment columns (CID, ClubID, etc.) are only populated for rank=1 rows. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.3 TP Trading Platform Dates

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 20 | TP_RegDate | date | YES | Account registration date (renamed from Registered). Default=getdate(). DWH note: CAST to DATE (time component discarded); renamed RegisteredReal→TP_RegDate. (Tier 1 — Customer.CustomerStatic) |
| 21 | TP_FTDDate | date | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. DWH note: CAST to DATE; renamed FirstDepositDate→TP_FTDDate. Passthrough from Dim_Customer. (Tier 2 — SP_Dim_Customer) |

### 4.4 Registration-Time Snapshot (Customer State at eMoney Account Creation)

*Sourced from DWH_dbo.Fact_SnapshotCustomer at the date range matching AccountCreateDateID.*

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 22 | RegClubID | int | YES | PlayerLevelID from Fact_SnapshotCustomer at the date of eMoney account creation. Represents the customer's club at eTM onboarding. (Tier 2 — SP_eMoney_Dim_Account) |
| 23 | RegClub | varchar(50) | YES | Club display name for RegClubID, resolved from DWH_dbo.Dim_PlayerLevel. (Tier 2 — SP_eMoney_Dim_Account) |
| 24 | RegClubCategory | varchar(50) | YES | Club category bucket at account creation. Same mapping as ClubCategory (NoClub/LowClub/HighClub/Internal) applied to RegClubID. (Tier 2 — SP_eMoney_Dim_Account) |
| 25 | RegRegulationID | int | YES | RegulationID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 — SP_eMoney_Dim_Account) |
| 26 | RegRegulation | varchar(50) | YES | Regulation display name for RegRegulationID, resolved from DWH_dbo.Dim_Regulation. (Tier 2 — SP_eMoney_Dim_Account) |
| 27 | RegCountryID | int | YES | CountryID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 — SP_eMoney_Dim_Account) |
| 28 | RegCountry | varchar(50) | YES | Country display name for RegCountryID, resolved from DWH_dbo.Dim_Country. (Tier 2 — SP_eMoney_Dim_Account) |
| 29 | RegRegion | varchar(50) | YES | Geographic region for RegCountryID, resolved from DWH_dbo.Dim_Country.Region. (Tier 2 — SP_eMoney_Dim_Account) |
| 30 | RegPlayerStatusID | int | YES | PlayerStatusID from Fact_SnapshotCustomer at the date of eMoney account creation. (Tier 2 — SP_eMoney_Dim_Account) |
| 31 | RegPlayerStatus | varchar(50) | YES | Player status display name for RegPlayerStatusID, resolved from DWH_dbo.Dim_PlayerStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 32 | RegAccountProgramID | int | YES | Account program type at eMoney account creation: 0=Unknown, 1=card, 2=iban. Determines the fundamental product type (card-based vs IBAN-based banking). Captured from eMoney_Account_Mappings baseline (original FiatAccount.AccountProgramId). (Tier 1 — dbo.FiatAccount) |
| 33 | RegAccountProgram | varchar(50) | YES | Account program display name for RegAccountProgramID, resolved from eMoney_Dictionary_AccountProgram. (Tier 2 — SP_eMoney_Dim_Account) |
| 34 | RegAccountSubProgramID | int | YES | Specific sub-program variant at eMoney account creation: 1-16 (e.g., Card Premium UK, IBAN EU Green). FK to eMoney_dbo.SubPrograms. NULL if not yet assigned to a specific variant. Captured from eMoney_Account_Mappings baseline. (Tier 1 — dbo.FiatAccount) |
| 35 | RegAccountSubProgram | varchar(50) | YES | Sub-program display name for RegAccountSubProgramID, resolved from eMoney_dbo.SubPrograms. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.5 Change Detection Flags

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 36 | HasCustomerInfoChanged | int | YES | 1 if ANY of the following changed since account creation: ClubID, RegulationID, CountryID, PlayerStatusID, AccountProgramID, AccountSubProgramID. Composite of all six individual change flags. (Tier 2 — SP_eMoney_Dim_Account) |
| 37 | HasClubChanged | int | YES | 1 if ClubID (current) ≠ RegClubID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 38 | HasRegulationChanged | int | YES | 1 if RegulationID (current) ≠ RegRegulationID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 39 | HasCountryChanged | int | YES | 1 if CountryID (current) ≠ RegCountryID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 40 | HasPlayerStatusChanged | int | YES | 1 if PlayerStatusID (current) ≠ RegPlayerStatusID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 41 | HasAccountProgramChanged | int | YES | 1 if AccountProgramID (current) ≠ RegAccountProgramID (at account creation). Tracks card-to-IBAN upgrades. (Tier 2 — SP_eMoney_Dim_Account) |
| 42 | HasAccountSubProgramChanged | int | YES | 1 if AccountSubProgramID (current) ≠ RegAccountSubProgramID (at account creation). Tracks sub-program tier/region changes. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.6 Currency Balance Details

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 43 | CurrencyBalanceISOCode | int | YES | ISO 4217 numeric currency code. E.g., "826"=GBP, "978"=EUR, "036"=AUD. Indexed for currency-based queries. Renamed from FiatCurrencyBalances.CurrencyISON. (Tier 1 — dbo.FiatCurrencyBalances) |
| 44 | CurrencyBalanceISODesc | varchar(50) | YES | Currency display name resolved from eMoney_Currency_Instrument_Mapping_Static via CurrencyBalanceISOCode (where SellCurrencyID=1). (Tier 2 — SP_eMoney_Dim_Account) |
| 45 | CurrencyBalanceCreateTime | datetime | YES | UTC timestamp when this currency balance was created in the data warehouse. Renamed from FiatCurrencyBalances.Created. (Tier 1 — dbo.FiatCurrencyBalances) |
| 46 | CurrencyBalanceCreateDate | date | YES | Date portion of CurrencyBalanceCreateTime. DWH-derived: CAST(CurrencyBalanceCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 47 | CurrencyBalanceCreateDateID | int | YES | YYYYMMDD integer date key for CurrencyBalanceCreateDate. DWH-derived: CONVERT(VARCHAR(8), CurrencyBalanceCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 48 | CurrencyBalanceStatusID | int | YES | Current currency balance operational status: 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. Latest status from FiatCurrencyBalancesStatuses (RNDesc=1 by EventTimestamp). (Tier 2 — SP_eMoney_Dim_Account) |
| 49 | CurrencyBalanceStatus | varchar(50) | YES | Currency balance status display name for CurrencyBalanceStatusID, resolved from eMoney_Dictionary_CurrencyBalanceStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 50 | CurrencyBalanceStatusTime | datetime | YES | EventTimestamp of the most recent status change for this currency balance (from FiatCurrencyBalancesStatuses, RNDesc=1). (Tier 2 — SP_eMoney_Dim_Account) |
| 51 | ProviderDesc | varchar(50) | YES | Provider name for this account (e.g., Tribe), sourced from AccountsProviderHoldersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |
| 52 | ProviderCurrencyBalanceID | int | YES | Provider-side currency balance identifier from CurrencyBalancesProvidersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.7 Bank Account Details

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 53 | BankAccountID | int | YES | Auto-incrementing surrogate primary key. (Tier 1 — dbo.FiatBankAccount) |
| 54 | BankAccountIsExternal | int | YES | Classifies the bank account: 0=internal platform bank account (linked to currency balance), 1=external customer payee bank account (standalone). Determines how the account is used in payment flows. (Tier 1 — dbo.FiatBankAccount) |
| 55 | BankAccountName | nvarchar(100) | YES | Full name of the bank account holder. Masked with dynamic data masking (DDM) for PII protection - only privileged users see the actual value. Renamed from FiatBankAccount.FullName. (Tier 1 — dbo.FiatBankAccount) |
| 56 | BankAccountNumber | int | YES | Bank account number. Masked for PII protection. Format varies by region (UK: 8 digits, other regions vary). (Tier 1 — dbo.FiatBankAccount) |
| 57 | BankAccountSortCode | int | YES | UK bank sort code (6 digits, e.g., "040004"). Used together with BankAccountNumber for UK Faster Payments and Bacs transfers. NULL for non-UK accounts. (Tier 1 — dbo.FiatBankAccount) |
| 58 | BankAccountIBAN | varchar(200) | YES | International Bank Account Number. Masked for PII protection. Used for SEPA transfers in EU/EEA. NULL for non-IBAN accounts (e.g., UK-only sort code accounts). (Tier 1 — dbo.FiatBankAccount) |
| 59 | BankAccountBIC | varchar(200) | YES | Bank Identifier Code (SWIFT/BIC). Identifies the bank for international transfers. Used alongside IBAN for SEPA payments. (Tier 1 — dbo.FiatBankAccount) |

### 4.8 Fiat Account Create & Status

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 60 | AccountCreateTime | datetime | YES | UTC timestamp when this account record was created in the data warehouse. Renamed from FiatAccount.Created. (Tier 1 — dbo.FiatAccount) |
| 61 | AccountCreateDate | date | YES | Date portion of AccountCreateTime. DWH-derived: CAST(AccountCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 62 | AccountCreateDateID | int | YES | YYYYMMDD integer date key for AccountCreateDate. DWH-derived: CONVERT(VARCHAR(8), AccountCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 63 | AccountStatusID | int | YES | Current account lifecycle status: 0=Active, 1=Suspended, 2=Deleted. Latest StatusType from FiatAccountStatuses (RNDesc=1 by Created). (Tier 1 — dbo.FiatAccountStatuses) |
| 64 | AccountStatus | varchar(50) | YES | Account status display name for AccountStatusID, resolved from eMoney_Dictionary_AccountStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 65 | AccountStatusTime | datetime | YES | Created timestamp of the most recent account status change event (from FiatAccountStatuses, RNDesc=1). (Tier 2 — SP_eMoney_Dim_Account) |

### 4.9 Account Program & Sub-Program (Current)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 66 | AccountProgramID | int | YES | Account program type: 0=Unknown, 1=card, 2=iban. Determines the fundamental product type (card-based vs IBAN-based banking). DWH note: current program; ISNULL(latest FiatAccountsProperties record, original FiatAccount.AccountProgramId) — reflects most recent program upgrade/downgrade. (Tier 1 — dbo.FiatAccount) |
| 67 | AccountProgram | varchar(50) | YES | Account program display name for AccountProgramID, resolved from eMoney_Dictionary_AccountProgram. (Tier 2 — SP_eMoney_Dim_Account) |
| 68 | AccountSubProgramID | int | YES | Specific sub-program variant: 1-16 (e.g., Card Premium UK, IBAN EU Green). FK to eMoney_dbo.SubPrograms. NULL if not yet assigned to a specific variant. DWH note: current sub-program; ISNULL(latest FiatAccountsProperties record, original FiatAccount.SubProgramId). (Tier 1 — dbo.FiatAccount) |
| 69 | AccountSubProgram | varchar(50) | YES | Sub-program display name for AccountSubProgramID, resolved from eMoney_dbo.SubPrograms (16 active programs across UK/EU/AUS regions). (Tier 2 — SP_eMoney_Dim_Account) |
| 70 | AccountPropertiesTime | datetime | YES | Created timestamp of the most recent FiatAccountsProperties record for this account (the source of AccountProgramID/AccountSubProgramID). NULL if no properties record exists. (Tier 2 — SP_eMoney_Dim_Account) |
| 71 | AccountPropertiesDate | date | YES | Date portion of AccountPropertiesTime. DWH-derived: CAST(AccountPropertiesTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 72 | CountAccountProgramChanges | int | YES | Number of distinct program types this account has had. Set to 0 when ≤1 (i.e., never changed). N≥2 means the account has changed program N times. (Tier 2 — SP_eMoney_Dim_Account) |
| 73 | CountAccountSubProgramChanges | int | YES | Number of distinct sub-programs this account has had. Set to 0 when ≤1 (never changed). N≥2 means the account has changed sub-program N times. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.10 Provider & Seniority

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 74 | ProviderHolderID | int | YES | Provider-side holder identifier from AccountsProviderHoldersMapping via eMoney_Account_Mappings. Identifies the customer's account in the Tribe payment provider system. (Tier 2 — SP_eMoney_Dim_Account) |
| 75 | Seniority_TP_RegDate | int | YES | Months since TP (trading platform) registration date (DATEDIFF MONTH between RegisteredReal and @Date=yesterday). NULL when TP_RegDate is NULL. (Tier 2 — SP_eMoney_Dim_Account) |
| 76 | Seniority_TP_FTDDate | int | YES | Months since first trading platform deposit date (DATEDIFF MONTH between FirstDepositDate and @Date=yesterday). NULL when TP_FTDDate is NULL or is the sentinel '19000101'. (Tier 2 — SP_eMoney_Dim_Account) |
| 77 | Seniority_eTM_RegDate | int | YES | Months since eToro Money account creation date (DATEDIFF MONTH between AccountCreateTime and @Date=yesterday). Measures eTM-specific tenure. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.11 Card Details

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 78 | HasCard | int | YES | 1 if this account has an associated card (CardID IS NOT NULL), 0 otherwise. (Tier 2 — SP_eMoney_Dim_Account) |
| 79 | CardID | int | YES | Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. (Tier 1 — dbo.FiatCards) |
| 80 | CardCreateTime | datetime | YES | UTC timestamp when this card record was created in the data warehouse. Renamed from FiatCards.Created. (Tier 1 — dbo.FiatCards) |
| 81 | CardCreateDate | date | YES | Date portion of CardCreateTime. DWH-derived: CAST(CardCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 82 | CardCreateDateID | int | YES | YYYYMMDD integer date key for CardCreateDate. DWH-derived: CONVERT(VARCHAR(8), CardCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 83 | CardStatusID | int | YES | Current card lifecycle status: 0=NotActivated, 1=Activated, 2=Blocked, 3=Suspended, 4=Risk, 5=Stolen, 6=Lost, 7=Expired, 8=Fraud. Latest status from FiatCardStatuses (RNDesc=1 by EventTimestamp). (Tier 1 — dbo.FiatCardStatuses) |
| 84 | CardStatus | varchar(50) | YES | Card status display name for CardStatusID, resolved from eMoney_Dictionary_CardStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 85 | CardStatusExpirationTime | datetime | YES | Card expiration date at the time of this status event. (Tier 1 — dbo.FiatCardStatuses) |
| 86 | CardStatusTime | datetime | YES | When the status change occurred in the source system. (Tier 1 — dbo.FiatCardStatuses) |
| 87 | ProviderCardID | int | YES | Provider-side card identifier from CardsProvidersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |

### 4.12 Metadata

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 88 | UpdateDate | datetime | YES | GETDATE() at INSERT time. Marks when the daily ETL refresh ran; not a business timestamp. (Tier 2 — SP_eMoney_Dim_Account) |
| 89 | Entity | varchar(250) | YES | eToro Money entity name resolved from eMoney_EntityByCurrencyISO_MappingStatic via CurrencyBalanceISOCode. Identifies the regulatory/legal entity serving this balance. ISNULL → 'N/A' when no mapping exists. Values observed: Malta, UK, AUS. (Tier 2 — SP_eMoney_Dim_Account) |

---

## 5. Lineage

### 5.1 Production Sources

| DWH Column Group | Production Source | Source Column(s) | Transform |
|-----------------|-------------------|-----------------|-----------|
| CurrencyBalanceID | FiatDwhDB.dbo.FiatCurrencyBalances | Id | Passthrough |
| AccountID, GCID | FiatDwhDB.dbo.FiatAccount | Id, Gcid | Passthrough |
| AccountCreateTime | FiatDwhDB.dbo.FiatAccount | Created | Rename |
| CID, ClubID, RegulationID, CountryID, PlayerStatusID, IsValidCustomer, TP_RegDate, TP_FTDDate | DWH_dbo.Dim_Customer | RealCID, PlayerLevelID, RegulationID, CountryID, PlayerStatusID, IsValidCustomer, RegisteredReal, FirstDepositDate | Passthrough/rename/CAST DATE |
| RegClubID, RegRegulationID, RegCountryID, RegPlayerStatusID | DWH_dbo.Fact_SnapshotCustomer | PlayerLevelID, RegulationID, CountryID, PlayerStatusID | Snapshot at AccountCreateDateID range |
| AccountStatusID, AccountStatusTime | FiatDwhDB.dbo.FiatAccountStatuses | StatusType, Created | Latest record (RNDesc=1) |
| AccountProgramID, AccountSubProgramID, RegAccountProgramID, RegAccountSubProgramID | FiatDwhDB.dbo.FiatAccount + FiatAccountsProperties | AccountProgramId, SubProgramId | ISNULL(latest from Properties, original from Account) |
| BankAccountID, BankAccountIsExternal, BankAccountName, BankAccountNumber, BankAccountSortCode, BankAccountIBAN, BankAccountBIC | FiatDwhDB.dbo.FiatBankAccount | Id, IsExternal, FullName, BankAccountNumber, SortCode, Iban, Bic | Passthrough (FullName renamed) |
| CurrencyBalanceISOCode, CurrencyBalanceCreateTime | FiatDwhDB.dbo.FiatCurrencyBalances | CurrencyISON, Created | Rename |
| CurrencyBalanceStatusID, CurrencyBalanceStatusTime | FiatDwhDB.dbo.FiatCurrencyBalancesStatuses | StatusType, EventTimestamp | Latest record (RNDesc=1) |
| CardID, CardCreateTime | FiatDwhDB.dbo.FiatCards | Id, Created | Passthrough/rename |
| CardStatusID, CardStatusExpirationTime, CardStatusTime | FiatDwhDB.dbo.FiatCardStatuses | CardStatusId, ExpirationDate, EventTimestamp | Latest record (RNDesc=1) |
| Entity | eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic | Entity | LEFT JOIN on CurrencyBalanceISOCode |
| IsTestAccount | eMoney_google_sheets.emoney_test_users | gcid | Fivetran Google Sheets; CASE lookup |
| All computed fields | SP_eMoney_Dim_Account | — | CASE/DATEDIFF/ROW_NUMBER |

### 5.2 ETL Pipeline

```
FiatDwhDB (eToro Money Fiat DWH)
├── dbo.FiatCurrencyBalances ─────────────────────┐
├── dbo.FiatAccount ──────────────────────────────┤
├── dbo.FiatAccountStatuses (RNDesc=1) ───────────┤
├── dbo.FiatAccountsProperties (RNDesc=1) ────────┤  eMoney_dbo.eMoney_Account_Mappings
├── dbo.FiatCurrencyBalancesStatuses (RNDesc=1) ──┤  (SP_eMoney_Account_Mappings, daily refresh)
├── dbo.FiatBankAccount ──────────────────────────┤
├── dbo.FiatCards ────────────────────────────────┤
└── dbo.FiatCardStatuses (RNDesc=1) ─────────────┘
                                                   │
                                                   ▼
                              SP_eMoney_Dim_Account (11-step, @Date=yesterday)
                                     │
                    ┌────────────────┼────────────────┐
                    ▼                ▼                ▼
         DWH_dbo.Dim_Customer  Fact_SnapshotCustomer  eMoney_EntityByCurrencyISO_MappingStatic
         (current attributes)  (reg-time snapshot)    (entity by currency)
                    │
              eMoney_google_sheets.emoney_test_users (Fivetran)
                    │
                    ▼
         eMoney_dbo.eMoney_Dim_Account
         (DELETE all + INSERT, daily)
                    │
                    ▼
         UC: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | eToro trading platform customer |
| GCID | DWH_dbo.Dim_Customer.GCID | Cross-platform identity link |
| ClubID | DWH_dbo.Dim_PlayerLevel.PlayerLevelID | Club level lookup |
| RegulationID | DWH_dbo.Dim_Regulation.DWHRegulationID | Regulation lookup |
| CountryID | DWH_dbo.Dim_Country.CountryID | Country lookup |
| PlayerStatusID | DWH_dbo.Dim_PlayerStatus.PlayerStatusID | Player status lookup |
| AccountProgramID | eMoney_dbo.eMoney_Dictionary_AccountProgram.AccountProgramID | Program type |
| AccountSubProgramID | eMoney_dbo.SubPrograms.Id | Sub-program variant |
| CardStatusID | eMoney_dbo.eMoney_Dictionary_CardStatus.CardStatusID | Card status lookup |
| AccountStatusID | eMoney_dbo.eMoney_Dictionary_AccountStatus.AccountStatusID | Account status lookup |
| CurrencyBalanceStatusID | eMoney_dbo.eMoney_Dictionary_CurrencyBalanceStatus.CurrencyBalanceStatusID | Balance status lookup |
| Entity | eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic | Legal entity mapping |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| eMoney_dbo.eMoney_Dim_Transaction | CID | Transaction CID join |
| eMoney_dbo.eMoney_Fact_Transaction_Status | CID | Transaction status CID join |
| eMoney_dbo.eMoneyClientBalance | CurrencyBalanceID | Daily balance reconciliation |
| eMoney_dbo.eMoney_Panel_FirstDates | CID | First dates panel |
| eMoney_dbo.eMoney_Reports_AcquisitionFunnel | CID | Acquisition funnel reporting |
| eMoney_dbo.v_eMoney_Dim_Account | — | View wrapper (67 of 89 columns; WHERE today's UpdateDate) |

---

## 7. Sample Queries

### 7.1 Active eTM customers by entity and account program

```sql
SELECT
    da.Entity,
    da.AccountProgram,
    COUNT(DISTINCT da.CID) AS CustomerCount
FROM eMoney_dbo.eMoney_Dim_Account da WITH(NOLOCK)
WHERE da.IsValidETM = 1
  AND da.GCID_Unique_Count = 1
  AND da.AccountStatusID = 0  -- Active
GROUP BY da.Entity, da.AccountProgram
ORDER BY da.Entity, CustomerCount DESC;
```

### 7.2 Customers who changed regulation since eTM onboarding

```sql
SELECT
    da.CID,
    da.GCID,
    da.RegRegulation AS RegAtOnboarding,
    da.Regulation AS CurrentReg,
    da.AccountCreateDate,
    da.RegulationID,
    da.RegRegulationID
FROM eMoney_dbo.eMoney_Dim_Account da WITH(NOLOCK)
WHERE da.HasRegulationChanged = 1
  AND da.GCID_Unique_Count = 1
  AND da.IsValidETM = 1
ORDER BY da.AccountCreateDate DESC;
```

### 7.3 GBP IBAN holders in UK entity with active card

```sql
SELECT
    da.CurrencyBalanceID,
    da.CID,
    da.AccountSubProgram,
    da.CardStatus,
    da.CardCreateDate
FROM eMoney_dbo.eMoney_Dim_Account da WITH(NOLOCK)
WHERE da.Entity = 'UK'
  AND da.CurrencyBalanceISOCode = 826  -- GBP
  AND da.AccountProgramID = 2           -- IBAN
  AND da.HasCard = 1
  AND da.CardStatusID = 1               -- Activated
  AND da.GCID_Unique_Count = 1
ORDER BY da.CardCreateDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-20 | Quality: 8.8/10 | Phases: P1-P10A/14 (P10 Atlassian skipped — MCP unavailable)*
*Tiers: 29 T1, 60 T2, 0 T3, 0 T4, 0 T5 | Elements: 89/89*
*Object: eMoney_dbo.eMoney_Dim_Account | Type: Table | Production Source: FiatDwhDB via SP_eMoney_Dim_Account*
