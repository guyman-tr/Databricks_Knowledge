# Customer.CustomersByOriginalCID

> Looks up customers by username (case-insensitive) via a remote procedure on the etoro database, delegating through a synonym to [etoro].[Customer].[GetCustomersByOriginalCID].

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserName (lookup key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.CustomersByOriginalCID is a thin wrapper that looks up customers by their username. Despite its name suggesting "OriginalCID" (original Customer ID), the input is actually a username string, and the procedure delegates to a remote procedure that performs the actual lookup on the etoro database.

This procedure exists as a local entry point for username-based customer lookups. It normalizes the input to lowercase for case-insensitive matching, then routes the call to the remote etoro database where the full customer data resides.

Data flows in as a username string, gets lowercased, and is passed to dbo.GetCustomersByOriginalCID - a synonym pointing to [etoro].[Customer].[GetCustomersByOriginalCID] on the etoro database. The remote procedure executes the actual lookup and returns the result set.

---

## 2. Business Logic

### 2.1 Case-Insensitive Username Matching

**What**: All username lookups are normalized to lowercase before execution.

**Columns/Parameters Involved**: `@UserName`

**Rules**:
- The input @UserName is converted to lowercase via LOWER() before being passed to the remote procedure
- This ensures case-insensitive matching regardless of how the caller formats the username
- The LOWER() conversion happens locally before the cross-database call

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | varchar(20) | NO | - | CODE-BACKED | The username to search for. Converted to lowercase internally for case-insensitive matching. Maximum 20 characters, matching the username field constraints in Customer.BasicUserInfo. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | dbo.GetCustomersByOriginalCID | EXEC (synonym) | Delegates lookup to [etoro].[Customer].[GetCustomersByOriginalCID] |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by services performing username-based customer lookups |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CustomersByOriginalCID (procedure)
+-- dbo.GetCustomersByOriginalCID (synonym)
      +-- [etoro].[Customer].[GetCustomersByOriginalCID] (remote procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.GetCustomersByOriginalCID | Synonym | EXEC - delegates the actual customer lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up a customer by username
```sql
EXEC Customer.CustomersByOriginalCID @UserName = 'johndoe123'
```

### 8.2 Look up with mixed-case username (case-insensitive)
```sql
EXEC Customer.CustomersByOriginalCID @UserName = 'JohnDoe123'
-- Internally converted to 'johndoe123' before lookup
```

### 8.3 Call from dynamic context
```sql
DECLARE @uname varchar(20) = 'traderx'
EXEC Customer.CustomersByOriginalCID @UserName = @uname
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CustomersByOriginalCID | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.CustomersByOriginalCID.sql*
