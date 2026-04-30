# Customer.IsNeedToAddMail

> Returns the IsEnabled flag from Customer.EmailSettings for a specific customer and email template, indicating whether the customer has opted in to receive that email type.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @TemplateID -> IsEnabled from Customer.EmailSettings |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.IsNeedToAddMail checks whether a specific customer has opted in to receive a particular email notification type. It queries Customer.EmailSettings (which stores per-customer, per-template opt-in/opt-out preferences) and returns the IsEnabled flag for the given CID and TemplateID combination.

Called by the email notification system to determine whether to send a specific email to a customer before dispatching. If no row exists for the CID+TemplateID combination, no result is returned (empty set), which the caller treats as "not configured" (check calling application for fallback behavior).

Data flows: Customer.EmailSettings is populated by Customer.SetEmailSettings when customers change their notification preferences. This procedure is the read path for that data.

---

## 2. Business Logic

No complex multi-column business logic detected. See element descriptions in Section 4.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Internal Customer ID identifying the customer whose email preferences are being checked. |
| 2 | @TemplateID | int | NO | - | VERIFIED | Email template identifier. Each TemplateID represents a specific notification type (e.g., weekly report, trade confirmation, marketing). See Customer.EmailSettings.TemplateID for the full template catalog. |

**Output column** (SELECT result set):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | IsEnabled | bit | NO | - | VERIFIED | 1 = customer has opted in to receive this email template; 0 = opted out. Returns empty result set if no row exists for this CID+TemplateID combination (template not yet configured for this customer). See Customer.EmailSettings.IsEnabled. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @TemplateID | Customer.EmailSettings | Reader (SELECT) | Point lookup of email opt-in status for a specific customer and template |

### 5.2 Referenced By (other objects point to this)

No callers found in the codebase. Called externally by the email dispatch service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.IsNeedToAddMail (procedure)
└── Customer.EmailSettings (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.EmailSettings | Table | SELECT IsEnabled WHERE CID=@CID AND TemplateID=@TemplateID |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: no SET NOCOUNT ON and no BEGIN...END block.

---

## 8. Sample Queries

### 8.1 Check if a customer should receive a specific email template
```sql
EXEC Customer.IsNeedToAddMail @CID = 12345678, @TemplateID = 5;
-- Returns IsEnabled=1 (send), IsEnabled=0 (don't send), or empty set (not configured)
```

### 8.2 Direct equivalent query for debugging
```sql
SELECT IsEnabled
FROM Customer.EmailSettings WITH (NOLOCK)
WHERE CID = 12345678
  AND TemplateID = 5;
```

### 8.3 Check all email preferences for a customer
```sql
SELECT TemplateID, IsEnabled
FROM Customer.EmailSettings WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY TemplateID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.IsNeedToAddMail | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.IsNeedToAddMail.sql*
