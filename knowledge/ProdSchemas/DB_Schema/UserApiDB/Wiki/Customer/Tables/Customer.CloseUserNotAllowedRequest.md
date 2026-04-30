# Customer.CloseUserNotAllowedRequest

> Records instances where a user's account closure was blocked due to a specific blocking condition (open positions, high equity, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | Gcid + Occurred (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.CloseUserNotAllowedRequest logs each instance when a user attempted to close their account but was blocked by a specific condition. The composite PK (Gcid, Occurred) allows tracking multiple blocked attempts over time for the same user. This supports operational analytics on closure friction points.

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
| 1 | Gcid | int | NO | - | CODE-BACKED | Part of composite PK. Global Customer ID of the user whose closure was blocked. |
| 2 | CloseUserNotAllowedReasonId | int | NO | - | CODE-BACKED | FK to Dictionary.CloseUserNotAllowedReason. The blocking condition: 1=TooHighEquity, 2=OpenOrders, 3=OpenPositions, 4=OpenMirrors, 5=OpenCashouts, 6=WalletNotAllowedToClose. See [Close User Not Allowed Reason](_glossary.md#close-user-not-allowed-reason). |
| 3 | Occurred | datetime | NO | getdate() | CODE-BACKED | Part of composite PK. When the blocked closure attempt happened. Default: current datetime. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CloseUserNotAllowedReasonId | Dictionary.CloseUserNotAllowedReason | Explicit FK | The specific blocking condition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.AddCloseUserNotAllowedRequest | Gcid | SP writes | Records blocked closure attempts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CloseUserNotAllowedRequest (table)
  +-- Dictionary.CloseUserNotAllowedReason (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CloseUserNotAllowedReason | Table | FK: CloseUserNotAllowedReasonId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.AddCloseUserNotAllowedRequest | Stored Procedure | Inserts rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CloseUserNotAllowedRequest | CLUSTERED PK | Gcid, Occurred | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed) | DEFAULT | getdate() for Occurred |
| FK_CloseUserNotAllowedReason | FOREIGN KEY | CloseUserNotAllowedReasonId -> Dictionary.CloseUserNotAllowedReason |

---

## 8. Sample Queries

### 8.1 Get blocked closure attempts for a user
```sql
SELECT r.CloseUserNotAllowedReasonName, c.Occurred
FROM Customer.CloseUserNotAllowedRequest c WITH (NOLOCK)
JOIN Dictionary.CloseUserNotAllowedReason r WITH (NOLOCK) ON c.CloseUserNotAllowedReasonId = r.CloseUserNotAllowedReasonId
WHERE c.Gcid = @GCID ORDER BY c.Occurred DESC
```

### 8.2 Most common blocking reasons
```sql
SELECT r.CloseUserNotAllowedReasonName, COUNT(*) AS BlockedCount
FROM Customer.CloseUserNotAllowedRequest c WITH (NOLOCK)
JOIN Dictionary.CloseUserNotAllowedReason r WITH (NOLOCK) ON c.CloseUserNotAllowedReasonId = r.CloseUserNotAllowedReasonId
GROUP BY r.CloseUserNotAllowedReasonName ORDER BY BlockedCount DESC
```

### 8.3 Recent blocked attempts
```sql
SELECT TOP 50 Gcid, CloseUserNotAllowedReasonId, Occurred FROM Customer.CloseUserNotAllowedRequest WITH (NOLOCK) ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.CloseUserNotAllowedRequest | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.CloseUserNotAllowedRequest.sql*
