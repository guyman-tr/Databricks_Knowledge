# BackOffice.JUNK_PortFolio

> DEPRECATED multi-statement table-valued function returning a single-row manager portfolio summary (deposits, bonuses, commissions, cashouts, customer counts, blocked counts) for a given manager and date range.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Multi-Statement Table-Valued Function (MSTVF) |
| **Key Identifier** | Returns TABLE(@Output) with 11 columns - one row per call |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_PortFolio` is a deprecated portfolio reporting function for BackOffice managers. It aggregates multiple financial and customer metrics for a single manager's book of business over a specified date range, returning a single row summary. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For manager @ManagerID, between @StartDate and @EndDate, what were the total deposits, bonuses, commissions, cashouts, and customer counts (new, active, total, blocked)?" This is a classic sales dashboard summary - everything a manager needs to assess their portfolio performance in one query.

**Who is a BackOffice Manager**: Managers are sales and relationship staff who are assigned customers (`BackOffice.Customer.ManagerID`). They are responsible for their assigned customers' activity. A manager's "portfolio" is the sum of activity across all customers assigned to them.

**Critical design note**: The function uses `History.BackOfficeCustomer` with `ValidFrom`/`ValidTo` to handle the case where customers changed managers during the period. This ensures metrics are attributed to the manager who owned the customer at the time of the transaction, not just the current manager.

**Comment in DDL**: `GRANT SELECT on BackOffice.PortFolio to R_FullRead` - the original non-JUNK version (`BackOffice.PortFolio`) was granted to a read role, suggesting this was a commonly-used reporting function before deprecation.

---

## 2. Business Logic

### 2.1 Manager Assignment Tracking via History.BackOfficeCustomer

**What**: Uses the customer history table to attribute transactions to the correct manager at the time they occurred.

**Columns/Parameters Involved**: `@ManagerID`, `ManagerID`, `ValidFrom`, `ValidTo`, `CID`, `CustomerHistoryID`

**Rules**:
- `History.BackOfficeCustomer` tracks historical manager assignments for each customer.
- Each row has a `ValidFrom`/`ValidTo` range indicating when that manager assignment was active.
- All metric queries JOIN to `History.BackOfficeCustomer HBOC` and filter `HBOC.ManagerID = @ManagerID` AND the transaction date `BETWEEN ValidFrom AND ValidTo`.
- This ensures: if a customer was managed by Manager A in January and Manager B in February, a deposit in January is credited to Manager A, not Manager B.

**Diagram**:
```
Transaction Date (e.g., deposit ModificationDate)
  |
  +-- BETWEEN History.BackOfficeCustomer.ValidFrom AND ValidTo?
  |          AND History.BackOfficeCustomer.ManagerID = @ManagerID?
  |
  YES -> Include in this manager's metrics
  NO  -> Exclude (customer was with different manager at that time)
```

### 2.2 New Customers Calculation (Manager Transfer Detection)

**What**: Counts customers who newly joined a manager's portfolio in the date range (transferred from another manager).

**Columns/Parameters Involved**: `@NewCustomers`, `CustomerHistoryID`, `CID`, `Rank`, `ValidFrom`, `ManagerID`

**Rules**:
- CTE `RNK` assigns `RANK()` to each customer's history records ordered by `CustomerHistoryID`.
- A "new customer" for a manager is one where their Rank-N record shows `ManagerID = @ManagerID` AND the previous record (Rank-N-1) shows a DIFFERENT manager AND `ValidFrom BETWEEN @StartDate AND @EndDate`.
- Self-joins RNK1 (current) with RNK2 (previous): `RNK1.CID = RNK2.CID AND RNK1.Rank = RNK2.Rank + 1 AND RNK1.ManagerID != RNK2.ManagerID`.
- This identifies the moment a customer transferred TO this manager within the date range.

### 2.3 Deposit Calculation (Approved Deposits with Manager Attribution)

**What**: Counts distinct depositing customers and sums deposit amounts for approved deposits attributed to the manager's customers.

**Columns/Parameters Involved**: `@Depositors`, `@TotalDeposit`, `TotalCashChange`, `PaymentStatusID`, `DepositID`, `ModificationDate`

**Rules**:
- Source: `Billing.Deposit` JOIN `History.Credit` (on DepositID, CreditTypeID=1) JOIN `Billing.Funding` JOIN `History.BackOfficeCustomer`.
- Filter: `PaymentStatusID = 2` (approved deposit status).
- Date filter: `ModificationDate BETWEEN @StartDate AND @EndDate AND BETWEEN ValidFrom AND ValidTo`.
- Uses `@FromDepositID`/`@ToDepositID` pre-calculated from Billing.Deposit.ModificationDate range for performance.
- `@Depositors = COUNT(DISTINCT BDEP.CID)`, `@TotalDeposit = SUM(TotalCashChange)`.

### 2.4 Bonus Calculation (Specific BonusTypeIDs Only)

**What**: Sums specific bonus types for the manager's customers during the date range.

**Columns/Parameters Involved**: `@TotalBonus`, `BonusTypeID`, `CreditTypeID`, `Payment`

**Rules**:
- Source: `History.Credit` JOIN `History.BackOfficeCustomer`.
- Filter: `CreditTypeID = 7` (Bonus credit type) AND `BonusTypeID IN (4,5,7,10,23,24,25)`.
- Only specific BonusTypeIDs are included - not all bonuses. The selection criteria for these specific BonusTypeIDs is not documented in the DDL.
- Date filter: `Occurred BETWEEN @StartDate AND @EndDate AND BETWEEN ValidFrom AND ValidTo`.

### 2.5 Active Customers (Deposited OR Traded in Period)

**What**: Counts customers who were active (either deposited or traded) during the period under this manager.

**Columns/Parameters Involved**: `@ActiveCustomers`, `BDEP.PaymentStatusID`, `HPOS.CloseOccurred`

**Rules**:
- Source: `Customer.Customer` JOIN `History.BackOfficeCustomer` JOIN `BackOffice.Customer`.
- Active definition: EXISTS (approved deposit in period for this manager) OR EXISTS (closed position in period).
- The OR logic means either depositing OR trading qualifies as "active".
- Additionally requires the customer exists in `BackOffice.Customer` (has a BackOffice profile).

### 2.6 Blocked Customers (PlayerStatusID Bitmap)

**What**: Counts customers with a restricted/blocked player status.

**Columns/Parameters Involved**: `@Blocked`, `PlayerStatusID`

**Rules**:
- Source: `BackOffice.Customer` JOIN `Customer.Customer`.
- Filter: `ManagerID = @ManagerID` (current assignment, not historical) AND `PlayerStatusID IN (2,4,6,7,8,9)`.
- These PlayerStatusIDs represent various blocked/restricted states. The specific statuses are enumerated in BackOffice.Customer documentation.

---

## 3. Data Overview

N/A for Multi-Statement Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting period. Used as lower bound for all date range filters across deposits, bonuses, commissions, cashouts, and new customer transfers. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of the reporting period (inclusive). Upper bound for all date range filters. |
| 3 | @ManagerID | INT | NO | - | CODE-BACKED | BackOffice Manager ID. Filters all metrics to customers assigned to this manager at the time of each transaction (via History.BackOfficeCustomer ValidFrom/ValidTo). |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TotalDeposit | MONEY | NO | 0 | CODE-BACKED | Sum of TotalCashChange from Billing.Deposit for approved deposits (PaymentStatusID=2) by this manager's customers during the date range. ISNULL-wrapped to 0. |
| 2 | Depositors | INT | NO | 0 | CODE-BACKED | Count of distinct customers (CID) who made at least one approved deposit during the date range while assigned to this manager. |
| 3 | TotalBonus | MONEY | NO | 0 | CODE-BACKED | Sum of Payment from History.Credit WHERE CreditTypeID=7 (Bonus) AND BonusTypeID IN (4,5,7,10,23,24,25) for this manager's customers during the period. Only specific bonus sub-types are included. |
| 4 | TotalCommission | MONEY | NO | 0 | CODE-BACKED | Sum of Commission from History.Position (CommissionOnClose) for positions closed by this manager's customers during the period. Represents eToro revenue from spread/commission on closed trades. |
| 5 | TotalCompensation | MONEY | NO | 0 | CODE-BACKED | Sum of Payment from History.Credit WHERE CreditTypeID=6 (Compensation) for this manager's customers during the period. Represents customer service compensation payouts. |
| 6 | TotalCashout | MONEY | NO | 0 | CODE-BACKED | Sum of Amount from Billing.Withdraw for approved cashouts (Approved=1 AND CashoutStatusID=3) by this manager's customers during the period. |
| 7 | NewCustomers | INT | NO | 0 | CODE-BACKED | Count of customers who transferred TO this manager's portfolio during the date range (previous manager record differs from current). Identified via RANK() on History.BackOfficeCustomer. |
| 8 | ActiveCustomers | INT | NO | 0 | CODE-BACKED | Count of distinct customers who deposited (approved) OR closed a position during the period, AND are assigned to this manager via History.BackOfficeCustomer, AND exist in BackOffice.Customer. |
| 9 | TotalCustomers | INT | NO | 0 | CODE-BACKED | Count of all customers currently assigned to this manager in BackOffice.Customer (current assignment, not time-filtered). |
| 10 | Blocked | INT | NO | 0 | CODE-BACKED | Count of customers currently assigned to this manager (BackOffice.Customer.ManagerID) with a blocked/restricted PlayerStatusID IN (2,4,6,7,8,9). Uses current assignment, not historical. |
| 11 | Manager | VARCHAR(110) | NO | '' | CODE-BACKED | Full name of the manager (FirstName + ' ' + LastName from BackOffice.Manager). Returns empty string if ManagerID not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ManagerID | BackOffice.Manager | Lookup | Retrieves manager full name (FirstName + LastName). |
| @ManagerID, ManagerID | BackOffice.Customer | Lookup | Counts total and blocked customers assigned to this manager. |
| CID, ManagerID, ValidFrom, ValidTo | History.BackOfficeCustomer | Table read | Historical manager assignments - used to attribute transactions to the correct manager at transaction time. |
| DepositID, ModificationDate, PaymentStatusID, TotalCashChange | Billing.Deposit | Table read | Source of deposit amounts and approval status. |
| DepositID, CreditTypeID | History.Credit | Table read | Used to confirm deposit credits (CreditTypeID=1) and bonus credits (CreditTypeID 6,7). |
| FundingID | Billing.Funding | Table read | Joined to Billing.Deposit for funding method context. |
| CID, Commission | History.Position | Table read | Source of commission on closed positions. |
| CID, InitDateTime, AmountInUnitsDecimal | Customer.Customer | Table read | Used for ActiveCustomers query to join customer existence. |
| CID, Amount, Approved, CashoutStatusID, ModificationDate | Billing.Withdraw | Table read | Source of cashout amounts. Filter: Approved=1, CashoutStatusID=3. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_PortFolio (function)
+-- BackOffice.Manager (table)
+-- BackOffice.Customer (table)
+-- History.BackOfficeCustomer (table) [cross-schema]
+-- Billing.Deposit (table) [cross-schema]
+-- History.Credit (table) [cross-schema]
+-- Billing.Funding (table) [cross-schema]
+-- History.Position (table) [cross-schema]
+-- Customer.Customer (table) [cross-schema]
+-- Billing.Withdraw (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | Manager name lookup (FirstName + LastName). |
| BackOffice.Customer | Table | Total and blocked customer counts for the manager. |
| History.BackOfficeCustomer | Table | Historical manager-customer assignments with ValidFrom/ValidTo for time-aware attribution. |
| Billing.Deposit | Table | Deposit amounts and approval status (PaymentStatusID=2). |
| History.Credit | Table | Deposit confirmation (CreditTypeID=1) and bonus (CreditTypeID=6,7) amounts. |
| Billing.Funding | Table | Joined to Billing.Deposit; funding method information. |
| History.Position | Table | Commission on closed positions (CommissionOnClose). |
| Customer.Customer | Table | Active customer existence check. |
| Billing.Withdraw | Table | Cashout amounts (Approved=1, CashoutStatusID=3). |

### 6.2 Objects That Depend On This

No dependents. JUNK-prefixed and deprecated.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Multi-Statement Table-Valued Function.

### 7.2 Constraints

N/A for Multi-Statement Table-Valued Function. JUNK_ prefix = deprecated. Uses WITH (NOLOCK) on all source tables. All output columns ISNULL-wrapped to 0 or ''. Performance may be poor for large date ranges due to multiple sequential aggregation queries without set-based parallelism. Uses a DepositID range pre-filter (@FromDepositID, @ToDepositID) from Billing.Deposit.ModificationDate as a performance optimization for the deposit query.

---

## 8. Sample Queries

### 8.1 Get manager portfolio summary for a specific month

```sql
SELECT
    TotalDeposit, Depositors, TotalBonus, TotalCommission,
    TotalCompensation, TotalCashout, NewCustomers,
    ActiveCustomers, TotalCustomers, Blocked, Manager
FROM BackOffice.JUNK_PortFolio('2023-01-01', '2023-01-31', 42);
```

### 8.2 Compare portfolio metrics across managers for a quarter

```sql
SELECT
    p.Manager,
    p.TotalDeposit,
    p.Depositors,
    p.TotalCommission,
    p.ActiveCustomers,
    p.TotalCustomers,
    p.Blocked
FROM BackOffice.Manager m WITH (NOLOCK)
CROSS APPLY BackOffice.JUNK_PortFolio('2023-01-01', '2023-03-31', m.ManagerID) p
ORDER BY p.TotalDeposit DESC;
```

### 8.3 Manager conversion rate (depositors vs total customers)

```sql
SELECT
    Manager,
    TotalCustomers,
    Depositors,
    CAST(Depositors AS FLOAT) / NULLIF(TotalCustomers, 0) * 100.0 AS DepositConversionPct
FROM BackOffice.JUNK_PortFolio('2023-01-01', '2023-12-31', 42);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_PortFolio | Type: Multi-Statement TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_PortFolio.sql*
