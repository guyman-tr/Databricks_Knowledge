# Dictionary.EvMatchStatus

> Lookup table defining match result statuses for Electronic Verification (EV) identity checks against provider data sources.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | EvMatchStatusId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.EvMatchStatus indicates how well a user's self-declared identity data matched against authoritative data sources during Electronic Verification. When the system sends user data (name, DOB, address) to an EV provider (e.g., GBG, Trulioo), the provider returns a match result indicating the degree of confirmation.

This status is critical for KYC compliance. Regulators require that identity verification achieves a minimum match threshold. A "Verified" match means all required fields were confirmed; "PartiallyVerified" may trigger additional document verification requirements; "NotVerified" typically requires manual document review.

Match status is set by the EV provider integration after each verification attempt. It is stored per EV attempt and determines the next step in the verification workflow (auto-approve, request documents, or escalate to compliance).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| EvMatchStatusId | Name | Meaning |
|---|---|---|
| 0 | None | No electronic match has been attempted for this verification |
| 1 | PartiallyVerified | Some identity fields matched (e.g., name+DOB) but not all required fields (e.g., address unconfirmed) |
| 2 | Verified | Full match - all required identity fields confirmed against authoritative data sources |
| 3 | NotVerified | Match attempted but provider could not confirm identity data - may indicate data mismatch or no records found |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EvMatchStatusId | int | NO | - | CODE-BACKED | Primary key. EV match result: 0=None (not attempted), 1=PartiallyVerified, 2=Verified (full match), 3=NotVerified (no match). See [EV Match Status](_glossary.md#ev-match-status). |
| 2 | Name | varchar(30) | YES | - | CODE-BACKED | Match result label used in compliance dashboards and verification reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer EV result tables | EvMatchStatusId | Lookup | Records the match outcome of each EV attempt |

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
| PK_Dictionary_EvMatchStatus | CLUSTERED PK | EvMatchStatusId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all EV match statuses
```sql
SELECT EvMatchStatusId, Name
FROM Dictionary.EvMatchStatus WITH (NOLOCK)
ORDER BY EvMatchStatusId
```

### 8.2 Find users with partial verification
```sql
SELECT ev.CustomerID, ems.Name AS MatchStatus
FROM Customer.EvResults ev WITH (NOLOCK)
JOIN Dictionary.EvMatchStatus ems WITH (NOLOCK) ON ev.EvMatchStatusId = ems.EvMatchStatusId
WHERE ev.EvMatchStatusId = 1 -- PartiallyVerified
```

### 8.3 EV match outcome distribution
```sql
SELECT ems.Name, COUNT(*) AS AttemptCount
FROM Customer.EvResults ev WITH (NOLOCK)
JOIN Dictionary.EvMatchStatus ems WITH (NOLOCK) ON ev.EvMatchStatusId = ems.EvMatchStatusId
GROUP BY ems.Name
ORDER BY AttemptCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.EvMatchStatus | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.EvMatchStatus.sql*
