# Billing.WithdrawalService_GetCustomerFeeGroups

> Returns the withdrawal fee schedule applicable to a specific customer by joining their fee group assignment to the cashout range configuration table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT - the customer whose fee schedule is returned |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the fee schedule that applies to a given customer when they request a withdrawal. eToro charges a flat withdrawal fee that varies by customer tier: Default customers pay $5, Exempt customers (high-tier eToro Club members, top Popular Investors) pay $0, and Discount customers have a bracket-based schedule (free below $500, $5 above). This procedure exposes that fee schedule to the withdrawal service so the UI or business logic can display the applicable fee to the customer before they submit.

The procedure exists as a lookup helper for the withdrawal flow. Before `Billing.WithdrawalService_WithdrawRequestAdd` submits a withdrawal, the calling application may use this procedure to present the customer with their fee structure. The fee schedule itself is configured in `Trade.CashoutRange` and the customer's fee group assignment is stored in `BackOffice.Customer.CashoutFeeGroupID`. The `AccountTypeID` is returned alongside the fee data to allow the caller to apply any account-type-specific display logic.

The procedure was authored by Alon Nachshon on 27-11-2013 as part of the original withdrawal service infrastructure. No callers were discovered in the SSDT repo, indicating it is called from application code via the `WithdrawalServiceUser` SQL login.

---

## 2. Business Logic

### 2.1 Customer Fee Group Resolution

**What**: The customer's fee tier is stored in `BackOffice.Customer.CashoutFeeGroupID`; this procedure joins it to the fee range table to produce the applicable schedule.

**Columns/Parameters Involved**: `@CID`, `CashoutFeeGroupID` (join key), `FromValue`, `ToValue`, `Fee`

**Rules**:
- The JOIN `BackOffice.Customer bc ON bc.CashoutFeeGroupID = cr.CashoutFeeGroupID` resolves the customer to their fee tier
- Multiple rows may be returned when the customer's fee group has multiple brackets (e.g., Discount group returns 2 rows: $0 for <$500, $5 for >$500)
- Default group (CashoutFeeGroupID=1): 1 row returned - $5 flat fee for all amounts
- Exempt group (CashoutFeeGroupID=2): 1 row returned - $0 for all amounts
- Discount group (CashoutFeeGroupID=3): 2 rows returned - $0 for $1-$500, $5 for $500.01-$100M
- The fee group is assigned based on eToro Club loyalty level and Popular Investor status; managed by `Billing.ProcessCashoutFeeGroupUpdate`

**Diagram**:
```
@CID
  |
  +--> BackOffice.Customer
  |      CashoutFeeGroupID = 1 (Default) | 2 (Exempt) | 3 (Discount)
  |
  +--> Trade.CashoutRange (JOIN on CashoutFeeGroupID)
         Group 1: [FromValue=$1, ToValue=$100M, Fee=$5]       1 row
         Group 2: [FromValue=$1, ToValue=$100M, Fee=$0]       1 row
         Group 3: [FromValue=$1, ToValue=$500, Fee=$0]
                  [FromValue=$500.01, ToValue=$100M, Fee=$5]  2 rows

Returns: FromValue, ToValue, Fee, AccountTypeID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Input parameter. The customer identifier (CID) whose fee schedule is to be retrieved. Passed to the WHERE clause filtering BackOffice.Customer. |
| 2 | FromValue | money | YES | - | VERIFIED | Output column from Trade.CashoutRange. Lower bound of the withdrawal amount range in dollars. E.g., 1.00 (all groups start at $1). The customer's withdrawal amount must be >= this value for the fee row to apply. (Source: Trade.CashoutRange) |
| 3 | ToValue | money | YES | - | VERIFIED | Output column from Trade.CashoutRange. Upper bound of the withdrawal amount range in dollars. E.g., 100000000.00. The customer's withdrawal amount must be <= this value for the fee row to apply. Together with FromValue defines the fee bracket. (Source: Trade.CashoutRange) |
| 4 | Fee | money | YES | - | VERIFIED | Output column from Trade.CashoutRange. Flat dollar fee charged for withdrawals within the range. Values: $0 (Exempt and Discount small amounts) or $5.00 (Default and Discount large amounts). Billing.WithdrawRequestAdd multiplies by 100 to convert to cents when applying the deduction. (Source: Trade.CashoutRange) |
| 5 | AccountTypeID | tinyint | NO | 1 | VERIFIED | Output column from BackOffice.Customer. Account classification: 1=Private (standard retail), 2=Corporate, 3=IB Account, 4=Joint, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 14=SMSF. Default=1 (Private). 99.3% of customers are Private. Returned alongside fee data to allow account-type-specific handling by the caller. See [Account Type](_glossary.md#account-type). (Source: BackOffice.Customer) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (JOIN) | Trade.CashoutRange | Lookup | Source of fee range data (FromValue, ToValue, Fee) |
| (JOIN) | BackOffice.Customer | Lookup | Source of customer's fee group assignment and AccountTypeID; filtered by @CID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Referenced in WithdrawalServiceUser and PROD_BIadmins permission scripts; called from application code.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawalService_GetCustomerFeeGroups (procedure)
├── Trade.CashoutRange (table)
└── BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CashoutRange | Table | JOIN source - provides fee range brackets (FromValue, ToValue, Fee) keyed by CashoutFeeGroupID |
| BackOffice.Customer | Table | JOIN + WHERE source - resolves @CID to CashoutFeeGroupID and supplies AccountTypeID |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by application code via WithdrawalServiceUser SQL login.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure for a specific customer

```sql
EXEC Billing.WithdrawalService_GetCustomerFeeGroups @CID = 12345;
```

### 8.2 Equivalent direct query with fee group name for analysis

```sql
SELECT  cr.FromValue,
        cr.ToValue,
        cr.Fee,
        bc.AccountTypeID,
        dcfg.Name AS FeeGroupName
FROM    Trade.CashoutRange cr WITH (NOLOCK)
JOIN    BackOffice.Customer bc WITH (NOLOCK)
        ON bc.CashoutFeeGroupID = cr.CashoutFeeGroupID
JOIN    Dictionary.CashoutFeeGroup dcfg WITH (NOLOCK)
        ON cr.CashoutFeeGroupID = dcfg.CashoutFeeGroupID
WHERE   bc.CID = 12345;
```

### 8.3 Check how many customers are in each fee group

```sql
SELECT  dcfg.Name       AS FeeGroupName,
        COUNT(bc.CID)   AS CustomerCount
FROM    BackOffice.Customer bc WITH (NOLOCK)
JOIN    Dictionary.CashoutFeeGroup dcfg WITH (NOLOCK)
        ON bc.CashoutFeeGroupID = dcfg.CashoutFeeGroupID
GROUP BY dcfg.Name
ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawalService_GetCustomerFeeGroups | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawalService_GetCustomerFeeGroups.sql*
