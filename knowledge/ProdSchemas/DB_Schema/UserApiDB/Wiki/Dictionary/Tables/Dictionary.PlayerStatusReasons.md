# Dictionary.PlayerStatusReasons

> Lookup table defining primary reasons for placing a user into a non-Normal player status, providing business justification for account restrictions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PlayerStatusReasonID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.PlayerStatusReasons provides the primary business justification for why a user's account has been restricted. When a compliance agent or automated system changes a user's PlayerStatus (from Dictionary.PlayerStatus), they must also specify a reason. This enables compliance reporting, trend analysis, and audit trails for account actions.

This table is critical for regulatory compliance. Regulators expect platforms to maintain detailed records of why accounts are restricted. The 43 reasons cover compliance (AML, KYC, Risk), financial disputes (Chargeback, Overpayment), user-initiated actions (CloseAccountByUser, Self-Service), and operational scenarios (Hacked Account, Employee Account).

Reasons are set alongside PlayerStatus changes, typically by compliance agents through admin tools or by automated risk rules. They are stored on Customer.RiskUserInfo and reported in aggregated user info procedures.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: Reasons grouped by business domain for compliance reporting and trend analysis.

**Columns/Parameters Involved**: `PlayerStatusReasonID`, `Name`

**Rules**:
- **Compliance/AML**: AML (10), AML review (11), AML-Account Closed (6), HRC (7), WCH match (18), Risk (4), Risk Check (14)
- **Financial Disputes**: Chargeback (5), ACH Chargeback (23), PWMB Chargeback (24), CheckoutChargeback (30), Overpayment (13)
- **Verification**: Failed Verification (1), Expired Document (2), Pending Docs (27), KYC (39)
- **User-Initiated**: CloseAccountByUser (3), Self-Service (21), By request (22), Right to be forgotten (20)
- **Operational**: Hacked Account (35), Employee Account (28), PI Account (29), Affiliate Account (26)
- **Abuse**: Off Market Abuse (12), Abusive Trading (34), Abuse (25)
- 0=None serves as the default/no-reason value

---

## 3. Data Overview

| PlayerStatusReasonID | Name | Meaning |
|---|---|---|
| 0 | None | No specific reason recorded - default value |
| 3 | CloseAccountByUser | User voluntarily requested account closure |
| 5 | Chargeback | Credit card chargeback initiated against the user's deposit |
| 10 | AML | Anti-Money Laundering investigation or finding |
| 35 | Hacked Account | Account compromised - blocked for security pending investigation |

*5 of 43 rows shown - selected to represent major reason categories.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlayerStatusReasonID | int | NO | - | CODE-BACKED | Primary key. 43 reason codes (0-42) covering compliance, financial, verification, user-initiated, operational, and abuse categories. See [Player Status Reason](_glossary.md#player-status-reason). |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Reason label used in admin tools, compliance reports, and audit logs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RiskUserInfo | PlayerStatusReasonID | Lookup | Stores reason for current account status |
| History.RiskUserInfo | PlayerStatusReasonID | Lookup | Historical tracking of status reason changes |
| Customer.GetRiskUserInfo | PlayerStatusReasonID | Lookup | Returns status reason in risk profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RiskUserInfo | Table | Stores PlayerStatusReasonID |
| History.RiskUserInfo | Table | Historical tracking |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_PlayerStatusReasons | CLUSTERED PK | PlayerStatusReasonID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all status reasons
```sql
SELECT PlayerStatusReasonID, Name
FROM Dictionary.PlayerStatusReasons WITH (NOLOCK)
ORDER BY PlayerStatusReasonID
```

### 8.2 Find blocked users by reason
```sql
SELECT r.CustomerID, ps.Name AS Status, psr.Name AS Reason
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON r.PlayerStatusID = ps.PlayerStatusID
JOIN Dictionary.PlayerStatusReasons psr WITH (NOLOCK) ON r.PlayerStatusReasonID = psr.PlayerStatusReasonID
WHERE ps.IsBlocked = 1
```

### 8.3 Reason distribution for non-normal accounts
```sql
SELECT psr.Name, COUNT(*) AS UserCount
FROM Customer.RiskUserInfo r WITH (NOLOCK)
JOIN Dictionary.PlayerStatusReasons psr WITH (NOLOCK) ON r.PlayerStatusReasonID = psr.PlayerStatusReasonID
WHERE r.PlayerStatusID <> 1
GROUP BY psr.Name
ORDER BY UserCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlayerStatusReasons | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.PlayerStatusReasons.sql*
