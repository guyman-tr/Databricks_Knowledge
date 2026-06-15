# Column Lineage: main.bi_output.bi_output_v_recurring_investment

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_v_recurring_investment` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_v_recurring_investment.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_v_recurring_investment.json` (rows: 3, mismatches: 2) |
| **Primary upstream** | `main.general.bronze_recurringinvestment_recurringinvestment_planinstances` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_recurringinvestment_recurringinvestment_plans` | JOIN / referenced | ✓ `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.Plans.md` |
| `main.experience.bronze_recurringinvestment_dictionary_copytype` | JOIN / referenced | ✓ `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.CopyType.md` |
| `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans` | JOIN / referenced | ✓ `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/History/Tables/History.RecurringInvestmentPlans.md` |
| `main.general.bronze_recurringinvestment_recurringinvestment_planinstances` | Primary (FROM) | ✓ `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/RecurringInvestment/Tables/RecurringInvestment.PlanInstances.md` |
| `main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid` | JOIN / referenced | ✓ `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.InstanceStatusID.md` |
| `main.bi_db.bronze_recurringinvestment_dictionary_planeventcode` | JOIN / referenced | ✓ `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanEventCode.md` |
| `main.bi_db.bronze_recurringinvestment_dictionary_planstatus` | JOIN / referenced | ✓ `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanStatus.md` |
| `main.experience.bronze_recurringinvestment_dictionary_positionstatus` | JOIN / referenced | ✓ `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PositionStatus.md` |
| `main.experience.bronze_recurringinvestment_dictionary_plantype` | JOIN / referenced | ✓ `knowledge/ProdSchemas/ExperianceDBs/RecurringInvestment/Wiki/Dictionary/Tables/Dictionary.PlanType.md` |

## Lineage Chain

```
main.general.bronze_recurringinvestment_recurringinvestment_planinstances   ←── primary upstream
  + main.bi_db.bronze_recurringinvestment_dictionary_planstatus   (JOIN)
  + main.experience.bronze_recurringinvestment_dictionary_plantype   (JOIN)
  + main.experience.bronze_recurringinvestment_dictionary_copytype   (JOIN)
  + main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid   (JOIN)
  + main.bi_db.bronze_recurringinvestment_dictionary_planeventcode   (JOIN)
  + main.experience.bronze_recurringinvestment_dictionary_positionstatus   (JOIN)
  + main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans   (JOIN)
  + main.general.bronze_recurringinvestment_recurringinvestment_plans   (JOIN)
        │
        ▼
main.bi_output.bi_output_v_recurring_investment   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `ActiveDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 2 | `ActiveMonth` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 3 | `ID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 4 | `PlanType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 5 | `PlaneTypeName` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 6 | `GCID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 7 | `CID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 8 | `InstrumentID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 9 | `RecurringDepositID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 10 | `Amount` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 11 | `CurrencyID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 12 | `PlanStatusID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 13 | `PlanStatusName` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 14 | `DepositPlanStatusID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 15 | `StatusReasonID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 16 | `PlanCreationDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 17 | `EndDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 18 | `ValidFrom` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 19 | `ValidTo` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 20 | `DepositStartDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 21 | `RepeatsOn` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 22 | `FrequencyID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 23 | `FundingID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 24 | `CopyType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 25 | `CopyTypeName` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 26 | `Trace` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 27 | `InstanceID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 28 | `InstanceStatusID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 29 | `InstanceStatusName` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 30 | `InstanceStatusReasonID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 31 | `InstanceStatusReasonName` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 32 | `NextOrderDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 33 | `CreationDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 34 | `DepositID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 35 | `DepositAmountUsd` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 36 | `DepositDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 37 | `DepositCycleNumber` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 38 | `HighLevelDepositStatusId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 39 | `DepositStatusID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 40 | `OrderID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 41 | `OrderTradeDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 42 | `OrderStatusId` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 43 | `PositionExecutionDate` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 44 | `ValidFromInstance` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 45 | `ValidToInstance` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 46 | `PositionFailErrorCode` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 47 | `MirrorID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 48 | `MirrorOrderCreated` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 49 | `CopyPositionStatusID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 50 | `CopyFailErrorCode` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 51 | `DepositFailReason` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 52 | `TraceInstance` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 53 | `CopyParentCID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 54 | `CopyparentGCID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 55 | `HasBackupPayment` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 56 | `PositionStatusID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 57 | `PositionStatusName` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 58 | `IsSkip` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 59 | `ActivePlan` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 60 | `PositionAmountUSD` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 61 | `AmountUSD` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 62 | `IsChurnPlan` | `main.general.bronze_recurringinvestment_recurringinvestment_planinstances` | `—` | `case` | — | CASE WHEN MAX(ActivePlan) OVER (PARTITION BY ID ORDER BY NextOrderDate) = 1 AND ActivePlan = 0 THEN 1 ELSE 0 END AS IsChurnPlan |
| 63 | `IsActiveUser` | `main.general.bronze_recurringinvestment_recurringinvestment_planinstances` | `—` | `case` | — | CASE WHEN SUM(ActivePlan) OVER (PARTITION BY CID, activemonth ORDER BY NextOrderDate ASC) >= 1 THEN 1 ELSE 0 END AS IsActiveUser /*  isActiv |

## Cross-check vs system.access.column_lineage

- Total target columns: **3**
- OK: **1**, WARN: **0**, ERROR: **2**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `IsChurnPlan` | — | `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans.enddate`, `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans.id`, `main.general.bronze_recurringinvestment_recurringinvestment_planinstances.depositid`, `main.general.bronze_recurringinvestment_recurringinvestment_planinstances.depositstatusid`, `main.general.bronze_recurringinvestment_recurringinvestment_planinstances.nextorderdate`, `main.general.bronze_recurringinvestment_recurringinvestment_plans.enddate`, `main.general.bronze_recurringinvestment_recurringinvestment_plans.id` | ERROR |
| `IsActiveUser` | — | `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans.cid`, `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans.enddate`, `main.bi_db.bronze_recurringinvestment_history_recurringinvestmentplans.id`, `main.general.bronze_recurringinvestment_recurringinvestment_planinstances.depositid`, `main.general.bronze_recurringinvestment_recurringinvestment_planinstances.depositstatusid`, `main.general.bronze_recurringinvestment_recurringinvestment_planinstances.nextorderdate`, `main.general.bronze_recurringinvestment_recurringinvestment_plans.cid`, `main.general.bronze_recurringinvestment_recurringinvestment_plans.enddate`, `main.general.bronze_recurringinvestment_recurringinvestment_plans.id` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN (SELECT ID, GCID, CID, InstrumentID, RecurringDepositID, Amount, CurrencyID, PlanStatusID, DepositPlanStatusID, StatusReasonID, CreationDate, EndDate, DepositStartDate, FrequencyID, RepeatsOn, FundingID, Trace, ValidFrom, ValidTo,
- `LEFT JOIN` — LEFT JOIN main.bi_db.bronze_recurringinvestment_dictionary_planstatus AS ps ON ip.PlanStatusID = ps.ID
- `LEFT JOIN` — LEFT JOIN main.experience.bronze_recurringinvestment_dictionary_plantype AS pt ON ip.PlanType = pt.ID
- `LEFT JOIN` — LEFT JOIN main.experience.bronze_recurringinvestment_dictionary_copytype AS ct ON ip.CopyType = ct.ID
- `LEFT JOIN` — LEFT JOIN main.bi_db.bronze_recurringinvestment_dictionary_instancestatusid AS isi ON ipi.InstanceStatusID = isi.ID
- `LEFT JOIN` — LEFT JOIN main.bi_db.bronze_recurringinvestment_dictionary_planeventcode AS pec ON ipi.InstanceStatusReasonID = pec.ID
- `LEFT JOIN` — LEFT JOIN main.experience.bronze_recurringinvestment_dictionary_positionstatus AS ps2 ON ipi.positionStatus = ps2.ID
