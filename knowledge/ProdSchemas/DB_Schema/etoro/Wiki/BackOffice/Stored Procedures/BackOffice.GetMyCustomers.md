# BackOffice.GetMyCustomers

> Returns a comprehensive financial summary for all customers assigned to specified BackOffice managers, filtered by registration date range and player level - a manager's customer dashboard with FTD, deposits, equity, balance, and cashout metrics.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ManagerIds + @RegisteredFrom + @RegisteredTo + @PlayerLevelIds |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure generates the "My Customers" dashboard for BackOffice account managers. Given a set of manager IDs, a registration date range, and optional player level filter, it returns a single row per customer with all key financial metrics needed for account management: first-time deposit details, last deposit, total deposits, current equity/balance, cashout history, last login, and last trading activity.

The procedure is used when a BackOffice manager (or supervisor overseeing multiple managers) needs a snapshot view of their assigned customers to prioritize outreach, identify inactive depositors, review high-value customers, or track conversion from registration to first deposit.

**Architecture**: Multi-step UPDATE pipeline using global temporary tables (`##BasicInfo`, `##LastDepositsDates`). The base customer population is built first, then each financial dimension is added via sequential UPDATE statements, and finally the fully populated result is returned with SELECT *.

**Permission**: Only VIEW DEFINITION granted to PROD\BIadmins. No active EXECUTE grants - this is likely called directly from a BI tool or used as a template query.

**Note on comment history**: Updated 2021-01-03 by Shay Oren to use `History.HistoryGetUnifiedbyCID` function for Last Open Position (replacing direct `History.Credit` query). The Last Open Position column contains a bug (see Section 2.6).

---

## 2. Business Logic

### 2.1 Base Population Filter

**What**: Determines which customers appear in the report by applying three simultaneous filters.

**Columns/Parameters Involved**: BC.ManagerID, CC.Registered, CC.PlayerLevelID, @ManagerIds, @RegisteredFrom, @RegisteredTo, @PlayerLevelIds

**Rules**:
- `BC.ManagerID IN (SELECT ManagerID FROM @ManagerIds)`: Only customers assigned to the specified BackOffice managers are included. Uses the `BackOffice.Managers` TVP to support multi-manager queries (e.g., a supervisor reviewing their team's customers).
- `CC.Registered BETWEEN @RegisteredFrom AND @RegisteredTo`: Restricts to customers who registered within the given date range.
- `CC.PlayerLevelID IN (SELECT PlayerLevelID FROM @PlayerLevelIds)`: Filters by player level (e.g., Demo, Silver, Gold, Platinum). Uses the `BackOffice.PlayerLevels` TVP. Pass all levels to get the full customer base; filter to specific levels for tier-based analysis.

### 2.2 First-Time Deposit (FTD) Enrichment

**What**: Populates FTD Amount and FTD Date for each customer's first qualifying deposit.

**Columns/Parameters Involved**: Billing.Deposit.IsFTD, Billing.Deposit.Amount, Billing.Deposit.PaymentDate

**Rules**:
- Joins `Billing.Deposit` where `IsFTD = 1`. Each customer has at most one FTD record.
- Customers without an FTD record retain NULL for both FTD Amount and FTD Date - indicating they registered but never completed their first deposit (unqualified registrant).

### 2.3 Last Deposit Enrichment

**What**: Populates Last Deposit Date and Last Deposit Amount using a two-step approach with a secondary temp table.

**Columns/Parameters Involved**: Billing.Deposit.PaymentDate, Billing.Deposit.Amount, Billing.Deposit.PaymentStatusID

**Rules**:
- Only approved deposits are considered: `BD.PaymentStatusID = 2` (Approved).
- Step 1: `##LastDepositsDates` aggregates the MAX(PaymentDate) per CID across all approved deposits.
- Step 2: A CROSS APPLY fetches `TOP 1 *` from `Billing.Deposit` ordered by the max payment date descending, then filters `BD.PaymentDate = LDD.[Last Payment Date]` to match the row. This retrieves the Amount for the most recent deposit.

### 2.4 Account Status Enrichment (Equity, Balance, Last Login)

**What**: Populates current account state from the `Customer.GetCustomerCurrentInfo` view/function.

**Columns/Parameters Involved**: LastLoginDate, Equity, Credit (aliased as Balance)

**Rules**:
- `Customer.GetCustomerCurrentInfo` provides real-time account metrics per CID.
- `Equity` = current total portfolio equity (cast to INT in the temp table definition).
- `Balance` = current available credit/cash balance (sourced from `GCCI.Credit`, cast to INT).
- `Last Login Date` = most recent login timestamp for the customer.

### 2.5 Manager Name Enrichment

**What**: Populates the Manager column with the assigned manager's full name.

**Columns/Parameters Involved**: BackOffice.Customer.ManagerID, BackOffice.Manager.FirstName, BackOffice.Manager.LastName

**Rules**:
- Concatenates `BM.FirstName + ' ' + BM.LastName` from `BackOffice.Manager` via `BackOffice.Customer.ManagerID`.
- If a customer's ManagerID does not match any manager in `BackOffice.Manager`, the Manager column remains NULL.

### 2.6 Last Open Position Enrichment (Bug Present)

**What**: Intended to populate Last Open Position with the timestamp of the most recent credit event per customer.

**Columns/Parameters Involved**: History.HistoryGetUnifiedbyCID (function), Occurred

**Rules**:
- Uses CROSS APPLY with `History.HistoryGetUnifiedbyCID(BI.CID)` to get the max Occurred date across all credit events for each customer.
- **BUG**: The UPDATE JOIN references `HC.CID` which is not defined in this scope (the CTE is named `MaxOccuredList` and the alias is `MaxOccuredList.CID`). The correct join condition should be `ON BI.CID = MaxOccuredList.CID`. As written, this UPDATE will produce an error or silently fail, leaving [Last Open Position] as NULL for all rows.
- Note: The earlier implementation using `History.Credit` directly with `CreditTypeID = 3` (Open position) is commented out - that version was replaced with the HistoryGetUnifiedbyCID function but the refactoring introduced the alias bug.

### 2.7 Total Deposits Enrichment

**What**: Sums all approved deposits per customer.

**Columns/Parameters Involved**: Billing.Deposit.Amount, Billing.Deposit.PaymentStatusID

**Rules**:
- `PaymentStatusID = 2` (Approved) - only completed deposits counted.
- `SUM(ISNULL(BD.Amount, 0))` - NULL amounts treated as 0.

### 2.8 Cashout Metrics Enrichment

**What**: Computes total cashout volume, in-process cashout volume, and last cashout date per customer.

**Columns/Parameters Involved**: Billing.Withdraw.CashoutStatusID, Billing.Withdraw.Amount, Billing.Withdraw.ModificationDate

**Rules**:
- `CashoutStatusID = 3` (Approved): Contributes to Total CO Amount and Last CO Date.
- `CashoutStatusID = 2` (In Process): Contributes to In Process CO Amount - cashouts pending approval.
- `SUM(CASE WHEN ... THEN ISNULL(Amount, 0) ELSE 0 END)`: Conditional aggregation in a single pass over Billing.Withdraw.
- `Last CO Date`: MAX of ModificationDate for approved cashouts only. Uses '1900-01-01' as the NULL sentinel for the MAX - if no approved cashout, Last CO Date will be '1900-01-01' rather than NULL.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ManagerIds | BackOffice.Managers (TVP) | NO | - | CODE-BACKED | Table-valued parameter. One row per ManagerID to include. Allows a supervisor to pull customers across multiple managers simultaneously. |
| 2 | @RegisteredFrom | DATETIME | NO | - | CODE-BACKED | Start of the registration date range filter. Only customers who registered on or after this date are included. |
| 3 | @RegisteredTo | DATETIME | NO | - | CODE-BACKED | End of the registration date range filter. Only customers who registered on or before this date are included. |
| 4 | @PlayerLevelIds | BackOffice.PlayerLevels (TVP) | NO | - | CODE-BACKED | Table-valued parameter. One row per PlayerLevelID to include. Pass all levels to get the full customer base. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer account identifier. Primary key of the result set. |
| 2 | Country | NVARCHAR | YES | - | CODE-BACKED | Customer's registered country name from Dictionary.Country. NULL if no country on record. |
| 3 | Language | NVARCHAR | YES | - | CODE-BACKED | Customer's preferred language from Dictionary.Language. NULL if not set. |
| 4 | Email | NVARCHAR | YES | - | CODE-BACKED | Customer's email address from Customer.Customer. |
| 5 | Phone | NVARCHAR | YES | - | CODE-BACKED | Customer's phone number from Customer.Customer. |
| 6 | Affiliate ID | INT | YES | - | CODE-BACKED | Customer's affiliate/serial identifier (CC.SerialID). Used for affiliate attribution tracking. |
| 7 | FTD Amount | DECIMAL(12,2) | YES | NULL | CODE-BACKED | Amount of the customer's first-time deposit (Billing.Deposit.IsFTD=1). NULL = no FTD recorded (customer never made a qualifying first deposit). |
| 8 | FTD Date | DATETIME | YES | NULL | CODE-BACKED | Date of the customer's first-time deposit. NULL = no FTD. |
| 9 | Last Deposit Amount | DECIMAL(12,2) | YES | NULL | CODE-BACKED | Amount of the most recent approved deposit (PaymentStatusID=2). NULL = no approved deposits. |
| 10 | Last Deposit Date | DATETIME | YES | NULL | CODE-BACKED | Date of the most recent approved deposit. NULL = no approved deposits. |
| 11 | Last Login Date | DATETIME | YES | NULL | CODE-BACKED | Most recent login timestamp from Customer.GetCustomerCurrentInfo. NULL = never logged in or data unavailable. |
| 12 | Last Open Position | DATETIME | YES | NULL | CODE-BACKED | (Currently always NULL due to SQL bug in UPDATE statement - see Section 2.6.) Intended to show the most recent credit event timestamp from History.HistoryGetUnifiedbyCID. |
| 13 | Manager | VARCHAR(50) | YES | NULL | CODE-BACKED | Full name of the customer's assigned BackOffice manager (FirstName + ' ' + LastName). NULL if ManagerID not found in BackOffice.Manager. |
| 14 | Total Deposits | DECIMAL(12,2) | YES | NULL | CODE-BACKED | Sum of all approved deposits (PaymentStatusID=2). NULL if no approved deposits exist. |
| 15 | Equity | INT | YES | NULL | CODE-BACKED | Current portfolio equity from Customer.GetCustomerCurrentInfo. Cast to INT. NULL if not available. |
| 16 | Balance | INT | YES | NULL | CODE-BACKED | Current cash balance (credit) from Customer.GetCustomerCurrentInfo.Credit. Cast to INT. NULL if not available. |
| 17 | Total CO Amount | DECIMAL(12,2) | YES | NULL | CODE-BACKED | Sum of all approved cashouts (CashoutStatusID=3). NULL if no approved cashouts. |
| 18 | Last CO Date | DATETIME | YES | NULL | CODE-BACKED | Date of most recent approved cashout (MAX ModificationDate where CashoutStatusID=3). Returns '1900-01-01' sentinel if no approved cashouts (due to MAX with '1900-01-01' NULL replacement). |
| 19 | In Process CO Amount | DECIMAL(12,2) | YES | NULL | CODE-BACKED | Sum of cashouts currently in-process (CashoutStatusID=2 = In Process). NULL if none pending. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Base population | Customer.Customer | Read (INNER JOIN via BackOffice.Customer) | Core customer attributes: CID, CountryID, LanguageID, Email, Phone, SerialID, Registered, PlayerLevelID |
| Base population | BackOffice.Customer | Read (INNER JOIN) | Provides ManagerID for filtering by @ManagerIds |
| Country | Dictionary.Country | Lookup (LEFT JOIN) | Resolves CountryID to country name |
| Language | Dictionary.Language | Lookup (LEFT JOIN) | Resolves LanguageID to language name |
| FTD | Billing.Deposit | Read (UPDATE JOIN, IsFTD=1) | First-time deposit amount and date |
| Last Deposit | Billing.Deposit | Read (UPDATE JOIN, PaymentStatusID=2) | Most recent approved deposit |
| Total Deposits | Billing.Deposit | Aggregation (UPDATE, PaymentStatusID=2) | Sum of all approved deposits |
| Equity/Balance/Login | Customer.GetCustomerCurrentInfo | Read (UPDATE JOIN) | Current account state view/function |
| Manager name | BackOffice.Manager | Lookup (UPDATE JOIN via BackOffice.Customer) | Manager full name |
| Last Open Position | History.HistoryGetUnifiedbyCID | Read (CROSS APPLY, bug present) | Credit history function for last activity timestamp |
| Cashout metrics | Billing.Withdraw | Aggregation (UPDATE, CashoutStatusID=2/3) | Cashout totals and dates |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active EXECUTE grants found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetMyCustomers (procedure)
+-- Customer.Customer (table)
+-- BackOffice.Customer (table)
+-- Dictionary.Country (table)
+-- Dictionary.Language (table)
+-- Billing.Deposit (table)
+-- Customer.GetCustomerCurrentInfo (view/function)
+-- BackOffice.Manager (table)
+-- History.HistoryGetUnifiedbyCID (function)
+-- Billing.Withdraw (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Base customer data: CID, CountryID, LanguageID, Email, Phone, SerialID, Registered, PlayerLevelID |
| BackOffice.Customer | Table | ManagerID lookup for @ManagerIds filter |
| Dictionary.Country | Table | Country name resolution |
| Dictionary.Language | Table | Language name resolution |
| Billing.Deposit | Table | FTD, Last Deposit, Total Deposits calculations |
| Customer.GetCustomerCurrentInfo | View/Function | Current Equity, Balance, LastLoginDate |
| BackOffice.Manager | Table | Manager full name |
| History.HistoryGetUnifiedbyCID | Function | Credit history for Last Open Position (currently buggy) |
| Billing.Withdraw | Table | Cashout metrics (Total CO, In Process CO, Last CO Date) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | No EXECUTE grants; BI tool or ad-hoc use only |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Global temp table ##BasicInfo | Architecture | PK Clustered on CID added after creation to enable efficient UPDATE JOINs |
| Global temp table ##LastDepositsDates | Architecture | PK Clustered on CID added after creation; intermediary for last-deposit calculation |
| PaymentStatusID = 2 | Business filter | Approved deposits only (for Last Deposit, Total Deposits) |
| CashoutStatusID = 2 | Business filter | In Process cashouts for In Process CO Amount |
| CashoutStatusID = 3 | Business filter | Approved cashouts for Total CO Amount and Last CO Date |
| '1900-01-01' sentinel | NULL handling | Used in ISNULL for MAX() aggregation on dates; produces '1900-01-01' instead of NULL when no rows |
| SQL Bug: Last Open Position | Known defect | HC.CID is undefined in the UPDATE JOIN; should be MaxOccuredList.CID. Last Open Position will always be NULL. |

---

## 8. Sample Queries

### 8.1 Execute for a specific manager's customers (registered in Q1 2024, all player levels)

```sql
-- Declare TVPs
DECLARE @ManagerIds BackOffice.Managers;
INSERT INTO @ManagerIds VALUES (42);

DECLARE @PlayerLevelIds BackOffice.PlayerLevels;
INSERT INTO @PlayerLevelIds VALUES (1), (2), (3), (4), (5);

EXEC BackOffice.GetMyCustomers
    @ManagerIds = @ManagerIds,
    @RegisteredFrom = '2024-01-01',
    @RegisteredTo = '2024-03-31',
    @PlayerLevelIds = @PlayerLevelIds;
```

### 8.2 Find customers without FTD (unqualified registrants)

```sql
-- After running the procedure, filter the result:
-- FTD Date IS NULL means the customer registered but never made a first deposit
-- (Note: procedure must be run first; then filter the ##BasicInfo result)
SELECT CID, Country, Email, [Last Login Date]
FROM ##BasicInfo
WHERE [FTD Date] IS NULL
ORDER BY CID;
```

### 8.3 View the CashoutStatusID lookup values

```sql
SELECT CashoutStatusID, Name
FROM Dictionary.CashoutStatus WITH (NOLOCK)
ORDER BY CashoutStatusID;
-- CashoutStatusID = 2 -> In Process
-- CashoutStatusID = 3 -> Approved
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetMyCustomers | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetMyCustomers.sql*
