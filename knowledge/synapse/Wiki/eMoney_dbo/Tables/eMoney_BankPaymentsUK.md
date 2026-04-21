# eMoney_dbo.eMoney_BankPaymentsUK

> 468,632-row GBP-only bank payment transaction log for eToro Money UK customers — one row per transaction (grain = TransactionId). Covers SEPA/Faster Payments bank-to-eTM and eTM-to-bank transfers, debit adjustments, and banking returns. Date range: 2025-12-21 to 2026-04-11 (112 days). All records are GBP; 66% are bank-in (BankPayIns-External), 34% bank-out (BankPayOuts-External). Written by SP_eMoney_Reconciliation_ETLs (BankPaymentsUK section). Unique in eMoney_dbo: HASH(TransactionId) + Clustered Columnstore Index (CCI) — the only historical-append table with column-store optimisation in the schema.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | FiatDwhDB / Tribe AccountsActivities reconciliation data (GBP bank payments). Written by SP_eMoney_Reconciliation_ETLs (BankPaymentsUK section). |
| **Refresh** | Incremental — DELETE WHERE Created=@Date + INSERT (daily re-process of same-day Tribe batch; rows accumulate over time). |
| **Synapse Distribution** | HASH(TransactionId) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX (CCI) — columnar storage for analytical aggregations |
| **UC Target** | `main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |
| **PII** | BankAccountNumber (external UK bank account number — handle with care) |

---

## 1. Business Meaning

`eMoney_BankPaymentsUK` is the GBP bank payment transaction log for eToro Money UK accounts. **Grain**: one row per Tribe transaction — one row per bank payment event (TransactionId is unique). As of 2026-04-11, the table holds 468,632 rows covering 102,877 distinct account holders (HolderId), spanning 2025-12-21 to 2026-04-11.

**What the table captures**: GBP-denominated bank transfer activity on eToro Money UK accounts — specifically:
- **BankPayIns-External** (309,224 rows, 66.0%): External bank-to-eTM transfers (customers funding their eTM wallet from a UK bank account). Amounts are positive.
- **BankPayOuts-External** (158,802 rows, 33.9%): eTM-to-external bank transfers (customers withdrawing from their eTM wallet to a UK bank account). Amounts are negative.
- **BankPayOuts-DebitAdj** (509 rows, 0.1%): Debit adjustment transactions — reversed or corrected outgoing payments (positive HolderAmount, offsetting prior MO events).
- **BankPayOuts-BankingReturn** (97 rows, 0.02%): Returned bank payments — outgoing transfers rejected by the receiving bank and returned to the eTM account (positive HolderAmount).

**What it excludes**: Non-GBP transactions; card transactions; IBAN direct debits; TransactionCodes 6,14,15,24,25,64 (excluded by SP filter); Network types other than 'Internal Payment' and 'External Payment'.

**Primary use case**: UK bank payment reconciliation, Faster Payments and SEPA monitoring, GBP funding/withdrawal volume reporting, and customer-level bank transfer pattern analysis.

**Index note**: This is the only table in eMoney_dbo with a Clustered Columnstore Index (CCI). Unlike other eMoney tables (HEAP), CCI is applied because the table accumulates history and aggregation-heavy analytical workloads benefit from columnar storage.

---

## 2. Business Logic

### 2.1 Incremental Append with Same-Day Re-processing

**What**: The table grows daily; the SP deletes and re-inserts only the current day's Tribe batch, preserving all prior days.

**Columns Involved**: `Created`, `Date`, `DateID`, `UpdateDate`

**Rules**:
- `Created` = Tribe batch creation timestamp for the transaction record (typically the batch's processing date, midnight). The DELETE targets rows WHERE Created = @Date before re-inserting — this idempotently re-processes any same-day corrections in the Tribe data.
- `Date` = CAST(TransactionDateTime AS DATE) — the actual business date of the bank transaction
- `DateID` = YYYYMMDD integer of Date
- Unlike TRUNCATE+INSERT tables, BankPaymentsUK retains all historical days. New days are appended; the current day is overwritten if the SP runs again intra-day.

### 2.2 BankActivityType CASE Classification

**What**: A computed column categorising each transaction into one of four bank activity types based on TransactionCode.

**Columns Involved**: `BankActivityType`, `TransactionCode`, `HolderAmount`

**Rules**:
- SP derives BankActivityType from a CASE expression on TransactionCode; observed mappings from live data:

| BankActivityType | TransactionCodes | Direction | Rows |
|-----------------|-----------------|-----------|------|
| BankPayIns-External | 57, 59, 68 | Positive (MI) | 309,224 |
| BankPayOuts-External | 56, 58 | Negative (MO) | 158,802 |
| BankPayOuts-DebitAdj | 11 | Positive (adjustment reversal) | 509 |
| BankPayOuts-BankingReturn | 66 | Positive (returned MO) | 97 |

- BankPayOuts-DebitAdj and BankPayOuts-BankingReturn have positive HolderAmount despite the "Outs" prefix — these are corrections of or returns from prior outgoing payments, resulting in money returning to the account.
- SP filter excludes TransactionCode IN (6,14,15,24,25,64) before BankActivityType assignment.

### 2.3 GBP-Only Scope

**What**: All rows in this table are GBP.

**Columns Involved**: `TransactionCurrencyCode`, `TransactionCurrencyAlpha`, `HolderCurrencyAlpha`

**Rules**:
- SP inserts only rows WHERE HolderCurrencyAlpha = 'GBP' — EUR, AUD, DKK bank payments are excluded
- TransactionCurrencyCode is always 826 (GBP ISO numeric), TransactionCurrencyAlpha always 'GBP'
- HolderCurrencyAlpha always 'GBP' — no FX conversion needed; TransactionAmount = HolderAmount for all rows
- Separate reconciliation tables would be needed for EUR (e.g., SEPA) and AUD bank payments

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(TransactionId) distributes by transaction — no two rows share a TransactionId, so all nodes hold roughly equal data volumes. The Clustered Columnstore Index (CCI) compresses column data and enables fast aggregation queries (SUM, COUNT, GROUP BY). CCI does not support single-row lookup by TransactionId efficiently — use equality predicates on HolderId, AccountId, or Date columns for filtered scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily bank-in volume (£) | `WHERE BankActivityType = 'BankPayIns-External' GROUP BY Date SUM(HolderAmount)` |
| Customer funding history | `WHERE HolderId = @holder GROUP BY Date, BankActivityType` — filter early on HolderId |
| Returned/failed payments | `WHERE BankActivityType = 'BankPayOuts-BankingReturn'` |
| Net daily bank flow | `SUM(HolderAmount) GROUP BY Date` (MI positive + MO negative = net) |
| Specific date range | `WHERE Date BETWEEN @start AND @end` — prefer Date over DateID for readability |
| Volume by TX type code | `GROUP BY TransactionCode, BankActivityType` — see mapping in Business Logic 2.2 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Dim_Account | ON bpuk.AccountId = mda.AccountID | Full account profile (CID, GCID, IsValidETM) |
| eMoney_dbo.eMoney_Account_Mappings | ON bpuk.ExternalBankAccountId = eam.BankAccountID | External bank details |
| DWH_dbo.Dim_Customer | ON mda.CID = dc.RealCID | Customer trading profile |

### 3.4 Gotchas

- **CCI is not like HEAP**: Unlike other eMoney tables, row-level updates are expensive. The DELETE+INSERT pattern is appropriate for batch reprocessing. Avoid row-by-row operations.
- **BankPayOuts-DebitAdj and BankPayOuts-BankingReturn are positive amounts**: Despite the "Out" prefix, these are credits (money returned to the account). Do not sum ALL BankPayOuts categories as money-out — filter on negative HolderAmount for true debits.
- **Created ≠ TransactionDateTime**: Created is the Tribe batch processing date (midnight), not when the transaction occurred. Use TransactionDateTime or Date for transaction timing.
- **BankAccountNumber is PII**: External UK bank account number — apply data masking or access controls where required.
- **No GCID or CID in this table**: The table does not include eToro CID or GCID directly. Join to eMoney_Dim_Account via AccountId to resolve CID/GCID.
- **Limited date range**: Data starts 2025-12-21 — older UK bank payment history is not in this table. The SP may have been first run or reset in late December 2025.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (FiatDwhDB or etoro DB_Schema) |
| Tier 2 | Derived from ETL SP code or DWH computation logic |
| Tier 3 | Inferred from column name and context |
| Tier 4 | Best available — limited confidence |
| Tier 5 | Glossary-sourced |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HolderId | int | YES | Tribe provider holder identifier for the account owner. Corresponds to ProviderHolderId in FiatDwhDB — the external payment provider's ID for this account holder. Sourced from Tribe AccountsActivities reconciliation data. (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 2 | AccountId | int | YES | Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. DWH note: source is FiatAccount.Id. (Tier 1 — dbo.FiatAccount) |
| 3 | ExternalBankAccountId | bigint | YES | Auto-incrementing surrogate primary key for the external bank account record. FK from FiatTransactions.ExternalBankAccountId → dbo.FiatBankAccount.Id. The external UK bank account on the other side of the payment. (Tier 1 — dbo.FiatBankAccount) |
| 4 | BankAccountNumber | bigint | YES | External UK bank account numeric identifier (from the Tribe AccountsActivities record for the counterparty bank account). **PII — handle with care.** (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 5 | TransactionCode | int | YES | Tribe internal transaction type code. Observed values: 57=bank-in external, 56/58=bank-out external, 59=bank-in external (alt), 11=debit adjustment, 66=banking return, 68=bank-in external (rare). Input to BankActivityType CASE expression. Excluded codes: 6,14,15,24,25,64. (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 6 | TransactionDateTime | datetime | YES | Timestamp when the bank payment transaction occurred (from Tribe AccountsActivities). Used to compute Date and DateID. (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 7 | TransactionAmount | float | YES | Transaction amount in TransactionCurrency (GBP). Positive for MI, negative for MO. Equals HolderAmount for GBP accounts (no FX). (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 8 | TransactionCurrencyCode | int | YES | ISO 4217 numeric currency code for the transaction (always 826=GBP for all rows in this table). (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 9 | TransactionCurrencyAlpha | nvarchar(124) | YES | Text ISO currency code for the transaction (always 'GBP' for all rows in this table). (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 10 | HolderAmount | float | YES | Amount in the account holder's currency (GBP). Positive for inbound transfers (BankPayIns); negative for outbound (BankPayOuts-External). BankPayOuts-DebitAdj and BankPayOuts-BankingReturn may be positive despite "Outs" prefix — these are credits from returned/corrected outgoing payments. Range for BankPayOuts-External: -100,000 to -0.01 GBP; BankPayIns-External: 0.01 to 1,000,000 GBP. (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 11 | HolderCurrencyAlpha | nvarchar(124) | YES | Holder's account currency text code (always 'GBP'). SP filter restricts to HolderCurrencyAlpha='GBP'. (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 12 | TransactionId | bigint | YES | Unique Tribe/FiatDwhDB transaction identifier (FiatTransactions.Id or equivalent Tribe TX ID). One row per TransactionId — the table grain and HASH distribution key. (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 13 | EpmMethodId | bigint | YES | Electronic payment method identifier from Tribe AccountsActivities. Value=4 observed for all sampled rows (likely the UK Faster Payments or SEPA credit transfer method). (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 14 | BankActivityType | nvarchar(4000) | YES | Computed classification of the bank payment event. Derived from a CASE expression on TransactionCode. Four live values: 'BankPayIns-External' (TC 57/59/68, 66.0%), 'BankPayOuts-External' (TC 56/58, 33.9%), 'BankPayOuts-DebitAdj' (TC 11, 0.1%), 'BankPayOuts-BankingReturn' (TC 66, 0.02%). nvarchar(4000) is the DDL-declared width; actual values are short strings. (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 15 | Created | datetime | YES | Tribe batch creation timestamp for this transaction record (typically midnight of the processing day). Used as the DELETE key in the incremental load pattern — DELETE WHERE Created = @Date before re-inserting the day's batch. (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 16 | Date | date | YES | Calendar date of the bank payment transaction (CAST(TransactionDateTime AS DATE)). Business date for filtering; range: 2025-12-21 to 2026-04-11. (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 17 | DateID | int | YES | YYYYMMDD integer of Date (e.g., 20260411). Numeric date key for date-based partitioning in queries. (Tier 2 — SP_eMoney_Reconciliation_ETLs) |
| 18 | UpdateDate | datetime | YES | Timestamp when this record was written by the SP. Set to GETDATE() at INSERT time. Not a business event timestamp. (Tier 2 — SP_eMoney_Reconciliation_ETLs) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| AccountId | FiatDwhDB.dbo.FiatAccount | Id | Passthrough from Tribe reconciliation data |
| ExternalBankAccountId | FiatDwhDB.dbo.FiatBankAccount | Id | FK from FiatTransactions.ExternalBankAccountId |
| TransactionId | FiatDwhDB.dbo.FiatTransactions (equiv.) | Id / Tribe TX ID | Grain key; passthrough |
| TransactionCode | Tribe AccountsActivities | TransactionCode | Passthrough; input to BankActivityType CASE |
| BankActivityType | ETL | — | CASE(TransactionCode): 4 live category values |
| HolderAmount | FiatDwhDB.dbo.FiatTransactions | HolderAmount | Passthrough |
| Created | Tribe AccountsActivities | Created | DELETE key for incremental load |
| Date | ETL | — | CAST(TransactionDateTime AS DATE) |
| DateID | ETL | — | YYYYMMDD integer of Date |
| UpdateDate | ETL | — | GETDATE() at INSERT |

### 5.2 ETL Pipeline

```
Tribe / FiatDwhDB GBP bank payment transactions
  |-- SP_eMoney_Reconciliation_ETLs: #AccountsActivities (Tribe reconciliation temp table) ---|
  Filter: HolderCurrencyAlpha='GBP'
         AND Network IN ('Internal Payment', 'External Payment')
         AND TransactionCode NOT IN (6,14,15,24,25,64)
  CASE TransactionCode → BankActivityType (BankPayIns-External / BankPayOuts-External / BankPayOuts-DebitAdj / BankPayOuts-BankingReturn)
  v
DELETE FROM eMoney_dbo.eMoney_BankPaymentsUK WHERE Created = @Date
INSERT INTO eMoney_dbo.eMoney_BankPaymentsUK (incremental daily append)
  v
eMoney_dbo.eMoney_BankPaymentsUK (468,632 rows, 2025-12-21→2026-04-11, HASH(TransactionId), CCI)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| AccountId | eMoney_dbo.eMoney_Dim_Account | Account identity (JOIN to get CID, GCID, IsValidETM) |
| ExternalBankAccountId | eMoney_dbo.eMoney_Account_Mappings | External bank account cross-reference |
| HolderId | eMoney_dbo.eMoney_Dim_Account (ProviderHolderID) | Tribe-side account identity |

### 6.2 Referenced By

| Object | Relationship |
|--------|-------------|
| main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_bankpaymentsuk | UC Gold export (Generic Pipeline, delta) |

---

## 7. Sample Queries

```sql
-- Daily GBP bank payment flow (net in/out) over the last 30 days
SELECT
    Date,
    SUM(CASE WHEN HolderAmount > 0 THEN HolderAmount ELSE 0 END) AS total_bank_in,
    SUM(CASE WHEN HolderAmount < 0 THEN HolderAmount ELSE 0 END) AS total_bank_out,
    SUM(HolderAmount) AS net_flow,
    COUNT(*) AS transaction_count
FROM eMoney_dbo.eMoney_BankPaymentsUK
WHERE Date >= DATEADD(day, -30, CAST(GETDATE() AS date))
GROUP BY Date
ORDER BY Date DESC;
```

```sql
-- Bank activity type breakdown by volume and amount
SELECT
    BankActivityType,
    TransactionCode,
    COUNT(*) AS tx_count,
    SUM(ABS(HolderAmount)) AS total_volume_gbp,
    AVG(ABS(HolderAmount)) AS avg_tx_amount_gbp
FROM eMoney_dbo.eMoney_BankPaymentsUK
GROUP BY BankActivityType, TransactionCode
ORDER BY tx_count DESC;
```

```sql
-- Top 20 accounts by inbound GBP bank transfer volume
SELECT TOP 20
    mda.CID,
    mda.GCID,
    bpuk.AccountId,
    COUNT(*) AS bank_in_count,
    SUM(bpuk.HolderAmount) AS total_bank_in_gbp
FROM eMoney_dbo.eMoney_BankPaymentsUK bpuk
JOIN eMoney_dbo.eMoney_Dim_Account mda ON bpuk.AccountId = mda.AccountID
WHERE bpuk.BankActivityType = 'BankPayIns-External'
    AND mda.GCID_Unique_Count = 1
GROUP BY mda.CID, mda.GCID, bpuk.AccountId
ORDER BY total_bank_in_gbp DESC;
```

---

## 8. Sources

No Atlassian documentation found for this object.

---

*Generated: 2026-04-21 | Quality: 8.8/10 | Phases: 13/14*
*Tiers: 2 T1, 16 T2, 0 T3, 0 T4, 0 T5 | Elements: 18/18*

> **Phase Gate Check**: T1 columns (AccountId, ExternalBankAccountId) verified against eMoney_Dim_Account.md (#2 AccountID), eMoney_Account_Mappings.md (#13 AccountID), eMoney_Dim_Transaction.md (#9 ExternalBankAccountID). BankActivityType CASE mapping verified against live TransactionCode data (7 observed codes → 4 activity types). CCI confirmed via sys.indexes query (CLUSTERED COLUMNSTORE). All 18 elements documented.

> **T1 Copy Verification**: AccountId — "Auto-incrementing surrogate primary key..." matches eMoney_Dim_Account #2. ExternalBankAccountId — "Auto-incrementing surrogate primary key for the external bank account record. FK from FiatTransactions.ExternalBankAccountId → dbo.FiatBankAccount.Id." matches eMoney_Dim_Transaction #9.
