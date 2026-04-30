# Customer.NotifyForgotPassword

> Sends a "forgot password" email to a customer by reading their stored credentials from Customer.Customer and dispatching them via Maintenance.SendMail (TemplateID=4, 2 params: username + password).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID -> Maintenance.SendMail (TemplateID=4) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.NotifyForgotPassword is the legacy password recovery procedure for eToro customers. When a customer requests a forgotten password reminder, this procedure retrieves the customer's UserName and Password directly from Customer.Customer (the stored password, not a reset token) and passes them as XML parameters to the Maintenance.SendMail system, which dispatches email TemplateID=4 (the "forgot password" template) to the customer's registered email address.

The procedure returns the answer code from Maintenance.SendMail - a success/failure indicator for the email dispatch. The @IsReal flag (read from Customer.Customer) gates whether the email is sent to the real customer address or a test/sandbox recipient.

**Legacy note**: This procedure reflects an older authentication model where passwords were stored (not hashed or salted in a modern sense) and could be retrieved and emailed in plaintext. Modern systems use password reset tokens/links rather than sending stored credentials. This procedure has likely been superseded in active code paths by token-based reset flows.

---

## 2. Business Logic

### 2.1 Password Reminder Email Dispatch

**What**: Reads the customer's stored UserName and Password and emails them directly using TemplateID=4.

**Columns/Parameters Involved**: `Customer.Customer.UserName`, `Customer.Customer.Password`, `Customer.Customer.Email`, `Customer.Customer.IsReal`

**Rules**:
- Reads from Customer.Customer WITHOUT NOLOCK (consistent read for credentials)
- Builds XML parameter string via `FOR XML RAW('ParamList')`: `<ParamList><PARAM>username</PARAM><PARAM>password</PARAM></ParamList>`
- Calls Maintenance.SendMail with: @CID, @IsReal, @Email, TemplateID=4, NumberOfParams=2, @Message=XML
- @IsReal controls email routing: real customer (IsReal=1) -> sends to @Email; test account -> sandbox/no-op behavior determined by Maintenance.SendMail
- RETURN @Answer propagates the SendMail result code to the caller

### 2.2 XML Parameter Construction

**What**: Packages UserName and Password into XML for the Maintenance.SendMail template substitution engine.

**Rules**:
- `SELECT @UserName AS PARAM, @Password AS PARAM FOR XML RAW('ParamList'), ROOT('ParamList')` produces two `<PARAM>` nodes under the root
- TemplateID=4 template has two named placeholders that the SendMail engine substitutes with PARAM[1] (username) and PARAM[2] (password) respectively
- Consistent XML format with other notification procedures (e.g., NotifyWeekEndMarketCloseByMail uses 0 params with NULL message)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | integer | NO | - | VERIFIED | Internal Customer ID of the account requesting password recovery. Used to look up credentials and passed to Maintenance.SendMail for dispatch logging. |

**Output**: RETURN value (integer) - the answer code from Maintenance.SendMail. 0 or positive = dispatched successfully; negative = failure code.

**Internal variables** (not parameters):

| # | Variable | Source | Description |
|---|----------|--------|-------------|
| 1 | @UserName | Customer.Customer.UserName | Customer's registered username, sent as first PARAM in the email template |
| 2 | @Password | Customer.Customer.Password | Customer's stored password, sent as second PARAM in the email template (legacy plaintext credential) |
| 3 | @Email | Customer.Customer.Email | Recipient email address for the password reminder |
| 4 | @IsReal | Customer.Customer.IsReal | 1 = real customer (send to actual Email); 0 = test/non-real (Maintenance.SendMail governs behavior) |
| 5 | @Message | nvarchar/xml | Assembled XML parameter string passed to Maintenance.SendMail |
| 6 | @Answer | int | Return code from Maintenance.SendMail, propagated via RETURN |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Reader (SELECT) | Reads UserName, Password, Email, IsReal for the given CID |
| TemplateID=4 | Maintenance.SendMail | Caller (EXECUTE) | Dispatches the forgot-password email with 2 XML params (username, password) |

### 5.2 Referenced By (other objects point to this)

No callers found in the codebase. Called externally by the password recovery service or back-office user management.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.NotifyForgotPassword (procedure)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── Maintenance.SendMail (procedure) [cross-schema]
      └── TemplateID=4 (forgot password email template)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | SELECT UserName, Password, Email, IsReal WHERE CID=@CID |
| Maintenance.SendMail | Procedure | Email dispatch - TemplateID=4 (forgot password), 2 params (username, password) |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Send a forgot password email for a customer
```sql
DECLARE @result INT;
EXEC @result = Customer.NotifyForgotPassword @CID = 12345678;
SELECT @result AS SendMailResult;  -- 0 = success, negative = failure
```

### 8.2 Direct equivalent query for debugging (what the SP reads)
```sql
SELECT UserName, Password, Email, IsReal
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678;
-- Then Maintenance.SendMail would be called with TemplateID=4 and these values
```

### 8.3 Check which customers recently used password recovery (via SendMail logs)
```sql
-- Via Maintenance.SendMail audit/log table if available
-- Or check History.Customer for password-related change events
SELECT TOP 10 CID, UserName, Email
FROM Customer.Customer WITH (NOLOCK)
WHERE CID IN (/* CIDs from external password reset log */)
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.NotifyForgotPassword | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.NotifyForgotPassword.sql*
