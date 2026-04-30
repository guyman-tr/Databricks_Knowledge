# Customer.UpdatePasswordRemote

> Sets the Password field on Customer.Customer for the customer identified by GCID; a targeted remote setter with no validation logic.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid - GCID-based lookup for Customer.Customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdatePasswordRemote is a minimal password setter that writes a new password directly to Customer.Customer.Password for the customer identified by @gcid. The "Remote" suffix follows the pattern of other UpdateXxxRemote procedures in this schema - it updates the data store directly without queuing downstream action notifications.

The procedure performs no hashing, validation, or policy enforcement - it is a raw setter. Password hashing and validation are expected to have been applied by the calling service before invoking this procedure. It is used by external authentication services that communicate via GCID rather than CID.

---

## 2. Business Logic

### 2.1 Direct Password Update

**Rules**:
- UPDATE Customer.Customer SET Password = @password WHERE GCID = @gcid
- No validation, no hashing, no history logging within this procedure
- No ISNULL guard - a NULL @password would write NULL to the Password column
- No SET NOCOUNT ON (row-count message is returned)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. WHERE GCID = @gcid targets the Customer.Customer row for this customer. |
| 2 | @password | nvarchar(50) | NO | - | CODE-BACKED | New password value. Written directly to Customer.Customer.Password. Hashing/encoding is the caller's responsibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.Customer | Modifier | UPDATE Password column via GCID lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from authentication/password reset services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdatePasswordRemote (procedure)
└── Customer.Customer (view - UPDATE target for Password)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | UPDATE target for Password column via GCID lookup |

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
| No NULL guard | Risk | NULL @password writes NULL to Password column; caller must ensure non-NULL |
| No hashing | Contract | Caller is responsible for pre-hashing; procedure stores the value as-is |

---

## 8. Sample Queries

### 8.1 Update a customer's password
```sql
EXEC Customer.UpdatePasswordRemote @gcid = 67890, @password = 'hashed_password_value';
```

### 8.2 Verify password was updated (do not log in production)
```sql
SELECT CID, GCID FROM Customer.Customer WITH (NOLOCK) WHERE GCID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.3/10 (Elements: 10/10, Logic: 4/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdatePasswordRemote | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdatePasswordRemote.sql*
