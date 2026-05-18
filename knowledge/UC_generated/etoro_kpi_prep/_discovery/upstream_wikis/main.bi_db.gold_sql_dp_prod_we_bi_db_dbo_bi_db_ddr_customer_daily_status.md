# BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status

> **~13.8B-row** DDR customer **daily** status fact — **one row per `RealCID` per `DateID`** spanning **20071001–20260513** in UC (`main.bi_db`). Each row carries platform-scoped FTDs, global FTD, MIMO-derived same-day money-movement flags, DDR engagement segments (active / portfolio-only / balance-only / inactive), **`Fact_SnapshotCustomer` as-of-snapshot attributes** (joined through `Dim_Range` for `@dateID`), login splits, and funded / first-action / IOB metadata. **Production load:** `BI_DB_dbo.SP_DDR_Customer_Daily_Status` (**DELETE** by `DateID` + **INSERT**). **Not** an SCD2 table — daily full recompute of the eligible population for that business date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Derived in DWH via `SP_DDR_Customer_Daily_Status` (`DataPlatform/.../BI_DB_dbo.SP_DDR_Customer_Daily_Status.sql`), sourcing `BI_DB_Client_Balance_CID_Level_New`, `Dim_Customer`, `Dim_FTDPlatform`, **`Fact_SnapshotCustomer` + `Dim_Range`**, `BI_DB_DDR_Fact_MIMO_AllPlatforms`, `eMoney_Fact_Transaction_Status`, `Fact_CustomerAction`, TVFs `Function_Population_*`, and `Dim_Country` |
| **Refresh** | Daily — `DELETE FROM BI_DB_DDR_Customer_Daily_Status WHERE DateID = @dateID` + INSERT for that calendar date |
| **Synapse Distribution** | `HASH(RealCID)` |
| **Synapse Index** | `CLUSTERED COLUMNSTORE INDEX` |
| **UC Target (Gold)** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` |
| **UC Format** | delta |
| **UC Partitioned By** | _Not verified in this write — use `DESCRIBE DETAIL` if required_ |
| **UC Table Type** | Gold export mirroring Synapse narrow fact (no direct PII identifiers in column list) |

---

## 1. Business Meaning

`BI_DB_DDR_Customer_Daily_Status` is the **DDR daily customer snapshot** used for segmentation, MI-style customer journey reporting, and dashboards that need a **single “as of business date” projection** without re-walking the full SCD2 history of `Fact_SnapshotCustomer`.

**Population waterfall (mutually exclusive precedence in the SP — see §2.1)** starts from **client-balance–backed TP customers** for the date, adds **IBAN-only** customers from `eMoney_Fact_Transaction_Status`, then pulls **Options**, **Options MIMO**, and **MoneyFarm** cohorts defined in the SP. Every row is then hydrated with **cross-platform FTD fields** (CASE-split from `Dim_Customer` / global FTD helpers), **daily MIMO-derived money-movement flags**, **DDR activity segments** (`Function_Population_*` family), **lifecycle snapshot columns** from **`Fact_SnapshotCustomer` matched to `@dateID` through `Dim_Range`**, login-based slices from **`Fact_CustomerAction`**, and **manual marketing region text** from **`Dim_Country.MarketingRegionManualName`**.

Row-scale evidence: **Databricks UC** ≈ **13.77B rows** total (`COUNT(*)`), **DateID** range **20071001–20260513** (query 2026-05-14). **Synapse** sample aggregates show **~6.81M rows** for `DateID = 20260425` (recent day with full pool in the connected pool). **PHASE 2 CHECKPOINT: PASS** (live MCP row-count / TOP sample); note a **forward `DateID` probe returned 0 rows** in the dev pool while UC already held `20260513` — treat as **environment drift**, not semantic truth.

The table is **`BI_DB_DDR_Customer_Periodic_Status`’s upstream daily feed** — the periodic table rolls these daily columns into `_ThisWeek/_ThisMonth/...` aggregates (see sibling wiki).

Author / change history is recorded in the SP header (Guy Manova et al.) — notably **IBAN cohort fix (2025-08)**, **IOB fields (2025-08)**, **Options/MoneyFarm/global-FTD cohesion (2025-10/11)**, and **final `ROW_NUMBER` dedup (2025-12)** guarding lake merge uniqueness on (`RealCID`,`DateID`).

---

## 2. Business Logic

### 2.1 Population Sources (SP Waterfall)

**What**: Build `#population` — the **union** of TP balance customers, IBAN-only depositors (settled `TxTypeID` 7 or 14), Options / Options-MIMO extensions, and MoneyFarm stragglers not already captured.

**Columns Involved**: `RealCID` (and implicit platform metadata carried into FTD helpers)

**Rules**:
- **TP base**: `BI_DB_Client_Balance_CID_Level_New` filtered to `@dateID`.
- **IBAN-only path**: earliest settled eMoney IBAN-like deposit per CID, excluding anyone already in TP.
- **Options / MIMO / MoneyFarm blocks**: see SP — each explicitly `NOT IN` prior pools.

### 2.2 As-Of Snapshot Attributes from `Fact_SnapshotCustomer`

**What**: Pull **one** `Fact_SnapshotCustomer` grain per customer where `@dateID` lies between `Dim_Range.FromDateID` and `Dim_Range.ToDateID`.

**Columns Involved**: `RegulationID`, `DesignatedRegulationID`, `PlayerStatusID`, **`IsCreditReportValidCB`**, **`IsValidCustomer`**, `AccountTypeID`, **`CountryID`** (note DECIMAL storage in this table DDL), `MifidCategorizationID`, `PlayerLevelID`, `IsDepositor`

**Rules**:
- **`LEFT JOIN` semantics** into `#basicStatuses` — population members without a matching open `DateRangeID` window carry **NULL** snapshot fields (still get a row).

### 2.3 Valid-user vs Credit-Balance reporting filters (contract)

**What**: Two **independent** analytic filters are materialized as ordinary columns — **the table is NOT pre-filtered** to either flag (no `IsPrefiltered` / no implicit `WHERE` in the physical table).

**Columns Involved**: `IsValidCustomer`, `IsCreditReportValidCB`

**Rules (stated exactly as the stewardship contract for this documentation pass)**:
- **`IsValidCustomer` / analytic `IsValidUser`**: **`IsValidCustomer = 1`** is the **standard business filter** (excludes **test / internal** users); it is the **DEFAULT filter for ~99% of analytics**. Semantics: **“user is real and tradeable for business analytics.”** **Popular Investors (`PIs`) are valid users — do NOT classify PIs as “non-valid.”** The physical column name is **`IsValidCustomer`**, passed through from **`Fact_SnapshotCustomer`** on the as-of date.
- **`IsCreditReportValidCB`**: **`IsCreditReportValidCB = 1`** is the **stricter financial / regulatory filter** for **Credit Balance (Client Balance) reporting** (`CB`). **It includes a small set of subsidiary CB users** that **`IsValidCustomer` / analytic `IsValidUser` excludes** from the **standard** CB view. **Formal CASE definition** lives in `Fact_SnapshotCustomer` §§2.3 (ETL) — this table **passes the already-computed flag** through for the snapshot row.

### 2.4 Daily MIMO Dimensions & Coercion

**What**: Collapse `BI_DB_DDR_Fact_MIMO_AllPlatforms` (@ `DateID=@dateID`) into per-customer aggregates (`#mimoUsers*`) with guarded **INSERT/DELETE** coercion when `Dim_Customer.FirstDepositDate` and MIMO transaction timing disagree (recovery-date class of issues).

**Columns Involved**: `GlobalDeposited`, `GlobalFirstDeposited`, `GlobalRedeposited`, `GlobalCashedOut`, `Redeemed`, `Deposited*`, `ReDeposited*`, `TPExternal*`, `TP_External_FTDA`, `Options*` fields, platform FTD indicators, etc.

**Rules**:
- Most flags are **daily 0/1** indicators from `MAX/CASE` gymnastics in the SP — treat `0` as definitive “did not happen **on** this `DateID`” (not lifetime).
- **`UPDATE #enrichStatusActions`** block back-fills **global / Options** FTD fields when **Options FTD date** equals `@dateID` but MIMO was sparse.

### 2.5 DDR Engagement Segments & Activity

**What**: Classify **active traders**, **portfolio-only (HODL)** accounts, **balance-only** cash accounts, and derive **inactive**, **account active**, **logged-in depositor flavors**, **funded**, **first-time funded**, and **first trading action** metadata.

**Columns Involved**: `ActiveTraded`, `BalanceOnlyAccount`, `Portfolio_Only`, `AccountActive`, `AccountInActive`, `IsFunded`, `FirstTimeFunded`, `FirstFundedDateID`, `FirstIOBDateID`, `FirstIOBTime`, `FirstActionType`, `FirstActionDateID`, `LoggedIn*`

**Rules**:
- **Tier resolution** uses the `Function_Population_*` TVFs invoked in the SP (see `.lineage.md` for object list).
- **`AccountActive`** = `ActiveTraded OR Portfolio_Only` (portfolio segment uses `ISNULL(Portfolio_Only,0)` in logic).
- **`FirstActionType`** returns `'NoAction'` when `FirstTradeDateID > @dateID` or is `NULL` (`#basicStatuses` CASE).
- **`FirstFundedDateID` / `FirstActionDateID` sentinels**: inserted as **`30000101`** when unknown (see `ISNULL` in final SELECT).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

`HASH(RealCID)` + CCI: **always predicate on `DateID` first** — this is a **10B+** class table in production. For point lookups, combine **`DateID` + `RealCID`**.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Standard active retail base for a day | `WHERE DateID = @d AND IsValidCustomer = 1` (**not** baked into the table — must filter) |
| Credit-balance regulatory slice | `WHERE DateID = @d AND IsCreditReportValidCB = 1` |
| Active traders yesterday | `WHERE DateID = @d AND ActiveTraded = 1` |
| Global first-time deposit events on a day | `WHERE DateID = @d AND GlobalFirstDeposited = 1` |
| Marketing-region mix | `WHERE DateID = @d GROUP BY MarketingRegion` (dimension text already on-row) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Customer` | `dc.RealCID = cds.RealCID` | Extra static attributes / labels |
| `DWH_dbo.Dim_Regulation` | `r.RegulationID = cds.RegulationID` | Regulation copy |
| `DWH_dbo.Dim_PlayerStatus` | `ps.PlayerStatusID = cds.PlayerStatusID` | Status naming |
| `DWH_dbo.Dim_PlayerLevel` | `pl.PlayerLevelID = cds.PlayerLevelID` | Player level naming |
| `DWH_dbo.Dim_Country` | `c.CountryID = cds.CountryID` | Already used for `MarketingRegion` — join again if other country fields needed |
| `BI_DB_DDR_Customer_Periodic_Status` | `RealCID`, `DateID` | Period rollups |

### 3.4 Gotchas

- **No automatic “valid user” filter** — **never** assume `IsValidCustomer = 1`; also **do not** reference deprecated predicates like **`IsPrefiltered`**, and **do not** claim this table is wholesale limited to valid users.
- **`Portfolio_Only` is `decimal(16,6)` in DDL** while most other flags are `int` — casts / `ISNULL` may be required in odd legacy queries.
- **`CountryID` / `MifidCategorizationID` are `decimal`** in this narrow table even though `Fact_SnapshotCustomer` documents `int` semantics — join still works but mind type promotion in mixed expressions.
- **`WHERE RN = 1` in the INSERT** mitigates rare duplicate `(RealCID,DateID)` failures for lake merge — duplicates should be **exceptional**, but the guard is real.
- **`FirstFundedDateID` / `FirstActionDateID` = `30000101`** means **“none / unknown sentinel”**, not a real calendar hit.
- **Upstream snapshot NULLs**: if a customer lacks a `Fact_SnapshotCustomer` row intersecting `@dateID`, **regulation / valid flags / country** may be `NULL` despite the customer being in the DDR population.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★☆ | Tier 1 | `(Tier 1 — production.wiki)` | Upstream production DB wiki (rare here) |
| ★★★☆☆ | Tier 2 | `(Tier 2 — …)` | Synapse SP / published DWH wiki (Fact / Dim) |
| ★★☆☆☆ | Tier 3 | `(Tier 3 — …)` | Extension tables / manual overlays |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED]` | Needs SME confirmation |

### Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Calendar business date evaluated by `SP_DDR_Customer_Daily_Status` (= `@date` parameter). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 2 | DateID | int | YES | `@dateID` (`YYYYMMDD`) — partition / delete key for the narrow table. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 3 | RealCID | int | YES | Real customer identifier (HASH distribution key). One row per `RealCID` per `DateID` after RN dedup. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 4 | TP_FTD_DateID | int | YES | Trading-platform first-deposit surrogate key from `#globalDepositorsAlltime` (`CASE` branch where `Dim_FTDPlatform.FTDPlatformName = 'TradingPlatform'`). (Tier 2 — Dim_Customer) |
| 5 | TP_FTD_Date | datetime | YES | Trading-platform FTD timestamp (paired with TP_FTD_* IDs). Source CASE columns from aggregated `Dim_Customer`/`#globalFTDs`. (Tier 2 — Dim_Customer) |
| 6 | TP_FTDA | decimal(16,6) | YES | Trading-platform FTD amount (USD). CASE branch tied to TP platform FTD rows. (Tier 2 — Dim_Customer) |
| 7 | IBAN_FTD_DateID | int | YES | IBAN / eMoney first-deposit surrogate key (`FTDPlatform = 'eMoney'` branch). (Tier 2 — Dim_Customer) |
| 8 | IBAN_FTD_Date | datetime | YES | IBAN FTD timestamp. CASE branch sourced from aggregated `Dim_Customer`. (Tier 2 — Dim_Customer) |
| 9 | IBAN_FTDA | decimal(16,6) | YES | IBAN FTD amount. CASE branch sourced from aggregated `Dim_Customer`. (Tier 2 — Dim_Customer) |
| 10 | TP_External_FTDA | decimal(16,6) | YES | External-facing TP FTD amount component sourced from aggregated MIMO prep (`TPExternalFTDA` path in `#enrichStatusActions`). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 11 | Global_FTD_DateID | int | YES | Minimum first-deposit `DateID` across platform-specific FTD CASE outputs (`MinFirstDepositDateID`). Earliest-platform FTD. (Tier 2 — Dim_Customer) |
| 12 | Global_FTD_Date | datetime | YES | Minimum first-deposit calendar datetime across platform branches (`MinFirstDepositDate`). (Tier 2 — Dim_Customer) |
| 13 | Global_FTDA | decimal(16,6) | YES | FTD monetary amount paired with globally winning FTD date (chosen via CASE bundle in `#globalDepositorsAlltime`). (Tier 2 — Dim_Customer) |
| 14 | IsDepositorGlobal | int | YES | Lifetime global depositor flag inside SP helper (`CASE WHEN FirstDepositDate > '1900-01-01' THEN 1 ELSE 0`). Mirrors “ever deposited anywhere” semantics feeding DDR depositors-login logic. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 15 | GlobalDeposited | int | YES | 1 if customer had a non-internal **Deposit** row on **`DateID`** in MIMO-prepared data (`GlobalDeposited` aggregator). Includes later Options-specific UPDATE patch paths. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 16 | GlobalFirstDeposited | int | YES | 1 if **global first deposit event** flagged on **`DateID`** (`IsGlobalFTD` path in `#mimoUsers` aggregations); subject to coercion inserts for Options gaps. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 17 | GlobalRedeposited | int | YES | 1 if customer deposited on **`DateID`** when **not** flagged as FTD (`IsGlobalFTD = 0`, non-internal). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 18 | GlobalCashedOut | int | YES | 1 if customer withdrew (non-internal) on **`DateID`**; redeemed-withdraw overlays may mark activity for FTD-timing fixes. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 19 | Redeemed | int | YES | 1 if a **billing redeem-linked** withdrawal (`IsRedeem = 1` on `#mimo_coerced_withdraw` rollup) intersects **`DateID`**. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 20 | DepositedTP | int | YES | 1 if **TradingPlatform** deposit (non-internal) occurred on **`DateID`**. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 21 | DepositedIBAN | int | YES | 1 if **eMoney / IBAN** deposit (non-internal) occurred on **`DateID`**. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 22 | ReDepositedTP | int | YES | 1 if **TP** redeposit (non-internal, non-FTD platform flag) occurred on **`DateID`**. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 23 | ReDepositedIBAN | int | YES | 1 if **IBAN** redeposit occurred on **`DateID`** under redeposit CASE logic (`IsPlatformFTD = 0`). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 24 | TPFirstDeposited | int | YES | 1 if **TradingPlatform FTD** (`IsPlatformFTD = 1`) occurred on **`DateID`**. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 25 | IBANFirstDeposited | int | YES | 1 if **IBAN FTD** occurred on **`DateID`** under MIMO aggregations (`IsPlatformFTD = 1` on eMoney path). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 26 | TPExternalFirstDeposited | int | YES | 1 if **external** TP FTD (non-internal transfer) flagged on **`DateID`**. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 27 | ActiveTraded | int | YES | 1 when `Function_Population_Active_Traders(@dateID,@dateID)` marks the CID as DDR-active (explicit trades / mirror participation / qualifying Options actions — see TVF wiki / SP commentary). Default `ISNULL` to 0 in INSERT. (Tier 2 — Function_Population_Active_Traders) |
| 28 | BalanceOnlyAccount | int | YES | Presence/measure flag from `Function_Population_Balance_Only_Accounts(@dateID,@dateID)` — customer had **positive equity** but **no** qualifying open-position / trading activity tiers. Stored as int indicator in INSERT path. (Tier 2 — Function_Population_Balance_Only_Accounts) |
| 29 | Portfolio_Only | decimal(16,6) | YES | **`Function_Population_Portfolio_Only`** output persisted as DECIMAL per DDL — analytics treat nonzero as **portfolio/HODL** segment participation for `@date`. `AccountActive` tests `ISNULL(Portfolio_Only,0)` in SP logic. (Tier 2 — Function_Population_Portfolio_Only) |
| 30 | AccountActive | int | YES | Derived: **`1` iff `ActiveTraded = 1 OR ISNULL(Portfolio_Only,0) <> 0`** (see `#enrichStatusActions`). Encapsulates intentional engagement vs inactive tiers. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 31 | AccountInActive | int | YES | Derived flag for customers occupying the explicit **inactive** bucket after removing balanced segment winners (`EXCEPT` ladders in `#inactive`). Requires understanding mutual exclusivity with active tiers — see sibling periodic wiki diagrams. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 32 | RegulationID | int | YES | Customer's assigned regulatory jurisdiction for the **`Fact_SnapshotCustomer` slice active on `@dateID`**. Taken from **`Fact_SnapshotCustomer.RegulationID`**. FK to **`Dim_Regulation`**. Same description spine as **`Fact_SnapshotCustomer`**. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 33 | DesignatedRegulationID | int | YES | Secondary / designated jurisdiction from **`Fact_SnapshotCustomer.DesignatedRegulationID`**. FK to **`Dim_Regulation`**. Same meaning as **`Fact_SnapshotCustomer`**. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 34 | PlayerStatusID | int | YES | Customer lifecycle **`PlayerStatusID`** sourced from **`Fact_SnapshotCustomer`**. FK to **`Dim_PlayerStatus`**. Same meaning as **`Fact_SnapshotCustomer`**. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 35 | IsCreditReportValidCB | int | YES | **`IsCreditReportValidCB = 1` is the regulatory-focused filter for Credit Balance reporting (CB = Client Balance). It includes a small number of subsidiary CB users that `IsValidCustomer` / analytic `IsValidUser` excludes from the standard CB view.** ETL CASE reference: **`Fact_SnapshotCustomer` §2.3**. Column is **passed through from `Fact_SnapshotCustomer`** for the snapshot window intersecting **`@dateID`**. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 36 | IsValidCustomer | int | YES | **`IsValidCustomer = 1` corresponds to analytic `IsValidUser = 1`: the standard business filter (excludes test / internal users); this is the DEFAULT filter for ~99% of analytics. The semantic is “user is real and tradeable for business analytics”. Popular Investors (PIs) are valid users — do NOT treat PIs as non-valid.** Physical column persists `Fact_SnapshotCustomer.IsValidCustomer` for **`@dateID`**. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 37 | AccountTypeID | int | YES | **`Fact_SnapshotCustomer.AccountTypeID`** (Back Office semantics). FK to **`Dim_AccountType`**. Used upstream in **`IsCreditReportValidCB`** logic. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 38 | CountryID | decimal(16,6) | YES | **`Fact_SnapshotCustomer.CountryID`** stored as DECIMAL in narrow table DDL — analytic meaning unchanged (registered country FK to **`Dim_Country`**). Same description lineage as **`Fact_SnapshotCustomer.CountryID`**. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 39 | MarketingRegion | varchar(100) | YES | **`Dim_Country.MarketingRegionManualName`** per final INNER JOIN (`dc.CountryID = sa.CountryID`). Manual marketing-region override sourced from **`Ext_Dim_Country`** lineage per **`Dim_Country` wiki**. Same content meaning as **`Dim_Country.MarketingRegionManualName`**. (Tier 3 — Ext_Dim_Country) |
| 40 | MifidCategorizationID | decimal(16,6) | YES | **`Fact_SnapshotCustomer.MifidCategorizationID`**, stored DECIMAL in DDL. MiFID categorization FK to **`Dim_MifidCategorization`**. Same meaning as Fact table column. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 41 | PlayerLevelID | int | YES | Account tier **`PlayerLevelID`** from **`Fact_SnapshotCustomer`**. FK to **`Dim_PlayerLevel`**. Critical upstream driver for analytic filters (paired with stewardship notes in **`Fact_SnapshotCustomer` §2.2**). (Tier 2 — SP_Fact_SnapshotCustomer) |
| 42 | IsDepositor | int | YES | **`Fact_SnapshotCustomer.IsDepositor`** (FTD sentinel from DWH ingestion) surfaced as **`int`** with `ISNULL(...,0)` in INSERT — same analytic meaning as **`Fact_SnapshotCustomer`**. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 43 | IsFunded | int | YES | Indicator that customer appears in **`Function_Population_Funded(@dateID)`** output for that date (`CASE WHEN Equity join exists`). (Tier 2 — Function_Population_Funded) |
| 44 | FirstTimeFunded | int | YES | 1 when **`FirstFundedDateID = @dateID`** from **`Function_Population_First_Time_Funded`**. Signals first crossing into fully-funded DDR definition used by downstream dashboards. (Tier 2 — Function_Population_First_Time_Funded) |
| 45 | FirstFundedDateID | int | YES | CID’s first-funded **`DateID`** from **`Function_Population_First_Time_Funded`**, **`ISNULL` → `30000101`** sentinel when unknown. (Tier 2 — Function_Population_First_Time_Funded) |
| 46 | FirstActionType | varchar(100) | YES | First qualitative trading/action label from **`Function_Population_First_Trading_Action(1)`**, trimmed by CASE when future-dated vs `@dateID` ⇒ `'NoAction'`. **`ISNULL` → `'NoAction'`** at insert shield. (Tier 2 — Function_Population_First_Trading_Action) |
| 47 | FirstActionDateID | int | YES | `FirstTradeDateID` surrogate passed through `#basicStatuses`; inserted as **`ISNULL(...,30000101)`**. Represents DDR “first meaningful action date” hooking TVF naming. (Tier 2 — Function_Population_First_Trading_Action) |
| 48 | LoggedIn | int | YES | 1 if **`Fact_CustomerAction`** has **`ActionTypeID = 14`** on **`@dateID`** for CID (login aggregator). **`ISNULL` → 0** in INSERT. (Tier 2 — Fact_CustomerAction) |
| 49 | LoggedInTPDepositor | int | YES | Login flag intersected with **TP FTD cohort** marker from **`#depositorsLoggedIn.TPDepositor`**. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 50 | LoggedInIBANDepositor | int | YES | Login ∧ **IBAN FTD** cohort (see `#depositorsLoggedIn.IBANDepositor`). (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 51 | LoggedInGlobalDepositor | int | YES | Login ∧ **global depositor** marker from **`#globalDepositorsAlltime`** join. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 52 | UpdateDate | datetime | YES | `GETDATE()` stamp at insert — operational telemetry, **not business event time**. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 53 | FirstIOBDateID | int | YES | **`Function_Population_First_Time_Funded.FirstIOBDateID`**, first inbound balance event metadata (DDR IOB rollout per SP changelog). (Tier 2 — Function_Population_First_Time_Funded) |
| 54 | FirstIOBTime | datetime | YES | **`Function_Population_First_Time_Funded.FirstIOBTime`** pairing for IOB timestamps. (Tier 2 — Function_Population_First_Time_Funded) |
| 55 | Options_FTD_DateID | int | YES | **`#globalDepositorsAlltime` CASE branch** for **`FTDPlatform = 'Options'`** — Options platform FTD `DateID`. (Tier 2 — Dim_Customer) |
| 56 | Options_FTD_Date | datetime | YES | Options FTD calendar datetime companion. Source CASE logic from **`Dim_Customer`**. (Tier 2 — Dim_Customer) |
| 57 | Options_FTDA | money | YES | Options FTD amount branch from **`Dim_Customer`** aggregator; typed **`money`** in DDL. (Tier 2 — Dim_Customer) |
| 58 | OptionsFirstDeposited | int | YES | **`#mimoUsers.OptionsFirstDeposited`** indicator for Options-platform FTDs executed on **`DateID`**. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 59 | DepositedOptions | int | YES | **`#mimoUsers.DepositedOptions`** indicator — deposit on Options channel on **`DateID`**. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 60 | ReDepositedOptions | int | YES | **`#mimoUsers.ReDepositedOptions`** indicator — redeposit on Options **`DateID`**, non-first-deposit semantics. (Tier 2 — SP_DDR_Customer_Daily_Status) |
| 61 | MoneyFarm_FTD_DateID | int | YES | **`#globalDepositorsAlltime` CASE branch** for MoneyFarm **`FTDPlatformID = 4`**. (Tier 2 — Dim_Customer) |
| 62 | MoneyFarm_FTD_Date | date | YES | **`date`-typed MoneyFarm FTD calendar date** sourced from aggregator CASE branches. (Tier 2 — Dim_Customer) |
| 63 | MoneyFarm_FTDA | money | YES | **`money`-typed MoneyFarm FTD monetary amount.** (Tier 2 — Dim_Customer) |
| 64 | MoneyFarmFirstDeposited | int | YES | Derived insert flag: **`1` iff `MoneyFarm_FTD_DateID = @dateID`**, else **`0`** — aligns Options/MoneyFarm onboarding telemetry with daily grain. (Tier 2 — SP_DDR_Customer_Daily_Status) |

---

## 5. Lineage

### 5.1 Production Sources (column grain summary)

See **`BI_DB_DDR_Customer_Daily_Status.lineage.md`** for the exhaustive 64-column matrix. Conceptual rollup:

| Layer | Columns | Mapping |
|-------|---------|---------|
| `Fact_SnapshotCustomer` + `Dim_Range` | Regulation / valid flags / demographics | As-of **`@dateID`** window |
| `Dim_Customer` + helper FTD CASE sets | TP/IBAN/Options/MoneyFarm & global FTD fields | Lifetime FTD anchors |
| `BI_DB_DDR_Fact_MIMO_AllPlatforms` (+ coercion temps) | `Global*`, platform deposit flags, redeemed paths | **`DateID`-scoped daily** semantics |
| `Function_Population_*` TVFs | Funded/first-trade/balance/portfolio/active signals | Operational classification |
| `Fact_CustomerAction` | `LoggedIn` (+ depositor combos) | **Single-day login** cohort |
| `Dim_Country` | `MarketingRegion` | Manual naming overlay |

### 5.2 ETL Pipeline

```
DDR population sources (Synapse BI_DB_dbo / DWH_dbo / eMoney_dbo)
 ├ BI_DB_Client_Balance_CID_Level_New (@DateID population spine)
 ├ Dim_Customer (+ Dim_FTDPlatform)   (multi-platform FTD metadata)
 ├ eMoney_Fact_Transaction_Status      (IBAN-only supplements)
 └ BI_DB_DDR_Fact_MIMO_*               (_OPTIONS / coercion helpers)
               │
               ├── joins Fact_SnapshotCustomer
               │         └─► Dim_Range (@dateID between FromDateID / ToDateID)
               │
               └── TVFs Function_Population_{Funded|First_Time_Funded|First_Trading_Action|Active_Traders|Portfolio_Only|Balance_Only_Accounts}
                       │
                       ├── Fact_CustomerAction (ActionTypeID 14 ⇒ LoggedIn)
                       └── BI_DB_DDR_Fact_MIMO_AllPlatforms (daily money-move aggregates)
                                       │
SP_DDR_Customer_Daily_Status (@date)
   │ DELETE WHERE DateID = @dateID
   │ INSERT SELECT … JOIN Dim_Country dc ON sa.CountryID = dc.CountryID WHERE RN = 1
   ▼
BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status  (HASH(RealCID), ~13.8B cumulative rows UC)
   │ Generic Pipeline Export (Bronze ► Gold)
   ▼
UC: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status
(+ backup sibling table in UC catalog listing)
```

---

## 6. Relationships

### 6.1 References To

| Column / Key | Targets | Purpose |
|--------------|---------|---------|
| `RealCID` | `Dim_Customer.RealCID`, all DDR fact tables keyed by CID | Universal customer join |
| `RegulationID` | `Dim_Regulation` | Jurisdiction labeling |
| `PlayerStatusID` | `Dim_PlayerStatus` | Status labeling |
| `PlayerLevelID` | `Dim_PlayerLevel` | Account tier labeling |
| `AccountTypeID` | `Dim_AccountType` | Account taxonomy |
| `CountryID` | `Dim_Country` | Geography & compliance overlays |
| `MifidCategorizationID` | `Dim_MifidCategorization` | Investor categorization |

### 6.2 Referenced By

- **`BI_DB_DDR_Customer_Periodic_Status`** — rolling period aggregates (`_ThisWeek/_ThisMonth/...`).
- Numerous DDR tableau extracts / KPI prep (out of scope for this wiki) — consumers always anchor on **`DateID` + `RealCID`**.

---

## 7. Sample Queries

```sql
-- Standard business population for one day (valid-user filter REQUIRED at query time)
SELECT COUNT(*) AS customers
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cds
WHERE cds.DateID = 20260331
  AND cds.IsValidCustomer = 1;  -- analytic “IsValidUser = 1”

-- Credit-balance regulatory slice (distinct from standard valid-user filter)
SELECT COUNT(*) AS cb_customers
FROM BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status cds
WHERE cds.DateID = 20260331
  AND cds.IsCreditReportValidCB = 1;

-- Drill from periodic roll-up back to daily detail
SELECT d.*
FROM BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status p
JOIN BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status d
  ON d.RealCID = p.RealCID
 AND d.DateID = p.DateID
WHERE p.DateID = 20260331
  AND p.RealCID = 123456789;
```

---

## 8. Atlassian Knowledge Sources

| Source | URL |
|--------|-----|
| “new DDR data model” presentation / object walk-through (references DDR Synapse constructs) | [Confluence — BIA / new DDR data model](https://etoro-jira.atlassian.net/wiki/spaces/BIA/pages/13158121475/new+DDR+data+model) |
| “Client Balance and Gaps masterclass” blog (finance context bridging Client Balance & gaps) | [Confluence Blog — Client Balance masterclass](https://etoro-jira.atlassian.net/wiki/spaces/BIA/blog/2023/10/02/12096997208/Client+Balance+and+Gaps+masterclass) |
| “MIMO Analysis” playbook (movement-level definitions feeding same-day aggregates) | [Confluence — MIMO Analysis](https://etoro-jira.atlassian.net/wiki/spaces/FC/pages/12000690235/MIMO+Analysis) |

---

*Generated: 2026-05-14 | Quality: 8.2/10 | Phases documented: execution card P1→P11 + P16 eval*  
*Tiers: 0 T1, 63 T2, 1 T3; Elements: **64/64**, Logic density: High*  
*Object: BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | Production Source: `SP_DDR_Customer_Daily_Status`*
