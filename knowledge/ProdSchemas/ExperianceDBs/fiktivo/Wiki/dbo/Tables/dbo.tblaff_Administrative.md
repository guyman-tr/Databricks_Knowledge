# dbo.tblaff_Administrative

> System configuration table holding global affiliate platform settings including admin credentials, website branding, tracking parameters, and default notification templates.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | UserID (INT IDENTITY, unique NC index - no PK) |
| **Partition** | No |
| **Indexes** | 2 active (NC unique on UserID, NC on AffiliateTypeID) |

---

## 1. Business Meaning

This is a singleton configuration table (1 row) that stores global settings for the affiliate platform. It defines the master administrator account, platform branding (website name/URL), tracking behavior (click uniqueness window, cookie lifetime, impression counting), and email notification templates for affiliate lifecycle events.

The table acts as the central configuration store read by many components of the affiliate system. Changes to this table affect all affiliates and all tracking behavior platform-wide. It is the equivalent of a "settings" table for the entire affiliate management system.

The single row contains the master admin credentials (masked with dynamic data masking for security), the default affiliate type assigned to new registrations, and HTML email templates for new member welcome, pending review, and rejection notifications.

---

## 2. Business Logic

### 2.1 Tracking Configuration

**What**: Global parameters that control how affiliate clicks and impressions are tracked.

**Columns/Parameters Involved**: `UniqueClickHour`, `CookieExpiration`, `TrackBannerImpressions`, `HTTP_REFERER`

**Rules**:
- UniqueClickHour defines the window (in hours) for deduplicating clicks - a second click from the same visitor within this window is not counted
- CookieExpiration defines how long (in days) the affiliate tracking cookie persists in the visitor's browser
- TrackBannerImpressions=1 enables counting banner display events (not just clicks)
- HTTP_REFERER controls whether the system validates the HTTP referer header for anti-fraud purposes

### 2.2 Affiliate Onboarding Templates

**What**: Email templates sent during affiliate lifecycle events.

**Columns/Parameters Involved**: `NewMemberMessage`, `PendingMemberMessage`, `RejectedMemberMessage`, `NewSaleMessage`

**Rules**:
- NewMemberMessage is sent when an affiliate successfully registers and is approved
- PendingMemberMessage is sent when NewMembersRequireValidation=1 and the affiliate is awaiting review
- RejectedMemberMessage is sent when an admin denies an affiliate application
- NewSaleMessage is sent to the admin when a new sale is attributed to an affiliate (if EmailAdministratorSaleNotification=1)

---

## 3. Data Overview

| UserID | AdministratorName | WebSiteName | AffiliateTypeID | Meaning |
|---|---|---|---|---|
| 1 | fiktivo | eToro Partners | 851 | The single configuration row - defines "eToro Partners" as the platform brand with affiliate type 851 as the default for new registrations |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserID | int | - | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing ID for the admin configuration record. In practice always 1 since this is a singleton table. |
| 2 | AdministratorName | nvarchar(10) | YES | - | VERIFIED | Master administrator username. MASKED with default() for dynamic data masking security. |
| 3 | AdministratorPassword | nvarchar(10) | YES | - | VERIFIED | Master administrator password. MASKED with default() for dynamic data masking security. |
| 4 | AdministratorEmail | nvarchar(255) | YES | - | VERIFIED | Email address of the master administrator. Receives sale notifications when enabled. MASKED with default(). |
| 5 | MailServer | nvarchar(255) | YES | - | CODE-BACKED | SMTP mail server address for sending affiliate notification emails. |
| 6 | WebSiteURL | nvarchar(255) | YES | - | VERIFIED | URL of the affiliate platform landing page. Included in email templates and affiliate portal branding. |
| 7 | WebSiteName | nvarchar(255) | YES | - | VERIFIED | Display name of the affiliate platform. Used in email headers and portal branding (e.g., "eToro Partners"). |
| 8 | NewMembersRequireValidation | bit | NO | 0 | VERIFIED | Controls whether new affiliate registrations require admin approval. 1=manual review required before activation, 0=auto-approve on registration. |
| 9 | AllowUsersEditing | bit | NO | 0 | CODE-BACKED | Controls whether affiliates can edit their own profile details in the portal. 1=self-service editing allowed, 0=admin-only changes. |
| 10 | DomainURL | nvarchar(255) | YES | - | CODE-BACKED | Domain URL for affiliate tracking links. The base domain used to construct affiliate referral URLs. |
| 11 | UniqueClickHour | int | YES | 0 | VERIFIED | Deduplication window in hours for affiliate click tracking. A second click from the same visitor within this window is not counted as a new click. |
| 12 | CookieExpiration | int | YES | 0 | VERIFIED | Lifetime of the affiliate tracking cookie in days. Determines how long after an initial click the affiliate still receives attribution for customer conversions. |
| 13 | EmailAdministratorSaleNotification | bit | NO | 0 | CODE-BACKED | Controls whether the admin receives email notifications for each new sale. 1=send notification to AdministratorEmail, 0=no notifications. |
| 14 | HTTP_REFERER | bit | YES | 0 | CODE-BACKED | Controls HTTP referer validation for anti-fraud. 1=validate referer headers on tracking requests, 0=skip validation. |
| 15 | TrackBannerImpressions | bit | NO | 1 | VERIFIED | Controls whether banner impression events are recorded. 1=count displays, 0=track clicks only. Default is ON (1). |
| 16 | AffiliateSignupPage | nvarchar(255) | YES | - | CODE-BACKED | URL of the affiliate registration/signup page. Used in redirect flows and email templates. |
| 17 | LocaleIdentifier | int | YES | 0 | CODE-BACKED | Default locale/language identifier for the affiliate portal. Determines the default UI language for new affiliates. |
| 18 | AffiliateTypeID | int | YES | 0 | VERIFIED | Default affiliate type assigned to newly registered affiliates. References dbo.tblaff_AffiliateTypes.AffiliateTypeID. Value 851 in production. |
| 19 | NewMemberMessage | ntext | YES | - | CODE-BACKED | HTML email template sent to affiliates upon successful registration and approval. Supports template variables for affiliate name, login details, etc. |
| 20 | PendingMemberMessage | ntext | YES | - | CODE-BACKED | HTML email template sent when an affiliate registration is pending admin review. Only used when NewMembersRequireValidation=1. |
| 21 | RejectedMemberMessage | ntext | YES | - | CODE-BACKED | HTML email template sent when an admin rejects an affiliate application. |
| 22 | NewSaleMessage | ntext | YES | - | CODE-BACKED | HTML email template sent to the administrator when a new sale is attributed. Only used when EmailAdministratorSaleNotification=1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateTypeID | dbo.tblaff_AffiliateTypes | Implicit | Default affiliate type for new registrations |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

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
| UserID | NC UNIQUE | UserID | - | - | Active |
| AffiliateTypeID | NC | AffiliateTypeID | - | - | Active |

Note: Table has no clustered index (heap) and no formal PK constraint. The unique NC index on UserID provides uniqueness.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Administrative_NewMembersRequireValidation | DEFAULT | 0 - new affiliates auto-approved by default |
| DF_tblaff_Administrative_AllowUsersEditing | DEFAULT | 0 - self-editing disabled by default |
| DF_tblaff_Administrative_UniqueClickHour | DEFAULT | 0 - no click deduplication by default |
| DF_tblaff_Administrative_CookieExpiration | DEFAULT | 0 - no cookie expiration by default |
| DF_tblaff_Administrative_EmailAdministratorSaleNotification | DEFAULT | 0 - sale notifications off by default |
| DF_tblaff_Administrative_HTTP_REFERER | DEFAULT | 0 - referer validation off by default |
| DF_tblaff_Administrative_TrackBannerImpressions | DEFAULT | 1 - impression tracking ON by default |
| DF_tblaff_Administrative_LocaleIdentifier | DEFAULT | 0 |
| DF_tblaff_Administrative_AffiliateTypeID | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 Get current platform configuration
```sql
SELECT WebSiteName, WebSiteURL, UniqueClickHour, CookieExpiration,
       TrackBannerImpressions, NewMembersRequireValidation, AffiliateTypeID
FROM dbo.tblaff_Administrative WITH (NOLOCK)
```

### 8.2 Get email notification settings
```sql
SELECT AdministratorEmail, EmailAdministratorSaleNotification, MailServer
FROM dbo.tblaff_Administrative WITH (NOLOCK)
```

### 8.3 Get default affiliate type details
```sql
SELECT a.AffiliateTypeID, t.AffiliateTypeName
FROM dbo.tblaff_Administrative a WITH (NOLOCK)
JOIN dbo.tblaff_AffiliateTypes t WITH (NOLOCK) ON a.AffiliateTypeID = t.AffiliateTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Administrative | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Administrative.sql*
