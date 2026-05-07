# DWH_dbo.V_Fact_CustomerAction_for_generic

> **8-date test/sample view** over `DWH_dbo.Fact_CustomerAction` — `SELECT * FROM Fact_CustomerAction WHERE DateID IN (20220819, 20220825, 20220826, 20220827, 20220901, 20220902, 20230120, 20230926)`. The "_for_generic" suffix indicates this view was built specifically as a fixed-data sample for **generic-pipeline testing** (small, deterministic, reproducible). Production analytics that need customer-action data should query the parent `Fact_CustomerAction` directly — not this view.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View — test/sample over Fact_CustomerAction |
| **Production Source** | `DWH_dbo.Fact_CustomerAction` (the canonical fact) |
| **Refresh** | None — static date-list filter; rows change only if Fact_CustomerAction is back-filled for those 8 dates |
| **Date Coverage** | 8 hand-picked DateIDs spanning 2022-08-19 → 2023-09-26 |
| **Grain** | One row per HistoryID (passthrough from Fact_CustomerAction) |
| | |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (generic pipeline test fixture) |

---

## 1. Business Meaning

This is a **fixture view** — not a production-analytics view. It exists so the generic-pipeline export framework has a small, deterministic slice of `Fact_CustomerAction` to round-trip through staging → silver → gold without dragging billions of rows. The 8 dates were hand-picked to cover representative business situations (e.g. weekend, month-boundary, weekday, 2022 + 2023 spread).

For all production reporting against customer actions, refer to the parent fact and its wiki:
- See `DWH_dbo/Tables/Fact_CustomerAction.md` for full column documentation, business logic, and lineage.

The view is `SELECT *`, so every column inherits its semantics from the parent table — there is no transformation, no rename, no aggregation. This wiki therefore intentionally keeps column descriptions short and refers to the parent for the detailed ActionType decode, NetProfit/Commission accounting, and DDR linkage.

---

## 2. Query Advisory

### 2.1 Use the Parent

If you find yourself joining `V_Fact_CustomerAction_for_generic` for any actual analysis, **stop and switch to `Fact_CustomerAction`**. The view's date filter is a feature for the test framework, not a feature for analysts.

### 2.2 Test-Fixture Use

```sql
-- Test that the gold export is round-tripping all 8 dates
SELECT DateID, COUNT(*) AS rows_cnt
FROM   main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic
GROUP  BY DateID
ORDER  BY DateID
```

### 2.3 Gotchas

- **Don't query for "recent" customer actions** — the latest date in this view is 2023-09-26.
- **Hard-coded date list**: if a date list is added/removed, the gold-export semantics change unannounced. Treat as fixture, not source of truth.
- **`SELECT *` view** — column ordering and types follow `Fact_CustomerAction` exactly. Backwards-incompatible changes there ripple here.

---

## 3. Elements

All 71 elements are passthrough from `DWH_dbo.Fact_CustomerAction`. See `DWH_dbo/Tables/Fact_CustomerAction.md` for full descriptions of each. Brief summaries follow for UC-comment population only.

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| ** | Tier 2 | Inherited from Fact_CustomerAction wiki |
| * | Tier 3 | Inferred from name [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HistoryID | decimal(38,0) | NO | Surrogate primary key — one row per customer-action event. Inherited from Fact_CustomerAction. (Tier 2) |
| 2 | GCID | int | NO | Global Customer ID. (Tier 2) |
| 3 | RealCID | int | NO | Real customer ID — joins to `Dim_Customer.RealCID`. (Tier 2) |
| 4 | DemoCID | int | NO | Demo (paper-trading) customer ID, when applicable. (Tier 2) |
| 5 | Occurred | datetime | NO | Action timestamp. Date component matches DateID. (Tier 2) |
| 6 | IPNumber | bigint | YES | IP address of the action (numeric form). (Tier 2) |
| 7 | IsReal | tinyint | NO | Real (1) vs Demo (0) account flag. (Tier 2) |
| 8 | ActionTypeID | smallint | NO | FK to `Dim_ActionType` — decodes to action label (Trade Open, Cashout, Login, Deposit, etc.). (Tier 2) |
| 9 | PlatformTypeID | smallint | NO | FK to `Dim_PlatformType` — Web, Mobile, OpenAPI, etc. (Tier 2) |
| 10 | InstrumentID | int | NO | FK to `Dim_Instrument` — the asset traded, when ActionType is trade-related. (Tier 2) |
| 11 | Amount | decimal(11,2) | NO | Action amount in customer currency. Semantics depend on ActionType. (Tier 2) |
| 12 | Leverage | int | NO | Position leverage (1, 2, 5, 10, ...). 1 for non-leveraged. (Tier 2) |
| 13 | NetProfit | money | NO | Net profit/loss on the action. Used heavily by DDR rollup. (Tier 2) |
| 14 | Commission | money | NO | Commission charged on the action (post-discount). (Tier 2) |
| 15 | PositionID | bigint | NO | FK to the position the action belongs to (when applicable). (Tier 2) |
| 16 | CampaignID | int | NO | Marketing campaign ID, when the action is attributed to a campaign. (Tier 2) |
| 17 | BonusTypeID | smallint | NO | FK to `Dim_BonusType` — type of bonus credited (when ActionType is a bonus event). (Tier 2) |
| 18 | FundingTypeID | smallint | NO | FK to `Dim_FundingType` — funding method (when ActionType is deposit-related). (Tier 2) |
| 19 | LoginID | int | NO | Login session ID — one per session. (Tier 2) |
| 20 | MirrorID | int | NO | Copy-trading mirror ID — populated for copy-related actions. (Tier 2) |
| 21 | WithdrawID | int | NO | FK to the withdraw record, when ActionType = Cashout/Withdraw. (Tier 2) |
| 22 | DurationInSeconds | int | YES | Duration of the action in seconds (e.g. session length, position open duration). (Tier 2) |
| 23 | PostID | uniqueidentifier | YES | FK to `eToro.Post` — for social actions (post, like, comment). (Tier 2) |
| 24 | CaseID | int | NO | Customer-support case identifier, when relevant. (Tier 2) |
| 25 | UpdateDate | datetime | NO | ETL load timestamp. (Tier 2) |
| 26 | DateID | int | NO | Date encoded as YYYYMMDD — joins to `Dim_Date.DateKey`. **In this view, only 8 distinct values: 20220819, 20220825, 20220826, 20220827, 20220901, 20220902, 20230120, 20230926.** (Tier 2 + view filter) |
| 27 | TimeID | int | NO | Time-of-day encoded as integer (HHMMSS). (Tier 2) |
| 28 | StatusID | tinyint | YES | Action status (e.g. complete/pending/failed) — interpretation per ActionType. (Tier 2) |
| 29 | PreviousOccurred | datetime | YES | Timestamp of the previous action of the same kind for this customer (used for inter-action duration). (Tier 2) |
| 30 | CompensationReasonID | int | NO | FK to `Dim_CompensationReason` for compensation-typed actions. (Tier 2) |
| 31 | WithdrawPaymentID | int | NO | FK to the withdraw payment record. (Tier 2) |
| 32 | CommissionOnClose | money | NO | Commission charged at position close (vs CommissionOnOpen). (Tier 2) |
| 33 | IsPlug | bit | YES | True for "plug" / corrective entries inserted by support to fix data issues. (Tier 2) |
| 34 | DepositID | int | YES | FK to the deposit record, for deposit-typed actions. (Tier 2) |
| 35 | PostRootID | varchar(200) | YES | Root identifier for thread-level post grouping. (Tier 2) |
| 36 | FullCommission | money | YES | Commission before any customer-specific discount. (Tier 2) |
| 37 | FullCommissionOnClose | money | YES | FullCommission charged at close. (Tier 2) |
| 38 | RedeemID | int | YES | FK to the redeem record, for redemption-typed actions. (Tier 2) |
| 39 | RedeemStatus | int | YES | Status of the redemption. (Tier 2) |
| 40 | SessionID | bigint | YES | Session identifier — narrower than LoginID in some pipelines. (Tier 2) |
| 41 | IsRedeem | int | YES | Boolean flag (0/1) for "this action is a redemption". (Tier 2) |
| 42 | RegulationIDOnOpen | int | YES | Regulation ID at the time of position open (for regulation-aware reporting). (Tier 2) |
| 43 | PlatformID | int | YES | FK to platform (older field — see PlatformTypeID for the modern axis). (Tier 2) |
| 44 | ReopenForPositionID | bigint | YES | If this action re-opens a previously closed position, FK to the original. (Tier 2) |
| 45 | IsReOpen | int | YES | Boolean flag (0/1) — paired with ReopenForPositionID. (Tier 2) |
| 46 | CommissionOnCloseOrig | money | YES | CommissionOnClose in the customer's original currency (pre-conversion). (Tier 2) |
| 47 | FullCommissionOnCloseOrig | money | YES | FullCommissionOnClose in the customer's original currency. (Tier 2) |
| 48 | OriginalPositionID | bigint | YES | FK to the originating position when the action is derived (split, partial close, etc). (Tier 2) |
| 49 | IsPartialCloseParent | int | YES | Boolean — this action is the parent of a partial-close split. (Tier 2) |
| 50 | IsPartialCloseChild | int | YES | Boolean — this action is the child of a partial-close split. (Tier 2) |
| 51 | InitialUnits | decimal(16,6) | YES | Position size in units at action time. (Tier 2) |
| 52 | PaymentStatusID | int | YES | FK to `Dim_PaymentStatus` (when payment-typed action). (Tier 2) |
| 53 | IsDiscounted | int | YES | Boolean — commission was discounted (FullCommission ≠ Commission). (Tier 2) |
| 54 | IsSettled | int | YES | Boolean — settlement complete on the underlying broker side. (Tier 2) |
| 55 | CommissionByUnits | decimal(38,6) | YES | Per-unit commission rate applied. (Tier 2) |
| 56 | FullCommissionByUnits | decimal(38,6) | YES | Per-unit gross commission rate. (Tier 2) |
| 57 | IsFTD | int | YES | Boolean — this action is the customer's First-Time Deposit. (Tier 2) |
| 58 | CountryIDByIP | int | YES | Country derived from the IP at action time. (Tier 2) |
| 59 | IsAnonymousIP | int | YES | Boolean — IP is anonymized/proxied. (Tier 2) |
| 60 | ProxyType | varchar(3) | YES | Proxy classification when the IP is proxied. (Tier 2) |
| 61 | IsFeeDividend | int | YES | Boolean — action is a dividend-fee recognition. (Tier 2) |
| 62 | IsAirDrop | int | YES | Boolean — action is a crypto airdrop. (Tier 2) |
| 63 | DividendID | int | YES | FK to dividend record (when IsFeeDividend or dividend-related). (Tier 2) |
| 64 | MoveMoneyReasonID | int | YES | FK to `Dim_MoveMoneyReason` — categorical reason for an internal money move. (Tier 2) |
| 65 | SettlementTypeID | int | YES | Settlement type classification. (Tier 2) |
| 66 | DLTOpen | smallint | YES | Distributed-Ledger-Technology (crypto wallet) flag at open. (Tier 2) |
| 67 | DLTClose | smallint | YES | Distributed-Ledger-Technology flag at close. (Tier 2) |
| 68 | OpenMarkupByUnits | money | YES | Markup added to per-unit price at open (markup vs raw spread). (Tier 2) |
| 69 | Description | varchar(255) | YES | Free-text description of the action — used sparingly for narrative annotation. (Tier 2) |
| 70 | IsBuy | bit | YES | Boolean — buy (1) vs sell (0) for trade-typed actions. (Tier 2) |
| 71 | CreditID | bigint | YES | FK to a credit record, for credit-typed actions. (Tier 2) |

---

## 4. Lineage

```
DWH_dbo.Fact_CustomerAction (full fact, billions of rows)
                            ↓ (filter to 8 hand-picked DateIDs)
DWH_dbo.V_Fact_CustomerAction_for_generic (test fixture, ~few thousand rows)
                            ↓ Generic Pipeline (gold export)
main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic
```

### View Definition

```sql
CREATE VIEW DWH_dbo.V_Fact_CustomerAction_for_generic AS
SELECT *
FROM   DWH_dbo.Fact_CustomerAction
WHERE  DateID IN (20220819, 20220825, 20220826, 20220827,
                  20220901, 20220902, 20230120, 20230926);
```

---

## 5. Relationships

References to / from match `Fact_CustomerAction` exactly. See parent wiki for the full join graph.

---

*Generated: 2026-05-07 | Wave 2 systematic NO_WIKI fill-in*
*Source: View definition + Fact_CustomerAction wiki + DDL*
*Object: DWH_dbo.V_Fact_CustomerAction_for_generic | Type: View (test fixture) | Base: Fact_CustomerAction*
