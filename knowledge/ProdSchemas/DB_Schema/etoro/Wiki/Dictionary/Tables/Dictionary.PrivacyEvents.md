# Dictionary.PrivacyEvents

> Lookup table defining privacy-sensitive platform events — currently contains only "Championship" (1) as an event type requiring privacy policy enforcement.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PrivacyEventID (INT IDENTITY, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PrivacyEvents identifies platform activities that have privacy implications and require privacy policy enforcement. When a customer participates in certain platform features, the system must check whether their privacy settings allow the associated data sharing.

This table exists because specific platform features (like championships/trading competitions) involve exposing user data to other participants (leaderboards, performance rankings). Before enrolling a user in such features, the system must verify that the user's privacy policy allows data sharing for that specific event type.

Currently only one event type is defined — Championship (1) — which corresponds to trading competitions where user performance is publicly visible. The table is referenced by Dictionary.PrivacyPolicyDetails, which defines the privacy settings per event type per policy.

---

## 2. Business Logic

### 2.1 Privacy-Sensitive Events

**What**: Platform events that require privacy policy checks before user participation.

**Columns/Parameters Involved**: `PrivacyEventID`, `PrivacyEventName`

**Rules**:
- **Championship (1)** — Trading competitions where user performance data (returns, rankings, portfolio composition) is visible to other participants. Users with "Don't Share" privacy policy may be excluded or have their data anonymized.
- The IDENTITY column allows new event types to be added as the platform introduces new features with privacy implications.
- Each event type links to Dictionary.PrivacyPolicyDetails, which maps the event to specific privacy settings.

**Diagram**:
```
Privacy Event Flow
    User → Joins Championship
            │
            ▼
    Check PrivacyPolicyDetails for (UserPrivacyPolicyID, PrivacyEventID=1)
            │
            ├── Allowed → Show user data on leaderboard
            └── Not Allowed → Exclude or anonymize
```

---

## 3. Data Overview

| PrivacyEventID | PrivacyEventName | Meaning |
|---|---|---|
| 1 | Championship | Trading competitions/tournaments where user performance is publicly visible. Requires checking whether the user's privacy policy permits sharing performance data with other participants on leaderboards and rankings. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PrivacyEventID | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing primary key. IDENTITY NOT FOR REPLICATION. Currently only 1=Championship. Referenced by Dictionary.PrivacyPolicyDetails for per-event privacy settings. |
| 2 | PrivacyEventName | varchar(30) | YES | - | VERIFIED | Human-readable event name. "Championship" is the only current value. Used in privacy policy configuration and user privacy checks. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.PrivacyPolicyDetails | PrivacyEventID | Implicit | Defines privacy settings per event type per policy |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PrivacyPolicyDetails | Table | References PrivacyEventID for per-event privacy configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DICT_PREV | CLUSTERED PK | PrivacyEventID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DICT_PREV | PRIMARY KEY | Unique privacy event identifier |

---

## 8. Sample Queries

### 8.1 List all privacy events
```sql
SELECT  PrivacyEventID,
        PrivacyEventName
FROM    [Dictionary].[PrivacyEvents] WITH (NOLOCK)
ORDER BY PrivacyEventID;
```

### 8.2 Check privacy settings for championship events
```sql
SELECT  ppd.*
FROM    [Dictionary].[PrivacyPolicyDetails] ppd WITH (NOLOCK)
JOIN    [Dictionary].[PrivacyEvents] pe WITH (NOLOCK)
        ON ppd.PrivacyEventID = pe.PrivacyEventID
WHERE   pe.PrivacyEventName = 'Championship';
```

### 8.3 Find events with privacy implications
```sql
SELECT  PrivacyEventID,
        PrivacyEventName,
        'Requires privacy policy check before user participation' AS Note
FROM    [Dictionary].[PrivacyEvents] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PrivacyEvents | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PrivacyEvents.sql*
