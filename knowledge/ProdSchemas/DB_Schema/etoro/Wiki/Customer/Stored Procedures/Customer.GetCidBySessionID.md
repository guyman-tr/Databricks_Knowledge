# Customer.GetCidBySessionID

> Resolves an active session GUID to the customer's CID by querying Customer.LoggedCustomer, enabling session-based authentication flows to obtain the canonical customer identifier.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SessionID (session GUID to resolve) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCidBySessionID resolves an active customer session token (a GUID) to the customer's CID. It queries Customer.LoggedCustomer - the table of currently authenticated sessions - returning the CID associated with the given session identifier.

The procedure exists for authentication middleware and session validation flows. When an inbound request arrives carrying a session token, the system needs to determine which customer the session belongs to before performing any customer-specific operation. This procedure is the lookup bridge between the session layer and the customer identity layer.

Customer.LoggedCustomer stores active sessions (customers currently logged in). If the session has expired or been invalidated, the row will not exist and the procedure returns an empty result set - the caller must handle an empty or missing CID as "session not found / not authenticated."

Note: unlike most Customer schema procedures, this one does NOT use WITH (NOLOCK). This is intentional for an authentication context - reading stale session data could allow a recently-logged-out customer to appear as still authenticated.

---

## 2. Business Logic

### 2.1 Session-to-CID Resolution

**What**: Returns the CID for an active session identified by its GUID.

**Columns/Parameters Involved**: `@SessionID`, `Customer.LoggedCustomer.CustomerSessionID`, `Customer.LoggedCustomer.CID`

**Rules**:
- SELECT CID FROM Customer.LoggedCustomer WHERE CustomerSessionID = @SessionID
- No NOLOCK (committed reads only - sessions must be real)
- Returns one row if session exists and is active; zero rows if expired or invalid
- No error raised on missing session - caller must check for empty result

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SessionID | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The session GUID (CustomerSessionID) to look up. This is the token passed by the client to identify their session. Returns CID of the customer who owns this session, or no rows if the session is not active. |

**Result set:**

| Column | Type | Description |
|--------|------|-------------|
| CID | INT | The customer's CID associated with this session. Single row if session exists; zero rows if session not found or expired. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SessionID | Customer.LoggedCustomer | Read | Session-to-CID lookup by CustomerSessionID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No callers found in SSDT repo. | - | Called by authentication/session validation services. | |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCidBySessionID (procedure)
+-- Customer.LoggedCustomer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.LoggedCustomer | Table | Active session store; SessionID -> CID lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. | - | Called by session/auth middleware. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No WITH (NOLOCK) | Design | Committed reads only - prevents stale session data from authenticating expired sessions |
| No NOCOUNT SET | Design | Row count returned (1 = found, 0 = not found) - callers can use @@ROWCOUNT to detect missing session |
| Empty result on missing session | Design | No RAISERROR - callers must handle empty result as authentication failure |

---

## 8. Sample Queries

### 8.1 Resolve a session to CID

```sql
EXEC Customer.GetCidBySessionID
    @SessionID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
-- Returns CID if session is active, no rows if expired/invalid
```

### 8.2 Equivalent inline resolution

```sql
SELECT CID
FROM Customer.LoggedCustomer
WHERE CustomerSessionID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCidBySessionID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetCidBySessionID.sql*
