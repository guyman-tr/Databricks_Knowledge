# Customer.UpdateIsEmailActivated2

> Updates a customer's email address and email activation state via GCID-or-CID routing using parameterized UPDATEs - the safe successor to UpdateIsEmailActivated that eliminates the dynamic SQL SQL-injection risk.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (if > 0) or @CID (fallback) - dual-path routing |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateIsEmailActivated2 is the safe successor to Customer.UpdateIsEmailActivated. It implements the same dual-path logic (GCID route to legacy tables, CID route to Customer.Customer) but uses parameterized UPDATE statements throughout, eliminating the SQL injection risk present in the "v1" procedure.

The suffix "2" identifies this as the second/replacement version. New callers should use UpdateIsEmailActivated2 over the original UpdateIsEmailActivated. Both procedures are maintained for backwards compatibility with existing callers.

Data flow: called from email verification flows when a customer confirms or resets their email address. @Activated=1 marks the email as verified; @Activated=0 clears verification. Applies to both legacy (RealCustomers/DemoCustomers) and current (Customer.Customer) tables depending on whether @GCID is provided.

---

## 2. Business Logic

### 2.1 GCID vs CID Routing (Parameterized)

**What**: Routes update to legacy tables or current Customer schema, using fully parameterized statements.

**Rules**:
- IF ISNULL(@GCID, 0) > 0: UPDATE RealCustomers SET Email=@Email, IsEmailActivated=@Activated WHERE GCID=@GCID
  AND UPDATE DemoCustomers SET Email=@Email, IsEmailActivated=@Activated WHERE GCID=@GCID
- ELSE: UPDATE Customer.Customer SET Email=@Email, IsEmailActivated=@Activated WHERE CID=@CID
- No dynamic SQL - all parameters bound safely

**Diagram**:
```
ISNULL(@GCID, 0) > 0?
  YES -> UPDATE RealCustomers SET Email=@Email, IsEmailActivated=@Activated WHERE GCID=@GCID
         UPDATE DemoCustomers SET Email=@Email, IsEmailActivated=@Activated WHERE GCID=@GCID
  NO  -> UPDATE Customer.Customer SET Email=@Email, IsEmailActivated=@Activated WHERE CID=@CID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer CID. Used in the fallback path (GCID=0/NULL): UPDATE Customer.Customer WHERE CID=@CID. |
| 2 | @Email | varchar(50) | NO | - | CODE-BACKED | New email address. Applied to both Email columns in either path. Parameterized safely (no dynamic SQL in this version). |
| 3 | @Activated | tinyint | NO | - | CODE-BACKED | Email activation state: 1 = email is activated/verified, 0 = not activated. Maps to IsEmailActivated in both legacy tables and Customer.Customer. |
| 4 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. If ISNULL(@GCID, 0) > 0, routes to legacy RealCustomers + DemoCustomers via parameterized UPDATE. If 0 or NULL, falls back to CID-based update on Customer.Customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID (> 0) | RealCustomers (legacy) | Modifier | Parameterized UPDATE of Email and IsEmailActivated |
| @GCID (> 0) | DemoCustomers (legacy) | Modifier | Parameterized UPDATE of Email and IsEmailActivated |
| @CID (fallback) | Customer.Customer | Modifier | Parameterized UPDATE of Email and IsEmailActivated |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from email verification flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateIsEmailActivated2 (procedure)
├── RealCustomers (legacy table - parameterized UPDATE, GCID path)
├── DemoCustomers (legacy table - parameterized UPDATE, GCID path)
└── Customer.Customer (view - parameterized UPDATE, CID path)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RealCustomers | Table (legacy) | Parameterized UPDATE for Email + IsEmailActivated via GCID |
| DemoCustomers | Table (legacy) | Parameterized UPDATE for Email + IsEmailActivated via GCID |
| Customer.Customer | View | Parameterized UPDATE for Email + IsEmailActivated via CID |

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
| Parameterized UPDATE | Security | Unlike UpdateIsEmailActivated, all parameters are bound - no SQL injection risk |
| GCID routing | Business rule | ISNULL(@GCID, 0) > 0 determines which code path executes |

---

## 8. Sample Queries

### 8.1 Mark email as activated for a GCID-based customer
```sql
EXEC Customer.UpdateIsEmailActivated2
    @CID = 0, @Email = 'user@example.com', @Activated = 1, @GCID = 67890;
```

### 8.2 Mark email as activated via CID
```sql
EXEC Customer.UpdateIsEmailActivated2
    @CID = 12345, @Email = 'user@example.com', @Activated = 1, @GCID = 0;
```

### 8.3 Check email activation state
```sql
SELECT CID, GCID, Email, IsEmailActivated
FROM Customer.Customer WITH (NOLOCK)
WHERE GCID = 67890;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateIsEmailActivated2 | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateIsEmailActivated2.sql*
