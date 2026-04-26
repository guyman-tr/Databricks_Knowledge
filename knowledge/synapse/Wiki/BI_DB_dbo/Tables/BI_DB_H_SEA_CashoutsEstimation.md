# BI_DB_dbo.BI_DB_H_SEA_CashoutsEstimation

> Hourly TRUNCATE snapshot of pending and in-process OnlineBanking (FundingTypeID=28) and UnionPay (FundingTypeID=22) cashout requests for the SEA (South-East Asia) Cashouts & Finance operations teams. Currently 0 rows (live operational snapshot — row count fluctuates hourly based on pending withdrawal queue). Refreshed hourly via SP_H_SEA_CashoutsEstimation (SB_Hourly).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Billing.Withdraw via SP_H_SEA_CashoutsEstimation |
| **Refresh** | Hourly (SB_Hourly, TRUNCATE + INSERT) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_H_SEA_CashoutsEstimation` is an hourly operational estimation table built for the SEA Cashouts and Finance teams to monitor pending and in-process withdrawal requests specifically for OnlineBanking (FundingTypeID=28) and UnionPay (FundingTypeID=22) payment methods. The table is fully truncated and rebuilt every hour, so its row count reflects the current pending cashout queue at the time of the last refresh — when all pending cashouts have been processed, the table is empty (as observed at query time: 0 rows).

Each row represents a single withdrawal request (identified by WID / WithdrawID) that is in one of three pending states:
- **Pending** (CashoutStatusID=1): new requests awaiting initial review, sourced from `Billing.Withdraw` directly
- **InProcess** (CashoutStatusID=2): requests being processed that have NOT yet been linked to a funding leg (not in `Billing.WithdrawToFunding`), also from `Billing.Withdraw`
- **Pending Review** (CashoutStatusID=14): requests that HAVE a funding leg (`Billing.WithdrawToFunding`) but are pending review, sourced through the funding path

The SP assigns a SCREEN label to each row: 'WD Requests Screen' for Pending/InProcess cashouts (operations queue) and 'PaymentsToSend' for PendingReview cashouts (finance payment queue). If a withdrawal appears in both paths, the PaymentsToSend classification takes priority.

The table enriches each withdrawal with the customer's regulation (via Dim_Customer → Dim_Regulation), the resolved funding method name, cashout status name, and account currency abbreviation.

Created by Pavlina Masuora on 2021-07-15 for OnlineBanking and UnionPay cashout operations monitoring.

---

## 2. Business Logic

### 2.1 Dual Processing Path (Pending vs PendingReview)

**What**: Withdrawals are classified into two processing paths based on their lifecycle stage.
**Columns Involved**: `SCREEN`, `Status`, `WID`
**Rules**:
- Path 1 — **WD Requests Screen**: Withdrawals from `Billing.Withdraw` with CashoutStatusID IN (1=Pending, 2=InProcess). For InProcess, only those NOT yet in `Billing.vWithdrawToFunding` (no funding leg created yet).
- Path 2 — **PaymentsToSend**: Withdrawals that HAVE a funding leg in `Billing.WithdrawToFunding` with CashoutStatusID=14 (Pending Review), joined through `Billing.Funding` to confirm FundingTypeID IN (22, 28).
- Priority: If the same WID appears in both paths, it appears ONLY as 'PaymentsToSend' (UNION with NOT IN exclusion).

### 2.2 OnlineBanking + UnionPay Filter

**What**: Only two specific payment methods are included.
**Columns Involved**: `Funding Method`, `FundingID`
**Rules**:
- FundingTypeID=22 → UnionPay
- FundingTypeID=28 → OnlineBanking
- All other funding types are excluded — this table is specifically for SEA operations

### 2.3 Date Filter

**What**: Only historical requests (before today) are included.
**Columns Involved**: `Request Time`
**Rules**:
- `CAST(RequestDate AS DATE) < CAST(GETDATE() AS DATE)` — excludes same-day requests
- This ensures the estimation is based on overnight/backlog items, not intraday submissions

### 2.4 Amount Aggregation

**What**: Net cashout amount is aggregated per withdrawal.
**Columns Involved**: `Net. Cashout Amount`
**Rules**:
- `SUM(CAST(Amount AS decimal(16,2)))` grouped by WithdrawID
- For the WithdrawToFunding path, the amount comes from the funding leg (`BWTF.Amount`), not the original withdrawal request

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP — no clustered index or distribution key. Suitable for the small, fully-truncated hourly snapshots expected. Full table scans are the only access pattern.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many pending cashouts by screen? | `SELECT SCREEN, COUNT(*), SUM([Net. Cashout Amount]) FROM BI_DB_dbo.BI_DB_H_SEA_CashoutsEstimation GROUP BY SCREEN` |
| Pending cashouts by regulation | `SELECT Regulation, COUNT(*), SUM([Net. Cashout Amount]) ... GROUP BY Regulation` |
| Oldest pending requests | `SELECT * ... ORDER BY [Request Time] ASC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | Dim_Customer.RealCID = CID | Customer details enrichment |

### 3.4 Gotchas

- **Column names have spaces and special characters**: `[Net. Cashout Amount]`, `[Funding Method]`, `[Request Time]` — always use bracket notation
- **Table may be empty**: This is normal — 0 rows means no pending OnlineBanking/UnionPay cashouts at last refresh
- **Approved is a string 'YES'/'NO'**: Not a bit field like the source — converted from `Billing.Withdraw.Approved` (bit) to varchar
- **Same-day requests excluded**: Only shows requests from before today (overnight backlog)
- **SCREEN column name is all-caps**: Hardcoded label, not from a lookup table

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
| 1 | WID | bigint | YES | FK to Billing.Withdraw. The parent withdrawal request. One WithdrawID can have multiple payment legs. Renamed from WithdrawID. (Tier 1 — Billing.Withdraw) |
| 2 | CID | int | YES | Customer ID. FK to Customer.CustomerStatic. Indexed in covering indexes. (Tier 1 — Billing.Withdraw) |
| 3 | Net. Cashout Amount | money | YES | Gross withdrawal amount aggregated per WithdrawID: SUM(CAST(Amount AS decimal(16,2))). For Pending/InProcess path, sourced from Billing.Withdraw.Amount; for PendingReview path, sourced from Billing.WithdrawToFunding.Amount via funding leg. (Tier 2 — SP_H_SEA_CashoutsEstimation) |
| 4 | Status | varchar(50) | YES | Cashout status name resolved from Dim_CashoutStatus. Expected values: Pending (CashoutStatusID=1), InProcess (CashoutStatusID=2), Pending Review (CashoutStatusID=14). (Tier 2 — SP_H_SEA_CashoutsEstimation via Dim_CashoutStatus) |
| 5 | Funding Method | varchar(50) | YES | Payment method name resolved from Dim_FundingType. Expected values: UnionPay (FundingTypeID=22), OnlineBanking (FundingTypeID=28). (Tier 2 — SP_H_SEA_CashoutsEstimation via Dim_FundingType) |
| 6 | Request Time | datetime | YES | Timestamp when the customer submitted the withdrawal request. Renamed from RequestDate. Only requests before today are included. (Tier 1 — Billing.Withdraw) |
| 7 | FundingID | bigint | YES | FK to Billing.Funding — the payment instrument to which the withdrawal should be paid. NULL if no specific instrument selected at request time. From Billing.Withdraw.FundingID for Pending/InProcess; from Billing.WithdrawToFunding.FundingID for PendingReview path. (Tier 1 — Billing.Withdraw) |
| 8 | AMOPCurrency | varchar(20) | YES | Account/process currency abbreviation resolved from Dim_Currency. For Pending/InProcess path, joined on AccountCurrencyID; for PendingReview path, joined on ProcessCurrencyID. (Tier 2 — SP_H_SEA_CashoutsEstimation via Dim_Currency) |
| 9 | Approved | varchar(20) | YES | Whether the withdrawal has received required approval. Converted from bit to string: CASE WHEN Billing.Withdraw.Approved=1 THEN 'YES' ELSE 'NO'. (Tier 2 — SP_H_SEA_CashoutsEstimation) |
| 10 | SCREEN | varchar(100) | YES | Operational screen classification. Hardcoded by SP: 'PaymentsToSend' for PendingReview cashouts (CashoutStatusID=14, funding leg exists), 'WD Requests Screen' for Pending/InProcess cashouts (CashoutStatusID=1 or 2, no funding leg yet). PaymentsToSend takes priority if WID appears in both paths. (Tier 2 — SP_H_SEA_CashoutsEstimation) |
| 11 | Regulation | varchar(50) | YES | Customer regulation name resolved via JOIN chain: Dim_Customer.RealCID=CID → Dim_Customer.RegulationID → Dim_Regulation.Name. NULL if customer not found or regulation not mapped. (Tier 2 — SP_H_SEA_CashoutsEstimation via Dim_Regulation) |
| 12 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline (GETDATE()). Reflects the last hourly refresh time. (Tier 5 — SP_H_SEA_CashoutsEstimation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| WID | Billing.Withdraw | WithdrawID | Rename |
| CID | Billing.Withdraw | CID | Passthrough |
| Net. Cashout Amount | Billing.Withdraw / WithdrawToFunding | Amount | SUM(CAST(Amount AS decimal(16,2))) |
| Status | Dim_CashoutStatus | Name | Lookup on CashoutStatusID |
| Funding Method | Dim_FundingType | Name | Lookup on FundingTypeID |
| Request Time | Billing.Withdraw | RequestDate | Rename |
| FundingID | Billing.Withdraw / WithdrawToFunding | FundingID | Passthrough (path-dependent) |
| AMOPCurrency | Dim_Currency | Abbreviation | Lookup on AccountCurrencyID / ProcessCurrencyID |
| Approved | Billing.Withdraw | Approved | CASE bit → 'YES'/'NO' |
| SCREEN | — | — | Hardcoded by processing path |
| Regulation | Dim_Regulation | Name | Lookup chain via Dim_Customer |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Billing.Withdraw (active, etoroDB-REAL, 1.66M rows)
  |-- Generic Pipeline (Override, delta, 60 min) ---|
  v
External_etoro_Billing_Withdraw (BI_DB_dbo)
  |                                                  |
  |  etoro.Billing.vWithdrawToFunding (1.07M rows)   |
  |  etoro.Billing.Funding                           |
  |    |-- Generic Pipeline ---|                     |
  |    v                                             |
  |  External_etoro_Billing_vWithdrawToFunding       |
  |  External_etoro_Billing_Funding_Datafactory      |
  |                                                  |
  +--- SP_H_SEA_CashoutsEstimation (hourly) --------|
  |    Filters: FundingTypeID IN (22,28)             |
  |    CashoutStatusID IN (1,2,14)                   |
  |    RequestDate < TODAY                           |
  |    JOINs: Dim_FundingType, Dim_Currency,         |
  |           Dim_CashoutStatus, Dim_Customer,       |
  |           Dim_Regulation                         |
  v
BI_DB_dbo.BI_DB_H_SEA_CashoutsEstimation (0 rows — live snapshot)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| WID | Billing.Withdraw | Parent withdrawal request |
| CID | DWH_dbo.Dim_Customer | Customer dimension (via RealCID) |
| FundingID | Billing.Funding | Payment instrument |
| Status | DWH_dbo.Dim_CashoutStatus | Cashout status name lookup |
| Funding Method | DWH_dbo.Dim_FundingType | Payment method name lookup |
| AMOPCurrency | DWH_dbo.Dim_Currency | Currency abbreviation lookup |
| Regulation | DWH_dbo.Dim_Regulation | Regulation name lookup |

### 6.2 Referenced By (other objects point to this)

No other BI_DB_dbo objects reference this table. It is a leaf operational dashboard table consumed by the SEA operations team.

---

## 7. Sample Queries

### 7.1 Pending cashout summary by screen and regulation

```sql
SELECT
    SCREEN,
    Regulation,
    COUNT(*) AS PendingCount,
    SUM([Net. Cashout Amount]) AS TotalAmount
FROM BI_DB_dbo.BI_DB_H_SEA_CashoutsEstimation
GROUP BY SCREEN, Regulation
ORDER BY TotalAmount DESC
```

### 7.2 Oldest pending cashout requests

```sql
SELECT
    WID,
    CID,
    [Net. Cashout Amount],
    Status,
    [Funding Method],
    [Request Time],
    SCREEN,
    Regulation
FROM BI_DB_dbo.BI_DB_H_SEA_CashoutsEstimation
ORDER BY [Request Time] ASC
```

### 7.3 Approved vs unapproved breakdown

```sql
SELECT
    Approved,
    SCREEN,
    COUNT(*) AS RequestCount,
    SUM([Net. Cashout Amount]) AS TotalAmount
FROM BI_DB_dbo.BI_DB_H_SEA_CashoutsEstimation
GROUP BY Approved, SCREEN
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 4 T1, 7 T2, 0 T3, 0 T4, 1 T5 | Elements: 12/12, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: BI_DB_dbo.BI_DB_H_SEA_CashoutsEstimation | Type: Table | Production Source: etoro.Billing.Withdraw via SP_H_SEA_CashoutsEstimation*
