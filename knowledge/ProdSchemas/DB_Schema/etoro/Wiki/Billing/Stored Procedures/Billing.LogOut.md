# Billing.LogOut

> Writer procedure that closes an open Billing cashier/backoffice session by setting the LoggedOut timestamp on the most recent Billing.Login row for the given CID - effectively deprecated since 2017.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT - the customer/user whose session is being closed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LogOut closes a Billing cashier/backoffice login session by updating the LoggedOut timestamp on the most recent open session for a given CID. It finds the latest LoginID for the CID, then sets LoggedOut=GETUTCDATE() on that row. If no session exists for the CID, it raises error 60000.

This procedure is effectively deprecated. Billing.Login has not received new rows since May 2017, and the corresponding LogIn procedure is also inactive. The procedures and table still exist in the codebase as legacy infrastructure.

Note: There is a deliberate or inadvertent timestamp mismatch between LogIn (uses GETDATE() - server local time) and LogOut (uses GETUTCDATE() - UTC). This can cause LoggedOut to appear earlier than LoggedIn when the server is in a timezone ahead of UTC, which is visible in the historical session data as rows where LoggedOut < LoggedIn.

---

## 2. Business Logic

### 2.1 Session Close

**What**: Closes the most recent open session for a CID by setting its LoggedOut timestamp.

**Columns/Parameters Involved**: `@CID`

**Rules**:
- Finds the most recent LoginID via MAX(LoginID) WHERE CID=@CID.
- @@ROWCOUNT check: if SELECT returns 1 row (i.e., at least one Login row exists for the CID), proceeds to UPDATE. If 0 rows, raises error 60000.
- UPDATE sets LoggedOut=GETUTCDATE() on the identified LoginID.
- Does NOT check if the session is still open (LoggedOut IS NULL). It will overwrite LoggedOut even if the session was already closed.
- GETUTCDATE() is used for LoggedOut (UTC), but LogIn used GETDATE() (local). Cross-timezone deployments may result in LoggedOut < LoggedIn anomalies.
- No explicit RETURN or output - the procedure is void on success.
- No TRY/CATCH block - errors propagate to the caller unhandled.

**Diagram**:
```
Billing.LogOut(@CID)
    |
    v
SELECT @LoginID = MAX(LoginID) FROM Billing.Login WHERE CID = @CID
    |
    +-- @@ROWCOUNT = 1 -> UPDATE Billing.Login SET LoggedOut = GETUTCDATE() WHERE LoginID = @LoginID
    |
    +-- @@ROWCOUNT = 0 -> RAISERROR(60000, 16, 1, 'Billing.LogOut', @CID)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer/user identifier whose session is being closed. Used to SELECT MAX(LoginID) from Billing.Login. All historical rows: CID=20653 (single Billing backoffice account). |
| RETURN | (void) | - | - | CODE-BACKED | No explicit RETURN on success. On error: RAISERROR(60000,16,1,'Billing.LogOut',@CID) - error 60000 indicates "no session found" for the given CID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT/UPDATE | Billing.Login | READ+WRITE | Finds the most recent LoginID then updates its LoggedOut timestamp. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing cashier/backoffice application | - | EXEC | Legacy caller - no longer active since 2017. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LogOut (procedure)
└── Billing.Login (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Login | Table | SELECT MAX(LoginID) then UPDATE LoggedOut. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing cashier/backoffice application | Application | EXEC - historical caller (deprecated since 2017). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Close a session (legacy usage pattern)
```sql
EXEC Billing.LogOut @CID = 20653;
```

### 8.2 Verify the session was closed
```sql
SELECT TOP 1
    LoginID, CID, LoggedIn, LoggedOut,
    DATEDIFF(MINUTE, LoggedIn, LoggedOut) AS SessionMinutes
FROM Billing.Login WITH (NOLOCK)
WHERE CID = 20653
ORDER BY LoginID DESC;
```

### 8.3 Check for sessions that were never closed
```sql
SELECT LoginID, CID, LoggedIn, IP
FROM Billing.Login WITH (NOLOCK)
WHERE LoggedOut IS NULL
ORDER BY LoggedIn DESC;
-- Many rows have LoggedOut=NULL - LogOut SP was not reliably called
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.2/10 (Elements: 10/10, Logic: 6/10, Relationships: 4/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LogOut | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LogOut.sql*
