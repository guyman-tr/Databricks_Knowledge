# Customer.RetrieveRealPassword

> Retrieves the auto-login password for a real account by username via the STS cross-database function F_Get_OBtoWT_AutoLoginUserPasswordByUsername; functionally identical to Customer.RetrieveDemoPassword.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @UserName VARCHAR(24) - the real account username to look up |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.RetrieveRealPassword` retrieves the auto-login token for a real (live) customer account from the STS system by username. The procedure is functionally identical to `Customer.RetrieveDemoPassword` - both call the same STS function `STS.[F_Get_OBtoWT_AutoLoginUserPasswordByUsername]`. The distinction exists only at the naming/semantic level: one is called in the context of demo accounts, the other for real accounts.

The STS function handles both real and demo customers internally. These are thin wrapper procedures to provide clear intent at the call site.

---

## 2. Business Logic

### 2.1 STS Auto-Login Password Retrieval

**What**: Delegates password retrieval to the STS cross-database function.

**Rules**:
- Single SELECT: `STS.[F_Get_OBtoWT_AutoLoginUserPasswordByUsername](@UserName)`.
- Returns the function's result directly.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserName | VARCHAR(24) | NO | - | CODE-BACKED | Real account username. Passed to STS.F_Get_OBtoWT_AutoLoginUserPasswordByUsername. |

**Returned:**
- Single scalar: auto-login password for the account; NULL if username not found.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserName | STS.F_Get_OBtoWT_AutoLoginUserPasswordByUsername | CALL (cross-DB) | Retrieves auto-login token from STS system |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | External call | Caller | Used to get real account auto-login credentials |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RetrieveRealPassword (procedure)
└── STS.F_Get_OBtoWT_AutoLoginUserPasswordByUsername (cross-DB function) [CALL]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| STS.F_Get_OBtoWT_AutoLoginUserPasswordByUsername | Cross-DB Function | CALL - actual password retrieval |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application layer | External | Calls for real account auto-login |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| STS dependency | External | Requires STS database connectivity |
| Identical to RetrieveDemoPassword | Design | Same STS function called; distinction is semantic only |

---

## 8. Sample Queries

### 8.1 Retrieve real password for a username

```sql
EXEC Customer.RetrieveRealPassword @UserName = 'realuser123'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 7.5/10, Logic: 7.5/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RetrieveRealPassword | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.RetrieveRealPassword.sql*
