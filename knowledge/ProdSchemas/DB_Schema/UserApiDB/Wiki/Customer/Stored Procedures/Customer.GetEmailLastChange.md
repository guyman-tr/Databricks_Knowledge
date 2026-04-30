# Customer.GetEmailLastChange

> Returns the date when a customer's email address was last changed, used for security and compliance tracking.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns EmailLastChangeDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetEmailLastChange retrieves the timestamp of when a customer last changed their email address. This is important for security features - for example, verifying recent email changes before allowing sensitive operations, or detecting suspicious account activity.

This procedure was created for the "Phone change feature" (per code comments, August 2020), where the system needed to check recent contact information changes as part of security validation flows.

The procedure reads from dbo.CustomerLastChanges (which tracks when key fields were last modified) via a RIGHT JOIN with dbo.Real_CustomerStatic (to resolve GCID to CID). The RIGHT JOIN ensures a result is returned even if no change record exists yet.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-value lookup.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID to look up the email change date for. |
| 2 | EmailLastChangeDate (output) | datetime | YES | - | CODE-BACKED | Timestamp of when the customer's email was last changed. NULL if no email change has been recorded. From dbo.CustomerLastChanges. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | dbo.CustomerLastChanges | RIGHT JOIN | Tracks when key customer fields were last modified |
| @GCID | dbo.Real_CustomerStatic | JOIN | Resolves GCID to CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Called during security validation for contact changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetEmailLastChange (procedure)
+-- dbo.CustomerLastChanges (table)
+-- dbo.Real_CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.CustomerLastChanges | Table | FROM - reads EmailLastChangeDate |
| dbo.Real_CustomerStatic | Table | RIGHT JOIN - resolves GCID to CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get email last change date
```sql
EXEC Customer.GetEmailLastChange @GCID = 12345
```

### 8.2 Direct query equivalent
```sql
SELECT clc.EmailLastChangeDate
FROM dbo.CustomerLastChanges clc
RIGHT JOIN dbo.Real_CustomerStatic cc WITH (NOLOCK) ON cc.CID = clc.CID
WHERE cc.GCID = @GCID
```

### 8.3 Check if email was changed in the last 30 days
```sql
SELECT CASE WHEN clc.EmailLastChangeDate > DATEADD(DAY, -30, GETUTCDATE()) THEN 1 ELSE 0 END AS RecentChange
FROM dbo.CustomerLastChanges clc
RIGHT JOIN dbo.Real_CustomerStatic cc WITH (NOLOCK) ON cc.CID = clc.CID
WHERE cc.GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetEmailLastChange | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetEmailLastChange.sql*
