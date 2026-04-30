# Customer.UpdateManyBasicInfo

> Bulk updates basic profile fields (gender, language, player level) for multiple customers via BasicUserInfo TVP with session context.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Bulk UPDATE Customer.BasicUserInfo from TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateManyBasicInfo performs a bulk update of basic profile fields for multiple customers in a single call. Accepts a Customer.BasicUserInfo TVP with rows containing GCID + fields to update. Uses ISNULL for partial updates (only non-NULL fields are applied). Sets session context for audit trail.

Limited to Gender, LanguageID, and PlayerLevelID updates (not names or birth date).

---

## 2. Business Logic

### 2.1 Bulk ISNULL Update

**Rules**:
- JOINs TVP to Customer.BasicUserInfo on GCID
- Each field uses ISNULL(BulkTable.col, existing.col)
- Session context set for trigger-based audit trail
- Only 3 fields updatable: Gender, LanguageID, PlayerLevelID

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BulkUpdateTable | Customer.BasicUserInfo (TVP) | NO | - | CODE-BACKED | Rows with GCID + fields to update (Gender, LanguageID, PlayerLevelID). |
| 2 | @correlationId | varchar(50) | YES | NULL | CODE-BACKED | Audit trail. |
| 3 | @clientRequestId | varchar(50) | YES | NULL | CODE-BACKED | Audit trail. |
| 4 | @requestTime | datetime | YES | NULL | CODE-BACKED | Audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @BulkUpdateTable | Customer.BasicUserInfo | UPDATE (bulk) | Bulk profile update |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Batch profile operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateManyBasicInfo (procedure)
+-- Customer.BasicUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BasicUserInfo | Table | UPDATE (bulk JOIN) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Batch operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk update language
```sql
DECLARE @bulk Customer.BasicUserInfo
INSERT @bulk (GCID, LanguageID) VALUES (1001, 2), (1002, 3)
EXEC Customer.UpdateManyBasicInfo @BulkUpdateTable=@bulk
```

### 8.2 With audit trail
```sql
EXEC Customer.UpdateManyBasicInfo @BulkUpdateTable=@bulk,
    @correlationId='batch-001', @clientRequestId='req', @requestTime=GETUTCDATE()
```

### 8.3 Compare with single
```sql
-- UpdateManyBasicInfo: bulk via TVP (Gender, Language, Level only)
-- UpdateBasicInfo: single customer, all fields (new)
-- Bulk_UpdateBasicUserInfo: batch 3 (uses different TVP)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateManyBasicInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateManyBasicInfo.sql*
