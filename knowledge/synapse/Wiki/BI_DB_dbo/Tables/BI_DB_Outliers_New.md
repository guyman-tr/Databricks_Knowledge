# BI_DB_dbo.BI_DB_Outliers_New

<!--
PHASE 1–10 gates (speckit 2026-05-14): P1 DDL Synapse MCP ✓ · P2 live sample ✓ · P3 distribution ✓
· P4 lookup (Dim_Customer/Dim_Regulation) ✓ · P5 joins ✓ · P6 biz rules ✓ · P8–P9 SP_Outliers_New ✓
· P10 Atlassian/Rovo outliers + credit-valid context ✓ · P10B lineage ✓ · P16 adversarial recheck ✓ → P11
-->

**Schema**: BI_DB_dbo | **UC Target**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_outliers_new`
**Row count**: 6,555 total (min `[Date]` 2015-01-12 → max `[Date]` 2026-04-25 — Synapse read 2026-05-14) | **Refresh**: daily | **Orchestration**: Priority 99 `FinanceReportSPS` (`SP_Outliers_New`)
**Distribution**: REPLICATE | **Structure**: HEAP

---

## 1. Business Meaning

Daily **outlier** population of customers whose **credit-report relevance flag** `IsCreditReportValidCB` (materialized here as string `CreditReportValid`) **changed between consecutive snapshot dates**. Each retained row attaches the customer’s **cumulative lifetime money movements up to (and including)** `DateID ≤ @ld_t2` (day *before* the processing stamp) across twenty harmonized Fact_CustomerAction/V_Liabilities baskets so finance can reconcile **client balance / BI panels without transition-day distortions**.

Confluence narration (Rovo search hit: *Client Balance and Gaps masterclass*, BIA blog 2023-10-02) describes the same validity flag flipping between valid/non-valid regimes and tying it to elimination of residual “gap” artefacts when netting exposure.

These rows are deliberately **narrow**: stable customers never appear.

---

## 2. Business Logic

### 2.1 Outlier Inclusion Rule (exclusive definition)

`SP_Outliers_New` intersects today’s snapshot (`Fact_SnapshotCustomer.DateKey=@ld`) with yesterday (`DateKey=@ld_t2`). A customer survives only where `CurrStat ≠ PrevStat` for `CurrStat = IsCreditReportValidCB`.

### 2.2 Financial Grain

All nineteen substantive money columns accumulate **lifetime** Facts up to `@ld_t2` (historical—not just the turnover on the `[Date]` row).

### 2.3 Sign Flip for Newly Invalid Rows

Whenever `CreditReportValid='0'`, negate every money column plus `[Cycle Calculation]` × −1 before persist. Rows with `'1'` keep original signed totals.

Interpretation shorthand after flip:
- Rows moving **Invalid → Valid** typically present **positive** net exposure after flip policy.
- Rows moving **Valid → Invalid** invert previously positive balances to **negative**.

### 2.4 NULL vs 0 semantics

Absent LEFT JOIN aggregates surface **NULL**, not zero. Numeric zero denotes an actual net-zero cumulative history segment.

### 2.5 `[Unrealized Commission Change]`

Historical tail still contains sparse non-null totals (CommissionOnOpen provenance via `Fact_CustomerUnrealized_PnL` temp); **modern runs insert literal NULL**. Live totals (Synapse MCP 2026-05-14): 6,513 NULL vs 42 non-null (legacy through ~2018). Treat as mostly NULL column for dashboards.

### 2.6 DLT experiment retired

Tickets SR-264692 / SR-281275 chronicle additive then removed DLT transition handling—today only the two textual `Transition` values appear in warehouse rows.

---

## 3. Query Advisory

1. **Bracket any column containing spaces**.
2. `CreditReportValid` stores `'0'` / `'1'` strings—never bitwise equality with integers.
3. `UpdateDate` is `varchar(50)` (SP stringified `GETDATE()`); analytic windows must pivot on `[Date]` / `[DateID]`.
4. Because financial fields are cumulative through `@ld_t2`, never join blindly to daily deltas without reading §2.
5. For UC consumers prefer **`V_BI_DB_Outliers_New`** (thin rename on one column vs base table DDL).

---

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| RealCID | int | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) | — | FK to Dim_Customer |
| Regulation | varchar(50) | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation) | — | 14 regs at snapshot date |
| CreditReportValid | varchar(50) | Post-transition `IsCreditReportValidCB`, stored as `'0'`/`'1'`. Determines sign flip envelope. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | string compare only |
| Transition | varchar(50) | Directional narration: `'Invalid to Valid'` or `'Valid To Invalid'`; CASE fallback `'NA'` is unreachable once DLT path removed (verified zero rows MCP 2026-05-14). (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | cardinality 2 observed |
| Deposit Amounts | decimal(19,4) | Lifetime gross deposits (`ActionTypeID = 7`, `DateID ≤ @ld_t2`) multiplied by −1 when `CreditReportValid='0'`. NULL absent deposit history. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | cumulative |
| Compensation Deposit | decimal(19,4) | Lifetime compensation bucket `ActionTypeID=36 ∧ CompensationReasonID=7`; sign flipped for invalid cohort. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| GivenBonus | decimal(19,4) | Lifetime `ActionTypeID=9`; sign flipped for invalid cohort. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Compensation | decimal(19,4) | Residual ReasonID≠{7,8,11,17,18,22,30,31,32,33,34,36,37,38,40,41,51,52} subset of compensation actions; mirrored logic from SP temp `#Compensation`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Compensation PI | decimal(19,4) | `ActionTypeID=36 ∧ CompensationReasonID=41`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Compensation To Affiliates | decimal(19,4) | `ActionTypeID=36 ∧ CompensationReasonID IN (8,51,52)`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Cashout Amounts | decimal(19,4) | Lifetime `ActionTypeID=8`; flipped for invalid rows. NULL when untouched. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Compensation Cashouts | decimal(19,4) | `CompensationReasonID=33`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Cashout Fee | decimal(19,4) | `ActionTypeID=30` commission rollups (SP pre-multiplies −1 internally, then participates in invalid-row outer negation exactly once). (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | nested sign handling |
| Chargeback | decimal(19,4) | `ActionTypeID IN (11,13)`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | incl reversals |
| Refund | decimal(19,4) | `ActionTypeID=12`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| ClientBalanceCommission | decimal(19,4) | Closed-trade commission leakage (`ActionTypeID IN (4,5,6,28,40)` on `CommissionOnClose` × −1 before outer flip). (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Over The Weekend Fee | decimal(19,4) | Overnight fee (`ActionTypeID=35`). (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Chargeback Loss | decimal(19,4) | From `V_Liabilities`: negative balances with exotic `PlayerStatusID` exclusions {1,3,5,7}. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Other Negative | decimal(19,4) | Complimentary slice of liabilities rows with standard statuses in {1,3,5,7}. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | complements row above |
| Compensation PnL Adjustment | decimal(19,4) | `CompensationReasonID=22`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | Synapse DDL spelling `PnL` |
| Compensation DormantFee | decimal(19,4) | `CompensationReasonID=30`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| ClientBalance Realized PnL | decimal(19,4) | `NetProfit` for close events (`ActionTypeID IN (4,5,6,28,40)`). (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Unrealized Commission Change | decimal(19,4) | Planned home for unrealized commission delta (CommissionOnOpen) but INSERT now hard-nulls column; surviving non-null tails correspond to archived CommissionOnOpen runs (42 rows MCP 2026-05-14). (Tier 2 — BI_DB_dbo.SP_Outliers_New + live Synapse distribution) | — | predominantly NULL |
| Cycle Calculation | decimal(19,4) | Net of the nineteen enumerated component columns respecting NULL arithmetic; inherits sign flip envelope. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Foreclosure | decimal(19,4) | `CompensationReasonID=32`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Lost Debt | decimal(19,4) | `CompensationReasonID=31`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| Date | date | Business detection date `@ld`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | |
| DateID | int | `YYYYMMDD(@ld)`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | delete key |
| Negative Refill Compensation | decimal(19,4) | `CompensationReasonID=11`; physically last money column (`ORDINAL_POSITION=29`). (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | logical vs physical ordering nuance |
| UpdateDate | varchar(50) | Stringified warehouse load audit (`GETDATE()` at SP runtime). Not SQL `datetime`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | Propagation-tier metadata analogue |

*(Tier column intentionally blank — tier lives inside Description cell for tooling/GATE uniformity.)*

---

## 5. Lineage

### 5.1 Source Objects

| Source | Layer | Role |
|--------|-------|------|
| DWH_dbo.Fact_SnapshotCustomer | DWH snapshot | Validity deltas + RegulationID |
| DWH_dbo.Fact_CustomerAction | DWH ledger | Monetary buckets |
| DWH_dbo.V_Liabilities | DWH view | Negative-liability splits |
| DWH_dbo.Fact_CustomerUnrealized_PnL | DWH unrealized stack | Historic CommissionOnOpen (column now NULL-loaded) |
| DWH_dbo.Dim_Regulation | DWH dict | Regulatory label |
| DWH_dbo.Dim_Range / Dim_Date | DWH calendar | binds snapshot windows |

```
UPSTREAM SEARCH LOG — BI_DB_Outliers_New:
  Lineage sources:
    1. DWH_dbo.Fact_SnapshotCustomer → (a) local wiki Tables/Fact_SnapshotCustomer.md FOUND Read=YES · (b) prod via DWH lineage only
    2. DWH_dbo.Fact_CustomerAction   → (a) FOUND Read=YES
    3. DWH_dbo.V_Liabilities         → (a) FOUND Views/V_Liabilities.md Read=YES
    4. DWH_dbo.Fact_CustomerUnrealized_PnL → (a) NOT_FOUND (fallback Tier2 SP-only)
    5. DWH_dbo.Dim_Regulation       → (a) FOUND Read=YES · inherits Dictionary.Regulation for Regulation column verbatim
    6. DWH_dbo.Dim_Customer          → (a) FOUND Read=YES · RealCID description copied verbatim §4
```

### 5.2 ETL Pipeline Narrative

| Step | Artifact | Detail |
|------|----------|--------|
| Warm | `@ld`, `@ld_t2`, temp `#cid/#Deposit/...` per SP_Outliers_New | Built inside FinanceReport priority lane |
| Clean | `DELETE BI_DB_Outliers_New WHERE DateID=@ld_t` | Idempotent per day |
| Load | INSERT from `#out` | Applies sign envelopes |
| Consume | Views + dashboards | Exclude or separately net these outliers when computing stable BI KPIs |

---

## 6. Relationships

See prior revision — primary joins remain `Dim_Customer.RealCID` and same-day aggregates in `BI_DB_Client_Balance_CID_Level_New`.

---

## 7. Sample Queries

```sql
-- Recent transitions with headline balances
SELECT TOP 50 [Date],
       RealCID,
       Regulation,
       Transition,
       [Cycle Calculation],
       [Deposit Amounts],
       [Cashout Amounts]
FROM BI_DB_dbo.BI_DB_Outliers_New
WHERE [Date] >= DATEADD(month, -3, CAST(GETDATE() AS date))
ORDER BY [Date] DESC;

-- Legacy unrealized residuals (non-null tails)
SELECT MIN([Date]) AS first_hit,
       MAX([Date]) AS last_hit,
       COUNT(*)    AS residual_rows
FROM BI_DB_dbo.BI_DB_Outliers_New
WHERE [Unrealized Commission Change] IS NOT NULL;
```

---

## 8. Atlassian / Change History

Human-readable changelog (Markdown table suppressed to avoid tooling collisions):

- SR-281275 (2024-11-18, Guy M) — removed obsolete DLT outlier bifurcation; transitions collapse to validity flips only.
- SR-264692 (2024-07-30, Guy M) — introduced transitional DLT logging (later rolled back via SR-281275).
- 2020-05-20 / 2019-10-07 / 2018-08-16 — historical Synapse lineage entries captured from legacy operational notes (“IsCreditReportValidCB rename”, tighter `DateID` filter, Katy F foundational port).

Additional Confluence signal (Phase 10 Rovo sweep 2026-05-14):

- Title *Outliers management and logic – Risk Policy* — documents enterprise outlier taxonomy (orthogonal risk controls; corroborating language only).
- Title *Risk Policy – General information* — generic outlier instrumentation for instruments (not identical grain but validates corporate vocabulary).
