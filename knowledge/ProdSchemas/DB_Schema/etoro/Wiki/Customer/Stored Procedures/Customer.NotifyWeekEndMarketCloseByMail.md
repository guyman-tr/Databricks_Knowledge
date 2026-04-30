# Customer.NotifyWeekEndMarketCloseByMail

> Sends a weekend market close notification email to a customer by reading their Email and IsReal flags from Customer.Customer and dispatching via Maintenance.SendMail (TemplateID=3, 0 params).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID -> Maintenance.SendMail (TemplateID=3) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.NotifyWeekEndMarketCloseByMail sends a standardized weekend market close notification email to a specific customer. The email uses a fixed template (TemplateID=3) with no dynamic parameters - the message content is entirely defined by the template itself. Only the recipient email address (from Customer.Customer) and the IsReal flag (to control routing) are read from the database.

This procedure is the per-customer delivery vehicle for the weekend market close notification. It is presumably called in a loop or batch for each customer that needs to be notified when markets close for the weekend (Friday evening or weekend trading halt).

Contrast with Customer.NotifyForgotPassword (TemplateID=4, 2 dynamic params): this procedure has zero dynamic content - the template message is the same for every recipient.

---

## 2. Business Logic

### 2.1 Simple Notification Dispatch (No Dynamic Content)

**What**: Sends TemplateID=3 to the customer's registered email with no variable content substitution.

**Columns/Parameters Involved**: `Customer.Customer.Email`, `Customer.Customer.IsReal`

**Rules**:
- Reads Email and IsReal from Customer.Customer for the given CID
- Calls Maintenance.SendMail with TemplateID=3, NumberOfParams=0, @Message=NULL
- @IsReal controls real vs. test email routing (same pattern as NotifyForgotPassword)
- No XML parameter message needed - the TemplateID=3 email body is static
- Returns the SendMail answer/result code to the caller

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | integer | NO | - | VERIFIED | Internal Customer ID of the customer to notify. Used to look up Email and IsReal from Customer.Customer, and passed to Maintenance.SendMail for dispatch logging. |

**Output**: RETURN value (integer) - the answer code from Maintenance.SendMail. 0 or positive = dispatched successfully; negative = failure.

**Internal variables** (not parameters):

| # | Variable | Source | Description |
|---|----------|--------|-------------|
| 1 | @Email | Customer.Customer.Email | Recipient email address for the weekend close notification |
| 2 | @IsReal | Customer.Customer.IsReal | 1 = real customer (send to actual Email); 0 = test/non-real (Maintenance.SendMail governs behavior) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Reader (SELECT) | Reads Email and IsReal for recipient addressing |
| TemplateID=3 | Maintenance.SendMail | Caller (EXECUTE) | Dispatches the weekend market close email (static template, 0 params) |

### 5.2 Referenced By (other objects point to this)

No callers found in the codebase. Called externally by the weekend market close notification batch job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.NotifyWeekEndMarketCloseByMail (procedure)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── Maintenance.SendMail (procedure) [cross-schema]
      └── TemplateID=3 (weekend market close email template)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | SELECT Email, IsReal WHERE CID=@CID |
| Maintenance.SendMail | Procedure | Email dispatch - TemplateID=3 (weekend close), 0 params, NULL message |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: minimal procedure - no SET NOCOUNT ON, no error handling, no transaction.

---

## 8. Sample Queries

### 8.1 Send the weekend market close notification to a customer
```sql
DECLARE @result INT;
EXEC @result = Customer.NotifyWeekEndMarketCloseByMail @CID = 12345678;
SELECT @result AS SendMailResult;  -- 0 = success, negative = failure
```

### 8.2 Direct equivalent query (what the SP reads)
```sql
SELECT Email, IsReal
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678;
-- Then Maintenance.SendMail called with TemplateID=3, 0 params, NULL message
```

### 8.3 Simulate a batch notification run
```sql
-- In a batch job context: iterate customers needing notification
DECLARE @CID INT;
DECLARE cur CURSOR FOR
    SELECT CID FROM Customer.Customer WITH (NOLOCK)
    WHERE IsReal = 1 AND /* has open positions or other eligibility criteria */;
OPEN cur;
FETCH NEXT FROM cur INTO @CID;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC Customer.NotifyWeekEndMarketCloseByMail @CID = @CID;
    FETCH NEXT FROM cur INTO @CID;
END;
CLOSE cur; DEALLOCATE cur;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 7/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.NotifyWeekEndMarketCloseByMail | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.NotifyWeekEndMarketCloseByMail.sql*
