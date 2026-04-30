# BackOffice.GetLastLoginDate_JunkByRan_251124

> DEPRECATED scalar function returning the most recent login datetime for a customer, checking the active login table first and falling back to the login history archive if no active record exists.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DATETIME - most recent login timestamp |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetLastLoginDate_JunkByRan_251124` returns the date and time of the most recent platform login for a given customer (CID). It implements a two-tier lookup: first checking `Customer.Login` (the active/current login table), and if no record exists there, falling back to `History.Login` (the login history archive).

**DEPRECATED**: The "JUNK" and "ByRan_251124" (created by Ran on 25/11/24) suffixes indicate this is a non-production legacy function created for a specific analysis or debugging task in November 2024. No active stored procedures in the BackOffice schema call this function.

The two-source lookup pattern reflects the login data architecture: recent logins may be in `Customer.Login`, while older logins are archived in `History.Login`. The function uses IF EXISTS to choose the source, then returns MAX(LoggedIn) from whichever table has records for the CID.

---

## 2. Business Logic

### 2.1 Two-Tier Login Source Fallback

**What**: Checks the active login table first; only reads the historical archive if no current record exists for the customer.

**Columns/Parameters Involved**: `@CID`, `@LoginDate`

**Rules**:
- IF EXISTS: `SELECT 1 FROM Customer.Login WITH(NOLOCK) WHERE CID = @CID`
  - If TRUE: `SELECT @LoginDate = MAX(LoggedIn) FROM Customer.Login WITH (NOLOCK) WHERE CID = @CID`
  - If FALSE: `SELECT @LoginDate = MAX(LoggedIn) FROM History.Login WITH (NOLOCK) WHERE CID = @CID`
- Returns NULL (implicit) if no record found in either table for the CID.
- The function does NOT combine both tables - it reads one or the other based on Customer.Login existence check.
- A customer present in Customer.Login will NOT have History.Login records included in the MAX().

**Diagram**:
```
@CID
  |
  v
IF EXISTS in Customer.Login?
  |
  YES --> MAX(LoggedIn) from Customer.Login
  NO  --> MAX(LoggedIn) from History.Login
  |
  v
Return most recent login DATETIME (or NULL if never logged in)
```

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID of the customer whose last login date to retrieve. Used to filter both Customer.Login and History.Login. |

### Return Value

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LoginDate | DATETIME | YES | NULL | CODE-BACKED | The most recent login timestamp (MAX(LoggedIn)) for the customer. Returns NULL if the customer has no login records in either Customer.Login or History.Login. For customers present in Customer.Login, only current login records are considered; for customers only in History.Login, the most recent archived login is returned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Login | Table read | Primary source: checked first for CID existence and used for MAX(LoggedIn) if the customer has active login records. |
| @CID | History.Login | Table read | Fallback source: read only if Customer.Login has no record for the CID. Provides historical login data for archived customers. |

### 5.2 Referenced By (other objects point to this)

No active callers found. Function is deprecated (JUNK prefix).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetLastLoginDate_JunkByRan_251124 (function)
├── Customer.Login (table) [cross-schema]
└── History.Login (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Login | Table | Read WITH (NOLOCK): IF EXISTS check plus MAX(LoggedIn) query for customers with active login records. |
| History.Login | Table | Read WITH (NOLOCK): MAX(LoggedIn) fallback for customers not found in Customer.Login. |

### 6.2 Objects That Depend On This

No dependents found. Deprecated function - no active callers in BackOffice schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

N/A for Scalar Function.

---

## 8. Sample Queries

### 8.1 Get last login date for a specific customer

```sql
SELECT BackOffice.GetLastLoginDate_JunkByRan_251124(12345) AS LastLoginDate;
-- Returns DATETIME or NULL
```

### 8.2 Modern alternative - direct query from both tables (preferred)

```sql
SELECT MAX(LoggedIn) AS LastLoginDate
FROM (
    SELECT LoggedIn FROM Customer.Login WITH (NOLOCK) WHERE CID = 12345
    UNION ALL
    SELECT LoggedIn FROM History.Login WITH (NOLOCK) WHERE CID = 12345
) combined;
```

### 8.3 Check if a customer has ever logged in

```sql
SELECT
    CASE WHEN BackOffice.GetLastLoginDate_JunkByRan_251124(12345) IS NULL
         THEN 'Never Logged In'
         ELSE 'Last Login: ' + CAST(BackOffice.GetLastLoginDate_JunkByRan_251124(12345) AS VARCHAR)
    END AS LoginStatus;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetLastLoginDate_JunkByRan_251124 | Type: Scalar Function | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetLastLoginDate_JunkByRan_251124.sql*
