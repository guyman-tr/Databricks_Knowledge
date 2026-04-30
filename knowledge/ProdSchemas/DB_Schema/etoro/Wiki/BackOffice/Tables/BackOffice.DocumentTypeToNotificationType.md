# BackOffice.DocumentTypeToNotificationType

> Sparse configuration mapping document types to approval notification templates - currently only 1 row mapping SelfieLiveliness (DocumentTypeID=18) to the "0091SelfieAcceptance" notification.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (DocumentTypeID, NotificationType) - composite CLUSTERED PK |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 1 active (1 clustered composite PK) |

---

## 1. Business Meaning

BackOffice.DocumentTypeToNotificationType is a configuration table that maps document types to their associated notification template names. Unlike DocumentRejectReasonToNotificationType (which maps rejection reasons to email templates), this table appears to map document types to approval or acceptance notifications.

As of 2026-03-17, the table has exactly 1 row: DocumentTypeID=18 (SelfieLiveliness) maps to NotificationType="0091SelfieAcceptance". This maps the selfie liveliness document type to an acceptance notification sent when a customer's selfie liveliness check is approved.

The NotificationType column stores a string name directly (not a foreign key to Dictionary.NotificationTypeName), suggesting it references a notification template identifier from a separate system. The only FK is on DocumentTypeID to Dictionary.DocumentType.

No stored procedures or views in the BackOffice SSDT repo reference this table directly - consumed by the application/notification layer.

---

## 2. Business Logic

### 2.1 Document Approval Notification Routing

**What**: Maps a document type to the notification template sent on successful verification/acceptance.

**Columns Involved**: `DocumentTypeID`, `NotificationType`

**Rules**:
- Application looks up the NotificationType string for a given DocumentTypeID when an approval notification needs to be sent.
- Currently only SelfieLiveliness (18) has a mapping - other document types may send no approval notification, or use other mechanisms.
- NotificationType="0091SelfieAcceptance" appears to be a notification template code (prefixed "0091", suggesting a template catalog numbering system).

---

## 3. Data Overview

1 row as of 2026-03-17:

| DocumentTypeID | DocumentType | NotificationType | Meaning |
|----------------|-------------|-----------------|---------|
| 18 | SelfieLiveliness | 0091SelfieAcceptance | When a customer's liveliness selfie check is approved, send the "0091SelfieAcceptance" notification email. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentTypeID | int | NO | - | VERIFIED | Document type whose approval triggers a notification. FK (WITH CHECK) to Dictionary.DocumentType(DocumentTypeID). Leading key of composite CLUSTERED PK. Currently only value is 18 (SelfieLiveliness). |
| 2 | NotificationType | varchar(50) | NO | - | CODE-BACKED | Notification template name/code. Part of composite PK. Stored as a string, not a FK to Dictionary.NotificationTypeName (which uses NotificationTypeID integer). Value "0091SelfieAcceptance" suggests a template catalog with numeric prefixes. Max 50 chars. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentTypeID | Dictionary.DocumentType | FK (WITH CHECK) | Document type whose approval triggers notification |
| NotificationType | (external notification system) | Implicit | Template name in the notification catalog |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views reference this table in the BackOffice SSDT repo. Consumed by application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.DocumentTypeToNotificationType (config table)
- FK target: Dictionary.DocumentType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.DocumentType | Table | FK on DocumentTypeID |

### 6.2 Objects That Depend On This

None found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_DocumentTypeToNotificationType | CLUSTERED PK | DocumentTypeID ASC, NotificationType ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOffice_DocumentTypeToNotificationType | PK | Uniqueness of (DocumentTypeID, NotificationType) |
| FK_BackOffice_DocumentTypeToNotificationType_DocumentTypeID | FK (WITH CHECK) | DocumentTypeID -> Dictionary.DocumentType(DocumentTypeID) |

---

## 8. Sample Queries

### 8.1 Get notification for a given document type
```sql
SELECT DocumentTypeID, NotificationType
FROM BackOffice.DocumentTypeToNotificationType WITH (NOLOCK)
WHERE DocumentTypeID = @DocumentTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.DocumentTypeToNotificationType | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.DocumentTypeToNotificationType.sql*
