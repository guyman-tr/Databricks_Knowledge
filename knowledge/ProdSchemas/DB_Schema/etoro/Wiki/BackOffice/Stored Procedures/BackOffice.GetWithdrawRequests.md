# BackOffice.GetWithdrawRequests

> Returns a filtered, deduplicated list of withdrawal requests from Billing.Withdraw with customer profile, lifetime financials, cashout mode, and MOP validation flags. Uses dynamic SQL with sp_executesql for optional multi-value filter parameters.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate/@EndDate window on ModificationDate; optional @CID, @CashoutStatusIDs, @FundingTypeIDs, @RegulationIDs, @CustomerStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary data source for the Withdraw Requests report in BackOffice - a list view that operations agents use to review, process, and monitor customer withdrawal requests. It is called internally by `GetCashOutRequests` (which wraps it and adds processing-level and approval-history result sets).

Each row represents one withdrawal request from `Billing.Withdraw`, showing the customer's identity, withdrawal status, amounts, cashout mode (how the withdrawal was prepared), which BackOffice manager last prepared it, the customer's current balance and lifetime financials, and MOP (Method of Payment) validation flags.

**Date filter**: Uses `ModificationDate BETWEEN @StartDate AND @EndDate` - this captures records that were last changed (status updated) within the window, not just requests placed in that window. Agents monitoring daily operations use this to find all withdrawals that changed state today.

**Dynamic SQL architecture**: The core query is built as an `NVARCHAR(MAX)` string and executed via `sp_executesql`. This is necessary because optional list-valued parameters (`@CashoutStatusIDs`, `@FundingTypeIDs`, `@RegulationIDs`, `@CustomerStatuses`) must use `IN (...)` clauses that cannot be parameterized with standard `sp_executesql` parameter binding. The @CID value, when provided, is directly concatenated as an integer literal (type-safe; no string injection risk).

**ROW_NUMBER deduplication**: The CTE (`BWIT`) joins `Billing.Withdraw` to `Billing.WithdrawToFunding` (the processing table), which can have multiple rows per WithdrawID. An OUTER APPLY fetches the most recent manager action (CashoutStatusID IN (1, 14)) from `History.WithdrawToFundingAction`. The `ROW_NUMBER() OVER (PARTITION BY WithdrawID ORDER BY ModificationDate DESC)` ensures one row per WithdrawID is returned (`WHERE rn = 1`).

**MOP validation flags** (added Jun 2020, Yaron): `[Report Non Valid MOP]` (ParameterTypeID=5) and `[Proof Of MOP]` (ParameterTypeID=6) were originally two separate LEFT JOINs on `Billing.WithdrawAdditionalParameters`; replaced with a single OUTER APPLY pivot to avoid row multiplication.

**Duplicate column**: `[Withdraw Status]` and `[Status]` are both `DCAS.Name` - the same column aliased twice. Legacy artifact from incremental column additions.

---

## 2. Business Logic

### 2.1 Dynamic SQL Filter Conditions

**What**: Optional filter parameters are dynamically appended to the SQL string.

| Parameter | Condition Added (when not NULL/0) |
|-----------|----------------------------------|
| @CID | `AND BW.CID = {value}` (direct INT concat, type-safe) |
| @CashoutStatusIDs | `AND BWIT.CashoutStatusID IN ({csv})` |
| @FundingTypeIDs | `AND DFUT.FundingTypeID IN ({csv})` |
| @IncludeInternalAccounts=0 | `AND CCST.PlayerLevelID <> 4` (PlayerLevelID=4 = Internal accounts) |
| @RegulationIDs | `AND BCST.RegulationID IN ({csv})` |
| @Approved<>0 | `AND BWIT.Approved = 1` |
| @CustomerStatuses | `AND DPST.PlayerStatusID IN ({csv})` |

### 2.2 Manager Attribution (Prepared By)

**What**: Identifies the BackOffice manager who most recently set the withdrawal to an approved or pending-approval state.

**Rules**:
- OUTER APPLY: `SELECT TOP 1` from `History.WithdrawToFundingAction HWFA` LEFT JOIN `BackOffice.Manager M`
- WHERE `HWFA.BW2F_ID = WTF.ID AND (CashoutStatusID = 1 OR CashoutStatusID = 14)`
- `ORDER BY ModificationDate DESC, CashoutStatusID ASC`
- CashoutStatusID=1: approved; CashoutStatusID=14: likely "Prepared" or "Sent to processor" state
- The manager's `CONCAT(FirstName, ' ', LastName)` is returned as `[Prepared By]`

### 2.3 MOP Validation Pivot

**What**: Pivots two specific parameters from Billing.WithdrawAdditionalParameters into separate columns.

**Rules**:
- `MAX(IIF(ParameterTypeID = 5, ParameterValue, NULL))` AS `[Report Non Valid MOP]` - flag/note about invalid MOP
- `MAX(IIF(ParameterTypeID = 6, ParameterValue, NULL))` AS `[Proof Of MOP]` - evidence of MOP verification
- OUTER APPLY: scoped to the current WithdrawID, ParameterTypeID IN (5, 6) only

### 2.4 Internal Account Exclusion

**Rules**:
- `@IncludeInternalAccounts = 0` adds `AND CCST.PlayerLevelID <> 4`
- PlayerLevelID=4 = Internal/test accounts; excluded from agent-facing reports by default when this flag is 0
- Default parameter value is `@IncludeInternalAccounts BIT = 1` (include internal accounts by default)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of ModificationDate window (inclusive). Used to find withdrawals whose status last changed in this period. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of ModificationDate window (inclusive). |
| 3 | @CID | INT | YES | NULL | CODE-BACKED | When provided, limits results to a single customer. Concatenated as integer literal in dynamic SQL. |
| 4 | @CashoutStatusIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated CashoutStatusIDs to include (e.g., '1,2,3'). NULL = no status filter. |
| 5 | @FundingTypeIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated FundingTypeIDs to include. NULL = all funding types. |
| 6 | @RegulationIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated regulation IDs. NULL = all regulations. |
| 7 | @Approved | BIT | YES | 0 | CODE-BACKED | When 1: adds AND Approved = 1 filter. When 0 (default): all approval states. |
| 8 | @IncludeInternalAccounts | BIT | YES | 1 | CODE-BACKED | When 0: excludes PlayerLevelID=4 (Internal/test) accounts. Default 1 = include all. |
| 9 | @CustomerStatuses | NVARCHAR(250) | NO | - | CODE-BACKED | Comma-separated PlayerStatusIDs. NULL = all customer statuses. (Required parameter - no default value.) |
| **Output Columns** | | | | | | |
| 10 | [CID] | INT | NO | - | CODE-BACKED | Customer ID. From Billing.Withdraw.CID. |
| 11 | [Status Modification Time] | DATETIME | YES | - | CODE-BACKED | Last status change timestamp. From Billing.Withdraw.ModificationDate. Primary sort key. |
| 12 | [Request Time] | DATETIME | YES | - | CODE-BACKED | When the withdrawal was originally requested. From Billing.Withdraw.RequestDate. |
| 13 | [Withdraw Status] | VARCHAR | NO | - | CODE-BACKED | Human-readable cashout status name. From Dictionary.CashoutStatus.Name on CashoutStatusID. |
| 14 | [Approved] | CHAR(3) | NO | - | CODE-BACKED | 'YES' if Billing.Withdraw.Approved=1; else 'NO'. |
| 15 | [3rd Party] | CHAR(3) | NO | - | CODE-BACKED | 'YES' if a BackOffice.CustomerToThirdPartyFundings row exists for this CID; else 'NO'. Correlated EXISTS subquery. |
| 16 | [Net. Cashout Amount] | DECIMAL(16,2) | YES | - | CODE-BACKED | Net withdrawal amount in dollars (after deductions). From Billing.Withdraw.Amount. |
| 17 | [Orig. Cashout Amount] | DECIMAL(16,2) | YES | - | CODE-BACKED | Gross withdrawal amount before fee deduction. Amount + ISNULL(Fee, 0). |
| 18 | [CashoutFee] | DECIMAL(16,2) | YES | - | CODE-BACKED | Fee charged on this withdrawal. From Billing.Withdraw.Fee. |
| 19 | [Account Balance] | DECIMAL(16,2) | YES | - | CODE-BACKED | Current cash account balance. From Customer.CustomerMoney.Credit. |
| 20 | [Funding Method (Request Only)] | VARCHAR | NO | - | CODE-BACKED | Payment method name as recorded at request time. From Dictionary.FundingType.Name on Billing.Withdraw.FundingTypeID. |
| 21 | WithdrawID | INT | NO | - | CODE-BACKED | Withdrawal record identifier. From Billing.Withdraw.WithdrawID. |
| 22 | [Country Reg. Form] | NVARCHAR | YES | - | CODE-BACKED | Country name from the customer's declared country. From Dictionary.Country.Name on Customer.Customer.CountryID. |
| 23 | [Customer Status] | VARCHAR | NO | - | CODE-BACKED | Customer trading status name. From Dictionary.PlayerStatus.Name. LTRIM/RTRIM applied. |
| 24 | [Customer Level] | VARCHAR | NO | - | CODE-BACKED | Customer tier/level name. From Dictionary.PlayerLevel.Name. LTRIM/RTRIM applied. |
| 25 | [Preparation Type] | VARCHAR | YES | - | CODE-BACKED | Cashout processing mode (e.g., 'Manual', 'Automatic'). From Dictionary.CashoutMode.CashoutModeName via WithdrawToFunding. |
| 26 | [Prepared By] | VARCHAR | YES | NULL | CODE-BACKED | Full name of the BackOffice manager who last set the withdrawal to approved/prepared state. Derived from History.WithdrawToFundingAction OUTER APPLY. NULL if no manager record found. |
| 27 | [Currency] | VARCHAR | NO | - | CODE-BACKED | Withdrawal currency. COALESCE(DisplayName, Abbreviation) from Dictionary.Currency on Billing.Withdraw.CurrencyID. |
| 28 | [Total Commissions] | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Lifetime commissions for this customer. ISNULL(BCAD.TotalCommission, 0). From BackOffice.CustomerAllTimeAggregatedData. |
| 29 | [Total Deposits] | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Lifetime total deposits. ISNULL(BCAD.TotalDeposit, 0). |
| 30 | [Total Cashouts] | DECIMAL(16,2) | NO | 0 | CODE-BACKED | Lifetime total cashouts. ISNULL(BCAD.TotalCashout, 0). |
| 31 | [Account Manager] | NVARCHAR(50) | YES | NULL | CODE-BACKED | Full name of the assigned account manager. From BackOffice.Manager via BackOffice.Customer.ManagerID. |
| 32 | [Status] | VARCHAR | NO | - | CODE-BACKED | Duplicate of [Withdraw Status]. Same source: Dictionary.CashoutStatus.Name. Legacy artifact. |
| 33 | CashoutStatusID | INT | NO | - | CODE-BACKED | Numeric cashout status code. From Billing.Withdraw.CashoutStatusID. |
| 34 | [BackOffice Withdraw Reason] | VARCHAR | YES | NULL | CODE-BACKED | BackOffice-assigned reason for the withdrawal outcome. From Dictionary.CashoutReason.Name on Billing.Withdraw.CashoutReasonID. |
| 35 | [Additional Information Type] | VARCHAR(1500) | YES | NULL | CODE-BACKED | Client-facing withdrawal comment category. From Dictionary.ClientWithdrawComment.Comment on Billing.Withdraw.ClientWithdrawCommentID. |
| 36 | [Additional Information Details] | VARCHAR | YES | NULL | CODE-BACKED | Free-text details accompanying the additional information type. From Billing.Withdraw.Remark. |
| 37 | [Report Non Valid MOP] | NVARCHAR(300) | YES | NULL | CODE-BACKED | MOP validation flag/note. From Billing.WithdrawAdditionalParameters where ParameterTypeID=5. |
| 38 | [Proof Of MOP] | NVARCHAR(300) | YES | NULL | CODE-BACKED | Evidence that MOP was verified. From Billing.WithdrawAdditionalParameters where ParameterTypeID=6. |
| 39 | [Internal Comment] | NVARCHAR(500) | YES | NULL | CODE-BACKED | Internal BackOffice comment. From Billing.Withdraw.Comment. |
| 40 | [Third Party Comment] | NVARCHAR(500) | YES | NULL | CODE-BACKED | White-label/third-party manager comment. From BackOffice.Customer.ThirdPartyManagerComment. |
| 41 | [Regulation] | NVARCHAR(50) | YES | NULL | CODE-BACKED | Regulatory jurisdiction name. From Dictionary.Regulation.Name on BackOffice.Customer.RegulationID. |
| 42 | [FundingTypeID (Request Only)] | INT | NO | - | CODE-BACKED | Numeric funding type at request time. From Billing.Withdraw.FundingTypeID. |
| 43 | [FundingID (Request Only)] | INT | YES | - | CODE-BACKED | Funding record ID at request time. From Billing.Withdraw.FundingID. |
| 44 | [AMOP Currency] | VARCHAR | YES | NULL | CODE-BACKED | Alternate/account MOP currency. COALESCE(DisplayName, Abbreviation) from Dictionary.Currency on Billing.Withdraw.AccountCurrencyID. NULL if AccountCurrencyID is NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | Primary Source (CTE) | All withdrawal requests in date window |
| WithdrawID / ID | Billing.WithdrawToFunding | LEFT JOIN (CTE) | Processing record; CashoutMode and manager source |
| BW2F_ID | History.WithdrawToFundingAction | OUTER APPLY (CTE) | Most recent approve/prepare manager action |
| CashoutModeID | Dictionary.CashoutMode | LEFT JOIN (CTE) | Cashout mode name |
| CID | Customer.Customer | JOIN | Customer identity and player level/status |
| CID | BackOffice.Customer | JOIN | Regulation, account manager, ThirdPartyManagerComment |
| CID | BackOffice.CustomerAllTimeAggregatedData | LEFT JOIN | Lifetime deposit/cashout/commission totals |
| ManagerID | BackOffice.Manager | LEFT JOIN x2 | Account manager name; OUTER APPLY manager name |
| CountryID | Dictionary.Country | LEFT JOIN | Country name |
| CurrencyID | Dictionary.Currency | JOIN x2 | Currency display name (request + account currency) |
| FundingTypeID | Dictionary.FundingType | JOIN | Funding method name |
| CashoutStatusID | Dictionary.CashoutStatus | JOIN | Cashout status name |
| PlayerLevelID | Dictionary.PlayerLevel | JOIN | Customer level name |
| PlayerStatusID | Dictionary.PlayerStatus | JOIN | Customer status name |
| RegulationID | Dictionary.Regulation | LEFT JOIN | Regulation name |
| CashoutReasonID | Dictionary.CashoutReason | LEFT JOIN | BO withdraw reason name |
| ClientWithdrawCommentID | Dictionary.ClientWithdrawComment | LEFT JOIN | Additional info type |
| CID | Customer.CustomerMoney | LEFT JOIN | Current account balance |
| CID | BackOffice.CustomerToThirdPartyFundings | Correlated EXISTS | 3rd Party flag check |
| WithdrawID | Billing.WithdrawAdditionalParameters | OUTER APPLY | MOP validation flags (ParameterTypeID 5/6) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCashOutRequests | @StartDate...@CustomerStatuses | EXEC call | Calls this SP; inserts results into #t temp table |
| BackOffice application (BO) | N/A | Application call | Withdraw Requests report (direct call) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawRequests (procedure)
|- Billing.Withdraw (primary)
|- Billing.WithdrawToFunding (processing state + cashout mode)
|- History.WithdrawToFundingAction (manager attribution)
|- Customer.Customer (identity, level, status)
|- BackOffice.Customer (regulation, account manager, comment)
|- BackOffice.CustomerAllTimeAggregatedData (lifetime totals)
|- BackOffice.Manager (manager names x2)
|- BackOffice.CustomerToThirdPartyFundings (3rd party flag)
|- Customer.CustomerMoney (current balance)
|- Billing.WithdrawAdditionalParameters (MOP flags)
|- Dictionary.CashoutMode, CashoutStatus, CashoutReason (lookups)
|- Dictionary.FundingType, Currency x2, Country (lookups)
|- Dictionary.PlayerLevel, PlayerStatus, Regulation (lookups)
+-- Dictionary.ClientWithdrawComment (lookup)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Primary source - withdrawal requests |
| Billing.WithdrawToFunding | Table | Processing state, cashout mode |
| History.WithdrawToFundingAction | Table | Manager attribution for Prepared By |
| Customer.Customer | Table | Customer identity, player level, country |
| BackOffice.Customer | Table | Regulation, account manager FK, ThirdPartyManagerComment |
| BackOffice.CustomerAllTimeAggregatedData | Table | Lifetime financials |
| BackOffice.Manager | Table | Manager full names (x2: account manager + prepared by) |
| BackOffice.CustomerToThirdPartyFundings | Table | 3rd Party flag correlated EXISTS |
| Customer.CustomerMoney | Table | Current account balance |
| Billing.WithdrawAdditionalParameters | Table | MOP validation fields (ParameterTypeID 5, 6) |
| Dictionary.CashoutMode | Table | Cashout mode name |
| Dictionary.CashoutStatus | Table | Status name (displayed twice) |
| Dictionary.FundingType | Table | Payment method name |
| Dictionary.Currency | Table | Currency names (request + account) |
| Dictionary.Country | Table | Country name |
| Dictionary.PlayerLevel | Table | Customer tier name |
| Dictionary.PlayerStatus | Table | Customer status name |
| Dictionary.Regulation | Table | Regulation name |
| Dictionary.CashoutReason | Table | BackOffice withdraw reason |
| Dictionary.ClientWithdrawComment | Table | Additional information type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCashOutRequests | Procedure | Calls this SP via INSERT INTO #t EXEC to get the base withdraw list |
| BackOffice application (BO) | External application | Withdraw Requests report |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`; dynamic SQL via `sp_executesql` for optional IN-clause filters.
- `WITH(NOLOCK)` on all tables in the dynamic query.
- `ORDER BY BWIT.ModificationDate DESC` appended at end of dynamic SQL.
- Integer @CID is directly concatenated into SQL string (type-safe; INT prevents injection).
- @CustomerStatuses has no DEFAULT value - callers must supply it (even NULL); this is a backward compatibility design gap.

---

## 8. Sample Queries

### 8.1 Withdraw requests in a date range

```sql
EXEC BackOffice.GetWithdrawRequests
    @StartDate = '2026-03-01',
    @EndDate = '2026-03-17',
    @CID = NULL,
    @CashoutStatusIDs = NULL,
    @FundingTypeIDs = NULL,
    @RegulationIDs = NULL,
    @Approved = 0,
    @IncludeInternalAccounts = 1,
    @CustomerStatuses = NULL;
```

### 8.2 Single customer all withdrawals

```sql
EXEC BackOffice.GetWithdrawRequests
    @StartDate = '2020-01-01',
    @EndDate = '2026-12-31',
    @CID = 12345678,
    @CashoutStatusIDs = NULL,
    @FundingTypeIDs = NULL,
    @RegulationIDs = NULL,
    @Approved = 0,
    @IncludeInternalAccounts = 1,
    @CustomerStatuses = NULL;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-4354 (inferred from comment) | Jira | Jul 2020 - Added @CustomerStatuses parameter to filter by customer status in the withdraw report. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 35 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawRequests | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdrawRequests.sql*
