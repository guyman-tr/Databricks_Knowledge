# BI_DB_dbo.BI_DB_HourlyReport_Withdraws

> 288,689-row hourly TRUNCATE snapshot of all non-crypto withdrawal requests (FundingTypeID != 27) from the last 15 days (excluding cancelled), tracking 80,923 distinct customers with per-status funding leg breakdowns (PIVOT by CashoutStatusID 1-13) and fully-funded detection. Refreshed hourly via SP_H_Ops_HourlyReport_Withdraws (SB_Hourly). Companion to BI_DB_HourlyReport_Redeems (crypto-only, same structure).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Withdraw + Billing.vWithdrawToFunding via SP_H_Ops_HourlyReport_Withdraws |
| **Refresh** | Hourly (SB_Hourly, TRUNCATE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **PK** | WithdrawID (NOT ENFORCED) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_HourlyReport_Withdraws` is an hourly operational report for the Ops Tableau dashboard, tracking all non-crypto wallet withdrawal requests over the last 15 days. It is the complement of `BI_DB_HourlyReport_Redeems` — while Redeems covers FundingTypeID=27 (eToroCryptoWallet), this table covers ALL other funding types (Visa, Wire, PayPal, eToroMoney, etc.).

Each row represents a single withdrawal request (WithdrawID, with a NOT ENFORCED primary key) that is not cancelled (CashoutStatusID != 4). The table provides:
- **Request details**: amount, date, approval status, foreclosure flag, pending customer feedback indicator
- **Funding leg breakdown**: PIVOT of `Billing.vWithdrawToFunding` amounts by CashoutStatusID 1-13, showing how much money is at each processing stage per withdrawal
- **Operational flags**: ReadyForPayment (fully funded + InProcess), FullyFunded (all legs in-flight with no processed/cancelled legs)

Current snapshot: 288,689 rows across 80,923 distinct customers. Status distribution: Processed (98.4%), InProcess (1.5%), Pending (0.2%), Rejected (0.003%), Partially Processed (0.001%).

Originally created by Guy Manova on 2018-04-09 for the Ops Tableau dashboard. Modified by Boris (linked server changes 2019-2020) and Pavlina Masoura (cashout status filter changes 2021, window reduced from 6 months to 2 weeks in August 2021).

---

## 2. Business Logic

### 2.1 Non-Crypto Filter (FundingTypeID != 27)

**What**: All funding types EXCEPT eToroCryptoWallet (27) are included.
**Columns Involved**: All — population filter
**Rules**:
- FundingTypeID NOT IN (27) — excludes crypto wallet (covered by BI_DB_HourlyReport_Redeems)
- CashoutStatusID NOT IN (4) — excludes Cancelled
- RequestDate >= GETDATE()-15 AND RequestDate < GETDATE() — 15-day rolling window

### 2.2 Funding Leg PIVOT (COStatus1-13)

**What**: Each withdrawal's funding legs are pivoted by their CashoutStatusID.
**Columns Involved**: `COStatus1` through `COStatus13`
**Rules**:
- Source: `Billing.vWithdrawToFunding` filtered to WithdrawIDs in the population
- PIVOT: SUM(Amount) FOR CashoutStatusID IN (1-13)
- Key statuses: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled, 5=Partially Processed, 7=Rejected
- NULL = no funding leg at that status

### 2.3 FullyFunded Detection

**What**: Identifies withdrawals where total funded amount matches request and all legs are in-flight.
**Columns Involved**: `FullyFunded`, `RequestAmount`, `FundingAmount`, `COStatus3`, `COStatus4`, `CashoutStatusID`
**Rules**:
- FullyFunded = 1 when ALL of:
  - RequestAmount = FundingAmount
  - COStatus3 IS NULL (no Processed legs)
  - COStatus4 IS NULL (no Cancelled legs)
  - CashoutStatusID = 2 (InProcess at withdraw level)
- Int type (unlike Object 3 which is money type)

### 2.4 Foreclosed Flag

**What**: Identifies withdrawals triggered by account foreclosure or affiliate payments.
**Columns Involved**: `Foreclosed`
**Rules**:
- Foreclosed = 1 when CashoutReasonID IN (12=Foreclose account, 15=Affiliate Payment)

### 2.5 PendingCustomerFeedback

**What**: Detects meaningful customer feedback.
**Columns Involved**: `PendingCustomerFeedback`
**Rules**:
- PendingCustomerFeedback = 1 when LEN(Billing.Withdraw.Comment) > 4

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. PK on WithdrawID (NOT ENFORCED — for documentation/optimizer hints only, no physical uniqueness enforcement).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many pending withdrawals by status? | `SELECT CashoutStatus, COUNT(*), SUM(RequestAmount) FROM ... GROUP BY CashoutStatus` |
| Withdrawals ready for final payment | `SELECT * FROM ... WHERE ReadyForPayment = 1 OR FullyFunded = 1` |
| Foreclosure-driven withdrawals | `SELECT * FROM ... WHERE Foreclosed = 1` |
| Pending customer feedback review | `SELECT * FROM ... WHERE PendingCustomerFeedback = 1 AND CashoutStatusID IN (1,2)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | Dim_Customer.RealCID = CID | Customer details |
| DWH_dbo.Dim_FundingType | (not stored — requires re-joining to External_etoro_Billing_Withdraw) | Funding method name |

### 3.4 Gotchas

- **Companion table pair**: This table (non-crypto) + BI_DB_HourlyReport_Redeems (crypto=27) together cover ALL active withdrawals. To see all withdrawals, UNION both tables.
- **15-day window vs 30 days for Redeems**: Different window sizes — Withdraws is 15 days, Redeems is 30 days
- **WithdrawID is int here vs bigint in Redeems**: Possible truncation risk for large WithdrawID values
- **PK is NOT ENFORCED**: Duplicates are theoretically possible if the SP produces them (unlikely given WithdrawID grouping)
- **No FundingType column**: Unlike Object 1, this table does not resolve the funding type name — to see which payment method, you need to re-join to the external table

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream production wiki (Billing.Withdraw) — verbatim | Highest |
| Tier 2 | SP code analysis + DWH dimension lookups | High |
| Tier 5 | ETL metadata (GETDATE) | Standard |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | WithdrawID | int | NO | Withdrawal request identifier. Primary key, IDENTITY starting at 1. NOT ENFORCED PK constraint. Passthrough from Billing.Withdraw. (Tier 1 — Billing.Withdraw) |
| 2 | CID | int | YES | Customer ID. FK to Customer.CustomerStatic. Passthrough from Billing.Withdraw. (Tier 1 — Billing.Withdraw) |
| 3 | RequestAmount | money | YES | Gross withdrawal amount in CurrencyID denomination. Renamed from Billing.Withdraw.Amount. (Tier 1 — Billing.Withdraw) |
| 4 | RequestDate | datetime | YES | Timestamp when the customer submitted the withdrawal request. Passthrough from Billing.Withdraw. Only last 15 days included. (Tier 1 — Billing.Withdraw) |
| 5 | FundingAmount | money | YES | Total funding leg amount: SUM(External_etoro_Billing_vWithdrawToFunding.Amount) per WithdrawID. When FundingAmount equals RequestAmount, the withdrawal is fully funded. NULL if no funding legs exist yet (e.g., Pending status). (Tier 2 — SP_H_Ops_HourlyReport_Withdraws) |
| 6 | CashoutStatusID | int | YES | Current withdrawal status. FK to Dictionary.CashoutStatus. Values in data: 1=Pending, 2=InProcess, 3=Processed, 5=Partially Processed, 7=Rejected. Cancelled (4) excluded from population. Passthrough from Billing.Withdraw. (Tier 1 — Billing.Withdraw) |
| 7 | CashoutStatus | varchar(30) | YES | Cashout status name resolved from Dim_CashoutStatus. Current distribution: Processed (98.4%), InProcess (1.5%), Pending (0.2%), Rejected (0.003%), Partially Processed (0.001%). (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Dim_CashoutStatus) |
| 8 | PendingCustomerFeedback | int | YES | Whether the customer provided meaningful feedback: CASE WHEN LEN(Billing.Withdraw.Comment) > 4 THEN 1 ELSE 0. Indicates comment is more than trivial placeholder. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws) |
| 9 | Approved | int | YES | Whether the withdrawal has received required approval: 1=Approved, 0=Pending approval. Passthrough from Billing.Withdraw.Approved. (Tier 1 — Billing.Withdraw) |
| 10 | Foreclosed | int | YES | Whether the withdrawal was triggered by account foreclosure or affiliate payment: CASE WHEN CashoutReasonID IN (12=Foreclose account, 15=Affiliate Payment) THEN 1 ELSE 0. System-initiated, not customer-initiated. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws) |
| 11 | ReadyForPayment | int | YES | Flag indicating withdrawal is fully funded and InProcess: SUM(CASE WHEN RequestAmount=FundingAmount AND CashoutStatusID=2 THEN 1 ELSE 0). Per-row aggregation yields 0 or 1. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws) |
| 12 | COStatus1 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=1 (Pending). NULL if no legs at this status. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 13 | COStatus2 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=2 (InProcess). NULL if no legs at this status. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 14 | COStatus3 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=3 (Processed). NULL if no legs at this status. Used in FullyFunded check (must be NULL). (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 15 | COStatus4 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=4 (Cancelled). NULL if no legs at this status. Used in FullyFunded check (must be NULL). (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 16 | COStatus5 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=5 (Partially Processed). NULL if no legs at this status. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 17 | COStatus6 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=6. NULL if no legs at this status. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 18 | COStatus7 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=7 (Rejected). NULL if no legs at this status. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 19 | COStatus8 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=8. NULL if no legs at this status. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 20 | COStatus9 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=9. NULL if no legs at this status. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 21 | COStatus10 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=10. NULL if no legs at this status. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 22 | COStatus11 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=11. NULL if no legs at this status. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 23 | COStatus12 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=12. NULL if no legs at this status. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 24 | COStatus13 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=13. NULL if no legs at this status. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws via Billing.vWithdrawToFunding) |
| 25 | FullyFunded | int | YES | Fully-funded flag for InProcess withdrawals: 1 when RequestAmount=FundingAmount AND COStatus3 IS NULL AND COStatus4 IS NULL AND CashoutStatusID=2. Identifies withdrawals ready for final processing with no processed or cancelled funding legs. (Tier 2 — SP_H_Ops_HourlyReport_Withdraws) |
| 26 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was inserted by the ETL pipeline (GETDATE()). Reflects the last hourly refresh time. NOT NULL constraint. (Tier 5 — SP_H_Ops_HourlyReport_Withdraws) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| WithdrawID | Billing.Withdraw | WithdrawID | Passthrough |
| CID | Billing.Withdraw | CID | Passthrough |
| RequestAmount | Billing.Withdraw | Amount | Rename |
| RequestDate | Billing.Withdraw | RequestDate | Passthrough |
| FundingAmount | Billing.vWithdrawToFunding | Amount | SUM per WithdrawID |
| CashoutStatusID | Billing.Withdraw | CashoutStatusID | Passthrough |
| CashoutStatus | Dim_CashoutStatus | Name | Lookup |
| PendingCustomerFeedback | Billing.Withdraw | Comment | LEN > 4 → 1/0 |
| Approved | Billing.Withdraw | Approved | Passthrough |
| Foreclosed | Billing.Withdraw | CashoutReasonID | IN (12,15) → 1/0 |
| ReadyForPayment | — | — | Computed from RequestAmount, FundingAmount, CashoutStatusID |
| COStatus1-13 | Billing.vWithdrawToFunding | Amount | PIVOT by CashoutStatusID |
| FullyFunded | — | — | Computed from RequestAmount, FundingAmount, COStatus3/4, CashoutStatusID |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Billing.Withdraw (active, etoroDB-REAL, 1.66M rows)
  |-- Generic Pipeline (Override, delta, 60 min) ---|
  v
External_etoro_Billing_Withdraw (BI_DB_dbo)
  |                                                  |
  |  etoro.Billing.vWithdrawToFunding (1.07M rows)   |
  |    |-- Generic Pipeline ---|                     |
  |    v                                             |
  |  External_etoro_Billing_vWithdrawToFunding       |
  |                                                  |
  +--- SP_H_Ops_HourlyReport_Withdraws (hourly) ----|
  |    Filters: FundingTypeID NOT IN (27)            |
  |    CashoutStatusID != 4 (not Cancelled)          |
  |    Last 15 days                                  |
  |    JOINs: Dim_CashoutStatus                      |
  |    PIVOT: vWithdrawToFunding by CashoutStatusID  |
  v
BI_DB_dbo.BI_DB_HourlyReport_Withdraws (288.7K rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| WithdrawID | Billing.Withdraw | Parent withdrawal request |
| CID | DWH_dbo.Dim_Customer | Customer dimension (via RealCID) |
| CashoutStatusID | DWH_dbo.Dim_CashoutStatus | Cashout status dimension |

### 6.2 Referenced By (other objects point to this)

No other BI_DB_dbo objects reference this table. It is a leaf operational dashboard table consumed by the Ops Tableau dashboard.

---

## 7. Sample Queries

### 7.1 Withdrawal status summary

```sql
SELECT
    CashoutStatus,
    COUNT(*) AS WithdrawCount,
    SUM(RequestAmount) AS TotalRequestAmount,
    SUM(FundingAmount) AS TotalFundedAmount,
    SUM(FullyFunded) AS FullyFundedCount
FROM BI_DB_dbo.BI_DB_HourlyReport_Withdraws
GROUP BY CashoutStatus
ORDER BY WithdrawCount DESC
```

### 7.2 Pending/InProcess withdrawals with customer feedback

```sql
SELECT
    WithdrawID,
    CID,
    RequestAmount,
    RequestDate,
    CashoutStatus,
    PendingCustomerFeedback,
    Approved,
    Foreclosed
FROM BI_DB_dbo.BI_DB_HourlyReport_Withdraws
WHERE CashoutStatusID IN (1, 2)
ORDER BY RequestDate ASC
```

### 7.3 Combined view with crypto redeems

```sql
SELECT 'Withdraws' AS Source, CashoutStatus, COUNT(*) AS Cnt, SUM(RequestAmount) AS Total
FROM BI_DB_dbo.BI_DB_HourlyReport_Withdraws
GROUP BY CashoutStatus
UNION ALL
SELECT 'Redeems' AS Source, CashoutStatus, COUNT(*) AS Cnt, SUM(RequestAmount) AS Total
FROM BI_DB_dbo.BI_DB_HourlyReport_Redeems
GROUP BY CashoutStatus
ORDER BY Source, Cnt DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 6 T1, 19 T2, 0 T3, 0 T4, 1 T5 | Elements: 26/26, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_HourlyReport_Withdraws | Type: Table | Production Source: etoro.Billing.Withdraw via SP_H_Ops_HourlyReport_Withdraws*
