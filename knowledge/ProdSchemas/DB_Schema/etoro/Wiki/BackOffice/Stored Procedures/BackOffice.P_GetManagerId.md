# BackOffice.P_GetManagerId

> Returns the ManagerID for a manager identified by their login name (case-insensitive), used to resolve a username to an internal ID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT ManagerID FROM BackOffice.Manager WHERE LOWER(Login) = LOWER(@ManagerName) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.P_GetManagerId` resolves a manager login name to their numeric ManagerID. When external systems or UI components reference a manager by username (e.g., "jsmith") rather than ID, this procedure translates that to the ManagerID needed for database operations. The case-insensitive comparison (via LOWER()) accommodates login names entered in different cases.

Part of the back-office segregation framework (ticket 36240, May 2016). The `P_` prefix denotes it is a segregation-group procedure.

---

## 2. Business Logic

### 2.1 Case-Insensitive Login Lookup

**What**: Looks up ManagerID by login name using LOWER() on both sides for case-insensitive matching.

**Rules**:
- LOWER(@ManagerName) compared to LOWER(Login): handles "JSmith", "jsmith", "JSMITH" identically.
- Returns 0 or 1 rows (Login values are unique in BackOffice.Manager).
- Returns empty result set if name not found - no error raised.
- Does NOT filter on IsActive - returns ManagerID for inactive managers too.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ManagerName | varchar(300) | NO | - | CODE-BACKED | Login name of the manager to look up. Case-insensitive. Compared to BackOffice.Manager.Login via LOWER(). Accepts up to 300 characters (Manager.Login is varchar(50) in the table, so 300 is more than sufficient). |

Output: single column `ManagerID` (int) - the numeric ID of the manager with the matching login name.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ManagerName | BackOffice.Manager.Login | Reader | Case-insensitive name-to-ID resolution |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.P_GetManagerId (procedure)
+-- BackOffice.Manager (table) [SELECT source]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | SELECT ManagerID WHERE LOWER(Login) = LOWER(@ManagerName) |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get ManagerID by login name

```sql
EXEC BackOffice.P_GetManagerId @ManagerName = 'jsmith';
-- Returns ManagerID if found, empty result set if not
```

### 8.2 Direct equivalent with active-only filter

```sql
SELECT ManagerID, Login, IsActive
FROM BackOffice.Manager WITH (NOLOCK)
WHERE LOWER(Login) = LOWER('jsmith');
```

### 8.3 Check if a login exists (active managers)

```sql
SELECT ManagerID, Login, FirstName + ' ' + LastName AS FullName, IsActive
FROM BackOffice.Manager WITH (NOLOCK)
WHERE LOWER(Login) = LOWER('jsmith') AND IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.P_GetManagerId | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.P_GetManagerId.sql*
