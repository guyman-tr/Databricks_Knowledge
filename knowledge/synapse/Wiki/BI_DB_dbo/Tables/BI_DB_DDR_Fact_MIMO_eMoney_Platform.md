# BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform

> ~25.1M-row DDR MIMO fact at **eMoney / IBAN fiat transaction** grain (one row per settled `TransactionID` per day slice). Date span from live data **2020-11-10** through **2026-04-25**; daily `DELETE WHERE DateID=@dateID` + `INSERT` via `SP_DDR_Fact_MIMO_eMoney_Platform`. Fed from `eMoney_Fact_Transaction_Status` (not `Fact_CustomerAction`). Unions with `BI_DB_DDR_Fact_MIMO_Trading_Platform` inside `SP_DDR_Fact_Fact_MIMO_AllPlatforms`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact) |
| **Production Source** | Upstream eToro Money facts in Synapse: `eMoney_dbo.eMoney_Fact_Transaction_Status` (FiatDwhDB lineage per eMoney wiki); FTD joins `DWH_dbo.Dim_Customer` |
| **Refresh** | Daily (parameter `@date`); idempotent delete/insert for single `DateID` |
| **Synapse Distribution** | `HASH(RealCID)` |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **Row Count** | ~25,131,569 (`sys.partitions` rollup, 2026-05-14) |
| **UC Target** | **Not verified in Unity Catalog** — `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform` **missing** on sampled workspace; `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` **present**. Confirm export name with data-platform mapping. |
| **UC Format** | delta (when exported) |
| **UC Partitioned By** | None |

---

## 1. Business Meaning

This table is the **eMoney-platform sibling** of `BI_DB_DDR_Fact_MIMO_Trading_Platform`: both land in `BI_DB_DDR_Fact_MIMO_AllPlatforms` with identical column order. Where the trading table reads **billing + `Fact_CustomerAction`**, this table reads **settled eMoney ledger rows** filtered on `TxStatusID = 2` and a fixed `TxTypeID` allow-list (deposits vs withdrawals use different lists — see §2.1).

Business scope (per SP header): **IBAN-linked deposits and withdrawals** on eToro Money, including **internal transfer** types (`TxTypeID` 5 inbound, 6 outbound) that set `FundingTypeID = 33` and `IsInternalTransfer = 1`. The SP author notes `TxTypeID = 8` **Payment** withdraw rows are **trade open** events on the fiat side and “may be removed” from DDR MIMO later — they remain in the withdrawal allow-list today (`TxTypeID IN (8,6)`).

**Grain**: one output row per surviving `TransactionID` after `ROW_NUMBER()` dedupe (`PARTITION BY TransactionID`).

---

## 2. Business Logic

### 2.1 Settled rows & TxType allow-lists (verbatim predicates)

**What**: Only **settled** eMoney status rows on the **status modification business date** `@date` drive the fact.

**Columns Involved**: `DateID`, `TxTypeID`, `MIMOAction`, `AmountUSD`, `AmountOrigCurrency`, `FundingTypeID`, `IsInternalTransfer`, `IsCryptoToFiat`, `IsTradeFromIBAN`.

**Rules** (from `SP_DDR_Fact_MIMO_eMoney_Platform`):

- Global date key: `@dateID int = CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)`.
- **#FTDIBAN** pulls first-time-deposit candidates from `eMoney_Fact_Transaction_Status mfts`:
  - `WHERE mfts.TxStatusID = 2` **and** `mfts.TxTypeID IN (7,14)`
  - Join `DWH_dbo.Dim_Customer dc1 ON dc1.FTDTransactionID = mfts.SourceCugTransactionID AND dc1.FTDPlatformID = 3`.
- **#depositsIBAN** (`MIMOAction = 'Deposit'`):
  - `WHERE mfts.TxStatusModificationDateID = @dateID AND mfts.TxStatusID = 2 AND mfts.TxTypeID IN (7,5,14)`
- **#cashoutIBAN** (`MIMOAction = 'Withdraw'`):
  - `WHERE mfts.TxStatusModificationDateID = @dateID AND mfts.TxStatusID = 2 AND mfts.TxTypeID IN (8,6)`
- **Sign convention**: withdrawals multiply `USDAmountApprox` / `LocalAmount` by `-1` in `#cashoutIBAN`; deposits remain positive (before FTD amount override UPDATE).

### 2.2 `FundingTypeID` = 33 on internal-transfer TxTypes

**What**: When eMoney TxType denotes internal transfer, the SP emits **DDR funding type code 33** (aligns numeric hook used on TP DDR for internal-transfer channeling — decode names via `DWH_dbo.Dim_FundingType`).

**Columns Involved**: `FundingTypeID`, `TxTypeID`, `MIMOAction`.

**Rules**:
- Deposit leg: `CASE WHEN mfts.TxTypeID IN (5) THEN 33 ELSE 0 END`
- Withdraw leg: `CASE WHEN mfts.TxTypeID IN (6) THEN 33 ELSE 0 END`

### 2.3 `IsInternalTransfer` (eMoney semantics — **not** TP `FundingTypeID=33` CASE)

**What**: On this table, internal transfer is **directly** the eMoney TxType allow-list above — **not** the trading-platform `CASE WHEN FundingTypeID = 33` pattern used in `SP_DDR_Fact_MIMO_Trading_Platform`.

**Columns Involved**: `IsInternalTransfer`, `TxTypeID`.

**Rules**:
- Deposits: `CASE WHEN mfts.TxTypeID IN (5) THEN 1 ELSE 0 END`
- Withdrawals: `CASE WHEN mfts.TxTypeID IN (6) THEN 1 ELSE 0 END`
- INSERT applies `ISNULL(i.IsInternalTransfer,0)`

### 2.4 `IsRedeem` — schema parity only (NOT transfercoin; NOT bank redeem)

**What**: `IsRedeem` on **this** fact is **not** sourced from `Fact_CustomerAction` and does **not** carry **transfer-to-coin / transfercoin** semantics documented for trading MIMO (`BI_DB_DDR_Fact_MIMO_Trading_Platform` §2.3) or the **dual-semantics `IsRedeem`** narrative in `Fact_CustomerAction.md`.

**Columns Involved**: `IsRedeem`.

**Rules**:
- `#depositsIBAN` and `#cashoutIBAN` each set `NULL AS IsRedeem`.
- Final INSERT: `ISNULL(i.IsRedeem, 0)` → persisted **always 0** (verified on `DateID >= 20260101`: 6,211,305 rows, all `IsRedeem=0`).
- **Do not** explain this column as “eMoney balance redeemed to bank account” (legacy AllPlatforms-era wording conflicts with authoritative `Fact_CustomerAction` semantics and misstates this SP).

### 2.5 `IsCryptoToFiat` — deposit leg only (`TxTypeID = 14`)

**What**: Flags crypto-to-fiat deposit rows using the **eMoney TxType dictionary** (`TxTypeID = 14` per `eMoney_Fact_Transaction_Status` wiki).

**Columns Involved**: `IsCryptoToFiat`, `TxTypeID`, `MIMOAction`.

**Rules**:
- Deposit leg: `CASE WHEN mfts.TxTypeID IN (14) THEN 1 ELSE 0 END`
- Withdraw leg: `0 AS IsCryptoToFiat`
- INSERT: `ISNULL(IsCryptoToFiat,0)`
- Distribution check (`DateID>=20260101`): `IsCryptoToFiat=1` on **5,327** rows vs **6,205,978** zeros — aligns with **`TxTypeID=14`** volume (same window).

### 2.6 `IsTradeFromIBAN` — reference guard + TxType split

**What**: IBAN-originated **internal transfer** discriminator using **reference prefix** and effective date floor.

**Columns Involved**: `ReferenceNumber`, `TxStatusModificationDateID`, `TxTypeID`.

**Rules** (verbatim `CASE`):
- Deposits: `case when left(ReferenceNumber,1) != 'P' and TxStatusModificationDateID >= 20240403 and TxTypeID = 5 then 1 else 0 end`
- Withdrawals: `case when left(ReferenceNumber,1) != 'P' and TxStatusModificationDateID >= 20240403 and TxTypeID = 6 then 1 else 0 end`
- INSERT: `ISNULL(i.IsTradeFromIBAN,0)`

### 2.7 Platform FTD linkage & late recovery UPDATE

**What**: Deposit-side FTD uses `#FTDIBAN` keyed to `Dim_Customer` global FTD transaction (`FTDPlatformID = 3`). Additional **post-insert UPDATE** lifts `IsFTD` when Dim_Customer links catch up (`DateID >= 20250901`).

**Columns Involved**: `IsFTD`, `RealCID`, `TransactionID`.

**Rules** (see SP block comment “recovered FTDs”): `UPDATE` sets `IsFTD = 1` where join matches `Dim_Customer.FTDTransactionID` to `SourceCugTransactionID` (`CAST` to `varchar`) for deposit rows previously `IsFTD=0`.

### 2.8 `IsRecurring` and `IsIBANQuickTransfer` placeholders

**What**: Columns exist for UNION symmetry with TP / AllPlatforms schemas.

**Columns Involved**: `IsRecurring`, `IsIBANQuickTransfer`.

**Rules**:
- INSERT selects **literal** `0 AS IsRecurring` and **`0 AS IsIBANQuickTransfer`** regardless of `#MIMOIBAN` content — **all** rows `DateID>=20260101` show `IsIBANQuickTransfer=0`.
- SP change log cites **MoveMoneyReason = 6** / “Internal Transfer in emoney”; **body does not reference `MoveMoneyReasonID`** — treat quick-transfer tagging as **unimplemented drift** pending SP fix.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

`HASH(RealCID)` — join/filter on `RealCID` for colocation; avoid heavy `REFERENCE_NUMBER LIKE` predicates without `DateID` guard.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| eMoney deposits only | `WHERE MIMOAction='Deposit'` + `DateID` range |
| Internal transfers only | `WHERE IsInternalTransfer=1` (= TxType 5 deposit / 6 withdraw per §2.3) |
| Crypto→fiat ingress | `WHERE IsCryptoToFiat=1` (deposit `TxTypeID=14`) |
| IBAN-trade style internals | `WHERE IsTradeFromIBAN=1` |
| Exclude trade-open noise | Consider `WHERE NOT (MIMOAction='Withdraw' AND TxTypeID=8)` if product agrees |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| `DWH_dbo.Dim_Customer` | `RealCID = RealCID` | Customer attributes |
| `DWH_dbo.Dim_FundingType` | `FundingTypeID = FundingTypeID` | Decode 0 vs 33 |
| `BI_DB_DDR_Fact_MIMO_AllPlatforms` | unioned downstream | Multi-platform KPIs |

### 3.4 Gotchas

- **`IsRedeem` always 0** — do not use for redemption analytics; trading transfercoin semantics live on TP / `Fact_CustomerAction`.
- **`IsIBANQuickTransfer` always 0** despite column presence + SP header note — reconcile with DA before trusting AllPlatforms excerpts that mention MoveMoneyReasonID=6 for eMoney.
- **`ReferenceNumber` nulls** become **`-1`** on INSERT (`ISNULL(i.ReferenceNumber, -1)`).
- **`TransactionID` nulls** become **`-1`** on INSERT — treat as sentinel, not numeric FK.
- **Withdraw `TxTypeID=8`** includes non–pure-MIMO flows per author comment — trend lines may shift if removed.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Inherited verbatim / same origin as canonical DWH dimension wiki |
| Tier 2 | Grounded in `SP_DDR_Fact_MIMO_eMoney_Platform` + eMoney fact wiki |
| Tier 3 | Name / light inference only |
| Tier 4 | Known doc/ETL drift — needs owner confirmation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Business partition key for daily reload. `CAST(CONVERT(VARCHAR(8),@date,112) AS INT)` seeded into both deposit/withdraw temp sets; `DELETE` targets the same key. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 2 | Date | date | YES | Calendar date parameter `@date` materialized on insert. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 3 | RealCID | int | YES | Global Real Customer Identifier on the ledger row (`mfts.CID` aliased as `RealCID`). (Tier 1 — Customer.CustomerStatic) |
| 4 | MIMOAction | varchar(20) | YES | `'Deposit'` from `#depositsIBAN` or `'Withdraw'` from `#cashoutIBAN`. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 5 | OrigIdentifier | varchar(20) | YES | Literal discriminator `'TransactionID'` for DDR grain labeling. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 6 | TransactionID | int | YES | eMoney `TransactionID` with INSERT coercion `ISNULL(i.TransactionID, -1)`. (Tier 2 — eMoney_Fact_Transaction_Status) |
| 7 | ReferenceNumber | varchar(4000) | YES | Provider / bank reference from `mfts.ReferenceNumber`; INSERT coerces NULL to `-1`. (Tier 2 — eMoney_Fact_Transaction_Status) |
| 8 | AmountUSD | decimal(16,6) | YES | `USDAmountApprox` (deposits positive; withdraw leg multiplied by `-1`); FTD rows may take `USDAmountApprox` from `#FTDIBAN` via `UPDATE`. (Tier 2 — eMoney_Fact_Transaction_Status) |
| 9 | AmountOrigCurrency | decimal(16,6) | YES | `LocalAmount` with the same sign rule as `AmountUSD`. (Tier 2 — eMoney_Fact_Transaction_Status) |
| 10 | FundingTypeID | int | YES | `CASE WHEN mfts.TxTypeID IN (5) THEN 33 ELSE 0 END` on deposits; `CASE WHEN mfts.TxTypeID IN (6) THEN 33 ELSE 0 END` on withdrawals — join `Dim_FundingType` to decode. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 11 | CurrencyID | int | YES | Primary key. Universal instrument identifier. 0=NULL placeholder, 1-8=major forex currencies, ~1000+=stocks (AAPL, GOOG, etc.), ~100000+=crypto (BTC, ETH). Referenced by virtually all DWH fact tables. Legacy name: eToro originated as forex-only. Deposit path: `SellCurrencyID` from `eMoney_Currency_Instrument_Mapping_Static` on `HolderCurrencyISO = CurrencyISO` (`BuyCurrencyID = 1`). Withdraw path: `Dim_Currency.CurrencyID` on `HolderCurrencyDesc = Abbreviation`. (Tier 1 — Dictionary.Currency) |
| 12 | Currency | varchar(20) | YES | Passthrough `mfts.HolderCurrencyDesc` display string from eMoney (not `Dim_Currency.Abbreviation` join). (Tier 2 — eMoney_Fact_Transaction_Status) |
| 13 | IsFTD | int | YES | Deposits: `CASE WHEN f.TransactionID IS NOT NULL THEN 1 ELSE 0 END` against `#FTDIBAN`; withdraws forced `0` in temp; INSERT `ISNULL(i.IsFTD,0)`; late `UPDATE` for `DateID>=20250901` per SP. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 14 | IsInternalTransfer | int | YES | Deposits: `CASE WHEN mfts.TxTypeID IN (5) THEN 1 ELSE 0 END`. Withdrawals: `CASE WHEN mfts.TxTypeID IN (6) THEN 1 ELSE 0 END`. INSERT `ISNULL(...,0)`. **Differs from TP**, which keys off `FundingTypeID=33` on billing facts — here TxType drives the flag directly. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 15 | IsRedeem | int | YES | `#depositsIBAN` / `#cashoutIBAN` both assign `NULL AS IsRedeem`; final INSERT applies `ISNULL(i.IsRedeem, 0)`, so the persisted value is always **0**. Column exists for **DDR / `UNION ALL` schema parity** with `BI_DB_DDR_Fact_MIMO_Trading_Platform`, where `IsRedeem` can surface **transfer-to-coin / transfercoin** semantics from `Fact_CustomerAction` (`ActionTypeID IN (8,45)` withdraw path) and cross-checks **`Function_Revenue_TransferCoinFee`** (`ActionTypeID = 30 AND IsRedeem = 1`). **This eMoney SP never reads `Fact_CustomerAction.IsRedeem`** — do **not** apply TP/Fact_CustomerAction “redeem” narratives or “eMoney balance redeemed to bank account” wording here. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 16 | TxTypeID | int | YES | Transaction type identifier. 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat (15=CryptoToFiat via dictionary). Passthrough `mfts.TxTypeID` for filtered settled rows. (Tier 2 — eMoney_Fact_Transaction_Status) |
| 17 | IsTradeFromIBAN | int | YES | Deposits: `case when left(ReferenceNumber,1) != 'P' and TxStatusModificationDateID >= 20240403 and TxTypeID = 5 then 1 else 0 end`. Withdrawals: `case when left(ReferenceNumber,1) != 'P' and TxStatusModificationDateID >= 20240403 and TxTypeID = 6 then 1 else 0 end`. INSERT `ISNULL(i.IsTradeFromIBAN,0)`. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 18 | UpdateDate | datetime | YES | `GETDATE()` stamp on INSERT. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 19 | IsCryptoToFiat | int | YES | Deposit leg: `CASE WHEN mfts.TxTypeID IN (14) THEN 1 ELSE 0 END`. Withdraw leg: `0 AS IsCryptoToFiat`. INSERT: `ISNULL(IsCryptoToFiat,0)`. (Tier 2 — eMoney_Fact_Transaction_Status) |
| 20 | IsRecurring | int | YES | Literal `0` on INSERT (`0 AS IsRecurring`) — recurring schedules are tracked on TP/billing, not here. (Tier 2 — SP_DDR_Fact_MIMO_eMoney_Platform) |
| 21 | IsIBANQuickTransfer | int | YES | Literal `0` on INSERT (`0 AS IsIBANQuickTransfer`). SP changelog references **MoveMoneyReason = 6** for eMoney “Internal Transfer”, but **no** `MoveMoneyReasonID` filter exists in SQL — downstream AllPlatforms prose may assume behavior this SP does not implement. (Tier 4 — SP_DDR_Fact_MIMO_eMoney_Platform) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production / Synapse Origin | Transform |
|----------------|----------------------------|-----------|
| RealCID | `eMoney_Fact_Transaction_Status.CID` | Rename to RealCID |
| Amounts / TxType / Reference | `eMoney_Fact_Transaction_Status` | Filters + sign rules |
| CurrencyID | `eMoney_Currency_Instrument_Mapping_Static` / `Dim_Currency` | Dual join paths |
| FTD keys | `Dim_Customer` (`FTDPlatformID=3`, `FTDTransactionID`) | JOIN + UPDATE recovery |

### 5.2 ETL Pipeline

```
FiatDwhDB (per eMoney pipeline) -> Generic Pipeline / eMoney loader
    -> eMoney_dbo.eMoney_Fact_Transaction_Status
    -> BI_DB_dbo.SP_DDR_Fact_MIMO_eMoney_Platform(@date)
    -> BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
    -> BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms -> BI_DB_DDR_Fact_MIMO_AllPlatforms
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | `DWH_dbo.Dim_Customer` | Customer dimension |
| FundingTypeID | `DWH_dbo.Dim_FundingType` | Decode 0 / 33 |
| CurrencyID | `DWH_dbo.Dim_Currency` | Withdraw path instrument id |

### 6.2 Referenced By (other objects point to this)

| Source Object | Notes |
|--------------|-------|
| `BI_DB_dbo.SP_DDR_Fact_Fact_MIMO_AllPlatforms` | `UNION ALL` source for AllPlatforms MIMO |
| `BI_DB_dbo.SP_DDR_Process_Monitor` | Monitoring select |

---

## 7. Sample Queries

### 7.1 Daily eMoney internal-transfer volume (USD)

```sql
SELECT DateID,
       SUM(AmountUSD) AS sum_usd,
       COUNT_BIG(*)     AS n
FROM   BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
WHERE  DateID BETWEEN 20260101 AND 20260131
   AND IsInternalTransfer = 1
GROUP BY DateID
ORDER BY DateID;
```

### 7.2 Crypto-to-fiat deposits

```sql
SELECT DateID,
       SUM(AmountUSD) AS c2f_usd
FROM   BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
WHERE  MIMOAction = 'Deposit'
   AND IsCryptoToFiat = 1
   AND DateID >= 20260101
GROUP BY DateID
ORDER BY DateID;
```

### 7.3 Compare IBAN internal flags

```sql
SELECT IsInternalTransfer,
       IsTradeFromIBAN,
       COUNT_BIG(*) AS n
FROM   BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
WHERE  DateID >= 20260101
GROUP BY IsInternalTransfer, IsTradeFromIBAN
ORDER BY n DESC;
```

---

## 8. Atlassian Knowledge Sources

- [DDR Tables](https://etoro-jira.atlassian.net/wiki/spaces/~164971827/pages/13596884995/DDR+Tables) — personal space overview mentioning MIMO sub-tables and eMoney context (excerpt references MIMO family; not object-specific).
- No Confluence page specifically naming `SP_DDR_Fact_MIMO_eMoney_Platform` or `BI_DB_DDR_Fact_MIMO_eMoney_Platform` was returned by targeted CQL (`text ~ "SP_DDR_Fact_MIMO_eMoney"`, 0 hits).

---

*Generated: 2026-05-14 | Quality: 8.2/10 | Phases: 16/16 (SOFT eval)*
*Tiers: 2 T1, 18 T2, 0 T3, 1 T4, 0 T5 | Elements: 21/21, Logic: 8/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform | Type: Table | Production Source: eMoney_Fact_Transaction_Status + Dim_Customer*
