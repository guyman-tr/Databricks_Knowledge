# Dictionary.PlayerStatusSubReasons

> Lookup table defining granular sub-reasons within player status reasons for detailed compliance reporting and operational tracking.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PlayerStatusSubReasonID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.PlayerStatusSubReasons provides additional granularity below the primary status reason (Dictionary.PlayerStatusReasons). While the reason tells "why" an account was restricted (e.g., Chargeback), the sub-reason specifies the exact nature (e.g., ACH CHBK, Credit Card CHBK, PayPal CHBK). This enables precise compliance reporting and targeted operational response.

This table is essential for detailed compliance analytics. Regulators and internal compliance teams need to distinguish between, for example, a PayPal chargeback vs an ACH chargeback, or a sanctions match vs a PEP match in screening. The 80 sub-reasons cover fraud types, verification failures, screening outcomes, chargeback channels, AML triggers, and account classifications.

Sub-reasons are set alongside PlayerStatus and PlayerStatusReason changes. They provide the finest level of detail in the three-tier classification: Status -> Reason -> SubReason.

---

## 2. Business Logic

### 2.1 Sub-Reason Groupings

**What**: 80 sub-reasons organized by operational domain.

**Columns/Parameters Involved**: `PlayerStatusSubReasonID`, `Name`

**Rules**:
- **Fraud** (1-5): Fraud, Fake docs, Attack, Affiliate Fraud, 3rd Party
- **Chargeback by channel** (35-45): ACH CHBK, Credit Card CHBK, PayPal CHBK, PWMB CHBK, etc.
- **Screening/WCH** (31-34): Negative Results, PEP, Possible Match, Sanctions
- **AML** (17-21): Investigation, Cross Border, AML Trigger, Business Method, Mixed Funds
- **Verification** (7, 24-26, 61): Failed Verification, Selfie, Expired POI/POA
- **Tax/Compliance** (66-68, 76): FATCA, CRS, FATCA0013, W-8BEN
- 0=None serves as the default/no-sub-reason value

---

## 3. Data Overview

| PlayerStatusSubReasonID | Name | Meaning |
|---|---|---|
| 0 | None | No sub-reason specified |
| 1 | Fraud | Confirmed fraudulent activity on the account |
| 14 | Sanctions | User matched against sanctions lists (OFAC, EU, UN) |
| 36 | Credit Card CHBK | Chargeback initiated through credit card payment provider |
| 66 | FATCA | Account flagged for FATCA (Foreign Account Tax Compliance Act) reporting issues |

*5 of 80 rows shown - selected to represent major sub-reason categories.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerStatusSubReasonID | int | NO | - | CODE-BACKED | Primary key. 80 sub-reason codes (0-79) providing granular detail within each PlayerStatusReason. See [Player Status Sub Reason](_glossary.md#player-status-sub-reason). |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Sub-reason label used in compliance reports and admin tools. CHBK suffix denotes chargeback-specific sub-reasons. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RiskUserInfo | PlayerStatusSubReasonID | Lookup | Stores sub-reason for current account status |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RiskUserInfo | Table | Stores PlayerStatusSubReasonID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_PlayerStatusSubReasons | CLUSTERED PK | PlayerStatusSubReasonID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all sub-reasons
```sql
SELECT PlayerStatusSubReasonID, Name
FROM Dictionary.PlayerStatusSubReasons WITH (NOLOCK)
ORDER BY PlayerStatusSubReasonID
```

### 8.2 Full status detail for a user
```sql
SELECT r.CustomerID, ps.Name AS Status, psr.Name AS Reason, pssr.Name AS SubReason
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON r.PlayerStatusID = ps.PlayerStatusID
JOIN Dictionary.PlayerStatusReasons psr WITH (NOLOCK) ON r.PlayerStatusReasonID = psr.PlayerStatusReasonID
JOIN Dictionary.PlayerStatusSubReasons pssr WITH (NOLOCK) ON r.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
WHERE r.CustomerID = @CustomerID
```

### 8.3 Chargeback sub-reason breakdown
```sql
SELECT pssr.Name, COUNT(*) AS Cases
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.PlayerStatusSubReasons pssr WITH (NOLOCK) ON r.PlayerStatusSubReasonID = pssr.PlayerStatusSubReasonID
WHERE pssr.Name LIKE '%CHBK%'
GROUP BY pssr.Name
ORDER BY Cases DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlayerStatusSubReasons | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.PlayerStatusSubReasons.sql*
