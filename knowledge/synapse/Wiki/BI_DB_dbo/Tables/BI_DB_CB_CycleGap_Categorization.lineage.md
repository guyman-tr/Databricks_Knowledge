# Column Lineage — BI_DB_dbo.BI_DB_CB_CycleGap_Categorization

**Writer SP**: `BI_DB_dbo.SP_CB_Gap_Categorization` (Priority 99 — FinanceReportSPS)
**Author**: Guy Manova (2021-03-25)
**ETL Pattern**: DELETE-INSERT by DateID (daily incremental)
**Purpose**: Expands cycle gap investigation with categorized gap types for Tableau consumption. Note: the SP itself is "semi-valuable" — the final gap closure logic (looking back and forth on gap closures) is in a Tableau live query, not in this SP.

---

## Source Tables

### BI_DB layer (intra-schema — not in OpsDB dependency graph but used at SQL level)

| Source | Role |
|--------|------|
| BI_DB_dbo.BI_DB_Daily_CB_Gaps_All | Daily client balance gaps — primary gap amounts |
| BI_DB_dbo.BI_DB_Outliers_New | Outlier transitions (e.g., "Etoro To DLT") |
| BI_DB_dbo.BI_DB_CycleGap | Cashout gap details (COPosAmount, Payed, Gap) |
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Closing balance aggregation (documented — Batch 1) |
| BI_DB_dbo.V_GermanBaFin | German BaFin CID flag |

### DWH layer

| Source | Role |
|--------|------|
| DWH_dbo.Fact_SnapshotCustomer | Player status, credit report validity |
| DWH_dbo.Dim_PlayerStatus | Player status names (Normal, Suspended, etc.) |
| DWH_dbo.Dim_Range | Date range resolution for snapshot joins |
| DWH_dbo.Fact_CustomerAction | Refund-as-chargeback amounts (ActionTypeID = 13) |
| DWH_dbo.etoro_History_Credit | Production chargeback refunds (CreditTypeID = 16) |
| DWH_dbo.V_Liabilities | Total liabilities by CID |
| DWH_dbo.Fact_RegulationTransfer | Regulation transfer detection (dedup logic) |

---

## Column-Level Lineage

### A. Identity & Date (3 columns)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| CID | BI_DB_Daily_CB_Gaps_All / BI_DB_Outliers_New | UNION of both gap sources. HASH distribution key. |
| Date | computed | @date SP parameter |
| DateID | computed | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) |

### B. Gap Amounts (4 columns)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| DailyCBGap | BI_DB_Daily_CB_Gaps_All.Gap / BI_DB_Outliers_New.[Cycle Calculation] | ISNULL(MAX,0). Today's client balance gap amount |
| PreviousCBGap | SUM(BI_DB_Daily_CB_Gaps_All.Gap WHERE DateID < current) | ISNULL(SUM of all historical gaps for this CID, 0) |
| CycleCalculation | BI_DB_Daily_CB_Gaps_All.CycleCalculation / BI_DB_Outliers_New.[Cycle Calculation] | ISNULL(MAX,0). Cycle-level gap calculation |
| TotalGap | computed | ABS(DailyCBGap) - ABS(PreviousCBGap) + ABS(RefundAsChargeback_CB) - ABS(RefundAsChargeback_Prod). Net gap after accounting for chargebacks |

### C. Cashout Columns (3 columns)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| CashoutRequested | BI_DB_CycleGap.COPosAmount | ISNULL(SUM,0). Total cashout positions requested |
| CashoutProcessed | BI_DB_CycleGap.Payed | ISNULL(SUM,0). Total cashout amount actually processed |
| CashoutGap | BI_DB_CycleGap.Gap | ISNULL(SUM,0). Difference between requested and processed |

### D. Balance & Liability (2 columns)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| ClosingBalance | BI_DB_Daily_CB_Gaps_All.ClosingBalance / SUM(BI_DB_Client_Balance_CID_Level_New.ClosingBalance) | ISNULL(MAX,0). Outlier path aggregates from Client_Balance_CID_Level_New |
| Liabilities | V_Liabilities.Liabilities | Direct read for the current date |

### E. Outlier Columns (2 columns)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| OutlierTransition | BI_DB_Outliers_New.Transition | ISNULL(MAX,'0'). Values: "Etoro To DLT", "0" (no outlier), etc. |
| OutlierCycleCalculation | BI_DB_Outliers_New.[Cycle Calculation] | ISNULL(SUM,0). Cycle calculation specific to outlier transitions |

### F. Player Status (2 columns)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| PreviousPlayerStatus | Dim_PlayerStatus.Name (via Fact_SnapshotCustomer, prev day) | Direct. Values: "Normal", "Suspended", etc. |
| CurrentPlayerStatus | Dim_PlayerStatus.Name (via Fact_SnapshotCustomer, current day) | Direct. Outlier path also provides from initial join |

### G. Chargeback Refund (2 columns)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| RefundAsChargeback_CB | Fact_CustomerAction.Amount (ActionTypeID = 13) | ISNULL(SUM,0). Chargeback refunds recorded in CB system |
| RefundAsChargeback_Prod | etoro_History_Credit.TotalCashChange (CreditTypeID = 16) | ISNULL(SUM,0). Chargeback refunds in production credit history |

### H. Classification & Metadata (4 columns)

| BI_DB Column | Source | Transform |
|-------------|--------|-----------|
| Regulation | BI_DB_Daily_CB_Gaps_All.Regulation / BI_DB_Outliers_New.Regulation | Passthrough. String regulation name |
| IsCreditReportValidCB | Fact_SnapshotCustomer.IsCreditReportValidCB | Direct from customer snapshot |
| IsGermanBaFin | V_GermanBaFin CID existence | CASE WHEN CID IS NOT NULL THEN 1 ELSE 0 END |
| DidRegulationTransfer | Fact_RegulationTransfer CID+DateID existence | CASE WHEN CID IS NOT NULL THEN 1 ELSE 0 END. Used for dedup: if 1, creates double cycle calc rows — filtered out in #dailyGap |
| UpdateDate | GETDATE() | SP execution timestamp |

---

## ETL Flow

```
BI_DB_Daily_CB_Gaps_All ──→ #dailyGap (today's gaps, filtered non-transfers)
BI_DB_Outliers_New ──→ #outlierPrep ──→ UNION into #dailyGap
Fact_RegulationTransfer ──→ #regTransfers (dedup logic)
                                 ↓
BI_DB_Daily_CB_Gaps_All (history) ──→ #relvantCIDs + #PreviousGap
Fact_SnapshotCustomer + Dim_PlayerStatus ──→ #CurrentStatus + #PreviousStatus ──→ #statuses
BI_DB_CycleGap ──→ cashout data
                                 ↓
                    #gapsWithCOandOutliersPrep (JOIN all streams)
                    #gapsWithCOandOutliers (GROUP BY dedupe)
                                 ↓
Fact_CustomerAction (ActionTypeID=13) ──→ #cbRAC (CB chargebacks)
etoro_History_Credit (CreditTypeID=16) ──→ #hcRAC (Prod chargebacks)
V_Liabilities ──→ #liabilities
                                 ↓
                    #finalPrep (all columns assembled, TotalGap computed)
                    #final (column selection)
                                 ↓
             DELETE/INSERT into BI_DB_CB_CycleGap_Categorization
```
