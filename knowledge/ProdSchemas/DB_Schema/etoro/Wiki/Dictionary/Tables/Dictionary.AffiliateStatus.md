# Dictionary.AffiliateStatus

> Lookup table defining the 6 affiliate partner quality tiers — Normal, Good, Bad, Untouchable, Excellent, and Platinum — used to classify introducing broker (affiliate) performance and trustworthiness.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AffiliateStatusID (INT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.AffiliateStatus classifies affiliate partners (introducing brokers) into quality tiers based on their performance, traffic quality, and compliance behavior. eToro's affiliate program pays partners for referring new customers, and the affiliate status determines how much trust and flexibility the platform extends to each partner.

This table is essential for the affiliate management system. An affiliate's status affects how their referred customers are treated during onboarding, what level of scrutiny their referrals receive, and potentially what commission structures apply. The "Bad" and "Untouchable" tiers exist for affiliates whose traffic has quality issues (fraud, chargebacks, bot registrations).

The status is stored in BackOffice.Affiliate and set via BackOffice.AffiliateEdit. It's read during customer registration (Customer.RegisterReal, Customer.RegisterDemo, Customer.PostRegisterOperations) to apply affiliate-specific rules, and used by Customer.DemographyEdit and BackOffice.GetCustomerByCID for customer profile display. BackOffice.GetRegistrationReport includes affiliate status in registration analytics, and Internal.FixMissingDemoRegistrations references it during data repair operations.

---

## 2. Business Logic

### 2.1 Affiliate Quality Tiers

**What**: Classification of affiliate partner quality and trustworthiness.

**Columns/Parameters Involved**: `AffiliateStatusID`, `Name`

**Rules**:
- **Normal (1)**: Default status for new affiliates. Standard commission rates and standard scrutiny for referred customers.
- **Good (2)**: Above-average affiliate. Demonstrated quality traffic and low fraud/chargeback rates. May receive improved terms.
- **Bad (3)**: Affiliate with quality issues — high chargeback rates, suspicious registrations, or policy violations. Referred customers may undergo additional compliance checks.
- **Untouchable (4)**: Blacklisted affiliate. Highest risk tier — the affiliate's traffic is considered untrustworthy. May trigger automatic rejection or enhanced screening of their referrals.
- **Excellent (5)**: High-performing affiliate with consistently quality referrals. Premium partnership tier with potential commission benefits.
- **Platinum (6)**: Top-tier affiliate partner. Highest trust level. Strategic partnership with the best commission structures and least friction for their referrals.

**Diagram**:
```
Affiliate Quality Spectrum:

  Low Trust ◄──────────────────────────────────────────► High Trust

  Untouchable (4)  Bad (3)  Normal (1)  Good (2)  Excellent (5)  Platinum (6)
  ──────────────   ──────   ──────────  ────────  ─────────────  ────────────
  Blacklisted      Issues   Default     Above     High           Top tier
                            for new     average   performer      strategic
                            affiliates                           partner
```

---

## 3. Data Overview

| AffiliateStatusID | Name | Meaning |
|---|---|---|
| 1 | Normal | Default tier for newly onboarded affiliates. Standard terms, standard referred-customer screening. Most affiliates start here. |
| 3 | Bad | Affiliate flagged for quality issues — high chargeback rates, suspicious registration patterns, or compliance violations. Their referred customers may face enhanced scrutiny during onboarding. |
| 4 | Untouchable | Blacklisted affiliate. The highest risk classification — their traffic is considered untrustworthy. Referrals may be automatically flagged or rejected. Used for affiliates with confirmed fraud or severe policy breaches. |
| 5 | Excellent | High-performing affiliate with consistently clean, converting traffic. Earned through sustained quality metrics and low fraud/chargeback ratios. |
| 6 | Platinum | Strategic top-tier affiliate partnership. The highest trust level with best commercial terms. Reserved for the platform's most valuable and trusted affiliate partners. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateStatusID | int | NO | - | VERIFIED | Primary key identifying the affiliate quality tier. 1=Normal, 2=Good, 3=Bad, 4=Untouchable, 5=Excellent, 6=Platinum. Stored in BackOffice.Affiliate.AffiliateStatusID. Set by BackOffice.AffiliateEdit, read during Customer.RegisterReal and Customer.PostRegisterOperations. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable tier name. Unique index enforced (DAFS_NAME). Displayed in BackOffice affiliate management screens and registration reports (BackOffice.GetRegistrationReport). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.Affiliate | AffiliateStatusID | Implicit | Affiliate's current quality tier |
| BackOffice.AffiliateEdit | @AffiliateStatusID | Parameter UPDATE | Sets or changes an affiliate's status |
| Customer.RegisterReal | AffiliateStatusID | SELECT | Reads affiliate status during real account registration |
| Customer.RegisterDemo | AffiliateStatusID | SELECT | Reads affiliate status during demo registration |
| Customer.PostRegisterOperations | AffiliateStatusID | SELECT | Post-registration affiliate-specific processing |
| Customer.DynamicsInsert | AffiliateStatusID | SELECT | CRM sync includes affiliate status |
| Customer.DemographyEdit | AffiliateStatusID | SELECT | Customer profile updates reference affiliate tier |
| BackOffice.GetCustomerByCID | AffiliateStatusID | SELECT | Customer lookup returns affiliate status |
| BackOffice.GetRegistrationReport | AffiliateStatusID | SELECT | Registration analytics by affiliate tier |
| BackOffice.UpdateBackOfficeAffiliateTableForMissingRecords | AffiliateStatusID | INSERT | Data repair for missing affiliate records |
| Internal.FixMissingDemoRegistrations | AffiliateStatusID | SELECT | Fixes missing demo registrations |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Affiliate | Table | Stores AffiliateStatusID per affiliate |
| BackOffice.AffiliateEdit | Stored Procedure | Writer — sets affiliate status |
| Customer.RegisterReal | Stored Procedure | Reader — registration processing |
| Customer.PostRegisterOperations | Stored Procedure | Reader — post-registration hooks |
| BackOffice.GetRegistrationReport | Stored Procedure | Reader — registration analytics |
| BackOffice.GetCustomerByCID | Stored Procedure | Reader — customer profile |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DAFS | CLUSTERED PK | AffiliateStatusID ASC | - | - | Active (FILLFACTOR 90) |
| DAFS_NAME | NC UNIQUE | Name ASC | - | - | Active (FILLFACTOR 90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DAFS | PRIMARY KEY | Unique affiliate status identifier |
| DAFS_NAME | UNIQUE INDEX | Prevents duplicate status names |

---

## 8. Sample Queries

### 8.1 List all affiliate statuses
```sql
SELECT  AffiliateStatusID,
        Name
FROM    Dictionary.AffiliateStatus WITH (NOLOCK)
ORDER BY AffiliateStatusID;
```

### 8.2 Count affiliates by status tier
```sql
SELECT  das.Name            AS AffiliateStatus,
        COUNT(*)            AS AffiliateCount
FROM    BackOffice.Affiliate boa WITH (NOLOCK)
JOIN    Dictionary.AffiliateStatus das WITH (NOLOCK)
        ON boa.AffiliateStatusID = das.AffiliateStatusID
GROUP BY das.Name
ORDER BY AffiliateCount DESC;
```

### 8.3 Find all blacklisted affiliates
```sql
SELECT  boa.*,
        das.Name            AS StatusName
FROM    BackOffice.Affiliate boa WITH (NOLOCK)
JOIN    Dictionary.AffiliateStatus das WITH (NOLOCK)
        ON boa.AffiliateStatusID = das.AffiliateStatusID
WHERE   das.AffiliateStatusID IN (3, 4);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AffiliateStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.AffiliateStatus.sql*
