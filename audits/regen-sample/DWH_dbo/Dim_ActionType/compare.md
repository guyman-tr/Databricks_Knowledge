# Compare — `DWH_dbo.Dim_ActionType`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +0.75; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.1 | 8.85 | 0.75 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 6 | 6 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 3 | 0 | -3 |
| T3 count | 3 | 6 | +3 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 8 | 10 |
| data_evidence | 7 | 7 |
| shape_fidelity | 8 | 9 |
| tier_accuracy | 9 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `5` | 0.059 | 3 | 3 | Business category text label for grouping action types. Values: N/A, Account balance to mirror, Bonus, Cashier Loggin, Cashout, Chargeback, Compensation, Deposit, DepositAttempt, DetachPosition, Edit  | Category grouping for the action type. 30 distinct values: PositionOpen, PositionClose, Deposit, Cashout, Bonus, Chargeback, UserEngagement, WallEngagement, DetachPosition, etc. Multiple ActionTypeIDs |
| `6` | 0.07 | 3 | 3 | Business category integer code grouping multiple action types. Values: 0=N/A, 1=Account balance to mirror, 2=Bonus, 3=Cashier Loggin, 4=Cashout/Withdraw, 5=Cashout request, 6=Chargeback, 7=Compensatio | Integer identifier for the Category grouping. 29 distinct values (0-28). Used by SP_Validation_Cycle_Gap_DL_To_Synapse for financial reconciliation filtering (e.g., CategoryID=17 triggers NetProfit lo |
| `2` | 0.207 | 3 | 3 | Human-readable name of the action type. Key values: 1=ManualPositionOpen, 2=CopyPositionOpen, 3=CopyPlusPositionOpen, 4=ManualPositionClose, 5=CopyPositionClose, 6=CopyPlusPositionClose, 7=Deposit, 8= | Human-readable name of the action type. Values include ManualPositionOpen, CopyPositionClose, Deposit, Cashout, Bonus, Chargeback, LoggedIn, Customer Registration, etc. (45 distinct values). (Tier 3 — |
| `1` | 0.222 | 2 | 3 | Primary key. Integer identifier for the customer action type. Values 1-45 active; 0 = N/A placeholder. Referenced by Fact_CustomerAction.ActionTypeID. DWH note: smallint in DWH vs int in legacy DWH_Mi | Primary key identifying a specific customer action type. Integer codes 0-45 (gap at 33) where 0=N/A sentinel. Used as FK in Fact_CustomerAction, Fact_FirstCustomerAction, Fact_History_Cost, and numero |
| `3` | 0.347 | 2 | 3 | Production UpdateDate from legacy DWH SQL Server - passthrough, not ETL load time. Represents when the action type was last updated in the source system. Most rows = 2013-07-17 (initial migration); ne | Timestamp of the last update to this action type row. Most rows show 2013-07-17 (original seed); row 0 shows 2014-02-24. (Tier 3 — no upstream wiki, grounded in DDL + live data) |
| `4` | 0.381 | 2 | 3 | Production InsertDate from legacy DWH SQL Server - passthrough, not ETL load time. Represents when the action type was first inserted in the source system. Equals UpdateDate for most rows. (Tier 2 - D | Timestamp when this action type row was first inserted. Same pattern as UpdateDate — bulk seeded 2013-07-17, sentinel added 2014-02-24. (Tier 3 — no upstream wiki, grounded in DDL + live data) |

## Top issues — regen wiki (per judge)

- [low] `Section 8 / Footer` — No explicit Phase Gate Checklist subsection. Footer says 'Phases: 12/14' but does not enumerate which phases were completed or skipped.
- [low] `Section 3.3` — JOIN table lists only 3 of 8 downstream consumers from Section 6.2. Missing BI_DB and EXW SP joins.
- [low] `CategoryID` — Element description references SP_Validation_Cycle_Gap_DL_To_Synapse behavior (CategoryID=17 triggers NetProfit logic) which is SP-derived knowledge tagged as Tier 3. Not a tier error but slightly inconsistent — this knowledge came from reading downstream SP code, not from DDL+data alone.
- [info] `Section 8` — Atlassian sources skipped in regen harness mode. Expected behavior.
- [info] `Section 5.1` — All 6 columns have unknown production source. Correctly flagged in review-needed sidecar for follow-up.
