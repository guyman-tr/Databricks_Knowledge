# Customer.UpdateRegistrationRequest

> Stamps the OriginalProviderID and OriginalCID fields on an existing Customer.RegistrationRequest record identified by its GUID, completing the registration lineage after account creation.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RegistrationRequestID (VARCHAR cast to UNIQUEIDENTIFIER) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateRegistrationRequest writes back the resolved OriginalProviderID and OriginalCID onto a registration request after account creation is complete. Registration requests are created at the start of the sign-up flow (by Customer.InsertRegistrationRequest or similar); at that point the final CID and provider assignment may not yet be known. Once the account is created and the CID is assigned, this procedure closes the loop by stamping those values onto the request record.

OriginalProviderID identifies which liquidity/hedge provider was assigned to the customer. OriginalCID records the CID that was generated for this registration (for correlation between the request GUID and the internal customer ID).

The @RegistrationRequestID is accepted as VARCHAR(150) but converted to UNIQUEIDENTIFIER internally, allowing callers that hold the GUID as a string to pass it without explicit casting.

---

## 2. Business Logic

### 2.1 Registration Request Update

**Rules**:
- UPDATE Customer.RegistrationRequest SET OriginalProviderID=@OriginalProviderID, OriginalCID=@OriginalCID
- WHERE RegistrationRequestID = CONVERT(UNIQUEIDENTIFIER, @RegistrationRequestID)
- @RegistrationRequestID: VARCHAR(150) input; CONVERT to UNIQUEIDENTIFIER at query time - invalid GUIDs cause a conversion error
- Returns @@ERROR (0 = success, non-zero = SQL error code)
- No ISNULL guard - NULL @OriginalProviderID or @OriginalCID writes NULL

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegistrationRequestID | varchar(150) | NO | - | CODE-BACKED | GUID identifying the registration request row. Passed as string; converted to UNIQUEIDENTIFIER in the WHERE clause. Must be a valid GUID string or conversion fails. |
| 2 | @OriginalProviderID | int | NO | - | CODE-BACKED | Liquidity/hedge provider assigned to this customer. Written to Customer.RegistrationRequest.OriginalProviderID. |
| 3 | @OriginalCID | int | NO | - | CODE-BACKED | Customer CID assigned during account creation. Written to Customer.RegistrationRequest.OriginalCID, linking the request GUID to the internal customer identity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RegistrationRequestID | Customer.RegistrationRequest | Modifier | UPDATE OriginalProviderID + OriginalCID via GUID lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from registration completion flows after CID assignment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateRegistrationRequest (procedure)
└── Customer.RegistrationRequest (table - UPDATE target)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.RegistrationRequest | Table | UPDATE target: OriginalProviderID and OriginalCID columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| GUID conversion | Input validation | CONVERT(UNIQUEIDENTIFIER, @RegistrationRequestID) - invalid GUID strings cause a runtime conversion error |
| @@ERROR return | Error handling | Procedure returns the SQL error code; 0 = success; non-zero signals the caller of a failure |

---

## 8. Sample Queries

### 8.1 Stamp OriginalProviderID and OriginalCID after account creation
```sql
EXEC Customer.UpdateRegistrationRequest
    @RegistrationRequestID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @OriginalProviderID = 5,
    @OriginalCID = 12345;
```

### 8.2 Verify the update
```sql
SELECT RegistrationRequestID, OriginalProviderID, OriginalCID
FROM Customer.RegistrationRequest WITH (NOLOCK)
WHERE RegistrationRequestID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateRegistrationRequest | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateRegistrationRequest.sql*
