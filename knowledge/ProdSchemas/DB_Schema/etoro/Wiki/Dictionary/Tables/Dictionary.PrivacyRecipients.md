# Dictionary.PrivacyRecipients

> Lookup table defining 7 data-sharing recipients (Community, Facebook, Twitter, LinkedIn, Google, Yahoo, Live) for eToro's granular privacy system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PrivacyRecipientID (INT IDENTITY, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PrivacyRecipients defines the possible audiences or platforms that can receive privacy-sensitive user data from the eToro platform. Each recipient represents a channel through which user activity (like championship participation) could be shared.

This table exists because eToro's social trading platform integrates with multiple social networks and internal communities. Users may want selective sharing — e.g., sharing championship results with the eToro Community but not with Twitter. The recipients list enables this granular control through the PrivacyPolicyDetails junction table.

The table is referenced by Dictionary.PrivacyPolicyDetails (FK) and indirectly by Customer.PrivacyUniqueIdentity which maps customers to specific privacy recipient configurations.

---

## 2. Business Logic

### 2.1 Recipient Categories

**What**: Recipients fall into two categories — the internal eToro community and external social networks.

**Columns/Parameters Involved**: `PrivacyRecipientID`, `PrivacyRecipientName`

**Rules**:
- **ID 1 (Community)** — eToro's internal social feed and user network. The primary sharing target.
- **IDs 2-7 (Social Networks)** — External platforms (Facebook, Twitter, LinkedIn, Google, Yahoo, Live/Microsoft). These represent legacy social integrations from eToro's OpenBook-era social trading features.

**Diagram**:
```
Privacy Recipients
├── 1 = Community      (internal — eToro social feed)
├── 2 = Facebook       (external social network)
├── 3 = Twitter        (external social network)
├── 4 = LinkedIn       (external social network)
├── 5 = Google         (external social network)
├── 6 = Yahoo          (external social network)
└── 7 = Live           (external — Microsoft Live)
```

---

## 3. Data Overview

| PrivacyRecipientID | PrivacyRecipientName | Meaning |
|---|---|---|
| 1 | Community | eToro's internal social trading community. The main audience for shared trading activity, leaderboard appearances, and championship results. |
| 2 | Facebook | Facebook social network integration for cross-posting trading activity. |
| 3 | Twitter | Twitter/X integration for sharing trading achievements. |
| 4 | LinkedIn | LinkedIn integration for professional trading profile sharing. |
| 5 | Google | Google integration (Google+/social features). |
| 6 | Yahoo | Yahoo integration for social sharing. |
| 7 | Live | Microsoft Live/Hotmail integration for social sharing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PrivacyRecipientID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. IDENTITY NOT FOR REPLICATION. Values 1-7 represent the 7 supported sharing recipients. |
| 2 | PrivacyRecipientName | varchar(30) | YES | - | VERIFIED | Human-readable name of the data recipient. Used in UI configuration and privacy settings screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.PrivacyPolicyDetails | PrivacyRecipientID | FK (FK_DICT_PRRE) | Grants data sharing to this recipient under a specific policy+event |
| Customer.PrivacyUniqueIdentity | PrivacyRecipientID | Implicit | Maps customer-specific privacy recipient settings |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PrivacyPolicyDetails | Table | FK — references this as the data recipient |
| Customer.PrivacyUniqueIdentity | Table | Stores per-customer recipient identity data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DICT_PRRE | CLUSTERED PK | PrivacyRecipientID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DICT_PRRE | PRIMARY KEY | Unique recipient identifier |

---

## 8. Sample Queries

### 8.1 List all privacy recipients
```sql
SELECT  PrivacyRecipientID,
        PrivacyRecipientName
FROM    [Dictionary].[PrivacyRecipients] WITH (NOLOCK)
ORDER BY PrivacyRecipientID;
```

### 8.2 Find recipients with active privacy grants
```sql
SELECT  DISTINCT pr.PrivacyRecipientName
FROM    [Dictionary].[PrivacyRecipients] pr WITH (NOLOCK)
JOIN    [Dictionary].[PrivacyPolicyDetails] ppd WITH (NOLOCK)
        ON pr.PrivacyRecipientID = ppd.PrivacyRecipientID;
```

### 8.3 List recipients without any privacy policy grants
```sql
SELECT  pr.PrivacyRecipientID,
        pr.PrivacyRecipientName
FROM    [Dictionary].[PrivacyRecipients] pr WITH (NOLOCK)
LEFT JOIN [Dictionary].[PrivacyPolicyDetails] ppd WITH (NOLOCK)
        ON pr.PrivacyRecipientID = ppd.PrivacyRecipientID
WHERE   ppd.ID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PrivacyRecipients | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PrivacyRecipients.sql*
