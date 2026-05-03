# EXW_Wallet.Conversions

> 50,268-row crypto-to-crypto conversion record table tracking wallet-level currency exchanges from October 2018 to June 2023. Sourced from WalletDB.Wallet.Conversions via Generic Pipeline (Bronze, daily append). Data ingestion appears to have stopped in mid-2023; the table is likely dormant.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.Conversions (Generic Pipeline, Bronze) |
| **Refresh** | Daily (1440 min), Append strategy — last data June 2023 (likely dormant) |
| **Synapse Distribution** | HASH(Id) |
| **Synapse Index** | HEAP |
| **UC Target** | `wallet.bronze_walletdb_wallet_conversions` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

EXW_Wallet.Conversions stores records of crypto-to-crypto conversions performed within the eToroX wallet platform. Each row represents a single conversion event where a user exchanged an amount of one cryptocurrency (FromCryptoId / FromAmount) into another cryptocurrency (ToCryptoId / ToAmount) between two wallets (FromWalletId / ToWalletId).

The table contains 50,268 rows spanning October 2018 through June 2023. All rows carry ConversionTypeId = 1, indicating a single conversion type is in use. The data is loaded via the Generic Pipeline from WalletDB.Wallet.Conversions using a daily Append strategy. The last recorded conversion is from 2023-06-14, suggesting the table is no longer actively refreshed.

The CorrelationId column links conversions to downstream transaction records in EXW_Wallet.SentTransactions and EXW_Wallet.ConversionTransactions, enabling the EXW_TransactionsView to assemble a unified transaction ledger.

The etr_y, etr_ym, and etr_ymd columns are ETL-generated partition columns derived from the Occurred timestamp.

---

## 2. Business Logic

### 2.1 Crypto-to-Crypto Exchange

**What**: Each conversion represents an exchange between two different cryptocurrency assets within the wallet ecosystem.
**Columns Involved**: FromCryptoId, ToCryptoId, FromAmount, ToAmount
**Rules**:
- FromCryptoId and ToCryptoId identify the source and target crypto assets (25 distinct values observed for each)
- FromAmount is the quantity debited from the source wallet; ToAmount is the quantity credited to the target wallet
- Both amounts use numeric(36,18) precision to support high-precision crypto quantities
- The exchange rate is implicit: ToAmount / FromAmount gives the effective conversion rate

### 2.2 Wallet Linkage

**What**: Each conversion operates between two wallets identified by GUIDs.
**Columns Involved**: FromWalletId, ToWalletId, CorrelationId
**Rules**:
- FromWalletId is the wallet debited; ToWalletId is the wallet credited
- CorrelationId links the conversion to SentTransactions entries in the EXW_TransactionsView
- No NULL values exist in any of these columns across the full dataset

### 2.3 Single Conversion Type

**What**: All rows share the same ConversionTypeId.
**Columns Involved**: ConversionTypeId
**Rules**:
- ConversionTypeId = 1 for all 50,268 rows
- No other conversion types are present in the dataset

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- Distributed by HASH(Id) — single-row lookups by Id are efficient
- HEAP storage (no clustered index) — full scans are required for range queries
- Table is small (50K rows) so full scans are fast regardless

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Find conversions for a specific wallet | `WHERE FromWalletId = '...' OR ToWalletId = '...'` |
| Calculate conversion rates | `SELECT FromCryptoId, ToCryptoId, ToAmount / NULLIF(FromAmount, 0) AS rate FROM EXW_Wallet.Conversions` |
| Monthly conversion volume | `SELECT etr_ym, COUNT(*) FROM EXW_Wallet.Conversions GROUP BY etr_ym ORDER BY etr_ym` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.SentTransactions | CorrelationId = CorrelationId | Link conversion to blockchain transactions |
| EXW_Wallet.ConversionTransactions | ConversionTransactions.ConversionId = Conversions.Id | Get per-leg transaction details (fees, rates) |

### 3.4 Gotchas

- All rows have ConversionTypeId = 1 — filtering on this column is a no-op
- Data stops at 2023-06-14; do not expect recent conversions
- FromAmount and ToAmount are numeric(36,18) — high precision but may cause rounding issues in aggregations; use explicit CAST when needed
- No FK constraints exist in the DDL — referential integrity is application-enforced
- The table is a Bronze-layer landing table; for enriched conversion data, use EXW_dbo.EXW_FactConversions (loaded via SP_EXW_C2F_E2E from a separate CopyFromLake pipeline)

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
| 1 | Id | bigint | YES | Primary key identifying each conversion record. Distribution key for the table. All values observed are unique positive integers. (Tier 3 — no upstream wiki; grounded in DDL + live sample) |
| 2 | FromWalletId | uniqueidentifier | YES | GUID of the source wallet from which cryptocurrency is debited during the conversion. No NULLs in dataset. (Tier 3 — no upstream wiki; grounded in DDL + live sample) |
| 3 | ToWalletId | uniqueidentifier | YES | GUID of the target wallet to which cryptocurrency is credited during the conversion. No NULLs in dataset. (Tier 3 — no upstream wiki; grounded in DDL + live sample) |
| 4 | ConversionTypeId | int | YES | Type of conversion. All 50,268 rows have value 1. No lookup table found in EXW_Dictionary. (Tier 3 — no upstream wiki; grounded in DDL + distribution analysis) |
| 5 | FromAmount | numeric(36,18) | YES | Quantity of cryptocurrency debited from the source wallet. High-precision decimal supporting sub-satoshi granularity. Sample values range from 0.011115 to 127.37. (Tier 3 — no upstream wiki; grounded in DDL + live sample) |
| 6 | ToAmount | numeric(36,18) | YES | Quantity of cryptocurrency credited to the target wallet. The ratio ToAmount/FromAmount represents the effective conversion rate. Sample values range from 0.000577 to 9729.516227. (Tier 3 — no upstream wiki; grounded in DDL + live sample) |
| 7 | CorrelationId | uniqueidentifier | YES | Unique correlation identifier linking this conversion to related SentTransactions and ConversionTransactions entries. Used as the JOIN key in EXW_Wallet.EXW_TransactionsView (conversion_in_transactions and conversion_out_transactions CTEs). No NULLs in dataset. (Tier 3 — no upstream wiki; grounded in DDL + JOIN analysis in EXW_TransactionsView) |
| 8 | Occurred | datetime2(7) | YES | Timestamp when the conversion was executed. Range: 2018-10-28 to 2023-06-14. Source for the etr_y/etr_ym/etr_ymd partition columns. (Tier 3 — no upstream wiki; grounded in DDL + live sample) |
| 9 | FromCryptoId | int | YES | Integer identifier for the source cryptocurrency being converted from. 25 distinct values observed; top values: 2 (17,135 rows), 1 (7,748), 4 (7,453), 21 (5,396). No NULLs. (Tier 3 — no upstream wiki; grounded in DDL + distribution analysis) |
| 10 | ToCryptoId | int | YES | Integer identifier for the target cryptocurrency being converted to. 25 distinct values observed; top values: 1 (17,950 rows), 2 (8,569), 4 (5,737), 21 (5,080). No NULLs. (Tier 3 — no upstream wiki; grounded in DDL + distribution analysis) |
| 11 | etr_y | varchar(max) | YES | ETL-generated partition column containing the four-digit year extracted from Occurred (e.g. "2021"). Added by the Generic Pipeline during Bronze ingestion. (Tier 3 — no upstream wiki; ETL partition column grounded in live sample) |
| 12 | etr_ym | varchar(max) | YES | ETL-generated partition column containing year-month extracted from Occurred (e.g. "2021-02"). Added by the Generic Pipeline during Bronze ingestion. (Tier 3 — no upstream wiki; ETL partition column grounded in live sample) |
| 13 | etr_ymd | varchar(max) | YES | ETL-generated partition column containing the full date extracted from Occurred (e.g. "2021-02-28"). Added by the Generic Pipeline during Bronze ingestion. (Tier 3 — no upstream wiki; ETL partition column grounded in live sample) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.Conversions | Id | Passthrough |
| FromWalletId | WalletDB.Wallet.Conversions | FromWalletId | Passthrough |
| ToWalletId | WalletDB.Wallet.Conversions | ToWalletId | Passthrough |
| ConversionTypeId | WalletDB.Wallet.Conversions | ConversionTypeId | Passthrough |
| FromAmount | WalletDB.Wallet.Conversions | FromAmount | Passthrough |
| ToAmount | WalletDB.Wallet.Conversions | ToAmount | Passthrough |
| CorrelationId | WalletDB.Wallet.Conversions | CorrelationId | Passthrough |
| Occurred | WalletDB.Wallet.Conversions | Occurred | Passthrough |
| FromCryptoId | WalletDB.Wallet.Conversions | FromCryptoId | Passthrough |
| ToCryptoId | WalletDB.Wallet.Conversions | ToCryptoId | Passthrough |
| etr_y | Generic Pipeline | Occurred | Year extracted from Occurred |
| etr_ym | Generic Pipeline | Occurred | Year-month extracted from Occurred |
| etr_ymd | Generic Pipeline | Occurred | Full date extracted from Occurred |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.Conversions (production, WalletDB server)
  |-- Generic Pipeline (Bronze, Append, daily/1440 min, parquet) ---|
  v
EXW_Wallet.Conversions (50,268 rows, HASH(Id), HEAP)
  |-- Generic Pipeline (Bronze export) ---|
  v
wallet.bronze_walletdb_wallet_conversions (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| FromWalletId | EXW_Wallet.Wallets | Source wallet for the conversion |
| ToWalletId | EXW_Wallet.Wallets | Target wallet for the conversion |
| CorrelationId | EXW_Wallet.SentTransactions | Links conversion to blockchain send transactions |
| FromCryptoId | Crypto asset dictionary (not in EXW_Dictionary) | Source cryptocurrency identifier |
| ToCryptoId | Crypto asset dictionary (not in EXW_Dictionary) | Target cryptocurrency identifier |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| Id | EXW_Wallet.ConversionTransactions.ConversionId | Per-leg transaction details for each conversion |
| CorrelationId | EXW_Wallet.EXW_TransactionsView | Unified transaction view joins via CorrelationId through SentTransactions |

---

## 7. Sample Queries

### 7.1 Conversion Volume by Month

```sql
SELECT
    etr_ym,
    COUNT(*) AS conversions,
    COUNT(DISTINCT FromCryptoId) AS unique_from_cryptos,
    COUNT(DISTINCT ToCryptoId) AS unique_to_cryptos
FROM EXW_Wallet.Conversions
GROUP BY etr_ym
ORDER BY etr_ym DESC;
```

### 7.2 Most Common Conversion Pairs

```sql
SELECT
    FromCryptoId,
    ToCryptoId,
    COUNT(*) AS cnt,
    AVG(ToAmount / NULLIF(FromAmount, 0)) AS avg_rate
FROM EXW_Wallet.Conversions
GROUP BY FromCryptoId, ToCryptoId
ORDER BY cnt DESC;
```

### 7.3 Link Conversion to Transaction Details

```sql
SELECT
    c.Id AS ConversionId,
    c.FromCryptoId,
    c.ToCryptoId,
    c.FromAmount,
    c.ToAmount,
    ct.CryptoRateUsd,
    ct.EtoroFeeCalculated
FROM EXW_Wallet.Conversions c
JOIN EXW_Wallet.ConversionTransactions ct ON ct.ConversionId = c.Id
WHERE c.Occurred >= '2023-01-01';
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 6/10 | Phases: 12/14*
*Tiers: 0 T1, 0 T2, 13 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 6/10, Lineage: 7/10*
*Object: EXW_Wallet.Conversions | Type: Table | Production Source: WalletDB.Wallet.Conversions (dormant)*
