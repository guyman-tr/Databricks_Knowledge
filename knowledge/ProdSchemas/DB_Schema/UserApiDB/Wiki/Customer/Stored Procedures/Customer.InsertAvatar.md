# Customer.InsertAvatar

> Inserts a new avatar image record for a customer and returns the auto-generated AvatarId.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Customer.Avatars, returns SCOPE_IDENTITY |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.InsertAvatar creates a new avatar record in the Customer.Avatars table. Each call inserts one size variant of an avatar image (a single upload generates multiple size variants, each with its own row). The procedure returns the newly generated AvatarId via SCOPE_IDENTITY().

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple INSERT with identity return.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | int | NO | - | CODE-BACKED | Customer ID (CID, not GCID). |
| 2 | @versionNum | int | NO | - | CODE-BACKED | Avatar version number. Incremented for each new upload. |
| 3 | @width | int | NO | - | CODE-BACKED | Image width in pixels. |
| 4 | @height | int | NO | - | CODE-BACKED | Image height in pixels. |
| 5 | @imageUrl | varchar(500) | NO | - | CODE-BACKED | URL to the stored image file. |
| 6 | @avatarTypeId | int | NO | - | CODE-BACKED | Avatar type: 4=System-generated, others=User-uploaded. |
| 7 | (return) | int | - | - | CODE-BACKED | SCOPE_IDENTITY() - the auto-generated AvatarId of the inserted row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Customer.Avatars | INSERT | Avatar storage table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Avatar upload flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.InsertAvatar (procedure)
+-- Customer.Avatars (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Avatars | Table | INSERT INTO |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Avatar upload service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Insert a user avatar
```sql
EXEC Customer.InsertAvatar @cid=100001, @versionNum=1, @width=150, @height=150,
    @imageUrl='https://cdn.etoro.com/avatars/100001_v1_150x150.jpg', @avatarTypeId=1
```

### 8.2 Insert a system avatar
```sql
EXEC Customer.InsertAvatar @cid=100001, @versionNum=1, @width=50, @height=50,
    @imageUrl='https://cdn.etoro.com/avatars/system_default_50x50.jpg', @avatarTypeId=4
```

### 8.3 Verify insert
```sql
SELECT TOP 1 * FROM Customer.Avatars WITH (NOLOCK) WHERE CID = 100001 ORDER BY AvatarId DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.InsertAvatar | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.InsertAvatar.sql*
