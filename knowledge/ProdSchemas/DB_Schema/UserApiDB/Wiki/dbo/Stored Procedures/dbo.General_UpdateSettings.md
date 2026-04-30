# dbo.General_UpdateSettings

> Upserts user display/social settings (AllowDisplayFullName, AllowShareFollow, HomepageId) in Customer.Settings using MERGE.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.General_UpdateSettings performs an upsert (MERGE) on Customer.Settings. If the user has existing settings, updates them; if not, inserts a new row with defaults. Replaces a former synonym to etoroGeneral SP. Uses CID (legacy), not GCID.

---

## 2. Business Logic

### 2.1 MERGE Upsert

**What**: INSERT or UPDATE based on CID match.

**Rules**:
- MATCHED: UPDATE AllowDisplayFullName, AllowShareFollow, HomepageId, DateModified
- NOT MATCHED: INSERT with ISNULL defaults (0 for booleans)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | int (IN) | NO | - | CODE-BACKED | Legacy Customer ID. |
| 2 | @allowDisplayFullName | bit (IN) | YES | NULL | CODE-BACKED | Show full name publicly. |
| 3 | @allowShareFollow | bit (IN) | YES | NULL | CODE-BACKED | Allow being followed/shared. |
| 4 | @homepageId | int (IN) | YES | NULL | CODE-BACKED | Preferred homepage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.Settings | MERGE | Upserts settings |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.General_UpdateSettings (procedure)
  +-- Customer.Settings (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Settings | Table | MERGE |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update settings
```sql
EXEC dbo.General_UpdateSettings @cid = 12345, @allowDisplayFullName = 1, @allowShareFollow = 1
```

### 8.2 Set homepage
```sql
EXEC dbo.General_UpdateSettings @cid = 12345, @homepageId = 2
```

### 8.3 Verify
```sql
SELECT * FROM Customer.Settings WITH (NOLOCK) WHERE CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.General_UpdateSettings | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.General_UpdateSettings.sql*
