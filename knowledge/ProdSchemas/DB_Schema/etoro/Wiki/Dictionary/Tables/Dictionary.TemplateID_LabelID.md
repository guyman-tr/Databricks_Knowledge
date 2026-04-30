# Dictionary.TemplateID_LabelID

> Maps email/notification template IDs to white-label brands, enabling per-label template customization.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Composite PK (TemplateID, LabelID) |
| **Row Count** | 0 (empty) |
| **Indexes** | 1 (clustered composite PK) |
| **Foreign Keys** | 1 (LabelID → Dictionary.Label) |
| **Filegroup** | DICTIONARY |

---

## 1. Business Meaning

### What It Is
Dictionary.TemplateID_LabelID is a junction table that maps notification/email template IDs to specific white-label brands (labels). It enables different eToro white-label platforms to use customized versions of the same template.

### Why It Exists
eToro operates multiple white-label brands (e.g., eToro, eToro Money, partner brands), each potentially requiring different email/notification templates. This table provides the many-to-many mapping between template IDs and labels, allowing the `Maintenance.SendMail` procedure to select the correct template for each brand.

### How It Works
When sending notifications, the system looks up which template ID applies to the target label. The composite PK ensures each template-label combination is unique. The optional `LableName` column (note: typo in DDL — "Lable" vs "Label") provides a cached label name for convenience.

**Note**: The table is currently **empty in production**, suggesting template-to-label mapping may have been moved to application configuration or is handled differently in the current architecture.

---

## 2. Business Logic

### Junction Table Pattern
```
Template (TemplateID)  ←→  Dictionary.TemplateID_LabelID  ←→  Dictionary.Label (LabelID)
```

### Current State
Empty (0 rows) — the feature may be deprecated or templates are now resolved through application-level configuration rather than database lookup.

---

## 3. Data Overview

N/A — table is empty in production.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TemplateID | int | NO | — | HIGH | Notification/email template identifier. Part of composite PK. References a template system (not a DB table — likely application-managed). |
| 2 | LabelID | int | NO | — | HIGH | FK to `Dictionary.Label.LabelID`. Identifies which white-label brand this template applies to. Part of composite PK. |
| 3 | LableName | varchar(50) | YES | — | MEDIUM | Cached label name for convenience. Note DDL typo: "Lable" instead of "Label". Nullable because it's a denormalized convenience field. |

---

## 5. Relationships

### Depends On (Explicit FK)

| Referenced Table | FK Name | Column | Referenced Column |
|-----------------|---------|--------|-------------------|
| Dictionary.Label | FK_LabelID | LabelID | LabelID |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Maintenance.SendMail (legacy) | SELECT | Template lookup by label for email sending |

---

## 6. Dependencies

### Depends On
- `Dictionary.Label` — FK on LabelID for white-label brand identification

### Depended On By
- `Maintenance.SendMail` (legacy) — reads template-to-label mapping

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_DTemplateID_LabelID | CLUSTERED PK | TemplateID ASC, LabelID ASC | FILLFACTOR 90, composite PK |

| Property | Value |
|----------|-------|
| Filegroup | DICTIONARY |
| Foreign Keys | FK_LabelID → Dictionary.Label |

---

## 8. Sample Queries

```sql
-- Get all template-label mappings (currently empty)
SELECT  tl.TemplateID,
        tl.LabelID,
        tl.LableName,
        l.LabelName
FROM    Dictionary.TemplateID_LabelID tl WITH (NOLOCK)
JOIN    Dictionary.Label l WITH (NOLOCK)
        ON tl.LabelID = l.LabelID
ORDER BY tl.TemplateID, tl.LabelID;

-- Check if a specific template exists for a label
SELECT  TemplateID,
        LableName
FROM    Dictionary.TemplateID_LabelID WITH (NOLOCK)
WHERE   LabelID = @LabelID;

-- Count templates per label
SELECT  LabelID,
        LableName,
        COUNT(*) AS TemplateCount
FROM    Dictionary.TemplateID_LabelID WITH (NOLOCK)
GROUP BY LabelID, LableName;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `TemplateID_LabelID`.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.TemplateID_LabelID | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TemplateID_LabelID.sql*
