# History.FastVerificationData

> System versioning history table for Customer.FastVerificationData, storing temporal snapshots of fast verification document data changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (clustered on EndTime,BeginTime) |
| **Partition** | No |
| **Indexes** | 1 (clustered on EndTime,BeginTime) |

---

## 1. Business Meaning

System versioning history target for Customer.FastVerificationData. Automatically managed by SQL Server. Stores previous versions of fast verification data (document numbers, Medicare details, card numbers, province) with their temporal validity period.

---

## 2. Business Logic

Automatically managed by SQL Server system versioning.

---

## 3. Data Overview

N/A - system-managed history.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | User whose fast verification data changed. |
| 2 | ExtendedUserValueTypeId | int | NO | - | CODE-BACKED | Document type at this point. |
| 3 | ExtendedUserFieldId | int | NO | - | CODE-BACKED | Extended field at this point. |
| 4 | Value | nvarchar(128) | NO | - | CODE-BACKED | Document number/value at this point. |
| 5 | MedicareReference | nvarchar(2) | YES | - | CODE-BACKED | Medicare reference at this point. |
| 6 | MedicareColor | nvarchar(10) | YES | - | CODE-BACKED | Medicare card color at this point. |
| 7 | ExpirationDate | nvarchar(7) | YES | - | CODE-BACKED | Document expiry at this point. |
| 8 | ProvinceId | int | YES | - | CODE-BACKED | Province at this point. |
| 9 | BeginTime | datetime2(7) | NO | - | CODE-BACKED | Version start. |
| 10 | EndTime | datetime2(7) | NO | - | CODE-BACKED | Version end. |
| 11 | CardNumber | nvarchar(30) | YES | - | CODE-BACKED | Card number at this point. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

System versioning pair with Customer.FastVerificationData.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

System versioning pair.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FastVerificationData | CLUSTERED | EndTime, BeginTime | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Document data history (temporal)
```sql
SELECT * FROM Customer.FastVerificationData FOR SYSTEM_TIME ALL WHERE GCID = @GCID ORDER BY BeginTime
```

### 8.2 Direct history query
```sql
SELECT GCID, Value, BeginTime, EndTime FROM History.FastVerificationData WITH (NOLOCK) WHERE GCID = @GCID ORDER BY BeginTime
```

### 8.3 Data at a point in time
```sql
SELECT * FROM Customer.FastVerificationData FOR SYSTEM_TIME AS OF '2025-06-01' WHERE GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.FastVerificationData | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.FastVerificationData.sql*
