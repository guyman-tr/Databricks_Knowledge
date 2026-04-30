# History.NamedLists

> SQL Server temporal history table automatically maintained by the database engine, recording every past state of CEP.NamedLists - the CEP (Customer Engagement Platform) configuration table that defines named customer segments and their SQL-based population queries.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite: (SysEndTime, SysStartTime) - temporal history clustered index |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

History.NamedLists is the temporal history backing table for CEP.NamedLists. It is automatically populated by SQL Server's SYSTEM_VERSIONING mechanism whenever rows in CEP.NamedLists are inserted, updated, or deleted.

CEP.NamedLists defines named customer lists used by the Customer Engagement Platform (CEP) - eToro's system for targeting customers with notifications, promotions, and risk interventions. Each named list has a SQL `Statment` (stored procedure call) that, when executed, populates the list with customer IDs matching the criteria. For example, "Large AUM" (NamedListID=1) runs every 1700 seconds (~28 minutes), identifying customers with large assets under management.

With 3,377 history rows, this table provides a complete audit trail of every configuration change to CEP's customer targeting lists - who changed the list definition, when, and what it was changed to/from. This is critical for compliance (demonstrating that targeting criteria changes were intentional and authorized) and debugging (identifying when a list definition was last changed before an unexpected campaign behavior).

The `Tr_T_NamedLists_INSERT` trigger on CEP.NamedLists performs a no-op UPDATE (SET Name=Name) after every INSERT, forcing the newly created list configuration to appear in temporal history even for the initial insertion.

---

## 2. Business Logic

### 2.1 Computed Identity Capture - Operator Accountability

**What**: CEP.NamedLists uses three computed columns (DbLoginName, AppLoginName, HostName) to automatically capture who made each change, without requiring the application to supply this information explicitly. These values are copied into the history table when rows are archived.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`, `HostName`

**Rules**:
- DbLoginName = suser_name() - the SQL Server login name at time of the change
- AppLoginName = CONVERT(varchar(500), context_info()) - the application-set identity via context_info()
- HostName = host_name() - the machine name of the client connection
- All three are computed columns on the live table; their values at change time are captured in the temporal history row
- The CEP application is responsible for setting context_info() before any DML to populate AppLoginName

### 2.2 INSERT Trigger Pattern - Capturing Initial State

**What**: `Tr_T_NamedLists_INSERT` fires on every INSERT to CEP.NamedLists and performs a no-op UPDATE (SET Name=Name), causing the newly inserted row to be archived in History before the transaction closes.

**Rules**:
- Without the trigger: an INSERT would not generate a history row (temporal only archives on UPDATE/DELETE)
- With the trigger: every INSERT generates one history row with a very short validity window (milliseconds between INSERT and the trigger's UPDATE)
- This ensures complete coverage: every created list configuration, including the initial creation, appears in History

### 2.3 ValidFrom - Manual Change Timestamp

**What**: ValidFrom is a manual datetime column (not the temporal SysStartTime) that records when the list definition was last changed by the `CEPNamedListsUpdate` trigger.

**Columns/Parameters Involved**: `ValidFrom`, `SysStartTime`, `SysEndTime`

**Rules**:
- ValidFrom = getutcdate() - updated by CEPNamedListsUpdate trigger when Name, Statment, PeriodicIntervalSec, or NamedListTypeID changes
- ValidFrom represents "when the list definition last changed" (business timestamp)
- SysStartTime = "when this row version became current" (temporal timestamp - more precise, auto-managed by SQL Server)
- These two timestamps may differ: SysStartTime changes on ANY column update; ValidFrom changes only on business-data column updates

---

## 3. Data Overview

3,377 rows in test environment.

| NamedListID | Name | StatementSample | PeriodicIntervalSec | NamedListTypeID | SysStartTime | SysEndTime |
|---|---|---|---|---|---|---|
| 1 | Large AUM | exec [CEP].[PR_Run_Statment] @ListID=1,@DB='etoro_repl',@SERVER='[AMS-REPL]', @ListParameters='' | 1700 | 2 | 2025-01-27 12:20:28 | 2025-01-27 12:48:48 |
| 1 | Large AUM | (same) | 1700 | 2 | 2025-01-27 11:52:08 | 2025-01-27 12:20:28 |

Key insight: NamedListID=1 "Large AUM" is frequently touched (~28-minute intervals match PeriodicIntervalSec=1700), and each touch archives the prior state here. The `Statment` column stores a stored procedure call pattern: `exec [CEP].[PR_Run_Statment] @ListID={N}, @DB='etoro_repl', @SERVER='[AMS-REPL]', @ListParameters=''` - the actual SQL is encapsulated in PR_Run_Statment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NamedListID | int | NO | - | CODE-BACKED | The CEP named list identifier. Matches CEP.NamedLists.NamedListID (IDENTITY PK NOT FOR REPLICATION on the live table). Multiple history rows share the same NamedListID as each configuration change creates a new history entry. References the list whose configuration was active during [SysStartTime, SysEndTime). |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | The human-readable name of the named list. Examples from data: "Large AUM". Used in CEP UI and reports to identify the customer segment. Changes to Name generate a new temporal history row. |
| 3 | Statment | varchar(8000) | YES | - | CODE-BACKED | The SQL expression or stored procedure call that defines the list's population logic. Note: column name has a typo ("Statment" not "Statement"). Pattern: `exec [CEP].[PR_Run_Statment] @ListID={N}, @DB='etoro_repl', @SERVER='[AMS-REPL]', @ListParameters=''`. The actual query is encapsulated in CEP.PR_Run_Statment. Changes to Statment are tracked for compliance and audit. |
| 4 | PeriodicIntervalSec | int | YES | - | CODE-BACKED | How frequently (in seconds) the CEP scheduler should re-execute this list's population query. 1700 seconds = ~28 minutes for "Large AUM". NULL if the list is not periodically refreshed (on-demand only). Changes to refresh frequency generate history entries. |
| 5 | NamedListTypeID | int | YES | - | CODE-BACKED | The type/category of the named list. FK to Dictionary.CEPNamedListTypeID on the live table (no FK enforced in history). Classifies what kind of customer segment this is (e.g., campaign targeting, risk monitoring). Value 2 observed in data. |
| 6 | LastUpdated | datetime | YES | - | CODE-BACKED | The last time the list was executed/populated (when CEP.NamedListRefresh last ran for this list). Distinct from ValidFrom (when the definition changed) - LastUpdated tracks operational execution, ValidFrom tracks configuration changes. |
| 7 | ValidFrom | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp of the last business-data change to this list definition (Name, Statment, PeriodicIntervalSec, NamedListTypeID). Updated by the CEPNamedListsUpdate trigger. Distinct from SysStartTime (which changes on any column update, even LastUpdated changes). |
| 8 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | The SQL Server login name of the session that last changed this row. Computed column on the live table (= suser_name()). Captured at change time and stored in history. Identifies the database-level operator. |
| 9 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | The application-level identity from context_info(). Computed column on live table. The CEP application sets context_info() before DML to record who is making the change (e.g., the user in the CEP admin UI). NULL if context_info was not set. |
| 10 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became current in CEP.NamedLists. Populated automatically by SQL Server SYSTEM_VERSIONING (GENERATED ALWAYS AS ROW START). |
| 11 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version was superseded and moved to history. The interval [SysStartTime, SysEndTime) is the period during which this named list configuration was active. |
| 12 | HostName | nvarchar(128) | YES | - | CODE-BACKED | The machine name of the client that changed this row. Computed column on live table (= host_name()). Captured at change time and stored in history. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| NamedListTypeID | Dictionary.CEPNamedListTypeID | Implicit | FK enforced on CEP.NamedLists; not enforced in history. Classifies the list type. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.NamedLists | SYSTEM_VERSIONING | Writer (automatic) | Live temporal table - SQL Server archives old states here |
| Tr_T_NamedLists_INSERT | (no-op UPDATE) | Writer (forced) | INSERT trigger on CEP.NamedLists forces INSERT events into history |

---

## 6. Dependencies

```
History.NamedLists (table)
  - No code-level dependencies (temporal history leaf table)
  - Source: CEP.NamedLists (live temporal table, SYSTEM_VERSIONING = ON)
    - Modified by: CEP.EditNamedList, CEP.NamedListRefresh (procedures)
    - Context triggers: CEPNamedListsUpdate (updates ValidFrom on content changes)
    - Audit triggers: AuditDelete/Insert/Update_CEP_NamedLists (also write to History.AuditHistory)
    - Also writes to: History.CEP_LOG_NamedLists (separate non-temporal audit log via CEPNamedListsDelete/Update triggers)
```

### 6.1 Objects This Depends On

No dependencies. Populated automatically by temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.NamedLists | Table | Live temporal table - this is its HISTORY_TABLE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_NamedLists | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression applied.

### 7.2 Constraints

No constraints on history table. CEP.NamedLists live table: CLUSTERED PK on NamedListID, FK to Dictionary.CEPNamedListTypeID.

---

## 8. Sample Queries

### 8.1 Full configuration change history for a specific named list

```sql
SELECT NamedListID, Name, LEFT(Statment, 200) AS StatementSummary,
       PeriodicIntervalSec, NamedListTypeID, ValidFrom,
       DbLoginName, AppLoginName, HostName,
       SysStartTime, SysEndTime
FROM [History].[NamedLists] WITH (NOLOCK)
WHERE NamedListID = 1
ORDER BY SysStartTime ASC
```

### 8.2 Find all named lists whose SQL definition (Statment) was changed

```sql
-- Changes where Statment actually differs between old and new
SELECT
    h1.NamedListID,
    h1.Name,
    LEFT(h1.Statment, 100) AS OldStatement,
    h1.SysEndTime AS ChangedAt,
    h1.DbLoginName AS ChangedBy
FROM [History].[NamedLists] h1 WITH (NOLOCK)
WHERE EXISTS (
    SELECT 1 FROM [History].[NamedLists] h2 WITH (NOLOCK)
    WHERE h2.NamedListID = h1.NamedListID
      AND h2.SysStartTime = h1.SysEndTime
      AND h2.Statment <> h1.Statment
)
ORDER BY h1.SysEndTime DESC
```

### 8.3 Point-in-time list configuration

```sql
SELECT NamedListID, Name, Statment, PeriodicIntervalSec
FROM [CEP].[NamedLists]
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
ORDER BY NamedListID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (CEP.EditNamedList) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.NamedLists | Type: Table | Source: etoro/etoro/History/Tables/History.NamedLists.sql*
