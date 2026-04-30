# dbo.tblaff_MessageTemplate

> Localized email message templates for affiliate onboarding communications - pending application and welcome messages in multiple languages.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | MessageTemplateID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table stores email message templates used during the affiliate onboarding process. Each row contains both a "pending member" message (sent when an affiliate application is under review) and a "new member" message (sent when the application is accepted). Templates are localized per language, with each LanguageID pointing to tblaff_Languages.

Without this table, the platform could not send localized onboarding emails to affiliates in their preferred language. Currently 9 templates covering the primary platform languages. Managed by admin users with Preferences_EmailMessages permission.

---

## 2. Business Logic

### 2.1 Dual-Message Onboarding Flow

**What**: Each template contains two message variants for different stages of the onboarding process.

**Columns/Parameters Involved**: `PendingMemberMessageSubject`, `PendingMemberMessageBody`, `NewMemberMessageSubject`, `NewMemberMessageBody`

**Rules**:
- PendingMember messages are sent immediately when an affiliate submits their application
- NewMember messages are sent when the admin approves the application
- Both share the same LanguageID to ensure consistent language experience
- MessageTemplate (ntext) may contain an additional/legacy template format

---

## 3. Data Overview

| MessageTemplateID | LanguageID | PendingMemberMessageSubject | NewMemberMessageSubject | Meaning |
|-------------------|-----------|----------------------------|------------------------|---------|
| 1 | 1 (English) | Your eToro Partners Program Application Status | Thanks for joining eToro Partners program! | English onboarding emails - default template for most affiliates |
| 2 | 2 (Spanish) | Your eToro Partners Program Application Status | Gracias por unirse al programa de socios de eToro! | Spanish localization for LATAM and Spanish market affiliates |
| 5 | 6 (Russian) | Your eToro Partners Program Application Status | (Russian welcome text) | Russian localization for CIS market affiliates |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MessageTemplateID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Auto-incrementing template identifier. |
| 2 | MessageTemplateName | nvarchar(150) | NO | - | CODE-BACKED | Template name/identifier. Currently blank for all rows - not actively used for display. |
| 3 | MessageTemplate | ntext | YES | - | CODE-BACKED | Legacy template body field. May contain an older format of the email template. ntext type indicates this predates nvarchar(max). |
| 4 | LanguageID | int | YES | - | CODE-BACKED | FK to dbo.tblaff_Languages. Determines which language this template is written in. Each language has one template row. |
| 5 | PendingMemberMessageBody | ntext | YES | - | CODE-BACKED | HTML email body sent when an affiliate's application is pending review. Contains branding, instructions, and expected timeline. |
| 6 | NewMemberMessageBody | ntext | YES | - | CODE-BACKED | HTML email body sent when an affiliate's application is approved. Contains welcome message, getting started guide, and portal login instructions. |
| 7 | PendingMemberMessageSubject | nvarchar(150) | YES | - | CODE-BACKED | Email subject line for the pending application notification. Mostly English across all templates (localization gap). |
| 8 | NewMemberMessageSubject | nvarchar(150) | YES | - | CODE-BACKED | Email subject line for the welcome/acceptance email. Localized per language. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LanguageID | dbo.tblaff_Languages | Implicit FK | Template language - determines which affiliates receive this template variant. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no hard dependencies (LanguageID is implicit).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblAff_MessageTemplate | CLUSTERED PK | MessageTemplateID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all templates with their language
```sql
SELECT mt.MessageTemplateID, l.LanguageName, mt.PendingMemberMessageSubject, mt.NewMemberMessageSubject
FROM dbo.tblaff_MessageTemplate mt WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Languages l WITH (NOLOCK) ON mt.LanguageID = l.LanguageID
ORDER BY l.LanguageName
```

### 8.2 Get template for a specific language
```sql
SELECT PendingMemberMessageSubject, PendingMemberMessageBody,
       NewMemberMessageSubject, NewMemberMessageBody
FROM dbo.tblaff_MessageTemplate WITH (NOLOCK)
WHERE LanguageID = 1
```

### 8.3 Find languages missing templates
```sql
SELECT l.LanguageID, l.LanguageName
FROM dbo.tblaff_Languages l WITH (NOLOCK)
LEFT JOIN dbo.tblaff_MessageTemplate mt WITH (NOLOCK) ON l.LanguageID = mt.LanguageID
WHERE mt.MessageTemplateID IS NULL
  AND l.IsCommunicationLanguage = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_MessageTemplate | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_MessageTemplate.sql*
