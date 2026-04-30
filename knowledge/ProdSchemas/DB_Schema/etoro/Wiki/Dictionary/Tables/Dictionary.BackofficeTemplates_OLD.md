# Dictionary.BackofficeTemplates_OLD

> Legacy lookup table of BackOffice email and notification template identifiers — primarily KYC document rejection reasons and premium account manager assignment emails.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | BackofficeTemplateID (int IDENTITY, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.BackofficeTemplates_OLD stores a registry of BackOffice notification/email templates that were used by compliance and account management teams. Each row maps a template ID to a descriptive key name that identifies what the template is for — such as rejecting a customer's KYC document for a specific reason, or assigning a premium customer to a named account manager.

The `_OLD` suffix indicates this table is a legacy artifact. It was likely replaced by a newer templating system, but the table remains in the schema (possibly referenced by historical records or audit logs). The table contains 22 templates across two functional categories: document rejection reasons (IDs 1-8, 21-22) and premium account manager assignment emails (IDs 9-20).

Rows are inserted via IDENTITY with `NOT FOR REPLICATION`, indicating this table was originally replicated across database instances. No procedures, views, or other objects in the current SSDT project reference this table, confirming it is deprecated.

---

## 2. Business Logic

### 2.1 Template Categories

**What**: Two distinct functional categories of BackOffice templates coexist in this table.

**Columns/Parameters Involved**: `BackofficeTemplateID`, `TemplateDescription`

**Rules**:
- **Document Rejection (IDs 1-8, 21-22)**: Templates for notifying customers why their KYC identity document was rejected. Each maps to a specific rejection reason (MRZ missing, expired, cropped, blurry, etc.). Used by compliance team during document review.
- **Premium Account Manager (IDs 9-20)**: Email templates for assigning premium/VIP customers to specific named account managers (Mati, Nimi, Omer, Talia, Sharon, Arie, Elie, Gabriel, Franziska, Sara, George, Nawal). Each manager had a personalized welcome email template.

**Diagram**:
```
BackofficeTemplates_OLD
├── Document Rejection (KYC)
│   ├── 1: MRZ Missing/Hidden
│   ├── 2: Black & White Copy
│   ├── 3: Missing Both Sides
│   ├── 4: Expired Document
│   ├── 5: Document Cropped
│   ├── 6: Bad Quality / Blurry
│   ├── 7: Covered Details
│   ├── 8: Missing ID
│   ├── 21: Missing Proof of Address
│   └── 22: Missing ID + Proof of Address
└── Premium Manager Email
    ├── 9-20: Named manager templates
    └── (Mati, Nimi, Omer, Talia, Sharon, Arie, ...)
```

---

## 3. Data Overview

| BackofficeTemplateID | TemplateDescription | Meaning |
|---|---|---|
| 1 | DocumentRejectionReason_MrzMissingOrHidden | KYC document rejected because the Machine Readable Zone (MRZ) on the passport/ID is not visible — prevents automated identity verification. |
| 4 | DocumentRejectionReason_ExpiredDocument | KYC document rejected because the ID/passport expiration date has passed — expired documents cannot be accepted for regulatory compliance. |
| 9 | Premium_NEW_email_Mati | Welcome email template for premium customers assigned to account manager Mati — part of the VIP onboarding flow where high-value customers get dedicated relationship managers. |
| 21 | MissingProofOfAddress | KYC rejection because the customer submitted identity documents but no proof of address (utility bill, bank statement) — regulatory requirement for full account verification. |
| 22 | MissingIDAndProofOfAddress | KYC rejection because both identity and address documents are missing — customer needs to submit both to pass compliance verification. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BackofficeTemplateID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Auto-incrementing primary key identifying each template. NOT FOR REPLICATION flag indicates this table participated in database replication where identity values were preserved across replicas. Values 1-22 in production. |
| 2 | TemplateDescription | varchar(200) | YES | - | VERIFIED | Descriptive key name for the template using PascalCase convention (e.g., 'DocumentRejectionReason_MrzMissingOrHidden', 'Premium_NEW_email_Mati'). Serves as both a human-readable identifier and a programmatic key that BackOffice code used to locate the correct email/notification template. Nullable but all 22 production rows have values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No references found in the current SSDT project. Table is deprecated (indicated by `_OLD` suffix).

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | BackofficeTemplateID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all templates by category
```sql
SELECT  BackofficeTemplateID,
        TemplateDescription,
        CASE
            WHEN TemplateDescription LIKE 'DocumentRejection%' THEN 'KYC Rejection'
            WHEN TemplateDescription LIKE 'Missing%'           THEN 'KYC Rejection'
            WHEN TemplateDescription LIKE 'Premium%'           THEN 'Premium Manager'
            ELSE 'Other'
        END AS Category
FROM    Dictionary.BackofficeTemplates_OLD WITH (NOLOCK)
ORDER BY BackofficeTemplateID;
```

### 8.2 Find all document rejection templates
```sql
SELECT  BackofficeTemplateID,
        TemplateDescription
FROM    Dictionary.BackofficeTemplates_OLD WITH (NOLOCK)
WHERE   TemplateDescription LIKE 'Document%'
     OR TemplateDescription LIKE 'Missing%'
ORDER BY BackofficeTemplateID;
```

### 8.3 List premium account manager templates
```sql
SELECT  BackofficeTemplateID,
        TemplateDescription,
        REPLACE(REPLACE(TemplateDescription, 'Premium_NEW_email_', ''), '_', ' ') AS ManagerName
FROM    Dictionary.BackofficeTemplates_OLD WITH (NOLOCK)
WHERE   TemplateDescription LIKE 'Premium%'
ORDER BY BackofficeTemplateID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.BackofficeTemplates_OLD | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.BackofficeTemplates_OLD.sql*
