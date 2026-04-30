# Customer.GetUserBio

> Retrieves a customer's bio/about-me content, language code, strategy ID, and short bio from the Publications table.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns bio content for a single GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUserBio retrieves a customer's public profile bio content. This includes the full bio text (AboutMe), a short summary (AboutMeShort, added LOY-1290 Dec 2022), the bio language code, and the investment strategy ID (added LOY-1023 Apr 2022). This data powers the public profile page where users describe their trading approach.

The procedure reads from dbo.Real_Customer (for GCID resolution) with a LEFT JOIN to dbo.Publications (the bio content table), so customers without a bio still return a row with NULL bio fields.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-customer bio read.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID (echoed). |
| 3 | AboutMe (output) | nvarchar | YES | - | CODE-BACKED | Full bio text. From Publications. |
| 4 | LanguageCode (output) | varchar | YES | - | CODE-BACKED | Language code of the bio content (e.g., 'en', 'de'). |
| 5 | StrategyID (output) | int | YES | - | CODE-BACKED | Investment strategy classification. Added LOY-1023. |
| 6 | AboutMeShort (output) | nvarchar | YES | - | CODE-BACKED | Short bio summary. Added LOY-1290. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | FROM | GCID to CID resolution |
| CID | dbo.Publications | LEFT JOIN | Bio content |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Public profile bio display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUserBio (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Publications (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - GCID resolution |
| dbo.Publications | Table | LEFT JOIN - bio content |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get user bio
```sql
EXEC Customer.GetUserBio @gcid = 12345
```

### 8.2 Direct query
```sql
SELECT rc.GCID, ub.AboutMe, ub.LanguageCode, ub.StrategyID, ub.AboutMeShort
FROM dbo.Real_Customer rc WITH (NOLOCK)
LEFT JOIN dbo.Publications ub WITH (NOLOCK) ON ub.CID = rc.CID
WHERE rc.GCID = @gcid
```

### 8.3 Find users with bios
```sql
SELECT rc.GCID, ub.AboutMe
FROM dbo.Real_Customer rc WITH (NOLOCK)
JOIN dbo.Publications ub WITH (NOLOCK) ON ub.CID = rc.CID
WHERE ub.AboutMe IS NOT NULL AND rc.GCID = @gcid
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetUserBio | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetUserBio.sql*
