# Dictionary.PrivacyPolicyDetails

> Junction table mapping privacy policies to specific privacy-sensitive events and data recipients — controlling granular per-event data sharing on the eToro social trading platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PrivacyPolicyDetails provides granular, per-event privacy control by linking a PrivacyPolicy to a specific PrivacyEvent and a PrivacyRecipient. While Dictionary.PrivacyPolicy defines the high-level privacy mode (Share All / Don't Share), this table specifies which events are shared with which recipients under each policy.

This table exists because not all privacy-sensitive events should be uniformly shared or hidden. For example, a "Share All" user may want championship results shared with the Community but not necessarily with external social networks. The junction table enables this fine-grained matrix of policy × event × recipient.

Currently contains only 1 row: PrivacyPolicyID=1 (Share All) × PrivacyEventID=1 (Championship) × PrivacyRecipientID=1 (Community), meaning championship activity is shared with the community under the Share All policy.

---

## 2. Business Logic

### 2.1 Privacy Matrix

**What**: Each row defines a single permission grant: "Under policy X, event Y is shared with recipient Z."

**Columns/Parameters Involved**: `PrivacyPolicyID`, `PrivacyEventID`, `PrivacyRecipientID`

**Rules**:
- A missing row means the event is NOT shared with that recipient under that policy.
- The table uses a sparse population model — only explicit grants exist.
- All three FK columns are nullable in DDL but logically required for a meaningful row.

**Diagram**:
```
Privacy Policy Details Matrix
┌─────────────────┬──────────────┬──────────────────┐
│ PrivacyPolicy   │ PrivacyEvent │ PrivacyRecipient │
├─────────────────┼──────────────┼──────────────────┤
│ 1 (Share All)   │ 1 (Champ.)   │ 1 (Community)    │  ← only active grant
└─────────────────┴──────────────┴──────────────────┘
```

---

## 3. Data Overview

| ID | PrivacyPolicyID | PrivacyEventID | PrivacyRecipientID | Meaning |
|---|---|---|---|---|
| 1 | 1 | 1 | 1 | Under "Share All" policy, Championship events are shared with the Community recipient. This is the only active privacy detail grant in the system. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing surrogate primary key. IDENTITY NOT FOR REPLICATION. |
| 2 | PrivacyPolicyID | int | YES | - | VERIFIED | FK → Dictionary.PrivacyPolicy.PrivacyPolicyID. Identifies which privacy policy this grant belongs to. 1=Share All, 2=Don't Share. |
| 3 | PrivacyEventID | int | YES | - | VERIFIED | FK → Dictionary.PrivacyEvents.PrivacyEventID. Identifies the privacy-sensitive event being controlled. Currently only 1=Championship. |
| 4 | PrivacyRecipientID | int | YES | - | VERIFIED | FK → Dictionary.PrivacyRecipients.PrivacyRecipientID. Identifies who receives the data. 1=Community, 2=Facebook, 3=Twitter, etc. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Element | FK Constraint | Description |
|-------------------|---------|---------------|-------------|
| Dictionary.PrivacyPolicy | PrivacyPolicyID | FK_DICT_PRPL | Parent privacy policy (Share All / Don't Share) |
| Dictionary.PrivacyEvents | PrivacyEventID | FK_DICT_PPEV | The privacy-sensitive event being controlled |
| Dictionary.PrivacyRecipients | PrivacyRecipientID | FK_DICT_PRRE | The data recipient |

### 5.2 Referenced By (other objects point to this)

No known consumers — this table is read directly as configuration data.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.PrivacyPolicyDetails
├── Dictionary.PrivacyPolicy (FK)
├── Dictionary.PrivacyEvents (FK)
└── Dictionary.PrivacyRecipients (FK)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PrivacyPolicy | Table | FK — parent privacy policy |
| Dictionary.PrivacyEvents | Table | FK — privacy event type |
| Dictionary.PrivacyRecipients | Table | FK — data recipient |

### 6.2 Objects That Depend On This

No known dependents in the etoro SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DICT_PRPO | CLUSTERED PK | ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DICT_PRPO | PRIMARY KEY | Unique row identifier |
| FK_DICT_PRPL | FOREIGN KEY | PrivacyPolicyID → Dictionary.PrivacyPolicy |
| FK_DICT_PPEV | FOREIGN KEY | PrivacyEventID → Dictionary.PrivacyEvents |
| FK_DICT_PRRE | FOREIGN KEY | PrivacyRecipientID → Dictionary.PrivacyRecipients |

---

## 8. Sample Queries

### 8.1 List all privacy policy details with resolved names
```sql
SELECT  ppd.ID,
        pp.PrivacyName,
        pe.PrivacyEventName,
        pr.PrivacyRecipientName
FROM    [Dictionary].[PrivacyPolicyDetails] ppd WITH (NOLOCK)
JOIN    [Dictionary].[PrivacyPolicy] pp WITH (NOLOCK) ON ppd.PrivacyPolicyID = pp.PrivacyPolicyID
JOIN    [Dictionary].[PrivacyEvents] pe WITH (NOLOCK) ON ppd.PrivacyEventID = pe.PrivacyEventID
JOIN    [Dictionary].[PrivacyRecipients] pr WITH (NOLOCK) ON ppd.PrivacyRecipientID = pr.PrivacyRecipientID;
```

### 8.2 Find which recipients receive Championship events
```sql
SELECT  pr.PrivacyRecipientName,
        pp.PrivacyName
FROM    [Dictionary].[PrivacyPolicyDetails] ppd WITH (NOLOCK)
JOIN    [Dictionary].[PrivacyRecipients] pr WITH (NOLOCK) ON ppd.PrivacyRecipientID = pr.PrivacyRecipientID
JOIN    [Dictionary].[PrivacyPolicy] pp WITH (NOLOCK) ON ppd.PrivacyPolicyID = pp.PrivacyPolicyID
WHERE   ppd.PrivacyEventID = 1;
```

### 8.3 Check for policies without any detail grants
```sql
SELECT  pp.PrivacyPolicyID,
        pp.PrivacyName
FROM    [Dictionary].[PrivacyPolicy] pp WITH (NOLOCK)
LEFT JOIN [Dictionary].[PrivacyPolicyDetails] ppd WITH (NOLOCK) ON pp.PrivacyPolicyID = ppd.PrivacyPolicyID
WHERE   ppd.ID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PrivacyPolicyDetails | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PrivacyPolicyDetails.sql*
