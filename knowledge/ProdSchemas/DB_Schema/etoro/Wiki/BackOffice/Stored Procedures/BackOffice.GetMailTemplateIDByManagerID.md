# BackOffice.GetMailTemplateIDByManagerID

> Returns the MailTemplateID assigned to a specific BackOffice manager, used to determine which email template is associated with that manager's communications.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ManagerID - the BackOffice manager whose mail template is retrieved |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the email template ID associated with a specific BackOffice manager. It answers: "What mail template is configured for this manager?" - enabling the notification system to send communications using the manager's assigned template, which likely controls the branding, signature, or tone of messages sent on behalf of that manager to customers.

The manager-to-mail-template relationship in `BackOffice.MailTemplates` allows each manager to be assigned a specific email template, personalizing automated outreach or ensuring the correct template is used for manager-specific customer communications (e.g., assigned account manager notifications).

**Status**: Only VIEW DEFINITION granted to PROD\BIadmins - no active EXECUTE grants to application users. The lookup logic may have been incorporated into application-layer code.

---

## 2. Business Logic

### 2.1 Manager-Specific Template Assignment

**What**: Each BackOffice manager can have a specific mail template assigned, controlling the format or branding of emails sent in that manager's context.

**Columns/Parameters Involved**: `@ManagerID`, `MailTemplateID`, `ManagerID`

**Rules**:
- Returns NULL / no rows if the manager has no entry in `BackOffice.MailTemplates`.
- A manager may have multiple MailTemplates entries (one per BackofficeTemplateID), so this could return multiple rows.
- The `ManagerID` column in `BackOffice.MailTemplates` links this to `BackOffice.Manager`.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ManagerID | INTEGER | NO | - | CODE-BACKED | Input parameter. The BackOffice manager identifier. References `BackOffice.Manager.ManagerID`. Filters `BackOffice.MailTemplates` to only the templates assigned to this manager. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MailTemplateID | INT | YES | - | CODE-BACKED | The email system template identifier assigned to this manager. May return multiple rows if the manager has multiple template assignments for different notification types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ManagerID | BackOffice.MailTemplates.ManagerID | Lookup (READ) | Filters mail templates by the assigned manager |
| @ManagerID | BackOffice.Manager | Implicit | The input ManagerID is a key from BackOffice.Manager |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No active EXECUTE grants found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetMailTemplateIDByManagerID (procedure)
└── BackOffice.MailTemplates (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.MailTemplates | Table | FROM clause; filtered by ManagerID to return the associated MailTemplateID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | No active EXECUTE grants in permissions files |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC BackOffice.GetMailTemplateIDByManagerID @ManagerID = 42
```

### 8.2 View all manager-to-mail-template assignments

```sql
SELECT ManagerID, BackofficeTemplateID, MailTemplateID
FROM BackOffice.MailTemplates WITH (NOLOCK)
WHERE ManagerID IS NOT NULL
ORDER BY ManagerID, BackofficeTemplateID;
```

### 8.3 Find managers without a mail template assignment

```sql
SELECT m.ManagerID, m.FirstName, m.LastName, m.Email
FROM BackOffice.Manager m WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM BackOffice.MailTemplates mt WITH (NOLOCK)
    WHERE mt.ManagerID = m.ManagerID
)
ORDER BY m.ManagerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 9.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetMailTemplateIDByManagerID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetMailTemplateIDByManagerID.sql*
