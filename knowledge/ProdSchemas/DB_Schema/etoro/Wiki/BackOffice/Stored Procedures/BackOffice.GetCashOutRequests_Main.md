# BackOffice.GetCashOutRequests_Main

> Returns the withdrawal (cashout) request management grid for BackOffice - a comprehensive multi-join query built via dynamic SQL, showing each withdrawal with customer details, status history, financial aggregates, and the most recent pending/review action's manager.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate/@EndDate (modification date window); optional @CID, @CashoutStatusIDs, @FundingTypeIDs, @RegulationIDs, @CustomerStatuses filters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetCashOutRequests_Main` is the primary withdrawal management screen query in BackOffice. It returns a list of withdrawal requests modified within a date range, enriched with full customer context, financial aggregates, status breakdowns, and the manager who most recently put the withdrawal into Pending (status 1) or Under Review (status 14).

This procedure was split from `GetCashOutRequests` in April 2021 (Ran Sh) to separate concerns: _Main handles the primary listing query, while the original may handle secondary lookups. The split improved performance and maintainability for the high-traffic withdrawal management screen.

**Dynamic SQL design**: The core query is built as a string and executed via `sp_executesql`. This allows optional WHERE conditions for CID, CashoutStatusIDs, FundingTypeIDs, RegulationIDs, CustomerStatuses, and Approved to be appended dynamically - avoiding parameter sniffing issues and keeping the base query plan simple when filters are absent.

**AGGR CTE + RANK logic**: The procedure identifies the most recent Pending/Under Review action on each WithdrawToFunding record via `History.WithdrawToFundingAction`. The RANK() partitioned by WithdrawID, ordered by ModificationDate DESC selects only the latest such action, whose ManagerID becomes the "Prepared By" manager shown in the UI.

**WTF aggregations (CROSS APPLY)**: For each withdrawal, a CROSS APPLY computes counts of associated WithdrawToFunding records by status (Total, Pending, Canceled, Rejected) and the FoundedAmount (sum of amounts excluding inactive statuses 1=Pending, 7=Rejected, 4=Canceled).

---

## 2. Business Logic

### 2.1 Dynamic SQL for Optional Filters

**What**: Core query is built as NVARCHAR(MAX) and executed via sp_executesql with named parameters.

**Columns/Parameters Involved**: `@CashoutStatusIDs`, `@FundingTypeIDs`, `@RegulationIDs`, `@CustomerStatuses`, `@Approved`, `@CID`, `@IncludeInternalAccounts`

**Rules**:
- @CID: If not null, appends `AND BW.CID = @CID` to the BWIT CTE.
- @CashoutStatusIDs: NVARCHAR(250) - raw SQL injection into `CashoutStatusID IN (...)`. **Caller must validate.**
- @FundingTypeIDs: Same pattern - `DFUT.FundingTypeID IN (...)`.
- @RegulationIDs: `BCST.RegulationID IN (...)`.
- @CustomerStatuses: `DPST.PlayerStatusID IN (...)`.
- @Approved=1: Appends `AND BWIT.Approved = 1`.
- @IncludeInternalAccounts=0: Appends `AND CCST.PlayerLevelID <> 4` (excludes internal/test accounts, PlayerLevelID=4).
- Final ORDER BY: Always `BWIT.ModificationDate DESC`.

### 2.2 BWIT CTE (Base Withdraw + WTF Aggregation)

**What**: Combines Billing.Withdraw with its WithdrawToFunding records and computes per-withdraw status counts.

**Columns/Parameters Involved**: BWIT CTE, `CROSS APPLY Aggr1`

**Rules**:
- Date filter: `BW.ModificationDate BETWEEN @StartDate AND @EndDate`.
- LEFT JOIN WithdrawToFunding (WTF) - a withdrawal may have zero or multiple WTF records (one per partial processing attempt).
- CROSS APPLY computes: cnt (total WTF rows), Pending (status=1), Canceled (status=4), Rejected (status=7), FoundedAmount (sum of Amount where CashoutStatusID NOT IN (1,7,4)).
- CashoutMode from Dictionary.CashoutMode via WTF.CashoutModeID.
- WTF_ManagerName from BackOffice.Manager via WTF.ManagerID.

### 2.3 AGGR CTE (Most Recent Pending/Review Action)

**What**: Identifies the manager who most recently set a WTF record to Pending or Under Review.

**Columns/Parameters Involved**: AGGR CTE, `History.WithdrawToFundingAction.CashoutStatusID IN (1,14)`

**Rules**:
- Joins BWIT to History.WithdrawToFundingAction (HWFA) on BW2F_ID (WithdrawToFunding ID).
- Only considers history records with CashoutStatusID IN (1=Pending, 14=Under Review).
- RANK() OVER PARTITION BY HWFA.WithdrawID ORDER BY ModificationDate DESC, BW2F_ID DESC, CashoutStatusID ASC - selects the most recent Pending/Review action.
- Final WHERE: `ISNULL(AGGR.r, 1) = 1` - r=1 is rank 1 (most recent); r=NULL means no history, keep the row.
- Prepared By = `ISNULL(AGGR.ManagerID, BWIT.ManagerID)` - prefers the history action's manager, falls back to the withdraw's own ManagerID.

### 2.4 WithdrawAdditionalParameters (OUTER APPLY)

**What**: Retrieves per-withdrawal metadata for specific parameter types.

**Columns/Parameters Involved**: `Billing.WithdrawAdditionalParameters.ParameterTypeID`, WAP columns

**Rules**:
- ParameterTypeID=2 -> [Intermediary Bank Details] (wire transfer bank routing info)
- ParameterTypeID=5 -> [Report Non Valid MOP] (method of payment validity flag)
- ParameterTypeID=6 -> [Proof Of MOP] (proof of payment method document reference)
- MAX(IIF) aggregation - returns NULL if the parameter type is absent for this withdraw.

### 2.5 WithdrawType + Flow Description

**What**: The most recent addition (Dec 2024) appended withdraw type and flow description to the output.

**Columns/Parameters Involved**: `Billing.Withdraw.WithdrawTypeID`, `Billing.Withdraw.FlowID`, `Dictionary.WithdrawType.Description`, `Dictionary.Flow.Description`

**Rules**:
- If FlowID is not null AND Flow description is not empty: CONCAT(WithdrawType.Description, ' - ', Flow.Description) as WithdrawalType.
- Otherwise: WithdrawType.Description alone.
- ExTransactionID: External transaction identifier for reconciliation.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of modification date window. Filters Billing.Withdraw.ModificationDate >= @StartDate. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of modification date window. Filters ModificationDate <= @EndDate. |
| 3 | @CID | INT | YES | NULL | CODE-BACKED | Optional customer filter. When provided, restricts to one customer's withdrawals. |
| 4 | @CashoutStatusIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated CashoutStatusIDs for IN() filter. 17 possible values (1=Pending through 17=Partially Reversed). |
| 5 | @FundingTypeIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated FundingTypeIDs for IN() filter. |
| 6 | @RegulationIDs | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated RegulationIDs for IN() filter. |
| 7 | @Approved | BIT | NO | 0 | CODE-BACKED | When 1, filters to approved withdrawals only (Billing.Withdraw.Approved=1). |
| 8 | @IncludeInternalAccounts | BIT | NO | 1 | CODE-BACKED | When 0, excludes internal/test accounts (PlayerLevelID=4). 1=include all levels. |
| 9 | @CustomerStatuses | NVARCHAR(250) | YES | NULL | CODE-BACKED | Comma-separated PlayerStatusIDs for IN() filter. |
| 10 | CID | INT | NO | - | CODE-BACKED | Customer identifier for this withdrawal. |
| 11 | Status Modification Time | DATETIME | NO | - | CODE-BACKED | Last modification date of the withdrawal (Billing.Withdraw.ModificationDate). |
| 12 | Request Time | DATETIME | NO | - | CODE-BACKED | Date the withdrawal was requested (Billing.Withdraw.RequestDate). |
| 13 | Withdraw Status | NVARCHAR | NO | - | CODE-BACKED | Current status name (Dictionary.CashoutStatus.Name). Repeated as both "Withdraw Status" and "Status" columns. |
| 14 | Approved | VARCHAR | NO | - | CODE-BACKED | 'YES'/'NO' based on Billing.Withdraw.Approved BIT. |
| 15 | 3rd Party | VARCHAR | NO | - | CODE-BACKED | 'YES' if customer has any BackOffice.CustomerToThirdPartyFundings record; 'NO' otherwise. |
| 16 | Net. Cashout Amount | DECIMAL(16,2) | NO | - | CODE-BACKED | Withdrawal amount (Billing.Withdraw.Amount). |
| 17 | Orig. Cashout Amount | DECIMAL(16,2) | NO | - | CODE-BACKED | Withdrawal amount + fee (Amount + Fee). |
| 18 | CashoutFee | DECIMAL(16,2) | YES | - | CODE-BACKED | Fee charged for the withdrawal (Billing.Withdraw.Fee). |
| 19 | Account Balance | DECIMAL(16,2) | YES | - | CODE-BACKED | Current account balance from Customer.CustomerMoney.Credit. |
| 20 | Funding Method (Request Only) | NVARCHAR | NO | - | CODE-BACKED | Funding type name at time of request (Dictionary.FundingType.Name). |
| 21 | WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal. |
| 22 | Country by Reg. Form | NVARCHAR | YES | - | CODE-BACKED | Country from registration form (Dictionary.Country.Name). |
| 23 | Customer Status | NVARCHAR | YES | - | CODE-BACKED | Current player status (Dictionary.PlayerStatus.Name, LTRIM/RTRIM). |
| 24 | Customer Level | NVARCHAR | YES | - | CODE-BACKED | Player level (Dictionary.PlayerLevel.Name, LTRIM/RTRIM). |
| 25 | Preparation Type | NVARCHAR | YES | - | CODE-BACKED | Cashout mode name (Dictionary.CashoutMode.CashoutModeName) from WTF record. |
| 26 | Prepared By | NVARCHAR | YES | - | CODE-BACKED | Full name of manager who most recently set status to Pending(1) or Under Review(14). Falls back to withdraw's own ManagerID if no history. |
| 27 | Currency | NVARCHAR | YES | - | CODE-BACKED | Withdrawal currency. COALESCE(DisplayName, Abbreviation) from Dictionary.Currency. |
| 28 | Total Commissions | DECIMAL(16,2) | NO | - | CODE-BACKED | Lifetime commissions from BackOffice.CustomerAllTimeAggregatedData. |
| 29 | Total Deposits | DECIMAL(16,2) | NO | - | CODE-BACKED | Lifetime deposits from BackOffice.CustomerAllTimeAggregatedData. |
| 30 | Total Cashouts | DECIMAL(16,2) | NO | - | CODE-BACKED | Lifetime cashouts from BackOffice.CustomerAllTimeAggregatedData. |
| 31 | Account Manager | NVARCHAR | YES | - | CODE-BACKED | Full name of the assigned BackOffice manager (BackOffice.Customer.ManagerID -> BackOffice.Manager). |
| 32 | Status | NVARCHAR | NO | - | CODE-BACKED | Duplicate of Withdraw Status (same Dictionary.CashoutStatus.Name). |
| 33 | CashoutStatusID | INT | NO | - | CODE-BACKED | Numeric cashout status for programmatic use. |
| 34 | BackOffice Withdraw Reason | NVARCHAR | YES | - | CODE-BACKED | Internal withdrawal reason (Dictionary.CashoutReason.Name). |
| 35 | Intermediary Bank Details | NVARCHAR | YES | - | CODE-BACKED | Wire transfer intermediary bank details from WithdrawAdditionalParameters (ParameterTypeID=2). |
| 36 | Additional Information Details | NVARCHAR | YES | - | CODE-BACKED | Billing.Withdraw.Remark free text. |
| 37 | Report Non Valid MOP | NVARCHAR | YES | - | CODE-BACKED | Invalid method of payment flag from WithdrawAdditionalParameters (ParameterTypeID=5). |
| 38 | Proof Of MOP | NVARCHAR | YES | - | CODE-BACKED | Proof of method of payment reference from WithdrawAdditionalParameters (ParameterTypeID=6). |
| 39 | Internal Comment | NVARCHAR | YES | - | CODE-BACKED | Internal BackOffice comment (Billing.Withdraw.Comment). |
| 40 | Third Party Comment | NVARCHAR | YES | - | CODE-BACKED | Third-party manager comment (BackOffice.Customer.ThirdPartyManagerComment). |
| 41 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Regulatory jurisdiction (Dictionary.Regulation.Name via BackOffice.Customer.RegulationID). |
| 42 | FundingTypeID (Request Only) | INT | NO | - | CODE-BACKED | Numeric funding type at request time. |
| 43 | FundingID (Request Only) | INT | YES | - | CODE-BACKED | Funding source ID at request time. |
| 44 | AMOP Currency | NVARCHAR | YES | - | CODE-BACKED | AMOP currency COALESCE(DisplayName, Abbreviation) from AccountCurrencyID. |
| 45 | Total | INT | NO | - | CODE-BACKED | Total count of WTF records for this withdrawal. |
| 46 | FoundedAmount | MONEY | NO | - | CODE-BACKED | Sum of WTF amounts excluding Pending(1)/Rejected(7)/Canceled(4). |
| 47 | Pending | INT | NO | - | CODE-BACKED | Count of WTF records with CashoutStatusID=1. |
| 48 | Canceled | INT | NO | - | CODE-BACKED | Count of WTF records with CashoutStatusID=4. |
| 49 | Rejected | INT | NO | - | CODE-BACKED | Count of WTF records with CashoutStatusID=7. |
| 50 | WithdrawTypeID | INT | YES | - | CODE-BACKED | Withdraw type identifier (Billing.Withdraw.WithdrawTypeID). FK to Dictionary.WithdrawType. Added Dec 2024 (MIMOPSA-14499). |
| 51 | ExTransactionID | NVARCHAR | YES | - | CODE-BACKED | External transaction ID for reconciliation (Billing.Withdraw.ExTransactionID). Added Dec 2024 (MIMOPSA-14499). |
| 52 | WithdrawalType | NVARCHAR | YES | - | CODE-BACKED | Concatenated description: if FlowID present, CONCAT(WithdrawType.Description, ' - ', Flow.Description); else WithdrawType.Description alone. |
| 53 | FlowID | INT | YES | - | CODE-BACKED | Flow identifier from Billing.Withdraw.FlowID. FK to Dictionary.Flow. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate/@EndDate | Billing.Withdraw | Primary source (CTE BWIT) | Withdrawal records in modification date window. |
| WithdrawID | Billing.WithdrawToFunding | Aggregation (CROSS APPLY) + LEFT JOIN | WTF records per withdrawal; status counts; CashoutMode; manager. |
| WithdrawID | History.WithdrawToFundingAction | AGGR CTE (most recent Pending/Review) | Most recent action per WTF for Prepared By manager. |
| ManagerID | BackOffice.Manager | Lookup (multiple LEFT JOINs) | WTF manager, Prepared By manager, Account Manager. |
| CID | Customer.Customer | INNER JOIN | Customer details: name, status, level, country. |
| CID | BackOffice.Customer | INNER JOIN | ThirdPartyManagerComment, RegulationID, ManagerID. |
| PlayerLevelID | Dictionary.PlayerLevel | INNER JOIN | Customer level label. |
| PlayerStatusID | Dictionary.PlayerStatus | INNER JOIN | Customer status label. |
| CountryID | Dictionary.Country | LEFT JOIN | Registration country. |
| CurrencyID | Dictionary.Currency | INNER JOIN (x2) | Withdrawal currency + AMOP currency labels. |
| FundingTypeID | Dictionary.FundingType | INNER JOIN | Funding method name. |
| CashoutStatusID | Dictionary.CashoutStatus | INNER JOIN | Status name (x2: Withdraw Status and Status). |
| CID | BackOffice.CustomerAllTimeAggregatedData | LEFT JOIN | Lifetime financial aggregates. |
| RegulationID | Dictionary.Regulation | LEFT JOIN | Regulation name. |
| CashoutReasonID | Dictionary.CashoutReason | LEFT JOIN | BO withdraw reason. |
| CID | Customer.CustomerMoney | LEFT JOIN | Current account balance. |
| CID | BackOffice.CustomerToThirdPartyFundings | EXISTS check | 3rd Party flag. |
| WithdrawID | Billing.WithdrawAdditionalParameters | OUTER APPLY | Intermediary bank, Report Non Valid MOP, Proof of MOP parameters. |
| WithdrawTypeID | Dictionary.WithdrawType | LEFT JOIN | Withdrawal type description. |
| FlowID | Dictionary.Flow | LEFT JOIN | Flow description for WithdrawalType concatenation. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by BackOffice cashout management screen. No SQL procedure callers found in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCashOutRequests_Main (procedure)
├── Billing.Withdraw (table) [cross-schema - CTE BWIT base]
├── Billing.WithdrawToFunding (table) [cross-schema - CROSS APPLY Aggr1 + LEFT JOIN]
├── History.WithdrawToFundingAction (table) [cross-schema - AGGR CTE]
├── Dictionary.CashoutMode (table) [cross-schema]
├── BackOffice.Manager (table) [multiple uses]
├── Customer.Customer (table) [cross-schema]
├── BackOffice.Customer (table)
├── Dictionary.PlayerLevel (table) [cross-schema]
├── Dictionary.PlayerStatus (table) [cross-schema]
├── Dictionary.Country (table) [cross-schema]
├── Dictionary.Currency (table) [cross-schema, x2]
├── Dictionary.FundingType (table) [cross-schema]
├── Dictionary.CashoutStatus (table) [cross-schema]
├── BackOffice.CustomerAllTimeAggregatedData (view)
├── Dictionary.Regulation (table) [cross-schema]
├── Dictionary.CashoutReason (table) [cross-schema]
├── Dictionary.ClientWithdrawComment (table) [cross-schema, present but unused in SELECT]
├── Customer.CustomerMoney (table) [cross-schema]
├── BackOffice.CustomerToThirdPartyFundings (table)
├── Billing.WithdrawAdditionalParameters (table) [cross-schema - OUTER APPLY]
├── Dictionary.WithdrawType (table) [cross-schema]
└── Dictionary.Flow (table) [cross-schema]
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by BackOffice cashout management screen. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Dynamic SQL via sp_executesql. @BeginDateTime declared but only used for potential future logging. @Params declared but never used (leftover from development). SET NOCOUNT ON (set twice - first instance before dynamic SQL block, second at top of static section).

### 7.2 Constraints

SET NOCOUNT ON (x2). NOLOCK on most tables (not on some LEFT JOINs in dynamic SQL). Dynamic SQL with NVARCHAR concatenation - @CashoutStatusIDs, @FundingTypeIDs, @RegulationIDs, @CustomerStatuses are directly injected into SQL string; callers must validate these inputs. Dictionary.ClientWithdrawComment is joined but its column is not in the SELECT (likely a remnant from a previous iteration). ORDER BY always ModificationDate DESC.

---

## 8. Sample Queries

### 8.1 Get pending cashout requests for last 7 days
```sql
EXEC BackOffice.GetCashOutRequests_Main
    @StartDate = DATEADD(DAY,-7,GETUTCDATE()),
    @EndDate = GETUTCDATE(),
    @CashoutStatusIDs = '1,14';  -- Pending and Under Review
```

### 8.2 Get all cashout requests for a specific customer
```sql
EXEC BackOffice.GetCashOutRequests_Main
    @StartDate = '2026-01-01',
    @EndDate = '2026-03-31',
    @CID = 10848122;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPS-3983 | Jira | Performance enhancements and aggregations added June 2021 (Shay O.). Split from GetCashOutRequests procedure April 2021 (Ran Sh). |
| MIMOPS-4538 | Jira | Added @CustomerStatuses parameter July 2021 (Eliran). |
| MIMOPSA-14499 | Jira | Added WithdrawTypeID, ExTransactionID, WithdrawalType+FlowID concatenation Dec 2024 (Evgeny). |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 53 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 3 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCashOutRequests_Main | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCashOutRequests_Main.sql*
