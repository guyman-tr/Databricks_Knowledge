# Customer.GetUserChanges

> Retrieves the history of changes to a customer's phone, email, and language from the temporal history table - used for security audit and compliance tracking.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns change history rows for a GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUserChanges retrieves the temporal history of a customer's contact information changes - specifically language, email, and phone. Each row in the result represents a historical state of these fields with ValidFrom/ValidTo timestamps, enabling the application to show when changes were made and what the previous values were.

Created by Yulia Kramer (Dec 2021, COAKV-4038/4142) to expose change history data for phone, email, and language modifications. This supports security features (detecting suspicious rapid changes) and compliance requirements (audit trail of contact info changes).

The procedure first resolves GCID to CID via dbo.Real_Customer, then queries dbo.Real_HistoryCustomer (the temporal history table for the customer record).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple history read by CID from temporal table.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | CID (output) | int | NO | - | CODE-BACKED | Customer ID. |
| 3 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 4 | LanguageID (output) | int | YES | - | CODE-BACKED | Language at that point in time. FK to Dictionary.Language. |
| 5 | Email (output) | nvarchar | YES | - | CODE-BACKED | Email address at that point in time. |
| 6 | Phone (output) | varchar | YES | - | CODE-BACKED | Phone number at that point in time. |
| 7 | ValidFrom (output) | datetime2 | NO | - | CODE-BACKED | Start of validity period for this historical state. |
| 8 | ValidTo (output) | datetime2 | NO | - | CODE-BACKED | End of validity period. datetime2 max = current/ongoing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | dbo.Real_Customer | SELECT | GCID to CID resolution |
| CID | dbo.Real_HistoryCustomer | FROM | Temporal history table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Security audit / change tracking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUserChanges (procedure)
+-- dbo.Real_Customer (table)
+-- dbo.Real_HistoryCustomer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | SELECT - CID resolution |
| dbo.Real_HistoryCustomer | Table | FROM - temporal history |

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

### 8.1 Get user change history
```sql
EXEC Customer.GetUserChanges @GCID = 12345
```

### 8.2 Direct query - recent email changes
```sql
DECLARE @CID int
SELECT @CID = CID FROM dbo.Real_Customer WITH (NOLOCK) WHERE GCID = @GCID
SELECT Email, ValidFrom, ValidTo
FROM dbo.Real_HistoryCustomer WITH (NOLOCK)
WHERE CID = @CID
ORDER BY ValidFrom DESC
```

### 8.3 Check if phone changed in last 30 days
```sql
DECLARE @CID int
SELECT @CID = CID FROM dbo.Real_Customer WITH (NOLOCK) WHERE GCID = @GCID
SELECT Phone, ValidFrom
FROM dbo.Real_HistoryCustomer WITH (NOLOCK)
WHERE CID = @CID AND ValidFrom > DATEADD(DAY, -30, GETUTCDATE())
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetUserChanges | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetUserChanges.sql*
