# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform

> 23.2M-row transaction-level MIMO (Money In / Money Out) fact table for the eMoney (IBAN) platform, tracking deposits and withdrawals from `eMoney_Fact_Transaction_Status` including internal transfers, crypto-to-fiat conversions, and first-time deposit flags. Assembled by `SP_DDR_Fact_MIMO_eMoney_Platform` with daily DELETE/INSERT by DateID, deduplication by TransactionID, and post-insert FTD recovery from `Dim_Customer`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `eMoney_dbo.eMoney_Fact_Transaction_Status` |
| **Refresh** | Daily (DELETE/INSERT by DateID) |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

This table is the **eMoney (IBAN) platform MIMO fact table** within the DDR (Daily Data Report) framework. Each row represents a single settled eMoney transaction — deposit or withdrawal — for a customer on a specific date. It answers: "What eMoney deposits and withdrawals settled for each customer today, at what amounts, and which was their first-time deposit?"

The eMoney platform handles IBAN-based financial transactions including:
- **Direct deposits** (TxTypeID = 7) — external money coming into the eMoney wallet
- **Internal transfers IN** (TxTypeID = 5) — funds moved from trading platform to eMoney
- **Crypto-to-fiat** (TxTypeID = 14) — crypto converted to fiat currency
- **Withdrawals** (TxTypeID = 8) — money out from eMoney to bank
- **Internal transfers OUT** (TxTypeID = 6) — funds moved from eMoney to trading platform

Data flows from `eMoney_Fact_Transaction_Status` (settled transactions only, `TxStatusID = 2`), enriched with FTD detection from `Dim_Customer` and currency resolution from `eMoney_Currency_Instrument_Mapping_Static` (deposits) or `Dim_Currency` (withdrawals).

The SP runs daily via Service Broker (`SB_Daily`). It was authored 2024-07-02, with key evolution: C2F support (2025-03-17), IsIBANQuickTransfer placeholder (2025-06-16), global FTD coalescing (2025-09-04), FTD recovery UPDATE (2025-10-23), currency mapping fix for Danish Krona (2025-12-23), and deduplication for symmetry with TP (2025-12-31).

---

## 2. Business Logic

### 2.1 Deposit Classification by TxTypeID

**What**: eMoney deposits are classified into three types based on transaction type

**Columns Involved**: `TxTypeID`, `IsInternalTransfer`, `IsCryptoToFiat`, `FundingTypeID`

**Rules**:
- TxTypeID = 7: External deposit → `IsInternalTransfer = 0`, `FundingTypeID = 0`
- TxTypeID = 5: Internal transfer from TP → `IsInternalTransfer = 1`, `FundingTypeID = 33`
- TxTypeID = 14: Crypto-to-fiat conversion → `IsCryptoToFiat = 1`, `FundingTypeID = 0`
- All three types can qualify as FTDs

### 2.2 First-Time Deposit Detection

**What**: Identifies the customer's first eMoney deposit using Dim_Customer as ground truth

**Columns Involved**: `IsFTD`

**Rules**:
- #FTDIBAN temp table: JOIN `eMoney_Fact_Transaction_Status` to `Dim_Customer` on `SourceCugTransactionID = FTDTransactionID` AND `FTDPlatformID = 3`
- Deposit matched to #FTDIBAN by TransactionID → `IsFTD = 1`
- Post-insert recovery UPDATE for DateID >= 20250901: re-matches transactions to `Dim_Customer` to catch late-arriving FTD data
- FTD amount is overridden with `Dim_Customer.FirstDepositAmount` via COALESCE

### 2.3 IBAN Trade Detection

**What**: Identifies eMoney-originated trades using reference number pattern

**Columns Involved**: `IsTradeFromIBAN`

**Rules**:
- `IsTradeFromIBAN = 1` when `LEFT(ReferenceNumber, 1) != 'P'` AND `TxStatusModificationDateID >= 20240403` AND `TxTypeID IN (5, 6)`
- Only applies to internal transfers (TxTypeID 5 for deposits, 6 for withdrawals)
- The 'P' prefix in ReferenceNumber indicates a platform-initiated transfer; non-'P' indicates an IBAN-initiated trade

### 2.4 Transaction Deduplication

**What**: Ensures no duplicate TransactionIDs in the output

**Columns Involved**: all

**Rules**:
- After UNION ALL of deposits + withdrawals, `ROW_NUMBER() OVER (PARTITION BY TransactionID ORDER BY TransactionID)` eliminates duplicates
- Only `RN = 1` is kept

### 2.5 Withdrawal Sign Convention

**What**: Withdrawal amounts are negated to indicate money out

**Columns Involved**: `AmountUSD`, `AmountOrigCurrency`

**Rules**:
- Withdrawals: `AmountUSD = -1 * USDAmountApprox`, `AmountOrigCurrency = -1 * LocalAmount`
- Deposits: positive values (original from source)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `RealCID` with a CLUSTERED COLUMNSTORE INDEX. Always include `RealCID` in WHERE or JOIN conditions for optimal distribution-aligned queries. With 23.2M rows, filter by `DateID` for time-bounded analysis.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's eMoney transaction history | `WHERE RealCID = @cid ORDER BY DateID` |
| Daily eMoney FTD count | `WHERE IsFTD = 1 AND MIMOAction = 'Deposit' GROUP BY DateID` |
| Internal transfer volume | `WHERE IsInternalTransfer = 1 GROUP BY DateID, MIMOAction` |
| C2F conversion trends | `WHERE IsCryptoToFiat = 1 GROUP BY DateID` — SUM `AmountUSD` |
| Net eMoney flow per day | `GROUP BY DateID` — SUM `AmountUSD` (deposits positive, withdrawals negative) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Customer` | `ON m.RealCID = dc.RealCID` | Customer demographics, registration |
| `DWH_dbo.Dim_Currency` | `ON m.CurrencyID = dc.CurrencyID` | Full currency details |
| `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms` | `ON m.TransactionID = ap.TransactionID AND ap.MIMOPlatform = 'eMoney'` | Unified view with global FTD flags |

### 3.4 Gotchas

- **23.2M rows** — filter by `DateID` for efficient queries.
- **Withdrawal amounts are negative** — `AmountUSD` and `AmountOrigCurrency` are negated for withdrawals. Net flow = SUM(AmountUSD).
- **IsFTD is platform-level only** — for global (cross-platform) FTD, use `BI_DB_DDR_Fact_MIMO_AllPlatforms.IsGlobalFTD`.
- **IsRedeem always 0** — column exists for schema compatibility with AllPlatforms union but is never populated.
- **IsRecurring always 0** — placeholder for future use; eMoney does not yet track recurring deposits.
- **IsIBANQuickTransfer always 0** — despite being added for the MoveMoneyReasonID=6 feature, it is hardcoded to 0 in this SP (populated at AllPlatforms level or not yet wired).
- **FundingTypeID values** — only 0 (external) and 33 (internal) are used; this is not the same granularity as TP FundingTypeIDs.
- **CurrencyID join path differs** — deposits use `eMoney_Currency_Instrument_Mapping_Static` (ISO-based), withdrawals use `Dim_Currency` (abbreviation-based). Danish Krona was lost in old mapping; fixed 2025-12-23.
- **TransactionID = -1 sentinel** — ISNULL coercion replaces NULL TransactionIDs with -1.
- **Date range starts 2020-11-10** — eMoney launched later than Trading Platform; no data before this date.
- **TxTypeID 8 = trade open** — included in withdrawals but is actually a trading action; may be removed in future.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — ...)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Date key in YYYYMMDD integer format. `CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)` from SP parameter. DELETE/INSERT partition key. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 2 | Date | date | YES | Calendar date. `@date` SP input parameter. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 3 | RealCID | int | YES | Customer identifier. Renamed from `eMoney_Fact_Transaction_Status.CID`. Distribution key. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 4 | MIMOAction | varchar(20) | YES | Transaction direction. Literal `'Deposit'` for deposits, `'Withdraw'` for withdrawals. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 5 | OrigIdentifier | varchar(20) | YES | Source ID type label. Always `'TransactionID'` for all eMoney transactions. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 6 | TransactionID | int | YES | eMoney transaction identifier from `eMoney_Fact_Transaction_Status.TransactionID`. `ISNULL(..., -1)` — sentinel -1 for NULLs. Used for deduplication and FTD matching. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 7 | ReferenceNumber | varchar(4000) | YES | Payment gateway reference string from `eMoney_Fact_Transaction_Status.ReferenceNumber`. `ISNULL(..., -1)`. First character used for IBAN trade detection ('P' prefix = platform-initiated). (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 8 | AmountUSD | decimal(16,6) | YES | Transaction amount in USD. `mfts.USDAmountApprox` for deposits (positive); `-1 * mfts.USDAmountApprox` for withdrawals (negative). FTD deposits overridden with `Dim_Customer.FirstDepositAmount`. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 9 | AmountOrigCurrency | decimal(16,6) | YES | Transaction amount in original currency. `mfts.LocalAmount` for deposits (positive); `-1 * mfts.LocalAmount` for withdrawals (negative). (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 10 | FundingTypeID | int | YES | Payment method type. `CASE WHEN TxTypeID IN (5) THEN 33 ELSE 0 END` (deposits) / `CASE WHEN TxTypeID IN (6) THEN 33 ELSE 0 END` (withdrawals). 33 = internal transfer, 0 = external. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 11 | CurrencyID | int | YES | Currency identifier. Deposits: `eMoney_Currency_Instrument_Mapping_Static.SellCurrencyID` via ISO match. Withdrawals: `Dim_Currency.CurrencyID` via abbreviation match. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 12 | Currency | varchar(20) | YES | Currency ISO code. Direct from `eMoney_Fact_Transaction_Status.HolderCurrencyDesc`. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 13 | IsFTD | int | YES | Platform-level first-time deposit flag. `CASE WHEN f.TransactionID IS NOT NULL THEN 1 ELSE 0 END` from #FTDIBAN match; `ISNULL(..., 0)`. Updated by FTD recovery for DateID >= 20250901. 645K deposits flagged out of 11.7M. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 14 | IsInternalTransfer | int | YES | Internal fund transfer flag. `CASE WHEN TxTypeID IN (5) THEN 1 ELSE 0 END` (deposits) / `... IN (6) ...` (withdrawals). `ISNULL(..., 0)`. 1 = transfer between eMoney and trading platform. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 15 | IsRedeem | int | YES | Redemption flag. Always `ISNULL(NULL, 0) = 0`. Placeholder for schema compatibility with AllPlatforms union; never populated. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 16 | TxTypeID | int | YES | eMoney transaction type. Direct from `eMoney_Fact_Transaction_Status.TxTypeID`. Values: 5=internal deposit, 6=internal withdrawal, 7=external deposit, 8=trade open withdrawal, 14=crypto-to-fiat. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 17 | IsTradeFromIBAN | int | YES | IBAN-initiated trade flag. `CASE WHEN LEFT(ReferenceNumber,1) != 'P' AND TxStatusModificationDateID >= 20240403 AND TxTypeID IN (5,6) THEN 1 ELSE 0 END`. `ISNULL(..., 0)`. Non-'P' reference = IBAN-originated. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 18 | UpdateDate | datetime | YES | ETL load timestamp. `GETDATE()` at SP execution time. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 19 | IsCryptoToFiat | int | YES | Crypto-to-fiat flag. `CASE WHEN TxTypeID IN (14) THEN 1 ELSE 0 END` (deposits); hardcoded `0` (withdrawals). `ISNULL(..., 0)`. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 20 | IsRecurring | int | YES | Recurring deposit flag. Hardcoded `0`. Placeholder for schema compatibility; eMoney does not track recurring deposits. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 21 | IsIBANQuickTransfer | int | YES | eMoney internal transfer (MoveMoneyReasonID = 6) flag. Hardcoded `0` in this SP. Feature exists but is wired at AllPlatforms level. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RealCID | eMoney_Fact_Transaction_Status | CID | rename |
| TransactionID | eMoney_Fact_Transaction_Status | TransactionID | passthrough + ISNULL(-1) |
| ReferenceNumber | eMoney_Fact_Transaction_Status | ReferenceNumber | passthrough + ISNULL(-1) |
| AmountUSD | eMoney_Fact_Transaction_Status | USDAmountApprox | rename; negated for withdrawals |
| AmountOrigCurrency | eMoney_Fact_Transaction_Status | LocalAmount | rename; negated for withdrawals |
| CurrencyID | eMoney_Currency_Instrument_Mapping_Static / Dim_Currency | SellCurrencyID / CurrencyID | join-enriched (different path per action) |
| Currency | eMoney_Fact_Transaction_Status | HolderCurrencyDesc | passthrough |
| IsFTD | eMoney_Fact_Transaction_Status + Dim_Customer | TransactionID + FTDTransactionID | CASE match + recovery UPDATE |
| TxTypeID | eMoney_Fact_Transaction_Status | TxTypeID | passthrough |
| IsTradeFromIBAN | eMoney_Fact_Transaction_Status | ReferenceNumber + TxTypeID | CASE LEFT(...) pattern |

### 5.2 ETL Pipeline

```
eMoney_dbo.eMoney_Fact_Transaction_Status (settled transactions: TxStatusID=2)
  + DWH_dbo.Dim_Customer (FTD reference: FTDPlatformID=3)
  + eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static (deposit currency ID)
  + DWH_dbo.Dim_Currency (withdrawal currency ID)
  |
  |-- SP_DDR_Fact_MIMO_eMoney_Platform(@date):
  |     #FTDIBAN: FTD deposits matched to Dim_Customer
  |     #depositsIBAN: TxTypeID IN (7,5,14), enriched with FTD flag + currency
  |     UPDATE: FTD amount from Dim_Customer
  |     #cashoutIBAN: TxTypeID IN (8,6), amounts negated
  |     UNION ALL → dedupe by TransactionID
  |     DELETE/INSERT by DateID
  |     FTD recovery UPDATE (DateID >= 20250901)
  v
BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform (23.2M rows, transaction-level grain)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | eMoney_Fact_Transaction_Status | Settled IBAN transactions (TxStatusID = 2) |
| FTD Ref | Dim_Customer | FTD matching via FTDTransactionID + FTDPlatformID = 3 |
| Currency | eMoney_Currency_Instrument_Mapping_Static / Dim_Currency | Currency ID resolution |
| ETL | SP_DDR_Fact_MIMO_eMoney_Platform | Deposit+withdrawal extraction, FTD flagging, dedup, DELETE/INSERT |
| Target | BI_DB_DDR_Fact_MIMO_eMoney_Platform | eMoney platform MIMO fact |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |
| CurrencyID | DWH_dbo.Dim_Currency | Currency details |
| TxTypeID | eMoney_dbo.Dim_TxType (implicit) | Transaction type name |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms | #IBAN_Mimo | Read as eMoney branch of AllPlatforms union |
| BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | — | Unified MIMO table consumes this as source |

---

## 7. Sample Queries

### 7.1 Daily eMoney deposit volume

```sql
SELECT DateID,
       COUNT(*) AS TxCount,
       SUM(AmountUSD) AS TotalUSD,
       SUM(CASE WHEN IsFTD = 1 THEN 1 ELSE 0 END) AS FTDs
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
WHERE MIMOAction = 'Deposit'
  AND DateID BETWEEN 20260301 AND 20260309
GROUP BY DateID
ORDER BY DateID;
```

### 7.2 Internal vs external transfers

```sql
SELECT DateID,
       IsInternalTransfer,
       MIMOAction,
       COUNT(*) AS TxCount,
       SUM(AmountUSD) AS TotalUSD
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
WHERE DateID = 20260309
GROUP BY DateID, IsInternalTransfer, MIMOAction
ORDER BY IsInternalTransfer, MIMOAction;
```

### 7.3 Crypto-to-fiat conversion analysis

```sql
SELECT DateID,
       COUNT(*) AS C2F_Count,
       SUM(AmountUSD) AS C2F_USD
FROM BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
WHERE IsCryptoToFiat = 1
  AND DateID BETWEEN 20260101 AND 20260309
GROUP BY DateID
ORDER BY DateID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-26 | Quality: 8.5/10 (★★★★☆) | Phases: 14/14*
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform | Type: Table | Production Source: eMoney_Fact_Transaction_Status + Dim_Customer*
