# Customer.GetTncSignaturesByDocType

> Retrieves TnC signature records for a customer filtered by document type - gets only signatures for a specific TnC document category.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TnC signatures filtered by TncDocTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetTncSignaturesByDocType is a filtered variant of GetTncSignatures. Instead of returning all TnC signatures, it filters by TncDocTypeID - returning only signatures for a specific document type category (e.g., only privacy policy signatures, or only trading terms signatures). This is useful when the application needs to check whether a customer has signed a specific type of regulatory document.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Same as GetTncSignatures with additional WHERE filter on td.TncDocTypeID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @docTypeId | int | NO | - | CODE-BACKED | TnC document type ID to filter by. From dbo.TncDocument.TncDocTypeID. |
| 3 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 4 | SignDate (output) | datetime | YES | - | CODE-BACKED | Signature date. |
| 5 | RegulationID (output) | int | YES | - | CODE-BACKED | Regulation context. |
| 6 | DocumentID (output) | int | YES | - | CODE-BACKED | Document identifier. |
| 7 | ReasonID (output) | int | YES | - | CODE-BACKED | Signing reason. |
| 8 | IsImplicit (output) | bit | YES | - | CODE-BACKED | Implicit (1) vs explicit (0) acceptance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.TncSignature | FROM | Signature records |
| DocumentID | dbo.TncDocument | LEFT JOIN | Filtered by TncDocTypeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Type-specific TnC verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetTncSignaturesByDocType (procedure)
+-- Customer.TncSignature (table)
+-- dbo.TncDocument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TncSignature | Table | FROM - signatures |
| dbo.TncDocument | Table | LEFT JOIN - filtered by TncDocTypeID |

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

### 8.1 Get signatures for a specific doc type
```sql
EXEC Customer.GetTncSignaturesByDocType @gcid = 12345, @docTypeId = 1
```

### 8.2 Direct query
```sql
SELECT ts.GCID, ts.SignDate, td.RegulationID, td.DocumentID, ts.ReasonID, ts.IsImplicit
FROM Customer.TncSignature ts WITH (NOLOCK)
LEFT JOIN dbo.TncDocument td WITH (NOLOCK) ON td.DocumentID = ts.DocumentID
WHERE ts.GCID = @gcid AND td.TncDocTypeID = @docTypeId
```

### 8.3 Compare with unfiltered version
```sql
-- GetTncSignatures: returns ALL TnC signatures
-- GetTncSignaturesByDocType: returns only signatures for specific TncDocTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetTncSignaturesByDocType | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetTncSignaturesByDocType.sql*
