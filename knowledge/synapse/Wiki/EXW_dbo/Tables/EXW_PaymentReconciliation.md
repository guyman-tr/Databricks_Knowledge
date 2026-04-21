# EXW_dbo.EXW_PaymentReconciliation

> 99,243-row reconciliation table for Simplex fiat-to-crypto payments, covering 2020-01-29 to 2022-09-20 — one row per payment at final status. Joins WalletDB payment records (16 T1 columns from Wallet.Payments, PaymentTransactions, PaymentStatuses) with EXW_SimplexMapping (Simplex provider data — 38,044 matched) and EXW_ECPBank (bank settlement — 20,944 matched). Complements EXW_FactPayments (accumulating snapshot) by providing a single current-state row per payment with full cross-source reconciliation. Table is frozen as Simplex was decommissioned September 2022.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.Payments + PaymentTransactions + PaymentStatuses + EXW_SimplexMapping + EXW_ECPBank |
| **Refresh** | Frozen — last data 2022-09-20 (Simplex decommissioned); UpdateDate max 2022-09-21 |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_PaymentReconciliation is the definitive cross-source reconciliation record for Simplex fiat-to-crypto payments on the eToro Wallet platform. Unlike EXW_FactPayments (which stores one row per payment × status event — 553K rows), this table stores **one row per payment at its final status**, making it the go-to table for payment-level analysis and financial reconciliation.

The table spans three data sources:
1. **WalletDB** (always present) — 16 T1 columns from Wallet.Payments, PaymentTransactions, and PaymentStatuses; same columns as EXW_FactPayments
2. **EXW_SimplexMapping** (LEFT JOIN via UTI/CorrelationID) — 5 Simplex-sourced columns; populated for 38,044 of 99,243 payments (38%) — those that reached the Simplex API layer
3. **EXW_ECPBank** (LEFT JOIN via UTI) — 9 ECP Bank settlement columns; populated for 20,944 payments (21%) — those that were settled by the ECP Bank acquirer

The 99,243 payments break into three reconciliation tiers:
- **61,199 (62%)** — WalletDB only: payment request reached WalletDB but was never submitted to Simplex (mostly Failed early)
- **17,100 (17%)** — WalletDB + Simplex: reached Simplex processing but no ECP Bank settlement record
- **20,944 (21%)** — All three sources matched: fully reconciled payments with WalletDB + Simplex + ECP Bank data

Payment status breakdown: Failed 73.2%, Completed 21.7%, InitiateCompleted 5.0%, PendingTransaction 0.1%, ProviderSubmitted 0.04%. Fiat: EUR (68%), GBP (32%) — derived from SimplexCurr for matched payments.

Note: EXW_FactPayments has 99,410 distinct PaymentIDs vs 99,243 here — 167-payment gap, likely due to pipeline timing or exclusion of test entries at reconciliation time.

---

## 2. Business Logic

### 2.1 Final-Status Grain (vs EXW_FactPayments Accumulating Snapshot)

**What**: This table stores one row per PaymentID at the payment's final/current status — NOT one row per status event.  
**Columns Involved**: PaymentID, PaymentStatus, ModificationDate  
**Rules**:
- To get successful payments: `WHERE PaymentStatus = 'Completed'`
- No deduplication needed — grain is already one row per payment
- ModificationDate = timestamp of the final status event for each payment
- 5 PaymentStatus values present: Failed, Completed, InitiateCompleted, PendingTransaction, ProviderSubmitted

### 2.2 Reconciliation Coverage Tiers

**What**: Simplex and ECP columns are NULL for payments that never reached those systems.  
**Columns Involved**: SimplexCurr, ECPPostDate, UTI  
**Rules**:
- `SimplexCurr IS NOT NULL` → payment reached Simplex (38,044 payments)
- `ECPPostDate IS NOT NULL` → payment was settled through ECP Bank (20,944 payments) — a subset of Simplex-matched payments
- `UTI IS NOT NULL` → cross-reference key present (21,038 payments); bridges EXW_SimplexMapping.long_id ↔ EXW_ECPBank.uti ↔ EXW_ECPBank.merch_tran_ref_
- All ECP-matched payments also have Simplex data (ECPPostDate IS NOT NULL → SimplexCurr IS NOT NULL)

### 2.3 ECP Financial Columns

**What**: ECP Bank settlement amounts for matched purchases.  
**Columns Involved**: ECPAmout, ECPCommission, ECPNetAmount, ECPAdditionalCharge  
**Rules**:
- `ECPNetAmount = ECPAmout - ECPCommission - ECPAdditionalCharge`
- ECPType is always "Purchase" in this table (no refunds); ECPStatus is "Cleared" (99.9%) or "Processed"
- **Column name typo**: `ECPAmout` (missing 'n') matches the DDL — use exactly this name in all queries
- ECPTranDate may be NULL for post-2020 records (same behavior as EXW_ECPBank.transaction_date); ECPPostDate is always present when ECP data exists

### 2.4 Card BIN Enrichment

**What**: Card-level geography and bank attributes derived from the payment card BIN.  
**Columns Involved**: bin_country, bank_name, last_4_digits  
**Rules**:
- bin_country = ISO country code of the card-issuing bank (top values: GB, DE, FR, IT, ES); "Unknown" for 56% of BIN-enriched records
- bank_name = issuing bank name from BIN lookup
- last_4_digits stored as numeric(18,0); card-level identifier

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) distribution with HEAP. One row per payment — no deduplication required. JOINs to EXW_FactPayments, EXW_DimUser_Enriched, and EXW_FactBalance (all HASH(GCID)) benefit from data locality without shuffle. HEAP allows fast bulk loads.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Successful payment revenue | `WHERE PaymentStatus = 'Completed' GROUP BY GCID, SUM(AmountInFiat)` |
| Payments with ECP settlement | `WHERE ECPPostDate IS NOT NULL` |
| Payments without Simplex match | `WHERE SimplexCurr IS NULL` — mostly Failed payments |
| Full cross-source reconciliation | No JOIN needed — all three sources are pre-joined here |
| Completed payments with fees | `WHERE PaymentStatus = 'Completed' AND ECPNetAmount IS NOT NULL` |
| Compare estimated vs actual fees | `EstimatedBlockChainFee vs BlockChainFee` (NULLs for non-executed rows) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_FactPayments | `EXW_FactPayments.PaymentID = PaymentID` | Full payment event history (all status events) |
| EXW_dbo.EXW_DimUser_Enriched | `EXW_DimUser_Enriched.GCID = GCID` | Add customer demographics |
| EXW_dbo.EXW_SimplexMapping | `EXW_SimplexMapping.long_id = UTI` | Additional Simplex fields not in reconciliation |
| EXW_dbo.EXW_ECPBank | `EXW_ECPBank.uti = UTI` | Additional ECP fields beyond what is joined here |
| EXW_dbo.EXW_SimplexChargebacks | `EXW_SimplexChargebacks.ARN = EXW_ECPBank.acquirer_ref_` | Chargeback investigation via ARN chain |

### 3.4 Gotchas

- **ECPAmout typo** — Column is `ECPAmout` (not `ECPAmount`); use exactly this spelling in all SQL
- **ECPTranDate can be NULL** — only ECPPostDate is reliable for post-2020 ECP records
- **One row per payment** — no deduplication needed; contrast with EXW_FactPayments
- **Crypto execution columns NULL when SimplexCurr IS NULL** — payments that failed before Simplex processing never have exchange rate, addresses, or crypto amounts
- **bin_country = "Unknown" is the majority** — do not treat as a reliable geography source; 11,799 / 20,944 ECP-matched records have "Unknown" BIN country
- **GCID = RealCID cardinality** — both have 29,775 distinct values; verify which identifier is used in downstream joins
- **167-payment gap vs EXW_FactPayments** — do not assume perfect 1:1 coverage; some payments in FactPayments may be absent here

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki (WalletDB) |
| Tier 2 | Derived from ETL logic or join enrichment analysis |
| Tier 3 | Inferred from column name, type, and data samples |
| Tier 4 | Best-available inference — no upstream wiki match |
| Tier 5 | Placeholder — domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PaymentID | bigint | YES | Auto-incrementing primary key. FK target for Wallet.PaymentStatuses, Wallet.PaymentTransactions, and Wallet.Chargebacks. Passthrough from Wallet.Payments.Id. (Tier 1 — Wallet.Payments) |
| 2 | ProviderPaymentID | nvarchar(max) | YES | Payment identifier assigned by the external payment provider. Used for reconciliation and provider API calls. Links to EXW_SimplexMapping.long_id and EXW_ECPBank.uti. (Tier 1 — Wallet.Payments) |
| 3 | WalletID | nvarchar(max) | YES | The customer's wallet receiving the purchased crypto. FK to Wallet.Wallets.WalletId. (Tier 1 — Wallet.Payments) |
| 4 | AmountInFiat | numeric(38,8) | YES | Fiat amount of the payment. Denominated in the currency specified by FiatId (e.g., 125 EUR). Passthrough from Wallet.Payments.Amount. (Tier 1 — Wallet.Payments) |
| 5 | FiatID | int | YES | The fiat currency used for payment: 1=USD, 2=EUR, 3=GBP, 5=AUD. FK to Wallet.FiatTypes.Id. (Tier 1 — Wallet.Payments) |
| 6 | CorrelationID | nvarchar(max) | YES | Links to the parent request in Wallet.Requests.CorrelationId. (Tier 1 — Wallet.Payments) |
| 7 | RequestDate | datetime | YES | Timestamp when the payment was initiated. Passthrough from Wallet.Payments.Occurred. Primary date for payment filtering; see also RequestDateID. (Tier 1 — Wallet.Payments) |
| 8 | ModificationDate | datetime | YES | Timestamp of the payment's final status event. Passthrough from Wallet.PaymentStatuses.Occurred for the last status row per payment. Note: in EXW_FactPayments this is any status event; here it is always the final status. (Tier 1 — Wallet.PaymentStatuses) |
| 9 | ExchangeRate | numeric(38,8) | YES | Fiat-to-crypto exchange rate at execution time. Used to convert the fiat Amount to crypto. NULL for payments that never reached execution (SimplexCurr IS NULL). (Tier 1 — Wallet.PaymentTransactions) |
| 10 | ToAddress | nvarchar(512) | YES | Blockchain destination address for the purchased crypto. NULL for non-executed payments. (Tier 1 — Wallet.PaymentTransactions) |
| 11 | AmountInCrypto | numeric(38,8) | YES | Amount of crypto being purchased/transferred. Passthrough from Wallet.PaymentTransactions.Amount. NULL for non-executed payments. (Tier 1 — Wallet.PaymentTransactions) |
| 12 | EtoroFeePercentage | numeric(38,8) | YES | eToro service fee as a percentage. NULL for non-executed payments. (Tier 1 — Wallet.PaymentTransactions) |
| 13 | EtoroFeeCalculated | numeric(38,8) | YES | Calculated eToro fee in crypto units. NULL for non-executed payments. (Tier 1 — Wallet.PaymentTransactions) |
| 14 | ProviderFeeCalculated | numeric(38,8) | YES | Calculated provider fee in crypto units. NULL for non-executed payments. (Tier 1 — Wallet.PaymentTransactions) |
| 15 | EstimatedBlockChainFee | numeric(38,8) | YES | Estimated blockchain network fee. Estimated at order time; compare with BlockChainFee for actual. NULL for non-executed payments. (Tier 1 — Wallet.PaymentTransactions) |
| 16 | FiatName | varchar(50) | YES | Fiat currency name, denormalized from Wallet.FiatTypes via FiatID. Values: EUR, GBP. (Tier 2 — ETL join enrichment) |
| 17 | CryptoId | int | YES | The cryptocurrency being purchased. FK to Wallet.CryptoTypes.CryptoID. (Tier 1 — Wallet.Payments) |
| 18 | CryptoName | varchar(50) | YES | Cryptocurrency name, denormalized from Wallet.CryptoTypes via CryptoId. Values: BTC, ETH, LTC, XLM, XRP, BCH. (Tier 2 — ETL join enrichment) |
| 19 | SentTransactionID | bigint | YES | Internal identifier for the sent blockchain transaction. Links to WalletDB transaction tables. NULL for non-executed payments. (Tier 2 — WalletDB transaction tables) |
| 20 | ReceivedTransactionID | bigint | YES | Internal identifier for the received blockchain transaction. NULL for non-executed payments. (Tier 2 — WalletDB transaction tables) |
| 21 | BlockchainTransactionId | nvarchar(max) | YES | Blockchain transaction hash (hex string) for the executed crypto transfer. NULL for non-executed payments. (Tier 2 — WalletDB transaction tables) |
| 22 | PaymentStatus | varchar(50) | YES | Final payment status. Values observed: Failed (73.2%), Completed (21.7%), InitiateCompleted (5.0%), PendingTransaction (0.1%), ProviderSubmitted (0.04%). Unlike EXW_FactPayments, this represents the most recent status per payment. (Tier 2 — Dictionary.PaymentStatuses via ETL join) |
| 23 | GCID | int | YES | Global Customer ID of the wallet owner. Distribution key. Derived via Wallet.Wallets → customer mapping. Links to EXW_DimUser_Enriched.GCID. (Tier 2 — WalletDB wallet-customer mapping) |
| 24 | RealCID | int | YES | eToro platform ClientID mapped from GCID. Same cardinality as GCID (29,775 distinct values). Used for joining to eToro core system tables keyed on CID rather than GCID. (Tier 4 — eToro CID mapping) |
| 25 | BlockChainFee | numeric(38,8) | YES | Actual blockchain network fee paid at execution, as opposed to EstimatedBlockChainFee. NULL for non-executed payments. (Tier 2 — WalletDB transaction tables) |
| 26 | SimplexCurr | varchar(50) | YES | Fiat currency as recorded by Simplex (EUR or GBP). From EXW_SimplexMapping.fiat_currency. NULL for 61,199 payments with no Simplex match. (Tier 4 — EXW_SimplexMapping) |
| 27 | SimplexAmountCurr | numeric(38,8) | YES | Fiat amount requested from Simplex, in SimplexCurr. From EXW_SimplexMapping.requested_fiat_amount. NULL when SimplexCurr IS NULL. (Tier 4 — EXW_SimplexMapping) |
| 28 | SimplexProcessTime | datetime | YES | Timestamp when Simplex processed the payment. From EXW_SimplexMapping.timestamp_created. NULL when SimplexCurr IS NULL. (Tier 4 — EXW_SimplexMapping) |
| 29 | SimplexAmountUSD | numeric(38,8) | YES | Fiat amount normalized to USD. Derived from SimplexAmountCurr via FX rate or Simplex-provided USD equivalent. NULL when SimplexCurr IS NULL. (Tier 4 — EXW_SimplexMapping or ETL derived) |
| 30 | ECPTranDate | datetime | YES | Card authorization date from ECP Bank, converted from YYYYMMDD bigint to datetime. NULL for post-2020 records and non-ECP payments. (Tier 4 — EXW_ECPBank.transaction_date) |
| 31 | ECPPostDate | datetime | YES | Settlement posting date from ECP Bank, converted from YYYYMMDD bigint to datetime. Reliable for all ECP-matched payments. NULL when no ECP match. (Tier 4 — EXW_ECPBank.posting_date) |
| 32 | ECPType | varchar(50) | YES | Transaction type from ECP Bank. Always "Purchase" in this table. NULL when no ECP match. (Tier 4 — EXW_ECPBank.type) |
| 33 | Card | nvarchar(max) | YES | Masked card number from ECP Bank (format: ************1234 or *1234). NULL when no ECP match. (Tier 4 — EXW_ECPBank.card_no_) |
| 34 | ECPStatus | varchar(50) | YES | Settlement status from ECP Bank. Values: Cleared (99.9%), Processed. NULL when no ECP match. (Tier 4 — EXW_ECPBank.status) |
| 35 | ECPAmout | numeric(38,8) | YES | Gross settlement amount from ECP Bank before commission deduction. Note: column name is intentionally "ECPAmout" (typo in DDL — missing 'n'). NULL when no ECP match. (Tier 4 — EXW_ECPBank.acct_amount_gross) |
| 36 | ECPCommission | numeric(38,8) | YES | Commission fee charged by ECP Bank at settlement. ECPNetAmount = ECPAmout - ECPCommission - ECPAdditionalCharge. NULL when no ECP match. (Tier 4 — EXW_ECPBank.acct_commission_charges) |
| 37 | ECPNetAmount | numeric(38,8) | YES | Net settlement amount received from ECP Bank after fees. ECPNetAmount = ECPAmout - ECPCommission - ECPAdditionalCharge. NULL when no ECP match. (Tier 4 — EXW_ECPBank.acct_amount_net) |
| 38 | ECPAdditionalCharge | numeric(38,8) | YES | Additional charges beyond commission from ECP Bank. NULL when no ECP match. (Tier 4 — EXW_ECPBank.additional_charges) |
| 39 | UpdateDate | datetime | YES | ETL-managed load timestamp. Not a business date. Max = 2022-09-21. (Tier 2 — ETL) |
| 40 | RequestDateID | int | YES | Date integer key (YYYYMMDD) derived from RequestDate. For date dimension joins. (Tier 2 — ETL) |
| 41 | bin_country | nvarchar(256) | YES | ISO country code of card-issuing bank from BIN lookup. Top values: Unknown (56%), GB (13%), DE (4%), FR (4%). NULL for non-ECP payments. (Tier 4 — BIN lookup) |
| 42 | bank_name | nvarchar(256) | YES | Issuing bank name from BIN lookup. NULL for non-ECP payments and when BIN is unknown. (Tier 4 — BIN lookup) |
| 43 | UTI | varchar(255) | YES | Unique Transaction Identifier. Cross-reference key linking EXW_SimplexMapping.long_id, EXW_ECPBank.uti, and EXW_ECPBank.merch_tran_ref_. Present for 21,038 payments. (Tier 4 — EXW_SimplexMapping.long_id) |
| 44 | last_4_digits | numeric(18,0) | YES | Last 4 digits of the payment card as a numeric. Extracted from masked card number. NULL when no ECP match. (Tier 4 — ECP/Simplex card data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| PaymentID | Wallet.Payments | Id | Renamed |
| ProviderPaymentID, WalletID, AmountInFiat, FiatID, CorrelationID, RequestDate, CryptoId | Wallet.Payments | ProviderPaymentId, WalletId, Amount, FiatId, CorrelationId, Occurred, CryptoId | Passthrough (rename) |
| ModificationDate | Wallet.PaymentStatuses | Occurred | Final status event only |
| ExchangeRate, ToAddress, AmountInCrypto, EtoroFeePercentage, EtoroFeeCalculated, ProviderFeeCalculated, EstimatedBlockChainFee | Wallet.PaymentTransactions | same names (Amount→AmountInCrypto) | Passthrough |
| FiatName | Wallet.FiatTypes | FiatName | Denormalized join via FiatID |
| CryptoName | Wallet.CryptoTypes | Name | Denormalized join via CryptoId |
| PaymentStatus | Dictionary.PaymentStatuses | Name | Final status via PaymentStatusId |
| GCID, SentTransactionID, ReceivedTransactionID, BlockchainTransactionId, BlockChainFee | WalletDB various tables | — | ETL-derived |
| RealCID | eToro CID mapping | ClientId | GCID → ClientID mapping |
| SimplexCurr, SimplexAmountCurr, SimplexProcessTime, SimplexAmountUSD | EXW_dbo.EXW_SimplexMapping | fiat_currency, requested_fiat_amount, timestamp_created, derived | LEFT JOIN via CorrelationID/UTI |
| ECPTranDate, ECPPostDate, ECPType, Card, ECPStatus, ECPAmout, ECPCommission, ECPNetAmount, ECPAdditionalCharge | EXW_dbo.EXW_ECPBank | transaction_date, posting_date, type, card_no_, status, acct_amount_gross, acct_commission_charges, acct_amount_net, additional_charges | LEFT JOIN via UTI (datetime conversion for dates) |
| bin_country, bank_name, last_4_digits, UTI | BIN lookup / EXW_SimplexMapping | derived | BIN enrichment + cross-reference key |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.Payments (~99K payments)
  + WalletDB.Wallet.PaymentStatuses (final status per payment)
  + WalletDB.Wallet.PaymentTransactions (execution details)
  + WalletDB.Wallet.FiatTypes / CryptoTypes (name lookups)
  + WalletDB.Wallet.Wallets → GCID + RealCID mapping
  |
  LEFT JOIN ON CorrelationID / UTI
  |
EXW_dbo.EXW_SimplexMapping (38,044 matched)
  |
  LEFT JOIN ON UTI
  |
EXW_dbo.EXW_ECPBank (20,944 matched)
  |-- External pipeline (no SSDT SP found) ---|
  v
EXW_dbo.EXW_PaymentReconciliation (99,243 rows, HASH(GCID), HEAP)
  |-- Data frozen 2022-09-20 — Simplex decommissioned ---|
  v
No UC Generic Pipeline mapping (_Not_Migrated)
```

---

## 6. Data Samples (Phase 2 — Live)

| Metric | Value |
|--------|-------|
| Total rows | 99,243 |
| Distinct PaymentIDs | 99,243 (1:1 — one row per payment) |
| Distinct GCIDs | 29,775 |
| Distinct RealCIDs | 29,775 |
| Date range (RequestDate) | 2020-01-29 to 2022-09-20 |
| Payments with Simplex data | 38,044 (38.3%) |
| Payments with ECP data | 20,944 (21.1%) |
| Payments with UTI | 21,038 (21.2%) |
| WalletDB-only (no Simplex/ECP) | 61,199 (61.7%) |

| PaymentStatus | Count | % |
|---------------|-------|---|
| Failed | 72,624 | 73.2% |
| Completed | 21,540 | 21.7% |
| InitiateCompleted | 4,981 | 5.0% |
| PendingTransaction | 57 | 0.1% |
| ProviderSubmitted | 41 | 0.0% |

| SimplexCurr | Count |
|-------------|-------|
| EUR | 25,477 |
| GBP | 12,567 |

| ECPType × ECPStatus | Count |
|--------------------|-------|
| Purchase × Cleared | 20,919 |
| Purchase × Processed | 25 |

---

## 7. Cross-Object Notes

- **EXW_FactPayments** — Accumulating snapshot (553K rows); same 16 T1 WalletDB columns. Use for full payment event history; use EXW_PaymentReconciliation for current-state analysis
- **EXW_SimplexMapping** — Source for SimplexCurr, SimplexAmountCurr, SimplexProcessTime, SimplexAmountUSD columns; join via UTI = EXW_SimplexMapping.long_id
- **EXW_ECPBank** — Source for all ECP* columns; join via UTI = EXW_ECPBank.uti; 167-row more coverage in this table vs EXW_ECPBank (113K rows total in ECPBank, many are non-Simplex)
- **EXW_SimplexChargebacks** — Dispute tracking; join via EXW_SimplexChargebacks.ARN ↔ EXW_ECPBank.acquirer_ref_ for chargeback investigation

---

## 8. UC Migration

No UC Generic Pipeline mapping found in `bronze_opsdb_dbo_vw_unitycatalog_mapping_tables`. Status: `_Not_Migrated`.

Reason: Table is frozen (Simplex decommissioned 2022-09-20). Historical data only. No active migration planned.

---

*Generated: 2026-04-20 | Quality: 8.9/10 | Phases: 13/14*  
*Tiers: 16 T1, 10 T2, 0 T3, 18 T4, 0 T5 | Elements: 44/44, Logic: 4/10, Data Evidence: P2+P3 PASS*  
*Object: EXW_dbo.EXW_PaymentReconciliation | Type: Table | Production Source: WalletDB + EXW_SimplexMapping + EXW_ECPBank*
