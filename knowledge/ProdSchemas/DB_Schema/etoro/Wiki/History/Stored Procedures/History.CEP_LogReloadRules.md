# History.CEP_LogReloadRules

> Audit writer that logs each CEP rules engine reload event into History.CEP_ReloadRules, capturing the SQL Server login and application-level username of whoever triggered the reload.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No return value; simple fire-and-forget audit INSERT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.CEP_LogReloadRules` is the single writer for `History.CEP_ReloadRules`. It is called by the application layer whenever the CEP (Complex Event Processing) rules engine is signaled to reload its in-memory rule cache from the database. CEP rules govern trade processing logic; when rules are modified, the engine must be reloaded to pick up changes - and this procedure records that that reload happened, who triggered it, and when.

The procedure exists to provide an immutable audit trail for CEP reload operations. By capturing both the SQL Server login (`SUSER_NAME()`) and the application-supplied username (`@AppUserName`), the log shows the identity from both the database authentication layer and the application layer - useful for auditing in environments where multiple application accounts share a single SQL login.

There is no error handling and no return value. This is a fire-and-forget audit write: if the INSERT fails, no exception is surfaced. From live data, 54 reloads have been recorded, indicating this is an infrequent administrative operation triggered by rule configuration deployments.

---

## 2. Business Logic

### 2.1 Dual Identity Capture

**What**: The procedure captures two user identities simultaneously - the SQL Server login and the application-layer username.

**Columns/Parameters Involved**: `@AppUserName`, `SUSER_NAME()` (automatic)

**Rules**:
- `DBUserName` = `SUSER_NAME()` - the SQL Server login of the connection making the call (captured automatically, not passed as a parameter)
- `AppUserName` = `@AppUserName` - the application-layer identity supplied by the caller
- `Occurred` is not a parameter - it defaults to `GETUTCDATE()` in the target table
- From live data: DBUserName values are TRAD domain Windows accounts (Noah, dotanva, rivkaya, yardenmo); AppUserName matches the short username

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AppUserName | nvarchar(255) | NO | - | CODE-BACKED | Application-level username of the user who triggered the CEP rules reload. Stored as History.CEP_ReloadRules.AppUserName. Typically matches the short username portion of the SQL Server login (e.g., "noah" for TRAD\Noah). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @AppUserName | History.CEP_ReloadRules | Write target | Inserts the reload event audit row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External CEP management application | (application call) | Application | Called whenever the CEP rules engine reload is triggered. No SSDT procedures call this procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEP_LogReloadRules (procedure)
└── History.CEP_ReloadRules (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CEP_ReloadRules | Table | INSERT target - one audit row per reload event |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External CEP management application | Application | Calls this procedure to record each rules engine reload event |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. No TRY/CATCH - INSERT failures are silently swallowed by the caller. Target table is a heap with no PK constraint or indexes.

---

## 8. Sample Queries

### 8.1 Show recent CEP reload events

```sql
SELECT TOP 10
    ID,
    Occurred,
    DBUserName,
    AppUserName
FROM History.CEP_ReloadRules WITH (NOLOCK)
ORDER BY ID DESC
```

### 8.2 Count reloads per user

```sql
SELECT
    AppUserName,
    COUNT(*) AS ReloadCount,
    MIN(Occurred) AS FirstReload,
    MAX(Occurred) AS LastReload
FROM History.CEP_ReloadRules WITH (NOLOCK)
GROUP BY AppUserName
ORDER BY ReloadCount DESC
```

### 8.3 Find reloads within a date range

```sql
SELECT
    ID,
    Occurred,
    DBUserName,
    AppUserName
FROM History.CEP_ReloadRules WITH (NOLOCK)
WHERE Occurred >= '2026-01-01'
  AND Occurred < '2026-04-01'
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.CEP_LogReloadRules | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.CEP_LogReloadRules.sql*
