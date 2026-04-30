# dbo.tblaff_Administrative4

> System configuration table (singleton row) storing affiliate platform settings for tracking behavior, UI messaging, approval thresholds, and promotional content.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

dbo.tblaff_Administrative4 is the fourth and final part of the affiliate system's singleton configuration tables. It stores settings that control tracking behavior (session tracking, 301 redirects, cookies, querystring passthrough), UI messaging (news, signup confirmation, linking instructions), payment approval thresholds (VP Marketing amount, Finance amount, Finance Manager amount), and promotional content.

The payment approval thresholds are particularly significant - they define when payments require higher-level approvals in the multi-level workflow tracked by tblaff_PaymentHistory: VPMarketingAmount=$5,000, FinanceAmount=$0 (all payments), FinanceManagerAmount=$10,000.

---

## 2. Business Logic

### 2.1 Payment Approval Thresholds

**What**: Controls when payments escalate to higher approval levels.

**Columns/Parameters Involved**: `VPMarketingAmount`, `FinanceAmount`, `FinanceManagerAmount`

**Rules**:
- VPMarketingAmount=5000: Payments >= $5,000 require VP Marketing approval (tblaff_PaymentHistory.VPMarketingApproved)
- FinanceAmount=0: ALL payments require finance approval (threshold of $0 means every payment)
- FinanceManagerAmount=10000: Payments >= $10,000 additionally require finance manager approval

### 2.2 Tracking Configuration

**What**: Controls how affiliate links track visitors.

**Columns/Parameters Involved**: `UseSessionTracking`, `Use301Redirect`, `CookieName`, `PassExtraQuerystringVariables`, `CookieExtraQuerystringVariables`

**Rules**:
- `Use301Redirect=true`: Affiliate links use 301 permanent redirects (better for SEO)
- `CookieName="AffiliateWizAffiliateID"`: Cookie name for tracking affiliate attribution
- `PassExtraQuerystringVariables=false`: Extra URL parameters are NOT forwarded through redirect
- `CookieExtraQuerystringVariables=false`: Extra parameters are NOT stored in cookie

---

## 3. Data Overview

| ID | VPMarketingAmount | FinanceAmount | FinanceManagerAmount | Use301Redirect | CookieName | Meaning |
|---|---|---|---|---|---|---|
| 1 | 5000 | 0 | 10000 | true | AffiliateWizAffiliateID | Payments above $5K need VP approval, all need Finance, above $10K need Finance Manager. 301 redirects enabled. Cookie-based tracking. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Singleton primary key. NOT FOR REPLICATION. |
| 2 | UseSessionTracking | bit | NO | 0 | CODE-BACKED | Whether to use server-side session tracking for affiliate attribution (in addition to cookies). |
| 3 | Use301Redirect | bit | NO | 0 | VERIFIED | Whether affiliate tracking links use HTTP 301 permanent redirects. Value: true (better for SEO). |
| 4 | FooterText | nvarchar(500) | YES | - | VERIFIED | Footer text for the affiliate portal. Contains copyright notice with HTML entity. |
| 5 | FooterLink | nvarchar(500) | YES | - | VERIFIED | URL for the footer link. Points to etoropartners.com. |
| 6 | CookieName | nvarchar(100) | YES | - | VERIFIED | Cookie name used for tracking affiliate attribution. "AffiliateWizAffiliateID" stores the referring affiliate's ID. |
| 7 | NewsMessage | ntext | YES | - | CODE-BACKED | HTML news/announcement message shown on the affiliate portal dashboard. |
| 8 | MessageAfterSignup | ntext | YES | - | VERIFIED | HTML confirmation message shown to affiliates after registration. |
| 9 | AffiliateMessage | ntext | YES | - | CODE-BACKED | General HTML message shown in the affiliate portal. Currently blank. |
| 10 | EmailAdministratorOnAccountUpdate | bit | NO | 0 | CODE-BACKED | Whether to email administrators when affiliate accounts are updated. Currently disabled. |
| 11 | LinkingMessage | ntext | YES | - | VERIFIED | Instructions for affiliates on how to create tracking links. Explains Direct Link Code and Serial ID concepts. |
| 12 | RejectedSaleMessageSubject | nvarchar(150) | YES | - | VERIFIED | Email subject for rejected sale notifications. Uses ##OrderNumber## and ##DATETIME## template variables. |
| 13 | RejectedSaleMessage | ntext | YES | - | VERIFIED | Email body template for rejected sale notifications. |
| 14 | PassExtraQuerystringVariables | bit | NO | 0 | CODE-BACKED | Whether to forward extra URL parameters through affiliate redirect links. |
| 15 | CookieExtraQuerystringVariables | bit | NO | 0 | CODE-BACKED | Whether to store extra URL parameters in the tracking cookie. |
| 16 | LoginRedirectURL | nvarchar(500) | YES | - | CODE-BACKED | URL to redirect affiliates after login. Points to SummaryReport.aspx. |
| 17 | PromoTitle | ntext | NO | '' | CODE-BACKED | Promotional content title. Currently "November". |
| 18 | PromoImage | ntext | NO | '' | CODE-BACKED | Promotional banner image URL. Points to S3-hosted image. |
| 19 | PromoText | ntext | NO | '' | CODE-BACKED | Promotional HTML content with links to campaign pages. |
| 20 | VPMarketingAmount | int | NO | 10000 | VERIFIED | Payment threshold for VP Marketing approval. Payments >= this amount require VPMarketingApproved=1 in tblaff_PaymentHistory. Current value: $5,000. |
| 21 | FinanceAmount | int | NO | 1500 | VERIFIED | Payment threshold for Finance approval. Current value: $0 (all payments require finance approval). Default in DDL is $1,500. |
| 22 | FinanceManagerAmount | int | NO | 10000 | VERIFIED | Payment threshold for Finance Manager approval. Payments >= this amount require FinanceManagerApproved=1. Current value: $10,000. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Read by the affiliate admin interface and payment approval workflow.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tblaff_Administrative4 | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_tblaff_Administrative4_UseSessionTracking | DEFAULT | 0 |
| DF_tblaff_Administrative4_Use301Redirect | DEFAULT | 0 |
| DF_tblaff_Administrative4_VPMarketingAmount | DEFAULT | 10000 |
| DF_tblaff_Administrative4_FinanceAmount | DEFAULT | 1500 |
| DF_tblaff_Administrative4_FinanceManagerAmount | DEFAULT | 10000 |

---

## 8. Sample Queries

### 8.1 Get payment approval thresholds
```sql
SELECT VPMarketingAmount, FinanceAmount, FinanceManagerAmount
FROM dbo.tblaff_Administrative4 WITH (NOLOCK)
```

### 8.2 Get tracking configuration
```sql
SELECT UseSessionTracking, Use301Redirect, CookieName,
       PassExtraQuerystringVariables, CookieExtraQuerystringVariables
FROM dbo.tblaff_Administrative4 WITH (NOLOCK)
```

### 8.3 Get all messaging templates
```sql
SELECT RejectedSaleMessageSubject, MessageAfterSignup, LinkingMessage
FROM dbo.tblaff_Administrative4 WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 9.1/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_Administrative4 | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_Administrative4.sql*
