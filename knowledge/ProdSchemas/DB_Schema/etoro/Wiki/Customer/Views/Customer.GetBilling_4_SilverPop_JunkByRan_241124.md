# Customer.GetBilling_4_SilverPop_JunkByRan_241124

> DEPRECATED (marked JUNK by Ran, Nov 2024): Legacy SilverPop email marketing feed that exposed per-customer deposit summary (last deposit date, amount, total, and count) for real depositing customers.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | GCID / CID from Customer.Customer |
| **Partition** | N/A |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Customer.GetBilling_4_SilverPop_JunkByRan_241124 was a data feed view for the SilverPop (now IBM Watson Campaign Automation) email marketing platform. It provided a deposit summary per customer, containing the most recent deposit date and amount, total lifetime deposit value, and total deposit count - all in USD using exchange-rate-converted amounts. Only customers who had completed at least one deposit (PaymentStatusID=2) appeared in this view.

The view existed to drive deposit-milestone email campaigns in SilverPop: welcome-back emails after first deposit, re-engagement campaigns for customers who had not deposited recently, and tiered promotional outreach based on total deposit volume.

This view was marked as JUNK by Ran on 2024-11-24 and is no longer deployed. SilverPop was retired from eToro's marketing stack and replaced by a different CRM platform. No stored procedures or downstream consumers reference this view.

---

## 2. Business Logic

### 2.1 GCID/CID Identity Masking

**What**: When a customer has a GCID (group cross-product identity), the CID field is zeroed out and the GCID is used as the primary identifier.

**Columns/Parameters Involved**: `GCID`, `CID`

**Rules**:
- If `CCST.GCID <> 0` (customer has a GCID): output `CID = 0`, output `GCID = GCID` - the GCID is the preferred identity key
- If `CCST.GCID = 0` (customer predates GCID introduction or not yet assigned): output `CID = CCST.CID` as the fallback identifier
- `DemoCID` is always hardcoded to `0` - this view only produces real customer rows (confirmed by INNER JOIN on Billing.Deposit)

```
GCID assigned: GCID=1234567, CID=0      -> use GCID as key
No GCID:       GCID=0,       CID=999888 -> use CID as key
```

### 2.2 Latest Deposit Window Function Logic

**What**: Returns exactly one row per customer with their most recent completed deposit plus aggregate totals across all completed deposits.

**Columns/Parameters Involved**: `LastDepositDateReal`, `LastDepositAmountReal`, `TotalDepositReal`, `NumberOfDepositsReal`

**Rules**:
- `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY PaymentDate DESC) AS RowNum` selects the most recent deposit
- `SUM(Amount*ExchangeRate) OVER (PARTITION BY CID)` accumulates total deposit value across all completed deposits for that customer
- `COUNT(*) OVER (PARTITION BY CID)` counts total completed deposits
- Outer `WHERE RowNum=1` collapses to one row per customer while retaining the window-calculated totals
- Amounts are in USD: `Amount * ExchangeRate` converts non-USD deposits to USD equivalent
- Filter `PaymentStatusID=2` restricts to completed/successful deposits only (excludes pending, failed, reversed)

```
Customer CID=500:
  Deposit 1: 2020-01-15, $500
  Deposit 2: 2021-06-01, $1,000
  Deposit 3: 2023-03-10, $250  <- RowNum=1 (latest)

Output row: LastDepositDate=2023-03-10, LastAmount=$250, Total=$1750, Count=3
```

---

## 3. Data Overview

View is not deployed to the current environment (Invalid object name error on SELECT). The view was dropped when SilverPop was decommissioned. Rows would have represented real depositing customers with their deposit summary as described above.

| GCID | CID | DemoCID | LastDepositDateReal | LastDepositAmountReal | TotalDepositReal | NumberOfDepositsReal | Meaning |
|------|-----|---------|--------------------|-----------------------|-----------------|----------------------|---------|
| (example) | 0 | 0 | 2023-03-10 | 250.00 | 1750.00 | 3 | Real customer with GCID: 3 completed deposits, last was $250, lifetime deposits $1,750. CID masked to 0 since GCID present. |
| 0 | (example) | 0 | 2021-08-22 | 100.00 | 100.00 | 1 | Pre-GCID customer: only 1 completed deposit of $100. CID exposed since GCID=0. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | VERIFIED | Group Customer ID - cross-product identity key. From Customer.Customer.GCID. Exposed as-is; when GCID != 0 this is the primary row identifier. NULL for accounts predating GCID introduction. |
| 2 | CID | int | NO | - | VERIFIED | Platform-internal customer ID. Derived: `CASE WHEN CCST.GCID <> 0 THEN 0 ELSE CCST.CID END`. Zero when the customer has a GCID (GCID is then the identifier); actual CID when GCID=0. |
| 3 | DemoCID | int | NO | - | CODE-BACKED | Hardcoded constant 0 for all rows. Reserved field from the SilverPop schema contract that distinguished real vs demo accounts. Always 0 here because this view is scoped to real depositors only (via INNER JOIN to Billing.Deposit). |
| 4 | LastDepositDateReal | varchar(50) | YES | - | CODE-BACKED | Date of the customer's most recent completed deposit, formatted as MM/DD/YYYY (via CONVERT(varchar(50), PaymentDate, 101)). From Billing.Deposit.PaymentDate, filtered to PaymentStatusID=2, ordered DESC - RowNum=1 selects latest. String format was required by the SilverPop import format. |
| 5 | LastDepositAmountReal | decimal(25,2) | YES | - | CODE-BACKED | USD-equivalent amount of the customer's most recent completed deposit. Computed: `Amount * ExchangeRate` from Billing.Deposit, rounded to 2 decimal places. ExchangeRate converts non-USD deposits to USD. |
| 6 | TotalDepositReal | decimal(25,2) | YES | - | CODE-BACKED | Total lifetime USD-equivalent deposit amount across ALL completed deposits (PaymentStatusID=2) for this customer. Computed via `SUM(Amount*ExchangeRate) OVER (PARTITION BY CID)` across all qualifying Billing.Deposit rows for the customer. |
| 7 | NumberOfDepositsReal | int | YES | - | CODE-BACKED | Total count of completed deposits for this customer. Computed via `COUNT(*) OVER (PARTITION BY CID)` across all Billing.Deposit rows with PaymentStatusID=2. Minimum value is 1 (because INNER JOIN requires at least 1 deposit to appear). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.Customer | FROM (CCST alias) | Source of customer identity fields: GCID, CID |
| - | Billing.Deposit | INNER JOIN via subquery on CID | Source of deposit data; PaymentStatusID=2 filter applied; window functions compute latest + totals per customer |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this view. It was a terminal data feed object used directly by an external ETL/import process for SilverPop. Now deprecated and not deployed.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBilling_4_SilverPop_JunkByRan_241124 (view) [DEPRECATED]
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── Billing.Deposit (table) [cross-schema]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM with alias CCST; provides GCID, CID for identity output |
| Billing.Deposit | Table (cross-schema) | Subquery: filtered to PaymentStatusID=2; window functions compute latest deposit date/amount and aggregate totals per CID |

### 6.2 Objects That Depend On This

No dependents found. View is deprecated and not deployed.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. See Customer.Customer (base) and Billing.Deposit (cross-schema) for index details.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | View is not schema-bound. |
| INNER JOIN filter | Implicit | Only customers with at least one row in Billing.Deposit WHERE PaymentStatusID=2 appear. Customers with zero completed deposits are excluded entirely. |

---

## 8. Sample Queries

### 8.1 Find all real customers with their deposit summary (historical DDL reference)
```sql
-- View is not currently deployed. This is the equivalent inline query:
SELECT
    CCST.GCID,
    CASE WHEN CCST.GCID <> 0 THEN 0 ELSE CCST.CID END AS CID,
    0 AS DemoCID,
    CONVERT(varchar(50), d.PaymentDate, 101) AS LastDepositDateReal,
    CONVERT(decimal(25,2), d.Amount * d.ExchangeRate) AS LastDepositAmountReal,
    CONVERT(decimal(25,2), d.TotalDepositReal) AS TotalDepositReal,
    d.NumOfDepositReal AS NumberOfDepositsReal
FROM Customer.Customer CCST WITH (NOLOCK)
INNER JOIN (
    SELECT
        CID,
        PaymentDate,
        Amount * ExchangeRate AS LastDepositAmountReal,
        ROW_NUMBER() OVER (PARTITION BY CID ORDER BY PaymentDate DESC) AS RowNum,
        SUM(Amount * ExchangeRate) OVER (PARTITION BY CID) AS TotalDepositReal,
        COUNT(*) OVER (PARTITION BY CID) AS NumOfDepositReal
    FROM Billing.Deposit WITH (NOLOCK)
    WHERE PaymentStatusID = 2
) d ON d.CID = CCST.CID
WHERE d.RowNum = 1;
```

### 8.2 Check top depositing customers (using base tables directly)
```sql
SELECT TOP 20
    c.GCID,
    c.CID,
    SUM(d.Amount * d.ExchangeRate) AS TotalDepositUSD,
    COUNT(*) AS DepositCount,
    MAX(d.PaymentDate) AS LastDepositDate
FROM Customer.Customer c WITH (NOLOCK)
INNER JOIN Billing.Deposit d WITH (NOLOCK)
    ON d.CID = c.CID
WHERE d.PaymentStatusID = 2
GROUP BY c.GCID, c.CID
ORDER BY TotalDepositUSD DESC;
```

### 8.3 Find single-deposit customers (first-time depositors only)
```sql
SELECT
    c.GCID,
    c.CID,
    d.PaymentDate AS FirstDepositDate,
    d.Amount * d.ExchangeRate AS DepositAmountUSD
FROM Customer.Customer c WITH (NOLOCK)
INNER JOIN Billing.Deposit d WITH (NOLOCK)
    ON d.CID = c.CID
WHERE d.PaymentStatusID = 2
  AND NOT EXISTS (
    SELECT 1 FROM Billing.Deposit d2 WITH (NOLOCK)
    WHERE d2.CID = c.CID AND d2.PaymentStatusID = 2 AND d2.DepositID <> d.DepositID
  );
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view, no consumers) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetBilling_4_SilverPop_JunkByRan_241124 | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetBilling_4_SilverPop_JunkByRan_241124.sql*
