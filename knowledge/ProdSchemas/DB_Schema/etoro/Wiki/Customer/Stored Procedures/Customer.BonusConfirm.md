# Customer.BonusConfirm

> Completes the two-step demo-account bonus flow: verifies a demo customer's email, credits a $2,000 bonus, and sends a confirmation email.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 0 on success, 60000 on transaction error, or Billing error code |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.BonusConfirm` is the second step of eToro's demo-account email-bonus flow. When a demo user requests a $2,000 virtual bonus via `Customer.BonusRequest`, a verification email is sent. When the user clicks the confirmation link in that email, the application calls `Customer.BonusConfirm` to complete the process.

This procedure exists to deliver the demo bonus only after email ownership is confirmed, preventing bonus abuse via unverified email addresses. It updates the customer's email and marks it as verified, then calls `Billing.AmountAddBonus` to credit 200,000 cents ($2,000) to the demo account, and finally sends a bonus confirmation email via `Maintenance.SendMail`.

The procedure enforces a double eligibility check: the customer must still be a demo account (IsReal=0) and their combined balance (Credit + open position value) must still be below $300 at the time of confirmation, preventing bonus stacking if the account was funded between request and confirm.

See also: `Customer.BonusRequest` (step 1 - initiates the flow and sends the verification email).

---

## 2. Business Logic

### 2.1 Eligibility Re-Check at Confirmation

**What**: The bonus eligibility is re-verified at confirmation time, not just at request time.

**Columns/Parameters Involved**: `Customer.Customer.IsReal`, `Customer.Customer.Credit`, `Trade.Position.Amount`, `@CID`

**Rules**:
- Customer must be demo: `IsReal = 0`
- Customer's total value (credit + sum of open position amounts) must be < 300 (USD, since amounts are in cents and the threshold is 300 cents = $3? Actually 300 in the Credit field which is stored in dollars based on context)
- `Credit + (SELECT ISNULL(SUM(Amount), 0) FROM Trade.Position WHERE CID = @CID) < 300`
- If either condition fails, the procedure exits without error and returns 0 (silently no-ops - the user is no longer eligible)

### 2.2 Three-Step Completion Sequence

**What**: Email verification, bonus credit, and notification are performed atomically inside a transaction.

**Columns/Parameters Involved**: `Customer.Customer.Email`, `Customer.Customer.IsEmailVerified`, `@Email`, `@CID`

**Rules**:
- Step 1: UPDATE Customer.Customer SET Email = @Email, IsEmailVerified = 1 WHERE CID = @CID
- Step 2: EXEC Billing.AmountAddBonus (200,000 cents = $2,000, AccountUpdateTypeID=3, Currency=1 USD, ManagerID=0 = system-initiated)
- Step 3: EXEC Maintenance.SendMail (TemplateID=1 = bonus confirmation email, 2 params: UserName + FirstName/LastName)
- All three run in a single transaction - if any step fails, the whole sequence rolls back
- Error code 60000 returned on any transaction failure

**Diagram**:
```
User clicks confirmation link
  -> App calls Customer.BonusConfirm(@CID, @Email)
       |
       v
  Re-check eligibility (IsReal=0, balance < $300)
       |
       +-- NOT eligible --> RETURN 0 (silent no-op)
       |
       +-- Eligible --> BEGIN TRANSACTION
             |
             +--> UPDATE Customer.Customer (Email, IsEmailVerified=1)
             |      ERROR? --> ROLLBACK, RAISERROR 60000
             |
             +--> EXEC Billing.AmountAddBonus ($2,000, system-initiated)
             |      ERROR? --> RETURN Billing error code
             |
             +--> EXEC Maintenance.SendMail (TemplateID=1, bonus confirmation)
             |      ERROR? --> RETURN Mail error code
             |
             +--> COMMIT, RETURN 0
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID of the demo account requesting the bonus. Used to look up eligibility in Customer.Customer and to scope Trade.Position sum. |
| 2 | @Email | VARCHAR(50) | NO | - | CODE-BACKED | Email address confirmed by the user clicking the verification link. Stored to Customer.Customer.Email and triggers IsEmailVerified=1. |
| 3 | RETURN value | INTEGER | NO | - | CODE-BACKED | 0 = success (or ineligible - silent no-op). 60000 = transaction failure during email update. Other positive values = error codes from Billing.AmountAddBonus or Maintenance.SendMail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID (eligibility) | Customer.Customer | Read + Write | Reads IsReal, Credit for eligibility check; updates Email and IsEmailVerified on confirmation |
| @CID (position value) | Trade.Position | Read | Sums open position Amount to verify balance still below $300 threshold |
| @CID (bonus) | Billing.AmountAddBonus | Call | Credits $2,000 (200,000 cents) as AccountUpdateTypeID=3 (bonus), Currency=1 (USD) |
| @CID (email) | Maintenance.SendMail | Call | Sends bonus confirmation email (TemplateID=1) with UserName and name as parameters |

### 5.2 Referenced By (other objects point to this)

Called by the application layer when a user clicks the email confirmation link from the bonus verification email sent by `Customer.BonusRequest`. PROD_BIadmins has EXECUTE permission.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.BonusConfirm (procedure)
├── Customer.Customer (view)
├── Trade.Position (table)
├── Billing.AmountAddBonus (procedure)
└── Maintenance.SendMail (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Eligibility check (IsReal=0, Credit threshold); UPDATE target for Email and IsEmailVerified; UserName/FirstName/LastName read for mail parameters |
| Trade.Position | Table | SUM(Amount) to compute total demo balance for eligibility check |
| Billing.AmountAddBonus | Procedure | Called to credit 200,000 cents ($2,000) as bonus (AccountUpdateTypeID=3, Currency=1 USD) |
| Maintenance.SendMail | Procedure | Called to send bonus confirmation email (TemplateID=1, 2 params) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | External | Called when user clicks email verification link in bonus request flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

The commented-out `BEGIN DIALOG CONVERSATION` block (Service Broker) indicates an older notification mechanism was removed and replaced with `Maintenance.SendMail`.

---

## 8. Sample Queries

### 8.1 Execute bonus confirmation for a demo customer

```sql
DECLARE @Result INT
EXEC @Result = [Customer].[BonusConfirm]
    @CID   = 12345,
    @Email = 'user@example.com'
SELECT @Result AS ReturnCode  -- 0=success, 60000=tx error, other=billing/mail error
```

### 8.2 Check if a demo customer is still eligible for the bonus

```sql
SELECT
    c.CID,
    c.IsReal,
    c.Credit,
    c.IsEmailVerified,
    ISNULL((SELECT SUM(Amount) FROM Trade.Position WITH (NOLOCK) WHERE CID = c.CID), 0) AS OpenPositionValue,
    c.Credit + ISNULL((SELECT SUM(Amount) FROM Trade.Position WITH (NOLOCK) WHERE CID = c.CID), 0) AS TotalValue
FROM Customer.Customer c WITH (NOLOCK)
WHERE c.CID = 12345
```

### 8.3 Find demo accounts that completed bonus confirmation recently

```sql
SELECT TOP 20
    c.CID,
    c.Email,
    c.IsEmailVerified,
    c.Credit,
    c.Registered
FROM Customer.CustomerStatic c WITH (NOLOCK)
WHERE c.IsReal = 0
AND c.IsEmailVerified = 1
AND c.Credit >= 2000
ORDER BY c.Registered DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3 (1, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.BonusConfirm | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.BonusConfirm.sql*
