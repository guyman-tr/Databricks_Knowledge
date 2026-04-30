# Customer.GetAdditionalCitizenship

> Returns the additional citizenship CountryID for a user.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetAdditionalCitizenship retrieves a user's secondary citizenship country. Returns a single CountryID or empty if the user has no additional citizenship recorded.

---

## 2. Business Logic

No complex business logic. Single SELECT with NOLOCK.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |

Output: CountryID (int).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.AdditionalCitizenship | SELECT FROM | Reads additional citizenship |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetAdditionalCitizenship (procedure)
  +-- Customer.AdditionalCitizenship (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.AdditionalCitizenship | Table | SELECT FROM |

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

### 8.1 Get additional citizenship
```sql
EXEC Customer.GetAdditionalCitizenship @GCID = 12345
```

### 8.2 With country name
```sql
DECLARE @CountryID INT
DECLARE @Result TABLE (CountryID INT)
INSERT INTO @Result EXEC Customer.GetAdditionalCitizenship @GCID = 12345
SELECT c.Name FROM @Result r JOIN Dictionary.Country c WITH (NOLOCK) ON r.CountryID = c.CountryID
```

### 8.3 Direct query
```sql
SELECT CountryID FROM Customer.AdditionalCitizenship WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetAdditionalCitizenship | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetAdditionalCitizenship.sql*
