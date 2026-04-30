# Billing.LogIn

> Writer procedure that records a Billing cashier/backoffice login event into the legacy Billing.Login session table - effectively deprecated since the table stopped receiving new rows in 2017.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT - the customer/user initiating the session |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LogIn records a login event into the legacy Billing.Login session table. It accepts the customer ID, manager ID, and the originating IP address, then inserts a new session row with LoggedIn=GETDATE() and LoggedOut=NULL. The session is later closed by Billing.LogOut (which sets LoggedOut=GETUTCDATE()).

This procedure is effectively deprecated. Billing.Login has not received new rows since May 2017, and all 384 historical rows belong to a single CID (20653) - a Billing backoffice account. The procedure still exists in the codebase and the table schema is intact, but it no longer receives production traffic. It is kept for potential rollback or audit purposes.

Note: The procedure uses GETDATE() (server local time) to record LoggedIn. Billing.LogOut uses GETUTCDATE(). This timestamp inconsistency means LoggedOut can appear earlier than LoggedIn in certain timezone configurations - a known data anomaly visible in the historical session records.

---

## 2. Business Logic

### 2.1 Session Creation

**What**: Creates a new open session row in Billing.Login.

**Columns/Parameters Involved**: `@CID`, `@ManagerID`, `@IP`

**Rules**:
- Inserts into Billing.Login: (CID, LoggedIn=GETDATE(), ManagerID=@ManagerID, IP=@IP).
- LoggedOut is NOT set - remains NULL until Billing.LogOut is called.
- GETDATE() is used (NOT GETUTCDATE()) - stores server local time, not UTC. This is a known inconsistency with LogOut which uses GETUTCDATE().
- @ManagerID is always passed as 0 in practice - the supervised-session design was never used.
- @IP is a char(15) - fixed-width IPv4 address. Values observed: 127.0.0.1 (loopback) and eToro office IPs.
- Returns @@ERROR (0 on success). Uses TRY/CATCH: on exception, RAISERROR with full error message + line + number, then returns ERROR_NUMBER().

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer/user identifier for the session owner. Written as CID to Billing.Login. All historical rows: CID=20653 (single Billing backoffice account). |
| 2 | @ManagerID | INT | NO | - | CODE-BACKED | Supervising manager identifier. Always 0 in practice - the supervised-session functionality was never implemented. Written as ManagerID to Billing.Login. |
| 3 | @IP | char(15) | NO | - | CODE-BACKED | IPv4 address of the logging-in client, as a fixed-length 15-character string. Written as IP to Billing.Login. Examples: '127.0.0.1      ' (loopback) or '194.105.145.92 ' (office IP). |
| RETURN | int | NO | - | CODE-BACKED | Returns @@ERROR (0 on success). On exception: RAISERROR with full error message + line + number, returns ERROR_NUMBER(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | Billing.Login | WRITE | Creates a new session row in the legacy login table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing cashier/backoffice application | - | EXEC | Legacy caller - no longer active since 2017. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LogIn (procedure)
└── Billing.Login (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Login | Table | INSERT - creates a new session row. |

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

### 8.1 Record a login (legacy usage pattern)
```sql
EXEC Billing.LogIn
    @CID = 20653,
    @ManagerID = 0,
    @IP = '127.0.0.1      ';
```

### 8.2 Verify the last session was created
```sql
SELECT TOP 1
    LoginID, CID, LoggedIn, LoggedOut, ManagerID, IP
FROM Billing.Login WITH (NOLOCK)
WHERE CID = 20653
ORDER BY LoginID DESC;
```

### 8.3 Find sessions with the timestamp inconsistency (LoggedOut < LoggedIn)
```sql
SELECT LoginID, CID, LoggedIn, LoggedOut,
    DATEDIFF(MINUTE, LoggedIn, LoggedOut) AS SessionMinutes
FROM Billing.Login WITH (NOLOCK)
WHERE LoggedOut IS NOT NULL
  AND LoggedOut < LoggedIn
ORDER BY LoginID DESC;
-- Caused by LogIn using GETDATE() (local) and LogOut using GETUTCDATE() (UTC)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 10/10, Logic: 6/10, Relationships: 4/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LogIn | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LogIn.sql*
