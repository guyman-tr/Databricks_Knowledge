# BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance

## 1. Business Meaning

Daily Client Money Reconciliation (CMR) report for client balances, pivoted into a vertical metric format. Each row represents one balance component for a given date x Regulation x PlayerStatus x IsCreditReportValidCB x AccountType x IsEtoroTradingCID combination.

The table unpivots 32 balance movement components from `BI_DB_Client_Balance_Aggregate_Level_New` (CBCAN) into individual metric rows (ExcelOrder 1-32), then adds two reconciliation metrics: Cycle Calculation (ExcelOrder 33) and Gap (ExcelOrder 34, ClosingBalance minus CycleCalculation). Gap = 0 confirms the balance cycle reconciles.

This is a Finance control and reporting table for regulatory reporting and client money oversight. It preserves the Excel-style row ordering (ExcelOrder) used in downstream reporting templates.

- **19.5M rows** across **1,564 dates** (2021-08-13 to 2026-04-12)
- **34 distinct Metric values** per dimension group per date
- **16 Regulations** covered (CySEC, BVI, FCA, ASIC, ASIC & GAML, FinCEN+FINRA, eToroUS, FSA Seychelles, FinCEN, FSRA, and more)
- **9 PlayerStatuses** (Blocked, Normal, Blocked Upon Request, Deposit Blocked, Trade & MIMO Blocked, Warning, Block Deposit & Trading, Pending Verification, Copy Block)
- **17 AccountTypes** (Private, Corporate, Employee Account, Analyst, Affiliate Private Account, Joint Account, and more)
- UC Target: _Not_Migrated

---

## 2. Business Logic

### Source
All metric values come from `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` (CBCAN), filtered by DateID = @dateID. CBCAN stores one row per customer per date with all balance component columns.

The SP pivots CBCAN into vertical form: for each of 32 balance components, one UNION ALL branch selects `SUM(ISNULL(component_column, 0))` grouped by 5 dimension keys (Regulation, PlayerStatus, IsCreditReportValidCB, AccountType, IsEtoroTradingCID). Club from CBCAN is used in the intermediate GROUP BY but is NOT written to the final table -- the CMR stores balance totals across all club tiers.

### Metric Rows (ExcelOrder 1-34)
| Range | Category | Examples |
|-------|---------|----------|
| 1 | Opening | Opening Balance |
| 2-9 | Inflows | Deposits, Compensation Deposit, UsedBonus, Compensation, Compensation PI, Compensation To Affiliates, NWA Adjustment, Negative Refill Compensation |
| 10-25 | Outflows/Adjustments | Cashout Amount, Transfer Coins, Transfer coins Fee, Compensation Cashouts, Cashout Fee, Chargeback, Refund, ClientBalanceCommission, Overnight Fees, DividendsPaid, Lost Debt, Chargeback Loss, Other Negative, Foreclosure, Compensation P&L Adjustment, Compensation DormantFee |
| 26-31 | P&L / Transfer | ClientBalance Realized PnL, Unrealized Commission Change, Unrealized P&L Change, NetActualNWATransfer, NetLiabilityTransfer, NetUnRelizedPnLTransfer |
| 32 | Closing | Closing Balance |
| 33 | Reconciliation | Cycle Calculation (sum of all components) |
| 34 | Reconciliation | Gap = ClosingBalance - CycleCalculation (should = 0) |

### Reconciliation Logic
```
Cycle Calculation = OpeningBalance
  + Deposits + CompensationDeposit + UsedBonus + Compensation + NWAAdjustment
  + CompensationPI + CompensationToAffiliate + TransferCoins + CompensationCashouts
  + CashoutFee + TransferCoinFees + Chargeback + Refund + OvernightFee
  + ChargebackLoss + OtherNegatives + CompensationDormantFee
  + ClientBalanceRealizedPnL + UnrealizedPnLChange + LostDebt + Foreclosure
  + CompensationPnLAdjustments + NetTransfersNWA + NetTransfersLiability
  + NetTransfersUnrealizedPnL + NegativeRefill
  - Cashouts

Gap = ClosingBalance - Cycle Calculation
```
When Gap = 0, the balance cycle is clean. Non-zero Gap rows indicate reconciliation exceptions.

---

## 3. Query Advisory

### Distribution
- ROUND_ROBIN distribution; no skew risk.
- CLUSTERED INDEX on `DateID ASC` -- use DateID in WHERE predicates for best performance.
- For a single date, approximately 12,500 rows (19.5M / 1564 dates).

### Typical Access Patterns
- Filter on `Date` or `DateID` first to scope to a reporting day.
- Filter on `ExcelOrder` or `Metric` to extract a specific component.
- To reconstruct the reconciliation cycle for a regulation: filter DateID + Regulation and read all ExcelOrders 1-34 in order.

### Known Gotchas
1. **Metric column contains SP typos.** `ExcelOrder = 1` stores `Opening Balace` (not `Opening Balance`) and `ExcelOrder = 32` stores `Closing Balace`. Queries filtering on exact Metric string must use these misspelled values.
2. **Club is not stored.** The SP groups by Club in the intermediate temp table but the outer aggregation drops it. CMR values represent all club tiers combined.
3. **Gap = 0 is normal.** For a clean day, all Gap rows have MetricValue = 0. Non-zero Gap values indicate a reconciliation exception.
4. **IsCreditReportValidCB and IsEtoroTradingCID split rows.** Each combination produces separate rows -- four combos per (Date, Regulation, PlayerStatus, AccountType, Metric). Sum across them when reporting totals.
5. **PlayerStatus includes all statuses.** Blocked, Warning, and other restricted statuses appear alongside Normal. Finance aggregations typically sum across all statuses.

---

## 4. Elements

| # | Column | Type | Nullable | PK | Description | Tier |
|---|--------|------|----------|----|-------------|------|
| 1 | Date | date | YES | -- | Reporting date. Matches @date SP parameter. Use as primary date filter. | Tier 2 |
| 2 | DateID | int | YES | -- | Integer date key (YYYYMMDD). Derived as CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). Clustered index key. | Tier 2 |
| 3 | ExcelOrder | int | YES | -- | Row sequence number 1-34, hardcoded in SP per metric type. Controls sort order in Excel-style downstream reports. | Tier 2 |
| 4 | Metric | nvarchar(100) | YES | -- | Balance component name, hardcoded in SP. 34 distinct values. Note: `Opening Balace` (ExcelOrder 1) and `Closing Balace` (ExcelOrder 32) are SP-level typos stored with misspelling. | Tier 2 |
| 5 | MetricValue | decimal(28,8) | YES | -- | Aggregated balance value for this metric, date, and dimension group. SUM(ISNULL(source_column, 0)) from CBCAN. Can be negative (outflows, PnL). ExcelOrders 33-34 are computed (not direct CBCAN columns). | Tier 2 |
| 6 | UpdateDate | datetime | YES | -- | ETL load timestamp. GETDATE() at INSERT time. | Propagation |
| 7 | Regulation | nvarchar(50) | YES | -- | Regulatory entity name from CBCAN. 16 distinct values (CySEC, BVI, FCA, ASIC, ASIC & GAML, FinCEN+FINRA, eToroUS, FSA Seychelles, FinCEN, FSRA, and others). | Tier 2 |
| 8 | PlayerStatus | nvarchar(100) | YES | -- | Customer account status from CBCAN. 9 distinct values: Normal, Blocked, Blocked Upon Request, Deposit Blocked, Trade & MIMO Blocked, Warning, Block Deposit & Trading, Pending Verification, Copy Block. | Tier 2 |
| 9 | IsCreditReportValidCB | bit | YES | -- | Credit report validity flag from CBCAN. 0 or 1. Splits rows -- sum across values for total balances. | Tier 2 |
| 10 | AccountType | nvarchar(100) | YES | -- | Customer account type from CBCAN. 17 distinct values (Private, Corporate, Employee Account, Analyst, Affiliate Private Account, Joint Account, Affiliate Corporate Account, Fund, Funded Employee Account, SMSF, and others). | Tier 2 |
| 11 | IsEtoroTradingCID | bit | YES | -- | Flag indicating eToro trading customer from CBCAN. 0 or 1. Splits rows -- sum across values for total balances. | Tier 2 |

---

## 5. Lineage

See: [BI_DB_CMR_Phase2_ClientBalance.lineage.md](BI_DB_CMR_Phase2_ClientBalance.lineage.md)

**Writer SP**: `BI_DB_dbo.SP_CMR_Phase2_ClientBalance`
**Refresh**: Daily (OpsDB Priority 15)
**Load Pattern**: DELETE WHERE Date = @date + INSERT

### Source Objects
| Source | Role |
|--------|------|
| `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` | Sole source; provides all balance component columns and dimension keys |

### Pipeline
```
BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New (CBCAN, DateID = @dateID)
  34 UNION ALL branches (one per metric), grouped by Regulation, PlayerStatus,
  IsCreditReportValidCB, AccountType, IsEtoroTradingCID
  Club used in intermediate GROUP BY but dropped in outer aggregation
  SP_CMR_Phase2_ClientBalance(@date)
  DELETE FROM BI_DB_CMR_Phase2_ClientBalance WHERE Date = @date
  INSERT INTO BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance
```

---

## 6. Relationships

| Related Object | Relationship | Notes |
|---------------|-------------|-------|
| `BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New` | Source (sole upstream) | CBCAN stores one row per customer per date; CMR pivots and aggregates it |
| `BI_DB_dbo.BI_DB_CMR_Phase2_CycleGap` | Sibling (same CMR suite) | Stores daily gap summary by Regulation and GapCategory |
| `BI_DB_dbo.BI_DB_CMR_Phase2_EU_Outliers` | Sibling (same CMR suite) | EU outlier movement metrics (ValidToInvalid, InvalidToValid) |
| `BI_DB_dbo.BI_DB_CMR_Phase2_LiabilityDecomp` | Sibling (same CMR suite) | Liability decomposition metrics |
| `BI_DB_dbo.BI_DB_CMR_Phase2_FinraGap` | Sibling (same CMR suite) | FINRA-specific gap metrics |

---

## 7. Sample Queries

### Latest day reconciliation check by regulation (find non-zero gaps)
```sql
SELECT
    Date,
    Regulation,
    SUM(MetricValue) AS TotalGap
FROM BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance)
  AND ExcelOrder = 34
GROUP BY Date, Regulation
HAVING SUM(MetricValue) <> 0
ORDER BY ABS(SUM(MetricValue)) DESC;
```

### Balance waterfall for a specific date and regulation
```sql
SELECT
    ExcelOrder,
    Metric,
    SUM(MetricValue) AS MetricValue
FROM BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance
WHERE DateID = 20260412
  AND Regulation = 'CySEC'
GROUP BY ExcelOrder, Metric
ORDER BY ExcelOrder;
```

### Trend of closing balance by regulation (monthly last-day)
```sql
SELECT
    Date,
    Regulation,
    SUM(MetricValue) AS ClosingBalance
FROM BI_DB_dbo.BI_DB_CMR_Phase2_ClientBalance
WHERE ExcelOrder = 32
  AND Date >= '2025-01-01'
  AND Date = EOMONTH(Date)
GROUP BY Date, Regulation
ORDER BY Date, Regulation;
```

---

## 8. Atlassian Knowledge

No Confluence or Jira sources found for this table. Business context derived from SP code analysis and data sampling.
