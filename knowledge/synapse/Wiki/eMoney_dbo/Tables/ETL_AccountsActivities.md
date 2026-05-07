# eMoney_dbo.ETL_AccountsActivities

**Schema**: eMoney_dbo | **UC Target**: `bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities`
**Row count**: ~30.5M (2020-11-06 → 2026-05-06; daily refresh active) | **Refresh**: daily (Override generic pipeline)
**Distribution**: ROUND_ROBIN (default) | **Type**: USER_TABLE
**Writer**: `eMoney_dbo.SP_eMoney_Reconciliation_ETLs` (Section: "Reconciliation Table 04 — Account Activities")

---

## 1. Business Meaning

**Daily-refreshed transaction event log** for eToro Money accounts across all eMoney programs (UK GBP, EU multi-currency, AUD via Banking Circle, etc.). One row = one debit/credit event on a holder's account, including:

- Card POS / ATM transactions (CardNumberId set, MerchantNumber set in settlements sibling)
- Direct debits / credits to fiat bank accounts (BankAccountIban / BankAccountNumber set)
- Internal transfers between eToro Money holder accounts
- EPM (External Payment Mechanism) inbound/outbound bank transfers (SEPA, Faster Payments, etc.)
- UNLOAD / LOAD operations (moving funds in/out of the eMoney program from the trading platform)
- Fee bookings (FX fees, F0 fees), interchange-related events

The table is sourced from the **Tribe** card-issuer platform feed (the eMoney processor — Tribe Payments, formerly Modulr/UAB Foras Bank). It is one of three sibling reconciliation tables produced by `SP_eMoney_Reconciliation_ETLs`:

1. `ETL_CardSnapshot` — point-in-time card status
2. `ETL_SettlementsTransactions` — Visa-network settlement events with merchant detail (sibling — see [its wiki](ETL_SettlementsTransactions.md))
3. **`ETL_AccountsActivities`** — this table — broader account-level event log
4. `eMoney_BankPaymentsUK` — UK bank-payments subledger (derived from this table)

**Granularity**: one row per `TransactionId` (provider-side unique transaction identifier). The same logical money movement (e.g., a card POS) may appear in **both** this table and `ETL_SettlementsTransactions` — they capture different views of the same provider feed.

---

## 2. Business Logic

### 2.1 Source Pipeline
The writer SP `SP_eMoney_Reconciliation_ETLs` reads from `eMoney_Tribe.AccountsActivities-509416` and related Tribe staging tables (`AccountsActivities_AccountActivity-*`, `AccountsActivities_SecurityChecks-*`). It first stages into a temp table `#AccountsActivities` (HEAP, ROUND_ROBIN), then DELETE+INSERT into the target.

### 2.2 Incremental Load Pattern
```sql
DECLARE @AccountActivities_DATE = (SELECT ISNULL(MAX(Created),'1900-01-01') FROM ETL_AccountsActivities);
-- stage to #AccountsActivities WHERE @Created >= @AccountActivities_DATE
DELETE FROM ETL_AccountsActivities WHERE Created >= @AccountActivities_DATE;
INSERT INTO ETL_AccountsActivities SELECT * FROM #AccountsActivities;
```

This is an **idempotent incremental rerun** — re-loads the latest day in case of late-arriving Tribe rows.

### 2.3 Multi-Program Coverage
A single row could be a UK card payment, a EU SEPA transfer, or an AUD Banking Circle payment — all coexist in this table. Always filter by `ProgramName` / `ProgramId` (or `IssuerIdentificationNumber` / BIN) when scoping to a specific program.

### 2.4 Money Direction
- `TransactionAmount` — signed value in transaction currency. Negative = debit from holder; Positive = credit.
- `Action` — text-encoded direction ('Debit' / 'Credit').
- `TransactionClass` — 'POS', 'ATM', 'Unknown', etc. — provider-side classification.
- `BalanceAdjustmentType` — int code mapping to the Tribe internal balance-event taxonomy.

### 2.5 Transaction Codes
The (`TransactionCode`, `TransactionCodeDescription`, `TransactionCodeIdentifier`) triple encodes the Tribe transaction taxonomy. Common values seen in samples: `UNLOAD`, `EPM_INBOUND`, `EPM_OUTBOUND`, `POS`, `ATM`, `FEE`, etc.

### 2.6 Fee Columns — FxFee* and F0Fee*
Two parallel fee blocks:
- `FxFee*` — FX conversion fee (typically when transaction currency ≠ holder currency)
- `F0Fee*` — Tribe-internal "fee zero" / base service fee (interchange, scheme fees, etc.)

Both blocks have Amount/Currency/Name/Reason. NULL values are common — most transactions have no fee.

### 2.7 Risk / Suspicious Flags
The block `Suspicious`, `RiskRuleCodes`, `MarkTransactionAsSuspicious`, `NotifyCardholderBySendingTAIsNotification`, `ChangeCardStatusToRisk`, `ChangeAccountStatusToSuspended`, `RejectTransaction` are populated by Tribe's risk engine. Boolean bit columns indicate whether the transaction triggered each risk action.

### 2.8 Card Verification Flags
`CardExpirationDatePresent`, `OnlinePIN`, `OfflinePIN`, `ThreeDomainSecure`, `Cvv2`, `MagneticStripe`, `AVS`, `PhoneNumber`, `Signature` — bit flags from the EMV / card-not-present authentication spec. These tell which authentication factors were verified.

### 2.9 Identifiers Without External Cross-Reference
`HolderId`, `AccountId`, `CardNumberId`, `BankAccountId`, `EpmTransactionId`, `EpmMandateId` — all are Tribe-side surrogate IDs. To link to the eToro side, join through `eMoney_dbo.FiatAccount` (HolderId → Gcid) and `eMoney_dbo.ETL_CardSnapshot` (CardNumberId → CardEvent).

---

## 3. Query Advisory

### 3.1 Use This With ETL_SettlementsTransactions
For card-specific merchant analytics, prefer [`ETL_SettlementsTransactions`](ETL_SettlementsTransactions.md) — that sibling has merchant name, MCC, country, ARN, etc. This table is broader (covers non-card transactions too) but has less merchant detail.

### 3.2 Multi-Currency
- `TransactionCurrencyAlpha` (3-letter ISO) and `TransactionCurrencyCode` (numeric ISO) describe the transaction's source currency.
- `HolderCurrencyAlpha` describes the holder-account base currency.
- `BillingCurrencyAlpha` describes the billing currency to the cardholder (after FX, for cards).
- `SettlementCurrencyAlpha` describes the network-side settlement currency.
- `FxRate`, `BillRateAmount`, `SettlementConversionRate` are the various conversion rates applied.

### 3.3 Date Filtering
Two date-like columns:
- `Date` (DATE) + `DateID` (YYYYMMDD int) — derived from `TransactionDateTime`
- `Created` (DATETIME) — Tribe-side row-creation timestamp; primary key for incremental load

Filter by `Date` for analytics; filter by `Created` only for ETL audit / late-arriving row analysis.

### 3.4 PII Columns
- `BankAccountIban`, `BankAccountNumber`, `BankAccountSortCode`, `BankAccountBic` — UK / SEPA account identifiers
- `CardNumber` — masked card PAN (typically `4596XXXXXXXX1234` format from Tribe)
- `ExternalIban`, `ExternalAccountName`, `ExternalAccountNumber`, `ExternalSortCode`, `ExternalBic`, `ExternalBban` — counterparty bank identifiers
- `OriginatorId`, `OriginatorName`, `OriginatorServiceUserNumber` — counterparty identification (for incoming direct debits)

These should be tagged PII in UC and access-controlled.

### 3.5 Ndays vs nvarchar(max)
Most string columns are `nvarchar(max)` from the Tribe feed. Cast / trim if precise length matters.

### 3.6 Action Column Values
Sample values: `'Debit'`, `'Credit'`, `'Unknown'`. The `Network` column gives `'Internal Payment'`, `'External Payment'`, `'Visa'`, `'Mastercard'`, etc.

### 3.7 Override Generic Pipeline
The UC pipeline is **Override** (not Append/Merge). Each daily batch wipes & rewrites the entire UC Delta table. Long-running queries against UC during pipeline execution may see partial / stale data.

---

## 4. Elements

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | FileName | nvarchar(MAX) | Source file name from the Tribe feed (often NULL — most transactions are real-time, not file-based). |
| 2 | WorkDate | datetime | Transaction processing date/time on the Tribe side (provider-local time). |
| 3 | IssuerIdentificationNumber | int | BIN-like issuer identifier — identifies the eMoney program issuer (Tribe-side IIN). |
| 4 | ProgramName | nvarchar(MAX) | Human-readable program name (e.g., 'eToro Money UK GBP', 'eToro Money EU Account', 'Banking Circle - AUD - Account'). |
| 5 | ProgramId | int | Tribe-side program identifier. |
| 6 | ProductName | nvarchar(MAX) | Card / account product label (e.g., 'eToro Money 459688 Consumer Debit Visa'). NULL for non-card programs. |
| 7 | ProductId | int | Tribe-side product identifier. |
| 8 | SubProductId | int | Sub-product identifier (e.g., specific card variant within a product family). |
| 9 | HolderId | int | Tribe-side holder (customer) identifier. Links via `FiatAccount.HolderId` to eToro `Gcid`. |
| 10 | AccountId | int | Tribe-side account identifier (a holder may have multiple accounts). |
| 11 | BankAccountId | int | Tribe-side internal bank account identifier (NULL when not bank-related). |
| 12 | ExternalBankAccountId | bigint | Tribe-side identifier for the external counterparty bank account. |
| 13 | BankAccountNumber | bigint | Domestic account number (UK/AU style). PII. |
| 14 | BankAccountSortCode | int | UK sort code (6-digit) of the holder's eMoney bank account. PII. |
| 15 | BankAccountIban | nvarchar(MAX) | IBAN of the holder's eMoney bank account (EU programs). PII. |
| 16 | BankAccountBic | nvarchar(MAX) | BIC/SWIFT of the holder's eMoney bank account. PII. |
| 17 | CardNumber | nvarchar(MAX) | Masked card PAN (typically '4596XX...XX1234'). PII. NULL for non-card transactions. |
| 18 | CardNumberId | bigint | Tribe-side surrogate ID for the card number — joins to `ETL_CardSnapshot.CardNumberId`. |
| 19 | CardRequestId | bigint | Tribe-side card-request identifier (originating card creation request). |
| 20 | Bin | int | Bank Identification Number (first 6 digits of PAN) for the card. |
| 21 | TransactionCode | int | Tribe transaction code — numeric code for the transaction type. |
| 22 | TransactionCodeDescription | nvarchar(MAX) | Text label for the transaction code (e.g., 'POS', 'UNLOAD', 'EPM_INBOUND'). |
| 23 | TransactionDateTime | datetime | Transaction occurrence timestamp (provider-local time). |
| 24 | TransactionAmount | float | Signed amount in transaction currency (negative = debit, positive = credit). |
| 25 | TransactionCurrencyCode | int | Numeric ISO 4217 currency code of the transaction. |
| 26 | TransactionCurrencyAlpha | nvarchar(MAX) | Alpha-3 ISO 4217 currency code of the transaction (e.g., 'GBP', 'EUR', 'AUD'). |
| 27 | TransLink | nvarchar(MAX) | Tribe-side link/reference identifier for related transactions (e.g., refund → original). |
| 28 | TraceId | bigint | Tribe-side trace identifier (for transaction reconciliation). |
| 29 | TransactionCodeIdentifier | int | Secondary numeric code grouping similar TransactionCodes. |
| 30 | HolderAmount | float | Transaction amount in the holder-account base currency (after FX). |
| 31 | HolderCurrencyAlpha | nvarchar(MAX) | Alpha-3 ISO of the holder-account base currency. |
| 32 | FxRate | float | FX rate from transaction currency to holder currency applied to derive `HolderAmount`. |
| 33 | FeeGroupId | bigint | Tribe-side fee-group identifier — identifies the fee schedule applied. |
| 34 | FeeGroupName | nvarchar(MAX) | Human-readable fee-group label. |
| 35 | FxFeeAmount | float | FX-conversion fee amount (NULL when no FX fee). |
| 36 | FxFeeName | nvarchar(MAX) | FX-fee label / type. |
| 37 | FxFeeCurrency | nvarchar(MAX) | Currency in which the FX fee is denominated. |
| 38 | FxFeeReason | nvarchar(MAX) | Reason / category for the FX fee. |
| 39 | F0FeeName | nvarchar(MAX) | F0 (base service / interchange) fee label. |
| 40 | F0FeeAmount | float | F0 fee amount. |
| 41 | F0FeeCurrency | int | Numeric ISO currency code of the F0 fee. |
| 42 | F0FeeReason | nvarchar(MAX) | Reason / category for the F0 fee. |
| 43 | BillRateAmount | float | Conversion rate from transaction currency to billing currency. |
| 44 | BillingDate | date | Date the transaction is/was posted to the billing cycle. |
| 45 | BillingAmount | float | Amount charged in billing currency (post-FX, post-fee where applicable). |
| 46 | BillingCurrencyCode | int | Numeric ISO code of the billing currency. |
| 47 | BillingCurrencyAlpha | nvarchar(MAX) | Alpha-3 ISO of the billing currency. |
| 48 | SettlementAmount | float | Network-side settlement amount in settlement currency (after Visa/Mastercard rules). |
| 49 | SettlementCurrencyCode | int | Numeric ISO code of the settlement currency. |
| 50 | SettlementCurrencyAlpha | nvarchar(MAX) | Alpha-3 ISO of the settlement currency. |
| 51 | SettlementConversionRate | nvarchar(MAX) | Conversion rate from transaction → settlement currency (string for precision). |
| 52 | CardPresent | nvarchar(MAX) | Card-present indicator (Y/N or text label). |
| 53 | TransactionId | bigint | Tribe-side primary transaction identifier (provider-unique). |
| 54 | TransactionClass | nvarchar(MAX) | Tribe transaction class label (e.g., 'POS', 'ATM', 'Unknown', 'Internal'). |
| 55 | Action | nvarchar(MAX) | Direction/action label ('Debit', 'Credit', etc.). |
| 56 | Network | nvarchar(MAX) | Payment network ('Visa', 'Mastercard', 'Internal Payment', 'External Payment', etc.). |
| 57 | TransactionDescription | nvarchar(MAX) | Free-text transaction description from Tribe. |
| 58 | EntryModeCode | int | EMV entry-mode code (chip, contactless, mag-stripe, manual, etc.). |
| 59 | EntryModeCodeDescription | nvarchar(MAX) | Text label for `EntryModeCode`. |
| 60 | ReferenceNumber | nvarchar(MAX) | Provider reference number (often the card-acquirer ARN). |
| 61 | CountryIson | int | Numeric ISO country code of the transaction location. |
| 62 | LoadType | int | Tribe load-type code (when transaction is a wallet load — distinguishes load source). |
| 63 | LoadSource | int | Tribe load-source code (specific load channel). |
| 64 | EpmMethodId | bigint | EPM (External Payment Mechanism) method identifier — used for SEPA, Faster Payments, etc. |
| 65 | EpmTransactionId | bigint | EPM-specific transaction identifier. |
| 66 | ExternalEpmTransactionId | bigint | External (counterparty / scheme) EPM transaction identifier. |
| 67 | EpmTransactionType | int | EPM transaction type code (Inbound / Outbound / Reversal / etc.). |
| 68 | EpmTransactionStatusCode | int | EPM status code (Pending / Settled / Failed / Returned / etc.). |
| 69 | EpmMandateId | bigint | EPM mandate identifier (for direct-debit mandates). |
| 70 | Reference | nvarchar(MAX) | Free-text reference field (often counterparty-supplied). |
| 71 | TransactionIdentifier | nvarchar(MAX) | Provider/scheme transaction identifier (e.g., end-to-end ID for SEPA). |
| 72 | EndToEndIdentifier | nvarchar(MAX) | SEPA end-to-end identifier. |
| 73 | Suspicious | nvarchar(MAX) | Provider-side suspicious-flag label. |
| 74 | RiskRuleCodes | nvarchar(MAX) | Comma-separated list of risk-engine rule codes triggered by this transaction. |
| 75 | BalanceAdjustmentType | int | Tribe internal balance-adjustment type code. |
| 76 | MarkTransactionAsSuspicious | bit | Risk action — flag the transaction as suspicious. |
| 77 | NotifyCardholderBySendingTAIsNotification | bit | Risk action — send TAIS (Transaction Alerts) notification to cardholder. |
| 78 | ChangeCardStatusToRisk | bit | Risk action — automatically change card status to RISK. |
| 79 | ChangeAccountStatusToSuspended | bit | Risk action — automatically suspend account. |
| 80 | RejectTransaction | bit | Risk action — reject the transaction (transaction was declined). |
| 81 | CardExpirationDatePresent | bit | Auth verification flag — was card expiration date present in the auth message. |
| 82 | OnlinePIN | bit | Auth verification flag — online PIN verified. |
| 83 | OfflinePIN | bit | Auth verification flag — offline PIN verified. |
| 84 | ThreeDomainSecure | bit | Auth verification flag — 3DS authenticated. |
| 85 | Cvv2 | bit | Auth verification flag — CVV2 verified. |
| 86 | MagneticStripe | bit | Auth verification flag — magnetic stripe used. |
| 87 | AVS | bit | Auth verification flag — Address Verification Service result valid. |
| 88 | PhoneNumber | bit | Auth verification flag — phone number verified. |
| 89 | Signature | bit | Auth verification flag — signature verified. |
| 90 | Date | date | Calendar date of the transaction (DATE part of `TransactionDateTime`). Use for partition / date-range filtering. |
| 91 | DateID | int | YYYYMMDD integer of `Date`. Joins to `DWH_dbo.Dim_Date.DateID`. |
| 92 | UpdateDate | datetime | Batch insert timestamp (`GETDATE()` at write). |
| 93 | Created | datetime | Tribe-side row creation timestamp. **Primary key for incremental load** (max(Created) drives next-load watermark). |
| 94 | InternalIbanCountry | nvarchar(MAX) | Country code of the internal eMoney IBAN. |
| 95 | ExternalIban | nvarchar(MAX) | Counterparty IBAN. PII. |
| 96 | ExternalBban | nvarchar(MAX) | Counterparty BBAN. PII. |
| 97 | ExternalAccountName | nvarchar(MAX) | Counterparty account holder name. PII. |
| 98 | ExternalAccountNumber | nvarchar(MAX) | Counterparty account number (domestic). PII. |
| 99 | ExternalSortCode | nvarchar(MAX) | Counterparty sort code (UK). PII. |
| 100 | ExternalBic | nvarchar(MAX) | Counterparty BIC/SWIFT. PII. |
| 101 | OriginatorId | nvarchar(MAX) | Direct-debit originator identifier (UK). |
| 102 | OriginatorName | nvarchar(MAX) | Direct-debit originator name. |
| 103 | OriginatorServiceUserNumber | nvarchar(MAX) | UK Direct Debit Service User Number (SUN) of the originator. |
| 104 | TransactionReferenceNumber | nvarchar(MAX) | Provider transaction reference number (separate from `ReferenceNumber` — used by EPM). |
| 105 | ActualEndToEndIdentifier | nvarchar(MAX) | Actual SEPA / FP end-to-end identifier as received from the counterparty. |

---

## 5. Lineage

### 5.1 Source Pipeline

```
Tribe (eMoney provider) production feed
  └─ eMoney_Tribe.AccountsActivities-509416, AccountsActivities_AccountActivity-*, AccountsActivities_SecurityChecks-*
      └─ SP_eMoney_Reconciliation_ETLs (daily, P1 — section "Reconciliation Table 04 — Account Activities")
          └─ #AccountsActivities (temp, HEAP, ROUND_ROBIN)
              └─ DELETE+INSERT eMoney_dbo.ETL_AccountsActivities
                  ├─ Generic Pipeline (Override, daily) → bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities
                  └─ Downstream: eMoney_dbo.eMoney_BankPaymentsUK (UK bank-payments subledger)
```

### 5.2 Sibling / Related Tables

| Table | Relationship |
|-------|--------------|
| [`ETL_SettlementsTransactions`](ETL_SettlementsTransactions.md) | Sibling — Visa-network settlements with merchant detail |
| `eMoney_dbo.ETL_CardSnapshot` | Card status snapshot — joins on `CardNumberId` |
| `eMoney_dbo.eMoney_BankPaymentsUK` | UK bank-payments subledger — derived from this table |
| [`eMoney_dbo.FiatAccount`](FiatAccount.md) | Holder/account dimension — `HolderId` → `Gcid` link to eToro customer |

---

## 6. Sample Queries

```sql
-- Daily volume of card POS transactions by program (last 30 days)
SELECT
    Date,
    ProgramName,
    COUNT(*) AS num_txns,
    SUM(ABS(TransactionAmount)) AS abs_volume
FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities
WHERE Date >= current_date() - INTERVAL 30 DAYS
  AND TransactionCodeDescription = 'POS'
GROUP BY Date, ProgramName
ORDER BY Date DESC, abs_volume DESC;
```

```sql
-- Suspicious-flag rate per program
SELECT
    ProgramName,
    SUM(CASE WHEN MarkTransactionAsSuspicious = 1 THEN 1 ELSE 0 END) AS suspicious_n,
    COUNT(*) AS total_n,
    SUM(CASE WHEN MarkTransactionAsSuspicious = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS suspicious_rate
FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities
WHERE Date >= current_date() - INTERVAL 7 DAYS
GROUP BY ProgramName
ORDER BY total_n DESC;
```

---

*Generated as part of Wave 2 medium-priority documentation effort. Sibling: [`ETL_SettlementsTransactions`](ETL_SettlementsTransactions.md).*
