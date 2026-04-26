# BI_DB_dbo.BI_DB_Negative_Balance_Monitor_Risk

> 78K-row aggregated monthly risk monitoring table tracking customer negative balance metrics across 39 end-of-month snapshots (Jan 2023 – Mar 2026). Each row represents a group of customers bucketed by regulation, MiFID category, player level, player status, depositor flag, and balance range. Refreshed monthly by SP_Negative_Balance_Monitor_Risk via DELETE+INSERT on end-of-month dates.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.V_Liabilities + Fact_SnapshotCustomer + Dim_Customer + Dim_PlayerLevel + Dim_PlayerStatus + Dim_MifidCategorization + Dim_Regulation via SP_Negative_Balance_Monitor_Risk |
| **Refresh** | Monthly (end-of-month only, DELETE+INSERT by FullDate) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | Not exported to Unity Catalog |

---

## 1. Business Meaning

This table powers the Risk team's Negative Balance Monitor dashboard, tracking how many customers have negative account balances at each month-end, bucketed by various customer attributes. It answers: **"How many customers have negative balances, what are the balance ranges, and are they trending better or worse?"**

The grain is a multi-dimensional group: FullDate x IsDepositor x Ind_FTD_Last_30days x MIFID x Club x PlayerStatus x Regulation x Negative_Balance_Ind x More_than_30Days_ind x Funded x Balance_Group x Registration_Last_30_Days. Each row has a `Customers` count and `Balance` sum for that group.

Key characteristics:
- **78K rows** across 39 end-of-month snapshots (Jan 2023 – Mar 2026), ~2K groups/month
- **Balance source**: V_Liabilities (Liabilities + ActualNWA = total account balance)
- **Only valid customers**: Fact_SnapshotCustomer.IsValidCustomer=1 with date range validation
- **Negative balance prevalence**: ~0.7% of customer-months have negative balance
- **Balance grouping**: 7 CASE buckets from "Positive Balance" down to "Check" (see bug note)
- **Month-over-month persistence**: More_than_30Days_ind flags customers with negative balance in both current and prior month
- Author: Artyom Bogomolsky, 2024-09-20

---

## 2. Business Logic

### 2.1 Balance Calculation

**What**: Customer balance = Liabilities + ActualNWA from V_Liabilities, taken at end-of-month snapshots.
**Columns Involved**: Balance, Negative_Balance_Ind, Balance_Group
**Rules**:
- Balance = SUM(Liabilities + ActualNWA) per group
- Negative_Balance_Ind = 1 when (Liabilities + ActualNWA) < 0, else 0
- Balance_Group CASE buckets: Positive Balance, >-1 USD, Between -1 and -10 USD, Between -10 and -50 USD, Between -50 and -100 USD, Between -100 and -500 USD, Check (fallthrough — see bug)

### 2.2 Month-over-Month Persistence

**What**: Flags customers with sustained negative balance across consecutive months.
**Columns Involved**: More_than_30Days_ind, Prev_Month
**Rules**:
- Self-join on #negative_balance_Artyom: same RealCID in Prev_Month with Balance < 0
- More_than_30Days_ind = 1 when the customer also had a negative balance in the prior month
- Prev_Month = EOMONTH(DATEADD(MONTH,-1,FullDate))

### 2.3 Customer Classification Dimensions

**What**: Groups by depositor status, FTD recency, registration recency, MiFID category, player level, player status, and regulation.
**Columns Involved**: IsDepositor, Ind_FTD_Last_30days, Registration_Last_30_Days, MIFID, Club, PlayerStatus, Regulation
**Rules**:
- Ind_FTD_Last_30days = 1 when DATEDIFF(day, FirstDepositDate, FullDate) <= 30
- Registration_Last_30_Days = 1 when DATEDIFF(day, RegisteredReal, FullDate) <= 30
- MIFID from Dim_MifidCategorization.Name (Retail, Retail Pending, Pending, Professional, etc.)
- Club from Dim_PlayerLevel.Name (Bronze, Silver, Gold, Platinum, Diamond, etc.)
- PlayerStatus from Dim_PlayerStatus.Name (Normal, Blocked, Deposit Blocked, etc.)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. Small table (78K rows) — full scans are efficient. No distribution key optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly negative balance customer count trend | `SELECT FullDate, SUM(CASE WHEN Negative_Balance_Ind=1 THEN Customers ELSE 0 END) FROM ... GROUP BY FullDate ORDER BY FullDate` |
| Negative balance by regulation | `SELECT Regulation, SUM(CASE WHEN Negative_Balance_Ind=1 THEN Customers ELSE 0 END) FROM ... WHERE FullDate='2026-03-31' GROUP BY Regulation` |
| Balance range distribution | `SELECT Balance_Group, SUM(Customers) FROM ... WHERE FullDate='2026-03-31' AND Negative_Balance_Ind=1 GROUP BY Balance_Group` |

### 3.3 Common JOINs

No common JOINs — this is an aggregated terminal table. Dimensions are already denormalized.

### 3.4 Gotchas

- **Balance_Group CASE bug**: Lines 101-102 in SP both test `nb.Balance >= -500`, making "Less than -500 USD" unreachable. Balances below -500 fall through to the ELSE "Check" bucket. Live data confirms: "Check" has 5,107 rows (these are the <-500 balances).
- **Funded column JOIN bug**: LEFT JOIN on BI_DB_DDR_CID_Level uses `bddcl.DateID = vl.CID` — comparing a date ID to a customer ID. This nonsensical condition means the JOIN almost never matches. Live data: 97.5% of Funded values are NULL.
- **BI_DB_DDR_CID_Level is blacklisted** — scheduled for decommission. The Funded column depends on it.
- **End-of-month only**: SP WHILE loop only fires when @Date = EOMONTH(@Date). Calling with mid-month dates produces no output.
- **INNER JOIN on Dim_Date**: Only IsLastDayOfMonth='Y' dates are included — ensures end-of-month snapshots only.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis | High — derived from ETL logic |
| Tier 5 | Propagation canonical | Standard ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FullDate | date | YES | End-of-month snapshot date from Dim_Date (IsLastDayOfMonth='Y'). Filter and partition key for monthly data. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 2 | IsDepositor | int | YES | Whether the customer has ever deposited. From Dim_Customer.IsDepositor. 1=has deposited, 0=never deposited. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 3 | Ind_FTD_Last_30days | int | YES | First-time deposit recency indicator. 1 if the customer's FirstDepositDate is within 30 days of FullDate, 0 otherwise. CASE: DATEDIFF(day, Dim_Customer.FirstDepositDate, FullDate) <= 30. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 4 | MIFID | varchar(200) | YES | MiFID categorization name from Dim_MifidCategorization. Values: Retail, Retail Pending, Pending, Professional, etc. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 5 | Club | varchar(200) | YES | Player level (tier) name from Dim_PlayerLevel. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, etc. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 6 | PlayerStatus | varchar(200) | YES | Player status name from Dim_PlayerStatus. Values: Normal, Blocked, Blocked Upon Request, Deposit Blocked, etc. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 7 | Regulation | varchar(200) | YES | Regulation name from Dim_Regulation. Values: CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, ASIC, MAS. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 8 | Negative_Balance_Ind | int | YES | 1 if the customer group has negative balance (Liabilities + ActualNWA < 0), 0 otherwise. Derived from V_Liabilities. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 9 | Prev_Month | date | YES | End of previous month: EOMONTH(DATEADD(MONTH,-1,FullDate)). Used for month-over-month self-join to compute More_than_30Days_ind. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 10 | More_than_30Days_ind | int | YES | 1 if the same customer had a negative balance in the prior month (self-join on RealCID + Prev_Month + Balance<0), 0 otherwise. Measures sustained negative balance. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 11 | Funded | int | YES | Funded_New_Def from BI_DB_DDR_CID_Level. WARNING: JOIN condition has a bug (DateID=CID — compares date to customer ID), causing ~97.5% NULL. BI_DB_DDR_CID_Level is blacklisted for decommission. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 12 | Balance_Group | varchar(200) | YES | Balance range bucket. CASE: Positive Balance, >-1 USD, Between -1 and -10 USD, Between -10 and -50 USD, Between -50 and -100 USD, Between -100 and -500 USD. WARNING: duplicate condition on >= -500 makes "Less than -500 USD" unreachable; those rows get "Check" instead. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 13 | Registration_Last_30_Days | int | YES | Recent registration indicator. 1 if the customer registered within 30 days of FullDate. CASE: DATEDIFF(day, Dim_Customer.RegisteredReal, FullDate) <= 30. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 14 | Customers | int | YES | Count of distinct customers (COUNT(RealCID)) in this group. Aggregation metric. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 15 | Balance | decimal(22,2) | YES | Total account balance for the group: SUM(Liabilities + ActualNWA) from V_Liabilities. Negative values indicate negative balance. In USD. (Tier 2 — SP_Negative_Balance_Monitor_Risk) |
| 16 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 — SP_Negative_Balance_Monitor_Risk) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| FullDate | Dim_Date | FullDate | End-of-month filter |
| IsDepositor | Dim_Customer | IsDepositor | Passthrough |
| Ind_FTD_Last_30days | Dim_Customer | FirstDepositDate | CASE DATEDIFF <=30 |
| MIFID | Dim_MifidCategorization | Name | JOIN lookup |
| Club | Dim_PlayerLevel | Name | JOIN lookup |
| PlayerStatus | Dim_PlayerStatus | Name | JOIN lookup |
| Regulation | Dim_Regulation | Name | JOIN lookup |
| Negative_Balance_Ind | V_Liabilities | Liabilities+ActualNWA | CASE <0 → 1 |
| Prev_Month | Dim_Date | FullDate | EOMONTH(DATEADD(MONTH,-1,...)) |
| More_than_30Days_ind | Self-join | Balance<0 in Prev_Month | CASE self-join |
| Funded | BI_DB_DDR_CID_Level | Funded_New_Def | LEFT JOIN (buggy) |
| Balance_Group | V_Liabilities | Liabilities+ActualNWA | CASE bucket (buggy) |
| Registration_Last_30_Days | Dim_Customer | RegisteredReal | CASE DATEDIFF <=30 |
| Customers | Aggregation | COUNT(RealCID) | Group count |
| Balance | V_Liabilities | Liabilities+ActualNWA | SUM per group |
| UpdateDate | ETL | GETDATE() | Generated |

### 5.2 ETL Pipeline

```
DWH_dbo.V_Liabilities (customer balance snapshots)
DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer=1)
DWH_dbo.Dim_Date (IsLastDayOfMonth='Y')
DWH_dbo.Dim_Customer (IsDepositor, FirstDepositDate, RegisteredReal)
DWH_dbo.Dim_PlayerLevel + Dim_PlayerStatus + Dim_MifidCategorization + Dim_Regulation
  |-- SP_Negative_Balance_Monitor_Risk @Date ---|
  v
BI_DB_dbo.BI_DB_Negative_Balance_Monitor_Risk (78K rows, aggregated)
  UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| MIFID | DWH_dbo.Dim_MifidCategorization (Name) | MiFID category name |
| Club | DWH_dbo.Dim_PlayerLevel (Name) | Player tier name |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus (Name) | Player status name |
| Regulation | DWH_dbo.Dim_Regulation (Name) | Regulation name |

### 6.2 Referenced By (other objects point to this)

No known consumers. Terminal risk dashboard table.

---

## 7. Sample Queries

### 7.1 Monthly Negative Balance Trend

```sql
SELECT
    FullDate,
    SUM(CASE WHEN Negative_Balance_Ind = 1 THEN Customers ELSE 0 END) AS NegativeBalanceCustomers,
    SUM(Customers) AS TotalCustomers,
    SUM(CASE WHEN Negative_Balance_Ind = 1 THEN Balance ELSE 0 END) AS TotalNegativeBalance
FROM [BI_DB_dbo].[BI_DB_Negative_Balance_Monitor_Risk]
GROUP BY FullDate
ORDER BY FullDate DESC
```

### 7.2 Negative Balance Distribution by Range

```sql
SELECT
    Balance_Group,
    SUM(Customers) AS Customers,
    SUM(Balance) AS TotalBalance
FROM [BI_DB_dbo].[BI_DB_Negative_Balance_Monitor_Risk]
WHERE FullDate = '2026-03-31'
  AND Negative_Balance_Ind = 1
GROUP BY Balance_Group
ORDER BY SUM(Customers) DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search access denied).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 15 T2, 0 T3, 0 T4, 1 T5 | Elements: 16/16, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_Negative_Balance_Monitor_Risk | Type: Table | Production Source: V_Liabilities + Fact_SnapshotCustomer*
