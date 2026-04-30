# BackOffice.MailTemplates

> 23-row configuration table mapping BackOffice internal template IDs to external mail system template IDs. Two use cases: (1) KYC document rejection/request templates (IDs 1-8, 21-22) used for automated customer notifications, and (2) Premium account manager personal email templates (IDs 9-20, 23) where each row is tied to a specific manager via ManagerID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | BackofficeTemplateID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 1 active (1 clustered PK) |

---

## 1. Business Meaning

BackOffice.MailTemplates is a configuration bridge between the BackOffice system's internal template identifiers and an external email delivery system's template IDs (MailTemplateID). The external system owns the actual email content/layout; this table stores which external template ID to use for a given BackOffice operation.

**Two distinct categories of templates**:

**Category 1 - KYC Document Templates (IDs 1-8, 21-22, ManagerID=NULL)**:
These are system-level templates used when customer documents are rejected or missing. They map document rejection scenarios to specific notification email layouts. The template descriptions align closely with the rejection reason names from Dictionary.DocumentRejectReason (e.g., DocumentRejectionReason_ExpiredDocument, DocumentRejectionReason_DocumentCropped).

**Category 2 - Premium Account Manager Templates (IDs 9-20, 23, ManagerID SET)**:
Each row corresponds to a specific premium account manager's personal email template - an email sent "from" that manager to their assigned VIP/premium customers. The ManagerID column links the template to a specific BackOffice.Manager agent. GetMailTemplateIDByManagerID retrieves the template for a given manager. Template descriptions follow the pattern "Premium_NEW_email_{ManagerFirstName}".

**Access patterns**:
- `GetMailTemplateIDByBackofficeTemplateID(@BackofficeTemplateID)` - resolves MailTemplateID for a given BackOffice operation ID. Used when the calling code knows which operation triggered the email.
- `GetMailTemplateIDByManagerID(@ManagerID)` - resolves MailTemplateID for a given manager. Used when sending a personalized premium email from a specific agent.

---

## 2. Business Logic

### 2.1 Template Lookup by BackOffice ID

**What**: Returns the external MailTemplateID for a given BackofficeTemplateID.

**Columns Involved**: `BackofficeTemplateID`, `MailTemplateID`

**Rules**:
- Simple SELECT WHERE BackofficeTemplateID = @BackofficeTemplateID.
- Calling code uses the returned MailTemplateID to trigger the email in the external mail system.

### 2.2 Template Lookup by Manager

**What**: Returns the external MailTemplateID for a given BackOffice agent's personal template.

**Columns Involved**: `ManagerID`, `MailTemplateID`

**Rules**:
- Simple SELECT WHERE ManagerID = @ManagerID.
- ManagerID is not unique-constrained - if a manager had multiple templates, multiple rows would be returned. In practice, one template per manager.
- Used when a premium service workflow needs to send a personalized email "from" a specific account manager.

---

## 3. Data Overview

23 rows as of 2026-03-17:

**KYC / Document Templates (ManagerID=NULL)**:

| BackofficeTemplateID | MailTemplateID | TemplateDescription |
|---------------------|----------------|---------------------|
| 1 | 668 | DocumentRejectionReason_MrzMissingOrHidden |
| 2 | 667 | DocumentRejectionReason_BlackAndWhiteCopy |
| 3 | 665 | DocumentRejectionReason_MissingBothSides |
| 4 | 670 | DocumentRejectionReason_ExpiredDocument |
| 5 | 666 | DocumentRejectionReason_DocumentCropped |
| 6 | 664 | DocumentRejectionReason_BadQualityBlurryPicture |
| 7 | 669 | DocumentRejectionReason_CoveredDetails / MissingID |
| 8 | 671 | DocumentRejectionReason_MissingID |
| 21 | 693 | MissingProofOfAddress |
| 22 | 694 | MissingIDAndProofOfAddress |

**Premium Account Manager Templates (ManagerID SET)**:

| BackofficeTemplateID | MailTemplateID | TemplateDescription | ManagerID |
|---------------------|----------------|---------------------|-----------|
| 9 | 703 | Premium_NEW_email_Mati | 624 |
| 10 | 704 | Premium_NEW_email_Nimi | 405 |
| 11 | 705 | Premium_NEW_email_Omer | 634 |
| 12 | 706 | Premium_NEW_email_Talia | 276 |
| 13 | 707 | Premium_NEW_email_Sharon | 620 |
| 14 | 708 | Premium_NEW_email_Arie | 451 |
| 15 | 709 | Premium_NEW_email_Elie | 268 |
| 16 | 710 | Premium_NEW_email_Gabriel | 678 |
| 17 | 711 | Premium_NEW_email_Franziska | 597 |
| 18 | 712 | Premium_NEW_email_Sara | 368 |
| 19 | 713 | Premium_NEW_email_George | 664 |
| 20 | 714 | Premium_NEW_email_Nawal | 300 |
| 23 | 1005 | Premium_NEW_email_ES_Tali | 753 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BackofficeTemplateID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-incrementing internal template key. NOT FOR REPLICATION. CLUSTERED PK. 23 rows currently, ranging from 1 to 23. Used as the external reference for BackOffice operations that need to trigger a specific email. |
| 2 | MailTemplateID | int | YES | NULL | VERIFIED | External email system template ID. References a template in the email delivery platform (not stored in this database). Values range: 664-714 (document/premium batch) and 1005 (later addition). No FK constraint - external system. All 23 current rows have this populated (no NULLs). |
| 3 | TemplateDescription | varchar(200) | YES | NULL | VERIFIED | Human-readable name for the template. Two naming patterns: "DocumentRejectionReason_{Reason}" for KYC templates and "Premium_NEW_email_{FirstName}" for manager templates. All 23 rows populated. Max 200 chars. |
| 4 | ManagerID | int | YES | NULL | VERIFIED | BackOffice manager associated with a personal premium email template. NULL for generic/system templates (IDs 1-8, 21-22). Populated for premium manager templates (IDs 9-20, 23) - 13 distinct managers. Logical FK to BackOffice.Manager - no declared constraint. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MailTemplateID | (external email system) | Implicit | Template in external email delivery platform |
| ManagerID | BackOffice.Manager | Implicit FK | Manager whose personal email template this is |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetMailTemplateIDByBackofficeTemplateID | BackofficeTemplateID | READER | Resolves external MailTemplateID by operation type |
| BackOffice.GetMailTemplateIDByManagerID | ManagerID | READER | Resolves personal email template for a given manager |
| BackOffice.GetMailTemplateByID_OLD | BackofficeTemplateID | READER (deprecated) | Legacy procedure - marked OLD |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.MailTemplates (config table)
- Implicit reference: BackOffice.Manager (ManagerID)
- Implicit reference: external email system (MailTemplateID)
- Readers:
  |- BackOffice.GetMailTemplateIDByBackofficeTemplateID
  |- BackOffice.GetMailTemplateIDByManagerID
  |- BackOffice.GetMailTemplateByID_OLD (deprecated)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | Implicit FK on ManagerID (no declared constraint) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetMailTemplateIDByBackofficeTemplateID | Procedure | READER - looks up by operation type |
| BackOffice.GetMailTemplateIDByManagerID | Procedure | READER - looks up by manager |
| BackOffice.GetMailTemplateByID_OLD | Procedure | READER (deprecated) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Status |
|-----------|------|-------------|--------|
| PK (unnamed in DDL) | CLUSTERED PK | BackofficeTemplateID ASC | Active (ON [PRIMARY]) |

Note: The PK constraint has no explicit name in the DDL (no `CONSTRAINT [name]` syntax used) - SQL Server auto-names it. No NC indexes on MailTemplateID or ManagerID despite both being lookup targets. With only 23 rows, table scans are trivially fast.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (auto-named PK) | PK | BackofficeTemplateID uniqueness |

No FK constraints. MailTemplateID references an external system; ManagerID references BackOffice.Manager without structural enforcement.

---

## 8. Sample Queries

### 8.1 Get email template for a document rejection scenario
```sql
SELECT BackofficeTemplateID, MailTemplateID, TemplateDescription
FROM BackOffice.MailTemplates WITH (NOLOCK)
WHERE BackofficeTemplateID = @BackofficeTemplateID
```

### 8.2 Find which managers have personal email templates
```sql
SELECT mt.BackofficeTemplateID, mt.MailTemplateID,
       mt.TemplateDescription,
       bm.FirstName + ' ' + bm.LastName AS ManagerName
FROM BackOffice.MailTemplates mt WITH (NOLOCK)
JOIN BackOffice.Manager bm WITH (NOLOCK) ON bm.ManagerID = mt.ManagerID
WHERE mt.ManagerID IS NOT NULL
ORDER BY mt.BackofficeTemplateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.MailTemplates | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.MailTemplates.sql*
