# Dictionary.PhoneTypes

> Lookup table defining 15 phone number line types — classifying phone numbers by carrier type (FixedLine, Mobile, VOIP, etc.) for identity verification and fraud prevention.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (TINYINT IDENTITY, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) + 1 unique constraint on Name |

---

## 1. Business Meaning

Dictionary.PhoneTypes classifies phone numbers by their carrier/line type as reported by phone verification providers. When a customer provides a phone number during registration or verification, the platform queries an external provider to determine the phone type — is it a mobile, fixed line, VOIP, prepaid, or other type?

This table exists because the phone line type is a key risk signal for fraud prevention and identity verification. Mobile numbers are considered higher trust than VOIP numbers, prepaid SIMs carry more risk than contract mobiles, and invalid/restricted numbers are red flags. The phone type classification feeds into KYC risk scoring and verification workflows.

The phone type is stored in Customer.PhoneVerificationDetails and referenced by phone verification reports and BackOffice SSRS dashboards. The "eToro" type (14) indicates an internal/system phone number used for testing or operational purposes.

---

## 2. Business Logic

### 2.1 Phone Type Risk Classification

**What**: Phone number types carry different risk levels for identity verification.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- **High Trust**: FixedLine (2), Mobile (3) — verified carrier-associated numbers.
- **Medium Trust**: PrePaidMobile (4), Personal (12), Number (11) — valid but less anchored to identity.
- **Low Trust**: NonFixedVOIP (6), TollFree (5), Pager (7), Payphone (8) — easily obtainable, not tied to a verified identity.
- **Red Flags**: Invalid (9), Restricted (10) — cannot be verified or deliberately hidden.
- **Internal**: eToro (14) — platform-internal numbers for testing/operations.
- **Catch-all**: Undetermined (1), Voicemail (13), Other (15) — unclassifiable or edge cases.

**Diagram**:
```
Phone Type Trust Tiers
├── High Trust
│   ├── 2  = FixedLine
│   └── 3  = Mobile
├── Medium Trust
│   ├── 4  = PrePaidMobile
│   ├── 11 = Number
│   └── 12 = Personal
├── Low Trust
│   ├── 5  = TollFree
│   ├── 6  = NonFixedVOIP
│   ├── 7  = Pager
│   └── 8  = Payphone
├── Red Flags
│   ├── 9  = Invalid
│   └── 10 = Restricted
└── Special
    ├── 1  = Undetermined
    ├── 13 = Voicemail
    ├── 14 = eToro (internal)
    └── 15 = Other
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 2 | FixedLine | Traditional landline telephone — high trust for identity verification as it's tied to a physical address. |
| 3 | Mobile | Standard mobile phone contract — the most common type for customer verification. Linked to carrier identity records. |
| 6 | NonFixedVOIP | Voice over IP number not tied to a physical location (e.g., Google Voice, Skype). Low trust for KYC as easily obtainable without identity verification. |
| 9 | Invalid | The phone number format is invalid or the number does not exist. Cannot be used for verification. Red flag for fraud. |
| 14 | eToro | Internal eToro phone number used for platform testing, operations, or system accounts. Not a customer-provided number. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | tinyint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. IDENTITY NOT FOR REPLICATION. Values 1-15 representing phone line types from verification providers. Referenced in Customer.PhoneVerificationDetails. |
| 2 | Name | varchar(15) | NO | - | VERIFIED | Unique phone type label. Enforced by UNQ_DictionaryPhoneTypes_PhoneType unique constraint. Values: Undetermined, FixedLine, Mobile, PrePaidMobile, TollFree, NonFixedVOIP, Pager, Payphone, Invalid, Restricted, Number, Personal, Voicemail, eToro, Other. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.PhoneVerificationDetails | PhoneTypeID | Implicit | Stores the phone type determined by verification provider |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.PhoneVerificationDetails | Table | Stores phone type per verification record |
| dbo.SSRS_PhoneVerification_CS | Stored Procedure | Reader — phone verification SSRS report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryPhoneTypes | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryPhoneTypes | PRIMARY KEY | Unique phone type identifier |
| UNQ_DictionaryPhoneTypes_PhoneType | UNIQUE | Ensures each phone type has a unique name |

---

## 8. Sample Queries

### 8.1 List all phone types
```sql
SELECT  ID,
        Name
FROM    [Dictionary].[PhoneTypes] WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Find high-risk phone types
```sql
SELECT  ID,
        Name
FROM    [Dictionary].[PhoneTypes] WITH (NOLOCK)
WHERE   Name IN ('Invalid', 'Restricted', 'NonFixedVOIP', 'Pager', 'Payphone')
ORDER BY ID;
```

### 8.3 Categorize phone types by trust level
```sql
SELECT  CASE WHEN Name IN ('FixedLine', 'Mobile') THEN 'High Trust'
             WHEN Name IN ('PrePaidMobile', 'Personal', 'Number') THEN 'Medium Trust'
             WHEN Name IN ('NonFixedVOIP', 'TollFree', 'Pager', 'Payphone') THEN 'Low Trust'
             WHEN Name IN ('Invalid', 'Restricted') THEN 'Red Flag'
             ELSE 'Special/Unknown'
        END AS TrustLevel,
        ID,
        Name
FROM    [Dictionary].[PhoneTypes] WITH (NOLOCK)
ORDER BY TrustLevel, ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PhoneTypes | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PhoneTypes.sql*
