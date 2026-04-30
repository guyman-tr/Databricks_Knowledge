# dbo.DELETE_ToaDetails_Registration

> Ad-hoc maintenance view filtering Customer.ToaDetails_Registration by specific phone numbers for targeted data cleanup.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | From Customer.ToaDetails_Registration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.DELETE_ToaDetails_Registration is an ad-hoc maintenance view created for one-time data cleanup. It selects all columns from Customer.ToaDetails_Registration filtered to specific phone numbers. The view name with "DELETE" prefix indicates it was created to identify rows for deletion. This appears to be a utility/maintenance artifact rather than a production object.

---

## 2. Business Logic

No business logic. SELECT * with WHERE filter on hardcoded phone numbers.

---

## 3. Data Overview

N/A - maintenance view.

---

## 4. Elements

All columns from Customer.ToaDetails_Registration, filtered by ToaPhone IN ('18475568490', '18318400845', '13585878131').

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.ToaDetails_Registration | SELECT FROM | Filtered maintenance view |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DELETE_ToaDetails_Registration (view)
  +-- Customer.ToaDetails_Registration (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ToaDetails_Registration | Table | SELECT FROM |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View matching records
```sql
SELECT * FROM dbo.DELETE_ToaDetails_Registration WITH (NOLOCK)
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM dbo.DELETE_ToaDetails_Registration WITH (NOLOCK)
```

### 8.3 Direct query equivalent
```sql
SELECT * FROM Customer.ToaDetails_Registration WITH (NOLOCK) WHERE ToaPhone IN ('18475568490', '18318400845', '13585878131')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: dbo.DELETE_ToaDetails_Registration | Type: View | Source: UserApiDB/UserApiDB/dbo/Views/dbo.DELETE_ToaDetails_Registration.sql*
