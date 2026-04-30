# Customer.GetTncSignatures

> Retrieves all Terms and Conditions signature records for a customer, with regulation and document details, including implicit consent tracking.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all TnC signature rows for a GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetTncSignatures retrieves the complete Terms and Conditions signature history for a customer. Each time a customer signs (or implicitly accepts) a regulatory document, a record is created in Customer.TncSignature. This procedure returns all such records with the associated regulation and document IDs from dbo.TncDocument.

The IsImplicit flag (added COAKVU-2600, Feb 2024) tracks whether the TnC was explicitly signed by the user or implicitly accepted (e.g., through continued platform usage after a TnC update).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple read with document metadata JOIN.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID (echoed). |
| 3 | SignDate (output) | datetime | YES | - | CODE-BACKED | When the TnC was signed/accepted. |
| 4 | RegulationID (output) | int | YES | - | CODE-BACKED | Regulation context from TncDocument. FK to Dictionary.Regulation. |
| 5 | DocumentID (output) | int | YES | - | CODE-BACKED | TnC document identifier. FK to dbo.TncDocument. |
| 6 | ReasonID (output) | int | YES | - | CODE-BACKED | Reason for signing. FK to Dictionary.SignTncReason. See [Sign TnC Reason](_glossary.md#sign-tnc-reason). |
| 7 | IsImplicit (output) | bit | YES | - | CODE-BACKED | Whether the TnC was implicitly accepted (1) vs explicitly signed (0). Added COAKVU-2600. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.TncSignature | FROM | Signature records |
| DocumentID | dbo.TncDocument | LEFT JOIN | Regulation and doc metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | TnC compliance verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetTncSignatures (procedure)
+-- Customer.TncSignature (table)
+-- dbo.TncDocument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TncSignature | Table | FROM - signature records |
| dbo.TncDocument | Table | LEFT JOIN - regulation/doc metadata |

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

### 8.1 Get all TnC signatures
```sql
EXEC Customer.GetTncSignatures @gcid = 12345
```

### 8.2 Direct query with reason name
```sql
SELECT ts.GCID, ts.SignDate, td.RegulationID, td.DocumentID, ts.ReasonID,
       sr.Name AS ReasonName, ts.IsImplicit
FROM Customer.TncSignature ts WITH (NOLOCK)
LEFT JOIN dbo.TncDocument td WITH (NOLOCK) ON td.DocumentID = ts.DocumentID
LEFT JOIN Dictionary.SignTncReason sr WITH (NOLOCK) ON ts.ReasonID = sr.SignTncReasonID
WHERE ts.GCID = @gcid
```

### 8.3 Count implicit vs explicit signatures
```sql
SELECT IsImplicit, COUNT(*) AS SignCount
FROM Customer.TncSignature WITH (NOLOCK)
WHERE GCID = @gcid
GROUP BY IsImplicit
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetTncSignatures | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetTncSignatures.sql*
