# Customer.GetNotificationSettings

> Returns the current email notification opt-in/opt-out status for a specific set of email templates for a given customer, using XML to pass the requested template IDs.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @TemplatesXML; returns TemplateID + IsEnabled pairs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetNotificationSettings retrieves a customer's current notification preference state for a specified list of email template types. The caller passes a set of template IDs in XML format; the procedure returns which of those templates the customer has opted in to or out of.

The procedure exists to support the notification preference UI and the email dispatch pipeline. Before sending a specific email type to a customer, the system can call this procedure to check whether that customer has disabled that template. If no row exists for a given template/CID combination, the customer has not explicitly set a preference - callers treat absence as "enabled" per Customer.EmailSettings business logic.

The MAXDOP 1 hint forces single-threaded execution, preventing query plan parallelism on what is expected to be a small, targeted result set.

---

## 2. Business Logic

### 2.1 XML Template ID Parsing

**What**: Accepts a list of template IDs via XML instead of a table-valued parameter, shredding them into a temp table for the join.

**Columns/Parameters Involved**: `@TemplatesXML`, `TemplateID`

**Rules**:
- XML structure expected: `<Root><TemplateID>651</TemplateID><TemplateID>652</TemplateID>...</Root>`
- `.nodes('Root/TemplateID')` shreds each element to a row in #IDs temp table
- Template IDs are cast to INT from the XML text content
- Known TemplateIDs in system: 651, 652, 653, 655, 656, 657, 658 (from EmailSettings distribution data)

### 2.2 Preference Lookup with MAXDOP 1

**What**: Joins the parsed template list against EmailSettings to return current preferences.

**Columns/Parameters Involved**: `@CID`, `TemplateID`, `IsEnabled`

**Rules**:
- INNER JOIN between EmailSettings and #IDs - only returns rows where preference was explicitly set
- Templates not present in EmailSettings for this CID are NOT returned (not in result = treat as enabled)
- MAXDOP 1: single-threaded execution hint for targeted small-result queries
- IsEnabled values: 1 = customer accepts this notification, 0 = customer has opted out

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Input: Customer ID whose notification preferences to retrieve. |
| 2 | @TemplatesXML | XML | NO | - | CODE-BACKED | Input: XML document containing the list of template IDs to check. Expected format: `<Root><TemplateID>651</TemplateID>...</Root>`. Only preferences for IDs in this list are returned. |
| 3 | TemplateID | int (output) | NO | - | VERIFIED | Email template identifier. From Customer.EmailSettings. Known values: 651, 652, 653, 655, 656, 657, 658. Each ID represents a specific category of email notification (e.g., referral alerts, promotional emails). |
| 4 | IsEnabled | bit (output) | NO | - | VERIFIED | Whether the customer has this template enabled. 1 = opted in (will receive this email type). 0 = opted out (suppress this email type for this customer). Inherited from Customer.EmailSettings: "Per-template opt-in/out: IsEnabled=0 means customer has opted out, no row means system treats as enabled." |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / TemplateID | Customer.EmailSettings | FROM + INNER JOIN | Source of notification preference data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (DB role) | - | GRANT EXECUTE | BI admin access |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetNotificationSettings (procedure)
└── Customer.EmailSettings (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.EmailSettings | Table | FROM + INNER JOIN to get IsEnabled per TemplateID for @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins | DB Role/User | EXECUTE permission granted |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (MAXDOP 1) | Query Hint | Forces single-threaded execution on the main SELECT - prevents unnecessary parallelism on this targeted lookup |

---

## 8. Sample Queries

### 8.1 Check notification settings for templates 651 and 652
```sql
DECLARE @xml XML = '<Root><TemplateID>651</TemplateID><TemplateID>652</TemplateID></Root>'
EXEC Customer.GetNotificationSettings @CID = 12345, @TemplatesXML = @xml;
```

### 8.2 Check all standard notification template settings
```sql
DECLARE @xml XML = '<Root>
  <TemplateID>651</TemplateID>
  <TemplateID>652</TemplateID>
  <TemplateID>653</TemplateID>
  <TemplateID>655</TemplateID>
  <TemplateID>656</TemplateID>
  <TemplateID>657</TemplateID>
  <TemplateID>658</TemplateID>
</Root>'
EXEC Customer.GetNotificationSettings @CID = 12345, @TemplatesXML = @xml;
```

### 8.3 Direct query equivalent for a single template
```sql
SELECT TemplateID, IsEnabled
FROM Customer.EmailSettings WITH (NOLOCK)
WHERE CID = 12345
  AND TemplateID IN (651, 652, 653, 655, 656, 657, 658);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetNotificationSettings | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetNotificationSettings.sql*
