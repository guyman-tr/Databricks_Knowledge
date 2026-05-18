# eMoney_dbo.eMoneyClientBalance

> Daily account-level balance table for the eToro Money fiat platform; tracks opening balance, 12 transaction flow components, closing balance (BO and computed), reconciliation gaps, and full reporting-currency conversions for all active Tribe accounts across UK, Malta, AUS, and DK entities. Computed by SP_eMoney_ClientBalance from three Tribe ETL staging tables plus DWH dimension lookups.

| Property | Value |
|----------|-------|
| Schema | eMoney_dbo |
| Object type | Table |
| Distribution | HASH(AccountId) |
| Index | CLUSTERED COLUMNSTORE INDEX |
| Rows (approx) | ~1.19B |
| Date range | 2023-12-29 → 2026-04-12 |
| Writer SP | SP_eMoney_ClientBalance (1073 lines; @d DATE param) |
| ETL pattern | Daily DELETE WHERE BalanceDateID=@dreport_i + INSERT |
| Columns (live) | 72 (SSDT stale at 45; 27 added via ALTER TABLE 2026-01-20) |
| UC target | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance |

---

## 1. Object Purpose

`eMoneyClientBalance` is the primary daily balance reconciliation table for the eToro Money fiat platform. For each Tribe account (`AccountId`), it captures the full intraday money movement picture: what the account held at day open, how it changed through banking transfers, card activity, eToro platform loads/unloads, adjustments, and fees, and what Tribe's back-office system reports as the closing balance. The computed closing balance (`ClosingBalanceCalc`) is independently derived and compared to the Tribe back-office closing balance (`ClosingBalanceBO`) to produce the reconciliation gap (`ClosingBalanceGAP`), which is the primary data quality signal used by the eToro Money finance team.

From 2026-01-20, the table was extended with full reporting-currency (RepCur) conversions of every financial column, plus FX components to separate pure business activity from currency revaluation effects.

**Primary use cases:**
- Daily balance reconciliation for eToro Money finance operations
- Per-account transaction flow breakdown (card, banking, eToro platform, fees)
- Multi-currency FX exposure and gain/loss analysis (post-2026-01-20)
- Linking Tribe accounts to eToro DWH user identities (GCID/CID)

---

## 2. Business Context

### 2.1 eToro Money Fiat Platform Architecture

eToro Money is eToro's regulated e-money product. Tribe Payments provides the underlying card and banking infrastructure. The DWH receives daily extract files from Tribe:
- **ETL_AccountSnapshot**: Tribe's authoritative balance file (settled balance per account per day)
- **ETL_AccountsActivities**: All non-card transactions (banking, eToro wallet transfers, adjustments)
- **ETL_SettlementsTransactions**: Card network settlement transactions

The SP_eMoney_ClientBalance processes these three files daily to build the account-level balance ledger.

### 2.2 Balance Date vs. File Date

A critical design detail: Tribe's balance files always arrive one day late. The business date to reconcile (@dreport = @d) corresponds to balance files dated @d+1 (@date). This means:
- `BalanceDate` = yesterday (business date)
- ETL_AccountSnapshot closing balance is read with `DateID = @d_i` (today's integer)
- ETL_AccountSnapshot opening balance is read with `DateID = @dreport_i` (yesterday's integer)

### 2.3 Opening Balance Priority Chain

Opening balance is populated in priority order:
1. **Primary (steady state)**: `eMoneyClientBalance.ClosingBalanceBO` from `BalanceDateID = @dreport_prev_i` (two days ago's closing balance as today's opening)
2. **First-fill fallback**: `ETL_AccountSnapshot.SettledBalance` for `DateID = @dreport_i` (used only when no prior eMoneyClientBalance row exists)

### 2.4 Multi-Entity FX Architecture (Added 2026-01-20)

With AUS (AUD) and DK (DKK) entities launched in late 2025, reporting across entities required a consistent currency. Each entity has a **reporting currency** mapped in `eMoney_EntityByCurrencyISO_MappingStatic`:
- eToro Money UK → GBP
- eToro Money Malta → EUR (also for DKK accounts)
- eToro Money AUS → AUD

Every financial column is replicated as `{Column}RepCur = {Column} * CrossExchangeRate2`. The FX components (`FX`, `PositiveFX`, `FXGAP`) separate currency revaluation from actual transactions, enabling clean P&L reporting across entities.

### 2.5 IsExistingUser Resolution

Tribe accounts are linked to eToro DWH users via two JOIN paths:
1. `AccountId = eMoney_Dim_Account.ProviderCurrencyBalanceID` (preferred — account-level)
2. `HolderId = eMoney_Dim_Account.ProviderHolderID` (fallback — holder-level)

Both paths filter `GCID_Unique_Count=1` to avoid ambiguous resolutions. A post-load UPDATE backfills GCID/CID/IsExistingUser for rows with `BalanceDateID >= 20250701` where GCID was initially NULL, addressing a known mapping lag after the July 2025 DIM rebuild.

---

## 3. Source Tables

| Source | Role | Join Key |
|--------|------|----------|
| eMoney_dbo.ETL_AccountSnapshot | Closing balance (BO), opening fallback, account metadata | DateID |
| eMoney_dbo.ETL_AccountsActivities | Banking/eToro/adjustment transactions | DateID, AccountId; Network IN ('Internal Payment','External Payment'); TC NOT IN (6,14,15,24,25,64) |
| eMoney_dbo.ETL_SettlementsTransactions | Card settlements | DateID, AccountId |
| eMoney_dbo.eMoneyClientBalance (self) | Prior-day closing as today's opening | BalanceDateID = @dreport_prev_i |
| eMoney_dbo.eMoney_Dim_Account | GCID, CID, AccountSubProgram, IsTest | ProviderCurrencyBalanceID / ProviderHolderID; GCID_Unique_Count=1 |
| eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic | Entity, HolderCurrency, ReportingCurrency | CurrencyISO = CurrencyIson |
| BI_DB_dbo.External_Cmrdb_FxRate | ExchangeRate, CrossExchangeRate | IsOld=0, AddedBy IS NULL, ExchangeDate > GETDATE()-60 |
| DWH_dbo.Fact_CurrencyPriceWithSplit | USDApproxRate, CrossExchangeRate2 | InstrumentID, OccurredDateID |
| DWH_dbo.Dim_Instrument | Reporting/holder instrument metadata | InstrumentID |

---

## 4. Data Elements

### 4.1 Date / ID Dimensions

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| BalanceDate | date | Business date this row represents; equals @d input param (= yesterday relative to load). All rows for a given run share this date. | T2 |
| BalanceDateID | int | Integer YYYYMMDD of BalanceDate; used as the DELETE key for idempotent daily reload. | T2 |

### 4.2 Account Identity

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| AccountId | int | Tribe fiat account identifier. Distribution hash key. Each account has exactly one currency denomination (CurrencyIson). | T2 |
| HolderId | int | Tribe holder (customer) identifier. One holder may have multiple accounts (one per currency). | T2 |
| ProgramId | int | Tribe program identifier. Maps to specific product configurations: 39=UK CARD GBP, 175=UK IBANO, 176=EU TEST IBANO, 177=EU IBANO, 178=UK FTD, 179=EU FTD, 180=UK GBP FOR UAE, 181=EU TEST BC, 182=EU Card, 183=Banking Circle AUD Account, 184=Banking Circle DKK Account, 185=Banking Circle DKK Test, 186=Banking Circle AUD Test. | T2 |
| Program | nvarchar(256) | Human-readable program label derived from ProgramId CASE expression. 'NA' for any ProgramId not in the 13 hardcoded values. | T2 |
| CurrencyIson | int | ISO 4217 numeric currency code for this account (826=GBP, 978=EUR, 36=AUD, 208=DKK). | T2 |
| AccountStatus | nvarchar(256) | Tribe account status shortcode: A=Active, S=Suspended, B=Blocked, P=Spend only, R=Receive only. Distribution (live): A=92.3%, S=6.5%, B=0.55%, P=0.53%, R=0.05%. | T2 |
| AccountStatusDescription | nvarchar(256) | Full text description of AccountStatus: 'Active', 'Suspended', 'Blocked', 'Spend only', 'Receive only'. | T2 |
| Entity | varchar(17) | eToro legal entity derived from CurrencyIson via eMoney_EntityByCurrencyISO_MappingStatic: 'eToro Money UK', 'eToro Money Malta', 'eToro Money AUS'. 'New' for 131 rows where CurrencyIson not in mapping table. | T2 |
| HolderCurrency | varchar(256) | ISO alpha currency code for this account (GBP, EUR, AUD, DKK). NULL for ~966M pre-mapping rows (loaded before entity mapping was populated for all CurrencyIson values). | T2 |
| ReportingCurrency | varchar(256) | Entity reporting currency: GBP (UK), EUR (Malta, including DKK accounts), AUD (AUS). NULL for same ~966M pre-mapping rows. | T2 |

### 4.3 User Resolution

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| GCID | int | eToro Global Customer ID. Resolved via eMoney_Dim_Account on ProviderCurrencyBalanceID (primary) or ProviderHolderID (fallback); GCID_Unique_Count=1 only. NULL for ~3.16M rows of unlinked Tribe accounts. | T2 |
| CID | int | eToro Customer ID paired with GCID. | T2 |
| AccountSubProgram | nvarchar(256) | Sub-program label copied from eMoney_Dim_Account (e.g., 'IBAN EU Green', 'IBAN EU Black', 'Card Green EU'). NULL if GCID unresolved. | T2 |
| IsExistingUser | int | 1 if account resolved to an eToro DWH user (GCID IS NOT NULL); 0 otherwise. 99.7% of rows are 1. Post-load UPDATE backfills this for BalanceDateID >= 20250701 where initial resolution failed. | T2 |
| IsTest | int | 1 if this is a test account per eMoney_Dim_Account.IsTestAccount; 0 for confirmed production accounts; NULL for ~966M rows loaded before IsTest column addition (~Sep 2025). | T2 |
| UpdateDate | datetime | GETDATE() load timestamp. | T2 |
| USDApproxRate | decimal(16,6) | Approximate USD conversion rate for this account's holder currency, from DWH_dbo.Fact_CurrencyPriceWithSplit mid-price (Ask+Bid)/2, adjusted for quote direction (IsToUSD flag). | T2 |

### 4.4 Opening Balance

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| OpeningBalance | decimal(16,6) | Total account balance at business date open in holder currency. Cascades from prior day's eMoneyClientBalance.ClosingBalanceBO (steady state) or ETL_AccountSnapshot.SettledBalance (first-fill fallback). | T2 |
| OpeningPositiveBalance | decimal(16,6) | Positive-only component of OpeningBalance; equals MAX(0, OpeningBalance). Used to track positive balance FX exposure separately from negative balances. | T2 |

### 4.5 Transaction Flows (Holder Currency)

All transaction flow columns use ISNULL(..., 0) — never NULL; zero for accounts with no activity in that category.

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| BankPayIns | decimal(16,6) | Sum of all inbound banking transfers: External Payment with positive HolderAmount (excl. TC=66) + TC=65 inbound return + TC=13/LoadSource=33 internal return. | T2 |
| BankPayOuts | decimal(16,6) | Sum of all outbound banking transfers: External Payment with negative HolderAmount (excl. TC=65) + TC=66 outbound return + TC=11/LoadSource=33. | T2 |
| Card_POS | decimal(16,6) | Sum of point-of-sale card transactions from ETL_SettlementsTransactions WHERE TransactionCode NOT IN (3,8). | T2 |
| Card_ATM | decimal(16,6) | Sum of ATM cash withdrawal transactions from ETL_SettlementsTransactions WHERE TransactionCode IN (3,8). | T2 |
| EtoroDeposits | decimal(16,6) | Sum of eToro platform wallet loads: TC=1 (Load), LoadType=1 (eWallet), LoadSource IN (30=External client Wallet, 35=local currency debit, 25=eToro). | T2 |
| EtoroCashouts | decimal(16,6) | Sum of eToro platform wallet unloads: TC=4 (Unload), LoadType=1 (eWallet), LoadSource IN (30,35,25). | T2 |
| EtoroC2FDeposits | decimal(16,6) | Sum of crypto-to-fiat conversion loads: TC=1 (Load), LoadType=1 (eWallet), LoadSource=34 (Crypto). | T2 |
| BalanceAdjustments | decimal(16,6) | Sum of manual and API balance adjustments: TC IN (11=CREDIT_ADJUSTMENT, 13=DEBIT_ADJUSTMENT), LoadSource IN (31=GUI, 32=PM API). | T2 |
| ChargeBackAdjustments | decimal(16,6) | Sum of chargeback dispute credits: TC=79 (DISPUTE_CREDIT_ADJUSTMENT). | T2 |
| ATMFee | decimal(16,6) | Sum of ATM fee charges from ETL_SettlementsTransactions WHERE F0FeeName='ATM fee'. | T2 |
| FxFee | decimal(16,6) | Sum of FX conversion fees from ETL_SettlementsTransactions.FxFeeAmount. | T2 |
| OtherFee | decimal(16,6) | Sum of non-ATM settlement fees from ETL_SettlementsTransactions WHERE F0FeeName<>'ATM fee'. | T2 |

### 4.6 Closing Balance & Reconciliation

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| ClosingBalanceCalc | decimal(16,6) | DWH-computed closing balance: ROUND(OpeningBalance + BankPayIns + BankPayOuts + Card_POS + Card_ATM + EtoroDeposits + EtoroCashouts + EtoroC2FDeposits + BalanceAdjustments + ChargeBackAdjustments + ATMFee + FxFee + OtherFee, 2). | T2 |
| ClosingBalanceBO | decimal(16,6) | Tribe back-office closing balance from ETL_AccountSnapshot.SettledBalance for DateID=@d_i (tomorrow's file = today's closing). Authoritative source of truth. | T2 |
| ClosingBalanceGAP | decimal(16,6) | Reconciliation gap: ClosingBalanceCalc - ClosingBalanceBO. Near-zero expected. Systematic non-zero gaps trigger SP_eMoney_Client_Balance_Check_Exceptions_Gap alert. | T2 |
| OpeningBalanceGAP | decimal(16,6) | Opening balance gap: difference between prior day's recorded closing balance and today's opening balance from snapshot file. 0 if no prior eMoneyClientBalance row (first fill). | T2 |
| ClosingNegativeBalanceBO | decimal(16,6) | Negative balance component of ClosingBalanceBO: CASE WHEN ClosingBalanceBO < 0 THEN ClosingBalanceBO ELSE 0 END. | T2 |
| NegativeBalanceMovement | decimal(16,6) | Change in negative balance: OpeningNegativeBalance - ClosingNegativeBalanceBO. Used in positive balance closing calc to preserve correct total. | T2 |
| ClosingPositiveBalanceBO | decimal(16,6) | Positive balance component of ClosingBalanceBO: CASE WHEN ClosingBalanceBO >= 0 THEN ClosingBalanceBO ELSE 0 END. | T2 |
| ClosingPositiveBalanceCalc | decimal(16,6) | DWH-computed positive closing balance: ROUND(OpeningPositiveBalance + all 12 transaction components + NegativeBalanceMovement, 2). | T2 |
| ClosingPositiveBalanceGAP | decimal(16,6) | Positive balance reconciliation gap: ClosingPositiveBalanceCalc - ClosingPositiveBalanceBO. | T2 |
| CheckCalc | decimal(16,6) | Internal consistency check: ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO. Should equal zero; non-zero indicates positive/negative decomposition error. | T2 |
| TransOutOfDate | decimal(16,6) | Sum of HolderAmount from transactions where TransactionDateTime date ≠ BalanceDate (late-arriving records from both settlements and activities). Tracks timing mismatch that contributes to ClosingBalanceGAP. | T2 |

### 4.7 FX Rate Columns (Added 2026-01-20)

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| CrossExchangeRate | decimal(24,12) | Holder-to-reporting-currency FX rate on business date (CrossExchangeRatePrev from prior day). 1 if HolderCurrency = ReportingCurrency. Source: BI_DB_dbo.External_Cmrdb_FxRate. | T2 |
| ExchangeRate | decimal(24,12) | Reporting-to-holder FX rate on business date (= PriceFromReportingCurrencyToHolderCurrencyBusnessDate). Inverse of CrossExchangeRate. | T2 |
| PriceFX | decimal(24,12) | Day-over-day FX rate change: CrossExchangeRate2 - CrossExchangeRatePrev2. Used to compute FX gain/loss columns. | T2 |
| FX | decimal(24,12) | FX gain/loss on total opening balance: OpeningBalance * PriceFX. Isolates currency revaluation from business activity. | T2 |
| PositiveFX | decimal(24,12) | FX gain/loss on positive opening balance component: OpeningPositiveBalance * PriceFX. | T2 |
| FXGAP | decimal(12,6) | FX reconciliation residual: ClosingBalanceBORepCur - OpeningBalanceRepCur - Delta (sum of all RepCur transaction flows) - FX. Near-zero expected; non-zero indicates rate sourcing inconsistency. | T2 |

### 4.8 Reporting Currency (RepCur) Columns (Added 2026-01-20)

All RepCur columns are `{source_column} * CrossExchangeRate2`. `CrossExchangeRate2 = 1/ExchangeRate`. Same-currency accounts have CrossExchangeRate2=1 (no conversion applied). **NULL for rows loaded before 2026-01-20** when the ALTER TABLE additions were not yet in place.

| Column | Source Column | Tier |
|--------|---------------|------|
| ClosingBalanceBORepCur | ClosingBalanceBO | T2 |
| OpeningBalanceRepCur | OpeningBalance | T2 |
| OpeningPositiveBalanceRepCur | OpeningPositiveBalance | T2 |
| BankPayInsRepCur | BankPayIns | T2 |
| BankPayOutsRepCur | BankPayOuts | T2 |
| Card_POSRepCur | Card_POS | T2 |
| Card_ATMRepCur | Card_ATM | T2 |
| EtoroDepositsRepCur | EtoroDeposits | T2 |
| EtoroCashoutsRepCur | EtoroCashouts | T2 |
| EtoroC2FDepositsRepCur | EtoroC2FDeposits | T2 |
| BalanceAdjustmentsRepCur | BalanceAdjustments | T2 |
| ChargeBackAdjustmentsRepCur | ChargeBackAdjustments | T2 |
| ATMFeeRepCur | ATMFee | T2 |
| FxFeeRepCur | FxFee | T2 |
| OtherFeeRepCur | OtherFee | T2 |
| ClosingBalanceCalcRepCur | ClosingBalanceCalc | T2 |
| ClosingBalanceGAPRepCur | ClosingBalanceGAP | T2 |
| ClosingNegativeBalanceBORepCur | ClosingNegativeBalanceBO | T2 |
| NegativeBalanceMovementRepCur | NegativeBalanceMovement | T2 |
| ClosingPositiveBalanceBORepCur | ClosingPositiveBalanceBO | T2 |
| ClosingPositiveBalanceCalcRepCur | ClosingPositiveBalanceCalc | T2 |
| ClosingPositiveBalanceGAPRepCur | ClosingPositiveBalanceGAP | T2 |

---

## 5. Business Logic

### 5.1 Daily ETL Flow

```
1. Declare @d (business date), @date (@d+1 = file date), @dreport (@d), @dreport_prev (@d-1)
2. Build #ISO_Mapping: entity/currency/instrument metadata from eMoney_EntityByCurrencyISO_MappingStatic + Dim_Instrument
3. Build #preprate → #rate: Cmrdb FX rates for @dreport (business date)
4. Build #rateprev: Cmrdb FX rates for @dreport_prev (prior business date)
5. Build #AccountsActivities: DISTINCT from ETL_AccountsActivities WHERE DateID=@dreport_i
   Network IN ('Internal Payment','External Payment'), TransactionCode NOT IN (6,14,15,24,25,64)
6. Build #AccountsActivitiesOutOfDate: transactions where TransactionDateTime date ≠ @dreport
7. Build #Settlements: DISTINCT from ETL_SettlementsTransactions WHERE DateID=@dreport_i
8. Build #SettlementsOutOfDate: settlements where TransactionDateTime date ≠ @dreport
9. Build #balanceclosing → #balancecl: ClosingBalanceBO from ETL_AccountSnapshot @d_i; RNDesc=1 for dedup
10. Build #balanceopening → #balanceop: OpeningBalance from ETL_AccountSnapshot @dreport_i; RNDesc=1
11. Build #opbalanceclientbalance: prior day's ClosingBalanceBO from eMoneyClientBalance WHERE BalanceDateID=@dreport_prev_i
12. Build #balance: JOIN closing + opening + prior_close + ISO_Mapping; opening balance cascade logic
13. Build #nocardtx: aggregate banking/eToro/adjustment flows from #AccountsActivities
14. Build #card: aggregate card flows from #Settlements
15. Build #final: JOIN all components; compute ClosingBalanceCalc, gaps, decompositions, Program CASE
16. Build #dim / #dim2: DISTINCT GCID/CID/AccountSubProgram/IsTest from eMoney_Dim_Account; GCID_Unique_Count=1
17. Build #split: FX rates from Fact_CurrencyPriceWithSplit + Cmrdb; compute CrossExchangeRate2, PriceFix2, USDApproxRate
18. Build #output: JOIN #final + #dim + #dim2 + #split; add IsExistingUser, COALESCE GCID, add FX rate columns
19. Build #outputwithrepcurnorounds: add all RepCur columns = {col} * CrossExchangeRate2
20. DELETE FROM eMoneyClientBalance WHERE BalanceDateID=@dreport_i
21. INSERT INTO eMoneyClientBalance from #outputwithrepcurnorounds (72 columns)
22. Post-load UPDATE: backfill GCID/CID/AccountSubProgram/IsExistingUser for BalanceDateID >= 20250701 WHERE GCID IS NULL
23. EXEC SP_eMoney_Client_Balance_Check_Opening_Balance @d  (alert)
24. EXEC SP_eMoney_Client_Balance_Check_Exceptions_Gap @d   (alert)
```

### 5.2 Transaction Code Exclusions

ETL_AccountsActivities filters out TransactionCodes 6, 14, 15, 24, 25, 64. LoadType 35 (local currency debits/credits, added SR-271356 2024-09-16) is INCLUDED in both deposits (LoadSource IN 30,35,25) and cashouts.

### 5.3 Reporting Currency Conversion Pattern

For cross-entity aggregation:
```
CrossExchangeRate2 = 1 / ExchangeRate
{Column}RepCur     = {Column} * CrossExchangeRate2
```
Where ExchangeRate = price from ReportingCurrency to HolderCurrency on business date. For same-currency accounts, CrossExchangeRate2 = 1 (no conversion). Null for accounts where entity mapping is missing.

---

## 6. Dependencies

### 6.1 Upstream Tables

| Table | Dependency | Notes |
|-------|-----------|-------|
| eMoney_dbo.ETL_AccountSnapshot | Hard — closing/opening balances | Must be loaded before SP run |
| eMoney_dbo.ETL_AccountsActivities | Hard — banking/eToro flows | Must be loaded before SP run |
| eMoney_dbo.ETL_SettlementsTransactions | Hard — card flows | Must be loaded before SP run |
| eMoney_dbo.eMoney_Dim_Account | Soft — GCID/CID resolution | Pre-load UPDATE handles missing; SP still loads without it |
| eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic | Soft — entity/currency mapping | Missing mapping → Entity='New', NULL HolderCurrency/ReportingCurrency |
| BI_DB_dbo.External_Cmrdb_FxRate | Hard (for RepCur) | Required for FX rate columns; filtered IsOld=0, AddedBy IS NULL |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Hard (for USDApproxRate) | Required for USD rate and CrossExchangeRate2 computation |

### 6.2 Known Downstream Consumers

- Finance reconciliation reporting (primary consumer of ClosingBalanceGAP, ClosingBalanceBORepCur)
- SP_eMoney_Client_Balance_Check_Opening_Balance (reads this table for prior day close)
- SP_eMoney_Client_Balance_Check_Exceptions_Gap (reads this table post-load for alert validation)
- Self-referential: SP reads prior day's eMoneyClientBalance.ClosingBalanceBO as today's opening balance

---

## 7. Data Quality Notes

### 7.1 ClosingBalanceGAP Non-Zero Cases

Expected sources of non-zero gap:
- **TransOutOfDate**: transactions dated differently from business date are included in flows but may not match the snapshot balance
- **Timing**: settlement files arriving after the daily cut cause systematic negative gaps
- **First-fill rows**: OpeningBalance uses ETL_AccountSnapshot (may differ slightly from Tribe's internal opening)

### 7.2 IsTest NULL Population (~966M rows)

IsTest is NULL for rows loaded before the IsTest column was added (~Sep 2025 with AUS entity launch). These rows should be treated as non-test (IsTest = 0 ≈ NULL) for production analytics. Use `ISNULL(IsTest, 0)` in filters.

### 7.3 HolderCurrency / ReportingCurrency NULL Population (~966M rows)

Rows loaded before the entity/currency mapping was fully expanded have NULL HolderCurrency and ReportingCurrency. These pre-date the RepCur column additions (2026-01-20) and will also have NULL for all RepCur columns. For time-series analysis, filter `BalanceDate >= '2026-01-20'` to work with fully-populated RepCur data.

### 7.4 SSDT DDL Stale

The SSDT DDL (45 columns) does not reflect the live table (72 columns). The 27 additional columns (CrossExchangeRate through FXGAP, minus ClosingBalanceBORepCur which was in SSDT but also re-added with changed precision) were added via ALTER TABLE commands in the SP comment block. `ClosingBalanceBORepCur` in SSDT has type `decimal(16,6)`; live table has `decimal(24,12)` after the 2026-01-20 ALTER.

---

## 8. UC Migration Notes

| Property | Value |
|----------|-------|
| UC target | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance |
| Column mapping | Direct rename; all 72 columns carry over |
| Partitioning suggestion | PARTITION BY BalanceDateID (integer; enables efficient date-range pruning) |
| RepCur column backfill | Rows before 2026-01-20 have NULL RepCur columns; migration must preserve NULLs or backfill with NULL for pre-date rows |
| IsTest backfill | Rows before ~Sep 2025 have NULL IsTest; ISNULL(IsTest, 0) pattern recommended |
| SSDT alignment | DDL must be updated to match 72-column live schema before UC migration |

---

*Wiki generated: 2026-04-20 | Quality: 8.7/10 | Phases completed: P1, P2, P3, P8, P9, P10B, P11 | Tier distribution: T2=72 (100%)*
