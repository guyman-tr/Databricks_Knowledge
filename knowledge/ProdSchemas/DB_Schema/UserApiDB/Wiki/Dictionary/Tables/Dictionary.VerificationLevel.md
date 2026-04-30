# Dictionary.VerificationLevel

> Lookup table defining progressive levels of user identity verification completion that unlock platform features.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.VerificationLevel defines four progressive tiers of identity verification. Each level represents increased verification depth and unlocks more platform capabilities and higher transaction limits. Level 0 is unverified (email only), while Level 3 represents full enhanced verification with all documents confirmed.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Linear progression 0->1->2->3.

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | Level 0 | Unverified - basic registration complete, email confirmed, minimal trading access |
| 1 | Level 1 | Basic verification - phone verified, limited deposit/trading allowed |
| 2 | Level 2 | Standard verification - ID document verified, full trading access, standard limits |
| 3 | Level 3 | Enhanced verification - additional documents verified (POA, source of funds), highest transaction limits |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key. Verification tier: 0=unverified, 1=basic, 2=standard, 3=enhanced. See [Verification Level](_glossary.md#verification-level). |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Level label used in user profile and compliance dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer user tables | VerificationLevelID | Lookup | Stores user's current verification tier |

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
| PK_VerificationLevel | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List verification levels
```sql
SELECT ID, Name FROM Dictionary.VerificationLevel WITH (NOLOCK) ORDER BY ID
```

### 8.2 User distribution by verification level
```sql
SELECT vl.Name, COUNT(*) AS UserCount FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.VerificationLevel vl WITH (NOLOCK) ON u.VerificationLevelID = vl.ID GROUP BY vl.Name ORDER BY vl.ID
```

### 8.3 Find unverified users
```sql
SELECT u.CustomerID, u.RegistrationDate FROM Customer.Users u WITH (NOLOCK) WHERE u.VerificationLevelID = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.VerificationLevel | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.VerificationLevel.sql*
