# Customer.UpdateIsEmailActivated

> Updates a customer's email address and email activation state via GCID-or-CID routing, with GCID-based updates applied to legacy RealCustomers and DemoCustomers via dynamic SQL, and CID-based updates applied to Customer.Customer.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (if > 0) or @CID (fallback) - dual-path routing |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateIsEmailActivated is a legacy dual-path procedure that updates both Email and IsEmailActivated for a customer. When @GCID is provided (> 0), it updates the legacy RealCustomers and DemoCustomers tables using dynamic SQL. When @GCID is 0 or NULL, it falls back to updating Customer.Customer by @CID.

The existence of two code paths reflects the platform's migration from legacy RealCustomers/DemoCustomers tables to the unified Customer schema. The GCID path exists for backwards compatibility with legacy systems or administrative tools that still operate on the old table structure.

**NOTE**: The GCID-based dynamic SQL path in this procedure directly concatenates @Email into the SQL string without parameterization, which is a SQL injection risk. The companion procedure UpdateIsEmailActivated2 resolves this by using parameterized updates.

Data flow: called from email verification flows when a customer confirms their email address. @Activated = 1 marks the email as verified; @Activated = 0 clears the verification. Both procedures (this and UpdateIsEmailActivated2) exist - callers should prefer UpdateIsEmailActivated2 which avoids dynamic SQL.

---

## 2. Business Logic

### 2.1 GCID vs CID Routing

**What**: Routes the update to legacy tables (GCID path) or the current Customer schema (CID path) based on @GCID value.

**Columns/Parameters Involved**: `@GCID`, `@CID`

**Rules**:
- IF ISNULL(@GCID, 0) > 0: update RealCustomers + DemoCustomers via dynamic SQL WHERE GCID = @GCID
- ELSE: update Customer.Customer WHERE CID = @CID
- Both paths set Email = @Email and IsEmailActivated = @Activated

**Diagram**:
```
ISNULL(@GCID, 0) > 0?
  YES -> Dynamic SQL: UPDATE RealCustomers SET Email, IsEmailActivated WHERE GCID=@GCID
         Dynamic SQL: UPDATE DemoCustomers SET Email, IsEmailActivated WHERE GCID=@GCID
  NO  -> UPDATE Customer.Customer SET Email, IsEmailActivated WHERE CID=@CID
```

### 2.2 Dynamic SQL in GCID Path (Security Note)

**What**: The GCID path builds the UPDATE statement by string concatenation, creating a SQL injection exposure for the @Email parameter.

**Rules**:
- @Email is embedded as: `SET Email = ''' + @Email + ''''` - wrapped with escaped single quotes
- A malicious @Email value with embedded quotes or statement terminators could alter the SQL statement
- @Activated and @GCID are CAST to varchar (integer types) - safe from injection
- UpdateIsEmailActivated2 replaces this pattern with parameterized UPDATEs - use that procedure instead when possible

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer CID. Used in the fallback path (GCID=0/NULL): UPDATE Customer.Customer WHERE CID=@CID. |
| 2 | @Email | varchar(50) | NO | - | CODE-BACKED | New email address. Applied to both Email columns in either path. In the GCID path, directly concatenated into dynamic SQL - see Security Note in Section 2.2. |
| 3 | @Activated | tinyint | NO | - | CODE-BACKED | Email activation state: 1 = email is activated/verified, 0 = not activated. Maps to IsEmailActivated in both legacy tables and Customer.Customer. |
| 4 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. If ISNULL(@GCID, 0) > 0, routes to legacy RealCustomers + DemoCustomers tables via dynamic SQL. If 0 or NULL, falls back to CID path on Customer.Customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID (> 0) | RealCustomers (legacy) | Modifier | Dynamic SQL UPDATE of Email and IsEmailActivated |
| @GCID (> 0) | DemoCustomers (legacy) | Modifier | Dynamic SQL UPDATE of Email and IsEmailActivated |
| @CID (fallback) | Customer.Customer | Modifier | Parameterized UPDATE of Email and IsEmailActivated |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from email verification flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateIsEmailActivated (procedure)
├── RealCustomers (legacy table - dynamic SQL UPDATE, GCID path)
├── DemoCustomers (legacy table - dynamic SQL UPDATE, GCID path)
└── Customer.Customer (view - parameterized UPDATE, CID path)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RealCustomers | Table (legacy) | Dynamic SQL UPDATE for Email + IsEmailActivated via GCID |
| DemoCustomers | Table (legacy) | Dynamic SQL UPDATE for Email + IsEmailActivated via GCID |
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
| Dynamic SQL (GCID path) | Implementation note | @Email is directly concatenated into SQL string - SQL injection risk. Prefer UpdateIsEmailActivated2 which uses parameterized UPDATEs. |
| GCID routing | Business rule | ISNULL(@GCID, 0) > 0 determines which code path executes |

---

## 8. Sample Queries

### 8.1 Mark email as activated for a GCID-based customer (prefer UpdateIsEmailActivated2)
```sql
EXEC Customer.UpdateIsEmailActivated
    @CID = 0, @Email = 'user@example.com', @Activated = 1, @GCID = 67890;
```

### 8.2 Mark email as activated via CID fallback
```sql
EXEC Customer.UpdateIsEmailActivated
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
*Object: Customer.UpdateIsEmailActivated | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateIsEmailActivated.sql*
