# Column Lineage: eMoney_dbo.eMoneyClientBalance

**Generated**: 2026-04-20 | **Batch**: 8 | **Object type**: Table

## ETL Pipeline

```
eMoney_dbo.ETL_AccountSnapshot (DateID=@d_i = today)    ──→  ClosingBalanceBO, AccountStatus, HolderId, ProgramId, CurrencyIson
eMoney_dbo.ETL_AccountSnapshot (DateID=@dreport_i)       ──→  OpeningBalance (first-fill fallback)
eMoney_dbo.eMoneyClientBalance (BalanceDateID=prev_day)  ──→  OpeningBalance (primary self-join cascade)
eMoney_dbo.ETL_AccountsActivities (DateID=@dreport_i)   ──→  BankPayIns/Outs, EtoroDeposits/Cashouts/C2F,
                                                                BalanceAdjustments, ChargeBackAdjustments
eMoney_dbo.ETL_SettlementsTransactions (DateID=@dreport_i) → Card_POS, Card_ATM, ATMFee, FxFee, OtherFee
eMoney_dbo.eMoney_Dim_Account (GCID_Unique_Count=1)      ──→  GCID, CID, AccountSubProgram, IsExistingUser, IsTest
eMoney_dbo.eMoney_EntityByCurrencyISO_MappingStatic      ──→  Entity, HolderCurrency, ReportingCurrency
BI_DB_dbo.External_Cmrdb_FxRate (IsOld=0, AddedBy IS NULL) → ExchangeRate, CrossExchangeRate
DWH_dbo.Fact_CurrencyPriceWithSplit (OccurredDateID)     ──→  USDApproxRate, CrossExchangeRate2/PriceFX
                        │
                        ▼
          SP_eMoney_ClientBalance (@d DATE param)
          Daily DELETE WHERE BalanceDateID=@dreport_i
          INSERT from #outputwithrepcurnorounds
                        │
                        ▼
          eMoney_dbo.eMoneyClientBalance
          72 cols | HASH(AccountId) | CLUSTERED COLUMNSTORE
          Post-load UPDATE: backfill GCID/CID/IsExistingUser
          WHERE BalanceDateID >= 20250701 AND GCID IS NULL
```

*Note: SSDT DDL (45 cols) is stale. Live table has 72 columns — 27 added via ALTER TABLE on 2026-01-20 (RepCur extensions + FX components). This lineage reflects the live SP INSERT column list.*

---

## Column Lineage Map

### Date / ID Dimensions

| # | Column | Type | Source | Tier | Notes |
|---|--------|------|--------|------|-------|
| 1 | BalanceDate | date | @dreport = @d (input param) | T2 | Business date to reconcile = "yesterday" |
| 2 | BalanceDateID | int | CAST(CONVERT(VARCHAR(8), @dreport, 112) AS INT) | T2 | Integer YYYYMMDD of BalanceDate |

### Account Dimensions

| # | Column | Type | Source | Tier | Notes |
|---|--------|------|--------|------|-------|
| 3 | AccountId | int | ETL_AccountSnapshot.AccountId CAST AS INT | T2 | Tribe fiat account identifier; HASH distribution key |
| 29 | HolderId | int | ETL_AccountSnapshot.HolderId CAST AS INT | T2 | Tribe holder (customer) identifier |
| 30 | ProgramId | int | ETL_AccountSnapshot.ProgramId CAST AS INT | T2 | Tribe program identifier (39=UK CARD GBP, 182=EU Card, 183-186=AUS/DK) |
| 31 | Program | nvarchar(256) | CASE WHEN ProgramId IN (39/175-186) | T2 | Human-readable program label; 13 hardcoded IDs, else 'NA' |
| 32 | CurrencyIson | int | ETL_AccountSnapshot.CurrencyIson CAST AS INT | T2 | ISO 4217 numeric currency code |
| 33 | AccountStatus | nvarchar(256) | ETL_AccountSnapshot.AccountStatus | T2 | Single-char shortcode: A=Active, S=Suspended, B=Blocked, P=Spend only, R=Receive only |
| 34 | AccountStatusDescription | nvarchar(256) | ETL_AccountSnapshot.AccountStatusDescription | T2 | Full text description matching AccountStatus shortcode |
| 35 | Entity | varchar(17) | ISNULL(eMoney_EntityByCurrencyISO_MappingStatic.Entity, 'New') | T2 | Legal entity: 'eToro Money UK', 'eToro Money Malta', 'eToro Money AUS', or 'New' |
| 42 | HolderCurrency | varchar(256) | eMoney_EntityByCurrencyISO_MappingStatic.CurrencyName | T2 | ISO currency alpha code (GBP/EUR/AUD/DKK); NULL for pre-mapping rows (~966M) |
| 43 | ReportingCurrency | varchar(256) | eMoney_EntityByCurrencyISO_MappingStatic.ReportingCurrency | T2 | Entity reporting currency (GBP/EUR/AUD/EUR for DKK); NULL for pre-mapping rows |

### User Resolution

| # | Column | Type | Source | Tier | Notes |
|---|--------|------|--------|------|-------|
| 36 | GCID | int | COALESCE(d.GCID, d1.GCID) from eMoney_Dim_Account | T2 | eToro global customer ID; JOIN via ProviderCurrencyBalanceID (primary) or ProviderHolderID (fallback); GCID_Unique_Count=1 filter |
| 37 | CID | int | COALESCE(d.CID, d1.CID) from eMoney_Dim_Account | T2 | eToro customer ID paired with GCID |
| 38 | AccountSubProgram | nvarchar(256) | COALESCE(d.AccountSubProgram, d1.AccountSubProgram) from eMoney_Dim_Account | T2 | Sub-program label (e.g., 'IBAN EU Green'); copied from eMoney_Dim_Account |
| 39 | IsExistingUser | int | CASE WHEN COALESCE(GCID, d1.GCID) IS NULL THEN 0 ELSE 1 END | T2 | 1 if account resolved to a known eToro user; 0 if no DWH match; backfilled post-load for BalanceDateID >= 20250701 |
| 40 | UpdateDate | datetime | GETDATE() | T2 | Row load timestamp |
| 41 | USDApproxRate | decimal(16,6) | DWH_dbo.Fact_CurrencyPriceWithSplit: (Ask+Bid)/2 if IsToUSD=1, else 1/((Ask+Bid)/2) | T2 | Approximate USD conversion rate for this account's currency |
| 44 | IsTest | int | ISNULL(COALESCE(d.IsTestAccount, d1.IsTestAccount), 0) from eMoney_Dim_Account | T2 | 1 if test account; NULL for ~966M rows pre-dating column addition (~Sep 2025) |

### Opening Balance

| # | Column | Type | Source | Tier | Notes |
|---|--------|------|--------|------|-------|
| 4 | OpeningBalance | decimal(16,6) | CASCADE: first-fill → ETL_AccountSnapshot.SettledBalance @dreport_i; else → prior day eMoneyClientBalance.ClosingBalanceBO | T2 | Total opening balance in holder currency |
| 5 | OpeningPositiveBalance | decimal(16,6) | CASCADE: same source as OpeningBalance, positive component only | T2 | Max(0, OpeningBalance); excludes negative balances |

### Transaction Flows (Holder Currency)

| # | Column | Type | Source | Tier | Notes |
|---|--------|------|--------|------|-------|
| 6 | BankPayIns | decimal(16,6) | ETL_AccountsActivities: External Payment HolderAmount>0 (excl TC=66) + TC=65 (inbound return) + TC=13/LS=33 (internal return) | T2 | Inbound banking transfers |
| 7 | BankPayOuts | decimal(16,6) | ETL_AccountsActivities: External Payment HolderAmount<0 (excl TC=65) + TC=66 (outbound return) + TC=11/LS=33 | T2 | Outbound banking transfers |
| 8 | Card_POS | decimal(16,6) | ETL_SettlementsTransactions: SUM(HolderAmount) WHERE TransactionCode NOT IN (3,8) | T2 | Point-of-sale card spend |
| 9 | Card_ATM | decimal(16,6) | ETL_SettlementsTransactions: SUM(HolderAmount) WHERE TransactionCode IN (3,8) | T2 | ATM cash withdrawals |
| 10 | EtoroDeposits | decimal(16,6) | ETL_AccountsActivities: TC=1, LoadType=1, LoadSource IN (30,35,25) | T2 | eToro platform wallet loads (external client wallet) |
| 11 | EtoroCashouts | decimal(16,6) | ETL_AccountsActivities: TC=4, LoadType=1, LoadSource IN (30,35,25) | T2 | eToro platform wallet unloads |
| 12 | EtoroC2FDeposits | decimal(16,6) | ETL_AccountsActivities: TC=1, LoadType=1, LoadSource=34 | T2 | Crypto-to-fiat conversion loads |
| 13 | BalanceAdjustments | decimal(16,6) | ETL_AccountsActivities: TC IN (11,13), LoadSource IN (31,32) | T2 | Manual + API balance adjustments (GUI/PM API) |
| 14 | ChargeBackAdjustments | decimal(16,6) | ETL_AccountsActivities: TC=79 (DISPUTE_CREDIT_ADJUSTMENT) | T2 | Chargeback dispute credits |
| 15 | ATMFee | decimal(16,6) | ETL_SettlementsTransactions: SUM WHERE F0FeeName='ATM fee' | T2 | ATM fee charges |
| 16 | FxFee | decimal(16,6) | ETL_SettlementsTransactions: SUM(FxFeeAmount) | T2 | FX conversion fee |
| 17 | OtherFee | decimal(16,6) | ETL_SettlementsTransactions: SUM WHERE F0FeeName<>'ATM fee' | T2 | Non-ATM fees (card fees, etc.) |

### Closing Balance & Reconciliation

| # | Column | Type | Source | Tier | Notes |
|---|--------|------|--------|------|-------|
| 18 | ClosingBalanceCalc | decimal(16,6) | ROUND(OpeningBalance + all 12 transaction components, 2) | T2 | DWH-computed closing balance |
| 19 | ClosingBalanceBO | decimal(16,6) | ETL_AccountSnapshot.SettledBalance WHERE DateID=@d_i (next day file) | T2 | Tribe back-office closing balance |
| 20 | ClosingBalanceGAP | decimal(16,6) | ClosingBalanceCalc - ClosingBalanceBO | T2 | Reconciliation gap (should be near zero) |
| 21 | OpeningBalanceGAP | decimal(16,6) | 0 if first fill; else oc.OpeningBalanceByCB - b.OpeningBalance | T2 | Opening balance gap vs. prior day close |
| 22 | ClosingNegativeBalanceBO | decimal(16,6) | CASE WHEN ClosingBalanceBO < 0 THEN ClosingBalanceBO ELSE 0 END | T2 | Negative balance component of closing BO |
| 23 | NegativeBalanceMovement | decimal(16,6) | OpeningNegativeBalance - ClosingNegativeBalanceBO | T2 | Change in negative balance |
| 24 | ClosingPositiveBalanceBO | decimal(16,6) | CASE WHEN ClosingBalanceBO >= 0 THEN ClosingBalanceBO ELSE 0 END | T2 | Positive balance component of closing BO |
| 25 | ClosingPositiveBalanceCalc | decimal(16,6) | ROUND(OpeningPositiveBalance + all tx components + NegativeBalanceMovement, 2) | T2 | Computed positive closing balance |
| 26 | ClosingPositiveBalanceGAP | decimal(16,6) | ClosingPositiveBalanceCalc - ClosingPositiveBalanceBO | T2 | Positive balance reconciliation gap |
| 27 | CheckCalc | decimal(16,6) | ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO | T2 | Internal consistency check (should be zero) |
| 28 | TransOutOfDate | decimal(16,6) | ISNULL(SettlementsOutOfDate, 0) + ISNULL(AccountsActivitiesOutOfDate, 0) | T2 | Sum of transactions where TransactionDateTime date ≠ BalanceDate (late-arriving) |

### FX / Rate Columns (Added 2026-01-20 via ALTER TABLE)

| # | Column | Type | Source | Tier | Notes |
|---|--------|------|--------|------|-------|
| 45 | CrossExchangeRate | decimal(24,12) | CASE same currency THEN 1 ELSE CrossExchangeRate from #split (Cmrdb_FxRate @dreport) | T2 | Holder→Reporting FX rate on business date; 1 if same currency. Added 2026-01-20 |
| 46 | ExchangeRate | decimal(24,12) | PriceFromReportingCurrencyToHolderCurrencyBusnessDate from Cmrdb_FxRate | T2 | Reporting→Holder rate from Cmrdb (inverse of CrossExchangeRate) |
| 49 | FX | decimal(24,12) | OpeningBalance * PriceFix2 (= CrossExchangeRate2 - CrossExchangeRatePrev2) | T2 | FX gain/loss on opening balance due to rate movement |
| 50 | PositiveFX | decimal(24,12) | OpeningPositiveBalance * PriceFix2 | T2 | FX gain/loss on positive opening balance component |
| 71 | PriceFX | decimal(24,12) | CrossExchangeRate2 - CrossExchangeRatePrev2 (day-over-day FX rate change) | T2 | Rate delta; used to compute FX and FXGAP |
| 72 | FXGAP | decimal(12,6) | CAST(ClosingBalanceBORepCur - OpeningBalanceRepCur - Delta - FX AS DECIMAL(16,6)) | T2 | FX reconciliation gap in reporting currency |

### Reporting Currency (RepCur) Extensions (Added 2026-01-20 via ALTER TABLE)

All RepCur columns = `{source_column} * CrossExchangeRate2` (= 1/ExchangeRate). CASE: if same currency, CrossExchangeRate2=1.

| # | Column | Type | Source Column | Tier |
|---|--------|------|---------------|------|
| 44* | ClosingBalanceBORepCur | decimal(24,12)¹ | ClosingBalanceBO * CrossExchangeRate2 | T2 |
| 47 | OpeningBalanceRepCur | decimal(24,12) | OpeningBalance * CrossExchangeRatePrev2 | T2 |
| 48 | OpeningPositiveBalanceRepCur | decimal(24,12) | OpeningPositiveBalance * CrossExchangeRatePrev2 | T2 |
| 51 | BankPayInsRepCur | decimal(24,12) | BankPayIns * CrossExchangeRate2 | T2 |
| 52 | BankPayOutsRepCur | decimal(24,12) | BankPayOuts * CrossExchangeRate2 | T2 |
| 53 | Card_POSRepCur | decimal(24,12) | Card_POS * CrossExchangeRate2 | T2 |
| 54 | Card_ATMRepCur | decimal(24,12) | Card_ATM * CrossExchangeRate2 | T2 |
| 55 | EtoroDepositsRepCur | decimal(24,12) | EtoroDeposits * CrossExchangeRate2 | T2 |
| 56 | EtoroCashoutsRepCur | decimal(24,12) | EtoroCashouts * CrossExchangeRate2 | T2 |
| 57 | EtoroC2FDepositsRepCur | decimal(24,12) | EtoroC2FDeposits * CrossExchangeRate2 | T2 |
| 58 | BalanceAdjustmentsRepCur | decimal(24,12) | BalanceAdjustments * CrossExchangeRate2 | T2 |
| 59 | ChargeBackAdjustmentsRepCur | decimal(24,12) | ChargeBackAdjustments * CrossExchangeRate2 | T2 |
| 60 | ATMFeeRepCur | decimal(24,12) | ATMFee * CrossExchangeRate2 | T2 |
| 61 | FxFeeRepCur | decimal(24,12) | FxFee * CrossExchangeRate2 | T2 |
| 62 | OtherFeeRepCur | decimal(24,12) | OtherFee * CrossExchangeRate2 | T2 |
| 63 | ClosingBalanceCalcRepCur | decimal(24,12) | ClosingBalanceCalc * CrossExchangeRate2 | T2 |
| 64 | ClosingBalanceGAPRepCur | decimal(24,12) | ClosingBalanceGAP * CrossExchangeRate2 | T2 |
| 65 | ClosingNegativeBalanceBORepCur | decimal(24,12) | ClosingNegativeBalanceBO * CrossExchangeRate2 | T2 |
| 66 | NegativeBalanceMovementRepCur | decimal(24,12) | NegativeBalanceMovement * CrossExchangeRate2 | T2 |
| 67 | ClosingPositiveBalanceBORepCur | decimal(24,12) | ClosingPositiveBalanceBO * CrossExchangeRate2 | T2 |
| 68 | ClosingPositiveBalanceCalcRepCur | decimal(24,12) | ClosingPositiveBalanceCalc * CrossExchangeRate2 | T2 |
| 69 | ClosingPositiveBalanceGAPRepCur | decimal(24,12) | ClosingPositiveBalanceGAP * CrossExchangeRate2 | T2 |

*¹ ClosingBalanceBORepCur appears in SSDT at position 44 as decimal(16,6); live table has it as decimal(24,12) after ALTER TABLE DROP + re-ADD.*

---

## Tier Summary

| Tier | Count | % | Notes |
|------|-------|---|-------|
| T1 | 0 | 0% | No upstream FiatDwhDB wiki source (Synapse-native computation) |
| T2 | 72 | 100% | All columns traced to SP_eMoney_ClientBalance code |
| T3 | 0 | — | — |
| T4 | 0 | — | Prior T4 flag (IsExistingUser) resolved: confirmed T2 from SP line 706 |

*Object summary: 72-col daily account-level balance table; 1.19B rows (2023-12-29 to 2026-04-12); HASH(AccountId) + CLUSTERED COLUMNSTORE; 3 Tribe ETL staging sources + 4 DWH lookup sources; SSDT stale (45 cols), live = 72.*
