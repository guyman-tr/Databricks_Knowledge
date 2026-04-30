# Customer.RetrieveDemoPassword

> Retrieves the auto-login password for a demo account by username via the STS cross-database function F_Get_OBtoWT_AutoLoginUserPasswordByUsername.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserName VARCHAR(24) - the demo account username to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.RetrieveDemoPassword` is a thin wrapper around the STS (Security Token Service) cross-database function for retrieving demo account auto-login credentials. The STS system manages actual password storage and authentication - this procedure provides a clean entry point for the application layer to retrieve the current auto-login token for a demo account given its username.

The function `STS.[F_Get_OBtoWT_AutoLoginUserPasswordByUsername]` lives in the STS database (cross-DB call via the STS schema). The "OBtoWT" naming convention indicates "OpenBook to WebTrader" - a legacy naming from when the demo environment was called "OpenBook" and the trading platform was "WebTrader".

Note: `Customer.RetrieveRealPassword` (#23) contains identical code - both call the same STS function. The distinction is purely semantic (naming/context), as the same STS function handles both real and demo usernames.

---

## 2. Business Logic

### 2.1 STS Auto-Login Password Retrieval

**What**: Delegates password retrieval entirely to the STS cross-database function.

**Rules**:
- Single SELECT: `STS.[F_Get_OBtoWT_AutoLoginUserPasswordByUsername](@UserName)`.
- Returns the function's result directly to the caller.
- No local variables, no error handling, no table access.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | VARCHAR(24) | NO | - | CODE-BACKED | Demo account username. Passed directly to STS.F_Get_OBtoWT_AutoLoginUserPasswordByUsername. |

**Returned:**
- Single scalar value: the auto-login password for the demo account; NULL if username not found.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserName | STS.F_Get_OBtoWT_AutoLoginUserPasswordByUsername | CALL (cross-DB) | Retrieves auto-login token from STS system |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | External call | Caller | Used to get demo auto-login credentials |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RetrieveDemoPassword (procedure)
└── STS.F_Get_OBtoWT_AutoLoginUserPasswordByUsername (cross-DB function) [CALL]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| STS.F_Get_OBtoWT_AutoLoginUserPasswordByUsername | Cross-DB Function | CALL - actual password retrieval |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | External | Calls for demo auto-login |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| STS dependency | External | Requires STS database connectivity; no fallback |
| No error handling | Design | Any STS failure propagates directly to the caller |

---

## 8. Sample Queries

### 8.1 Retrieve demo password for a username

```sql
EXEC Customer.RetrieveDemoPassword @UserName = 'testuser123'
```

### 8.2 Check if a username exists in Customer.Customer

```sql
SELECT CID, GCID, UserName, IsReal
FROM Customer.Customer WITH (NOLOCK)
WHERE UserName_LOWER = LOWER('testuser123')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8.0/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RetrieveDemoPassword | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.RetrieveDemoPassword.sql*
