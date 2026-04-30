# BackOffice.GetWithdrawalsByCID

> Returns withdrawal requests for a customer, with optional filtering by specific withdrawal ID, status list, and date range - used by Back Office and services to retrieve a customer's withdrawal history.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CustomerID (required), @StatusIDs TVP (required, may be empty); returns Billing.Withdraw rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetWithdrawalsByCID` is a flexible withdrawal retrieval procedure for a specific customer. It supports three use cases described in the DDL header:
1. Get all withdrawals for a customer (empty @StatusIDs, no @WithdrawalID)
2. Get a specific withdrawal by CID + WithdrawID
3. Get all withdrawals in specific statuses (pass status IDs in @StatusIDs TVP)

The procedure branches on whether @StatusIDs contains rows - if it does, an INNER JOIN filters to those statuses; if empty, all statuses are returned. Optional @WithdrawalID and @FromDate narrow results further. Performance was optimized in DBAD-30 by removing a temp table and relying on a covering index on Billing.Withdraw.

---

## 2. Business Logic

### 2.1 Status Filter Branching

**What**: Two execution paths based on whether @StatusIDs has rows.

**Columns/Parameters Involved**: `@StatusIDs`, `CashoutStatusID`

**Rules**:
- IF EXISTS (SELECT 1 FROM @StatusIDs): INNER JOIN @StatusIDs S ON BW.CashoutStatusID = S.ID (only those statuses)
- ELSE: no status filter (all statuses returned)
- @StatusIDs is the BackOffice.IDs UDT (column name `ID`)

### 2.2 Optional Filters

**What**: @WithdrawalID and @FromDate are optional via ISNULL pattern.

**Columns/Parameters Involved**: `@WithdrawalID`, `@FromDate`

**Rules**:
- `AND BW.WithdrawID = ISNULL(@WithdrawalID, BW.WithdrawID)` - if NULL, no filter on WithdrawID
- `AND BW.RequestDate >= ISNULL(@FromDate, BW.RequestDate)` - if NULL, no date filter; otherwise returns only requests on or after @FromDate

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CustomerID | INT | NO | - | CODE-BACKED | Customer ID to retrieve withdrawals for. Required. Used as BW.CID = @CustomerID filter. |
| 2 | @WithdrawalID | INT | YES | NULL | CODE-BACKED | Optional specific withdrawal ID. NULL = return all withdrawals for customer. |
| 3 | @FromDate | DATETIME | YES | NULL | CODE-BACKED | Optional start date filter. NULL = no date restriction. Returns withdrawals with RequestDate >= @FromDate when provided. Added Sept 2022. |
| 4 | @StatusIDs | BackOffice.IDs (TABLE TYPE) | NO | - | CODE-BACKED | Table-valued parameter of CashoutStatusID values to filter on. Empty = return all statuses. Non-empty = INNER JOIN to restrict to listed statuses. Uses BackOffice.IDs UDT (column: ID). |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CustomerId | INT | NO | - | CODE-BACKED | Customer ID (Billing.Withdraw.CID). |
| 2 | WithdrawID | INT | NO | - | CODE-BACKED | Primary key of the withdrawal (Billing.Withdraw.WithdrawID). |
| 3 | Status | INT | NO | - | CODE-BACKED | CashoutStatus numeric ID (Billing.Withdraw.CashoutStatusID). Raw ID - join Dictionary.CashoutStatus for name. |
| 4 | Amount | MONEY | YES | - | CODE-BACKED | Requested withdrawal amount (Billing.Withdraw.Amount). |
| 5 | CurrencyID | INT | YES | - | CODE-BACKED | Currency of the withdrawal (Billing.Withdraw.CurrencyID). |
| 6 | AccountCurrencyID | INT | YES | - | CODE-BACKED | Customer account currency (Billing.Withdraw.AccountCurrencyID). |
| 7 | PaymentMethodTypeID | INT | NO | - | CODE-BACKED | FundingTypeID for the payment method, ISNULL -> 0 (Billing.Withdraw.FundingTypeID). |
| 8 | PaymentMethodID | INT | NO | - | CODE-BACKED | FundingID for the specific payment method record, ISNULL -> 0 (Billing.Withdraw.FundingID). |
| 9 | Fee | MONEY | YES | - | CODE-BACKED | Fee charged for this withdrawal (Billing.Withdraw.Fee). |
| 10 | ModificationDate | DATETIME | YES | - | CODE-BACKED | Last modification timestamp for this withdrawal record (Billing.Withdraw.ModificationDate). |
| 11 | RequestDate | DATETIME | YES | - | CODE-BACKED | When the customer submitted the withdrawal request (Billing.Withdraw.RequestDate). |
| 12 | UserComment | NVARCHAR | YES | - | CODE-BACKED | Customer's comment/remark on the withdrawal (Billing.Withdraw.Remark). |
| 13 | ManagerID | INT | YES | - | CODE-BACKED | ID of the BackOffice manager who last processed this withdrawal (Billing.Withdraw.ManagerID). |
| 14 | Comment | NVARCHAR | YES | - | CODE-BACKED | Internal BackOffice comment on the withdrawal (Billing.Withdraw.Comment). |
| 15 | Approved | BIT | YES | - | CODE-BACKED | Global approval flag for this withdrawal (Billing.Withdraw.Approved). 1=globally approved, 0/NULL=pending. |
| 16 | ExTransactionID | NVARCHAR | YES | - | CODE-BACKED | External transaction ID from the payment processor (Billing.Withdraw.ExTransactionID). Added Aug 2023. |
| 17 | WithdrawTypeID | INT | YES | - | CODE-BACKED | Type classification of the withdrawal (Billing.Withdraw.WithdrawTypeID). |
| 18 | FlowID | NVARCHAR | YES | - | CODE-BACKED | Withdrawal processing flow identifier (Billing.Withdraw.FlowID). |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BW.CID = @CustomerID | Billing.Withdraw | Read (driving) | Customer's withdrawal records |
| S.ID = BW.CashoutStatusID | @StatusIDs (BackOffice.IDs) | INNER JOIN (conditional) | Status filter when TVP has rows |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO and application services) | @CustomerID | Application | Called for withdrawal history display and programmatic checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetWithdrawalsByCID (procedure)
├── Billing.Withdraw (table)
└── BackOffice.IDs (user defined type - TVP)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | All withdrawal data for the customer |
| BackOffice.IDs | User Defined Type | @StatusIDs TVP type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO and application services. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Covering index optimization | Performance | DBAD-30 removed temp table usage and relies on covering index on Billing.Withdraw for CID + status + date filters (Sept 2022, KateM). |
| BackOffice.IDs vs dbo.IDIntList | Implementation | Uses BackOffice.IDs (column: ID) UDT, not dbo.IDIntList or dbo.IdList. |
| ISNULL filter pattern | Logic | ISNULL(@WithdrawalID, BW.WithdrawID) and ISNULL(@FromDate, BW.RequestDate) patterns allow optional filtering without dynamic SQL. |

---

## 8. Sample Queries

### 8.1 Get all withdrawals for a customer
```sql
DECLARE @StatusIDs BackOffice.IDs
-- Leave empty for all statuses
EXEC [BackOffice].[GetWithdrawalsByCID]
    @CustomerID = 123456,
    @WithdrawalID = NULL,
    @FromDate = NULL,
    @StatusIDs = @StatusIDs
```

### 8.2 Get pending withdrawals only (CashoutStatusID 1 and 2)
```sql
DECLARE @StatusIDs BackOffice.IDs
INSERT INTO @StatusIDs VALUES (1), (2)
EXEC [BackOffice].[GetWithdrawalsByCID]
    @CustomerID = 123456,
    @WithdrawalID = NULL,
    @FromDate = NULL,
    @StatusIDs = @StatusIDs
```

### 8.3 Get a specific withdrawal by ID
```sql
DECLARE @StatusIDs BackOffice.IDs
EXEC [BackOffice].[GetWithdrawalsByCID]
    @CustomerID = 123456,
    @WithdrawalID = 79802,
    @FromDate = NULL,
    @StatusIDs = @StatusIDs
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| MIMOPSA-5783 | Jira (DDL comment) | Original creation - Michal Rechnitzer Dec 2021 |
| DBAD-30 | Jira (DDL comment) | Performance improvement - removed temp table, added covering index on Billing.Withdraw (KateM Sept 2022) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira (MIMOPSA-5783, DBAD-30 from DDL comments) | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetWithdrawalsByCID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetWithdrawalsByCID.sql*
