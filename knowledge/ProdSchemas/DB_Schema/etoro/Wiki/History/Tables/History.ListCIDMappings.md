# History.ListCIDMappings

> SQL Server temporal history table automatically maintained by the database engine, recording every past state of CEP.ListCIDMappings - the Customer Engagement Platform table mapping individual customers (CIDs) to named targeting lists.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite: (SysEndTime, SysStartTime) - temporal history clustered index |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

History.ListCIDMappings is the temporal history backing table for CEP.ListCIDMappings. It is automatically populated by SQL Server's SYSTEM_VERSIONING mechanism whenever rows in CEP.ListCIDMappings are updated or deleted.

CEP.ListCIDMappings is the membership table for CEP named lists: each row states "customer CID is currently a member of named list NamedListID." The named list system (see History.NamedLists) defines customer segments by SQL criteria, and CEP.NamedListRefresh periodically executes those criteria to refresh membership - inserting new CIDs that now qualify and deleting CIDs that no longer qualify.

History.ListCIDMappings captures the full audit trail of these membership changes: which customers left which lists, when, and who triggered the change. With 53 rows and two named lists represented (NamedListID=1 "Large AUM" with 52 removals and NamedListID=15 with 1 removal), this table records historical snapshots of customer segment membership.

**Critical business impact**: NamedListID=3 (the "bonus-only customers" list) has a direct hedge effect - the `TrCEPListCIDMappings_InsDel` trigger updates Customer.Customer.IsHedged based on membership changes to list 3. Customers in this list have IsHedged=0 (not hedged, because they only have bonus money); removing them from the list restores IsHedged=1.

---

## 2. Business Logic

### 2.1 Temporal List Membership - INSERT Trigger Pattern

**What**: CEP.ListCIDMappings uses the same INSERT trigger pattern as CEP.NamedLists to force INSERT events into temporal history. Since SYSTEM_VERSIONING only archives rows on UPDATE or DELETE (not INSERT), the trigger performs a no-op UPDATE after every INSERT.

**Columns/Parameters Involved**: `NamedListID`, `CID`, `SysStartTime`, `SysEndTime`

**Rules**:
- `Tr_T_ListCIDMappings_INSERT` fires on every INSERT: `UPDATE A SET A.NamedListID = A.NamedListID` - a no-op that triggers temporal archiving of the just-inserted row
- This ensures every CID addition to a list appears in History, not just removals
- The resulting history row has SysStartTime = SysEndTime = time of the no-op UPDATE (milliseconds after INSERT)
- Without this trigger: INSERT events would NOT be visible in History.ListCIDMappings

### 2.2 Named List Refresh - Batch Add/Remove

**What**: `CEP.NamedListRefresh` re-executes the list's population SQL and updates membership in batches of 4,000 rows, generating temporal history entries for every removed and added CID.

**Rules**:
- Step 1: Execute `CEP.NamedLists.Statment` (stored procedure call) -> returns qualifying CIDs into #temp
- Step 2: WHILE loop DELETE in batches of 4,000: removes CIDs no longer qualifying
- Step 3: WHILE loop INSERT in batches of 4,000: adds CIDs now qualifying
- Each batch DELETE generates temporal history rows for the removed CIDs
- Each batch INSERT + the Tr_T_ListCIDMappings_INSERT trigger generates temporal history rows for the added CIDs
- `@IsChanged BIT OUTPUT` tells the caller whether the membership changed this refresh cycle

**Flow**:
```
CEP scheduler -> CEP.NamedListRefresh(@NamedListID=1)
  EXEC [CEP].[PR_Run_Statment] -> returns current qualifying CIDs
  DELETE CEP.ListCIDMappings WHERE NamedListID=1 AND CID NOT IN new list (batched)
    -> temporal mechanism archives deleted rows to History.ListCIDMappings
  INSERT CEP.ListCIDMappings (NamedListID=1, CID, ValidFrom=getutcdate())
    -> Tr_T_ListCIDMappings_INSERT fires -> no-op UPDATE -> temporal archives to History
```

### 2.3 NamedListID=3 Hedge Control (Critical Business Rule)

**What**: List ID 3 is the "bonus-only customers" list. Changes to membership in this list trigger automatic updates to Customer.Customer.IsHedged via the `TrCEPListCIDMappings_InsDel` trigger.

**Rules**:
- INSERT to CEP.ListCIDMappings WHERE NamedListID=3 -> SET Customer.Customer.IsHedged=0 (customer has only bonus money; do NOT hedge them)
- DELETE from CEP.ListCIDMappings WHERE NamedListID=3 -> SET Customer.Customer.IsHedged=1 (customer is back to normal; hedge them again), EXCEPT for BackOffice.BonusOnlyCustomers members and specific label/player level exclusions (LabelID <> 26, PlayerLevelID <> 4)
- This makes History.ListCIDMappings for NamedListID=3 an indirect audit trail of IsHedged flag changes
- History rows for NamedListID=3 can explain why a customer was temporarily unhedged

### 2.4 AppLoginName - CEP Admin User Identity

**What**: AppLoginName captures the CEP admin user who triggered the list change via context_info(), distinct from DbLoginName (the SQL session).

**Rules**:
- AppLoginName = CONVERT(varchar(500), context_info()) on the live table
- CEP.ArchiveListCIDMapping sets context_info: `SET CONTEXT_INFO = CAST(LEFT(@AppLoginName, 128) AS VARBINARY(128))`
- Data example: AppLoginName="moshezo" (null-padded to 128 bytes, then stored in varchar(500)) identifies the CEP admin who triggered the removal for NamedListID=15
- NULL AppLoginName: changes made by automated scheduler (CEP.NamedListRefresh called without application context) or DEV\trading_services service account

### 2.5 ValidFrom - Business Timestamp vs Temporal Timestamps

**What**: ValidFrom is a manual datetime column (DEFAULT getutcdate()) representing when this CID was added to the list, distinct from SysStartTime (when the row version became current in the temporal sense).

**Rules**:
- ValidFrom: set on INSERT, represents the business "added to list" timestamp. Preserved unchanged in temporal history.
- SysStartTime: the temporal row version start - may differ from ValidFrom due to the INSERT trigger's no-op UPDATE (adding a small delta between ValidFrom and SysStartTime)
- Data: ValidFrom="2012-12-02 10:18:06" for NamedListID=1 rows (legacy data from 2012 still in membership), but SysStartTime="2021-09-13" (when temporal versioning was activated)

---

## 3. Data Overview

53 rows.

| NamedListID | CID | ValidFrom | DbLoginName | AppLoginName | SysStartTime | SysEndTime | ValidForSec |
|---|---|---|---|---|---|---|---|
| 15 | 888888 | 2024-12-19 09:48:40 | TRAD\orshoh | moshezo | 2024-12-19 09:48:40 | 2024-12-19 09:48:40 | 0 | Test/internal CID (888888). Removed from NamedListID=15 instantly. AppLoginName="moshezo" (CEP admin). |
| 1 | 2203248 | 2012-12-02 10:18:06 | DEV\trading_services | NULL | 2021-09-13 05:26:04 | 2024-11-06 11:24:39 | 99,381,515 | "Large AUM" list member since 2012, removed 2024-11-06 (>3 years membership). Automated service account. |
| 1 | 2112649 | 2012-12-02 10:18:06 | DEV\trading_services | NULL | 2021-09-13 05:26:04 | 2024-11-06 11:24:39 | 99,381,515 | Same batch removal pattern - all 52 NamedListID=1 rows share identical SysEndTime (bulk refresh). |

**NamedListID distribution**: 1 ("Large AUM")=52 rows, 15=1 row. The 52 simultaneous removals from NamedListID=1 on 2024-11-06 represent a single NamedListRefresh cycle.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NamedListID | int | NO | - | CODE-BACKED | The CEP named list this customer belonged to. FK to CEP.NamedLists on the live table (not enforced in history). Matches CEP.NamedLists.NamedListID. NamedListID=1="Large AUM", NamedListID=3=Bonus-only customers (critical: controls IsHedged flag), others as defined in CEP.NamedLists. Part of the composite PK on the live table: (NamedListID, CID). |
| 2 | CID | int | NO | - | CODE-BACKED | The customer who was a member of this named list. FK to Customer.CustomerStatic enforced on the live table (not in history). Multiple history rows with the same CID represent the customer's membership history across different lists or different time periods. |
| 3 | ValidFrom | datetime | NO | getutcdate() | CODE-BACKED | Business timestamp of when this CID was added to the named list. DEFAULT getutcdate() on the live table. Set on INSERT and preserved unchanged in history. May differ from SysStartTime (which reflects the temporal row version start after the INSERT trigger's no-op UPDATE). Legacy rows may show ValidFrom dates from 2012 while SysStartTime reflects when temporal versioning was enabled. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that changed this list membership. Computed column on live table (= suser_name()); stored as snapshot in history. Values: "DEV\trading_services" (automated scheduler), "TRAD\orshoh" (manual CEP admin action). Identifies the database session responsible for the add/remove. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | CEP application user who triggered the change. Computed column on live table (= CONVERT(varchar(500), context_info())). Set by CEP.ArchiveListCIDMapping via SET CONTEXT_INFO before DELETE. Stored null-padded to 128 bytes (context_info buffer size) then stored as varchar(500). NULL when automated scheduler runs without application context. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this membership row version became current in CEP.ListCIDMappings. For newly inserted CIDs: reflects the INSERT trigger's no-op UPDATE timestamp (milliseconds after actual INSERT). Populated automatically by SQL Server SYSTEM_VERSIONING. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this customer's membership in the named list ended (was removed). All 52 NamedListID=1 history rows share SysEndTime="2024-11-06 11:24:39" - confirming they were removed in a single batch refresh operation. SysEndTime=SysStartTime indicates an immediately-superseded row (INSERT trigger pattern). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| NamedListID | CEP.NamedLists | Implicit | FK enforced on CEP.ListCIDMappings; not in history. The named list whose membership this row records. History in History.NamedLists. |
| CID | Customer.CustomerStatic | Implicit | FK enforced on CEP.ListCIDMappings; not in history. The customer who was a list member. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.ListCIDMappings | SYSTEM_VERSIONING | Writer (automatic) | Live temporal table - SQL Server archives old membership states here |
| Tr_T_ListCIDMappings_INSERT | (no-op UPDATE) | Writer (forced) | INSERT trigger forces new memberships into temporal history |
| Customer.Customer | IsHedged | Side-effect (via trigger) | TrCEPListCIDMappings_InsDel updates IsHedged when NamedListID=3 rows change |

---

## 6. Dependencies

```
History.ListCIDMappings (table)
  - No code-level dependencies (temporal history leaf table)
  - Source: CEP.ListCIDMappings (live temporal table, SYSTEM_VERSIONING = ON)
    - Writers: CEP.NamedListRefresh (batch DELETE + INSERT on membership refresh)
               CEP.ArchiveListCIDMapping (bulk DELETE for a named list)
    - Side effects: Tr_T_ListCIDMappings_INSERT (no-op UPDATE to capture INSERTs in history)
                    TrCEPListCIDMappings_InsDel (updates Customer.Customer.IsHedged for NamedListID=3)
                    ListCidMappingsDelete trigger (also writes to History.CEPListCIDMappings - legacy dual audit)
```

### 6.1 Objects This Depends On

No dependencies. Populated automatically by temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.ListCIDMappings | Table | Live temporal table - this is its HISTORY_TABLE |
| CEP.NamedListRefresh | Stored Procedure | Primary writer (deletes expired members, inserts new) |
| CEP.ArchiveListCIDMapping | Stored Procedure | Bulk list cleaner (deletes all members of a list) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ListCIDMappings | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression applied. ON [PRIMARY] filegroup.

### 7.2 Constraints

No constraints on history table. CEP.ListCIDMappings live table: CLUSTERED PK on (NamedListID, CID), FK_HedgeRulesCIDMappings_Customer (CID -> Customer.CustomerStatic), FK_ListCIDMappings_NamedLists (NamedListID -> CEP.NamedLists).

---

## 8. Sample Queries

### 8.1 Full membership history for a specific customer in a named list

```sql
SELECT NamedListID, CID, ValidFrom, DbLoginName, AppLoginName, SysStartTime, SysEndTime,
       DATEDIFF(SECOND, SysStartTime, SysEndTime) AS MemberForSec
FROM [History].[ListCIDMappings] WITH (NOLOCK)
WHERE CID = @CID
ORDER BY SysStartTime ASC
```

### 8.2 Point-in-time membership of a named list

```sql
SELECT NamedListID, CID, ValidFrom
FROM [CEP].[ListCIDMappings]
FOR SYSTEM_TIME AS OF '2024-01-01 00:00:00'
WHERE NamedListID = 1
ORDER BY CID
```

### 8.3 Audit: who removed customers from which list

```sql
SELECT NamedListID, CID, DbLoginName, AppLoginName, SysEndTime AS RemovedAt,
       DATEDIFF(SECOND, SysStartTime, SysEndTime) AS WasMemberForSec
FROM [History].[ListCIDMappings] WITH (NOLOCK)
WHERE SysEndTime >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.3/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (CEP.NamedListRefresh, CEP.ArchiveListCIDMapping) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.ListCIDMappings | Type: Table | Source: etoro/etoro/History/Tables/History.ListCIDMappings.sql*
