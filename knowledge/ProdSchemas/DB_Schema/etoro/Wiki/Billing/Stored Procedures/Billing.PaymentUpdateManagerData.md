# Billing.PaymentUpdateManagerData

> Records back-office manager approval and commission on a legacy Billing.Payment record; originally dispatched commission change notifications via Service Broker (fully commented out - decommissioned).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PaymentUpdateManagerData` records the back-office manager approval decision on a legacy `Billing.Payment` deposit. When a sales manager manually reviews and approves a payment, this procedure stamps the payment with the manager's ID, the approval flag, and the computed sales commission.

The commission is calculated using a range-based lookup (`BackOffice.SaleCommissionRange`) applied to the USD-equivalent deposit amount. The function `BackOffice.GetSaleCommission()` converts the local-currency amount to USD (using the stored ExchangeRate), queries the commission tier table, and returns the applicable commission rate.

Originally, the procedure dispatched Service Broker XML messages to a `svcCustomerSupport` service for both the reversal of the previous manager's commission and the attribution of the new one. This entire notification block is fully commented out - the commission notification service has been decommissioned. The XML structures remain in the code as documentation of the original intent.

`Billing.Payment` was frozen since January 2011. No SQL-level callers for this procedure were found in the repo; it is called externally by the back-office administration application.

---

## 2. Business Logic

### 2.1 Commission Computation (Conditional)

**What**: Calculates the sales commission for the approving manager only when both ManagerID and Approved are supplied.

**Parameters Involved**: `@ManagerID`, `@Approved`, `@PaymentID`

**Rules**:
- Commission is calculated ONLY IF `@ManagerID IS NOT NULL AND @Approved = 1`
- Formula: `SELECT @Commission = BackOffice.GetSaleCommission(CAST((Amount/100.0)*ExchangeRate AS MONEY)) FROM Billing.Payment WHERE PaymentID = @PaymentID`
  - `Amount/100.0`: converts stored cents amount to dollar amount
  - `* ExchangeRate`: converts to USD equivalent (dtPrice = decimal(16,8))
  - `BackOffice.GetSaleCommission(@USD_Amount)`: looks up commission tier from `BackOffice.SaleCommissionRange` (MinRange/MaxRange in cents, returns Commission/100.0)
- If ManagerID is NULL or Approved=0: `@Commission` remains NULL -> stored as `ISNULL(@Commission, 0)` = 0

### 2.2 Payment Update with OUTPUT Capture

**What**: Updates ManagerID, Approved, and Commission on the payment, capturing pre-update values.

**Parameters Involved**: `@PaymentID`, `@ManagerID`, `@Approved`, `@Commission`

**Rules**:
- `UPDATE Billing.Payment SET ManagerID=@ManagerID, Approved=@Approved, Commission=ISNULL(@Commission,0) WHERE PaymentID=@PaymentID`
- `OUTPUT DELETED.CID, DELETED.Approved, DELETED.ManagerID, DELETED.Amount, DELETED.ExchangeRate, DELETED.Commission INTO @Info`
- DELETED.* = values BEFORE the update - captures previous manager data for potential reversal notification
- If @PaymentID not found: UPDATE is a silent no-op (@@ROWCOUNT=0, no error)
- No transaction wrapper; no audit trail in History.Payment

### 2.3 PlayerLevelID Enrichment

**What**: Enriches the @Info table variable with the customer's current player level.

**Rules**:
- `UPDATE i SET i.PlayerLevelID = C.PlayerLevelID FROM @Info i INNER JOIN Customer.Customer C ON i.CID = C.CID`
- PlayerLevelID=4 = Test user; guards in the (now-commented-out) notification block excluded test users from commission notifications
- This join still executes even though the notification block is commented out (minor overhead, no functional impact)

### 2.4 Commission Notification via Service Broker (FULLY COMMENTED OUT - Decommissioned)

**What**: Originally sent two XML commission messages to `svcCustomerSupport` for manager commission reattribution.

**Rules (historical)**:
- **Reversal message (previous manager)**: Built FOR XML RAW('CustomerSupport') with CustomerSupportType='COMMISSION', DELETED.ManagerID, Commission = DELETED.Commission * -100 (negative, as reversal)
- **New assignment message (current manager)**: CustomerSupportType='COMMISSION', @ManagerID, Commission = @Commission * 100 (positive, in cents)
- Guard for new assignment: `@Approved=1 AND @ManagerID != 0 AND @Commission > 0 AND PlayerLevelID != 4`
- Service Broker: `BEGIN DIALOG CONVERSATION ... FROM SERVICE svcInitiator TO SERVICE 'svcCustomerSupport'`
- **Entire block is commented out** - the commission notification service was decommissioned; both BEGIN DIALOG and SEND ON CONVERSATION calls are inactive

### 2.5 Error Propagation

**Rules**:
- `RETURN @@ERROR` - raw SQL error code (0=success)
- No TRY/CATCH, no RAISERROR, no explicit transaction

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | INTEGER | NO | - | CODE-BACKED | PK of Billing.Payment to update. Silent no-op if not found (no error raised). |
| 2 | @ManagerID | INTEGER | YES | - | CODE-BACKED | Back-office sales manager ID approving the deposit. NULL = no manager assignment (commission stays 0). FK to back-office user/manager table (not validated in proc). |
| 3 | @Approved | BIT | NO | - | CODE-BACKED | Manager approval decision. 1=Approved (triggers commission calculation). 0=Rejected or pending (commission set to 0). Stored in Billing.Payment.Approved. |
| 4 | RETURN value | INTEGER | - | - | CODE-BACKED | @@ERROR: 0=success, non-zero=SQL error. No TRY/CATCH. |
| 5 | @Commission (internal) | MONEY | YES | NULL | CODE-BACKED | Locally computed commission amount. From BackOffice.GetSaleCommission(USD_amount). 0 if not applicable. Stored as Commission in Billing.Payment. |
| 6 | @Info (internal) | TABLE | - | - | CODE-BACKED | Table variable capturing DELETED.* (pre-update values) via OUTPUT INTO. Columns: CID, Approved, ManagerID, Amount, ExchangeRate, Commission, PlayerLevelID. Used for Service Broker notification (commented out). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE + OUTPUT | [Billing.Payment](../Tables/Billing.Payment.md) | MODIFIER | Sets ManagerID, Approved, Commission; captures pre-update values |
| GetSaleCommission | BackOffice.GetSaleCommission | Function call | Computes range-based commission on USD deposit amount |
| PlayerLevelID join | Customer.Customer | READ | Enriches @Info with PlayerLevelID for test-user guard |
| Commission lookup | BackOffice.SaleCommissionRange | READ (via function) | Tier table used by BackOffice.GetSaleCommission |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office administration (external) | @PaymentID | EXEC caller | Called by back-office operator tool when manager approves a legacy payment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentUpdateManagerData (procedure)
├── Billing.Payment (table)
├── BackOffice.GetSaleCommission (function)
│   └── BackOffice.SaleCommissionRange (table)
└── Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Payment](../Tables/Billing.Payment.md) | Table | UPDATE (ManagerID, Approved, Commission) + OUTPUT INTO @Info |
| BackOffice.GetSaleCommission | Function | Computes commission from USD-equivalent deposit amount |
| BackOffice.SaleCommissionRange | Table (via function) | Commission tier lookup (MinRange, MaxRange, Commission) |
| Customer.Customer | Table | JOIN for PlayerLevelID (test user flag) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back-office admin tool (external) | Application | Called to stamp manager approval and commission on legacy deposits |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No transaction wrapper. No audit trail (no History.Payment insert). Commission calculation only fires when @ManagerID IS NOT NULL AND @Approved=1. Service Broker commission notification block fully commented out. PlayerLevelID join executes regardless (minor overhead). Silent no-op if @PaymentID missing.

---

## 8. Sample Queries

### 8.1 Approve a legacy payment with manager commission

```sql
DECLARE @Err INTEGER;
EXEC @Err = Billing.PaymentUpdateManagerData
    @PaymentID = 12345,
    @ManagerID = 101,   -- sales manager user ID
    @Approved  = 1;     -- approved
SELECT @Err AS ErrorCode;
```

### 8.2 Reject / clear manager data on a legacy payment

```sql
EXEC Billing.PaymentUpdateManagerData
    @PaymentID = 12345,
    @ManagerID = NULL,  -- no manager
    @Approved  = 0;     -- not approved (commission = 0)
```

### 8.3 Check commission ranges used by GetSaleCommission

```sql
SELECT
    MinRange,
    MaxRange,
    Commission,
    MinRange / 100.0  AS MinRangeUSD,
    MaxRange / 100.0  AS MaxRangeUSD,
    Commission / 100.0 AS CommissionRate
FROM BackOffice.SaleCommissionRange WITH (NOLOCK)
ORDER BY MinRange;
```

### 8.4 Find legacy payments with manager commission assigned

```sql
SELECT
    bp.PaymentID,
    bp.CID,
    bp.Amount / 100.0 AS AmountUSD,
    bp.ExchangeRate,
    bp.ManagerID,
    bp.Approved,
    bp.Commission
FROM Billing.Payment bp WITH (NOLOCK)
WHERE bp.ManagerID IS NOT NULL
  AND bp.Approved = 1
  AND bp.Commission > 0
ORDER BY bp.PaymentDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentUpdateManagerData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PaymentUpdateManagerData.sql*
