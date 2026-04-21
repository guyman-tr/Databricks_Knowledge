# EXW_dbo.EXW_ECPBank

> 113,146-row ECP Bank card settlement report for Simplex-processed eToro Wallet crypto purchases, covering 2019-02-01 to 2022-09-20 (posting dates) — each row represents one settled card transaction with full acquirer details including ARN, UTI, commission breakdown, capture method, and geographic classification. Loaded via Fivetran from ECP Bank's merchant settlement system; table is frozen as Simplex was decommissioned in 2022.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | ECP Bank merchant settlement report (external acquirer, loaded via Fivetran) |
| **Refresh** | Frozen — last sync 2024-04-09; data stops 2022-09-20 (Simplex decommissioned) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_ECPBank stores ECP Bank's card settlement records for all Simplex-facilitated crypto purchases on eToro Wallet. ECP Bank was the acquiring bank (payment processor) that sat between Simplex and the card networks (Visa/Mastercard), handling the actual card charging and settlement for the eToro Gibraltar merchant account (merchant_no_ = 172000000006524 / "Simplex_etorox").

Each row represents one settled card transaction: 99.9% are purchases, with 25 credit refunds. Settlement currencies are GBP (46%) and EUR (54%). The `uti` field matches back to `EXW_SimplexMapping.uti` for approved transactions, and `acquirer_ref_` (the ARN) matches `EXW_SimplexChargebacks.ARN` for chargeback dispute tracing.

The table contains 113,146 rows covering posting dates 20190201 to 20220920. It was loaded via Fivetran (evidenced by `_row`, `_fivetran_deleted`, `_fivetran_synced` columns) and is frozen since Simplex was decommissioned as eToro Wallet's primary card-buy provider in late 2022. The `_fivetran_deleted = True` rows represent records that were deleted in the ECP Bank source but are retained in Synapse per Fivetran's soft-delete behavior.

Key financial columns: `acct_amount_gross` (pre-fee amount), `acct_commission_charges` (ECP's fee), `acct_amount_net` (gross - commission), `acct_assessed_intchg_amount` (card network interchange fee).

---

## 2. Business Logic

### 2.1 Settlement Amount Breakdown

**What**: Three financial columns capture the settlement economics per transaction.  
**Columns Involved**: acct_amount_gross, acct_commission_charges, acct_amount_net, acct_assessed_intchg_amount  
**Rules**:
- `acct_amount_net = acct_amount_gross - acct_commission_charges`
- `acct_commission_charges` = ECP Bank's acquiring commission (processing fee)
- `acct_assessed_intchg_amount` = interchange fee charged by the card network (Visa/Mastercard), separate from ECP's commission
- `additional_charges` = any charges beyond the standard commission (rare/small amounts)

### 2.2 Date Encoding — Bigint YYYYMMDD

**What**: Both date columns are stored as bigint in YYYYMMDD integer format, not as SQL dates.  
**Columns Involved**: transaction_date, posting_date  
**Rules**:
- `posting_date` = always populated; format: 20190201 to 20220920
- `transaction_date` = authorization date; populated for 2019-2020 records; EMPTY (NULL) for newer records
- Convert to date: `DATEFROMPARTS(transaction_date / 10000, (transaction_date % 10000) / 100, transaction_date % 100)`

### 2.3 Fivetran Metadata Columns

**What**: Three columns are Fivetran-specific, not from ECP Bank data.  
**Columns Involved**: _row, _fivetran_deleted, _fivetran_synced  
**Rules**:
- `_row`: Fivetran's synthetic sequential PK — use for deduplication
- `_fivetran_deleted = True`: Record was deleted in ECP Bank's source system; keep these rows out of financial aggregations
- `_fivetran_synced`: Timestamp when Fivetran last synced this record; use for incremental tracking, NOT as a business date

### 2.4 UTI Cross-Reference Chain

**What**: The `uti` field is the link between ECP Bank settlement and Simplex transaction tracking.  
**Columns Involved**: uti, merch_tran_ref_, acquirer_ref_  
**Rules**:
- `uti` = 32-char hex UTI (same format as EXW_SimplexMapping.uti for approved transactions)
- `merch_tran_ref_` = first 15 characters of the UTI (truncated merchant reference)
- `acquirer_ref_` = 23-digit ARN assigned by the card network (same value as EXW_SimplexChargebacks.ARN)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CCI — table has no natural distribution key (uti is a hash string). CCI enables fast analytical scans. For joins with EXW_SimplexMapping on `uti`, Synapse will perform a shuffle-based join; small enough (113K rows) that this is acceptable.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total net settlement by month | `GROUP BY LEFT(CAST(posting_date AS varchar), 6), SUM(acct_amount_net)` |
| Join to Simplex mapping | `JOIN EXW_SimplexMapping ON EXW_SimplexMapping.uti = EXW_ECPBank.uti` |
| Active transactions only (exclude soft-deletes) | `WHERE _fivetran_deleted = 0` or `_fivetran_deleted = 'False'` |
| Interchange cost by card network | `GROUP BY acquirer_bin_ica` (453760=Visa, 14206=Mastercard) |
| Link chargebacks to settlements | `JOIN EXW_SimplexChargebacks ON ARN = acquirer_ref_` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_SimplexMapping | `EXW_SimplexMapping.uti = EXW_ECPBank.uti` | Match settlement to Simplex transaction |
| EXW_dbo.EXW_PaymentReconciliation | `EXW_PaymentReconciliation.UTI = EXW_ECPBank.uti` | Full payment reconciliation |
| EXW_dbo.EXW_SimplexChargebacks | `EXW_SimplexChargebacks.ARN = EXW_ECPBank.acquirer_ref_` | Cross-reference chargebacks |

### 3.4 Gotchas

- **transaction_date is bigint YYYYMMDD** — empty for post-2019 records; use `posting_date` for date-based filtering
- **_fivetran_deleted = 'True'/'False' (bit stored as nvarchar-like)** — filter `WHERE _fivetran_deleted = 0` to exclude soft-deletes from aggregations
- **merchant_no_ formatting inconsistency** — 3 variants (172000000006524, 1720000000006524, 172000000000000) all refer to the same Gibraltar merchant; do not GROUP BY this column
- **trans_curr and trans_amount empty for newer records** — settlement currency (acct_curr) is always present; transaction currency is not
- **merch_tran_ref_ is a 15-char UTI prefix** — not the full UTI; join on `uti` column instead
- **internal_batch_no_ stored as float** — pattern YYYYMMDDBATCH.0; not directly castable to date

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki |
| Tier 2 | Derived from SP/ETL code analysis |
| Tier 3 | Inferred from column name, type, and data samples |
| Tier 4 | Best-available inference — no upstream wiki, external acquirer data |
| Tier 5 | Placeholder — domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | _row | bigint | NO | Fivetran-generated sequential row identifier. Synthetic PK for Fivetran-managed records. Not from ECP Bank source data. (Tier 2 — Fivetran ETL) |
| 2 | _fivetran_deleted | bit | YES | Fivetran soft-delete flag. True = record deleted in ECP Bank source but retained in Synapse. Exclude `_fivetran_deleted = True` rows from financial aggregations. (Tier 2 — Fivetran ETL) |
| 3 | merchant_no_ | bigint | YES | ECP Bank merchant account number. Primarily 172000000006524 (eToro Gibraltar Simplex merchant). Three formatting variants exist due to ECP Bank export inconsistency; all represent the same merchant. (Tier 4 — ECP Bank) |
| 4 | batch_no_ | nvarchar(256) | YES | ECP Bank settlement batch identifier. Value: "eMP" for all standard records; some null rows show "eMP" in merchant_name position due to data shift. (Tier 4 — ECP Bank) |
| 5 | transaction_date | bigint | YES | Original card authorization date in YYYYMMDD bigint format. Populated for 2019-2020 records only; NULL for newer records. Use `posting_date` for reliable date filtering. Convert: `DATEFROMPARTS(transaction_date/10000, (transaction_date%10000)/100, transaction_date%100)`. (Tier 4 — ECP Bank) |
| 6 | posting_date | bigint | YES | Settlement/posting date in YYYYMMDD bigint format. Always populated. Range: 20190201 to 20220920. Primary date column for this table. (Tier 4 — ECP Bank) |
| 7 | type | nvarchar(256) | YES | Transaction type. Values: Purchase, Refund (Credit). Empty for ~48 records with missing data. (Tier 4 — ECP Bank) |
| 8 | card_no_ | nvarchar(256) | YES | Masked card number. Older records: "************1234" (12 stars + last 4); newer records: "*1234" (star + last 4). PCI-compliant masking. (Tier 4 — ECP Bank) |
| 9 | uti | nvarchar(256) | YES | Unique Transaction Identifier (UTI) — 32-char hex string with "0000" suffix. Links to EXW_SimplexMapping.uti (approved transactions) and EXW_PaymentReconciliation.UTI. Primary cross-reference key. (Tier 4 — ECP Bank) |
| 10 | status | nvarchar(256) | YES | Settlement status. Values: Cleared (99.9% = fully settled), Processed (in-process), empty (missing data). (Tier 4 — ECP Bank) |
| 11 | trans_curr | nvarchar(256) | YES | Transaction currency code (card charge currency). Populated for 2019-2020 records (GBP or EUR); NULL for newer records. (Tier 4 — ECP Bank) |
| 12 | acct_curr | nvarchar(256) | YES | Account/settlement currency code. Always populated. Values: GBP or EUR. (Tier 4 — ECP Bank) |
| 13 | acct_commission_charges | float | YES | ECP Bank's acquiring commission fee deducted at settlement, in account currency. Calculated as a percentage of the gross amount. (Tier 4 — ECP Bank) |
| 14 | acct_amount_net | float | YES | Net settlement amount in account currency after deducting ECP commission: `acct_amount_gross - acct_commission_charges`. Amount actually credited to Simplex/eToro. (Tier 4 — ECP Bank) |
| 15 | capture_method | nvarchar(256) | YES | Card capture authentication method. Common values: "SET/3D-SET authenticated" (3DS), "eCommerce Channel Encrypt" (standard eCommerce), "eCommerce Channel Encrypt( UCAF 2 )" (Mastercard SecureCode). (Tier 4 — ECP Bank) |
| 16 | merch_tran_ref_ | nvarchar(256) | YES | Merchant transaction reference — first 15 characters of the UTI. Partial match for UTI lookup; use `uti` column for full joins. (Tier 4 — ECP Bank) |
| 17 | acquirer_ref_ | nvarchar(256) | YES | Acquirer Reference Number (ARN) — 23-digit unique settlement reference assigned by the card network. Used for chargeback dispute tracing. Matches EXW_SimplexChargebacks.ARN. (Tier 4 — ECP Bank) |
| 18 | merchant_name | nvarchar(256) | YES | ECP Bank merchant account name. Value: "Simplex_etorox" (the profile name for the Gibraltar eToro Simplex merchant account). (Tier 4 — ECP Bank) |
| 19 | transaction_country | nvarchar(256) | YES | ECP Bank merchant country registration. Value: "Gibraltar" (eToro's entity jurisdiction for this merchant account). (Tier 4 — ECP Bank) |
| 20 | acquirer_bin_ica | bigint | YES | Acquiring bank's BIN/ICA code. Values: 453760 (Visa acquirer), 14206 (Mastercard acquirer). Identifies the card network processor. (Tier 4 — ECP Bank) |
| 21 | area_of_event | nvarchar(256) | YES | Geographic classification of the transaction based on cardholder vs. merchant country. Values: Domestic - UK, Foreign - REST, Foreign - EMEA, Foreign EEA-UK, Foreign-EEAIntra, etc. Used for interchange rate calculation. (Tier 4 — ECP Bank) |
| 22 | fpi | nvarchar(256) | YES | FPI (Funding/Product Indicator) code — 3-char bank classification code used in card scheme interchange calculations. Identifies card product type and funding source. (Tier 4 — ECP Bank) |
| 23 | acct_assessed_intchg_amount | float | YES | Interchange fee assessed by the card network (Visa/Mastercard) on this transaction, in account currency. Separate from ECP commission. (Tier 4 — ECP Bank) |
| 24 | expiry_date | bigint | YES | Card expiry date in YYYYMM bigint format. Mostly empty (populated for older 2019-2020 records only). (Tier 4 — ECP Bank) |
| 25 | cross_rate | bigint | YES | Exchange rate used for cross-currency settlement when trans_curr ≠ acct_curr. Populated for cross-currency transactions; empty for same-currency. (Tier 4 — ECP Bank) |
| 26 | additional_charges | float | YES | Additional charges beyond standard commission. Small amounts when applicable; NULL/0 for most transactions. (Tier 4 — ECP Bank) |
| 27 | _fivetran_synced | datetime2(7) | YES | Fivetran sync timestamp — when this record was last processed by Fivetran. Not a business date. Use for ETL freshness monitoring. (Tier 2 — Fivetran ETL) |
| 28 | internal_batch_no_ | float | YES | ECP Bank's internal batch tracking number, stored as float in YYYYMMDDBATCH.0 format (e.g., 91300000000.0 = batch 913 on some date). (Tier 4 — ECP Bank) |
| 29 | auth_code | nvarchar(256) | YES | Card authorization approval code assigned by the issuing bank. 4-6 digit code returned at time of authorization. (Tier 4 — ECP Bank) |
| 30 | acct_amount_gross | float | YES | Gross settlement amount in account currency before ECP commission deduction. The card charge amount converted to settlement currency. (Tier 4 — ECP Bank) |
| 31 | trans_amount | float | YES | Transaction amount in transaction currency (trans_curr). NULL for newer records where trans_curr is also absent. (Tier 4 — ECP Bank) |
| 32 | UpdateDate | datetime | YES | ETL-managed timestamp of last Synapse load. Not a business date. Max = 2024-04-09. (Tier 2 — ETL) |
| 33 | UpdateDateID | int | YES | Date integer key derived from UpdateDate (YYYYMMDD format). Mostly NULL in current data. (Tier 2 — ETL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Rows 1-2, 27 | Fivetran metadata | synthetic | Generated by Fivetran sync |
| Rows 3-31 | ECP Bank settlement report | Corresponding report fields | Passthrough |
| Rows 32-33 | ETL pipeline | — | Load timestamp / date key |

### 5.2 ETL Pipeline

```
ECP Bank Merchant Portal (Gibraltar merchant 172000000006524)
  |-- Fivetran connector (incremental sync via API/SFTP) ---|
  v
EXW_dbo.EXW_ECPBank (113K rows, ROUND_ROBIN, CCI)
  |-- Data frozen 2022-09-20 — Simplex decommissioned ---|
  v
No UC Generic Pipeline mapping (_Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| uti | EXW_dbo.EXW_SimplexMapping.uti | Links ECP settlement to Simplex transaction record |
| uti | EXW_dbo.EXW_PaymentReconciliation.UTI | Links ECP settlement to internal payment reconciliation |
| acquirer_ref_ | EXW_dbo.EXW_SimplexChargebacks.ARN | Links settled transaction to chargeback dispute |

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| EXW_dbo.EXW_PaymentReconciliation | ECPTranDate, ECPPostDate, ECPType, ECPStatus, ECPAmout, ECPCommission, ECPNetAmount, ECPAdditionalCharge | Payment reconciliation joins ECP Bank settlement details |

---

## 7. Sample Queries

### Monthly Settlement Volume by Currency

```sql
SELECT
    LEFT(CAST(posting_date AS varchar(8)), 6) AS yyyymm,
    acct_curr,
    COUNT(*) AS transactions,
    SUM(acct_amount_gross) AS gross_amount,
    SUM(acct_commission_charges) AS total_commission,
    SUM(acct_amount_net) AS net_settlement
FROM [EXW_dbo].[EXW_ECPBank]
WHERE _fivetran_deleted = 0
    AND type = 'Purchase'
GROUP BY LEFT(CAST(posting_date AS varchar(8)), 6), acct_curr
ORDER BY yyyymm DESC, acct_curr;
```

### Cross-Reference ECP Settlement with Simplex Mapping

```sql
SELECT
    ecb.posting_date,
    ecb.uti,
    ecb.acct_amount_gross,
    ecb.acct_curr,
    ecb.status AS ecp_status,
    sm.status AS simplex_status,
    sm.crypto_currency,
    sm.country AS cardholder_country
FROM [EXW_dbo].[EXW_ECPBank] ecb
JOIN [EXW_dbo].[EXW_SimplexMapping] sm
    ON sm.uti = ecb.uti
WHERE ecb._fivetran_deleted = 0
ORDER BY ecb.posting_date DESC;
```

### Interchange Cost by Card Network

```sql
SELECT
    CASE acquirer_bin_ica
        WHEN 453760 THEN 'Visa'
        WHEN 14206 THEN 'Mastercard'
        ELSE CAST(acquirer_bin_ica AS varchar)
    END AS card_network,
    COUNT(*) AS transaction_count,
    SUM(acct_assessed_intchg_amount) AS total_interchange,
    SUM(acct_amount_gross) AS total_gross,
    SUM(acct_assessed_intchg_amount) / NULLIF(SUM(acct_amount_gross), 0) * 100 AS interchange_rate_pct
FROM [EXW_dbo].[EXW_ECPBank]
WHERE _fivetran_deleted = 0 AND type = 'Purchase'
GROUP BY acquirer_bin_ica;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian (Confluence/Jira) sources found for EXW_ECPBank. This is external acquirer data from ECP Bank's merchant settlement system.

---

*Generated: 2026-04-20 | Quality: 8.6/10 | Phases: 11/14*  
*Tiers: 0 T1, 4 T2, 0 T3, 29 T4, 0 T5 | Elements: 33/33, Logic: 4/10, Data Evidence: P2+P3 PASS*  
*Object: EXW_dbo.EXW_ECPBank | Type: Table | Production Source: ECP Bank settlement (Fivetran)*
