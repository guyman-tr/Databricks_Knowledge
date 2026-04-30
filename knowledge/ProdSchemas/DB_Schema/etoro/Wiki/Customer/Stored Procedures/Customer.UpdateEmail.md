# Customer.UpdateEmail

> Updates a customer's email address on Customer.Customer by GCID, with a guard condition that prevents accidental NULL/zero GCID updates.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID - GCID-based lookup for Customer.Customer |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateEmail is a targeted setter for a customer's email address using GCID as the lookup key. The procedure updates Customer.Customer.Email for the customer identified by @GCID. A guard condition (AND GCID IS NOT NULL AND GCID > 0) in the WHERE clause prevents the UPDATE from running if @GCID is NULL or zero, avoiding accidental mass-updates on rows without a GCID.

The procedure is used when an email change needs to be applied via the GCID path (as opposed to CID-based setters). This is common when external systems know the GCID but not the CID.

---

## 2. Business Logic

### 2.1 GCID-Guarded Email Update

**Rules**:
- UPDATE Customer.Customer SET Email = @Email WHERE GCID = @GCID AND GCID IS NOT NULL AND GCID > 0
- The triple condition (GCID = @GCID, GCID IS NOT NULL, GCID > 0) prevents any update if @GCID is NULL or 0
- If @GCID is 0 or NULL: WHERE clause matches 0 rows, no update occurs (silent no-op)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. Used in WHERE GCID = @GCID AND GCID IS NOT NULL AND GCID > 0. Guards against 0/NULL GCIDs. |
| 2 | @Email | varchar(50) | NO | - | CODE-BACKED | New email address for the customer. SET directly into Customer.Customer.Email for the matching GCID row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.Customer | Modifier | Updates Email column via GCID lookup with NULL/zero guard |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from email change flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateEmail (procedure)
└── Customer.Customer (view - UPDATE target)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | UPDATE target for Email column via GCID lookup |

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
| GCID guard | Safety | WHERE GCID = @GCID AND GCID IS NOT NULL AND GCID > 0 prevents NULL/zero GCID updates |

---

## 8. Sample Queries

### 8.1 Update a customer's email address
```sql
EXEC Customer.UpdateEmail @GCID = 67890, @Email = 'newemail@example.com';
```

### 8.2 Verify email was updated
```sql
SELECT CID, GCID, Email FROM Customer.Customer WITH (NOLOCK) WHERE GCID = 67890;
```

### 8.3 Find customers with a specific email domain
```sql
SELECT CID, GCID, Email FROM Customer.Customer WITH (NOLOCK)
WHERE Email LIKE '%@example.com' ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateEmail | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateEmail.sql*
