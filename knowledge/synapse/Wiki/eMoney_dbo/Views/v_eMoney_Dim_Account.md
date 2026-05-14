# eMoney_dbo.v_eMoney_Dim_Account

> Live operational view of eMoney_Dim_Account (2,034,012-row base table) that shows only today's rows — returns data solely on days when SP_eMoney_Dim_Account has refreshed (base table UpdateDate = GETDATE()). Selects 78 of 89 base columns, excluding account-program change tracking and entity fields. Limited to TOP 1000 rows (no ORDER BY). Returns 0 rows on non-SP-run days; base table last updated 2026-04-13.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | View |
| **Production Source** | eMoney_dbo.eMoney_Dim_Account (SELECT pass-through with date filter) |
| **Refresh** | Live query against eMoney_Dim_Account; no materialization |
| **Synapse Distribution** | N/A (view) |
| **Synapse Index** | N/A (view) |
| **Row Count** | 0 (sampled 2026-04-21; base table last updated 2026-04-13; view returns data only on refresh days) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not in Gold layer |

---

## 1. Business Meaning

`v_eMoney_Dim_Account` is a live operational view over `eMoney_Dim_Account` (the central eToro Money account dimension). It provides a **today-only window** into the daily refresh result: on any given day that SP_eMoney_Dim_Account ran, this view exposes the freshly loaded data.

The view achieves this with a CTE-based date filter:
```sql
WITH a AS (SELECT MAX(UpdateDate) FROM eMoney_Dim_Account)
SELECT TOP (1000) ... 
WHERE CAST(GETDATE() AS DATE) = (SELECT CAST(UpdateDate AS DATE) FROM a)
```

This means:
- **On refresh days**: returns up to 1,000 rows from the current batch (UpdateDate = today)
- **On non-refresh days**: returns 0 rows — the view is effectively empty until the next SP run

**TOP (1000) without ORDER BY**: The view limits to 1,000 rows with no ordering clause. This means the 1,000 rows returned are arbitrary — not the "most recent" or "most important" accounts. The view is designed for quick sampling/validation that a refresh occurred, not for analytical queries.

**Excluded columns (vs eMoney_Dim_Account)**: The view omits 11 columns from the base table:
- Registration-time program tracking: `RegAccountProgramID`, `RegAccountProgram`, `RegAccountSubProgramID`, `RegAccountSubProgram`
- Program change counts and timestamps: `HasAccountProgramChanged`, `HasAccountSubProgramChanged`, `AccountPropertiesTime`, `AccountPropertiesDate`, `CountAccountProgramChanges`, `CountAccountSubProgramChanges`
- Entity mapping: `Entity`

---

## 2. Business Logic

### 2.1 Today-Only Date Filter

**What**: The view uses a dynamic WHERE clause to return only rows from the most recent SP_eMoney_Dim_Account refresh, and only if that refresh occurred today.

**Columns Involved**: `UpdateDate` (from base table, exposed in view)

**Rules**:
- CTE `a` selects `MAX(UpdateDate)` from `eMoney_Dim_Account`
- WHERE clause: `CAST(GETDATE() AS DATE) = CAST(UpdateDate FROM a AS DATE)`
- If today's date matches the SP run date → rows returned
- If today's date is different (e.g., weekend, holiday, SP did not run) → 0 rows returned

### 2.2 TOP 1000 Sampling Semantics

**What**: The view limits output to 1,000 rows without an ORDER BY clause.

**Rules**:
- Row selection is non-deterministic without ORDER BY — result set varies between executions
- The view is intended as a quick existence-check or sample, not a full data source
- For full data, query `eMoney_Dim_Account` directly
- GCID_Unique_Count=1 filter should still be applied for customer-level analytics

### 2.3 Column Exclusion Pattern

**What**: The view drops 11 columns from the base table, focusing on identity, status, and financial attributes.

**Rules**:
- Account program change tracking columns are excluded (useful for historical migration analysis but not day-to-day operations)
- Entity column is excluded (requires eMoney_EntityByCurrencyISO_MappingStatic join — may be intentional simplification)
- All binary identity and status columns retained

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

The view inherits the distribution of `eMoney_Dim_Account` (HASH on CID). Queries joining to the view on CID avoid data movement. The date filter against `MAX(UpdateDate)` requires a full scan of the base table's `UpdateDate` column — use the base table directly for large-scale analytics.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Did today's SP_eMoney_Dim_Account run? | `SELECT COUNT(*) FROM v_eMoney_Dim_Account` — 0 = not yet run |
| Sample today's refreshed data | `SELECT TOP 20 * FROM v_eMoney_Dim_Account` |
| Quick entity/program check | `SELECT AccountProgram, COUNT(*) FROM v_eMoney_Dim_Account GROUP BY AccountProgram` |
| Full eTM analysis | Use `eMoney_Dim_Account` directly with `WHERE GCID_Unique_Count=1` |

### 3.3 Common JOINs

The view inherits all JOIN patterns of `eMoney_Dim_Account`. Most useful joins:

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON v.CID = dc.RealCID | Trading profile for today's eTM customers |
| eMoney_dbo.eMoneyClientBalance | ON v.CurrencyBalanceID = cb.CurrencyBalanceID | Today's balance details |

### 3.4 Gotchas

- **Returns 0 rows most of the time**: The view is only non-empty on days when SP_eMoney_Dim_Account ran and `UpdateDate = today`. As of 2026-04-21, base table UpdateDate = 2026-04-13, so view returns 0 rows.
- **TOP 1000 without ORDER BY**: Row selection is non-deterministic. Do not rely on this view for complete data sets.
- **Missing Entity column**: The base table's `Entity` column is not in this view. For entity-level analysis, use `eMoney_Dim_Account` directly.
- **Missing account program change tracking**: `CountAccountProgramChanges`, `HasAccountProgramChanged`, etc., are excluded.
- **GCID_Unique_Count still present**: Apply `WHERE GCID_Unique_Count = 1` for customer-level analysis.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (FiatDwhDB or DWH_dbo); same tier as in eMoney_Dim_Account |
| Tier 2 | Description written from ETL SP code analysis; same tier as in eMoney_Dim_Account |
| Tier 3 | Description inferred from column name and context |
| Tier 4 | Best available — limited evidence |
| Tier 5 | Name only |

*All descriptions are pass-throughs from `eMoney_dbo.eMoney_Dim_Account`. Tier assignments and sources are identical. Snapshot statistics (row counts, percentages) stripped per policy.*

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CurrencyBalanceID | int | YES | Auto-incrementing surrogate PK. Referenced by FiatTransactions, FiatCurrencyBalancesStatuses, CurrencyBalancesProvidersMapping, PaymentSpecifications, FiatBankAccount, and BalanceReports. (Tier 1 — dbo.FiatCurrencyBalances) |
| 2 | AccountID | int | YES | Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. (Tier 1 — dbo.FiatAccount) |
| 3 | GCID | int | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 — dbo.FiatAccount) |
| 4 | CID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 5 | ClubID | int | YES | Customer player-level tier. FK to DWH_dbo.Dim_PlayerLevel. Per dictionary (verified 2026-05-13): 0=N/A, 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (in-house / eToro-employee accounts), 5=Silver, 6=Platinum Plus, 7=Diamond. NOT a Popular Investor signal (PI is tracked by GuruStatusID). NOT a demo flag (demo is AccountTypeID=2). Default=0. (Tier 2 - DWH_dbo.Dim_PlayerLevel)|
| 6 | Club | varchar(50) | YES | Player level display name resolved from DWH_dbo.Dim_PlayerLevel. (Tier 2 — SP_eMoney_Dim_Account) |
| 7 | ClubCategory | varchar(50) | YES | Grouped player level bucket. NoClub=PlayerLevelID 1; LowClub=3 or 5; HighClub=2, 6, or 7; Internal=4; Error=unmapped values. (Tier 2 — SP_eMoney_Dim_Account) |
| 8 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Changes trigger RegulationChangeDate update. (Tier 1 — BackOffice.Customer) |
| 9 | Regulation | varchar(50) | YES | Regulation display name resolved from DWH_dbo.Dim_Regulation. (Tier 2 — SP_eMoney_Dim_Account) |
| 10 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 11 | Country | varchar(50) | YES | Country display name resolved from DWH_dbo.Dim_Country. (Tier 2 — SP_eMoney_Dim_Account) |
| 12 | Region | varchar(50) | YES | Geographic region from DWH_dbo.Dim_Country.Region, resolved via CountryID. (Tier 2 — SP_eMoney_Dim_Account) |
| 13 | PlayerStatusID | int | YES | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Normal; other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 14 | PlayerStatus | varchar(50) | YES | Player status display name resolved from DWH_dbo.Dim_PlayerStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 15 | IsValidETM | int | YES | eToro Money validity flag. 1 when IsValidCustomer=1 AND IsTestAccount=0 AND IsCancelledAccount=0. Standard filter for eTM production analytics. (Tier 2 — SP_eMoney_Dim_Account) |
| 16 | IsValidCustomer | int | YES | DWH-computed: 1 when not Internal (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. Passthrough from Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 17 | IsTestAccount | int | YES | 1 if GCID appears in the Fivetran Google Sheets test-user list (eMoney_google_sheets.emoney_test_users); 0 otherwise. Exclude from all production analytics. (Tier 2 — SP_eMoney_Dim_Account) |
| 18 | IsCancelledAccount | int | YES | 1 when GCID=0 (cancelled accounts are recorded with a zero GCID in FiatDwhDB). (Tier 2 — SP_eMoney_Dim_Account) |
| 19 | GCID_Unique_Count | int | YES | Rank of this currency balance account for its GCID, ordered by AccountCreateTime DESC. 1 = most recently created eMoney account for this customer (the primary account). Customer DWH enrichment columns (CID, ClubID, etc.) are only populated for rank=1 rows. (Tier 2 — SP_eMoney_Dim_Account) |
| 20 | TP_RegDate | date | YES | Account registration date (renamed from Registered). Default=getdate(). DWH note: CAST to DATE (time component discarded); renamed RegisteredReal→TP_RegDate. (Tier 1 — Customer.CustomerStatic) |
| 21 | TP_FTDDate | date | YES | Date of first deposit. DEFAULT='19000101'. Updated from CustomerFinanceDB FTD data with FTDRecoveryDate logic. DWH note: CAST to DATE; renamed FirstDepositDate→TP_FTDDate. Passthrough from Dim_Customer. (Tier 2 — SP_Dim_Customer) |
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
| 32 | HasCustomerInfoChanged | int | YES | 1 if ANY of the following changed since account creation: ClubID, RegulationID, CountryID, PlayerStatusID, AccountProgramID, AccountSubProgramID. Composite of all six individual change flags. (Tier 2 — SP_eMoney_Dim_Account) |
| 33 | HasClubChanged | int | YES | 1 if ClubID (current) ≠ RegClubID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 34 | HasRegulationChanged | int | YES | 1 if RegulationID (current) ≠ RegRegulationID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 35 | HasCountryChanged | int | YES | 1 if CountryID (current) ≠ RegCountryID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 36 | HasPlayerStatusChanged | int | YES | 1 if PlayerStatusID (current) ≠ RegPlayerStatusID (at account creation). (Tier 2 — SP_eMoney_Dim_Account) |
| 37 | CurrencyBalanceISOCode | int | YES | ISO 4217 numeric currency code. E.g., "826"=GBP, "978"=EUR, "036"=AUD. Indexed for currency-based queries. Renamed from FiatCurrencyBalances.CurrencyISON. (Tier 1 — dbo.FiatCurrencyBalances) |
| 38 | CurrencyBalanceISODesc | varchar(50) | YES | Currency display name resolved from eMoney_Currency_Instrument_Mapping_Static via CurrencyBalanceISOCode (where SellCurrencyID=1). (Tier 2 — SP_eMoney_Dim_Account) |
| 39 | CurrencyBalanceCreateTime | datetime | YES | UTC timestamp when this currency balance was created in the data warehouse. Renamed from FiatCurrencyBalances.Created. (Tier 1 — dbo.FiatCurrencyBalances) |
| 40 | CurrencyBalanceCreateDate | date | YES | Date portion of CurrencyBalanceCreateTime. DWH-derived: CAST(CurrencyBalanceCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 41 | CurrencyBalanceCreateDateID | int | YES | YYYYMMDD integer date key for CurrencyBalanceCreateDate. DWH-derived: CONVERT(VARCHAR(8), CurrencyBalanceCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 42 | CurrencyBalanceStatusID | int | YES | Current currency balance operational status: 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. Latest status from FiatCurrencyBalancesStatuses (RNDesc=1 by EventTimestamp). (Tier 2 — SP_eMoney_Dim_Account) |
| 43 | CurrencyBalanceStatus | varchar(50) | YES | Currency balance status display name for CurrencyBalanceStatusID, resolved from eMoney_Dictionary_CurrencyBalanceStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 44 | CurrencyBalanceStatusTime | datetime | YES | EventTimestamp of the most recent status change for this currency balance (from FiatCurrencyBalancesStatuses, RNDesc=1). (Tier 2 — SP_eMoney_Dim_Account) |
| 45 | ProviderDesc | varchar(50) | YES | Provider name for this account (e.g., Tribe), sourced from AccountsProviderHoldersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |
| 46 | ProviderCurrencyBalanceID | int | YES | Provider-side currency balance identifier from CurrencyBalancesProvidersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |
| 47 | BankAccountID | int | YES | Auto-incrementing surrogate primary key. (Tier 1 — dbo.FiatBankAccount) |
| 48 | BankAccountIsExternal | int | YES | Classifies the bank account: 0=internal platform bank account (linked to currency balance), 1=external customer payee bank account (standalone). Determines how the account is used in payment flows. (Tier 1 — dbo.FiatBankAccount) |
| 49 | BankAccountName | nvarchar(100) | YES | Full name of the bank account holder. Masked with dynamic data masking (DDM) for PII protection - only privileged users see the actual value. Renamed from FiatBankAccount.FullName. (Tier 1 — dbo.FiatBankAccount) |
| 50 | BankAccountNumber | int | YES | Bank account number. Masked for PII protection. Format varies by region (UK: 8 digits, other regions vary). (Tier 1 — dbo.FiatBankAccount) |
| 51 | BankAccountSortCode | int | YES | UK bank sort code (6 digits, e.g., "040004"). Used together with BankAccountNumber for UK Faster Payments and Bacs transfers. NULL for non-UK accounts. (Tier 1 — dbo.FiatBankAccount) |
| 52 | BankAccountIBAN | varchar(200) | YES | International Bank Account Number. Masked for PII protection. Used for SEPA transfers in EU/EEA. NULL for non-IBAN accounts (e.g., UK-only sort code accounts). (Tier 1 — dbo.FiatBankAccount) |
| 53 | BankAccountBIC | varchar(200) | YES | Bank Identifier Code (SWIFT/BIC). Identifies the bank for international transfers. Used alongside IBAN for SEPA payments. (Tier 1 — dbo.FiatBankAccount) |
| 54 | AccountCreateTime | datetime | YES | UTC timestamp when this account record was created in the data warehouse. Renamed from FiatAccount.Created. (Tier 1 — dbo.FiatAccount) |
| 55 | AccountCreateDate | date | YES | Date portion of AccountCreateTime. DWH-derived: CAST(AccountCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 56 | AccountCreateDateID | int | YES | YYYYMMDD integer date key for AccountCreateDate. DWH-derived: CONVERT(VARCHAR(8), AccountCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 57 | AccountStatusID | int | YES | Current account lifecycle status: 0=Active, 1=Suspended, 2=Deleted. Latest StatusType from FiatAccountStatuses (RNDesc=1 by Created). (Tier 1 — dbo.FiatAccountStatuses) |
| 58 | AccountStatus | varchar(50) | YES | Account status display name for AccountStatusID, resolved from eMoney_Dictionary_AccountStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 59 | AccountStatusTime | datetime | YES | Created timestamp of the most recent account status change event (from FiatAccountStatuses, RNDesc=1). (Tier 2 — SP_eMoney_Dim_Account) |
| 60 | AccountProgramID | int | YES | Account program type: 0=Unknown, 1=card, 2=iban. Determines the fundamental product type (card-based vs IBAN-based banking). DWH note: current program; ISNULL(latest FiatAccountsProperties record, original FiatAccount.AccountProgramId) — reflects most recent program upgrade/downgrade. (Tier 1 — dbo.FiatAccount) |
| 61 | AccountProgram | varchar(50) | YES | Account program display name for AccountProgramID, resolved from eMoney_Dictionary_AccountProgram. (Tier 2 — SP_eMoney_Dim_Account) |
| 62 | AccountSubProgramID | int | YES | Specific sub-program variant: 1-16 (e.g., Card Premium UK, IBAN EU Green). FK to eMoney_dbo.SubPrograms. NULL if not yet assigned to a specific variant. DWH note: current sub-program; ISNULL(latest FiatAccountsProperties record, original FiatAccount.SubProgramId). (Tier 1 — dbo.FiatAccount) |
| 63 | AccountSubProgram | varchar(50) | YES | Sub-program display name for AccountSubProgramID, resolved from eMoney_dbo.SubPrograms (16 active programs across UK/EU/AUS regions). (Tier 2 — SP_eMoney_Dim_Account) |
| 64 | ProviderHolderID | int | YES | Provider-side holder identifier from AccountsProviderHoldersMapping via eMoney_Account_Mappings. Identifies the customer's account in the Tribe payment provider system. (Tier 2 — SP_eMoney_Dim_Account) |
| 65 | Seniority_TP_RegDate | int | YES | Months since TP (trading platform) registration date (DATEDIFF MONTH between RegisteredReal and @Date=yesterday). NULL when TP_RegDate is NULL. (Tier 2 — SP_eMoney_Dim_Account) |
| 66 | Seniority_TP_FTDDate | int | YES | Months since first trading platform deposit date (DATEDIFF MONTH between FirstDepositDate and @Date=yesterday). NULL when TP_FTDDate is NULL or is the sentinel '19000101'. (Tier 2 — SP_eMoney_Dim_Account) |
| 67 | Seniority_eTM_RegDate | int | YES | Months since eToro Money account creation date (DATEDIFF MONTH between AccountCreateTime and @Date=yesterday). Measures eTM-specific tenure. (Tier 2 — SP_eMoney_Dim_Account) |
| 68 | HasCard | int | YES | 1 if this account has an associated card (CardID IS NOT NULL), 0 otherwise. (Tier 2 — SP_eMoney_Dim_Account) |
| 69 | CardID | int | YES | Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. (Tier 1 — dbo.FiatCards) |
| 70 | CardCreateTime | datetime | YES | UTC timestamp when this card record was created in the data warehouse. Renamed from FiatCards.Created. (Tier 1 — dbo.FiatCards) |
| 71 | CardCreateDate | date | YES | Date portion of CardCreateTime. DWH-derived: CAST(CardCreateTime AS DATE). (Tier 2 — SP_eMoney_Dim_Account) |
| 72 | CardCreateDateID | int | YES | YYYYMMDD integer date key for CardCreateDate. DWH-derived: CONVERT(VARCHAR(8), CardCreateTime, 112). (Tier 2 — SP_eMoney_Dim_Account) |
| 73 | CardStatusID | int | YES | Current card lifecycle status: 0=NotActivated, 1=Activated, 2=Blocked, 3=Suspended, 4=Risk, 5=Stolen, 6=Lost, 7=Expired, 8=Fraud. Latest status from FiatCardStatuses (RNDesc=1 by EventTimestamp). (Tier 1 — dbo.FiatCardStatuses) |
| 74 | CardStatus | varchar(50) | YES | Card status display name for CardStatusID, resolved from eMoney_Dictionary_CardStatus. (Tier 2 — SP_eMoney_Dim_Account) |
| 75 | CardStatusExpirationTime | datetime | YES | Card expiration date at the time of this status event. (Tier 1 — dbo.FiatCardStatuses) |
| 76 | CardStatusTime | datetime | YES | When the status change occurred in the source system. (Tier 1 — dbo.FiatCardStatuses) |
| 77 | ProviderCardID | int | YES | Provider-side card identifier from CardsProvidersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Dim_Account) |
| 78 | UpdateDate | datetime | YES | GETDATE() at INSERT time. Marks when the daily ETL refresh ran; not a business timestamp. (Tier 2 — SP_eMoney_Dim_Account) |

---

## 5. Lineage

### 5.1 Production Sources

All columns are pass-throughs from `eMoney_Dim_Account`. See `eMoney_Dim_Account.md` Section 5.1 for full production source mapping.

| Column Group | Production Source | Notes |
|-------------|-------------------|-------|
| CurrencyBalanceID, CurrencyBalanceISOCode, CurrencyBalanceCreateTime | FiatDwhDB.dbo.FiatCurrencyBalances | Tier 1 passthrough |
| AccountID, GCID, AccountCreateTime, AccountProgramID, AccountSubProgramID, AccountStatusID | FiatDwhDB.dbo.FiatAccount + FiatAccountStatuses | Tier 1 passthrough |
| BankAccount* (7 cols) | FiatDwhDB.dbo.FiatBankAccount | Tier 1 passthrough |
| CardID, CardCreateTime, CardStatusID, CardStatusExpirationTime, CardStatusTime | FiatDwhDB.dbo.FiatCards + FiatCardStatuses | Tier 1 passthrough |
| CID, ClubID, RegulationID, CountryID, PlayerStatusID, TP_RegDate | etoro.Customer.CustomerStatic, etoro.BackOffice.Customer | Tier 1 passthrough |
| All other columns (51 cols) | SP_eMoney_Dim_Account (ETL-computed) | Tier 2 |

### 5.2 ETL Pipeline

```
FiatDwhDB + etoro DB sources
  |-- SP_eMoney_Dim_Account (daily DELETE + INSERT) ---|
  v
eMoney_dbo.eMoney_Dim_Account (2,034,012 rows; UpdateDate = SP run date)
  |-- v_eMoney_Dim_Account (live view, no materialization)
  |   WHERE CAST(GETDATE() AS DATE) = CAST(MAX(UpdateDate) AS DATE)
  |   TOP 1000 (no ORDER BY)
  v
Live view result (0 rows on non-refresh days; up to 1,000 rows on refresh day)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| All 78 columns | eMoney_dbo.eMoney_Dim_Account | Base table — full dependency |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| — | — | No downstream objects documented as referencing this view |

---

## 7. Sample Queries

### 7.1 Check if today's SP_eMoney_Dim_Account has run

```sql
SELECT COUNT(*) AS RefreshCount,
       MAX(UpdateDate) AS LatestUpdateDate
FROM eMoney_dbo.v_eMoney_Dim_Account;
-- RefreshCount > 0 and UpdateDate = today = SP ran today
-- RefreshCount = 0 = SP has not run yet today
```

### 7.2 Quick sample of today's account refresh

```sql
SELECT TOP 10
    CurrencyBalanceID,
    GCID,
    CID,
    AccountProgram,
    CurrencyBalanceISOCode,
    AccountStatusID,
    UpdateDate
FROM eMoney_dbo.v_eMoney_Dim_Account
WHERE GCID_Unique_Count = 1;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this view.

---

*Generated: 2026-04-21 | Quality: 8.9/10 | Phases: P1/P2/P4/P5/P6/P7/P10A/P10B (P3 view, P8-P9 no writer SP, P10 Atlassian skipped)*
*Tiers: 27 T1, 51 T2, 0 T3, 0 T4, 0 T5 | Elements: 78/78*
*Object: eMoney_dbo.v_eMoney_Dim_Account | Type: View | Production Source: eMoney_dbo.eMoney_Dim_Account (pass-through with date filter)*
