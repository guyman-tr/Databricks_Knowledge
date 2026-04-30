# Dictionary.EvStatus

> Lookup table defining the overall Electronic Verification status for a user's identity verification process, aggregated across multiple verification sources.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | EvStatusId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.EvStatus represents the aggregated outcome of a user's Electronic Verification (EV) process. Unlike EvMatchStatus (which tracks individual match attempts), EvStatus reflects the overall verification conclusion after potentially multiple provider attempts and manual reviews. It determines whether the user is verified, needs additional documents, or has been rejected.

This status is central to the KYC (Know Your Customer) workflow. A user's EvStatus directly impacts their account capabilities - unverified users have limited functionality, while approved users get full platform access. Some regulators require verification from two independent sources, which is why the table distinguishes between "One Source" and "Two Sources" verification.

EvStatus is updated by the EV orchestration system as verification results come in from providers. It may also be manually overridden by compliance agents (e.g., ApprovedWithConflict when a manual review accepts the user despite conflicting data).

---

## 2. Business Logic

### 2.1 EV Status Progression

**What**: Multi-source verification lifecycle with manual review override capability.

**Columns/Parameters Involved**: `EvStatusId`, `Name`

**Rules**:
- None (0) is the initial state for all new users
- Automated flow: None -> One Source (1) -> Two Sources (2) -> Approved (5)
- No Match (3) triggers document verification fallback
- Alert (7) requires manual compliance review
- ApprovedWithConflict (4) is a manual override by compliance agents
- Rejected (6) is a terminal state requiring re-registration

**Diagram**:
```
None(0) -> One Source(1) -> Two Sources(2)
  |              |               |
  +-> No Match(3)    +-> Approved(5)
  |                        |
  +-> Alert(7) -----> ApprovedWithConflict(4)
                  |
                  +-> Rejected(6)
One Source Verified(8) = final single-source approval
```

---

## 3. Data Overview

| EvStatusId | Name | Meaning |
|---|---|---|
| 0 | None | No electronic verification attempted yet - user is in initial registration |
| 1 | One Source | One data source confirmed identity, may need second source per regulation |
| 2 | Two Sources | Two independent sources confirmed identity - highest automated confidence |
| 3 | No Match | EV provider could not find matching records - user needs document-based verification |
| 4 | ApprovedWithConflict | Compliance agent manually approved despite conflicting data from providers |
| 5 | Approved | Fully approved through the standard EV process |
| 6 | Rejected | Verification failed definitively - identity could not be confirmed |
| 7 | Alert | Verification flagged for manual compliance review - potential issues detected |
| 8 | One Source Verified | Single-source verification accepted as sufficient for this regulation |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EvStatusId | int | NO | - | CODE-BACKED | Primary key. Overall EV outcome: 0=None, 1=One Source, 2=Two Sources, 3=No Match, 4=ApprovedWithConflict, 5=Approved, 6=Rejected, 7=Alert, 8=One Source Verified. See [EV Status](_glossary.md#ev-status). |
| 2 | Name | varchar(30) | YES | - | CODE-BACKED | Status label used in compliance dashboards and user management tools. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer EV tracking tables | EvStatusId | Lookup | Stores the current overall EV status for each user |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryEvStatus | CLUSTERED PK | EvStatusId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all EV statuses
```sql
SELECT EvStatusId, Name
FROM Dictionary.EvStatus WITH (NOLOCK)
ORDER BY EvStatusId
```

### 8.2 Find users pending manual review
```sql
SELECT ev.CustomerID, es.Name AS EvStatus, ev.LastUpdated
FROM Customer.EvResults ev WITH (NOLOCK)
JOIN Dictionary.EvStatus es WITH (NOLOCK) ON ev.EvStatusId = es.EvStatusId
WHERE ev.EvStatusId = 7 -- Alert
```

### 8.3 EV outcome distribution
```sql
SELECT es.Name, COUNT(*) AS UserCount
FROM Customer.EvResults ev WITH (NOLOCK)
JOIN Dictionary.EvStatus es WITH (NOLOCK) ON ev.EvStatusId = es.EvStatusId
GROUP BY es.Name
ORDER BY UserCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.EvStatus | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.EvStatus.sql*
