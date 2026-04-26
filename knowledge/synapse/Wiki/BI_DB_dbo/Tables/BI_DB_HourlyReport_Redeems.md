# BI_DB_dbo.BI_DB_HourlyReport_Redeems

> 4,097-row hourly TRUNCATE snapshot of eToroCryptoWallet (FundingTypeID=27) withdrawal requests from the last 30 days (excluding cancelled), tracking 1,516 distinct customers with per-status funding leg breakdowns (PIVOT by CashoutStatusID 1-13) and fully-funded detection. Refreshed hourly via SP_H_HourlyReport_Redeems (SB_Hourly).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Withdraw + Billing.vWithdrawToFunding via SP_H_HourlyReport_Redeems |
| **Refresh** | Hourly (SB_Hourly, TRUNCATE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_HourlyReport_Redeems` is an hourly operational report tracking eToroCryptoWallet (FundingTypeID=27) withdrawal requests over the last 30 days. Despite the table name containing "Redeems," the data is filtered to crypto wallet withdrawals specifically — the "redeem" terminology reflects the eToro crypto withdrawal workflow where users redeem crypto holdings to external wallets.

Each row represents a single withdrawal request (WithdrawID) that is not cancelled (CashoutStatusID != 4). The table provides a comprehensive operational view:
- **Request details**: amount, date, approval status, foreclosure flag
- **Funding leg breakdown**: PIVOT of `Billing.vWithdrawToFunding` amounts by CashoutStatusID 1-13 (13 columns: COStatus1 through COStatus13), showing how much money is at each processing stage
- **Operational flags**: ReadyForPayment (fully funded + InProcess), FullyFunded (all legs complete with no processed/cancelled legs), PendingCustomerFeedback (customer comment > 4 characters)

The table is fully truncated and rebuilt every hour. Current snapshot: 4,097 rows, 1,516 distinct CIDs, with 99.95% already Processed and 0.05% InProcess. The 30-day window means the table shows both resolved and still-pending requests.

Created by Pavlina Masoura on 2021-03-11. Used by operations teams for crypto withdrawal monitoring dashboards.

---

## 2. Business Logic

### 2.1 FundingTypeID=27 Filter (eToroCryptoWallet)

**What**: Only crypto wallet withdrawals are included.
**Columns Involved**: All — this is a population filter
**Rules**:
- FundingTypeID IN (27) — eToroCryptoWallet only
- CashoutStatusID NOT IN (4) — excludes Cancelled
- RequestDate > GETDATE()-30 AND RequestDate < GETDATE() — 30-day rolling window, excludes future-dated

### 2.2 Funding Leg PIVOT (COStatus1-13)

**What**: Each withdrawal's funding legs are pivoted by their CashoutStatusID.
**Columns Involved**: `COStatus1` through `COStatus13`
**Rules**:
- Source: `Billing.vWithdrawToFunding` filtered to WithdrawIDs in the population
- PIVOT: SUM(Amount) FOR CashoutStatusID IN (1-13)
- Each COStatusN column shows the total funding amount at that status
- Key statuses: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled
- NULL = no funding leg at that status

### 2.3 FullyFunded Detection

**What**: Identifies withdrawals where the total funded amount equals the request and all legs are at terminal status.
**Columns Involved**: `FullyFunded`, `RequestAmount`, `FundingAmount`, `COStatus3`, `COStatus4`, `CashoutStatusID`
**Rules**:
- FullyFunded = 1 when ALL of:
  - RequestAmount = FundingAmount (total funding matches request)
  - COStatus3 IS NULL (no Processed legs — meaning all funding is still in-progress)
  - COStatus4 IS NULL (no Cancelled legs)
  - CashoutStatusID = 2 (InProcess at withdraw level)
- This identifies withdrawals that are ready for final processing

### 2.4 Foreclosed Flag

**What**: Identifies withdrawals triggered by account foreclosure or affiliate payments.
**Columns Involved**: `Foreclosed`
**Rules**:
- Foreclosed = 1 when CashoutReasonID IN (12=Foreclose account, 15=Affiliate Payment)
- These are system-initiated, not customer-initiated

### 2.5 PendingCustomerFeedback

**What**: Detects if the customer has provided meaningful feedback on the withdrawal.
**Columns Involved**: `PendingCustomerFeedback`
**Rules**:
- PendingCustomerFeedback = 1 when LEN(Billing.Withdraw.Comment) > 4
- Threshold of 4 characters filters out empty/trivial entries

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — no distribution key or clustered index. Full table scans for the small hourly snapshot (4K rows).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many crypto redeems are pending? | `SELECT CashoutStatus, COUNT(*), SUM(RequestAmount) FROM ... GROUP BY CashoutStatus` |
| Which redeems are fully funded? | `SELECT * FROM ... WHERE FullyFunded = 1` |
| Foreclosed vs customer-initiated | `SELECT Foreclosed, COUNT(*), SUM(RequestAmount) FROM ... GROUP BY Foreclosed` |
| Funding leg status breakdown | `SELECT WithdrawID, COStatus1, COStatus2, COStatus3 FROM ... WHERE COStatus1 IS NOT NULL OR COStatus2 IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | Dim_Customer.RealCID = CID | Customer details |
| DWH_dbo.Dim_CashoutStatus | CashoutStatusID | Status name (already resolved in CashoutStatus column) |

### 3.4 Gotchas

- **Table name says "Redeems" but data is eToroCryptoWallet (FundingTypeID=27)**: The "redeem" label refers to crypto wallet redemption, not a separate "Redeem" funding type
- **FullyFunded logic may surprise**: It checks COStatus3 IS NULL AND COStatus4 IS NULL — meaning the funding legs have NOT reached Processed or Cancelled. This identifies "in-flight" fully-funded redeems, not completed ones
- **ReadyForPayment always 0 in current data**: The aggregation is SUM(CASE...) but is computed at a GROUP BY level, producing 0 or 1 — check if this is always 0 due to double grouping
- **COStatus columns are money type**: They represent SUM(Amount) at each status, not counts
- **Typo in external table name**: `External_etoro_Billimg_vWithdrawToFunding_FUll` has "Billimg" instead of "Billing" and "FUll" with inconsistent casing

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
| 1 | WithdrawID | bigint | YES | Withdrawal request identifier. Primary key, IDENTITY starting at 1. Passthrough from Billing.Withdraw. (Tier 1 — Billing.Withdraw) |
| 2 | CID | int | YES | Customer ID. FK to Customer.CustomerStatic. Passthrough from Billing.Withdraw. (Tier 1 — Billing.Withdraw) |
| 3 | RequestAmount | money | YES | Gross withdrawal amount in CurrencyID denomination. Renamed from Billing.Withdraw.Amount. (Tier 1 — Billing.Withdraw) |
| 4 | RequestDate | datetime | YES | Timestamp when the customer submitted the withdrawal request. Passthrough from Billing.Withdraw. Only last 30 days included. (Tier 1 — Billing.Withdraw) |
| 5 | FundingAmount | money | YES | Total funding leg amount: SUM(External_etoro_Billimg_vWithdrawToFunding_FUll.Amount) per WithdrawID. When FundingAmount equals RequestAmount, the withdrawal is fully funded. NULL if no funding legs exist. (Tier 2 — SP_H_HourlyReport_Redeems) |
| 6 | CashoutStatusID | int | YES | Current withdrawal status. FK to Dictionary.CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled. Passthrough from Billing.Withdraw. Cancelled (4) excluded from population. (Tier 1 — Billing.Withdraw) |
| 7 | CashoutStatus | varchar(30) | YES | Cashout status name resolved from Dim_CashoutStatus. Current values in data: Processed (99.95%), InProcess (0.05%). (Tier 2 — SP_H_HourlyReport_Redeems via Dim_CashoutStatus) |
| 8 | PendingCustomerFeedback | int | YES | Whether the customer provided meaningful feedback: CASE WHEN LEN(Billing.Withdraw.Comment) > 4 THEN 1 ELSE 0. Indicates comment is more than trivial placeholder. (Tier 2 — SP_H_HourlyReport_Redeems) |
| 9 | Approved | int | YES | Whether the withdrawal has received required approval: 1=Approved, 0=Pending approval. Passthrough from Billing.Withdraw.Approved (int, not converted to string). (Tier 1 — Billing.Withdraw) |
| 10 | Foreclosed | int | YES | Whether the withdrawal was triggered by account foreclosure or affiliate payment: CASE WHEN CashoutReasonID IN (12=Foreclose account, 15=Affiliate Payment) THEN 1 ELSE 0. System-initiated, not customer-initiated. (Tier 2 — SP_H_HourlyReport_Redeems) |
| 11 | ReadyForPayment | int | YES | Flag indicating withdrawal is fully funded and InProcess: SUM(CASE WHEN RequestAmount=FundingAmount AND CashoutStatusID=2 THEN 1 ELSE 0). Per-row aggregation yields 0 or 1. (Tier 2 — SP_H_HourlyReport_Redeems) |
| 12 | COStatus1 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=1 (Pending). NULL if no legs at this status. (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 13 | COStatus2 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=2 (InProcess). NULL if no legs at this status. (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 14 | COStatus3 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=3 (Processed). NULL if no legs at this status. Used in FullyFunded check (must be NULL). (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 15 | COStatus4 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=4 (Cancelled). NULL if no legs at this status. Used in FullyFunded check (must be NULL). (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 16 | COStatus5 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=5. NULL if no legs at this status. (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 17 | COStatus6 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=6. NULL if no legs at this status. (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 18 | COStatus7 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=7. NULL if no legs at this status. (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 19 | COStatus8 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=8. NULL if no legs at this status. (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 20 | COStatus9 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=9. NULL if no legs at this status. (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 21 | COStatus10 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=10. NULL if no legs at this status. (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 22 | COStatus11 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=11. NULL if no legs at this status. (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 23 | COStatus12 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=12. NULL if no legs at this status. (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 24 | COStatus13 | money | YES | PIVOT: SUM of funding leg amounts at CashoutStatusID=13. NULL if no legs at this status. (Tier 2 — SP_H_HourlyReport_Redeems via Billing.vWithdrawToFunding) |
| 25 | FullyFunded | money | YES | Fully-funded flag for InProcess redeems: 1 when RequestAmount=FundingAmount AND COStatus3 IS NULL AND COStatus4 IS NULL AND CashoutStatusID=2. Identifies withdrawals ready for final processing with no processed or cancelled funding legs. Money type but contains 0/1 values. (Tier 2 — SP_H_HourlyReport_Redeems) |
| 26 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline (GETDATE()). Reflects the last hourly refresh time. (Tier 5 — SP_H_HourlyReport_Redeems) |

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
  |  External_etoro_Billimg_vWithdrawToFunding_FUll  |
  |                                                  |
  +--- SP_H_HourlyReport_Redeems (hourly) ----------|
  |    Filters: FundingTypeID=27 (eToroCryptoWallet) |
  |    CashoutStatusID != 4 (not Cancelled)          |
  |    Last 30 days                                  |
  |    JOINs: Dim_CashoutStatus                      |
  |    PIVOT: vWithdrawToFunding by CashoutStatusID  |
  v
BI_DB_dbo.BI_DB_HourlyReport_Redeems (4,097 rows)
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

No other BI_DB_dbo objects reference this table. It is a leaf operational dashboard table consumed by operations teams.

---

## 7. Sample Queries

### 7.1 Crypto redeem status summary

```sql
SELECT
    CashoutStatus,
    COUNT(*) AS RedeemCount,
    SUM(RequestAmount) AS TotalRequestAmount,
    SUM(FundingAmount) AS TotalFundedAmount,
    SUM(CASE WHEN FullyFunded = 1 THEN 1 ELSE 0 END) AS FullyFundedCount
FROM BI_DB_dbo.BI_DB_HourlyReport_Redeems
GROUP BY CashoutStatus
ORDER BY RedeemCount DESC
```

### 7.2 Unfunded or partially funded redeems

```sql
SELECT
    WithdrawID,
    CID,
    RequestAmount,
    FundingAmount,
    RequestAmount - ISNULL(FundingAmount, 0) AS Shortfall,
    CashoutStatus,
    RequestDate
FROM BI_DB_dbo.BI_DB_HourlyReport_Redeems
WHERE ISNULL(FundingAmount, 0) < RequestAmount
ORDER BY RequestDate ASC
```

### 7.3 Foreclosed vs customer-initiated breakdown

```sql
SELECT
    Foreclosed,
    COUNT(*) AS RedeemCount,
    SUM(RequestAmount) AS TotalAmount,
    AVG(RequestAmount) AS AvgAmount
FROM BI_DB_dbo.BI_DB_HourlyReport_Redeems
GROUP BY Foreclosed
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 6 T1, 19 T2, 0 T3, 0 T4, 1 T5 | Elements: 26/26, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_HourlyReport_Redeems | Type: Table | Production Source: etoro.Billing.Withdraw via SP_H_HourlyReport_Redeems*
