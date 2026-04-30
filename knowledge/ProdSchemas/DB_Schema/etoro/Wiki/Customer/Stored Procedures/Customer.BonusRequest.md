# Customer.BonusRequest

> Initiates the demo-account $2,000 bonus flow: immediately credits the bonus if email is already verified, or sends a verification email if it is not.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 0 on success, or an error code from Billing/Mail subsystems |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.BonusRequest` is the first step of eToro's demo-account email-bonus program. A demo user who has not yet received the $2,000 virtual bonus can request it. If their email is already verified and matches what is on record, the bonus is credited immediately. If not, a verification email is sent; the user must click the link which triggers `Customer.BonusConfirm` to complete the flow.

The procedure exists to incentivise demo-account engagement: new users who register and verify their email receive $2,000 in virtual funds to trade with. Phone number normalisation is optionally applied if the customer provides a phone number during the request, keeping contact data clean via `Internal.NormalizeString`.

The eligibility guard (IsReal=0, combined balance < $300) prevents real-money account holders from receiving demo bonuses and prevents repeated bonus requests by customers who have already been substantially funded.

See also: `Customer.BonusConfirm` (step 2 - email link clicked, bonus credited and confirmation email sent).

---

## 2. Business Logic

### 2.1 Eligibility Check (Demo + Low Balance)

**What**: The bonus is restricted to demo accounts whose total value is still below a threshold.

**Columns/Parameters Involved**: `Customer.Customer.IsReal`, `Customer.Customer.Credit`, `Trade.Position.Amount`, `@CID`

**Rules**:
- `IsReal = 0` - customer must be a demo account (not a real-money account)
- `Credit + (SELECT ISNULL(SUM(Amount), 0) FROM Trade.Position WHERE CID = @CID) < 300` - total demo balance below threshold
- If ineligible: procedure exits immediately, returns 0 (silent no-op)

### 2.2 Two-Path Bonus Logic: Immediate vs Deferred

**What**: If email is already verified, bonus is given immediately. If not, email verification is sent first.

**Columns/Parameters Involved**: `Customer.Customer.IsEmailVerified`, `Customer.Customer.Email`, `@Email`

**Rules**:
- **Immediate path** (`IsEmailVerified = 1 AND Email = @Email`): EXEC Billing.AmountAddBonus (200,000 cents = $2,000, BonusCategoryID=3 "custom", AccountUpdateTypeID=3, Currency=1 USD, ManagerID=0 system-initiated)
- **Deferred path** (email not yet verified or different email): EXEC Maintenance.SendMail (TemplateID=9 = bonus verification email, 3 params: UserName, CID, Email)
- The immediate path uses BonusCategoryID=3 (vs NULL in BonusConfirm) - this is the only difference in the bonus credit call between the two SPs

**Diagram**:
```
App calls Customer.BonusRequest(@CID, @Email, @Phone)
  |
  v
Eligibility check (IsReal=0, balance < $300)
  |
  +-- NOT eligible --> RETURN 0 (silent no-op)
  |
  +-- Eligible --> BEGIN TRANSACTION
        |
        +--> Phone update (if @Phone NOT NULL, normalized via Internal.NormalizeString)
        |
        +--> IsEmailVerified=1 AND Email=@Email?
               |
               +-- YES (already verified) --> EXEC Billing.AmountAddBonus ($2,000)
               |                              --> RETURN result
               |
               +-- NO (not verified)  --> EXEC Maintenance.SendMail (TemplateID=9, verification email)
                                          User clicks link --> Customer.BonusConfirm called
```

### 2.3 Phone Normalisation

**What**: Optionally updates the customer's phone number, normalising it before storage.

**Columns/Parameters Involved**: `@Phone`, `Customer.Customer.Phone`

**Rules**:
- Only runs if `@Phone IS NOT NULL` after `Internal.NormalizeString(@Phone)` is applied
- `Internal.NormalizeString` strips formatting characters from phone numbers
- UPDATE Customer.Customer SET Phone = @Phone WHERE CID = @CID runs inside the same transaction
- If this UPDATE fails, the transaction rolls back and error code is returned

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID of the demo account requesting the bonus. Used for eligibility check, position value lookup, optional phone update, and bonus credit. |
| 2 | @Email | VARCHAR(50) | NO | - | CODE-BACKED | Email address provided by the customer. Checked against Customer.Customer.Email + IsEmailVerified=1 to determine immediate vs deferred bonus path. |
| 3 | @Phone | VARCHAR(30) | YES | NULL | CODE-BACKED | Optional phone number. If provided, normalised via Internal.NormalizeString and stored to Customer.Customer.Phone before the bonus logic runs. |
| 4 | RETURN value | INTEGER | NO | - | CODE-BACKED | 0 = success (bonus credited or verification email sent, or ineligible silent no-op). Positive value = error code from Billing.AmountAddBonus or Maintenance.SendMail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID (eligibility + paths) | Customer.Customer | Read + Write | Reads IsReal, Credit, IsEmailVerified, Email, UserName for logic; optionally updates Phone |
| @CID (balance check) | Trade.Position | Read | SUM(Amount) on open positions to verify total balance below $300 threshold |
| @Phone | Internal.NormalizeString | Call | Strips formatting from phone number before storage |
| Immediate path | Billing.AmountAddBonus | Call | Credits $2,000 (200,000 cents) as bonus when email already verified (BonusCategoryID=3) |
| Deferred path | Maintenance.SendMail | Call | Sends verification email (TemplateID=9, 3 params: UserName, CID, Email) when email not yet verified |

### 5.2 Referenced By (other objects point to this)

Called by the application layer when a demo user requests the email bonus (e.g., bonus prompt in the trading dashboard). PROD_BIadmins has EXECUTE permission.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.BonusRequest (procedure)
├── Customer.Customer (view)
├── Trade.Position (table)
├── Internal.NormalizeString (function/procedure)
├── Billing.AmountAddBonus (procedure)
└── Maintenance.SendMail (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | Eligibility (IsReal, Credit), email verification check (IsEmailVerified, Email), phone update target, UserName read for mail parameters |
| Trade.Position | Table | SUM(Amount) for balance eligibility check |
| Internal.NormalizeString | Function/Procedure | Normalises @Phone string before UPDATE |
| Billing.AmountAddBonus | Procedure | Credits $2,000 bonus on the immediate-verification path (BonusCategoryID=3, AccountUpdateTypeID=3, Currency=1 USD) |
| Maintenance.SendMail | Procedure | Sends verification email on deferred path (TemplateID=9, 3 params: UserName/CID/Email) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | External | Called when demo user triggers bonus request in the platform UI |
| Customer.BonusConfirm | Procedure | The second step - called after user clicks the verification email link sent by this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute bonus request for a demo customer (with phone)

```sql
DECLARE @Result INT
EXEC @Result = [Customer].[BonusRequest]
    @CID   = 12345,
    @Email = 'user@example.com',
    @Phone = '+1-555-123-4567'
SELECT @Result AS ReturnCode  -- 0=success, positive=error
```

### 8.2 Execute bonus request without phone update

```sql
DECLARE @Result INT
EXEC @Result = [Customer].[BonusRequest]
    @CID   = 12345,
    @Email = 'user@example.com'
SELECT @Result AS ReturnCode
```

### 8.3 Find demo customers eligible for the bonus (not yet verified, low balance)

```sql
SELECT
    c.CID,
    c.UserName,
    c.Email,
    c.IsEmailVerified,
    c.Credit,
    c.Registered
FROM Customer.CustomerStatic c WITH (NOLOCK)
WHERE c.IsReal = 0
AND c.IsEmailVerified = 0
AND c.Credit + ISNULL(
    (SELECT SUM(p.Amount) FROM Trade.Position p WITH (NOLOCK) WHERE p.CID = c.CID), 0
) < 300
ORDER BY c.Registered DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3 (1, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.BonusRequest | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.BonusRequest.sql*
