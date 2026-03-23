# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform

> Daily granular fact for **Money-In / Money-Out (MIMO)** on the **eMoney** (electronic money) platform: IBAN-related deposits and withdrawals settled on the run date, including internal transfers and crypto-to-fiat deposit flows. One row per eMoney transaction after deduplication; feeds the cross-platform DDR MIMO rollup.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — daily transaction grain) |
| **Production Source** | eMoney: `eMoney_dbo.eMoney_Fact_Transaction_Status` (+ currency mapping, `DWH_dbo.Dim_Customer` for FTD) |
| **Refresh** | Daily — `DELETE WHERE DateID = @dateID` + `INSERT` via `SP_DDR_Fact_MIMO_eMoney_Platform @date` |
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

`BI_DB_DDR_Fact_MIMO_eMoney_Platform` is the **DDR (deposits / withdrawals reporting) tier-1 fact** for eMoney **MIMO** activity: money moving in or out of the eMoney / IBAN context, distinct from the main **trading platform** MIMO fact (`BI_DB_DDR_Fact_MIMO_Trading_Platform`). Rows represent **settled** eMoney transactions whose status modification date equals the batch date.

The procedure header describes the scope as **daily IBAN deposits and withdrawals including internal deposits to/from IBAN**. **MIMO** = Money In, Money Out; **eMoney** = eToro’s electronic money platform. **FTD** here is **first-time deposit on the eMoney platform** (aligned with `Dim_Customer.FTDPlatformID = 3` in FTD helper logic), not the “all platforms” global FTD label (that layering lives in `SP_DDR_Fact_Fact_MIMO_AllPlatforms`).

**TxTypeID** values are **eMoney transaction type codes**; the SP filters deposits to `TxTypeID IN (7, 5, 14)` and withdrawals to `IN (8, 6)`. Type **14** is treated as **crypto-to-fiat (C2F)** on the deposit side (`IsCryptoToFiat`). Type **8** is included on the withdraw path; the author notes it may represent **trade-open** flows that are not strictly MIMO and could be reclassified later.

**ReferenceNumber** holds the external payment reference (source column is large `varchar`); the ETL may coerce nulls to a sentinel for merge keys.

Created 2024-07-02 (Guy Manova), with ongoing FTD, currency mapping, and dedupe enhancements per change history in the SP.

---

## 2. Business Logic

### 2.1 Inclusion and grain

**What**: One logical transaction per `TransactionID` after deduplication for the batch date.

**Columns involved**: `DateID`, `Date`, `TransactionID`, `MIMOAction`

**Rules**:
- Only **settled** rows: `TxStatusID = 2` on `eMoney_Fact_Transaction_Status`.
- Grain date = **`TxStatusModificationDateID`** = `@dateID` (YYYYMMDD int from `@date`).
- **Deposits** → `MIMOAction = 'Deposit'`; **withdrawals** → `MIMOAction = 'Withdraw'`.
- **Dedupe**: `ROW_NUMBER() OVER (PARTITION BY TransactionID …)` keeps one row per `TransactionID` in the union of deposits and cashouts.

### 2.2 Amounts and direction

**What**: USD and local-currency amounts with correct sign for in/out flow.

**Columns involved**: `AmountUSD`, `AmountOrigCurrency`

**Rules**:
- Deposits: amounts from `USDAmountApprox` / `LocalAmount` (positive).
- Withdrawals: amounts multiplied by **-1** (money out).
- **FTD amount alignment**: After building deposits, an **UPDATE** joins to `#FTDIBAN` to set `AmountUSD` to the FTD row’s `USDAmountApprox` where the transaction is the platform FTD transaction.

### 2.3 First-time deposit (eMoney)

**What**: Whether the row is the customer’s **eMoney FTD** and alignment with **global** FTD in `Dim_Customer`.

**Columns involved**: `IsFTD`, `AmountUSD` (indirectly), `RealCID`, `TransactionID`

**Rules**:
- `#FTDIBAN` identifies FTD candidates (eMoney TxTypes **7 and 14**, settled) and joins `Dim_Customer` where `FTDTransactionID` matches `SourceCugTransactionID` and **`FTDPlatformID = 3`**.
- Deposits left-join this to set **`IsFTD = 1`** when the transaction matches.
- **Post-insert UPDATE** (for `DateID >= 20250901`): Sets `IsFTD = 1` for qualifying **Deposit** rows where `Dim_Customer` links global FTD (`SourceCugTransactionID` cast to string vs `FTDTransactionID`) even when the row was not flagged initially—covers **late-arriving** Dim_Customer FTD data.

### 2.4 Internal transfer, funding type, and IBAN trade flags

**What**: Flags for internal eMoney movements and “trade from IBAN” style flows.

**Columns involved**: `IsInternalTransfer`, `FundingTypeID`, `IsTradeFromIBAN`, `TxTypeID`

**Rules**:
- **Internal transfer**: `IsInternalTransfer = 1` when deposit `TxTypeID = 5` or withdraw `TxTypeID = 6`; **`FundingTypeID = 33`** in those cases, else **0** (DDR coding convention).
- **IsTradeFromIBAN**: **1** when `LEFT(ReferenceNumber,1) <> 'P'`, `TxStatusModificationDateID >= 20240403`, and (deposit with `TxTypeID = 5` or withdraw with `TxTypeID = 6`); else **0**.

### 2.5 Crypto-to-fiat and placeholder columns

**What**: C2F identification and columns reserved for the AllPlatforms union.

**Columns involved**: `IsCryptoToFiat`, `IsRecurring`, `IsIBANQuickTransfer`, `IsRedeem`

**Rules**:
- **`IsCryptoToFiat`**: **1** for deposit rows with `TxTypeID = 14`; withdraw branch sets **0**.
- **`IsRecurring`**, **`IsIBANQuickTransfer`**: Loaded as **0** in this SP; author notes **`IsRecurring`** is meaningless on this slice for now; **`IsIBANQuickTransfer`** is driven elsewhere for the unified AllPlatforms model.
- **`IsRedeem`**: Not populated from eMoney logic in this SP (stored as **0** after `ISNULL`).

---

## 3. Query Advisory

### 3.1 Synapse distribution and index

**HASH(RealCID)**: Co-locates rows for the same customer for joins to customer-scoped dimensions and aggregations by `RealCID`.

**CLUSTERED COLUMNSTORE INDEX**: Favour large scans and aggregates by date / customer; typical filters should still include **`DateID`** (partition of the daily load) to limit scans.

### 3.1b UC (Databricks) storage and partitioning

_Pending — resolved during write-objects._

### 3.2 Common JOINs

| Join to | Join condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Customer | `RealCID` = `RealCID` | Customer attributes, FTD context |
| DWH_dbo.Dim_Date | `DateID` | Calendar attributes |
| DWH_dbo.Dim_Currency | `CurrencyID` | Currency metadata (when ID present) |

### 3.3 Gotchas

- **Withdraw vs deposit currency joins differ**: Deposits use **`eMoney_Currency_Instrument_Mapping_Static`** on **ISO**; withdrawals join **`Dim_Currency`** on **`HolderCurrencyDesc = Abbreviation`** — inconsistent paths are intentional in the SP but matter for reconciliation.
- **TxType 8 on withdraws**: May include non-MIMO **trade-open** traffic; treat aggregates as “as implemented” until product reclassifies.
- **ReferenceNumber / TransactionID sentinels**: `ISNULL` on keys is for **lake merge** safety — do not assume raw NULLs in downstream.
- **Dedupe**: If upstream sends duplicate `TransactionID` within the union, only one row survives—volume should match post-dedupe logic.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| ★ | Tier 4 — Inferred | (Tier 4 — [UNVERIFIED]) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NULL | Batch date as YYYYMMDD from `TxStatusModificationDateID` filter. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 2 | Date | date | NULL | Calendar date parameter `@date` for the run. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 3 | RealCID | int | NULL | Real customer ID (`CID` from eMoney fact). Distribution key. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 4 | MIMOAction | varchar(20) | NULL | `Deposit` or `Withdraw`. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 5 | OrigIdentifier | varchar(20) | NULL | Source key type label — constant `TransactionID`. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 6 | TransactionID | int | NULL | eMoney transaction id; `ISNULL` to -1 in insert for merge keys. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 7 | ReferenceNumber | varchar(4000) | NULL | External payment / bank reference from eMoney; `ISNULL` to -1 in insert. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 8 | AmountUSD | decimal(16,6) | NULL | USD amount; sign by direction; may be overridden for FTD deposit from `#FTDIBAN`. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 9 | AmountOrigCurrency | decimal(16,6) | NULL | Local amount; sign by direction. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 10 | FundingTypeID | int | NULL | `33` for internal-transfer TxTypes (5/6), else `0`. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 11 | CurrencyID | int | NULL | Resolved via ISO mapping (deposits) or Dim_Currency abbreviation (withdraws). (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 12 | Currency | varchar(20) | NULL | `HolderCurrencyDesc` from eMoney fact. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 13 | IsFTD | int | NULL | 1 if eMoney FTD for this transaction / recovered via Dim_Customer update. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 14 | IsInternalTransfer | int | NULL | 1 for internal transfer TxTypes (5 deposit, 6 withdraw). (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 15 | IsRedeem | int | NULL | Not sourced from eMoney logic in this SP — stored 0. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 16 | TxTypeID | int | NULL | eMoney transaction type id; deposit set {7,5,14}, withdraw {8,6}. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 17 | IsTradeFromIBAN | int | NULL | Trade-from-IBAN style flow per ReferenceNumber prefix and date rule. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 18 | UpdateDate | datetime | NULL | ETL load timestamp `GETDATE()` on insert. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 19 | IsCryptoToFiat | int | NULL | 1 when deposit `TxTypeID = 14`. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 20 | IsRecurring | int | NULL | Hardcoded 0 in this SP (placeholder for AllPlatforms). (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 21 | IsIBANQuickTransfer | int | NULL | Hardcoded 0 in this SP; named differently from TP “internal transfer”. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |

---

## 5. Lineage

### 5.1 Pipeline

See **`BI_DB_DDR_Fact_MIMO_eMoney_Platform.lineage.md`** for full column mapping and consumer list.

```
eMoney_dbo.eMoney_Fact_Transaction_Status
  → SP_DDR_Fact_MIMO_eMoney_Platform(@date)
      ├─ DELETE WHERE DateID = @dateID
      └─ INSERT + post-UPDATE IsFTD (Dim_Customer)
```

### 5.2 Key source tables

| Source | Role |
|--------|------|
| eMoney_dbo.eMoney_Fact_Transaction_Status | Primary transactional source |
| eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static | Deposit-side currency id |
| DWH_dbo.Dim_Currency | Withdraw-side currency id |
| DWH_dbo.Dim_Customer | eMoney FTD (platform 3) and recovery update |

---

## 6. Relationships

### 6.1 References to (this object points to)

| Target object | Join column | Description |
|---------------|-------------|-------------|
| DWH_dbo.Dim_Customer | RealCID | Customer / FTD context |
| DWH_dbo.Dim_Date | DateID | Calendar |
| DWH_dbo.Dim_Currency | CurrencyID | Currency (when joined on id) |

### 6.2 Referenced by (other objects point to this)

| Source object | Description |
|---------------|-------------|
| SP_DDR_Fact_Fact_MIMO_AllPlatforms | Pulls eMoney rows for `DateID` into unified MIMO fact |
| SP_DDR_Process_Monitor | DDR monitoring |

---

## 7. Sample Queries

### 7.1 Daily deposit vs withdraw totals (USD)

```sql
SELECT  MIMOAction,
        SUM(AmountUSD) AS TotalUSD,
        COUNT(*)        AS TxnCount
FROM    [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_eMoney_Platform]
WHERE   DateID = 20260320
GROUP BY MIMOAction;
```

### 7.2 eMoney FTD deposits for a date

```sql
SELECT  RealCID, TransactionID, AmountUSD, TxTypeID, IsCryptoToFiat
FROM    [BI_DB_dbo].[BI_DB_DDR_Fact_MIMO_eMoney_Platform]
WHERE   DateID = 20260320
  AND   MIMOAction = 'Deposit'
  AND   IsFTD = 1;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| _None populated in this pass_ | — | Run Phase 10 scan to attach eMoney / DDR Confluence links |

---

*Generated: 2026-03-23 | Quality: draft | Primary evidence: SP_DDR_Fact_MIMO_eMoney_Platform.sql (DataPlatform repo)*  
*Object: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform | Type: Table | Writer: SP_DDR_Fact_MIMO_eMoney_Platform*
