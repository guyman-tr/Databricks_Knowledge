# Customer.UpdateUserBio

> Upserts a customer's bio/about-me content in dbo.Publications - updates if exists, inserts if not.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPSERT dbo.Publications (AboutMe, AboutMeShort, LanguageCode, StrategyID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateUserBio saves or updates a customer's public profile bio content. If the customer already has a Publications record, it updates all bio fields. If not, it creates a new record. Supports AboutMe (full bio), AboutMeShort (summary, added LOY-1290 Dec 2022), LanguageCode, and StrategyID (investment strategy, added LOY-1023 Apr 2022).

---

## 2. Business Logic

### 2.1 UPSERT via CID Lookup

**Rules**:
- First checks if Publications record exists for CID (via JOIN to Real_Customer)
- If @cid > 0 (record exists): UPDATE all bio fields
- Else: INSERT new Publications record (resolves CID from Real_Customer by GCID)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @aboutMe | nvarchar(1000) | YES | NULL | CODE-BACKED | Full bio text. |
| 3 | @aboutMeShort | nvarchar(300) | YES | NULL | CODE-BACKED | Short bio summary. Added LOY-1290. |
| 4 | @languageCode | varchar(50) | YES | NULL | CODE-BACKED | Bio language code. |
| 5 | @strategyID | int | YES | NULL | CODE-BACKED | Investment strategy. Added LOY-1023. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | JOIN | CID resolution |
| CID | dbo.Publications | UPSERT | Bio content |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Profile bio editing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateUserBio (procedure)
+-- dbo.Publications (table)
+-- dbo.Real_Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Publications | Table | UPSERT |
| dbo.Real_Customer | Table | JOIN - CID resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Profile editing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update bio
```sql
EXEC Customer.UpdateUserBio @gcid=12345, @aboutMe=N'Experienced trader focusing on tech stocks',
    @aboutMeShort=N'Tech stock trader', @languageCode='en', @strategyID=1
```

### 8.2 Read bio back
```sql
EXEC Customer.GetUserBio @gcid=12345
```

### 8.3 Check Publications table
```sql
SELECT * FROM dbo.Publications WITH (NOLOCK)
WHERE CID = (SELECT CID FROM dbo.Real_Customer WITH (NOLOCK) WHERE GCID = 12345)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateUserBio | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateUserBio.sql*
