# History.GetUserLogins

> Returns the distinct application client types from which a customer has previously logged in, filtered to a caller-provided set of application names.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to check; @LoginTypes TVP - application filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.GetUserLogins` answers the question: "Has this customer ever logged in from these specific application types?" It queries `History.LoginOpenBook` - the archived login history table - and returns the distinct `ClientType` values (application names) for which the customer has login records matching the caller-provided filter list.

The procedure was originally created (2014) to check login history from a replica database ("Should query the replica db to know if the user has logged in from those application names"). The `dbo.LoginType` TVP allows the caller to define the specific application names to check, making the result set a filtered intersection of the customer's actual login types and the requested types.

Use case: determining whether a customer has ever used a specific platform variant (e.g., mobile app, web browser, OpenBook) - typically used in eligibility checks, onboarding flows, or fraud/compliance assessments.

---

## 2. Business Logic

### 2.1 TVP-Filtered Login Type Intersection

**What**: Returns only the ClientType values from the customer's login history that the caller explicitly requests to check.

**Columns/Parameters Involved**: `@LoginTypes`, `ClientType`, `@CID`

**Rules**:
- @LoginTypes contains ApplicationName values (via dbo.LoginType UDT) representing the application types the caller wants to check
- Only ClientType values that exist IN (@LoginTypes.ApplicationName) are returned
- If @LoginTypes is empty, no rows are returned (empty IN filter matches nothing)
- SELECT DISTINCT ensures each matching ClientType is returned only once, regardless of how many times the customer logged in from that application
- A return of zero rows means the customer has no login history from any of the requested application types

**Diagram**:
```
@CID + @LoginTypes (set of ApplicationName values)
        |
        v
History.LoginOpenBook
  WHERE CID = @CID
    AND ClientType IN (SELECT ApplicationName FROM @LoginTypes)
        |
        v
SELECT DISTINCT ClientType
(subset of @LoginTypes values that the customer has used)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Filters History.LoginOpenBook to only check login records for this customer. |
| 2 | @LoginTypes | dbo.LoginType | YES | READONLY TVP (empty = no results) | CODE-BACKED | Table-valued parameter containing the application names to check. Each row has an ApplicationName value. Only ClientType values matching these names are returned. Uses dbo.LoginType UDT. If empty, returns no rows. |

**Output columns** (returned by SELECT):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClientType | VARCHAR | YES | - | CODE-BACKED | The application name from which the customer has logged in, filtered to the requested set. From History.LoginOpenBook.ClientType. Examples: platform/application variant names (web, mobile app, etc.). Returned DISTINCT - one row per matching application type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.LoginOpenBook | Reads (filtered) | SELECT DISTINCT ClientType WHERE CID and ClientType IN TVP |
| @LoginTypes | dbo.LoginType | TVP parameter type | User-defined table type for passing the application name filter list |

### 5.2 Referenced By (other objects point to this)

No callers found in the etoro SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetUserLogins (procedure)
├── History.LoginOpenBook (table)
└── dbo.LoginType (user defined type - TVP parameter)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.LoginOpenBook | Table | SELECT - reads ClientType for the specified customer, filtered by TVP |
| dbo.LoginType | User Defined Type | Parameter type for @LoginTypes TVP |

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Note: Created 2014-02-04 by Guy Mansano. Original comment states it was designed for replica DB querying (now queries History.LoginOpenBook directly).

---

## 8. Sample Queries

### 8.1 Check if a customer has logged in from specific application types

```sql
DECLARE @loginTypes dbo.LoginType
INSERT INTO @loginTypes (ApplicationName) VALUES ('Web'), ('MobileAndroid'), ('MobileIOS')

EXEC History.GetUserLogins
    @CID = 12345,
    @LoginTypes = @loginTypes
```

### 8.2 Check for any login history from a single application type

```sql
DECLARE @loginTypes dbo.LoginType
INSERT INTO @loginTypes (ApplicationName) VALUES ('OpenBook')

EXEC History.GetUserLogins
    @CID = 12345,
    @LoginTypes = @loginTypes
```

### 8.3 Direct equivalent query on LoginOpenBook

```sql
SELECT DISTINCT ClientType
FROM History.LoginOpenBook WITH (NOLOCK)
WHERE CID = 12345
  AND ClientType IN ('Web', 'MobileAndroid', 'MobileIOS')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.GetUserLogins | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetUserLogins.sql*
