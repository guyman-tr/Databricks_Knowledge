# Customer.GetRelatedUsersByPhoneOLD

> Legacy version of GetRelatedUsersByPhone - finds customers with same phone number from dbo.Real_Customer.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 20 GCID + Phone |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRelatedUsersByPhoneOLD is the legacy version of Customer.GetRelatedUsersByPhone. It performs the same phone number matching but reads from dbo.Real_Customer instead of Customer.ContactUserInfo. Kept for backward compatibility with callers not yet migrated to the Customer schema version.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple exact phone match with TOP 20.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @phone | varchar(max) | NO | - | CODE-BACKED | Phone number to search for. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | Phone (output) | varchar | YES | - | CODE-BACKED | Phone number (echoed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @phone | dbo.Real_Customer | Exact match | Legacy phone matching |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy phone fraud detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRelatedUsersByPhoneOLD (procedure)
+-- dbo.Real_Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - phone matching |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Legacy callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find accounts with same phone (legacy)
```sql
EXEC Customer.GetRelatedUsersByPhoneOLD @phone = '+972501234567'
```

### 8.2 Direct query
```sql
SELECT TOP 20 GCID, Phone FROM dbo.Real_Customer WITH (NOLOCK) WHERE Phone = @phone
```

### 8.3 Prefer new version
```sql
-- Use Customer.GetRelatedUsersByPhone for new development
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetRelatedUsersByPhoneOLD | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRelatedUsersByPhoneOLD.sql*
