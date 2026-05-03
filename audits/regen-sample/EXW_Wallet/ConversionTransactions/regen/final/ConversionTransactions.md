# EXW_Wallet.ConversionTransactions

> 98,713-row per-leg crypto conversion transaction table recording each side (FROM/TO) of wallet-to-wallet crypto swaps from October 2018 to June 2023. Sourced from WalletDB.Wallet.ConversionTransactions via Generic Pipeline (Bronze, daily Append). Each conversion in EXW_Wallet.Conversions produces ~2 rows here (one per leg). Data ingestion appears to have stopped mid-2023; the table is likely dormant.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.ConversionTransactions (Generic Pipeline #656, Bronze) |
| **Refresh** | Daily (1440 min), Append strategy — last data 2023-06-14 (likely dormant) |
| **Synapse Distribution** | HASH(ConversionId) |
| **Synapse Index** | HEAP |
| **UC Target** | `wallet.bronze_walletdb_wallet_conversiontransactions` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.ConversionTransactions stores the per-leg transaction details for every crypto-to-crypto conversion executed within the eToro Wallet (eToroX) platform. While EXW_Wallet.Conversions holds the conversion header (source/target wallets, amounts, correlation), this table captures one row per conversion leg — typically two rows per ConversionId: one for the FROM leg (crypto sold) and one for the TO leg (crypto purchased).

The table contains 98,713 rows spanning October 2018 through June 2023, covering 49,955 distinct ConversionIds across 43,469 distinct WalletIds. The data is loaded via Generic Pipeline #656 from WalletDB.Wallet.ConversionTransactions using a daily Append strategy. The last recorded transaction is from 2023-06-14, suggesting the conversion feature was deprecated or replaced.

Each leg records the crypto amount transferred, the USD rate at conversion time, the blockchain destination address, and fees (eToro fee percentage/calculated amount + estimated blockchain fee). The EXW_Wallet.EXW_TransactionsView consumes this table in its `conversion_in_transactions` and `conversion_out_transactions` CTEs, joining through EXW_Wallet.Conversions to link legs back to SentTransactions. The downstream EXW_dbo.EXW_FactConversions denormalizes both legs into a single flat row per conversion.

The etr_y, etr_ym, and etr_ymd columns are ETL-generated partition columns derived from the Occurred timestamp by the Generic Pipeline.

---

## 2. Business Logic

### 2.1 Per-Leg Transaction Architecture

**What**: Each conversion has two legs stored as separate rows — one for the FROM side (crypto sold) and one for the TO side (crypto purchased).
**Columns Involved**: ConversionId, WalletId, CryptoId, Amount
**Rules**:
- Two rows per ConversionId: one where WalletId = Conversions.FromWalletId AND CryptoId = Conversions.FromCryptoId (FROM leg), one where they match the To side (TO leg)
- The EXW_TransactionsView uses this pattern: `ct.WalletId = c.FromWalletId AND ct.CryptoId = c.FromCryptoId` to identify FROM legs; `ctt.WalletId <> c.FromWalletId OR ctt.CryptoId <> c.FromCryptoId` for TO legs
- 49,955 distinct ConversionIds producing 98,713 rows confirms ~2 rows/conversion

### 2.2 Fee Structure

**What**: Each leg carries a fee percentage, calculated fee amount, and estimated blockchain fee.
**Columns Involved**: EtoroFeePercentage, EtoroFeeCalculated, EstimatedBlockChainFee
**Rules**:
- EtoroFeePercentage = 0.10 (10 basis points) in 99.98% of rows; 1.00 in 18 rows, 0.50 in 6 rows
- EtoroFeeCalculated is the actual fee deducted in native crypto units
- EstimatedBlockChainFee is the estimated blockchain network fee at transaction initiation
- In EXW_TransactionsView, the TO leg's EtoroFeeCalculated becomes `EtoroFees` and EstimatedBlockChainFee becomes `EffectiveBlockchainFee`

### 2.3 USD Rate Snapshot

**What**: CryptoRateUsd captures the market price of the crypto asset at conversion time.
**Columns Involved**: CryptoRateUsd
**Rules**:
- Used by EXW_TransactionsView to compute FeeExchangeRate: `ctf.CryptoRateUsd / NULLIF(ctt.CryptoRateUsd, 0)` (FROM rate / TO rate)
- Values range widely depending on the crypto asset (e.g., BTC ~38K–60K USD, XRP ~0.08–0.43 USD)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- Distributed by HASH(ConversionId) — queries filtering or joining on ConversionId are co-located
- HEAP storage (no clustered index) — full scans required for range queries
- Table is moderate size (98K rows) so full scans are fast

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Get both legs of a conversion | `WHERE ConversionId = @id` — both rows co-located by distribution |
| Fee analysis by crypto | `GROUP BY CryptoId` with `AVG(EtoroFeePercentage)`, `SUM(EtoroFeeCalculated)` |
| Monthly transaction volume | `GROUP BY etr_ym` |
| Link to parent conversion | `JOIN EXW_Wallet.Conversions c ON c.Id = ct.ConversionId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.Conversions | `Conversions.Id = ConversionTransactions.ConversionId` | Get parent conversion details (wallets, amounts, correlation) |
| EXW_Wallet.SentTransactions | Via Conversions.CorrelationId (indirect) | Link to blockchain send records |
| EXW_Wallet.EXW_TransactionsView | Embedded in view CTEs | Unified transaction ledger |

### 3.4 Gotchas

- Each ConversionId appears ~2 times (FROM and TO legs) — do not treat Id as equivalent to ConversionId
- Data stops at 2023-06-14; do not expect recent conversions
- CryptoRateUsd precision is numeric(36,18) — may cause rounding in aggregations; use explicit CAST
- EtoroFeePercentage is nearly uniform (0.10 in 99.98% of rows) — filtering on it is usually a no-op
- No FK constraints in DDL — referential integrity is application-enforced
- ToAddress is varchar(max); includes Bitcoin, Ethereum, Ripple, and Stellar address formats

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code or ETL logic |
| Tier 3 | Grounded in DDL, live data, and JOIN context; no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | bigint | YES | Primary key identifying each per-leg conversion transaction row. Unique across the table. Not the same as ConversionId — each conversion produces ~2 rows with distinct Ids. (Tier 3 — no upstream wiki; grounded in DDL + live sample) |
| 2 | ConversionId | bigint | YES | FK to EXW_Wallet.Conversions.Id identifying the parent conversion. Distribution key for the table. Each ConversionId typically appears twice (FROM and TO legs). 49,955 distinct values across 98,713 rows. (Tier 3 — no upstream wiki; grounded in DDL + live sample + JOIN analysis) |
| 3 | WalletId | uniqueidentifier | YES | GUID of the wallet participating in this leg of the conversion. For the FROM leg, this equals Conversions.FromWalletId; for the TO leg, Conversions.ToWalletId. 43,469 distinct wallets. (Tier 3 — no upstream wiki; grounded in DDL + live sample + EXW_TransactionsView JOIN logic) |
| 4 | CryptoRateUsd | numeric(36,18) | YES | USD exchange rate for the crypto asset at conversion time. Used by EXW_TransactionsView to compute FeeExchangeRate between FROM and TO legs (`ctf.CryptoRateUsd / NULLIF(ctt.CryptoRateUsd, 0)`). Values vary by asset (e.g., BTC ~38K, XRP ~0.08). (Tier 3 — no upstream wiki; grounded in DDL + live sample + view code) |
| 5 | ToAddress | varchar(max) | YES | Blockchain destination address for this conversion leg. Format varies by chain: Bitcoin base58 (e.g., `3D5j...`), Ethereum `0x`+40 hex, Ripple base58+tag, Stellar uppercase base32. (Tier 3 — no upstream wiki; grounded in DDL + live sample) |
| 6 | Amount | numeric(36,18) | YES | Quantity of cryptocurrency transferred in this leg, in native crypto units. High-precision decimal supporting sub-satoshi granularity. Mapped to FromAmount or ToAmount in EXW_FactConversions depending on leg side. (Tier 3 — no upstream wiki; grounded in DDL + live sample + downstream EXW_FactConversions lineage) |
| 7 | EtoroFeePercentage | numeric(5,2) | YES | eToro fee percentage applied to this conversion leg. 0.10 (10 basis points) in 99.98% of rows (98,689); 1.00 in 18 rows; 0.50 in 6 rows. (Tier 3 — no upstream wiki; grounded in DDL + distribution analysis) |
| 8 | EtoroFeeCalculated | numeric(36,18) | YES | Calculated eToro fee in native crypto units for this conversion leg. Used as `EtoroFees` in the EXW_TransactionsView conversion_out CTE. Many rows show 0 (zero fee collected). (Tier 3 — no upstream wiki; grounded in DDL + live sample + view code) |
| 9 | EstimatedBlockChainFee | numeric(36,18) | YES | Estimated blockchain network fee for this conversion leg in native crypto units. Used as `EffectiveBlockchainFee` in EXW_TransactionsView conversion_out CTE. Mapped to FromEtoroEstimatedBCFee (FROM leg) or ToEtoroEstimatedBCFee (TO leg) in EXW_FactConversions. (Tier 3 — no upstream wiki; grounded in DDL + live sample + view code + downstream lineage) |
| 10 | Occurred | datetime2(7) | YES | Timestamp when this conversion leg transaction was created. Range: 2018-10-28 to 2023-06-14. Source for the etr_y/etr_ym/etr_ymd ETL partition columns. Mapped to FromEtoroDate or ToEtoroDate in EXW_FactConversions depending on leg side. (Tier 3 — no upstream wiki; grounded in DDL + live sample + downstream lineage) |
| 11 | CryptoId | int | YES | Integer identifier for the cryptocurrency asset in this leg. 25 distinct values observed; top values: 2 (25,522 rows), 1 (24,938), 4 (12,955), 21 (10,282), 6 (6,738), 102 (6,612). No lookup in EXW_Dictionary; resolves via EXW_Wallet.CryptoTypes. (Tier 3 — no upstream wiki; grounded in DDL + distribution analysis) |
| 12 | etr_y | varchar(max) | YES | ETL-generated partition column containing the four-digit year extracted from Occurred (e.g., "2021"). Added by the Generic Pipeline during Bronze ingestion. (Tier 3 — no upstream wiki; ETL partition column grounded in live sample) |
| 13 | etr_ym | varchar(max) | YES | ETL-generated partition column containing year-month extracted from Occurred (e.g., "2021-04"). Added by the Generic Pipeline during Bronze ingestion. (Tier 3 — no upstream wiki; ETL partition column grounded in live sample) |
| 14 | etr_ymd | varchar(max) | YES | ETL-generated partition column containing the full date extracted from Occurred (e.g., "2021-04-09"). Added by the Generic Pipeline during Bronze ingestion. (Tier 3 — no upstream wiki; ETL partition column grounded in live sample) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.ConversionTransactions | Id | Passthrough |
| ConversionId | WalletDB.Wallet.ConversionTransactions | ConversionId | Passthrough |
| WalletId | WalletDB.Wallet.ConversionTransactions | WalletId | Passthrough |
| CryptoRateUsd | WalletDB.Wallet.ConversionTransactions | CryptoRateUsd | Passthrough |
| ToAddress | WalletDB.Wallet.ConversionTransactions | ToAddress | Passthrough |
| Amount | WalletDB.Wallet.ConversionTransactions | Amount | Passthrough |
| EtoroFeePercentage | WalletDB.Wallet.ConversionTransactions | EtoroFeePercentage | Passthrough |
| EtoroFeeCalculated | WalletDB.Wallet.ConversionTransactions | EtoroFeeCalculated | Passthrough |
| EstimatedBlockChainFee | WalletDB.Wallet.ConversionTransactions | EstimatedBlockChainFee | Passthrough |
| Occurred | WalletDB.Wallet.ConversionTransactions | Occurred | Passthrough |
| CryptoId | WalletDB.Wallet.ConversionTransactions | CryptoId | Passthrough |
| etr_y | Generic Pipeline | Occurred | Year extracted from Occurred |
| etr_ym | Generic Pipeline | Occurred | Year-month extracted from Occurred |
| etr_ymd | Generic Pipeline | Occurred | Full date extracted from Occurred |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.ConversionTransactions (production, WalletDB server)
  |-- Generic Pipeline #656 (Bronze, Append, daily/1440 min, parquet) --|
  v
EXW_Wallet.ConversionTransactions (98,713 rows, HASH(ConversionId), HEAP)
  |-- Generic Pipeline (Bronze export) --|
  v
wallet.bronze_walletdb_wallet_conversiontransactions (UC Bronze)

Downstream consumers:
  EXW_Wallet.EXW_TransactionsView (conversion_in/out CTEs)
  EXW_dbo.EXW_FactConversions (denormalized flat fact table)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| ConversionId | EXW_Wallet.Conversions | Parent conversion record (FK to Conversions.Id) |
| WalletId | EXW_Wallet.Wallets | Wallet participating in this conversion leg |
| CryptoId | EXW_Wallet.CryptoTypes | Cryptocurrency asset reference |

### 6.2 Referenced By (other objects point to this)

| Source Object | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.EXW_TransactionsView | `ct.ConversionId = c.Id AND ct.WalletId = c.FromWalletId AND ct.CryptoId = c.FromCryptoId` | Unified transaction view — conversion_in/out CTEs |
| EXW_dbo.EXW_FactConversions | Historical one-time load consuming per-leg amounts, fees, addresses | Denormalized conversion fact table |

---

## 7. Sample Queries

### 7.1 Both Legs of a Conversion

```sql
SELECT
    ct.Id,
    ct.ConversionId,
    ct.WalletId,
    ct.CryptoId,
    ct.Amount,
    ct.CryptoRateUsd,
    ct.EtoroFeeCalculated,
    ct.Occurred
FROM EXW_Wallet.ConversionTransactions ct
WHERE ct.ConversionId = @ConversionId
ORDER BY ct.Id;
```

### 7.2 Monthly Conversion Volume by Crypto

```sql
SELECT
    etr_ym,
    CryptoId,
    COUNT(*) AS leg_count,
    SUM(Amount) AS total_amount,
    AVG(CryptoRateUsd) AS avg_usd_rate
FROM EXW_Wallet.ConversionTransactions
GROUP BY etr_ym, CryptoId
ORDER BY etr_ym DESC, leg_count DESC;
```

### 7.3 Join to Parent Conversion

```sql
SELECT
    c.Id AS ConversionId,
    c.FromCryptoId,
    c.ToCryptoId,
    ct_from.Amount AS FromAmount,
    ct_from.CryptoRateUsd AS FromRate,
    ct_to.Amount AS ToAmount,
    ct_to.CryptoRateUsd AS ToRate
FROM EXW_Wallet.Conversions c
JOIN EXW_Wallet.ConversionTransactions ct_from
    ON ct_from.ConversionId = c.Id
    AND ct_from.WalletId = c.FromWalletId
    AND ct_from.CryptoId = c.FromCryptoId
JOIN EXW_Wallet.ConversionTransactions ct_to
    ON ct_to.ConversionId = c.Id
    AND (ct_to.WalletId <> c.FromWalletId OR ct_to.CryptoId <> c.FromCryptoId)
WHERE c.Occurred >= '2023-01-01';
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 6.5/10 | Phases: 12/14*
*Tiers: 0 T1, 0 T2, 13 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 7/10, Lineage: 7/10*
*Object: EXW_Wallet.ConversionTransactions | Type: Table | Production Source: WalletDB.Wallet.ConversionTransactions (dormant)*
