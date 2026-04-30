# BackOffice.GetMailTemplateIDByBackofficeTemplateID

> Returns the MailTemplateID associated with a given BackOffice notification template ID, directly from the MailTemplates table without dictionary validation.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BackofficeTemplateID - the BackOffice template to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure resolves a BackOffice template ID to its corresponding mail template ID. It answers: "What email template should be used to send a specific BackOffice notification type?" - bridging the BackOffice notification system's template identifiers to the email sending infrastructure's template IDs.

The procedure is the active replacement for `BackOffice.GetMailTemplateByID_OLD`. It omits the INNER JOIN to `Dictionary.BackofficeTemplates` that the older version used, making it more permissive - it returns the `MailTemplateID` whenever `BackofficeTemplateID` exists in `BackOffice.MailTemplates`, regardless of whether the template is registered in the dictionary.

**Status**: Only VIEW DEFINITION granted to PROD\BIadmins - no active EXECUTE grants to application users. The newer `GetMailTemplateIDByBackofficeTemplateID` appears in the codebase but is not actively called through a permission grant, suggesting the mail template lookup may have been moved to application-layer logic or the feature is deprecated.

---

## 2. Business Logic

### 2.1 Direct Template ID Resolution

**What**: Single-table lookup that maps BackOffice notification template IDs to mail system template IDs.

**Columns/Parameters Involved**: `@BackofficeTemplateID`, `MailTemplateID`

**Rules**:
- Returns NULL / no rows if the given `@BackofficeTemplateID` has no entry in `BackOffice.MailTemplates`.
- Returns the `MailTemplateID` which is then used by the email/notification service to load the correct template body, subject, and localization.
- Unlike `GetMailTemplateByID_OLD`, does NOT require the template to exist in `Dictionary.BackofficeTemplates`.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BackofficeTemplateID | INTEGER | NO | - | CODE-BACKED | Input parameter. The BackOffice notification template identifier. Identifies which notification type to map (e.g., withdrawal confirmation, password reset). References `BackOffice.MailTemplates.BackofficeTemplateID`. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MailTemplateID | INT | YES | - | CODE-BACKED | The email system template identifier associated with this BackOffice notification template. Passed to the email sending service to load the correct template content. NULL / no rows if @BackofficeTemplateID has no mapping in MailTemplates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BackofficeTemplateID | BackOffice.MailTemplates | Lookup (READ) | Maps BackOffice notification template ID to mail system template ID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No EXECUTE grants found in permissions files.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetMailTemplateIDByBackofficeTemplateID (procedure)
└── BackOffice.MailTemplates (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.MailTemplates | Table | FROM clause; source of the MailTemplateID for a given BackofficeTemplateID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none active) | - | No active EXECUTE grants; replaces GetMailTemplateByID_OLD |

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
EXEC BackOffice.GetMailTemplateIDByBackofficeTemplateID @BackofficeTemplateID = 5
```

### 8.2 View all BackOffice template to mail template mappings

```sql
SELECT BackofficeTemplateID, MailTemplateID, ManagerID
FROM BackOffice.MailTemplates WITH (NOLOCK)
ORDER BY BackofficeTemplateID;
```

### 8.3 Find which BackOffice templates have mail template assignments

```sql
SELECT bt.BackofficeTemplateID,
       bt.Name AS TemplateName,
       mt.MailTemplateID
FROM Dictionary.BackofficeTemplates bt WITH (NOLOCK)
LEFT JOIN BackOffice.MailTemplates mt WITH (NOLOCK)
    ON mt.BackofficeTemplateID = bt.BackofficeTemplateID
ORDER BY bt.BackofficeTemplateID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 9.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 active callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetMailTemplateIDByBackofficeTemplateID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetMailTemplateIDByBackofficeTemplateID.sql*
