# Customer.SignTnc

> Records a customer's Terms and Conditions signature for a single document, with reason and implicit consent tracking.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Customer.TncSignature (single document) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SignTnc records when a customer signs a specific Terms and Conditions document. Each regulatory document version gets its own signature record. The procedure tracks the signing reason (e.g., new registration, regulation change) and whether the consent was implicit (COAKVU-2600, Feb 2024) or explicit.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple INSERT with default values.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @documentId | int | NO | - | CODE-BACKED | TnC document identifier. FK to dbo.TncDocument. |
| 3 | @signDate | datetime | NO | - | CODE-BACKED | When the document was signed. |
| 4 | @reasonID | int | YES | 0 | CODE-BACKED | Why the TnC was signed. FK to Dictionary.SignTncReason. 0=default/initial. |
| 5 | @isImplicit | bit | YES | NULL | CODE-BACKED | Whether the consent was implicit (1) vs explicit (0/NULL). Added COAKVU-2600. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Customer.TncSignature | INSERT | Signature record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | TnC signing flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SignTnc (procedure)
+-- Customer.TncSignature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TncSignature | Table | INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | TnC compliance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Sign a TnC document
```sql
EXEC Customer.SignTnc @gcid=12345, @documentId=101, @signDate=GETUTCDATE(), @reasonID=1
```

### 8.2 Sign with implicit consent
```sql
EXEC Customer.SignTnc @gcid=12345, @documentId=102, @signDate=GETUTCDATE(), @reasonID=0, @isImplicit=1
```

### 8.3 Read signatures
```sql
EXEC Customer.GetTncSignatures @gcid=12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.SignTnc | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.SignTnc.sql*
