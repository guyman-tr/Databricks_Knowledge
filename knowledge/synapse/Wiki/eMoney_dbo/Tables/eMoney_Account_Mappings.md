# eMoney_dbo.eMoney_Account_Mappings

> Consolidated account linkage table joining every eToro Money customer's currency balance, bank account, fiat account identity, and debit card into a single row per currency balance. 2,034,012 rows as of 2026-04-13, spanning all active eToro Money accounts (EUR=67%, GBP=31%, AUD=2%, DKK<1%). Refreshed via DELETE+INSERT by SP_eMoney_Account_Mappings. Primary use case: one-stop lookup to map a CurrencyBalanceID → GCID → AccountID → CardID → ProviderIDs without multi-table joins.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB mirrors: FiatCurrencyBalances, FiatBankAccount, FiatAccount, FiatCards, plus provider mapping tables. Written by SP_eMoney_Account_Mappings. |
| **Refresh** | Daily DELETE + INSERT (full rebuild) |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

`eMoney_Account_Mappings` is the central cross-reference table for eToro Money account infrastructure. It denormalizes five separate entity tables — currency balances, bank accounts, fiat accounts, provider holder mappings, and card mappings — into a single row per currency balance. This eliminates repetitive multi-table joins in downstream analytics and reporting.

**Grain**: One row per currency balance (CurrencyBalanceID). A customer (GCID) with two currency balances (e.g., EUR + GBP) will have two rows. The 2,034,012 rows correspond to all provisioned currency balances, predominantly IBAN accounts (iban=97%, card=3%).

**Key linkage chain**:
- `CurrencyBalanceID` → `AccountID` → `GCID` (customer identity)
- `CurrencyBalanceID` → `ProviderCurrencyBalanceID` (Tribe balance reference)
- `AccountID` → `ProviderHolderID` (Tribe holder reference)
- `AccountID` → `CardID` → `ProviderCardID` (card reference, NULL for IBAN accounts)

**Provider**: Tribe is the sole payment provider (ProviderDesc='Tribe' for 99.99% of rows). The 227 NULL ProviderDesc rows are currency balances not yet mapped to a provider.

**Bank account deduplication**: When multiple bank account events exist for a currency balance, only the most recent is selected (ROW_NUMBER OVER PARTITION BY CurrencyBalanceId ORDER BY EventTimestamp DESC = 1). Similarly for cards: only the most recently created card per account is retained.

**Load pattern**: DELETE + INSERT (not TRUNCATE + INSERT). This is unusual and may preserve certain index states. The table is completely rebuilt each run.

---

## 2. Business Logic

### 2.1 Currency Balance as the Primary Grain

**What**: The mapping table's primary entity is the currency balance, not the account.

**Columns Involved**: `CurrencyBalanceID`, `AccountID`, `GCID`, `CurrencyBalanceISON`

**Rules**:
- A customer (GCID) with EUR + GBP accounts has two rows (two CurrencyBalanceIDs)
- ISO 4217 numeric currency codes: 978=EUR (1,353,787 rows), 826=GBP (638,925), 36=AUD (40,038), 208=DKK (1,262)
- Account-level columns (AccountID, GCID, AccountProgram, AccountSubProgram, ProviderHolderID) repeat across all of a customer's currency balance rows

### 2.2 Latest Card and Bank Account Deduplication

**What**: When multiple records exist per entity, only the most recent is retained.

**Columns Involved**: `BankAccountID`, `CardID`

**Rules**:
- Bank account: `ROW_NUMBER() OVER(PARTITION BY CurrencyBalanceId ORDER BY EventTimestamp DESC) = 1` → only the latest bank account event per balance
- Card: `ROW_NUMBER() OVER(PARTITION BY AccountId ORDER BY Created DESC) = 1` → only the most recently created card per account
- CardID is NULL for IBAN accounts (1,939,357 rows = 95.3%); only card-program accounts have CardIDs

### 2.3 Provider ID Bridge

**What**: The mapping table is the bridge between internal IDs and Tribe provider IDs.

**Columns Involved**: `ProviderCurrencyBalanceID`, `ProviderHolderID`, `ProviderCardID`, `ProviderDesc`

**Rules**:
- `ProviderCurrencyBalanceID`: Tribe's account ID for the currency balance ("AccountId" in Tribe terminology)
- `ProviderHolderID`: Tribe's holder ID for the account (used in all provider API calls)
- `ProviderCardID`: Tribe's card ID for the customer's card
- `ProviderDesc`: resolved provider name (currently always 'Tribe'); 227 NULLs = unmapped balances

### 2.4 PII Columns

**What**: Bank account details contain masked PII in the FiatDwhDB source.

**Columns Involved**: `BankAccountName`, `BankAccountNumber`, `BankAccountIBAN`

**Rules**:
- In FiatDwhDB, these fields use SQL Server Dynamic Data Masking (DDM) — restricted access
- In eMoney_dbo (Synapse), the same values are cast to wider types but are no longer DDM-masked (Synapse does not support DDM) — treat as PII in queries
- `BankAccountNumber` is cast from nvarchar to INT — non-numeric characters will cause conversion errors if any exist
- `BankAccountSortCode` similarly cast to INT — UK only (NULL for EU/AUS accounts)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) allows efficient customer-level aggregations and joins to eMoney_Dim_Account (also HASH on GCID). Multi-currency customers will have rows on the same node. Queries on CurrencyBalanceID or AccountID require shuffle. HEAP is appropriate for a full-rebuild daily table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find all accounts for a GCID | WHERE GCID = ? GROUP BY CurrencyBalanceID, CurrencyBalanceISON |
| Cross-reference ProviderHolderID → GCID | WHERE ProviderHolderID = ? → GCID, AccountID |
| IBAN accounts with bank details | WHERE AccountProgram='iban' AND BankAccountIBAN IS NOT NULL |
| Card accounts with Tribe card ID | WHERE CardID IS NOT NULL AND ProviderCardID IS NOT NULL |
| Currency breakdown | GROUP BY CurrencyBalanceISON, AccountProgram |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| eMoney_dbo.eMoney_Dim_Account | ON am.GCID = mda.GCID | Extend with account status, KYC flags, FMI/FMO dates |
| eMoney_dbo.eMoney_Dim_Transaction | ON am.AccountID = t.AccountId | Transaction history per account |
| DWH_dbo.Dim_Customer | ON am.GCID = dc.GCID | Customer profile (club, country, regulation) |
| eMoney_dbo.eMoney_Currency_Mapping_ISO | ON am.CurrencyBalanceISON = iso.CurrencyNumericCode_ISO | ISO alpha currency code |

### 3.4 Gotchas

- **GCID not unique**: Customers with two currency balances have two rows. Always GROUP BY or DISTINCT when counting customers.
- **CardID NULL for IBAN accounts**: 95.3% of rows have no card. Joining on CardID without NULL handling will silently drop IBAN accounts.
- **BankAccountID NULL**: 436 rows (0.02%) — currency balances provisioned but not yet linked to a bank account.
- **DELETE+INSERT not TRUNCATE**: Unlike most eMoney tables, this table uses DELETE (no identity reset). Check if downstream tools rely on row counts between runs.
- **BankAccountSortCode/BankAccountNumber as INT**: Only UK accounts have sort codes. NULL for non-UK; non-numeric values in source will fail the CAST.
- **Latest card only**: If a customer had multiple card versions (e.g., replacement), only the most recent card is retained. Historical card-level analysis requires FiatCards directly.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream FiatDwhDB wiki; original source confirmed |
| Tier 2 | Derived from SP code analysis, DDL, and live data sampling — no upstream wiki with this column |
| Tier 3 | Inferred from column name, type, and context |
| Tier 4 | Best-available guess; requires reviewer verification |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CurrencyBalanceID | int | YES | Auto-incrementing surrogate PK. Referenced by FiatTransactions, FiatCurrencyBalancesStatuses, CurrencyBalancesProvidersMapping, PaymentSpecifications, FiatBankAccount, and BalanceReports. DWH note: renamed from `Id` in dbo.FiatCurrencyBalances. (Tier 1 — dbo.FiatCurrencyBalances) |
| 2 | CurrencyBalanceISON | int | YES | ISO 4217 numeric currency code. E.g., "826"=GBP, "978"=EUR, "036"=AUD. See ISO Currency Info. Indexed for currency-based queries. DWH note: renamed from `CurrencyISON` and CAST to INT. Live values: 978=EUR(67%), 826=GBP(31%), 36=AUD(2%), 208=DKK(<1%). (Tier 1 — dbo.FiatCurrencyBalances) |
| 3 | CurrencyBalanceCreateTime | datetime | YES | UTC timestamp when this currency balance was created in the data warehouse. DWH note: renamed from `Created`. (Tier 1 — dbo.FiatCurrencyBalances) |
| 4 | ProviderDesc | varchar(50) | YES | Provider name for this currency balance, resolved from eMoney_Dictionary_Provider via CurrencyBalancesProvidersMapping. Currently 'Tribe' (99.99%); NULL for 227 unmapped balances. (Tier 2 — SP_eMoney_Account_Mappings) |
| 5 | ProviderCurrencyBalanceID | int | YES | The provider's identifier for this currency balance. Used for provider API calls and reconciliation. DWH note: renamed from `CurrencyBalanceProviderId` and CAST to INT; called "AccountId" in Tribe's system. (Tier 1 — dbo.CurrencyBalancesProvidersMapping) |
| 6 | BankAccountID | int | YES | Auto-incrementing surrogate primary key. DWH note: renamed from `Id` in dbo.FiatBankAccount; latest bank account per CurrencyBalanceId (ROW_NUMBER by EventTimestamp DESC). NULL for card accounts or unlinked balances (436 rows). (Tier 1 — dbo.FiatBankAccount) |
| 7 | BankAccountIsExternal | int | YES | Classifies the bank account: 0=internal platform bank account (linked to currency balance), 1=external customer payee bank account (standalone). Determines how the account is used in payment flows. DWH note: renamed from `IsExternal`. (Tier 1 — dbo.FiatBankAccount) |
| 8 | BankAccountName | nvarchar(100) | YES | Full name of the bank account holder. Masked with dynamic data masking (DDM) for PII protection - only privileged users see the actual value. DWH note: renamed from `FullName`; CAST to NVARCHAR(200); DDM not enforced in Synapse — treat as PII. (Tier 1 — dbo.FiatBankAccount) |
| 9 | BankAccountNumber | int | YES | Bank account number. Masked for PII protection. Format varies by region (UK: 8 digits, other regions vary). DWH note: CAST from nvarchar to INT — UK account numbers only (sort code accounts). (Tier 1 — dbo.FiatBankAccount) |
| 10 | BankAccountSortCode | int | YES | UK bank sort code (6 digits, e.g., "040004"). Used together with BankAccountNumber for UK Faster Payments and Bacs transfers. NULL for non-UK accounts. DWH note: renamed from `SortCode`; CAST to INT. (Tier 1 — dbo.FiatBankAccount) |
| 11 | BankAccountIBAN | varchar(200) | YES | International Bank Account Number. Masked for PII protection. Used for SEPA transfers in EU/EEA. NULL for non-IBAN accounts (e.g., UK-only sort code accounts). DWH note: renamed from `Iban`; CAST to NVARCHAR(200); 40,407 NULL rows. (Tier 1 — dbo.FiatBankAccount) |
| 12 | BankAccountBIC | varchar(200) | YES | Bank Identifier Code (SWIFT/BIC). Identifies the bank for international transfers. Used alongside IBAN for SEPA payments. DWH note: renamed from `Bic`; CAST to NVARCHAR(200). (Tier 1 — dbo.FiatBankAccount) |
| 13 | AccountID | int | YES | Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. DWH note: renamed from `Id` in dbo.FiatAccount. (Tier 1 — dbo.FiatAccount) |
| 14 | GCID | int | YES | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. DWH note: renamed from `Gcid`. (Tier 1 — dbo.FiatAccount) |
| 15 | AccountCreateTime | datetime | YES | UTC timestamp when this account record was created in the data warehouse. Indexed for time-range queries. DWH note: renamed from `Created`. (Tier 1 — dbo.FiatAccount) |
| 16 | AccountProgramID | int | YES | Account program type: 0=Unknown, 1=card (default), 2=iban. See Account Program. (Dictionary.AccountPrograms). Determines the fundamental product type (card-based vs IBAN-based banking). DWH note: renamed from `AccountProgramId`. Live: iban=97%, card=3%. (Tier 1 — dbo.FiatAccount) |
| 17 | AccountProgram | varchar(50) | YES | Account program display name for AccountProgramID, resolved from eMoney_Dictionary_AccountProgram. Values: 'card', 'iban'. NULL if AccountProgramID=0 (Unknown). (Tier 2 — SP_eMoney_Account_Mappings) |
| 18 | AccountSubProgramID | int | YES | Specific sub-program variant: 1-16 (e.g., Card Premium UK, IBAN EU Green). See Sub-Program. FK to dbo.SubPrograms. NULL if not yet assigned to a specific variant. DWH note: renamed from `SubProgramId`. (Tier 1 — dbo.FiatAccount) |
| 19 | AccountSubProgram | varchar(50) | YES | Account sub-program display name for AccountSubProgramID, resolved from eMoney_Dictionary_AccountSubProgram (e.g., 'IBAN EU Green', 'IBAN Standard UK', 'Card Standard UK'). NULL if AccountSubProgramID is NULL. (Tier 2 — SP_eMoney_Account_Mappings) |
| 20 | ProviderHolderID | int | YES | The external provider's (Tribe) identifier for this account holder. Used in all provider API interactions and support queries. Stored as string to accommodate different provider ID formats. DWH note: renamed from `ProviderHolderId`; CAST to INT. (Tier 1 — dbo.AccountsProviderHoldersMapping) |
| 21 | CardID | int | YES | Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. DWH note: renamed from `Id` in dbo.FiatCards; latest card per AccountId (ROW_NUMBER by Created DESC). NULL for IBAN accounts (95.3% of rows). (Tier 1 — dbo.FiatCards) |
| 22 | CardCreateTime | datetime | YES | UTC timestamp when this card record was created in the data warehouse. DWH note: renamed from `Created`. NULL for IBAN accounts. (Tier 1 — dbo.FiatCards) |
| 23 | ProviderCardID | int | YES | The provider's identifier for this card in their system. Used for provider API calls. DWH note: renamed from `CardProviderId` in dbo.CardsProvidersMapping; CAST to INT. NULL for IBAN accounts. (Tier 1 — dbo.CardsProvidersMapping) |
| 24 | UpdateDate | datetime | YES | ETL execution timestamp set to GETDATE() when SP_eMoney_Account_Mappings ran. Reflects data freshness, not entity creation time. (Tier 2 — SP_eMoney_Account_Mappings) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Intermediate Source Table | Source Column | Transform |
|---------------|---------------------------|---------------|-----------|
| CurrencyBalanceID | FiatCurrencyBalances | Id | Renamed passthrough |
| CurrencyBalanceISON | FiatCurrencyBalances | CurrencyISON | Renamed + CAST to INT |
| CurrencyBalanceCreateTime | FiatCurrencyBalances | Created | Renamed passthrough |
| ProviderDesc | eMoney_Dictionary_Provider | Provider | JOIN-denormalized via CurrencyBalancesProvidersMapping |
| ProviderCurrencyBalanceID | CurrencyBalancesProvidersMapping | CurrencyBalanceProviderId | Renamed + CAST to INT |
| BankAccountID | FiatBankAccount | Id | Renamed; latest per CurrencyBalanceId by EventTimestamp |
| BankAccountIsExternal | FiatBankAccount | IsExternal | Renamed passthrough |
| BankAccountName | FiatBankAccount | FullName | Renamed + CAST to NVARCHAR(200) |
| BankAccountNumber | FiatBankAccount | BankAccountNumber | CAST to INT |
| BankAccountSortCode | FiatBankAccount | SortCode | Renamed + CAST to INT |
| BankAccountIBAN | FiatBankAccount | Iban | Renamed + CAST to NVARCHAR(200) |
| BankAccountBIC | FiatBankAccount | Bic | Renamed + CAST to NVARCHAR(200) |
| AccountID | FiatAccount | Id | Renamed passthrough |
| GCID | FiatAccount | Gcid | Renamed passthrough |
| AccountCreateTime | FiatAccount | Created | Renamed passthrough |
| AccountProgramID | FiatAccount | AccountProgramId | Renamed passthrough |
| AccountProgram | eMoney_Dictionary_AccountProgram | AccountProgram | JOIN-denormalized name |
| AccountSubProgramID | FiatAccount | SubProgramId | Renamed passthrough |
| AccountSubProgram | eMoney_Dictionary_AccountSubProgram | AccountSubProgram | JOIN-denormalized name |
| ProviderHolderID | AccountsProviderHoldersMapping | ProviderHolderId | Renamed + CAST to INT |
| CardID | FiatCards | Id | Renamed; latest card per AccountId by Created |
| CardCreateTime | FiatCards | Created | Renamed passthrough |
| ProviderCardID | CardsProvidersMapping | CardProviderId | Renamed + CAST to INT |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
FiatDwhDB mirrors in eMoney_dbo:
  eMoney_dbo.FiatCurrencyBalances  (source: FiatDwhDB.dbo.FiatCurrencyBalances)
  eMoney_dbo.CurrencyBalancesProvidersMapping
  eMoney_dbo.FiatBankAccount
  eMoney_dbo.FiatAccount
  eMoney_dbo.AccountsProviderHoldersMapping
  eMoney_dbo.FiatCards
  eMoney_dbo.CardsProvidersMapping
  eMoney_dbo.eMoney_Dictionary_Provider (provider name)
  eMoney_dbo.eMoney_Dictionary_AccountProgram (program name)
  eMoney_dbo.eMoney_Dictionary_AccountSubProgram (sub-program name)
  |-- SP_eMoney_Account_Mappings (4 steps):  ---|
  |     Step 1: #currency_balance (balance + provider + bank data)
  |     Step 2: #fiat_account (account + program names + holder ID)
  |     Step 3: #fiat_card (latest card + provider card ID)
  |     Step 4: DELETE FROM eMoney_Account_Mappings + INSERT (full rebuild)
  v
eMoney_dbo.eMoney_Account_Mappings (2,034,012 rows, daily refresh)
  |-- Generic Pipeline (Gold export) ---|
  v
bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_account_mappings
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CurrencyBalanceID | eMoney_dbo.FiatCurrencyBalances | FK to internal balance entity |
| AccountID | eMoney_dbo.FiatAccount | FK to fiat account |
| GCID | eMoney_dbo.eMoney_Dim_Account | Join key for eTM account details |
| GCID | DWH_dbo.Dim_Customer | Join key for customer profile |
| AccountProgramID | eMoney_dbo.eMoney_Dictionary_AccountProgram | 0=Unknown, 1=card, 2=iban |
| AccountSubProgramID | eMoney_dbo.eMoney_Dictionary_AccountSubProgram | Sub-program variant |
| CardID | eMoney_dbo.FiatCards | FK to card entity |

### 6.2 Referenced By (other objects point to this)

| Object | Reference Type | Notes |
|--------|---------------|-------|
| eMoney_Dim_Account | Cross-reference (via GCID) | AccountProgram/SubProgram baseline captured from this table at account creation |
| Analytics / BI reports | Consumer | Provider ID bridge for operational investigations |

---

## 7. Sample Queries

### Find All Currency Balances and Bank Details for a Customer

```sql
SELECT
    am.GCID,
    am.CurrencyBalanceID,
    am.CurrencyBalanceISON,
    am.AccountProgram,
    am.AccountSubProgram,
    am.BankAccountIBAN,
    am.BankAccountBIC,
    am.ProviderCurrencyBalanceID,
    am.ProviderHolderID
FROM [eMoney_dbo].[eMoney_Account_Mappings] am
WHERE am.GCID = 18417756
ORDER BY am.CurrencyBalanceISON;
```

### Provider ID Lookup by Tribe Holder ID

```sql
SELECT
    am.ProviderHolderID,
    am.GCID,
    am.AccountID,
    am.AccountProgram,
    am.ProviderCurrencyBalanceID,
    am.CurrencyBalanceISON
FROM [eMoney_dbo].[eMoney_Account_Mappings] am
WHERE am.ProviderHolderID = 16588734;
```

### Currency Distribution by Program

```sql
SELECT
    am.AccountProgram,
    am.CurrencyBalanceISON,
    COUNT(*) AS account_count
FROM [eMoney_dbo].[eMoney_Account_Mappings] am
GROUP BY am.AccountProgram, am.CurrencyBalanceISON
ORDER BY account_count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table during documentation. The FiatDwhDB source documentation references a Confluence pattern: "Get the accountId from the providerHolderId (Tribe)" — see AccountsProviderHoldersMapping in BankingDBs/FiatDwhDB/Wiki.

---

*Generated: 2026-04-21 | Quality: 9.1/10 | Phases: 13/14*
*Tiers: 20 T1, 4 T2, 0 T3, 0 T4 | Elements: 24/24, Logic: 9/10, ETL: 9/10*
*Object: eMoney_dbo.eMoney_Account_Mappings | Type: Table | Production Source: FiatDwhDB mirrors via SP_eMoney_Account_Mappings*
