# BI_DB_dbo.BI_DB_CB_CycleGap_Categorization

## 1. Overview

Daily categorization of client balance (CB) cycle gaps for the **Client Money Reconciliation (CMR)** process. Each row represents one customer's gap analysis on one calendar day, breaking down discrepancies into cashout gaps, outlier transitions, chargeback refund gaps, and unexplained gaps. The table feeds a Tableau dashboard that applies final gap-closure logic via live queries — the SP itself provides the raw categorization, not the final resolution status.

**Row grain**: One CID per Date (deduplicated — regulation transfer duplications are filtered)

---

## 2. Business Context

Created March 2021 by Guy Manova to expand the cycle gap investigation with clearer categorization for the finance team. The table answers: "For each customer with a balance discrepancy today, what TYPE of gap is it?"

**Key business rules**:
- **Cycle gap**: A discrepancy between what a customer's balance SHOULD be (based on deposits/withdrawals/PnL) and what it actually IS. Gaps indicate potential errors, chargebacks, or system timing issues.
- **Outlier transitions**: Customers who transition between platforms (e.g., "Etoro To DLT" — eToro to Digital Ledger Technology) create expected gaps that need separate categorization.
- **Chargeback refund gap**: When a chargeback refund is recorded in the CB system (Fact_CustomerAction, ActionTypeID 13) but not yet in production (etoro_History_Credit, CreditTypeID 16), or vice versa, a gap exists. TotalGap adjusts for these.
- **Regulation transfer dedup**: If a customer transfers regulation AND has an outlier transition on the same day, the SP produces duplicate rows. The `DidRegulationTransfer` flag and a WHERE filter eliminate these (April 2021 fix).
- **Important**: The final gap closure logic (looking backwards and forwards to determine if a gap was eventually resolved) lives in a **Tableau live query**, not in this table. This table is the raw categorization input.

**Consumers**: `SP_CMR_Phase2_CycleGap`, `SP_CMR_Automation_ASIC_CycleGap`, `SP_CMR_Automation_EU_CycleGap`, `SP_CMR_Automation_ASIC_CheckTableUpdate`, `SP_CMR_Automation_EU_CheckTableUpdate`.

---

## 3. Structure

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | USER_TABLE |
| **Columns** | 23 |
| **Distribution** | HASH(CID) |
| **Clustered Index** | CID ASC |

---

## 4. Elements

| # | Column | Type | Nullable | Description |
|---|--------|------|----------|-------------|
| 1 | CID | bigint | YES | Customer ID. From BI_DB_Daily_CB_Gaps_All or BI_DB_Outliers_New (UNION). HASH distribution key. Only customers with non-zero gaps or outlier transitions appear. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All + BI_DB_Outliers_New) |
| 2 | Date | date | YES | Calendar date of the gap analysis. SP @date parameter. (Tier 2 — SP_CB_Gap_Categorization, @date) |
| 3 | DateID | int | YES | YYYYMMDD integer date key. Computed from @date parameter. Used for DELETE-INSERT scope and history joins. (Tier 2 — SP_CB_Gap_Categorization, computed) |
| 4 | DailyCBGap | money | YES | Today's client balance gap amount in USD. From BI_DB_Daily_CB_Gaps_All.Gap or BI_DB_Outliers_New.[Cycle Calculation] for outlier transitions. ISNULL default 0. A non-zero value means the customer's actual balance differs from the expected balance. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All.Gap) |
| 5 | PreviousCBGap | money | YES | Sum of all historical gaps for this CID before the current date. SUM(BI_DB_Daily_CB_Gaps_All.Gap WHERE DateID < current). ISNULL default 0. Used to determine if today's gap is new or a continuation. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All historical) |
| 6 | CashoutRequested | money | YES | Total cashout position amount requested on this date. From BI_DB_CycleGap.COPosAmount. ISNULL(SUM,0). (Tier 2 — SP_CB_Gap_Categorization, BI_DB_CycleGap.COPosAmount) |
| 7 | CashoutProcessed | money | YES | Total cashout amount actually paid/processed on this date. From BI_DB_CycleGap.Payed. ISNULL(SUM,0). (Tier 2 — SP_CB_Gap_Categorization, BI_DB_CycleGap.Payed) |
| 8 | ClosingBalance | money | YES | Customer's closing balance on this date in USD. From BI_DB_Daily_CB_Gaps_All.ClosingBalance for regular gaps; from SUM(BI_DB_Client_Balance_CID_Level_New.ClosingBalance) for outlier transitions. ISNULL default 0. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All + BI_DB_Client_Balance_CID_Level_New) |
| 9 | CycleCalculation | money | YES | The cycle-level gap calculation amount. Represents the gap computed within the current billing/settlement cycle. From BI_DB_Daily_CB_Gaps_All.CycleCalculation or BI_DB_Outliers_New.[Cycle Calculation]. ISNULL(MAX,0). (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All.CycleCalculation) |
| 10 | CashoutGap | money | YES | Gap between cashout requested and processed. From BI_DB_CycleGap.Gap. ISNULL(SUM,0). Non-zero means a cashout is pending or partially fulfilled. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_CycleGap.Gap) |
| 11 | OutlierTransition | varchar(1000) | YES | Type of outlier platform transition causing the gap. Values: "Etoro To DLT" (eToro to Digital Ledger Technology), "0" (no outlier), etc. From BI_DB_Outliers_New.Transition. Rows with OutlierTransition IS NOT NULL AND DailyCBGap = 0 are deleted (gap resolved by transition). (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Outliers_New.Transition) |
| 12 | OutlierCycleCalculation | money | YES | Cycle gap amount attributable specifically to the outlier transition. From BI_DB_Outliers_New.[Cycle Calculation]. ISNULL(SUM,0). Non-zero means the gap is explained by a platform transition, not a data error. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Outliers_New.[Cycle Calculation]) |
| 13 | PreviousPlayerStatus | varchar(1000) | YES | Customer's player status on the previous day. From Dim_PlayerStatus.Name via Fact_SnapshotCustomer (prev day). Values: "Normal", "Suspended", "Blocked", etc. Used to detect status transitions that might explain gaps. (Tier 2 — SP_CB_Gap_Categorization, Dim_PlayerStatus.Name) |
| 14 | CurrentPlayerStatus | varchar(1000) | YES | Customer's player status on the current day. From Dim_PlayerStatus.Name via Fact_SnapshotCustomer (current day). Compare with PreviousPlayerStatus to detect transitions (e.g., Normal → Suspended). (Tier 2 — SP_CB_Gap_Categorization, Dim_PlayerStatus.Name) |
| 15 | RefundAsChargeback_CB | money | YES | Chargeback refund amount recorded in the CB (Client Balance) system on this date. SUM of Fact_CustomerAction.Amount where ActionTypeID = 13. ISNULL default 0. When this differs from RefundAsChargeback_Prod, a chargeback timing gap exists. (Tier 2 — SP_CB_Gap_Categorization, Fact_CustomerAction.Amount) |
| 16 | RefundAsChargeback_Prod | money | YES | Chargeback refund amount in the production credit history on this date. SUM of etoro_History_Credit.TotalCashChange where CreditTypeID = 16. ISNULL default 0. Differences from RefundAsChargeback_CB indicate system sync delay. (Tier 2 — SP_CB_Gap_Categorization, etoro_History_Credit.TotalCashChange) |
| 17 | TotalGap | money | YES | Net gap after chargeback adjustment. Formula: ABS(DailyCBGap) - ABS(PreviousCBGap) + ABS(RefundAsChargeback_CB) - ABS(RefundAsChargeback_Prod). A TotalGap of 0 with non-zero DailyCBGap means the gap is fully explained by chargebacks or previous gaps closing. (Tier 2 — SP_CB_Gap_Categorization, computed) |
| 18 | Liabilities | money | YES | Total liabilities from V_Liabilities for this CID on this date. Used in Tableau for negative-liability categorization (e.g., gap explained by negative liability = chargeback loss). (Tier 2 — SP_CB_Gap_Categorization, V_Liabilities.Liabilities) |
| 19 | Regulation | varchar(1000) | YES | Regulation name for the customer. Passthrough from BI_DB_Daily_CB_Gaps_All.Regulation or BI_DB_Outliers_New.Regulation. All regulations included (not limited to ASIC). (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All.Regulation) |
| 20 | IsCreditReportValidCB | int | YES | Credit report validity flag from Fact_SnapshotCustomer. 1 = valid customer for CB reporting. Direct passthrough. (Tier 2 — SP_CB_Gap_Categorization, Fact_SnapshotCustomer.IsCreditReportValidCB) |
| 21 | IsGermanBaFin | int | YES | German BaFin flag. 1 if CID appears in V_GermanBaFin for this date. Regulatory overlap indicator. (Tier 2 — SP_CB_Gap_Categorization, V_GermanBaFin) |
| 22 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 — SP_CB_Gap_Categorization, GETDATE()) |
| 23 | DidRegulationTransfer | int | YES | Flag: 1 if the CID had a regulation transfer on this date (from Fact_RegulationTransfer). Used for deduplication — when 1, the row was filtered out of #dailyGap to prevent double-counting cycle calculations. Added April 2021 to fix rare duplication bug found by Eva and Artemis. (Tier 2 — SP_CB_Gap_Categorization, Fact_RegulationTransfer) |

---

## 5. Relationships

### Source Tables

| Source | Schema | Relationship |
|--------|--------|-------------|
| BI_DB_Daily_CB_Gaps_All | BI_DB_dbo | Primary gap amounts (CID, DateID) |
| BI_DB_Outliers_New | BI_DB_dbo | Outlier transitions — UNIONed with daily gaps |
| BI_DB_CycleGap | BI_DB_dbo | Cashout gap details (CID, Date) |
| BI_DB_Client_Balance_CID_Level_New | BI_DB_dbo | Closing balance for outlier path (documented) |
| V_GermanBaFin | BI_DB_dbo | German BaFin indicator view |
| Fact_SnapshotCustomer | DWH_dbo | Player status, credit report validity |
| Dim_PlayerStatus | DWH_dbo | Status name resolution |
| Dim_Range | DWH_dbo | Date range resolution |
| Fact_CustomerAction | DWH_dbo | Chargeback refunds (ActionTypeID 13) |
| etoro_History_Credit | DWH_dbo | Production chargeback history (CreditTypeID 16) |
| V_Liabilities | DWH_dbo | Total liabilities |
| Fact_RegulationTransfer | DWH_dbo | Regulation transfer detection |

### Consumers

| Consumer | Purpose |
|----------|---------|
| SP_CMR_Phase2_CycleGap | Phase 2 of CMR cycle gap analysis |
| SP_CMR_Automation_ASIC_CycleGap | ASIC-specific CMR automation |
| SP_CMR_Automation_EU_CycleGap | EU-specific CMR automation |
| SP_CMR_Automation_*_CheckTableUpdate | Data freshness verification |

---

## 6. ETL & Lifecycle

| Property | Value |
|----------|-------|
| **Writer SP** | SP_CB_Gap_Categorization |
| **ETL Pattern** | DELETE-INSERT by DateID |
| **Grain** | One row per CID per Date (deduplicated) |
| **Schedule** | Daily (SB_Daily, Priority 99 — FinanceReportSPS) |
| **Parameter** | @date (Date) — the calendar day to process |
| **Delete Scope** | `DELETE WHERE DateID = @dateID` |
| **History** | Accumulating daily snapshot. Old rows preserved for trend analysis. |
| **Note** | SP reads from 4 other BI_DB tables (Daily_CB_Gaps_All, Outliers_New, CycleGap, Client_Balance_CID_Level_New) — these are SQL-level dependencies not tracked in OpsDB. |

---

## 7. Query Advisory

| Consideration | Guidance |
|--------------|---------|
| **HASH(CID) distribution** | Queries joining on CID benefit from colocation. For date-range queries, add DateID filter to avoid full scans. |
| **TotalGap = 0 means explained** | A gap is "explained" when TotalGap = 0 despite non-zero DailyCBGap. This means prior gaps + chargeback adjustments account for the discrepancy. |
| **Tableau final logic** | This table is an intermediate artifact. The Tableau dashboard applies backward/forward gap-closure logic that is NOT in this SP. Do not treat this table as the final gap resolution status. |
| **OutlierTransition filtering** | Rows with OutlierTransition IS NOT NULL AND DailyCBGap = 0 are deleted by the SP — these represent resolved outlier transitions. |
| **DidRegulationTransfer = 1** | These rows exist only in the #outlierPrep UNION path. The #dailyGap path filters them out. If you see DidRegulationTransfer = 1, it's an outlier who also transferred regulation. |

---

## 8. Classification & Status

| Property | Value |
|----------|-------|
| **Domain** | Finance / Client Money Reconciliation |
| **Sub-domain** | Cycle Gap Investigation |
| **Sensitivity** | Contains CID, financial balances, and gap amounts — PII-adjacent. |
| **Owner** | Finance team (Guy Manova) |
| **Quality Score** | 9.0 |

---

*Generated by DWH Semantic Documentation Pipeline — Batch 3, Object #2*
*Phases: P1 ✓ P2 ✓ P3 ✓ P5 ✓ P6 ✓ P8 ✓ P9 ✓ P10 ✓ | Skipped: P4, P7, P9B, P10.5 (multi-source)*
