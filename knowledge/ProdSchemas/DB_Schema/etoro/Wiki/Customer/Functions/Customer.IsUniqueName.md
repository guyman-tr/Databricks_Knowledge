# Customer.IsUniqueName

> Username availability check: returns 1 if the given username is already in use, 0 if it is available for registration.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Inline TVF |
| **Key Identifier** | @UserName varchar(20) (always returns exactly 1 row) |
| **Partition** | N/A |
| **Indexes** | N/A (function) |

---

## 1. Business Meaning

Customer.IsUniqueName checks whether a given username is already taken by an existing customer. It returns a single column `InUse`: 1 means the username is already registered, 0 means it is available.

Despite the name "IsUniqueName", the return value is inverted from what the name suggests: the function returns 1 when the name is NOT unique (already in use), not when it IS unique. The name reflects the question "is this a unique (available) name?" but the InUse column answers "is this name already in use?"

The function is used during customer registration flow to validate username availability before committing a new registration. It is also used by the stored procedure Customer.InsertRealCustomer and similar registration procedures to pre-check uniqueness.

---

## 2. Business Logic

### 2.1 Existence Check via EXISTS

**What**: Uses EXISTS for performance - short-circuits on first match rather than scanning all rows.

**Columns/Parameters Involved**: `InUse`, `@UserName`

**Rules**:
- `CASE WHEN EXISTS (SELECT * FROM Customer.Customer WITH (NOLOCK) WHERE UserName = @UserName) THEN 1 ELSE 0 END`
- Returns 1 (InUse) if ANY customer record has this username
- Returns 0 (available) if no customer has this username
- UserName comparison uses the column's native collation from CustomerStatic (Latin1_General_BIN - binary, case-sensitive)
- Note: the function ALWAYS returns exactly 1 row (no @UserName == no row is not possible with a CASE expression)

---

## 3. Data Overview

N/A for Inline TVF. The function always returns exactly 1 row with InUse = 0 or 1.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | varchar(20) | NO | - | VERIFIED | Username to check availability for. Case sensitivity depends on Customer.CustomerStatic.UserName collation (Latin1_General_BIN = binary/case-sensitive). |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InUse | int | NO | - | CODE-BACKED | 1 = username already exists in Customer.Customer (NOT available for new registration); 0 = username does not exist (available). Note: despite the function name "IsUniqueName", InUse=1 means the name is NOT unique. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (existence check) | Customer.Customer | EXISTS subquery WHERE UserName=@UserName | Username uniqueness lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used by registration workflows.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.IsUniqueName (function)
`-  Customer.Customer (view)
      |-  Customer.CustomerStatic (table)
      `-  Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | EXISTS subquery WHERE UserName=@UserName |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Always returns 1 row | Design | CASE expression guarantees exactly 1 row output regardless of existence result |
| WITH (NOLOCK) | Concurrency | Uses NOLOCK for performance during registration flow |

---

## 8. Sample Queries

### 8.1 Check if a username is available

```sql
SELECT InUse FROM Customer.IsUniqueName('john.doe99') WITH (NOLOCK);
-- InUse=0: available; InUse=1: already taken
```

### 8.2 Use in registration pre-check

```sql
DECLARE @Requested VARCHAR(20) = 'newuser123';
DECLARE @IsAvailable BIT;

SELECT @IsAvailable = CASE WHEN InUse = 0 THEN 1 ELSE 0 END
FROM Customer.IsUniqueName(@Requested) WITH (NOLOCK);

IF @IsAvailable = 1
    PRINT 'Username is available';
ELSE
    PRINT 'Username is taken - suggest alternative';
```

### 8.3 Bulk availability check for suggested usernames

```sql
SELECT
    u.SuggestedName,
    n.InUse,
    CASE WHEN n.InUse = 0 THEN 'Available' ELSE 'Taken' END AS Status
FROM (VALUES ('alice99'), ('alice100'), ('alice_trade')) u(SuggestedName)
CROSS APPLY Customer.IsUniqueName(u.SuggestedName) n;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 6.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (function) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.IsUniqueName | Type: Inline TVF | Source: etoro/etoro/Customer/Functions/Customer.IsUniqueName.sql*
