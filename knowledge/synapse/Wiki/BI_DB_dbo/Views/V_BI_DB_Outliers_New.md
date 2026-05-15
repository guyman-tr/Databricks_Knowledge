# BI_DB_dbo.V_BI_DB_Outliers_New

> Canonical Unity Catalog façade over **`BI_DB_dbo.BI_DB_Outliers_New`**. Warehouse metadata hides the persisted `CREATE VIEW` text (`sys.sql_modules` / `INFORMATION_SCHEMA.VIEWS` return blank in sql_dp_prod_we), but a column-for-column diff shows **one rename**: base `[Compensation PnL Adjustment]` exports as **`Compensation P&L Adjustment`** (ampersand) for downstream SQL/Spark clients. All other fields are value-identical passthrough.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | View (thin projection) |
| **Base Table** | `BI_DB_dbo.BI_DB_Outliers_New` |
| **Writer** | Inherits table refresh via `SP_Outliers_New` |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_outliers_new` |
| **Row parity** | 1:1 with base on any `[Date]` slice |

---

## 1. Business Meaning

See [`BI_DB_Outliers_New.md`](../Tables/BI_DB_Outliers_New.md) §§1–3 for the full “credit-report validity outlier” narrative, sign-flip rules, and NULL vs 0 semantics. Use this view whenever Unity Catalog / Databricks SQL requires the UC-friendly column spelling for the PnL adjustment field.

---

## 2. View Definition (reconstructed)

```sql
CREATE VIEW [BI_DB_dbo].[V_BI_DB_Outliers_New] AS
SELECT
    [RealCID],
    [Regulation],
    [CreditReportValid],
    [Transition],
    [Deposit Amounts],
    [Compensation Deposit],
    [GivenBonus],
    [Compensation],
    [Compensation PI],
    [Compensation To Affiliates],
    [Cashout Amounts],
    [Compensation Cashouts],
    [Cashout Fee],
    [Chargeback],
    [Refund],
    [ClientBalanceCommission],
    [Over The Weekend Fee],
    [Chargeback Loss],
    [Other Negative],
    [Compensation PnL Adjustment] AS [Compensation P&L Adjustment],
    [Compensation DormantFee],
    [ClientBalance Realized PnL],
    [Unrealized Commission Change],
    [Cycle Calculation],
    [Foreclosure],
    [Lost Debt],
    [Date],
    [DateID],
    [Negative Refill Compensation],
    [UpdateDate]
FROM [BI_DB_dbo].[BI_DB_Outliers_New];
```

*(Layout inferred 2026-05-14; only the single `AS` alias is observed evidence.)*

---

## 3. Query Advisory

1. Always reference `Compensation P&L Adjustment` (ampersand) in UC—base table still uses `Compensation PnL Adjustment`.
2. Otherwise identical cautions on varchar flags, varchar `UpdateDate`, and cumulative balances apply from the table wiki.

---

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| RealCID | int | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) | — | passthrough |
| Regulation | varchar(50) | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation) | — | passthrough |
| CreditReportValid | varchar(50) | Post-transition `IsCreditReportValidCB`, stored as `'0'`/`'1'`. Determines sign flip envelope. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Transition | varchar(50) | Directional narration: `'Invalid to Valid'` or `'Valid To Invalid'`; CASE fallback `'NA'` unreachable post-DLT removal. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Deposit Amounts | decimal(19,4) | Lifetime gross deposits (`ActionTypeID = 7`, `DateID ≤ @ld_t2`) multiplied by −1 when `CreditReportValid='0'`. NULL absent deposit history. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Compensation Deposit | decimal(19,4) | Lifetime compensation bucket `ActionTypeID=36 ∧ CompensationReasonID=7`; sign flipped for invalid cohort. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| GivenBonus | decimal(19,4) | Lifetime `ActionTypeID=9`; sign flipped for invalid cohort. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Compensation | decimal(19,4) | Residual ReasonID≠{7,8,11,17,18,22,30,31,32,33,34,36,37,38,40,41,51,52} subset of compensation actions; mirrored logic from SP temp `#Compensation`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Compensation PI | decimal(19,4) | `ActionTypeID=36 ∧ CompensationReasonID=41`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Compensation To Affiliates | decimal(19,4) | `ActionTypeID=36 ∧ CompensationReasonID IN (8,51,52)`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Cashout Amounts | decimal(19,4) | Lifetime `ActionTypeID=8`; flipped for invalid rows. NULL when untouched. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Compensation Cashouts | decimal(19,4) | `CompensationReasonID=33`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Cashout Fee | decimal(19,4) | `ActionTypeID=30` commission rollups (SP pre-multiplies −1 internally, then participates in invalid-row outer negation exactly once). (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Chargeback | decimal(19,4) | `ActionTypeID IN (11,13)`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Refund | decimal(19,4) | `ActionTypeID=12`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| ClientBalanceCommission | decimal(19,4) | Closed-trade commission leakage (`ActionTypeID IN (4,5,6,28,40)` on `CommissionOnClose` × −1 before outer flip). (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Over The Weekend Fee | decimal(19,4) | Overnight fee (`ActionTypeID=35`). (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Chargeback Loss | decimal(19,4) | From `V_Liabilities`: negative balances with exotic `PlayerStatusID` exclusions {1,3,5,7}. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Other Negative | decimal(19,4) | Complimentary slice of liabilities rows with standard statuses in {1,3,5,7}. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Compensation P&L Adjustment | decimal(19,4) | Same measure as base `[Compensation PnL Adjustment]` (`CompensationReasonID=22`); Synapse exposes the UC-safe alias **`Compensation P&L Adjustment`** (ampersand) in this view. (Tier 2 — BI_DB_dbo.SP_Outliers_New, view rename) | — | ONLY column renamed |
| Compensation DormantFee | decimal(19,4) | `CompensationReasonID=30`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| ClientBalance Realized PnL | decimal(19,4) | `NetProfit` for close events (`ActionTypeID IN (4,5,6,28,40)`). (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Unrealized Commission Change | decimal(19,4) | Planned home for unrealized commission delta but INSERT currently NULL; sparse historic CommissionOnOpen tail (Synapse MCP 2026-05-14). (Tier 2 — BI_DB_dbo.SP_Outliers_New + live Synapse distribution) | — | passthrough |
| Cycle Calculation | decimal(19,4) | Net of the nineteen enumerated component columns respecting NULL arithmetic; inherits sign flip envelope. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Foreclosure | decimal(19,4) | `CompensationReasonID=32`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Lost Debt | decimal(19,4) | `CompensationReasonID=31`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Date | date | Business detection date `@ld`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| DateID | int | `YYYYMMDD(@ld)`. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| Negative Refill Compensation | decimal(19,4) | `CompensationReasonID=11`; physical ordinal 29 in both view and table. (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |
| UpdateDate | varchar(50) | Stringified warehouse load audit (`GETDATE()` at SP runtime). (Tier 2 — BI_DB_dbo.SP_Outliers_New) | — | passthrough |

*(Tier echoes inside Description cells for GATE tooling.)*

---

## 5. Lineage

Thin view → `BI_DB_dbo.BI_DB_Outliers_New` → Fact_SnapshotCustomer / Fact_CustomerAction / `V_Liabilities` (+ unrealized artefacts). Detailed hop table lives in [`BI_DB_Outliers_New.lineage.md`](../Tables/BI_DB_Outliers_New.lineage.md).
