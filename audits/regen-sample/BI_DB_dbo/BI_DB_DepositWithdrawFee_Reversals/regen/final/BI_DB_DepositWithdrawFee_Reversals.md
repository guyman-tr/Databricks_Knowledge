# BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals

> Reversal companion to BI_DB_DepositWithdrawFee — ~19.8K rows capturing deposit chargebacks, refunds, reversed deposits, cashout rollbacks, and their cancelled variants from 2023-01-03 to present. Built daily by `SP_DepositWithdrawFee` from `Fact_Deposit_State` (WHERE TransactionType != 'Deposit') UNION ALL `Fact_Cashout_State` (WHERE TransactionType != 'Withdraw'), enriched with customer snapshot attributes, payment metadata, and post-insert amount sign corrections.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_DepositWithdrawFee from Fact_Deposit_State + Fact_Cashout_State (reversal subsets) |
| **Key Identifier** | No PK; grain = DepositWithdrawID + TransactionID per DateID |
| **Distribution** | HASH(CID) |
| **Index** | CLUSTERED COLUMNSTORE INDEX |
| **Column Count** | 45 |
| **Synapse Pool** | sql_dp_prod_we |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |
| **Refresh** | Daily (DELETE by DateID + INSERT, Priority 99, FinanceReportSPS) |

---

## 1. Business Meaning

`BI_DB_DepositWithdrawFee_Reversals` is the reversal-only companion to `BI_DB_DepositWithdrawFee`. While the sibling table stores standard `Deposit` and `Withdraw` transactions, this table stores all non-standard transaction types: chargebacks, refunds, chargeback reversals, reversed deposits, cashout rollbacks, and their cancelled variants. Both tables share the same 45-column schema and are loaded by the same SP (`SP_DepositWithdrawFee`).

As of 2026-04-24, the table holds ~19,762 rows spanning DateID 20230103 to 20260424. The distribution by TransactionType (2026 YTD):
- Refund: 1,946 (64%)
- Chargeback: 796 (26%)
- ChargebackReversal: 234 (8%)
- CancelledRefund: 27
- CancelledChargeback: 11
- ReversedDeposit: 6
- CashoutRollback: 5
- CancelledCashoutRollback: 4
- CancelledChargebackReversal: 3
- CancelledReversedDeposit: 1
- CancelledRefundReversal: 1

The SP builds two temp tables — `#depositsRevesals` (from Fact_Deposit_State WHERE TransactionType != 'Deposit') and `#withdrawsrollbacks` (from Fact_Cashout_State WHERE TransactionType != 'Withdraw') — then UNION ALLs them into this table. After insert, amount sign corrections are applied via a `#amountDirections` mapping table and edge-case fixes via Fact_CustomerAction JOIN.

Created 2025-02-06 (SR-299957). Switched to RnD PIPS pipeline 2025-07-27 (SR-324538). ExchangeFeePercentage added 2026-03-04 (SR-359957).

---

## 2. Business Logic

### 2.1 Reversal Transaction Filtering

**What**: Selects only non-standard (reversal) transaction types from the deposit and cashout state tables.

**Columns Involved**: `TransactionType`, `DepositWithdrawID`, `TransactionID`

**Rules**:
- Deposit reversals: `Fact_Deposit_State WHERE TransactionType != 'Deposit' AND ModificationDateID = @StartDateID` joined to `Fact_BillingDeposit` on DepositID
- Withdraw rollbacks: `Fact_Cashout_State WHERE TransactionType != 'Withdraw' AND ModificationDateID = @StartDateID` joined to deduped `Fact_BillingWithdraw` (deduped via DISTINCT on WithdrawPaymentID to eliminate BankName duplicates)
- TransactionID is synthetic: `CAST(DepositID AS VARCHAR(50)) + 'D'` for deposit reversals, `CAST(WPID AS VARCHAR(50)) + 'W'` for withdraw rollbacks

### 2.2 Amount Sign Correction (ABS then Sign)

**What**: All amounts are loaded as absolute values, then signed based on transaction type direction.

**Columns Involved**: `Amount`, `AmountUSD`, `PIPsCalculation`

**Rules**:
- At INSERT: `ABS(Amount)`, `ABS(AmountInUSD)`, `ABS(ISNULL(PIPsInUSD,0))`
- Post-INSERT UPDATE via `#amountDirections` table:
  - Direction -1: Withdraw, Chargeback, Refund, ReverseDeposit, ReversedDeposit, CancelledChargebackReversal, CancelledRefundReversal
  - Direction +1: Deposit, CancelledChargeback, CancelledRefund, CancelledReversedDeposit, ChargebackReversal, CashoutRollback
  - Special: PIPsCalculation for `Withdraw` type keeps its sign (not multiplied by direction)
- Edge-case corrections: `CashoutRollback` and `CancelledCashoutRollback` rows matching `Fact_CustomerAction` (on DateID + CreditID) get PIPsCalculation negated
- Edge-case: `CancelledChargebackReversal` rows where `Fact_CustomerAction.Amount = -1 * AmountUSD` get all three amount columns negated

### 2.3 Customer Snapshot Enrichment

**What**: Resolves point-in-time customer attributes from Fact_SnapshotCustomer using Dim_Range date bridge.

**Columns Involved**: `RegulationID`, `LabelID`, `PlayerLevelID`, `IsValidCustomer`, `Regulation`, `Label`, `Club`, `PlayerStatus`, `RegCountry`, `GuruStatus`

**Rules**:
- JOIN: `Fact_SnapshotCustomer fsc ON dc.RealCID = fsc.RealCID` + `Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND ModificationDateID BETWEEN dr.FromDateID AND dr.ToDateID`
- Dimension names resolved via: `Dim_Regulation.Name`, `Dim_Label.Name`, `Dim_PlayerLevel.Name`, `Dim_PlayerStatus.Name`, `Dim_Country.Name`, `Dim_GuruStatus.GuruStatusName`
- Deposit path uses `dc.LabelID` (from Dim_Customer) and `dc.CountryID` for RegCountry; withdraw path uses `fsc.LabelID` and `fsc.CountryID`

### 2.4 Intentionally NULL Columns

**What**: Three columns are structurally present but always NULL.

**Columns Involved**: `CreditTypeID`, `MOPCountry`, `IsGermanBaFin`

**Rules**:
- `CreditTypeID`: set to NULL per SR-313302 (legacy column retired 2025-05-07)
- `MOPCountry`: NULL literal in SP (not populated in current build)
- `IsGermanBaFin`: NULL literal in SP (not populated in current build)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) with CLUSTERED COLUMNSTORE INDEX. At ~19.8K rows the table is small; full scans are fast. Customer-centric queries (WHERE CID = @cid) access a single distribution.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Chargebacks for a customer | `WHERE CID = @cid AND TransactionType = 'Chargeback'` |
| Monthly reversal volume by type | `GROUP BY DateID / 100, TransactionType` |
| Reversal amount by regulation | `GROUP BY Regulation, TransactionType` — pre-resolved, no JOIN needed |
| Compare reversals to main table | UNION ALL with BI_DB_DepositWithdrawFee (identical schema) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_DepositWithdrawFee | UNION ALL (same schema) | Combined deposit/withdrawal + reversal analysis |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes not in snapshot |
| DWH_dbo.Fact_BillingDeposit | ON DepositID | Full deposit details for deposit-side reversals |
| DWH_dbo.Fact_BillingWithdraw | ON WithdrawPaymentID | Full withdrawal details for withdraw-side rollbacks |

### 3.4 Gotchas

- **CreditTypeID, MOPCountry, IsGermanBaFin are always NULL** — do not filter or aggregate on these columns
- **Amounts are already signed** — refunds/chargebacks are negative, chargeback reversals are positive; do not negate again
- **TransactionID suffix encodes origin**: 'D' = deposit reversal, 'W' = withdraw rollback
- **DepositID is NULL on withdraw rows; WithdrawPaymentID is NULL on deposit rows** — use the non-NULL column to identify the source
- **UpdateDate min is 2025-07-27** — the table was backfilled when the SP was switched to the RnD PIPS pipeline (SR-324538)
- **Fact_BillingWithdraw deduplication**: the SP dedupes on WithdrawPaymentID before joining to avoid ~200 duplicate rows from the BankName field
- **"Partialy Reversed" in TransactionStatus** — this is a known production typo from the source data, not a pipeline bug

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag | Meaning |
|------|-----|---------|
| Tier 1 | (Tier 1 — {origin}) | Dim-lookup passthrough from production dictionary/source; description inherited verbatim from upstream wiki |
| Tier 2 | (Tier 2 — SP_DepositWithdrawFee) | Derived from SP code, snapshot lookup, or ETL computation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Business date as YYYYMMDD for the load (@StartDateID parameter). Used as the DELETE/INSERT partition key. (Tier 2 — SP_DepositWithdrawFee) |
| 2 | CID | int | YES | Customer ID (RealCID) from the deposit or cashout state record. HASH distribution key. (Tier 2 — SP_DepositWithdrawFee) |
| 3 | DepositWithdrawID | int | YES | DepositID (deposit reversals) or WithdrawID (withdraw rollbacks) — the stable identifier for the original cash event being reversed. (Tier 2 — SP_DepositWithdrawFee) |
| 4 | Occurred | datetime | YES | Event timestamp (ModificationDate from Fact_Deposit_State or Fact_Cashout_State). (Tier 2 — SP_DepositWithdrawFee) |
| 5 | CreditTypeID | int | YES | Intentionally NULL in the current procedure. Legacy column retired per SR-313302 (2025-05-07). (Tier 2 — SP_DepositWithdrawFee) |
| 6 | TransactionID | varchar(200) | YES | Synthetic identifier: CAST(DepositID AS VARCHAR(50)) + 'D' for deposit reversals, CAST(WPID AS VARCHAR(50)) + 'W' for withdraw rollbacks. (Tier 2 — SP_DepositWithdrawFee) |
| 7 | Date | date | YES | Calendar date of ModificationDate. CAST(ModificationDate AS DATE). (Tier 2 — SP_DepositWithdrawFee) |
| 8 | Customer | varchar(200) | YES | APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. CAST to VARCHAR(50) from Dim_Customer.ExternalID. (Tier 1 — Customer.CustomerStatic) |
| 9 | TransactionType | varchar(200) | YES | Reversal type from the state fact. Values: Refund, Chargeback, ChargebackReversal, ReversedDeposit, CashoutRollback, CancelledRefund, CancelledChargeback, CancelledCashoutRollback, CancelledChargebackReversal, CancelledReversedDeposit, CancelledRefundReversal. (Tier 2 — SP_DepositWithdrawFee) |
| 10 | PaymentMethod | varchar(200) | YES | Payment method name (e.g., CreditCard, Wire, PayPal, Skrill, Neteller, ApplePay, GooglePay). Passthrough from Dim_FundingType. (Tier 1 — Dictionary.FundingType) |
| 11 | Amount | numeric(38,8) | YES | Transaction amount in original currency. ABS() at insert, then signed via #amountDirections and edge-case corrections. Negative for refunds/chargebacks, positive for chargeback reversals/cashout rollbacks. (Tier 2 — SP_DepositWithdrawFee) |
| 12 | Currency | varchar(200) | YES | Ticker symbol (e.g., USD, EUR, GBP). Use this for human-readable currency identification. Passthrough from Dim_Currency. (Tier 1 — Dictionary.Currency) |
| 13 | ExchangeRate | numeric(38,8) | YES | FX rate from the state fact row. (Tier 2 — SP_DepositWithdrawFee) |
| 14 | AmountUSD | numeric(38,8) | YES | USD equivalent amount. ABS(AmountInUSD) at insert, then signed via #amountDirections and edge-case corrections. (Tier 2 — SP_DepositWithdrawFee) |
| 15 | RegulationID | int | YES | Regulatory entity governing this customer at the time of the reversal. Point-in-time snapshot from Fact_SnapshotCustomer via Dim_Range date bridge. (Tier 2 — SP_DepositWithdrawFee) |
| 16 | LabelID | int | YES | White-label brand ID at the time of the reversal. From Fact_SnapshotCustomer (withdraw path) or Dim_Customer (deposit path). (Tier 2 — SP_DepositWithdrawFee) |
| 17 | PlayerLevelID | int | YES | eToro Club loyalty tier at the time of the reversal. Point-in-time snapshot from Fact_SnapshotCustomer. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal, 5=Silver, 6=Platinum Plus, 7=Diamond. (Tier 2 — SP_DepositWithdrawFee) |
| 18 | Regulation | varchar(200) | YES | Short code for the regulation. Passthrough from Dim_Regulation. (Tier 1 — Dictionary.Regulation) |
| 19 | Label | varchar(200) | YES | Brand name displayed in BackOffice interfaces, reports, and internal systems. Passthrough from Dim_Label. (Tier 1 — Dictionary.Label) |
| 20 | IsValidCustomer | int | YES | 1 when not Popular Investor (PlayerLevelID != 4), not label 30/26, and not CountryID=250. Point-in-time snapshot from Fact_SnapshotCustomer. (Tier 2 — SP_DepositWithdrawFee) |
| 21 | UpdateDate | datetime | NO | Row load timestamp (GETDATE() at insert). (Tier 2 — SP_DepositWithdrawFee) |
| 22 | BaseExchangeRate | numeric(38,8) | YES | Reference exchange rate before fee markup from the state fact. Spread = ExchangeRate minus BaseExchangeRate. (Tier 2 — SP_DepositWithdrawFee) |
| 23 | ExchangeFee | numeric(38,8) | YES | Exchange fee from the state fact in provider-specific encoding. (Tier 2 — SP_DepositWithdrawFee) |
| 24 | ExternalTransactionID | varchar(200) | YES | Payment provider transaction ID (ExTransactionID from state fact). Used for provider-side reconciliation. (Tier 2 — SP_DepositWithdrawFee) |
| 25 | Depot | varchar(200) | YES | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). Used in admin dashboards, routing logs, and discrepancy reports. Passthrough from Dim_BillingDepot. (Tier 1 — Billing.Depot) |
| 26 | MIDValue | varchar(200) | YES | Merchant ID value from the state fact (MID column). Identifies the acquiring bank's merchant account. (Tier 2 — SP_DepositWithdrawFee) |
| 27 | Club | varchar(200) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Passthrough from Dim_PlayerLevel. (Tier 1 — Dictionary.PlayerLevel) |
| 28 | PlayerStatus | varchar(200) | YES | Human-readable restriction state label (e.g., Normal, Blocked, Trade & MIMO Blocked). Passthrough from Dim_PlayerStatus. (Tier 1 — Dictionary.PlayerStatus) |
| 29 | PIPsCalculation | numeric(38,8) | YES | ABS(ISNULL(PIPsInUSD,0)) at insert; signed via #amountDirections (Withdraw type keeps original sign); further corrected via Fact_CustomerAction JOIN for CashoutRollback/CancelledCashoutRollback/CancelledChargebackReversal edge cases. (Tier 2 — SP_DepositWithdrawFee) |
| 30 | RegCountry | varchar(200) | YES | Full country name in English for the customer's registration country. Passthrough from Dim_Country via snapshot CountryID (withdraw) or Dim_Customer.CountryID (deposit). (Tier 1 — Dictionary.Country) |
| 31 | RegCountryByIP | varchar(50) | YES | Full country name in English for the customer's IP-detected country. Passthrough from Dim_Country via Dim_Customer.CountryIDByIP. (Tier 1 — Dictionary.Country) |
| 32 | CardType | varchar(200) | YES | Card network brand. Deposit path: raw CardType string from Fact_Deposit_State. Withdraw path: CarTypeName from Dim_CardType via Fact_BillingWithdraw.CardTypeIDAsInteger. Values: Visa, Master Card, Maestro, N/A. (Tier 2 — SP_DepositWithdrawFee) |
| 33 | CardCategory | varchar(200) | YES | Card product category (e.g., 'Visa Classic', 'Gold MasterCardr Card', 'Debit MasterCardr (Enhanced)'). From Fact_Deposit_State.CardCategory (deposit) or Fact_BillingWithdraw.CardCategory (withdraw). (Tier 2 — SP_DepositWithdrawFee) |
| 34 | BinCountry | varchar(200) | YES | Full country name in English for the country associated with the card BIN code. Passthrough from Dim_Country via BinCountryIDAsInteger from Fact_BillingDeposit (deposit) or Fact_BillingWithdraw (withdraw). (Tier 1 — Dictionary.Country) |
| 35 | MOPCountry | varchar(200) | YES | Not populated (NULL literal) in current SP build. Reserved column for method-of-payment country. (Tier 2 — SP_DepositWithdrawFee) |
| 36 | IsGermanBaFin | int | YES | Not populated (NULL literal) in current SP build. Reserved column for German BaFin regulatory flag. (Tier 2 — SP_DepositWithdrawFee) |
| 37 | IsIBANTrade | int | YES | 1 when the billing fact FlowID indicates IBAN processing: FlowID = 1 (deposit path) or FlowID = 2 (withdraw path); else 0. (Tier 2 — SP_DepositWithdrawFee) |
| 38 | MIDName | varchar(200) | YES | Human-readable merchant ID display name from the state fact (e.g., 'eToroEU', 'eToroUS', 'EMUK', 'ACH(Silvergate)'). (Tier 2 — SP_DepositWithdrawFee) |
| 39 | GuruStatus | varchar(200) | YES | Human-readable PI tier name: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Passthrough from Dim_GuruStatus. (Tier 1 — Dictionary.GuruStatus) |
| 40 | PreviousTransactionStatus | varchar(200) | YES | Prior status on the state fact before the current modification (PreviousStatus column). Empty string for initial creation events. (Tier 2 — SP_DepositWithdrawFee) |
| 41 | TransactionStatus | varchar(200) | YES | Current status from the state fact (DepositStatus for deposit path, CashoutStatus for withdraw path). Values: Refund, Chargeback, ChargebackReversal, Approved, ReversedDeposit, Processed, Partialy Reversed, Reversed, RefundReversal. (Tier 2 — SP_DepositWithdrawFee) |
| 42 | DepositID | int | YES | Populated on deposit reversal rows; NULL on withdraw rollback rows. References Fact_BillingDeposit.DepositID. (Tier 2 — SP_DepositWithdrawFee) |
| 43 | WithdrawPaymentID | int | YES | Populated on withdraw rollback rows; NULL on deposit reversal rows. References Fact_BillingWithdraw.WithdrawPaymentID. (Tier 2 — SP_DepositWithdrawFee) |
| 44 | CreditID | bigint | YES | Credit record ID from the state fact. Used for Fact_CustomerAction JOIN in post-insert PIPsCalculation sign corrections. Added SR-328549 (2025-08-10). (Tier 2 — SP_DepositWithdrawFee) |
| 45 | ExchangeFeePercentage | decimal(20,5) | YES | Exchange fee as a percentage. Sourced from Fact_Deposit_State.FeeInPercentage (deposit path) or Fact_Cashout_State.ExchaFeeInPercentage (withdraw path). Added SR-359957 (2026-03-04). (Tier 2 — SP_DepositWithdrawFee) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| DateID | SP_DepositWithdrawFee | @StartDateID | ETL-computed: CONVERT(VARCHAR(8), @StartDate, 112) |
| CID | Fact_Deposit_State / Fact_Cashout_State | CID | Passthrough |
| DepositWithdrawID | Fact_Deposit_State / Fact_Cashout_State | DepositID / WithdrawID | Passthrough |
| Occurred | Fact_Deposit_State / Fact_Cashout_State | ModificationDate | Passthrough |
| CreditTypeID | — | — | NULL literal (retired) |
| TransactionID | Fact_Deposit_State / Fact_Cashout_State | DepositID / WPID | CAST + suffix ('D' or 'W') |
| Date | Fact_Deposit_State / Fact_Cashout_State | ModificationDate | CAST AS DATE |
| Customer | Dim_Customer | ExternalID | CAST AS VARCHAR(50) |
| TransactionType | Fact_Deposit_State / Fact_Cashout_State | TransactionType | Passthrough (filtered != Deposit/Withdraw) |
| PaymentMethod | Dim_FundingType | Name | Dim-lookup via FundingTypeID |
| Amount | Fact_Deposit_State / Fact_Cashout_State | Amount | ABS() + sign correction |
| Currency | Dim_Currency | Abbreviation | Dim-lookup via CurrencyID |
| ExchangeRate | Fact_Deposit_State / Fact_Cashout_State | ExchangeRate | Passthrough |
| AmountUSD | Fact_Deposit_State / Fact_Cashout_State | AmountInUSD | ABS() + sign correction |
| RegulationID | Fact_SnapshotCustomer | RegulationID | Snapshot lookup |
| LabelID | Fact_SnapshotCustomer / Dim_Customer | LabelID | Snapshot lookup |
| PlayerLevelID | Fact_SnapshotCustomer | PlayerLevelID | Snapshot lookup |
| Regulation | Dim_Regulation | Name | Dim-lookup via RegulationID |
| Label | Dim_Label | Name | Dim-lookup via LabelID |
| IsValidCustomer | Fact_SnapshotCustomer | IsValidCustomer | Snapshot lookup |
| UpdateDate | — | — | GETDATE() |
| BaseExchangeRate | Fact_Deposit_State / Fact_Cashout_State | BaseExchangeRate | Passthrough |
| ExchangeFee | Fact_Deposit_State / Fact_Cashout_State | ExchangeFee | Passthrough |
| ExternalTransactionID | Fact_Deposit_State / Fact_Cashout_State | ExTransactionID | Passthrough (rename) |
| Depot | Dim_BillingDepot | Name | Dim-lookup via DepotID |
| MIDValue | Fact_Deposit_State / Fact_Cashout_State | MID | Passthrough (rename) |
| Club | Dim_PlayerLevel | Name | Dim-lookup via PlayerLevelID |
| PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup via PlayerStatusID |
| PIPsCalculation | Fact_Deposit_State / Fact_Cashout_State | PIPsInUSD | ABS(ISNULL()) + sign correction + Fact_CustomerAction edge-case fix |
| RegCountry | Dim_Country | Name | Dim-lookup via CountryID |
| RegCountryByIP | Dim_Country | Name | Dim-lookup via CountryIDByIP |
| CardType | Fact_Deposit_State / Dim_CardType | CardType / CarTypeName | Mixed: passthrough (deposit) / dim-lookup (withdraw) |
| CardCategory | Fact_Deposit_State / Fact_BillingWithdraw | CardCategory | Passthrough |
| BinCountry | Dim_Country | Name | Dim-lookup via BinCountryIDAsInteger |
| MOPCountry | — | — | NULL literal |
| IsGermanBaFin | — | — | NULL literal |
| IsIBANTrade | Fact_BillingDeposit / Fact_BillingWithdraw | FlowID | CASE WHEN FlowID = 1/2 THEN 1 ELSE 0 END |
| MIDName | Fact_Deposit_State / Fact_Cashout_State | MIDName | Passthrough |
| GuruStatus | Dim_GuruStatus | GuruStatusName | Dim-lookup via GuruStatusID |
| PreviousTransactionStatus | Fact_Deposit_State / Fact_Cashout_State | PreviousStatus | Passthrough (rename) |
| TransactionStatus | Fact_Deposit_State / Fact_Cashout_State | DepositStatus / CashoutStatus | Passthrough |
| DepositID | Fact_Deposit_State | DepositID | Passthrough (deposit rows only) |
| WithdrawPaymentID | Fact_BillingWithdraw | WithdrawPaymentID | Passthrough (withdraw rows only) |
| CreditID | Fact_Deposit_State / Fact_Cashout_State | CreditID | Passthrough |
| ExchangeFeePercentage | Fact_Deposit_State / Fact_Cashout_State | FeeInPercentage / ExchaFeeInPercentage | Passthrough |

### 5.2 ETL Pipeline

```
etoro.Billing.BI_Deposit_State_Report (production)     etoro.Billing.BI_Cashout_State_Report (production)
  |-- Custom pipeline (daily) ---|                        |-- Custom pipeline (daily) ---|
  v                                                       v
DWH_dbo.Fact_Deposit_State                              DWH_dbo.Fact_Cashout_State
  (WHERE TransactionType != 'Deposit')                    (WHERE TransactionType != 'Withdraw')
  |                                                       |
  |-- JOIN Fact_BillingDeposit (FundingTypeID, FlowID, BinCountryID)
  |-- JOIN Dim_Customer (ExternalID, CountryIDByIP)
  |-- JOIN Fact_SnapshotCustomer + Dim_Range (point-in-time attributes)
  |-- JOIN Dim_FundingType, Dim_Currency, Dim_Regulation, Dim_Label,
  |        Dim_BillingDepot, Dim_PlayerLevel, Dim_PlayerStatus,
  |        Dim_Country, Dim_CardType, Dim_GuruStatus
  |
  v [SP_DepositWithdrawFee — DELETE by DateID + INSERT UNION ALL + sign corrections]
BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals (~19.8K rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source (deposits) | DWH_dbo.Fact_Deposit_State | Deposit state change events (non-deposit types) |
| Source (withdraws) | DWH_dbo.Fact_Cashout_State | Cashout state events (non-withdraw types) |
| Dedup | #fbwDeduped | DISTINCT on Fact_BillingWithdraw by WithdrawPaymentID |
| Temp deposit | #depositsRevesals | Deposit reversals + dim joins |
| Temp withdraw | #withdrawsrollbacks | Withdraw rollbacks + dim joins |
| Load | SP_DepositWithdrawFee | DELETE WHERE DateID = @StartDateID; INSERT UNION ALL |
| Sign fix | #amountDirections | UPDATE Amount, AmountUSD, PIPsCalculation signs |
| Edge fix | Fact_CustomerAction | UPDATE PIPsCalculation for CashoutRollback/CancelledCashoutRollback/CancelledChargebackReversal |
| Target | BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals | ~19.8K rows |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer who initiated the reversal |
| RegulationID | DWH_dbo.Dim_Regulation | Regulatory jurisdiction at reversal time |
| LabelID | DWH_dbo.Dim_Label | White-label brand |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | eToro Club tier at reversal time |
| DepositID | DWH_dbo.Fact_BillingDeposit | Source deposit (deposit reversals only) |
| WithdrawPaymentID | DWH_dbo.Fact_BillingWithdraw | Source withdrawal payment (withdraw rollbacks only) |
| CreditID | DWH_dbo.Fact_CustomerAction | Credit event for PIPsCalculation corrections |

### 6.2 Referenced By (other objects point to this)

No downstream consumers identified. This is a BI reporting output table consumed by finance reconciliation and payment analytics.

---

## 7. Sample Queries

### 7.1 Monthly chargeback volume and USD amounts

```sql
SELECT
    DateID / 100 AS YearMonth,
    TransactionType,
    COUNT(*) AS reversal_count,
    SUM(AmountUSD) AS total_usd
FROM [BI_DB_dbo].[BI_DB_DepositWithdrawFee_Reversals]
WHERE TransactionType IN ('Chargeback', 'ChargebackReversal')
GROUP BY DateID / 100, TransactionType
ORDER BY YearMonth DESC;
```

### 7.2 Refund breakdown by regulation and payment method

```sql
SELECT
    Regulation,
    PaymentMethod,
    COUNT(*) AS refund_count,
    SUM(AmountUSD) AS refund_usd,
    SUM(PIPsCalculation) AS pips_usd
FROM [BI_DB_dbo].[BI_DB_DepositWithdrawFee_Reversals]
WHERE TransactionType = 'Refund'
GROUP BY Regulation, PaymentMethod
ORDER BY refund_usd;
```

### 7.3 Transaction type distribution (current year)

```sql
SELECT
    TransactionType,
    TransactionStatus,
    COUNT(*) AS cnt,
    SUM(Amount) AS total_amount,
    SUM(AmountUSD) AS total_usd
FROM [BI_DB_dbo].[BI_DB_DepositWithdrawFee_Reversals]
WHERE DateID >= 20260101
GROUP BY TransactionType, TransactionStatus
ORDER BY cnt DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found directly referencing this table. Related context exists under the deposit/withdrawal fee reporting domain — see sibling table `BI_DB_DepositWithdrawFee` documentation.

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 11 T1, 34 T2, 0 T3, 0 T4, 0 T5 | Elements: 45/45, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals | Type: Table | Production Source: SP_DepositWithdrawFee (Fact_Deposit_State + Fact_Cashout_State)*
