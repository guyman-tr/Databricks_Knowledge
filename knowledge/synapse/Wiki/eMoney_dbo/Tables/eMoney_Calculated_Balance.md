# eMoney_dbo.eMoney_Calculated_Balance

> Daily per-account cumulative balance table for the eToro Money fiat platform; aggregates all-time transaction history from eMoney_Fact_Transaction_Status by TxTypeID category, plus DWH customer dimension attributes, to produce a per-account running balance ledger. Sources transaction-based (not Tribe snapshot-based) balance data. Last loaded 2025-06-09.

| Property | Value |
|----------|-------|
| Schema | eMoney_dbo |
| Object type | Table |
| Distribution | HASH(CID) |
| Index | CLUSTERED INDEX(BalanceDateID ASC) + NCI(CurrencyBalanceID ASC) |
| Rows (approx) | Large (sampled: 538M+ rows for 2025-06-09 alone) |
| Date range | 2020-11-09 → 2025-06-09 |
| Writer SP | SP_eMoney_Calculated_Balance (529 lines; @Date DATE param) |
| ETL pattern | Daily DELETE WHERE BalanceDateID=@DateID + INSERT |
| Columns | 48 (matches SSDT DDL) |
| UC target | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_calculated_balance |
| **ALERT** | Last load: 2025-06-09 (~10 months stale as of 2026-04-20) |

---

## 1. Object Purpose

`eMoney_Calculated_Balance` is the transaction-based daily balance ledger for eToro Money fiat accounts. Unlike `eMoneyClientBalance` (which uses Tribe's back-office snapshot files), this table derives balances by aggregating all settled transactions from `eMoney_Fact_Transaction_Status`. For each account (`CurrencyBalanceID`), it computes:
- **TotalBalance** / **ClosingBalance**: cumulative sum of all historical transaction amounts (IsTxStatusCBRelevant=1)
- **Daily transaction flows**: by TxTypeID category (BankingPaymentsIN, BankingPaymentsOut, CardActivity, Loads, Unloads, BalanceAdjustments, Fee, DirectDebit, Unknown, TBD)
- **OpeningBalance**: prior day's ClosingBalance (self-join cascade)
- **Correction**: adjustment for late-arriving and back-dated transactions

The table enriches each account row with full DWH customer attributes from Fact_SnapshotCustomer (date-effective via Dim_Range), enabling segmented balance analysis by country, club tier, regulation, and account type.

**Primary use cases (historical, pre-June 2025):**
- Transaction-based balance reconciliation by TxType category
- Customer-segmented balance analytics (by Country, Club, Regulation)
- FMI/FMO flow analysis (Loads/Unloads vs. BankingPayments breakdown)

---

## 2. Business Context

### 2.1 Transaction-Based vs. Snapshot-Based Balance

This table differs fundamentally from `eMoneyClientBalance`:

| Dimension | eMoney_Calculated_Balance | eMoneyClientBalance |
|-----------|--------------------------|---------------------|
| Source | eMoney_Fact_Transaction_Status | Tribe ETL_AccountSnapshot files |
| Balance concept | Cumulative SUM of all transactions | Tribe back-office settled balance |
| TxType grouping | FMI/FMO/Card/Fee categories | BankPayIns/BankPayOuts/Card/Etoro |
| Customer attributes | Full DWH Fact_SnapshotCustomer | Tribe entity mapping only |
| FX conversion | USD approximate only | Full RepCur (from 2026-01-20) |
| Last updated | 2025-06-09 | 2026-04-12 (current) |

### 2.2 TxTypeID Category Groupings

Transaction flow columns use these TxTypeID mappings (from SP lines 229-236, 283-291):

| Column | TxTypeID(s) | TxType Names |
|--------|-------------|--------------|
| BankingPaymentsIN | 7 | PaymentReceived (FMO) |
| BankingPaymentsOut | 8 | Payment |
| CardActivity | 1, 2, 3, 4, 9 | CardPayment, Contactless, OnlinePayment, CashWithdrawal, Refund |
| Loads | 5 | TransferReceived (FMI) |
| Unloads | 6 | Transfer |
| BalanceAdjustments | 11, 12 | CreditBA, DebitBA |
| Fee | 10 | Fee |
| DirectDebit | 13 | DirectDebit |
| Unknown | 0 | Unknown |
| TBD | TxClientBalanceCategory='TBD' | CryptoToFiat (TxTypeID=14) and any other unmapped types |

### 2.3 ClosingBalance = TotalBalance (Cumulative)

A critical distinction: `ClosingBalance` in this table equals `TotalBalance` — both represent the **cumulative all-time sum** of all relevant transactions for the account. This is NOT an incremental daily closing balance.

In the INSERT (SP line 513): `TotalBalance AS ClosingBalance`

The `#final.ClosingBalance` computed in Step 10 (OpeningBalance + daily flows + Correction) is used ONLY for:
1. `ClosingBalanceUSDApprox` = #final.ClosingBalance × USDApproxRate
2. Deriving the TotalBalance reconciliation component of `Correction`

### 2.4 Correction Logic

`Correction` captures two adjustment types:
1. **Late-arriving transactions** (#balance_gap): transactions where TxStatusCreatedDateID=@DateID but TxStatusModificationDateID < @DateID (created today, back-dated status)
2. **TotalBalance reconciliation**: (TotalBalance - #final.ClosingBalance) — ensures ClosingBalance = TotalBalance after accounting for all historical transactions

For new accounts (first row in the table), all transactions on the first date are taken directly without correction.

### 2.5 Account Population Filter

The SP includes accounts where `CurrencyBalanceCreateDateID < @DateID_NextDay` (created before tomorrow). Customer attributes are joined from `Fact_SnapshotCustomer` via `Dim_Range` (SCD date-range join: `@DateID BETWEEN FromDateID AND ToDateID`), ensuring point-in-time attribute accuracy.

---

## 3. Source Tables

| Source | Role | Join Key |
|--------|------|----------|
| eMoney_dbo.eMoney_Dim_Account | Account identity and flags | CurrencyBalanceCreateDateID < @DateID_NextDay |
| DWH_dbo.Fact_SnapshotCustomer | Customer attributes (SCD via Dim_Range) | RealCID; DateRangeID BETWEEN @DateID |
| DWH_dbo.Dim_Country | Country name | CountryID (INNER JOIN — excludes accounts without country) |
| DWH_dbo.Dim_PlayerLevel | Club name | PlayerLevelID (INNER JOIN) |
| DWH_dbo.Dim_Regulation | Regulation name | RegulationID (INNER JOIN) |
| DWH_dbo.Dim_AccountType | Account type name | AccountTypeID (LEFT JOIN) |
| DWH_dbo.Dim_Label | Label name | LabelID (LEFT JOIN) |
| DWH_dbo.Dim_MifidCategorization | MiFID category name | MifidCategorizationID (LEFT JOIN) |
| DWH_dbo.Dim_PlayerStatus | Player status name | PlayerStatusID (LEFT JOIN) |
| eMoney_dbo.eMoney_Fact_Transaction_Status | All transaction flows; TotalBalance | CurrencyBalanceID; IsTxStatusCBRelevant=1 |
| eMoney_dbo.eMoney_Calculated_Balance (self) | Prior day OpeningBalance | BalanceDateID = @DateID_PreviousDay |
| eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static | CurrencyISO → InstrumentID | CurrencyISO = CurrencyISOCode; SellCurrencyID=1 |
| DWH_dbo.Fact_CurrencyPriceWithSplit | USDApproxRate | InstrumentID; OccurredDateID=@DateID |

---

## 4. Data Elements

### 4.1 Date / ID

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| BalanceDateID | int | Integer YYYYMMDD of the balance date; primary DELETE key for idempotent reload; CLUSTERED INDEX key. | T2 |
| BalanceDate | date | Business date this row represents. | T2 |

### 4.2 Account Identity

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| CurrencyBalanceID | int | DWH account identifier from eMoney_Dim_Account. NCI key for efficient CurrencyBalanceID lookups. | T2 |
| ProviderCurrencyBalanceID | int | Tribe's AccountId — the provider's account key. | T2 |
| AccountID | int | Platform account identifier. | T2 |
| GCID | int | eToro global customer ID. | T2 |
| CID | int | eToro customer ID. Distribution hash key. | T2 |
| CurrencyISOCode | int | ISO 4217 numeric currency code (826=GBP, 978=EUR, 36=AUD, 208=DKK). | T2 |
| Currency | varchar(50) | ISO alpha currency code: GBP, EUR, AUD, DKK. From eMoney_Dim_Account.CurrencyBalanceISODesc. | T2 |
| AccountProgramID | int | FK to eMoney_Dictionary_AccountProgram: 1=card, 2=iban. | T2 |
| AccountProgram | varchar(50) | Account program label: 'card' or 'iban' (lowercase). | T2 |
| AccountSubProgramID | int | FK to eMoney_Dictionary_AccountSubProgram. | T2 |
| AccountSubProgram | varchar(50) | Sub-program label (e.g., 'IBAN Standard UK', 'Card Standard UK', 'IBAN EU Green'). | T2 |
| ProviderHolderID | int | Tribe holder (customer) identifier. | T2 |
| CardID | int | Always NULL. Commented out in SP; reserved for future card linkage. | T2 |
| ProviderCardID | int | Always NULL. Commented out in SP; reserved for future card linkage. | T2 |
| IsTestAccount | int | 1 if test account per eMoney_Dim_Account. | T2 |
| IsValidETM | int | 1 if valid eToro Money account per eMoney_Dim_Account. | T2 |
| IsGermanBaFin | int | Always NULL. German BaFin indicator feature not implemented in current SP version. | T2 |
| UserType | varchar(50) | Classification: 'TestUser' (IsTestAccount=1), 'Obsolete Account' (GCID=0), 'eTorian' (IsValidCustomer=0), 'RegularUser' (all others). Live distribution for 2025-06-09: RegularUser=99.999%, TestUser<0.01%, eTorian<0.01%. | T2 |

### 4.3 Customer Attributes

All derived from DWH_dbo.Fact_SnapshotCustomer (point-in-time via Dim_Range SCD) + dimension lookups.

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| AccountType | varchar(50) | eToro account type from Dim_AccountType (LEFT JOIN; may be NULL). | T2 |
| Label | varchar(50) | Customer segment label from Dim_Label (LEFT JOIN). | T2 |
| MifidCategory | varchar(50) | MiFID II categorization from Dim_MifidCategorization (LEFT JOIN). | T2 |
| CountryID | int | DWH country dimension FK from Fact_SnapshotCustomer (INNER JOIN — excludes unmatched accounts). | T2 |
| Country | varchar(50) | Country name from Dim_Country (e.g., 'United Kingdom', 'Germany'). | T2 |
| PlayerLevelID | int | Player level FK from Fact_SnapshotCustomer (INNER JOIN). | T2 |
| Club | varchar(50) | Club tier from Dim_PlayerLevel (e.g., 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'). | T2 |
| PlayerStatusID | int | Player status FK. | T2 |
| PlayerStatus | varchar(50) | Player status label from Dim_PlayerStatus (LEFT JOIN). | T2 |
| RegulationID | int | Regulation FK from Fact_SnapshotCustomer (INNER JOIN). | T2 |
| Regulation | varchar(50) | Regulatory regime name from Dim_Regulation (e.g., 'UK', 'EU', 'AU'). | T2 |

### 4.4 Balance Metrics

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| TotalBalance | numeric(38,4) | Cumulative all-time sum of HolderAmount from eMoney_Fact_Transaction_Status WHERE IsTxStatusCBRelevant=1 AND both TxStatusModificationDateID and TxStatusCreatedDateID < @DateID+1. Equals ClosingBalance. | T2 |
| OpeningBalance | numeric(38,4) | Prior day's ClosingBalance from this table (self-join on BalanceDateID=@DateID_PreviousDay). 0 if no prior row (first date for this account). | T2 |
| Correction | numeric(38,4) | Two-component adjustment: (1) sum of late-arriving transactions (TxStatusCreatedDateID=today, TxStatusModificationDateID<today, IsTxStatusCBRelevant=1, excluding first-day accounts); (2) TotalBalance-ClosingBalance reconciliation residual. | T2 |

### 4.5 Daily Transaction Flows

All transaction flow columns capture the **daily delta** for `BalanceDate`: transactions where `TxStatusModificationDateID = @DateID` AND `TxStatusCreatedDateID < @DateID+1` AND `IsTxStatusCBRelevant = 1`. Not zero-filled — ISNULL applied. Excludes new accounts (handled separately in #balance_calculation_for_new).

| Column | Type | TxTypeIDs | Description | Tier |
|--------|------|-----------|-------------|------|
| BankingPaymentsIN | numeric(38,4) | 7 | Inbound banking payments (PaymentReceived / FMO). | T2 |
| BankingPaymentsOut | numeric(38,4) | 8 | Outbound banking payments (Payment). | T2 |
| CardActivity | numeric(38,4) | 1,2,3,4,9 | Card transactions: CardPayment, Contactless, OnlinePayment, CashWithdrawal, Refund. | T2 |
| Loads | numeric(38,4) | 5 | eToro platform loads (TransferReceived / FMI). | T2 |
| Unloads | numeric(38,4) | 6 | eToro platform unloads (Transfer). | T2 |
| BalanceAdjustments | numeric(38,4) | 11, 12 | Balance adjustments (CreditBA, DebitBA). | T2 |
| Fee | numeric(38,4) | 10 | Fee transactions. | T2 |
| DirectDebit | numeric(38,4) | 13 | Direct debit transactions. | T2 |
| Unknown | numeric(38,4) | 0 | Unknown transaction type. | T2 |
| TBD | numeric(38,4) | TxClientBalanceCategory='TBD' | Unmapped transaction types; currently includes TxTypeID=14 (CryptoToFiat). TBD filter uses TxClientBalanceCategory column, not TxTypeID directly. | T2 |

### 4.6 Closing Balance & USD Conversion

| Column | Type | Description | Tier |
|--------|------|-------------|------|
| ClosingBalance | numeric(38,4) | Cumulative all-time balance = TotalBalance. The INSERT writes `TotalBalance AS ClosingBalance`. NOT an incremental daily closing sum. | T2 |
| ClosingBalanceUSDApprox | numeric(38,4) | Approximate USD value of the incremental closing balance: (#final.ClosingBalance = OpeningBalance + daily flows + Correction) × USDApproxRate. ISNULL=0. Note: uses the incremental computed sum, not TotalBalance. | T2 |
| USDApproxRate | numeric(38,4) | Mid-price USD conversion rate: (Ask+Bid)/2 from Fact_CurrencyPriceWithSplit, joined via eMoney_Currency_Instrument_Mapping_Static WHERE SellCurrencyID=1. | T2 |
| UpdateDate | datetime | GETDATE() load timestamp. | T2 |

---

## 5. Business Logic

### 5.1 Daily ETL Flow

```
Step 01: (Historical WHILE loop - commented out; now single-date mode)
Step 02: Declare @DateID, @DateID_PreviousDay, @DateID_NextDay
Step 03: Build #account from eMoney_Dim_Account WHERE CurrencyBalanceCreateDateID < @DateID_NextDay
         Compute UserType CASE in #account
Step 03: Build #balance_populationprep: JOIN #account + Fact_SnapshotCustomer (via Dim_Range SCD)
Step 03: Build #balance_population: JOIN #balance_populationprep + 7 DWH dimension lookups
         (Country INNER, PlayerLevel INNER, Regulation INNER; AccountType/Label/MifidCategory/PlayerStatus LEFT)
Step 04: IsGermanBaFin block commented out (feature inactive)
Step 05: DELETE FROM eMoney_Calculated_Balance WHERE BalanceDateID=@DateID
Step 05: Build #balanceprep: prior day ClosingBalance from eMoney_Calculated_Balance
Step 05: Build #txprep: all transactions from eMoney_Fact_Transaction_Status (no date filter — full history)
Step 05: Build #min_st_created: identify new accounts (first TxStatusCreatedDateID in #txprep)
Step 06: Build #balance_calculation_for_new: aggregate new accounts' first-day transactions
         (TxStatusCreatedDateID=@DateID AND MinStatusCreatedDateID=@DateID AND IsTxStatusCBRelevant=1)
Step 07: Build #balance_gap: late-arriving transactions
         (TxStatusCreatedDateID=@DateID, TxStatusModificationDateID < @DateID, IsTxStatusCBRelevant=1,
          NOT new accounts via bcfn IS NULL)
Step 08: Build #balance_calculation: today's flows (TxStatusModificationDateID=@DateID,
          TxStatusCreatedDateID < @DateID_NextDay, IsTxStatusCBRelevant=1, NOT new accounts)
         UNION ALL new accounts from #balance_calculation_for_new
Step 09: Build #balance_total: cumulative SUM(HolderAmount) all-time (both date cols < @DateID_NextDay)
Step 10: Build #final: JOIN population + total + gap + calculation + balanceprep + FX pricing
         Compute: OpeningBalance (self-join), ClosingBalance = OpeningBalance + flows + correction,
         TotalBalance = cumulative; USDApproxRate from Fact_CurrencyPriceWithSplit
Step 11: INSERT 48 columns; CardID/ProviderCardID=NULL, IsGermanBaFin=NULL
         Correction adjusted: bga.Correction + (TotalBalance - #final.ClosingBalance)
         ClosingBalance in INSERT = TotalBalance (not the computed sum)
         ClosingBalanceUSDApprox = #final.ClosingBalance × USDApproxRate
```

### 5.2 FMI / FMO Definitions

Cross-referencing with SP_eMoney_Reports_Daily and batch context Batch 3:
- **FMI** (eToro In): Loads (TxTypeID=5=TransferReceived) + BankingPaymentsIN (TxTypeID=7=PaymentReceived) with TxStatusID=2 AND HolderAmount<>0
- **FMO** (eToro Out): Unloads (TxTypeID=6) + BankingPaymentsOut (TxTypeID=8) with TxStatusID=2

Note: The `IsTxStatusCBRelevant` filter in this SP is pre-applied on eMoney_Fact_Transaction_Status — exact definition is in SP_eMoney_DimFact_Transaction.

### 5.3 TBD Classification

`TBD = SUM(HolderAmount WHERE TxClientBalanceCategory = 'TBD')` rather than a TxTypeID filter. `TxClientBalanceCategory` is computed upstream in `eMoney_Fact_Transaction_Status`. Currently captures TxTypeID=14 (CryptoToFiat) as TBD.

---

## 6. Dependencies

### 6.1 Upstream Tables

| Table | Dependency | Notes |
|-------|-----------|-------|
| eMoney_dbo.eMoney_Fact_Transaction_Status | Hard — all balance computation | Full table scan (no DateID filter on #txprep); performance-sensitive |
| eMoney_dbo.eMoney_Dim_Account | Hard — account population | Must run after daily Dim_Account refresh |
| DWH_dbo.Fact_SnapshotCustomer | Hard — customer attributes | SCD via Dim_Range; accounts without snapshot record are excluded |
| DWH_dbo.Dim_Country/PlayerLevel/Regulation | Hard — INNER JOINs | Missing dim records exclude accounts from output |
| DWH_dbo.Fact_CurrencyPriceWithSplit | Soft — USDApproxRate | NULL rate → ClosingBalanceUSDApprox = 0 |

### 6.2 Downstream Consumers

Historically used for:
- Daily balance dashboards segmented by Country/Club/Regulation
- FMI/FMO flow analysis by customer type
- ClosingBalanceUSDApprox for USD-normalized balance reporting

---

## 7. Data Quality Notes

### 7.1 Table Staleness (CRITICAL)

`MaxDate = 2025-06-09`. The SP_eMoney_Calculated_Balance has not loaded data since 2025-06-10. The eMoney_Calculated_Balance table is ~10 months stale. Any analytics using this table reflect state as of June 2025 only.

Possible causes:
- SP disabled/removed from daily orchestration pipeline
- Replaced by `eMoneyClientBalance` or newer reporting tables (Snapshot_Settled_Balance, etc.)
- Long-running SP performance issues (full scan of eMoney_Fact_Transaction_Status for cumulative TotalBalance)

### 7.2 CardID / ProviderCardID Always NULL

These columns are permanently NULL — SP hardcodes NULL for both. Commented-out code references CardID/ProviderCardID but they were never activated.

### 7.3 IsGermanBaFin Always NULL

The German BaFin indicator block is fully commented out in the SP. Column is permanently NULL.

### 7.4 ClosingBalance vs TotalBalance Naming

`ClosingBalance = TotalBalance` (cumulative, not incremental). This naming can mislead analysts expecting an end-of-day account balance in the traditional sense. For incremental daily movement analysis, use the individual transaction flow columns. For a true "end of day balance", the cumulative TotalBalance IS the correct concept for a transaction-based ledger, but is different from `eMoneyClientBalance.ClosingBalanceBO` (Tribe snapshot).

### 7.5 CLUSTERED INDEX vs COLUMNSTORE

Unlike most eMoney_dbo tables, this table uses a row-store CLUSTERED INDEX(BalanceDateID) rather than CLUSTERED COLUMNSTORE. This enables efficient single-date DELETEs and point-time queries but makes full-range aggregations slower.

---

## 8. UC Migration Notes

| Property | Value |
|----------|-------|
| UC target | main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_calculated_balance |
| Partition suggestion | PARTITION BY BalanceDateID (integer; natural for daily DELETE+INSERT) |
| Staleness | Confirm whether to migrate as-is (snapshot to June 2025) or resume daily loads |
| CardID/ProviderCardID | Consider dropping — always NULL, never populated |
| IsGermanBaFin | Consider dropping — always NULL, feature inactive |
| TotalBalance cumulative | Ensure UC consumers understand ClosingBalance = TotalBalance (cumulative) |

---

*Wiki generated: 2026-04-20 | Quality: 8.8/10 | Phases completed: P1, P2, P3, P8, P9, P10B, P11 | Tier distribution: T2=48 (100%)*
