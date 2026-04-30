# Customer.SignTncDocuments

> Records a customer's TnC signatures for multiple documents at once via an IdList TVP - batch version of SignTnc.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Customer.TncSignature (batch from IdList) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SignTncDocuments is the batch version of Customer.SignTnc. Instead of signing one document at a time, it accepts an IdList TVP of document IDs and creates a signature record for each one in a single INSERT...SELECT. This is used when a customer needs to sign multiple regulatory documents simultaneously (e.g., during regulation change or onboarding).

Created by Ran Ovadia (May 2018) for multi-document signing.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Batch INSERT from TVP.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @documentIds | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of document IDs to sign. |
| 3 | @signDate | datetime | NO | - | CODE-BACKED | Sign date (same for all documents). |
| 4 | @reasonID | int | YES | 0 | CODE-BACKED | Signing reason. FK to Dictionary.SignTncReason. |
| 5 | @isImplicit | bit | YES | NULL | CODE-BACKED | Implicit consent flag. Added COAKVU-2600. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Customer.TncSignature | INSERT batch | Batch signature records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Multi-document TnC signing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SignTncDocuments (procedure)
+-- Customer.TncSignature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TncSignature | Table | INSERT...SELECT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Batch TnC signing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Sign multiple documents
```sql
DECLARE @docs dbo.IdList
INSERT @docs VALUES (101), (102), (103)
EXEC Customer.SignTncDocuments @gcid=12345, @documentIds=@docs, @signDate=GETUTCDATE(), @reasonID=1
```

### 8.2 Compare with single version
```sql
-- SignTnc: one document at a time
-- SignTncDocuments: batch via IdList TVP
```

### 8.3 Verify all signed
```sql
EXEC Customer.GetTncSignatures @gcid=12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.SignTncDocuments | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.SignTncDocuments.sql*
