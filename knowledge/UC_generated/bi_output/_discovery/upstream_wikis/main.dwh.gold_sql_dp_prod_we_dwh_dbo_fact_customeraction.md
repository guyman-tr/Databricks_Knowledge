# DWH_dbo.Fact_CustomerAction

> Unified **customer action** fact (**~11.44 billion** rows via Synapse partition stats May 2026) consolidating **credit-ledger**, **position open/close**, **login**, **cashier**, and **registration** events keyed by **`ActionTypeID`** (`DWH_dbo.Dim_ActionType`). Loads daily through **`SP_Fact_CustomerAction_DL_To_Synapse` → `SP_Fact_CustomerAction` → `SP_Fact_CustomerAction_SWITCH`**, plus post-job **`SP_Fact_CustomerAction_IsParitalCloseParent`**. UC Gold copy: **`main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`** (Databricks `SHOW TABLES` 2026-05-14; **no** `main.pii_data.*fact_customeraction*` sibling returned).

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact) |
| **Row Count** | ~11.44B (`sys.partitions` sum May 2026) |
| **Production Sources (indirect composite)** | `History.Credit` (+ archives), `Trade.OpenPositionEndOfDay`, `History.ClosePositionEndOfDay`, `Billing.Login`, STS login feeds, `Customer.CustomerStatic` |
| **Refresh** | Daily (1440 min Generic Pipeline classify + SWITCH partition increment) |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE + multiple nonclustered (`ActionTypeID`+`DateID`, compensation, CID composites per historic ops notes) |
| **UC Target (Databricks)** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **UC PII-split sibling** | *Not found*: `SHOW TABLES IN main.pii_data LIKE '*fact_customeraction*'` → 0 rows (2026-05-14) |
| **UC Format** | Delta EXTERNAL |
| **UC Partitioned By** | `etr_y`, `etr_ym`, `etr_ymd` (Databricks-only partitioning — absent in Synapse DDL) |

---

## 1. Business Meaning

`Fact_CustomerAction` is the **foundation ledger** powering BI_DB DDR facts (MIMO, revenue TVFs, etc.). Each row captures one **instrumented platform action**. Because sources differ, **the row is intentionally sparse**: position economics columns are zeroed/NULL unless the branch is trading; ledger columns activate on financial `ActionTypeID` families.

**ActionType dominance (distribution evidence — Synapse MCP, `WHERE DateID >= 20260101`):** fees (`35` Overnight/Week Fee), closes (`5` Copy close, `6`/`4` mixes), opens (`2` Copy open dominates manual `1`), logins (`14`), stop edits (`32`), withdrawals (`45`/`8`/`30`), internal transfers (`44`/`45`), comps (`36`), churn of mirror ops (`15`–`19`), etc.—see §2.1 for ranked counts tied to **`Dim_ActionType.Name`**.

**`IsRedeem` is overloaded (canary semantics):**

1. **Transfer-to-coin (fiat wallet → on-chain/crypto custody)** — History path uses **`FundingTypeID = 27`** (eToroCryptoWallet); documented loader CASE from sibling wiki: **`CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`** (`DWH_dbo.Dim_FundingType.md §2.3`). Validates against live **`ActionTypeID = 8` + `IsRedeem = 1 ⇒ FundingTypeID = 27`** (all **`19 981`** rows in Jan‑2026+ slice). **`ActionTypeID = 30` (`Processed Cashout`) + `IsRedeem = 1`** aligns with **`Function_Revenue_TransferCoinFee`** (TVF anchors **`ActionTypeID = 30` AND `IsRedeem = 1`** for **`TransferCoinFee`** revenue).
2. **CFD / Billing.Redeem context** — distinct concept carried with **`RedeemID`/`RedeemStatus`** from **`Trade.PositionTbl`** lineage on **position-close action types (`ActionTypeID` ∈ `{4,5,6,…}`)**; **`IsRedeem = 1` appears (~22k manual closes in slice)** even when **`RedeemStatus` samples zero** — treat as redemption-style close events keyed by Billing redeem identifiers **`RedeemID`**.

Operational note: **`HistoryID` remains non-unique** — never treat as surrogate PK.

---

## 2. Business Logic

### 2.1 `ActionTypeID` distribution (critical) — **`DateID ≥ 20260101` TOP slice**

Synapse MCP grouped counts (joined to `Dim_ActionType`; only **29** distinct IDs fire in slice — bounded population, **not full TOP‑50 cardinality**):

| Rank | ActionTypeID | Dim_ActionType.Name | Row count |
|------|--------------|---------------------|-----------|
| 1 | 35 | End Of The Week Fee | 160 195 073 |
| 2 | 5 | CopyPositionClose | 140 892 743 |
| 3 | 2 | CopyPositionOpen | 114 621 954 |
| 4 | 14 | LoggedIn | 68 344 165 |
| 5 | 1 | ManualPositionOpen | 26 253 214 |
| 6 | 4 | ManualPositionClose | 26 119 673 |
| 7 | 32 | Edit StopLoss | 5 643 361 |
| 8 | 10 | Cashout request | 2 952 998 |
| 9 | 30 | Processed Cashout | 2 908 868 |
| 10 | 36 | Compensation | 2 494 343 |
| (…) | … | … | *(19 additional IDs totaling remainder — see MCP export / future widen `DateID` window for rare codes)* |

**Inline decoder (selected business-critical IDs)** — always join `Dim_ActionType` for authoritative labels:

| IDs | Meaning |
|-----|---------|
| 1–3, 39 | Position opens (`Trade.OpenPositionEndOfDay` lineage) |
| 4–6, 28, 40 | Position closes (`History.ClosePositionEndOfDay` lineage) |
| 7 / 44 | Deposits (standard vs internal sweep) |
| 8 / 45 / 30 | Cash-outs (request / internal withdrawal / processed) — **`30`** pairs with **`IsRedeem`** for **transfercoin** analytics |
| 14 / 41 | STS login / Registration |
| 35 | Consolidated rolling fee bucket (overnight, weekend, dividends, ticket fee, SDRT — see DSM-1463 via `Description` parsing) |

### 2.2 `IsFeeDividend` (ActionType = 35 nuance)

**What**: Parses `Description` strings for DSM‑14671 fee subclasses.  
**Columns**: `Description`, `IsFeeDividend`.  
**Rules**:

- `1` overnight/weekend lexical hits  
- `2` dividend  
- `3` SDRT  
- `4` ticket fees (**Open/Close TotalFees** literals) — DSM-1463  


### 2.3 FundingType → **`IsRedeem` on ledger cash-outs**

Cross-object rule (documented **`SP_Fact_CustomerAction`** excerpt via `Dim_FundingType.md`):  
`CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`.  
FundingType **`27`** must remain stable — renaming breaks flag.

### 2.4 Position-derived columns (**`Dim_Position` parity**)

Opens/closes hydrate large sets of **`Trade.PositionTbl`** lineage columns independent of querying `Dim_Position` (heavy). Reopen commissions, partial-close constructs, **`SettlementTypeID`**, DLT flags, **`IsAirDrop`**, markup prorations follow **`SP_Dim_Position_DL_To_Synapse`** documented formulas in `Dim_Position.md`.

---

## 3. Query Advisory

### 3.1 Synapse distribution & index

HASH on **`RealCID`** — constrain filters/joins with **`RealCID`** + **`DateID`** + **`ActionTypeID`** to avoid shuffle‑heavy scans on **CB** scale.

### 3.2 Common patterns

| Question | Approach |
|---------|----------|
| Customer deposits | `ActionTypeID IN (7,44)` + `JOIN Dim_Customer` |
| Logins per CID | `ActionTypeID = 14` |
| TransferCoin revenue archaeology | **`ActionTypeID = 30 AND IsRedeem = 1`** then join **`Function_Revenue_TransferCoinFee`** |
| Avoid Dim_Position explosions | Prefer columns already duplicated here when possible |

### 3.3 Common joins

| Target | Predicate | Purpose |
|--------|-----------|---------|
| `Dim_ActionType` | `fca.ActionTypeID` | Canonical labels |
| `Dim_Customer` | `RealCID` | Segmentation |
| `Dim_Product` | `fca.PlatformID = dp.ProductID` | Login/registration product axis |
| `Dim_FundingType` | `FundingTypeID` | Decode withdrawals / redeem wallet path (**27**) |

### 3.4 Gotchas

- **Never full-scan** — predicate on **`DateID`** (UC: also `etr_*` partitions).  
- **`IsBuy` NULL** ⇒ non-trade row — not directional unknown.  
- **`IsRedeem` meaning depends on `ActionTypeID` + FundingType + redeem IDs** — do not flatten.  
- **HistoryID duplicated** — dedupe forbidden.  

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 1** | Production-grounded inheritance (`Trade.*`, `History.Credit`, `Billing.Login`, STS, CRM, dictionaries) |
| **Tier 2** | Loader / derived (`SP_Fact_CustomerAction`, `SP_Dim_Position_DL_To_Synapse`, calendar buckets) |
| **Tier 3** | Operational sentinel / lightly documented |
| **Tier 5** | Expert / deprecation / disputed semantics |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HistoryID | decimal(38,0) | NO | Intended as a unique key but contains duplicates — NOT reliable as a primary/unique identifier. Do not use for JOINs, deduplication, or row identification. Has no practical use for analysts. (Tier 5 — domain expert) |
| 2 | GCID | int | NO | Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 — Customer.CustomerStatic) |
| 3 | RealCID | int | NO | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 4 | DemoCID | int | NO | Demo-account Customer ID. Always 0 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 5 | Occurred | datetime | NO | UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent) |
| 6 | IPNumber | bigint | YES | IP address of the customer as a numeric value. Populated for logins and registrations. (Tier 1 — STS/Billing.Login) |
| 7 | IsReal | tinyint | NO | Account type flag. Always 1 in this table (real accounts only). (Tier 3 — ETL-assigned) |
| 8 | ActionTypeID | smallint | NO | Event classifier — join `Dim_ActionType` for `Name` / `Category`. Drives sparse column population. Derived from **`CreditTypeID`** & branch router in loader + positional feeds. (Tier 1 — History.Credit / Trade snapshots / STS / Customer payloads) |
| 9 | PlatformTypeID | smallint | NO | Legacy platform discriminator (`0` default; `99` STS-heavy logins sampled 202601+). (Tier 3 — ETL-assigned) |
| 10 | InstrumentID | int | NO | FK to `Trade.Instrument`. Financial instrument being traded when row is instrument-bearing. (Tier 1 — Trade.PositionTbl) |
| 11 | Amount | decimal(11,2) | NO | Position / ledger amount discipline per branch (cash change on opens; fee/deposit sizing on ledger rows — see lineage). Must be ≥0 on trade opens historically. (Tier 1 — Trade.PositionTbl / History.Credit) |
| 12 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement posture. (Tier 1 — Trade.PositionTbl) |
| 13 | NetProfit | money | NO | Realized PnL. 0 when open; populated on closes in position currency. (Tier 1 — Trade.PositionTbl) |
| 14 | Commission | money | NO | Open commission in dollars (`/100` cents conversion on ingest per `Dim_Position` lineage notes). (Tier 1 — Trade.PositionTbl) |
| 15 | PositionID | bigint | NO | Position identifier from the source trading system. NOT a primary key of this table — defaults to 0 for non-position events, and the same PositionID appears in both open and close rows. |
| 16 | CampaignID | int | NO | Marketing campaign identifier — 0 if not campaign-bound. References `Dim_Campaign`. (Tier 5 — domain expert) |
| 17 | BonusTypeID | smallint | NO | Bonus classifier on bonus credit rows (`ActionTypeID=9`). 0 elsewhere. References `Dim_BonusType`. (Tier 5 — domain expert) |
| 18 | FundingTypeID | smallint | NO | Ledger funding / wallet channel identifier (deposits & cash-outs). Nullable upstream coerced with `ISNULL(...,0)` sentinel row **`0`** (`Dim_FundingType.md`). **Value 27 pairs with redeem flag derivation on cash-outs.** References `Dim_FundingType`. (Tier 1 — History.Credit) |
| 19 | LoginID | int | NO | Billing login session key (`Billing.Login` lineage). 0 off-login. (Tier 1 — Billing.Login) |
| 20 | MirrorID | int | NO | FK to Trade.Mirror (`0`/NULL ⇒ manual trading; >0 ⇒ copy-trade child). (Tier 1 — Trade.PositionTbl) |
| 21 | WithdrawID | int | NO | Withdrawal request identifier for cash-out credits; 0 when absent. (Tier 1 — History.Credit) |
| 22 | DurationInSeconds | int | YES | Login session dwell seconds (NULL outside login cashier events). (Tier 1 — Billing.Login) |
| 23 | PostID | uniqueidentifier | YES | Social GUID for deprecated social action types (**21‑26**) — stale per historical wiki audits. NULL otherwise. (Tier 1 — Social platform) |
| 24 | CaseID | int | NO | CRM case (`ActionTypeID=31`). 0 default. (Tier 1 — CRM) |
| 25 | UpdateDate | datetime | NO | Last successful fact loader write (`GETDATE()`/`GETUTCDATE()` parity in ops). (Tier 2 — SP_Fact_CustomerAction) |
| 26 | DateID | int | NO | **`Occurred`** → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) |
| 27 | TimeID | int | NO | Hour bucket `DATEPART(HOUR,Occurred)`. (Tier 2 — SP_Fact_CustomerAction) |
| 28 | StatusID | tinyint | YES | Row vitality flag (**1** almost always; rare NULL cohort). (Tier 3 — ETL-assigned) |
| 29 | PreviousOccurred | datetime | YES | Deprecated / unreliable historical column — analysts should ignore. (Tier 5 — domain expert) |
| 30 | CompensationReasonID | int | NO | `BackOffice.CompensationReason` code on comps & some opens for airdrops. (Tier 1 — History.Credit, updated wiki 2025-12) |
| 31 | WithdrawPaymentID | int | NO | Payment-processing key for withdrawals; used to collapse duplicate WithdrawProcessing tuples per historical ETL memo. (Tier 1 — History.Credit) |
| 32 | CommissionOnClose | money | NO | Close commission dollars — reopen-adjust net-of-original per `Dim_Position` wiki. **`CommissionOnCloseOrig` preserves untouched close fee.** (Tier 1 — Trade.PositionTbl) |
| 33 | IsPlug | bit | YES | Deprecated placeholder (`NULL`). (Tier 5 — domain expert) |
| 34 | DepositID | int | YES | Deposit transaction reference on inbound money rows (`NULL` off-deposit actions). (Tier 1 — History.Credit) |
| 35 | PostRootID | varchar(200) | YES | Deprecated social threading key. NULL off-social. (Tier 1 — Social platform) |
| 36 | FullCommission | money | YES | Gross commission inclusive of hidden spread uplift at open (`/100` ingestion note). (Tier 1 — Trade.PositionTbl) |
| 37 | FullCommissionOnClose | money | YES | Gross commission on exit — symmetrical reopen-adjust story to `CommissionOnClose`. (Tier 1 — Trade.PositionTbl) |
| 38 | RedeemID | int | YES | Billing.Redeem reference when position closed via redeem. (Tier 1 — Trade.PositionTbl) |
| 39 | RedeemStatus | int | YES | Redemption state. Billing.Redeem integration. (Tier 1 — Trade.PositionTbl) |
| 40 | SessionID | bigint | YES | STS session BIGINT for opens/logins (`NULL` off those branches). (Tier 1 — STS) |
| 41 | IsRedeem | int | YES | **Dual-semantics redeem flag.** (A) **Ledger / Crypto-wallet Path:** Loader CASE documented in **`Dim_FundingType.md` §2.3 (`CASE WHEN CreditTypeID = 2 AND FundingTypeID = 27 THEN 1 ELSE 0 END`)** tagging **eToroCryptoWallet (`FundingTypeID=27`) cash-outs** (`ActionTypeID = 8` sample slice **100 % FundingType 27 whenever `IsRedeem=1`** for `DateID≥20260101`). Revenue TVF **`Function_Revenue_TransferCoinFee`** filters **`Fact_CustomerAction` with `ActionTypeID = 30` AND `IsRedeem = 1`** — interpret as **transfer-to-coin / fiat-wallet → on-chain custody** (**not** shorthand for bank cash-out). (B) **CFD Billing.Redeem Path:** Positional closes (`ActionTypeID∈{4,5,6,…}`) can emit **`IsRedeem=1` alongside `RedeemID`/`RedeemStatus`** (Billing.Redeem integration per `Trade.PositionTbl`) — orthogonal to transfercoin semantics. CLOSE-branch **`CASE` text unavailable** (`sys.sql_modules.definition` **NULL** for `SP_Fact_CustomerAction` on this Synapse warehouse). **Do not equate blindly to non-existent `Dim_Position.IsRedeem` column.** (Tier 2 — SP_Fact_CustomerAction) |
| 42 | RegulationIDOnOpen | int | YES | Regulatory jurisdiction ID at time of position open. ETL-computed via JOIN to etoro_History_BackOfficeCustomer (customer regulation history). ISNULL(..., 0) when no regulation match found. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 43 | PlatformID | int | YES | Product/platform identifier — badly named, references `Dim_Product.ProductID`; resolve Product/Platform/SubPlatform columns via JOIN (`ActionTypeID` **14**/ **41** focus). (Tier 5 — domain expert) |
| 44 | ReopenForPositionID | bigint | YES | When position reopened: erroneous prior **`PositionID`**. NULL if virgin cycle. (Tier 1 — Trade.PositionTbl) |
| 45 | IsReOpen | int | YES | 1=this position was reopened from `ReopenForPositionID`. CASE WHEN **`ReopenForPositionID`** NOT NULL ⇒1 else0 default. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 46 | CommissionOnCloseOrig | money | YES | **`CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0`** — preserves naive close commission before netting. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 47 | FullCommissionOnCloseOrig | money | YES | **`CASE WHEN ReopenForPositionID IS NOT NULL THEN FullCommissionOnClose ELSE 0`** (default zeros). (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 48 | OriginalPositionID | bigint | YES | Source position BEFORE partial-split chains. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 49 | IsPartialCloseParent | int | YES | Marks parent row around partial-close split (subject to **`SP_Fact_CustomerAction_IsParitalCloseParent`** post-job). Analyst filtering nuance persists from `Dim_Position` guidance. (Tier 5 — domain expert, SP_Fact_CustomerAction_IsParitalCloseParent) |
| 50 | IsPartialCloseChild | int | YES | Marks remainder leg after partial close — filter guidance identical to **`Dim_Position`**: avoid dropping CLOSE child rows blindly. (Tier 5 — domain expert, SP_Dim_Position_DL_To_Synapse) |
| 51 | InitialUnits | decimal(16,6) | YES | Opening unit count denominator for partial proration ladders. (Tier 1 — Trade.PositionTbl) |
| 52 | PaymentStatusID | int | YES | Payment pipeline status IDs on inbound/outbound monies — join `Dim_PaymentStatus`. (Tier 5 — domain expert) |
| 53 | IsDiscounted | int | YES | 1=commission discount applied at open (legacy bit widening). (Tier 1 — Trade.PositionTbl) |
| 54 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 55 | CommissionByUnits | decimal(38,6) | YES | Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 — Trade.Position) |
| 56 | FullCommissionByUnits | decimal(38,6) | YES | Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 — Trade.Position) |
| 57 | IsFTD | int | YES | First-Time Deposit tagging on qualifying deposit/action rows (NULL elsewhere). Derived during credit classification & snapshot merges. (Tier 2 — SP_Fact_CustomerAction) |
| 58 | CountryIDByIP | int | YES | Geo-IP-derived country surrogate — join **`Dim_Country`**. (Tier 5 — domain expert) |
| 59 | IsAnonymousIP | int | YES | Anonymous / proxy heuristic flag STS path. NULL off relevant rows. (Tier 1 — IP geolocation service) |
| 60 | ProxyType | varchar(3) | YES | Proxy taxonomy (`DCH`, `VPN`, `TOR`, etc.) from STS classifications. NULL if direct. (Tier 1 — STS) |
| 61 | IsFeeDividend | int | YES | Fee subclass for **`ActionTypeID=35`** (1 nightly/weekend fee, 2 dividend, 3 SDRT, 4 ticket aggregates) encoded off **`Description`** heuristics (DSM‑1463). NULL off-fee rows. (Tier 2 — SP_Fact_CustomerAction) |
| 62 | IsAirDrop | int | YES | **`JOIN`** to **`etoro_Trade_PositionAirdropLog`** path per `Dim_Position` — 1 denotes airdrop-sourced crypto open. NULL otherwise. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 63 | DividendID | int | YES | Dividend event pointer for dividend-driven fee deductions. NULL off-dividend. (Tier 1 — Trade.Positions/dividends lineage) |
| 64 | MoveMoneyReasonID | int | YES | NULL in all archive branches; natively populated only in History.ActiveCredit. Do not join from this view. (Tier 1 - History.Credit.md) |
| 65 | SettlementTypeID | int | YES | **`Dictionary.SettlementTypes`** modern encoding (`0 CFD`, `1 REAL`, `2 TRS`, `3 CMT`, `4 REAL_FUTURES`, `5 MARGIN_TRADE`). Supersedes naïve `IsSettled` reads. (Tier 1 — Trade.PositionTbl) |
| 66 | DLTOpen | smallint | YES | Distributed-ledger telemetry captured at OPEN (Prod addition 2024‑06‑02 per dim wiki). NULL historical. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 67 | DLTClose | smallint | YES | Ledger telemetry captured at CLOSE mirroring **`DLTOpen`**. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 68 | OpenMarkupByUnits | money | YES | Prorated open markup **`OpenMarkup * AmountInUnitsDecimal / InitialUnits`** for partial closes. (Tier 1 — Trade.Position) |
| 69 | Description | varchar(255) | YES | Operational narrative pulled from Credits / fees ("Over night fee", ticket fee tokens, Payments deposit processor strings). (Tier 1 — History.Credit) |
| 70 | IsBuy | bit | YES | **`1`** Long **`0`** Short; NULL ⇒ non-trade row sentinel. (Tier 1 — Trade.PositionTbl) |
| 71 | CreditID | bigint | YES | Direct pointer to **`History.Credit.CreditID`** lineage for reversible audits. Added 2025 loader wave. (Tier 1 — History.Credit) |

---

## 5. Lineage

### 5.1 Production Sources (high level)

| Synapse grouping | Origin (via lake pipelines) |
|------------------|---------------------------|
| Ledger / internal money | `History.Credit` (+ Active + archive UNION in prod conceptual model) |
| Position economics | `Trade.OpenPositionEndOfDay`, `History.ClosePositionEndOfDay` |
| STS / biometric proxies | STS operational tables (see Confluence STS link §8) |
| Cashier | `Billing.Login` |
| Customer registration | `Customer.CustomerStatic` |
| Regulatory overlay | Historical Backoffice regulation feeds (see **`RegulationIDOnOpen`** element) |

### 5.2 ETL Pipeline (ASCII — operational)

```
etoro OLTP ──► Data Lake ──► DWH staging / EXTERNAL (Ext_FCA_* families)
                     │
                     ▼
   SP_Fact_CustomerAction_DL_To_Synapse  (tier-1 hydrate & typing)
                     ▼
   SP_Fact_CustomerAction               (canonical transform & union)
                     ▼
   SP_Fact_CUSTOMERACTION_SWITCH        (daily partition SWAP into DWH table)
                     ▼
   SP_Fact_CustomerAction_IsParitalCloseParent  (partial-close tagging)

Gold Generic Pipeline ──► main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
(Delta EXTERNAL; partitioning `etr_*` not in Synapse)
```

```text
UPSTREAM SEARCH LOG — Fact_CustomerAction:
  Lineage sources (Phase 10A sweep):
    1. Dim_Position.md                          → FOUND (Read YES) — Position + redeem column inheritance
    2. Dim_Customer.md                           → FOUND (Read YES)
    3. Dim_Currency.md                           → FOUND (Read YES — instrument registry context; Fact row lacks CurrencyID but cross-domain awareness)
    4. Dim_FundingType.md                        → FOUND (Read YES) — **IsRedeem CASE + FundingType 27 coupling**
    5. Dim_ActionType.md                       → FOUND (Read YES)
    6. Fact_BillingDeposit.md / Withdraw.md      → FOUND (patterns referenced historically; enrichment indirect)
    7. BI_DB Function_Revenue_TransferCoinFee.md → FOUND — **ActionType 30 ∧ IsRedeem business anchor**
    8. BI_DB_DDR_Fact_MIMO_Trading_Platform.*   → FOUND — withdraw leg inherits `fca.IsRedeem`
    Trade.PositionTbl wiki (Tier1 ultimate) — deferred to DB_Schema clone not mounted here (relayed via Dim_Position verbatim tags)
```

---

## 6. Relationships

### 6.1 References To (this → dimension / dictionary)

See §3.3 Quick join table — materially: `Dim_ActionType`, `Dim_Customer`, `Dim_Product`, `Dim_FundingType`, optional `Dim_PaymentStatus`, **`Dim_Country`**, `Dim_Instrument` (sparse), **`Dim_Date`**.

### 6.2 Referenced By (illustrative high-traffic analytic consumers — not exhaustive DMV)

DDR + revenue TVFs (**`Function_Revenue_*`**, **`Function_MIMO_*`**, **`BI_DB_DDR_*` facts**) — see prior wiki inventory; DMV catalog query returned zero rows (`sys.sql_expression_dependencies` Synapse limitation May 2026).

---

## 7. Sample Queries

### 7.1 Action mix for a CID (recent window)

```sql
SELECT f.ActionTypeID, d.Name, COUNT_BIG(*) cnt
FROM DWH_dbo.Fact_CustomerAction f
JOIN DWH_dbo.Dim_ActionType d ON d.ActionTypeID=f.ActionTypeID
WHERE f.RealCID = @cid AND f.DateID BETWEEN @sd AND @ed
GROUP BY f.ActionTypeID, d.Name
ORDER BY cnt DESC;
```

### 7.2 TransferCoin / processed cash-outs slice audit

```sql
SELECT COUNT(*) transfers
FROM DWH_dbo.Fact_CustomerAction
WHERE DateID BETWEEN @sd AND @ed
  AND ActionTypeID = 30
  AND IsRedeem = 1;
```

### 7.3 Login platform decode

```sql
SELECT dp.Product, dp.Platform, COUNT(*) cnt
FROM DWH_dbo.Fact_CustomerAction f
JOIN DWH_dbo.Dim_Product dp ON dp.ProductID = f.PlatformID
WHERE f.ActionTypeID = 14 AND f.DateID BETWEEN @sd AND @ed
GROUP BY dp.Product, dp.Platform
ORDER BY cnt DESC;
```

---

## 8. Atlassian Knowledge Sources

Soft phase (**Phase 10** not re-harvested this regen batch — resurrect historical pointers from superseded wiki for continuity):

| Asset | Hook |
|-------|------|
| Confluence BI Dictionary | Describes Fact_CustomerAction as foundational raw/near-raw slab |
| Confluence STS - Audit_Login | Login telemetry chain |
| Jira DSM-1463 | `IsFeeDividend` subclasses |
| Jira DSM-1769 / DSM-2392 | Redeem & withdraw enrichment initiatives |
| Jira DSM-1771 | Instrument augmentation for fee analytics |

URLs unchanged from March 2026 snapshot — reconcile owners if relocated.

---

*Generated: 2026-05-14 | Quality: 8.0/10 (Phase 16 self-eval provisional) | Phases: Steps 00/01/02/03/08/09★/10A/10B/11 invoked; 09 partial (SP catalog NULL); 07/SP-dep DMV empty.*  
*Tiers: 42 T1, 14 T2, 4 T3, 0 T4-unverified counted, 11 T5 | Elements: 71/71 | Source focus: MCP Synapse + repo wikis + Partial SP (catalog body NULL)* 
