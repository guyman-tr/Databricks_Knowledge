# Customer.GDPRSignature

> Records when users signed the GDPR (General Data Protection Regulation) consent agreement.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.GDPRSignature records the date when each user signed the GDPR consent. This is a compliance requirement for EU-regulated users under CySEC. One row per user, PK on GCID. Used by Customer.SignGDPR to record consent and by aggregated info procedures to check GDPR status.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Primary key. Global Customer ID. One consent record per user. |
| 2 | SignDate | datetime | NO | - | CODE-BACKED | When the user signed the GDPR consent. Used for compliance audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SignGDPR | GCID | SP writes | Records GDPR consent |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SignGDPR | Stored Procedure | Inserts rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_GDPRSignature_GCID | CLUSTERED PK | GCID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check GDPR consent for a user
```sql
SELECT GCID, SignDate FROM Customer.GDPRSignature WITH (NOLOCK) WHERE GCID = @GCID
```

### 8.2 Users without GDPR consent
```sql
SELECT b.GCID FROM Customer.BasicUserInfo b WITH (NOLOCK)
LEFT JOIN Customer.GDPRSignature g WITH (NOLOCK) ON b.GCID = g.GCID WHERE g.GCID IS NULL
```

### 8.3 Recent GDPR signatures
```sql
SELECT TOP 100 GCID, SignDate FROM Customer.GDPRSignature WITH (NOLOCK) ORDER BY SignDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.GDPRSignature | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.GDPRSignature.sql*
