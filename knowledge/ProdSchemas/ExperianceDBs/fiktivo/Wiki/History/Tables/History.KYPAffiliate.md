# History.KYPAffiliate

> SQL Server temporal history table storing all historical versions of KYP (Know Your Partner) affiliate verification records, tracking changes to compliance status, documentation progress, and corporate identity information.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | AffiliateID (int) - identifies the affiliate's KYP record across versions |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.KYPAffiliate is the system-versioned temporal history table for KYP.Affiliate. It captures every historical version of an affiliate's Know Your Partner verification record. KYP is the compliance process that verifies the identity, legal structure, and business legitimacy of affiliate partners before they can receive commissions. This table stores changes to verification status, document submissions, corporate details, and authorized person information.

This table is critical for regulatory compliance - it provides an immutable audit trail of when KYP status changed, who submitted what, and when verification was completed or rejected. With 3,180 historical versions, the KYP process generates frequent updates as affiliates progress through verification stages.

Data flows in automatically via SQL Server's temporal mechanism. Many sensitive fields are protected with dynamic data masking (MASKED) for PII compliance.

---

## 2. Business Logic

### 2.1 KYP Verification Lifecycle

**What**: Tracks the affiliate's progression through KYP verification stages.

**Columns/Parameters Involved**: `KYPStatusID`, `Progress`, `SubmittedOn`, `CanceledOn`

**Rules**:
- KYPStatusID tracks the lifecycle state. See [KYP Status](../../Dictionary/Tables/Dictionary.KYPStatus.md): 1=Unavailable, 2=Unverified, 3=In Progress, 4=Submit Pending, 5=Submitted, 6=Cancel Pending, 7=Verified
- Progress (0-100) indicates completion percentage of the verification form
- SubmittedOn is set when the affiliate submits their KYP documents for review
- CanceledOn is set if the KYP process is canceled

### 2.2 Corporate Identity Documentation

**What**: Captures the legal entity details and authorized representatives for corporate affiliates.

**Columns/Parameters Involved**: `FormOfIncorporationID`, `NatureOfBusinessID`, `IncorporationCountryID`, contact/authorized person fields

**Rules**:
- FormOfIncorporationID: See [Form Of Incorporation](../../Dictionary/Tables/Dictionary.FormOfIncorporation.md): 1=Other, 2=Private, 3=Public
- NatureOfBusinessID: See [Nature Of Business](../../Dictionary/Tables/Dictionary.NatureOfBusiness.md): 1=Other, 2=Real Estate, 3=Marketing, etc.
- ContactPerson* fields capture the primary contact for the affiliate entity
- AuthorizedPerson* fields capture the legally authorized signatory

---

## 3. Data Overview

| AffiliateID | KYPStatusID | Progress | SubmittedOn | FormOfIncorporationID | IsMigrated | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|---|---|
| 61743 | 3 (In Progress) | 25 | NULL | NULL | false | 2026-03-26 14:32:57 | 2026-03-26 14:32:57 | KYP verification in progress at 25% - affiliate has started filling the form but not yet submitted documents |
| 61743 | 3 (In Progress) | 25 | NULL | NULL | false | 2026-03-26 14:32:56 | 2026-03-26 14:32:57 | Previous version 0.3 seconds earlier - rapid updates during form progression |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | int | NO | - | CODE-BACKED | Affiliate undergoing KYP verification. References dbo.tblaff_Affiliates.AffiliateID. |
| 2 | KYPStatusID | int | NO | - | CODE-BACKED | Verification lifecycle state. See [KYP Status](../../Dictionary/Tables/Dictionary.KYPStatus.md): 1=Unavailable, 2=Unverified, 3=In Progress, 4=Submit Pending, 5=Submitted, 6=Cancel Pending, 7=Verified. |
| 3 | Progress | int | NO | - | CODE-BACKED | Percentage completion of the KYP verification form (0-100). |
| 4 | TicketID | nvarchar(50) | YES | - | CODE-BACKED | External compliance ticket reference (MASKED). Links to the compliance team's case management system. |
| 5 | SubmittedOn | datetime | YES | - | CODE-BACKED | When the affiliate submitted their KYP documents for review. NULL until submission. |
| 6 | CanceledOn | datetime | YES | - | CODE-BACKED | When the KYP process was canceled. NULL if not canceled. |
| 7 | PopupDismissed | bit | NO | - | CODE-BACKED | Whether the affiliate dismissed the KYP reminder popup in their console. |
| 8 | FormOfIncorporationID | int | YES | - | CODE-BACKED | Legal structure of the corporate affiliate. See [Form Of Incorporation](../../Dictionary/Tables/Dictionary.FormOfIncorporation.md): 1=Other, 2=Private, 3=Public. |
| 9 | FormOfIncorporationOther | nvarchar(50) | YES | - | CODE-BACKED | Free text when FormOfIncorporationID = 1 (Other). |
| 10 | NatureOfBusinessID | int | YES | - | CODE-BACKED | Industry sector. See [Nature Of Business](../../Dictionary/Tables/Dictionary.NatureOfBusiness.md): 1=Other, 2=Real Estate, 3=Marketing, etc. |
| 11 | NatureOfBusinessOther | nvarchar(50) | YES | - | CODE-BACKED | Free text when NatureOfBusinessID = 1 (Other). |
| 12 | IncorporationCountryID | int | YES | - | CODE-BACKED | Country where the corporate entity is incorporated. |
| 13 | TaxCountryID | int | YES | - | CODE-BACKED | Country of tax residence for the entity. |
| 14 | Tin | nvarchar(20) | YES | - | CODE-BACKED | Tax Identification Number (MASKED). |
| 15 | OpeningPurpose | nvarchar(80) | YES | - | CODE-BACKED | Stated purpose for opening the affiliate partnership. |
| 16 | ContactPersonSameAsAccount | bit | YES | - | CODE-BACKED | Whether the contact person is the same as the account holder. |
| 17 | ContactPersonFirstName | nvarchar(50) | YES | - | CODE-BACKED | Contact person's first name (MASKED). |
| 18 | ContactPersonLastName | nvarchar(50) | YES | - | CODE-BACKED | Contact person's last name (MASKED). |
| 19 | ContactPersonCountryID | int | YES | - | CODE-BACKED | Country of the contact person. |
| 20 | ContactPersonCity | nvarchar(100) | YES | - | CODE-BACKED | Contact person's city (MASKED). |
| 21 | ContactPersonState | nvarchar(20) | YES | - | CODE-BACKED | Contact person's state/province (MASKED). |
| 22 | ContactPersonStreetAddress | nvarchar(100) | YES | - | CODE-BACKED | Contact person's street address (MASKED). |
| 23 | ContactPersonStreetNumber | nvarchar(10) | YES | - | CODE-BACKED | Contact person's street number (MASKED). |
| 24 | ContactPersonPostalCode | nvarchar(25) | YES | - | CODE-BACKED | Contact person's postal code (MASKED). |
| 25 | ContactPersonPassport | nvarchar(15) | YES | - | CODE-BACKED | Contact person's passport number (MASKED). |
| 26 | AuthorizedPersonSameAsAccount | bit | YES | - | CODE-BACKED | Whether the authorized signatory is the same as the account holder (MASKED). |
| 27 | AuthorizedPersonFirstName | nvarchar(50) | YES | - | CODE-BACKED | Authorized person's first name (MASKED). |
| 28 | AuthorizedPersonLastName | nvarchar(50) | YES | - | CODE-BACKED | Authorized person's last name (MASKED). |
| 29 | AuthorizedPersonRole | nvarchar(50) | YES | - | CODE-BACKED | Authorized person's role/title in the organization. |
| 30 | AuthorizedPersonPhoneCountryID | int | YES | - | CODE-BACKED | Phone country code for the authorized person (MASKED). |
| 31 | AuthorizedPersonPhoneNumber | nvarchar(20) | YES | - | CODE-BACKED | Authorized person's phone number (MASKED). |
| 32 | AuthorizedPersonCountryID | int | YES | - | CODE-BACKED | Country of the authorized person (MASKED). |
| 33 | AuthorizedPersonCity | nvarchar(100) | YES | - | CODE-BACKED | Authorized person's city (MASKED). |
| 34 | AuthorizedPersonState | nvarchar(50) | YES | - | CODE-BACKED | Authorized person's state/province (MASKED). |
| 35 | AuthorizedPersonStreetAddress | nvarchar(100) | YES | - | CODE-BACKED | Authorized person's street address (MASKED). |
| 36 | AuthorizedPersonStreetNumber | nvarchar(100) | YES | - | CODE-BACKED | Authorized person's street number (MASKED). |
| 37 | AuthorizedPersonPostalCode | nvarchar(25) | YES | - | CODE-BACKED | Authorized person's postal code (MASKED). |
| 38 | AuthorizedPersonPassport | nvarchar(20) | YES | - | CODE-BACKED | Authorized person's passport number (MASKED). |
| 39 | Profession | nvarchar(50) | YES | - | CODE-BACKED | Authorized person's profession (MASKED). |
| 40 | HeldPublicPositions | bit | YES | - | CODE-BACKED | Whether the authorized person has held public/political positions (PEP check) (MASKED). |
| 41 | IllegalActivity | bit | YES | - | CODE-BACKED | Whether the authorized person has been involved in illegal activity (AML check) (MASKED). |
| 42 | TermsAccepted | bit | YES | - | CODE-BACKED | Whether the KYP terms and conditions were accepted. |
| 43 | IsMigrated | bit | NO | - | CODE-BACKED | Whether this KYP record was migrated from a legacy system (MASKED). |
| 44 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON session context. |
| 45 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | When this version became active. |
| 46 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | KYP.Affiliate | Temporal History | Stores historical versions of the base table |
| AffiliateID | dbo.tblaff_Affiliates | Implicit FK | The affiliate undergoing KYP verification |
| KYPStatusID | Dictionary.KYPStatus | Implicit FK | Verification lifecycle state |
| FormOfIncorporationID | Dictionary.FormOfIncorporation | Implicit FK | Legal structure of the entity |
| NatureOfBusinessID | Dictionary.NatureOfBusiness | Implicit FK | Industry sector |

### 5.2 Referenced By (other objects point to this)

Accessed implicitly via temporal queries on KYP.Affiliate.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.KYPAffiliate (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYP.Affiliate | Table | SYSTEM_VERSIONING |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_KYPAffiliate | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. Uses PAGE compression. Multiple columns use dynamic data masking.

---

## 8. Sample Queries

### 8.1 View KYP verification history for an affiliate
```sql
SELECT AffiliateID, KYPStatusID, Progress, SubmittedOn, ValidFrom, ValidTo
FROM KYP.Affiliate FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE AffiliateID = 61743
ORDER BY ValidFrom
```

### 8.2 Check KYP status at a specific date
```sql
SELECT AffiliateID, KYPStatusID, Progress, FormOfIncorporationID
FROM KYP.Affiliate FOR SYSTEM_TIME AS OF '2025-06-01' WITH (NOLOCK)
WHERE AffiliateID = 61743
```

### 8.3 Find recently verified affiliates
```sql
SELECT AffiliateID, KYPStatusID, Progress, ValidFrom, ValidTo
FROM History.KYPAffiliate WITH (NOLOCK)
WHERE KYPStatusID = 7
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 46 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.KYPAffiliate | Type: Table | Source: fiktivo/History/Tables/History.KYPAffiliate.sql*
