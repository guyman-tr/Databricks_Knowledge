# BackOffice.GetEnglishMessageTemplate

> View exposing active (non-hidden) message templates with their English-language message text, joining the template catalog with its English translation and filtering out hidden message types.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | MessageTemplateID (from Maintenance.MessageTemplate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetEnglishMessageTemplate` provides a read view of all active (non-hidden) message templates together with their English-language message body. It merges three source tables:

1. **Maintenance.MessageTemplate** (`MMST`): The template catalog - template metadata including which MessageType it belongs to, the promotion type, name, parameter count, retention flag, active status, and description.

2. **Dictionary.MessageType** (`DMST`): Message type lookup - filters to `IsHidden = 0` to exclude hidden/deprecated message types.

3. **Maintenance.MessageTemplateEn** (`MMEN`): English language content - the actual English message text for each template. LEFT OUTER JOIN - templates without an English translation still appear (with NULL Message).

This view feeds the back-office template management UI and any functionality that needs to display available message templates with their English content (e.g., for review, configuration, or bulk sending workflows).

---

## 2. Business Logic

### 2.1 Active Template Projection with English Content

**What**: Returns all templates for non-hidden message types, with English text if available.

**Rules**:
- `WHERE MMST.MessageTypeID = DMST.MessageTypeID` - INNER JOIN on MessageType (filters by hidden status).
- `AND DMST.IsHidden = 0` - only templates for active (not hidden) message types appear.
- `LEFT OUTER JOIN Maintenance.MessageTemplateEn` - templates without English translation return NULL for Message column.
- No filter on MMST.IsActive - both active and inactive templates are returned. Callers must filter if needed.
- PromotionTypeID is passed through - allows filtering by promotion category.

---

## 3. Data Overview

Row count = Maintenance.MessageTemplate rows joined to non-hidden Dictionary.MessageType, with optional English text. A reference/configuration table - not a large operational table.

---

## 4. Elements

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | MessageTemplateID | int | CODE-BACKED | Primary key of the message template. FK from Maintenance.MessageTemplate. |
| 2 | MessageTypeID | int | CODE-BACKED | Type/category of message this template belongs to. FK to Dictionary.MessageType. Only non-hidden types appear. |
| 3 | PromotionTypeID | int | CODE-BACKED | Promotion category ID associated with this template, if applicable. |
| 4 | Name | nvarchar | CODE-BACKED | Internal name/identifier of the template. |
| 5 | NumberOfParams | int | CODE-BACKED | Number of variable parameters this template accepts (for parameterized message substitution). |
| 6 | Retention | bit | CODE-BACKED | Flag indicating whether this is a retention-type message template. |
| 7 | IsActive | bit | CODE-BACKED | Whether the template is currently active. Both active and inactive templates are returned by this view. |
| 8 | Description | nvarchar | CODE-BACKED | Human-readable description of what this template is used for. |
| 9 | Message | nvarchar | YES | CODE-BACKED | The English-language message body/text. NULL if no English translation exists in Maintenance.MessageTemplateEn. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Template metadata | Maintenance.MessageTemplate | Base Table | All template fields except Message |
| MessageTypeID filter | Dictionary.MessageType | INNER JOIN | Filters out hidden message types (IsHidden=0) |
| Message | Maintenance.MessageTemplateEn | LEFT OUTER JOIN | English message text (NULL if not translated) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No BackOffice SP consumers identified in SSDT repo) | - | - | Consumed by application layer for template management and message sending workflows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetEnglishMessageTemplate (view)
+-- Maintenance.MessageTemplate (cross-schema)
+-- Dictionary.MessageType (cross-schema, IsHidden filter)
+-- Maintenance.MessageTemplateEn (cross-schema, LEFT JOIN)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.MessageTemplate | Table (cross-schema) | Base template catalog |
| Dictionary.MessageType | Table (cross-schema) | INNER JOIN - filters to IsHidden=0 |
| Maintenance.MessageTemplateEn | Table (cross-schema) | LEFT OUTER JOIN - English message text |

### 6.2 Objects That Depend On This

No stored procedure consumers identified in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Performance depends on indexes on Maintenance.MessageTemplate and Dictionary.MessageType.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 List all active message templates with English content

```sql
SELECT MessageTemplateID, MessageTypeID, Name, Message, IsActive
FROM BackOffice.GetEnglishMessageTemplate WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY Name;
```

### 8.2 Find templates without English translation

```sql
SELECT MessageTemplateID, Name, MessageTypeID
FROM BackOffice.GetEnglishMessageTemplate WITH (NOLOCK)
WHERE Message IS NULL;
```

### 8.3 Get templates for a specific message type

```sql
SELECT MessageTemplateID, Name, NumberOfParams, Message
FROM BackOffice.GetEnglishMessageTemplate WITH (NOLOCK)
WHERE MessageTypeID = 5
  AND IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this view.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11 (DDL, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetEnglishMessageTemplate | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetEnglishMessageTemplate.sql*
