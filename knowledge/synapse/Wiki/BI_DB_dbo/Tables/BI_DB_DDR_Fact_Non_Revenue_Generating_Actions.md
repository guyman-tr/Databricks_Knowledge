# BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions

> **~1.82B-row** DDR fact for **non-revenue customer actions** (logins, registrations, copy/mirror money flows, open/close **invested amounts**, select compensations, social actions, bonus comp, PnL adjustment comps), aggregated per **`RealCID` × `DateID` × business `ActionType` × `IsCopyFund`**. Loaded daily by **`BI_DB_dbo.SP_DDR_Fact_Non_Revenue_Generating_Actions`** from **`DWH_dbo.Fact_CustomerAction`** with dimension joins; **revenue streams** live in **`BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions`**. **UC Gold table not found** under `main.bi_db` (Databricks MCP 2026-05-14); canonical name follows the `gold_sql_dp_prod_we_bi_db_dbo_*` pattern.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (DDR fact) |
| **Production Source** | `DWH_dbo.Fact_CustomerAction` (+ `Dim_ActionType`, `Dim_CompensationReason`, `Dim_Position`, `Dim_Mirror`, `Fact_SnapshotCustomer`, `Dim_Range`) via `SP_DDR_Fact_Non_Revenue_Generating_Actions` |
| **Row estimate** | ~1.82B (`sys.partitions`, MCP 2026-05-14) |
| **Date span (keys present)** | `DateID` **20070827**–**20260426** (MCP MIN/MAX) |
| **Refresh** | Daily — `DELETE FROM … WHERE DateID = @dateID` + `INSERT` for `@date` |
| **Synapse Distribution** | HASH |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target (canonical name)** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions` |
| **UC Gold status** | **Not deployed / not visible** — `SHOW TABLES IN main.bi_db LIKE '*ddr_fact*'` returned revenue + other DDR facts but **no** `*non_revenue*` (MCP 2026-05-14). `DESCRIBE` on the canonical three-part name: **TABLE_OR_VIEW_NOT_FOUND**. |
| **UC Format** | Delta EXTERNAL (follows sibling BI_DB Gold exports once published) |
| **UC Partitioned By** | *Unknown until table exists — expect `etr_*` mirror of other BI_DB Gold tables* |

---

## 1. Business Meaning

This table is the **DDR non-revenue actions** counterpart to **`BI_DB_DDR_Fact_Revenue_Generating_Actions`**. It answers: **per customer per day**, how many **operational / engagement / flow** actions occurred (counts), and what **monetary surrogates** (`Amount`) the DDR model attaches to those buckets (invested amounts on opens/closes, copy funding, compensations, etc.) — **excluding** revenue TVF streams modeled elsewhere.

Each row is an aggregation at grain **`DateID` + `RealCID` + synthesized `ActionType` + `IsCopyFund`** (two-stage `GROUP BY` inside the SP). Individual `Fact_CustomerAction` rows are rolled up before the semantic `CASE` layer; anything that resolves to **`NA`** is discarded (`WHERE … <> 'NA'`).

Operational note from SP header: **`IsCopyFund`** required a workaround because **`Fact_CustomerAction`** may omit **`MirrorID`** for **`ActionTypeID = 5`** — the loader joins **`Dim_Position`** for mirror detection as well as the fact’s **`MirrorID`**.

---

## 2. Business Logic

### 2.1 Effective `ActionTypeID` coverage (WHAT is “non-revenue” here)

**Important:** **`#fcaPrep` does not filter `ActionTypeID`.** Inclusion is **`CASE`**-driven: only rows whose mapped label is **`<> 'NA'`** are inserted (`SP_DDR_Fact_Non_Revenue_Generating_Actions`, final `SELECT`). Effective IDs match the **`WHEN`** branches:

| Labels (examples) | `ActionTypeID` | Extra keys |
|-------------------|----------------|------------|
| Compensation* / `C2P` / `PnLAdjustment` | **36** | `CompensationReasonID` (see SP `CASE` for each label) |
| `EditStoploss` | **32** | |
| `InvestmentAmountInNewTrades` | **1, 2, 3, 39** | |
| `InvestmentAmountClosedTrades` | **4, 5, 6, 28, 40** | |
| `DepositorsLoggedIn` / `LoggedIn` | **14** | Requires depositor cohort from **`Fact_SnapshotCustomer`** + **`Dim_Range`** |
| `Registred` *(spelling in SP)* | **41** | |
| `AddToCopy`, `RemoveFromCopy`, `NewCopy`, `StopCopy` | **15, 16, 17, 18** | |
| `PublishPost`, `PublishComment`, `PublishLike` | **21, 22, 23** | |
| `BonusComp` | **9** | |

All **`Fact_CustomerAction`** rows on `@dateID` **outside** these combinations fall through **`ELSE 'NA'`** and **do not** appear in this table.

### 2.2 Phase 3 — TOP `ActionTypeID` by raw row volume (Evidence)

Synapse MCP: **`Fact_CustomerAction`** rows **`DateID = 20260426`** (latest `MAX(DateID)` in target table at query time), depositor cohort wired like the SP, **`CASE`** identical to **`#fcaBizPrep`**, **`WHERE BizAction <> 'NA'`**. Only **15** distinct IDs fired that day:

| Rank | `ActionTypeID` | `Dim_ActionType.Name` | Row count (`Fact_CustomerAction`) |
|------|----------------|-----------------------|-----------------------------------|
| 1 | 14 | LoggedIn | 421078 |
| 2 | 41 | Customer Registration | 40354 |
| 3 | 4 | ManualPositionClose | 15392 |
| 4 | 1 | ManualPositionOpen | 15029 |
| 5 | 5 | CopyPositionClose | 13141 |
| 6 | 32 | Edit StopLoss | 9270 |
| 7 | 2 | CopyPositionOpen | 6686 |
| 8 | 9 | Bonus | 1219 |
| 9 | 17 | Register new mirror | 1123 |
| 10 | 18 | Unregister mirror | 555 |
| 11 | 15 | Account balance to mirror | 537 |
| 12 | 16 | Mirror balance to account | 245 |
| 13 | 6 | CopyPlusPositionClose | 155 |
| 14 | 36 | Compensation | 80 |
| 15 | 3 | CopyPlusPositionOpen | 5 |

(Joint to **`DWH_dbo.Dim_ActionType`** for **`Name`**; counts are **pre-final-aggregation** event rows, not DDR fact rows.)

### 2.3 `Amount` and `CountActions` semantics

**What:** Measures attached to DDR buckets after SP-side rescaling.

**Columns:** `Amount`, `CountActions`

**Rules:**

- **`CountActions`:** `COUNT(RealCID)` at the first grouped temp (`#fca`), then **`SUM`**’d in `#fcaBiz` — interpret as **number of underlying customer actions** in the bucket.
- **`Amount`:** **`SUM(Fact_CustomerAction.Amount)`** with **`CASE`** sign rules (e.g. negatives for several “money into position/copy” buckets, **0** for pure activity rows like logins / social / registration). See SP `#fcaBizPrep` for the authoritative per-`ActionTypeID` mapping.

### 2.4 `IsCopyFund`

**What:** Flags Smart Portfolio / copy-fund context via **`Dim_Mirror.MirrorTypeID = 4`**.

**Columns:** `IsCopyFund`

**Rules:**

- **`1`** when **`COALESCE(position-path MirrorID, fact-path MirrorID)`** matches a **`Dim_Mirror`** row with **`MirrorTypeID = 4`**; else **`0`**.
- SP author note: **`Fact_CustomerAction.MirrorID`** gap for **`ActionTypeID = 5`** — position join path is required.

---

## 3. Query Advisory

### 3.1 Synapse distribution and index

**HASH** distribution policy (dedicated pool catalog) with **clustered columnstore** — always filter **`DateID`** (and **`RealCID`** for point lookups). Table is **~1.8B rows**.

### 3.2 Common query patterns

| Analyst question | Approach |
|------------------|----------|
| Daily login volume | `WHERE ActionType IN ('LoggedIn','DepositorsLoggedIn')` + `SUM(CountActions)` |
| New vs closed invested amounts | Filter `ActionType` **`InvestmentAmountInNewTrades`** vs **`InvestmentAmountClosedTrades`** |
| Compensation mix | `WHERE ActionType LIKE 'Compensation%' OR ActionType IN ('C2P','PnLAdjustment')` |
| Copy-fund slice | `WHERE IsCopyFund = 1` |

### 3.3 Common JOINs

| Join to | Condition | Purpose |
|---------|-----------|---------|
| `DWH_dbo.Dim_Customer` | `t.RealCID = dc.RealCID` | Segmentation / attributes |
| `DWH_dbo.Dim_Date` | `t.DateID = dd.DateID` | Calendar labels |
| `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions` | `RealCID` + `DateID` | Compare revenue vs non-revenue DDR metrics |

### 3.4 Gotchas

- **`Registred` spelling** is literal in `ActionType` (SP string).
- **Not exhaustive of all “non-revenue” events** — only IDs handled in the **`CASE`**; massive families (e.g. fees, many ledger action types) **map to `NA`** and **never load** here.
- **`Amount` is not company revenue** — compare to **`BI_DB_DDR_Fact_Revenue_Generating_Actions`** for fee/spread revenue.
- **Row grain** is **aggregated** — do not equate `CountActions` to distinct `HistoryID` rows.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 1** | Production-grounded — inherited verbatim from canonical `Fact_CustomerAction` / `Dim_Customer` semantics |
| **Tier 2** | DDR SP / loader logic (`SP_DDR_Fact_Non_Revenue_Generating_Actions`, aggregates, `CASE`, `GETDATE()`) |
| **Tier 3** | Operational / lightly documented |
| **Tier 4** | Confluence-linked [UNVERIFIED] — none identified |
| **Tier 5** | Expert-only / deprecation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NO | **`Occurred`** → `YYYYMMDD` int (nonclustered index driver). (Tier 2 — SP_Fact_CustomerAction) |
| 2 | Date | date | YES | Calendar **`@date`** parameter surfaced as a column (`@date AS [Date]`). (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 3 | RealCID | int | YES | Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic) |
| 4 | ActionType | varchar(200) | YES | DDR business bucket — `CASE` on `ActionTypeID` + `CompensationReasonID` + depositor cohort; unmapped combos become **`NA`** and are filtered out before insert (see §2.1). (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 5 | Amount | decimal(16,6) | YES | Aggregated `Fact_CustomerAction.Amount` with SP sign / zero rules per `ActionType` (see `#fcaBizPrep`). (Tier 2 — Fact_CustomerAction via SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 6 | CountActions | int | YES | Count of underlying actions in bucket — first-stage `COUNT(RealCID)`, then summed. (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 7 | UpdateDate | datetime | YES | ETL load watermark — **`GETDATE()`** at insert. (Tier 2 — SP_DDR_Fact_Non_Revenue_Generating_Actions) |
| 8 | IsCopyFund | int | YES | **`1`** when mirrored as Smart Portfolio / copy fund via **`Dim_Mirror.MirrorTypeID = 4`** (`COALESCE` position-path and fact-path `MirrorID`); **`0`** otherwise. (Tier 2 — Dim_Position / Dim_Mirror via SP_DDR_Fact_Non_Revenue_Generating_Actions) |

---

## 5. Lineage

### 5.1 Production sources

| Synapse Column | Immediate upstream | Transform |
|----------------|-------------------|-----------|
| `DateID`, `RealCID`, raw measures | `DWH_dbo.Fact_CustomerAction` (@date slice) | Group / sum |
| Labels / joins | `Dim_ActionType`, `Dim_CompensationReason` | enrichment |
| `IsCopyFund` | `Dim_Position`, `Dim_Mirror`, fact `MirrorID` | CASE |
| Depositor split | `Fact_SnapshotCustomer`, `Dim_Range` | login bucket |

### 5.2 ETL pipeline

```
DWH_dbo.Fact_CustomerAction (single DateID=@dateID)
 ├► #fcaPrep
 └► #fca (aggregated base)
      └► #fcaBizPrep (CASE ActionType / Amount signs + depositor rules)
           └► #fcaBiz (re-aggregate)
                 └► SP_DDR_Fact_Non_Revenue_Generating_Actions
                      DELETE WHERE DateID=@dateID
                      INSERT SELECT … WHERE ActionType <> 'NA'

BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions  (~1.82B rows)

--- Gold export (Databricks) ---
[Pending — no main.bi_db table observed 2026-05-14]
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_non_revenue_generating_actions  ← canonical naming only
```

---

## 6. Relationships

### 6.1 References to

| Element | Related object |
|---------|----------------|
| `RealCID` | `DWH_dbo.Dim_Customer` |
| `DateID` | `DWH_dbo.Dim_Date` |

### 6.2 Referenced by

| Consumer | Notes |
|----------|-------|
| `BI_DB_dbo.BI_DB_V_DDR_Non_Revenue_Generating_Actions` | View wrapper for DDR SQL |

---

## 7. Sample queries

### 7.1 Depositors vs non-depositors login counts

```sql
SELECT ActionType,
       SUM(CountActions) AS Actions
FROM BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions
WHERE DateID = 20260426
  AND ActionType IN ('LoggedIn','DepositorsLoggedIn')
GROUP BY ActionType;
```

### 7.2 Net invested surrogates (opens vs closes)

```sql
SELECT CASE WHEN ActionType = 'InvestmentAmountInNewTrades' THEN 'Open'
            WHEN ActionType = 'InvestmentAmountClosedTrades' THEN 'Close' END AS Leg,
       SUM(Amount) AS Amount,
       SUM(CountActions) AS Actions
FROM BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions
WHERE DateID BETWEEN 20260401 AND 20260407
  AND ActionType IN ('InvestmentAmountInNewTrades','InvestmentAmountClosedTrades')
GROUP BY CASE WHEN ActionType = 'InvestmentAmountInNewTrades' THEN 'Open'
              WHEN ActionType = 'InvestmentAmountClosedTrades' THEN 'Close' END;
```

### 7.3 Copy-fund flagged activity

```sql
SELECT ActionType,
       SUM(CountActions) AS Actions,
       SUM(Amount) AS Amount
FROM BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions
WHERE DateID = 20260426
  AND IsCopyFund = 1
GROUP BY ActionType
ORDER BY Actions DESC;
```

---

## 8. Atlassian knowledge sources

No Confluence pages returned for **`Non_Revenue_Generating_Actions`** / **DDR non-revenue** CQL search (`searchConfluenceUsingCql`, **2026-05-14**).

---

*Generated: 2026-05-14 | Quality: 8.7/10 | Phases: 14/14 (incl. Phase 16 review in `.review-needed.md`)*
*Tiers: 1 T1, 7 T2, 0 T3, 0 T4, 0 T5 | Elements: 8/8*
*Object: BI_DB_dbo.BI_DB_DDR_Fact_Non_Revenue_Generating_Actions | Type: Table | Production Source: Fact_CustomerAction → SP_DDR_Fact_Non_Revenue_Generating_Actions*
