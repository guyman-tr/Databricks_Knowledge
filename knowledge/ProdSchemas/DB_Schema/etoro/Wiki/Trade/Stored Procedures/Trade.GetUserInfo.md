# Trade.GetUserInfo

> Core pre-execution user context loader - returns a single row with credit (adjusted for open orders, in cents), copy status, regulation, account type, and blocking status for one customer. Called during trade open/close pre-execution to validate customer eligibility.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer being loaded |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserInfo` is the primary customer context loader for eToro's trade pre-execution pipeline. Before any trade can be opened or closed, the execution engine calls this procedure to retrieve the customer's current state: how much credit is available (adjusted for orders already in-flight), whether they are allowed to copy or be copied, their regulation, account type, and risk classification.

The procedure has evolved over several years (visible in the change log: 2017-2022), with notable additions:
- **TRADEX-578** (Jan 2021): Added DesignatedRegulationID output for regulatory override scenarios
- **TRADEX-1633** (Jun/Aug 2021): Added on-read credit validation - credit is now reported net of `Trade.GetTotalManualOrdersForOpenAmount` (pending manual orders that reserve credit). This prevents over-allocation when multiple orders are submitted simultaneously.
- **FB 52071** (Jul 2018): Added HighRiskApprovalStatus (now surfaced as TradingRiskStatusID via BackOffice.Customer)
- **FB 45530** (Jun 2017): Fund detection migrated from Trade.Fund table to AccountTypeID=9 in BackOffice.Customer

The Credit field is returned as BIGINT in cents (x100) to avoid floating-point precision loss in the execution engine's credit checks.

---

## 2. Business Logic

### 2.1 Credit Adjusted for Open Orders (TRADEX-1633)

**What**: The returned Credit reflects available balance minus the reserved amount for pending manual orders.

**Columns/Parameters Involved**: `Customer.Customer.Credit`, `@TotalOrdersAmount`, `Trade.GetTotalManualOrdersForOpenAmount`

**Rules**:
- `@TotalOrdersAmount = Trade.GetTotalManualOrdersForOpenAmount(@CID)`: function returns the sum of amounts reserved by open (pending) manual orders
- `Credit` output = `CAST((Credit - @TotalOrdersAmount) * 100 AS BIGINT)`: returned in cents (integer, x100) to avoid decimal precision issues
- If no pending orders: @TotalOrdersAmount = 0, Credit = raw balance x100
- This prevents double-spending: two concurrent trade opens would both see reduced available credit

### 2.2 IsBeingCopied Pre-Computation

**What**: Whether this customer is currently a copied Popular Investor.

**Rules**:
- `@IsBeingCopied = CAST(CASE WHEN EXISTS(SELECT 1 FROM Trade.Mirror WHERE ParentCID = @CID) THEN 1 ELSE 0 END AS BIT)`
- EXISTS check on Trade.Mirror for any active mirror with this CID as parent
- Computed before the main SELECT; stored in a local variable to avoid correlated subquery in the main result
- Note: checks any mirror (not only IsActive=1) - returns 1 if any mirror exists even if paused

### 2.3 IsFund Detection (AccountTypeID=9)

**What**: Identifies fund (pooled investment) accounts.

**Rules**:
- `IsFund = IIF(BC.AccountTypeID = 9, 1, 0)`
- AccountTypeID=9 in BackOffice.Customer = Fund account
- Migration note: previously checked Trade.Fund table (changed 2017, FB 45530); now solely derived from AccountTypeID

### 2.4 IsCupon (Bonus-Only Customer)

**What**: Whether the customer has a bonus-only status restricting certain operations.

**Rules**:
- `IsCupon = CASE WHEN ISNULL(HB.CID, 0) = 0 THEN 0 ELSE 1 END`
- LEFT JOIN to `BackOffice.BonusOnlyCustomers` - if row exists, IsCupon=1
- "Coupon" customers may have restricted withdrawal rights or trading capabilities

### 2.5 IsCopyBlocked / CopyBlockReasonID

**What**: Whether the customer's copy operations are blocked and why.

**Rules**:
- LEFT JOIN to `Customer.BlockedCustomerOperations` where `OperationTypeID IN (21, 1)`
  - OperationTypeID=21: likely copy-trade block
  - OperationTypeID=1: likely general trade block
- `IsCopyBlocked = ISNULL(CBO.OperationTypeID, 0)`: returns the OperationTypeID if blocked, 0 if not
- `CopyBlockReasonID = ISNULL(CBO.BlockReasonID, 0)`: reason code for the block

### 2.6 RegulationID Override Pattern

**What**: Returns designated regulation when set, or 0 when no override applies.

**Rules**:
- `RegulationID = ISNULL(BC.DesignatedRegulationID, 0)`
- Note: returns 0 (not the base RegulationID) when no designated override is set
- Callers treat 0 as "no regulatory override; use customer's base regulation from elsewhere"
- This differs from the standard pattern `ISNULL(DesignatedRegulationID, RegulationID)` used in other SPs; here the caller handles the fallback

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID for which to load trade context. All joins filter to this CID. |

**Output columns (single row):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | Credit | BIGINT | NO | - | CODE-BACKED | Available credit in cents (x100): (Customer.Credit - TotalManualOrdersForOpen) * 100. TRADEX-1633: adjusted for pending order reservations. |
| 3 | SpreadGroupID | INT | NO | - | CODE-BACKED | Spread group assignment for instrument pricing. From Customer.Customer. |
| 4 | LotCountGroupID | INT | YES | - | CODE-BACKED | Lot size group assignment. From Customer.Customer. |
| 5 | PlayerStatusID | INT | NO | - | CODE-BACKED | Current player account status. FK to Dictionary.PlayerStatus. |
| 6 | LabelID | INT | YES | - | CODE-BACKED | Marketing label assignment from Customer.Customer. |
| 7 | IsCupon | BIT | NO | - | CODE-BACKED | 1 = bonus-only customer (row in BackOffice.BonusOnlyCustomers); 0 = normal. |
| 8 | TotalCash | MONEY | NO | - | CODE-BACKED | ISNULL(TotalCash, 0). Total cash balance from Customer.Customer. |
| 9 | PlayerLevelID | INT | NO | - | CODE-BACKED | Customer tier (1=Regular, 2=Popular Investor, 4=Etorian, etc.). From Customer.Customer. FK to Dictionary.PlayerLevel. |
| 10 | RealizedEquity | MONEY | NO | - | CODE-BACKED | Cumulative realized P&L from Customer.Customer. |
| 11 | IsCopyBlocked | INT | NO | - | CODE-BACKED | ISNULL(CBO.OperationTypeID, 0). Non-zero = copy operations blocked; value = OperationTypeID of the block. OperationTypeID IN (21, 1) checked. |
| 12 | CopyBlockReasonID | INT | NO | - | CODE-BACKED | ISNULL(CBO.BlockReasonID, 0). Reason code for copy block. 0 = no block. |
| 13 | IsBeingCopied | BIT | NO | - | CODE-BACKED | 1 = customer currently has copiers (any Mirror with ParentCID=@CID exists); 0 = not being copied. |
| 14 | CountryID | INT | NO | - | CODE-BACKED | Customer's country of residence. FK to Dictionary.Country. |
| 15 | UserName | VARCHAR | NO | - | CODE-BACKED | Customer's username. |
| 16 | CountryName | VARCHAR | NO | - | CODE-BACKED | Country name from Dictionary.Country.Name. |
| 17 | AffiliateID | INT | YES | - | CODE-BACKED | Affiliate program SerialID from Customer.Customer. |
| 18 | GCID | INT | NO | - | CODE-BACKED | Global Customer ID. |
| 19 | CID | INT | NO | - | CODE-BACKED | Database-local Customer ID. |
| 20 | IsFund | BIT | NO | - | CODE-BACKED | 1 = fund account (AccountTypeID=9 in BackOffice.Customer); 0 = standard account. |
| 21 | TradingRiskStatusID | INT | NO | - | CODE-BACKED | Trading risk classification from BackOffice.Customer. FK to Dictionary.TradingRiskStatus. Added FB 52071. |
| 22 | RegulationID | INT | NO | - | CODE-BACKED | ISNULL(BC.DesignatedRegulationID, 0). Returns the designated regulation override if set, else 0. Callers fall back to base RegulationID when 0. Added TRADEX-578. |
| 23 | Registered | DATETIME | NO | - | CODE-BACKED | Customer registration date from Customer.Customer. |
| 24 | GuruStatusID | INT | YES | - | CODE-BACKED | Guru/Popular Investor program status from BackOffice.Customer. |
| 25 | AccountTypeID | INT | NO | - | CODE-BACKED | Account type from BackOffice.Customer. 9=Fund, 7/13=hedge desk types, others=standard. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Credit computation | Trade.GetTotalManualOrdersForOpenAmount | Function call | Gets total amount reserved by pending manual open orders |
| IsBeingCopied | Trade.Mirror | EXISTS subquery | Checks if any mirror has ParentCID = @CID |
| FROM | Customer.Customer | FROM | Primary customer data source |
| JOIN | BackOffice.Customer | INNER JOIN | AccountTypeID, TradingRiskStatusID, RegulationID, DesignatedRegulationID, GuruStatusID |
| JOIN | Dictionary.Country | INNER JOIN | Country name resolution |
| LEFT JOIN | BackOffice.BonusOnlyCustomers | LEFT JOIN | IsCupon flag |
| LEFT JOIN | Customer.BlockedCustomerOperations | LEFT JOIN | IsCopyBlocked and CopyBlockReasonID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetUserInfoWithCopyRestirctions | EXEC | Caller | Orchestrator that combines GetUserInfo + GetMirrorData + restrictions |
| (trade execution engine) | @CID | EXEC caller | Pre-execution customer context loader |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserInfo (procedure)
+-- Trade.GetTotalManualOrdersForOpenAmount (function)
+-- Trade.Mirror (table) [IsBeingCopied EXISTS check]
+-- Customer.Customer (table)
+-- BackOffice.Customer (table)
+-- Dictionary.Country (table)
+-- BackOffice.BonusOnlyCustomers (table)
+-- Customer.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTotalManualOrdersForOpenAmount | Function | Credit adjustment for pending orders |
| Trade.Mirror | Table | EXISTS check for IsBeingCopied |
| Customer.Customer | Table | Primary identity, credit, equity, country, label |
| BackOffice.Customer | Table | AccountTypeID, TradingRiskStatusID, DesignatedRegulationID, GuruStatusID |
| Dictionary.Country | Table | Country name resolution |
| BackOffice.BonusOnlyCustomers | Table | Bonus-only flag |
| Customer.BlockedCustomerOperations | Table | Copy block status and reason |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetUserInfoWithCopyRestirctions | Stored Procedure | EXEC caller - orchestration wrapper |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Credit * 100 CAST to BIGINT | Data format | Credit returned in cents as integer to avoid floating-point issues |
| OperationTypeID IN (21, 1) | Block type filter | Only specific operation types constitute a copy block |
| WITH (NOLOCK) | Isolation | All reads are dirty reads for performance |

---

## 8. Sample Queries

### 8.1 Load pre-execution user context
```sql
EXEC Trade.GetUserInfo @CID = 123456
```

### 8.2 Understand credit calculation
```sql
-- Available credit = (raw credit - pending order reservations) * 100 cents
SELECT CC.Credit,
       Trade.GetTotalManualOrdersForOpenAmount(123456) AS ReservedForOrders,
       CAST((CC.Credit - Trade.GetTotalManualOrdersForOpenAmount(123456)) * 100 AS BIGINT) AS AvailableCreditCents
FROM Customer.Customer CC WITH (NOLOCK)
WHERE CC.CID = 123456
```

### 8.3 Check copy block status
```sql
SELECT CID, OperationTypeID, BlockReasonID
FROM Customer.BlockedCustomerOperations WITH (NOLOCK)
WHERE CID = 123456
  AND OperationTypeID IN (21, 1)
```

---

## 9. Atlassian Knowledge Sources

**Jira**:
- **TRADEX-578** (referenced in DDL): Added DesignatedRegulationID output for regulatory override
- **TRADEX-1633** (referenced in DDL): Pre-execution on-read credit validation - introduced @TotalOrdersAmount credit adjustment

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 2 Jira (TRADEX-578, TRADEX-1633) | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserInfo | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserInfo.sql*
