# eMoney_dbo.ETL_SettlementsTransactions

**Schema**: eMoney_dbo | **UC Target**: `bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions`
**Row count**: ~3.0M (2020-11-17 → 2026-05-06; daily refresh active) | **Refresh**: daily (Override generic pipeline)
**Distribution**: ROUND_ROBIN (default) | **Type**: USER_TABLE
**Writer**: `eMoney_dbo.SP_eMoney_Reconciliation_ETLs` (Section: "Reconciliation Table 02 — Settlement Transactions")

---

## 1. Business Meaning

**Visa / Mastercard scheme-network settlement event log** for eToro Money cards. One row = one settlement event posted by the card network to Tribe's clearing system, including merchant detail (name, country, MCC), interchange fees, ECI indicator, and acquirer reference number (ARN).

This is the **card-payment-with-merchant-context** view of the eMoney transaction stream. It is a sibling of [`ETL_AccountsActivities`](ETL_AccountsActivities.md):

| Aspect | `ETL_AccountsActivities` | `ETL_SettlementsTransactions` (this table) |
|--------|--------------------------|---------------------------------------------|
| Scope | All account events (cards, bank, internal, EPM) | **Card scheme settlements only** (Visa/Mastercard) |
| Merchant detail | No | **Yes** (MerchantName, MerchantCountryName, Mcc, AcquirerReferenceNumber) |
| Card detail | Yes | Yes |
| Bank detail | Yes (IBAN, sort code, etc.) | No |
| Network info | Network text label | **MtiCode, FunctionCode, ECIIndicator, MessageReasonCode** |
| Settlement view | After-the-fact summary | Network-side settlement file detail |
| Row count | ~30.5M | ~3.0M |

**Granularity**: one row per `TransactionId` (Tribe-side) per settlement event. The same card POS may produce one auth row in `ETL_AccountsActivities` plus one settlement row here once the merchant submits the clearing batch (typically T+1 to T+3).

---

## 2. Business Logic

### 2.1 Source Pipeline
The writer SP `SP_eMoney_Reconciliation_ETLs` (Section "Reconciliation Table 02") reads from Tribe's settlements staging tables (`eMoney_Tribe.SettlementsTransactions-*`). It then DELETE+INSERTs the target.

### 2.2 Incremental Load Pattern
```sql
DECLARE @SettlementsTransactions_DATE = (SELECT ISNULL(MAX(Created),'1900-01-01') FROM ETL_SettlementsTransactions);
DELETE FROM ETL_SettlementsTransactions WHERE Created >= @SettlementsTransactions_DATE;
INSERT INTO ETL_SettlementsTransactions SELECT DISTINCT ... FROM Tribe staging WHERE Created >= @SettlementsTransactions_DATE;
```

The `SELECT DISTINCT` was added 2025-12-21 (changelog: "add distincts and remove filename to avoid duplicates handling") to suppress duplicate rows that emerged from Tribe staging changes.

### 2.3 Settlement Lifecycle (Visa Network)
1. **Authorization** — captured in `ETL_AccountsActivities` as a POS auth.
2. **Clearing** — merchant submits batch to acquirer (T+0 to T+1).
3. **Settlement** — Visa scheme settles between acquirer and issuer (T+1 to T+3).
4. This table captures step 3 — the issuer-side (Tribe) view of the settlement.

`SettlementDate` and `ReconciliationDate` mark the network-side dates; `TransactionDateTime` is the original card-present moment.

### 2.4 Interchange Fees
- `InterchangeFeeAmount` — interchange paid/received between issuer and acquirer (per Visa rules)
- `InterchangeFeeCurrency` — currency of the interchange fee
- `InterchangeFeeDirection` — 'IRF Issuer Pays' / 'IRF Issuer Receives' / etc.
- `InterchangeRateDesignator` — Visa rate-designator code (e.g., 'Z3' = consumer credit signature, etc.)

These are critical for FX/Treasury and finance reconciliation.

### 2.5 Merchant Identification
- `MerchantNumber` — Visa-assigned merchant ID (often the acquirer's MID)
- `Merchant` / `MerchantName` — display name (sample shows trimmed names like 'SAINSBURYS.CO.UK', 'SPAR STORE')
- `MerchantAddress`, `MerchantCity`, `MerchantPostcode`, `MerchantCountryCodeAlpha`, `MerchantCountryName` — merchant location
- `Mcc` — Merchant Category Code (4-digit ISO 18245), e.g., 5411 = Grocery Stores, 5812 = Restaurants

### 2.6 Network Message Codes
- `MtiCode` — ISO 8583 Message Type Indicator (e.g., 100 = auth request, 200 = financial txn, 220 = advice)
- `MessageReasonCode` — sub-code for the message
- `FunctionCode` — Visa function code
- `BusinessFormatCode` — Visa BFC indicating business segment
- `ECIIndicator` — Electronic Commerce Indicator (1 = secure 3DS, 5 = secure non-3DS, 7 = non-secure)
- `TransactionCodeQualifier` — Visa TCQ code

### 2.7 POS Data DE22 / DE61
- `PosDataDe22` — Point-of-Service Data Code (Visa Data Element 22) — captures auth conditions like CVV/PIN/ARQC presence as a packed integer
- `PosDataDe61` — POS Data DE61 — terminal capabilities

### 2.8 Risk / Verification Flags
Same set as `ETL_AccountsActivities`: `Suspicious`, `RiskRuleCodes`, `MarkTransactionAsSuspicious`, `NotifyCardholderBySendingTAIsNotification`, `ChangeCardStatusToRisk`, `ChangeAccountStatusToSuspended`, `RejectTransaction`, plus authentication factor flags.

### 2.9 Dispute Linkage
`DisputeId`, `ExternalDisputeId`, `ParentTransactionId`, `ActualAuthorizationId`, `FirstAuthorizationDate` — populated when the settlement row relates to a dispute / chargeback. The `ActualAuthorizationId` links back to the original auth in `ETL_AccountsActivities`.

### 2.10 Cycle Numbering
`CycleNumber` and `CycleFileId` identify the Visa settlement-cycle batch the row was reported in.

---

## 3. Query Advisory

### 3.1 Use This For Card / Merchant Analytics
For "spend by category", "top merchants", "geographic spend pattern" — use **this** table, not `ETL_AccountsActivities`. The merchant fields are populated only here.

### 3.2 Settlement vs Authorization Timing
`TransactionDateTime` ≠ `SettlementDate` ≠ `ReconciliationDate`. For "when did the customer pay", use `TransactionDateTime` or `Date`. For "when did the money settle", use `SettlementDate`. For ETL audit, use `Created`.

### 3.3 Joining to Authorization
To link a settlement row to its authorization row in `ETL_AccountsActivities`:
- Best key: `ActualAuthorizationId` (this table) ↔ `AuthorizationCode` or `TransactionId` (auth table) — verify per-program semantics
- Alternative: same `(CardNumberId, TransactionAmount, TransactionDateTime ± few hours)` heuristic match

### 3.4 MCC Lookups
Standard ISO 18245 MCC codes — common categories:

| MCC | Category |
|-----|----------|
| 5411 | Grocery Stores |
| 5812 | Eating Places, Restaurants |
| 5541 | Service Stations |
| 5311 | Department Stores |
| 4900 | Utilities |
| 6011 | Manual Cash Disbursements (ATM) |
| 6051 | Quasi Cash – Member Financial Institution |

Bring an MCC dimension or join externally for analytics.

### 3.5 Country Coding
- `MerchantCountryCodeAlpha` — Alpha-3 ISO 3166 (e.g., 'GBR', 'USA')
- `MerchantCountryName` — full name (e.g., 'United Kingdom')
- Use one consistently per analysis — sample shows full-name population in current rows.

### 3.6 PII
- `CardNumber` — masked PAN. PII.
- `MerchantName`, `MerchantAddress` — typically not PII (legal entities) but may include sole-trader names — treat as low-sensitivity.
- `AuthorizationCode`, `AcquirerReferenceNumber` — quasi-identifiers; access-control if the customer link is exposed.

### 3.7 Override Pipeline
Same as sibling — UC pipeline is Override mode. Daily full rewrite. Long-running queries during pipeline window may see partial state.

### 3.8 Network is Always Visa-Family
Despite the `Network` column existing in `ETL_AccountsActivities`, this table is in practice **Visa-only** (eToro Money UK GBP and EU programs are Visa-issued). Mastercard rows (if any) would appear here too but are rare.

---

## 4. Elements

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | FileName | nvarchar(MAX) | Source settlement file name from Tribe (often NULL — replaced with NULL in 2025-12-21 SP update). |
| 2 | WorkDate | datetime | Tribe processing timestamp for the settlement event. |
| 3 | IssuerIdentificationNumber | int | Tribe-side issuer identification number. |
| 4 | ProgramName | nvarchar(MAX) | Card program (e.g., 'eToro Money UK GBP', 'eToro Money EU'). |
| 5 | ProgramId | int | Tribe-side program identifier. |
| 6 | ProductName | nvarchar(MAX) | Card product label (e.g., 'eToro Money 459688 Consumer Debit Visa'). |
| 7 | ProductId | int | Tribe-side product identifier. |
| 8 | SubProductId | int | Sub-product identifier within the product family. |
| 9 | HolderId | int | Tribe-side holder (customer) identifier. Joins to `FiatAccount.HolderId` → eToro `Gcid`. |
| 10 | AccountId | int | Tribe-side account identifier. |
| 11 | BankAccountId | int | Tribe-side bank-account identifier (if linked). |
| 12 | CardNumber | nvarchar(MAX) | Masked card PAN (e.g., '4596XX...XX1234'). PII. |
| 13 | CardNumberId | bigint | Tribe surrogate ID for the card — joins to `ETL_CardSnapshot`. |
| 14 | CardRequestId | bigint | Originating card-request identifier. |
| 15 | Bin | int | Card BIN (first 6 digits of PAN). |
| 16 | TransactionCode | int | Tribe transaction code (numeric). |
| 17 | TransactionCodeDescription | nvarchar(MAX) | Text label (e.g., 'POS', 'ATM', 'REFUND', 'CHARGEBACK'). |
| 18 | TransactionDateTime | datetime | Original card-present transaction timestamp. |
| 19 | TransactionAmount | float | Signed amount in transaction currency (negative = debit, positive = credit/refund). |
| 20 | TransactionCurrencyCode | int | Numeric ISO 4217 of the transaction currency. |
| 21 | TransactionCurrencyAlpha | nvarchar(MAX) | Alpha-3 ISO of the transaction currency. |
| 22 | TransLink | nvarchar(MAX) | Tribe-side link/reference for related transactions (e.g., refund → original auth). |
| 23 | TraceId | bigint | Tribe trace identifier for reconciliation. |
| 24 | TransactionCodeIdentifier | int | Secondary numeric grouping code. |
| 25 | HolderAmount | float | Amount in holder-account base currency (after FX). |
| 26 | HolderCurrencyAlpha | nvarchar(MAX) | Alpha-3 ISO of holder currency. |
| 27 | FxRate | float | FX rate applied (transaction → holder currency). |
| 28 | FeeGroupId | bigint | Fee-group identifier. |
| 29 | FeeGroupName | nvarchar(MAX) | Fee-group label. |
| 30 | FxFeeAmount | float | FX-conversion fee amount. |
| 31 | FxFeeName | nvarchar(MAX) | FX-fee label. |
| 32 | FxFeeCurrency | nvarchar(MAX) | FX-fee currency. |
| 33 | FxFeeReason | nvarchar(MAX) | FX-fee reason / category. |
| 34 | F0FeeName | nvarchar(MAX) | Base-service / interchange-related fee label. |
| 35 | F0FeeAmount | float | F0-fee amount. |
| 36 | F0FeeCurrency | int | Numeric ISO of the F0 fee currency. |
| 37 | F0FeeReason | nvarchar(MAX) | F0-fee reason / category. |
| 38 | BillRateAmount | float | Conversion rate from transaction currency to billing currency. |
| 39 | BillingDate | date | Date the transaction was/will be posted to the billing cycle. |
| 40 | BillingAmount | float | Billing-currency amount (post-FX). |
| 41 | BillingCurrencyCode | int | Numeric ISO of the billing currency. |
| 42 | BillingCurrencyAlpha | nvarchar(MAX) | Alpha-3 ISO of the billing currency. |
| 43 | SettlementAmount | float | Network-side settlement amount in settlement currency. |
| 44 | SettlementCurrencyCode | int | Numeric ISO of the settlement currency. |
| 45 | SettlementCurrencyAlpha | nvarchar(MAX) | Alpha-3 ISO of the settlement currency (e.g., 'GBP', 'EUR', 'USD'). |
| 46 | SettlementConversionRate | nvarchar(MAX) | Transaction → settlement currency conversion rate (string for precision). |
| 47 | CardPresent | nvarchar(MAX) | Card-present indicator (Y/N or text). |
| 48 | TransactionId | bigint | Tribe primary transaction identifier (provider-unique). |
| 49 | TransactionClass | nvarchar(MAX) | Transaction class label ('POS', 'ATM', etc.). |
| 50 | Action | nvarchar(MAX) | Direction label ('Debit', 'Credit'). |
| 51 | Network | nvarchar(MAX) | Card network (typically 'Visa' for eToro Money). |
| 52 | TransactionDescription | nvarchar(MAX) | Free-text description from Tribe. |
| 53 | EntryModeCode | int | EMV entry-mode code. |
| 54 | EntryModeCodeDescription | nvarchar(MAX) | Text label for `EntryModeCode`. |
| 55 | LoadType | int | Tribe load-type code. |
| 56 | LoadSource | int | Tribe load-source code. |
| 57 | Suspicious | nvarchar(MAX) | Risk-engine suspicious-flag label. |
| 58 | RiskRuleCodes | nvarchar(MAX) | Comma-separated risk-rule codes triggered. |
| 59 | MarkTransactionAsSuspicious | bit | Risk action — mark as suspicious. |
| 60 | NotifyCardholderBySendingTAIsNotification | bit | Risk action — send TAIS notification to cardholder. |
| 61 | ChangeCardStatusToRisk | bit | Risk action — auto-change card status to RISK. |
| 62 | ChangeAccountStatusToSuspended | bit | Risk action — auto-suspend account. |
| 63 | RejectTransaction | bit | Risk action — auto-reject. |
| 64 | CardExpirationDatePresent | bit | Auth verification — card expiration date present. |
| 65 | OnlinePIN | bit | Auth verification — online PIN. |
| 66 | OfflinePIN | bit | Auth verification — offline PIN. |
| 67 | ThreeDomainSecure | bit | Auth verification — 3DS. |
| 68 | Cvv2 | bit | Auth verification — CVV2. |
| 69 | MagneticStripe | bit | Auth verification — magnetic stripe. |
| 70 | AVS | bit | Auth verification — Address Verification Service. |
| 71 | PhoneNumber | bit | Auth verification — phone number. |
| 72 | Signature | bit | Auth verification — signature. |
| 73 | MtiCode | int | ISO 8583 Message Type Indicator (e.g., 100, 200, 220). |
| 74 | MessageReasonCode | nvarchar(MAX) | ISO 8583 sub-code clarifying the message reason. |
| 75 | AuthorizationCode | nvarchar(16) | Visa authorization code (6-char) issued by the issuer for the original auth. |
| 76 | HolderCurrencyCode | int | Numeric ISO of holder-account currency (paired with `HolderCurrencyAlpha`). |
| 77 | FxFeeCode | nvarchar(MAX) | Tribe-side FX fee code. |
| 78 | F0FeeCode | nvarchar(MAX) | Tribe-side F0 fee code. |
| 79 | ReconciliationDate | date | Visa-network reconciliation date for the settlement batch. |
| 80 | SettlementDate | date | Date funds settled between acquirer and issuer (Visa scheme). |
| 81 | MerchantNumber | nvarchar(MAX) | Visa-assigned merchant identifier (acquirer-side MID). |
| 82 | Merchant | nvarchar(MAX) | Merchant identifier (often duplicate of MerchantName or acquirer's merchant code). |
| 83 | MerchantName | nvarchar(MAX) | Merchant display name (raw, often padded with trailing spaces — e.g., 'SAINSBURYS S/MKTS         '). |
| 84 | MerchantAddress | nvarchar(MAX) | Merchant address line. |
| 85 | MerchantCity | nvarchar(MAX) | Merchant city. |
| 86 | MerchantPostcode | int | Merchant postal/ZIP code (numeric — note: not all postcodes fit; UK alphanumeric postcodes may be NULL/truncated here). |
| 87 | MerchantCountryCodeAlpha | nvarchar(MAX) | Alpha-3 ISO 3166 merchant country code (e.g., 'GBR', 'USA'). |
| 88 | MerchantCountryName | nvarchar(MAX) | Full merchant country name (e.g., 'United Kingdom'). |
| 89 | Mcc | int | Merchant Category Code (ISO 18245 4-digit; e.g., 5411 = Grocery, 5812 = Restaurants). |
| 90 | CardInputMode | int | POS terminal input mode code (chip, contactless, mag-stripe, manual, etc.). |
| 91 | CardholderAuthenticationMethod | nvarchar(MAX) | Cardholder authentication method label (PIN / Signature / 3DS / None). |
| 92 | PosDataDe22 | bigint | Visa Data Element 22 — POS data code (packed conditions: chip, PIN, etc.). |
| 93 | PosDataDe61 | bigint | Visa Data Element 61 — terminal capabilities. |
| 94 | AcquirerId | int | Acquirer institution identifier. |
| 95 | AcquirerReferenceNumber | nvarchar(MAX) | ARN — 23-character Visa Acquirer Reference Number (uniquely identifies a transaction across the lifecycle for chargeback/dispute). |
| 96 | InterchangeFeeAmount | float | Interchange fee amount (issuer-acquirer). |
| 97 | InterchangeFeeCurrency | int | Interchange fee currency (numeric ISO). |
| 98 | InterchangeFeeDirection | nvarchar(MAX) | Interchange direction ('IRF Issuer Pays' / 'IRF Issuer Receives'). |
| 99 | InterchangeRateDesignator | nvarchar(MAX) | Visa rate-designator code (IRD — e.g., 'Z3' for consumer signature credit). |
| 100 | CycleNumber | int | Visa settlement cycle number. |
| 101 | CycleFileId | nvarchar(MAX) | Visa settlement cycle file identifier. |
| 102 | ECIIndicator | int | Electronic Commerce Indicator (1=secure 3DS, 5=secure non-3DS, 7=non-secure CNP). |
| 103 | FunctionCode | int | Visa function code. |
| 104 | SettlementFlag | int | Settlement flag (0/1 indicating settled vs pending). |
| 105 | TransactionCodeQualifier | int | Visa Transaction Code Qualifier (TCQ). |
| 106 | BusinessFormatCode | nvarchar(MAX) | Visa Business Format Code (BFC) indicating business segment. |
| 107 | ParentTransactionId | nvarchar(MAX) | Parent transaction identifier (for refunds/chargebacks pointing to original purchase). |
| 108 | DisputeId | nvarchar(MAX) | Tribe-side dispute identifier (NULL for non-disputed transactions). |
| 109 | ExternalDisputeId | nvarchar(MAX) | External (Visa-network) dispute identifier. |
| 110 | ActualAuthorizationId | nvarchar(MAX) | Identifier linking to the original authorization (joins back to `ETL_AccountsActivities`). |
| 111 | FirstAuthorizationDate | datetime | Date/time of the original first authorization (for multi-clearing scenarios). |
| 112 | ChipData | bit | Bit flag — chip data present in the auth message. |
| 113 | Date | date | Calendar date of the transaction (DATE part of `TransactionDateTime`). Use for date-range filtering. |
| 114 | DateID | int | YYYYMMDD integer of `Date`. Joins to `DWH_dbo.Dim_Date.DateID`. |
| 115 | UpdateDate | datetime | Batch insert timestamp (`GETDATE()`). |
| 116 | Created | datetime | Tribe-side row creation timestamp. **Primary key for incremental load** (max(Created) drives the next-load watermark). |

---

## 5. Lineage

```
Visa / Mastercard scheme settlement files
  └─ Tribe (eMoney processor) settlements clearing
      └─ eMoney_Tribe.SettlementsTransactions-* (staging)
          └─ SP_eMoney_Reconciliation_ETLs (daily — section "Reconciliation Table 02")
              └─ SELECT DISTINCT ... DELETE+INSERT
                  └─ eMoney_dbo.ETL_SettlementsTransactions
                      └─ Generic Pipeline (Override, daily)
                          └─ bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions
```

### 5.1 Sibling / Related Tables

| Table | Relationship |
|-------|--------------|
| [`ETL_AccountsActivities`](ETL_AccountsActivities.md) | Sibling — broader account event log (cards + bank + EPM) |
| `eMoney_dbo.ETL_CardSnapshot` | Card status snapshot — joins on `CardNumberId` |
| [`eMoney_dbo.FiatAccount`](FiatAccount.md) | Holder/account dimension — `HolderId` → `Gcid` link to eToro customer |

---

## 6. Sample Queries

```sql
-- Top 20 merchants by spend (last 30 days)
SELECT
    MerchantName,
    MerchantCountryName,
    Mcc,
    COUNT(*) AS num_txns,
    SUM(ABS(TransactionAmount)) AS total_spend
FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions
WHERE Date >= current_date() - INTERVAL 30 DAYS
  AND TransactionAmount < 0
GROUP BY MerchantName, MerchantCountryName, Mcc
ORDER BY total_spend DESC
LIMIT 20;
```

```sql
-- MCC category spend breakdown
SELECT
    Mcc,
    COUNT(*) AS num_txns,
    SUM(ABS(TransactionAmount)) AS total_spend,
    COUNT(DISTINCT HolderId) AS unique_cardholders
FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions
WHERE Date >= '2026-04-01'
  AND TransactionAmount < 0
GROUP BY Mcc
ORDER BY total_spend DESC;
```

```sql
-- Cross-border spend rate per program
SELECT
    ProgramName,
    SUM(CASE WHEN MerchantCountryCodeAlpha != 'GBR' THEN ABS(TransactionAmount) ELSE 0 END) AS cross_border_spend,
    SUM(ABS(TransactionAmount)) AS total_spend,
    SUM(CASE WHEN MerchantCountryCodeAlpha != 'GBR' THEN ABS(TransactionAmount) ELSE 0 END) / NULLIF(SUM(ABS(TransactionAmount)), 0) AS cross_border_rate
FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions
WHERE Date >= current_date() - INTERVAL 30 DAYS
  AND TransactionAmount < 0
GROUP BY ProgramName;
```

---

*Generated as part of Wave 2 medium-priority documentation effort. Sibling: [`ETL_AccountsActivities`](ETL_AccountsActivities.md).*
