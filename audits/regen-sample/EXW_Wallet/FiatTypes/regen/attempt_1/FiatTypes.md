# EXW_Wallet.FiatTypes

> 4-row fiat currency reference table listing supported fiat currencies (USD, EUR, GBP, AUD) sourced from WalletDB.Wallet.FiatTypes via daily Generic Pipeline Override refresh. Used as a lookup in crypto-to-fiat (C2F) conversion workflows.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.FiatTypes (Generic Pipeline, Override copy) |
| **Refresh** | Daily (1440 min), full Override |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `wallet.bronze_walletdb_wallet_fiattypes` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export |

---

## 1. Business Meaning

EXW_Wallet.FiatTypes is a small reference/dictionary table that defines the fiat currencies supported by the eToro Wallet platform. As of the latest sample, it contains exactly 4 rows: USD (US Dollar), EUR (Euro), GBP (British Pound), and AUD (Australian Dollar).

The table is loaded daily via the Generic Pipeline with an Override (full-refresh) strategy from the production WalletDB.Wallet.FiatTypes table. There is no dedicated writer stored procedure — the generic pipeline handles the entire load.

The primary consumer is SP_EXW_C2F_E2E, which joins on `FiatId` to resolve `FiatName` as the human-readable fiat currency label (`FiatCurrency`) in the EXW_C2F_E2E and EXW_C2P_E2E end-to-end conversion tracking tables.

Each row carries an ISO 4217 numeric code (`NumericCode`), a decimal precision setting (`Precision`), and an optional link to a trading instrument (`InstrumentId`). USD (FiatId=1) has no associated InstrumentId (NULL), while EUR, GBP, and AUD each map to a trading instrument.

---

## 2. Business Logic

### 2.1 Fiat Currency Registry

**What**: Each row represents one supported fiat currency with its metadata.
**Columns Involved**: FiatId, FiatName, IsActive, NumericCode, Precision
**Rules**:
- FiatId is the internal wallet-system identifier (1=USD, 2=EUR, 3=GBP, 5=AUD — note: 4 is skipped)
- FiatName stores the ISO 4217 alphabetic code (USD, EUR, GBP, AUD)
- All 4 currencies are currently IsActive = True
- NumericCode follows ISO 4217 (840=USD, 978=EUR, 826=GBP, 36=AUD)
- Precision is 5 for all currencies (5 decimal places)

### 2.2 Instrument Linkage

**What**: Fiat currencies other than USD are linked to trading instruments.
**Columns Involved**: InstrumentId, FiatId
**Rules**:
- USD (FiatId=1) has InstrumentId = NULL (base currency, no instrument needed)
- EUR (FiatId=2) has InstrumentId = 1
- GBP (FiatId=3) has InstrumentId = 2
- AUD (FiatId=5) has InstrumentId = 7

### 2.3 Avatar URLs

**What**: Each currency has an S3-hosted avatar image for UI display.
**Columns Involved**: AvatarUrl
**Rules**:
- All URLs follow the pattern `https://etoro-production.s3.amazonaws.com/market-avatars/{name}/150x150.png`
- USD and AUD both use the "dollar" avatar; EUR uses "euro"; GBP uses "pound"

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP storage. For a 4-row table, distribution strategy is irrelevant. The table fits in a single data page.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Look up fiat currency name by ID | `SELECT FiatName FROM EXW_Wallet.FiatTypes WHERE FiatId = @id` |
| List all active fiat currencies | `SELECT * FROM EXW_Wallet.FiatTypes WHERE IsActive = 1` |
| Get ISO numeric code for a currency | `SELECT NumericCode FROM EXW_Wallet.FiatTypes WHERE FiatName = 'USD'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_C2F_E2E / EXW_C2P_E2E | `ON c.FiatCurrencyID = ft.FiatId` | Resolve fiat currency name for C2F/C2P transactions |
| CopyFromLake.WalletConversionDB_C2F_Conversions | `ON c.FiatId = ft.FiatId` | Lookup fiat currency in conversion pipeline |

### 3.4 Gotchas

- FiatId values are not contiguous: 1, 2, 3, 5 (no FiatId = 4)
- Id (row surrogate) and FiatId (business key) are different: Id is sequential 1-4, FiatId has the gap
- InstrumentId is NULL for USD — do not assume all rows have an instrument link
- etr_y, etr_ym, etr_ymd partition columns are all NULL — not populated for this table
- The table has only 4 rows; do not join expecting a comprehensive currency list (e.g., no JPY, CHF, etc.)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | ETL-computed or derived by pipeline |
| Tier 3 | Source identified but no upstream wiki available |
| Tier 4 | Inferred from name only (banned in this pipeline) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | int | YES | Surrogate row identifier in Synapse. Sequential 1-4 matching the order of fiat currency records. Not the business key — use FiatId for joins. (Tier 3 — WalletDB.Wallet.FiatTypes) |
| 2 | FiatId | int | YES | Internal wallet-system fiat currency identifier. Business key for this table. Values: 1=USD, 2=EUR, 3=GBP, 5=AUD (note: 4 is skipped). Used as join key in SP_EXW_C2F_E2E and downstream C2F/C2P tables. (Tier 3 — WalletDB.Wallet.FiatTypes) |
| 3 | FiatName | varchar(max) | YES | ISO 4217 alphabetic currency code. Values: USD, EUR, GBP, AUD. Resolved as `FiatCurrency` in EXW_C2F_E2E and EXW_C2P_E2E via JOIN on FiatId. (Tier 3 — WalletDB.Wallet.FiatTypes) |
| 4 | IsActive | bit | YES | Whether the fiat currency is currently active and available for wallet operations. All 4 currencies are currently True. (Tier 3 — WalletDB.Wallet.FiatTypes) |
| 5 | AvatarUrl | varchar(max) | YES | S3 URL for the currency avatar image used in UI display. Format: `https://etoro-production.s3.amazonaws.com/market-avatars/{name}/150x150.png`. (Tier 3 — WalletDB.Wallet.FiatTypes) |
| 6 | Precision | int | YES | Number of decimal places for currency amount formatting. Currently 5 for all fiat currencies in this table. (Tier 3 — WalletDB.Wallet.FiatTypes) |
| 7 | InstrumentId | int | YES | FK to trading instrument associated with this fiat currency. NULL for USD (base currency); 1=EUR, 2=GBP, 7=AUD. (Tier 3 — WalletDB.Wallet.FiatTypes) |
| 8 | NumericCode | int | YES | ISO 4217 numeric currency code. 840=USD, 978=EUR, 826=GBP, 36=AUD. Standard international code for electronic payment systems. (Tier 3 — WalletDB.Wallet.FiatTypes) |
| 9 | etr_y | varchar(max) | YES | Generic Pipeline ETL partition column for year. Not populated (NULL) for this table. (Tier 2 — Generic Pipeline) |
| 10 | etr_ym | varchar(max) | YES | Generic Pipeline ETL partition column for year-month. Not populated (NULL) for this table. (Tier 2 — Generic Pipeline) |
| 11 | etr_ymd | varchar(max) | YES | Generic Pipeline ETL partition column for year-month-day. Not populated (NULL) for this table. (Tier 2 — Generic Pipeline) |
| 12 | SynapseUpdateDate | datetime | YES | Timestamp of last Generic Pipeline refresh into Synapse. Set to GETDATE() at load time. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | WalletDB.Wallet.FiatTypes | Id | Passthrough |
| FiatId | WalletDB.Wallet.FiatTypes | FiatId | Passthrough |
| FiatName | WalletDB.Wallet.FiatTypes | FiatName | Passthrough |
| IsActive | WalletDB.Wallet.FiatTypes | IsActive | Passthrough |
| AvatarUrl | WalletDB.Wallet.FiatTypes | AvatarUrl | Passthrough |
| Precision | WalletDB.Wallet.FiatTypes | Precision | Passthrough |
| InstrumentId | WalletDB.Wallet.FiatTypes | InstrumentId | Passthrough |
| NumericCode | WalletDB.Wallet.FiatTypes | NumericCode | Passthrough |
| etr_y | Generic Pipeline | — | ETL partition year (not populated) |
| etr_ym | Generic Pipeline | — | ETL partition year-month (not populated) |
| etr_ymd | Generic Pipeline | — | ETL partition year-month-day (not populated) |
| SynapseUpdateDate | Generic Pipeline | — | GETDATE() at load time |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.FiatTypes (production, WalletDB)
  |-- Generic Pipeline (Bronze export, Override, daily) --|
  v
internal-sources@/Bronze/WalletDB/Wallet/FiatTypes (parquet)
  |-- Generic Pipeline (lake → Synapse, Override) --|
  v
EXW_Wallet.FiatTypes (4 rows, ROUND_ROBIN, HEAP)
  |-- Generic Pipeline (Bronze export, delta) --|
  v
wallet.bronze_walletdb_wallet_fiattypes (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| InstrumentId | Trading Instrument (inferred) | FK to trading instrument; NULL for USD |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---|---|---|
| FiatId | EXW_dbo.EXW_C2F_E2E | Fiat currency lookup in crypto-to-fiat E2E tracking |
| FiatId | EXW_dbo.EXW_C2P_E2E | Fiat currency lookup in crypto-to-position E2E tracking |

---

## 7. Sample Queries

### 7.1 List All Supported Fiat Currencies

```sql
SELECT FiatId, FiatName, NumericCode, IsActive, Precision
FROM EXW_Wallet.FiatTypes
ORDER BY FiatId;
```

### 7.2 Resolve Fiat Currency for C2F Conversions

```sql
SELECT c.C2FCorrelationID, c.FiatCurrencyID, ft.FiatName, ft.NumericCode
FROM EXW_dbo.EXW_C2F_E2E c
JOIN EXW_Wallet.FiatTypes ft ON c.FiatCurrencyID = ft.FiatId
WHERE c.ConversionDate >= '2026-01-01';
```

### 7.3 Check Instrument Linkage

```sql
SELECT ft.FiatId, ft.FiatName, ft.InstrumentId, ft.NumericCode
FROM EXW_Wallet.FiatTypes ft
WHERE ft.InstrumentId IS NOT NULL;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 0 T1, 4 T2, 8 T3, 0 T4, 0 T5 | Elements: 12/12, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.FiatTypes | Type: Table | Production Source: WalletDB.Wallet.FiatTypes (Generic Pipeline)*
