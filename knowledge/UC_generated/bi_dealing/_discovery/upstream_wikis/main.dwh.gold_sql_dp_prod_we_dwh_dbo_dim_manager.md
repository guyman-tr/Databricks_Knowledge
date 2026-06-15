# DWH_dbo.Dim_Manager

> 5,152-row dimension table mapping ManagerID to the BackOffice customer-success and support manager who is assigned to a customer account -- combining manager name, active status, team-leader flag, Salesforce CRM ID, and Calendly scheduling ID into a single reference table for customer-manager analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.BackOffice.Manager (BackOffice CRM) + Salesforce (SFManagerID) |
| **Refresh** | Daily (incremental: UPDATE existing + INSERT new; never truncates) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | HEAP, PK_ManagerID NOT ENFORCED |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Manager` is the reference table for eToro's BackOffice customer-success managers -- the people (support agents, account managers, team leaders) assigned to serve customer accounts. A customer account typically has an assigned ManagerID that identifies the primary relationship owner in the BackOffice/CRM system.

The table holds 5,152 rows: 1,367 currently active managers (`IsActive=True`) including 1 active team leader, plus 3,785 historical/departed managers (`IsActive=False`). Since rows are never deleted, the table preserves the full history of everyone who has ever been a manager in the system.

Key columns: `FirstName`, `LastName` (personal details), `IsActive` (currently employed/assigned), `IsTeamLeader` (hierarchy flag), `SFManagerID` (Salesforce CRM ID, 18-char), `CalendlyID` (scheduling link). The `UserGroup` and `ParentUserGroup` columns are **not populated** -- both are hardcoded to `'Not Available'` in the ETL SP.

ETL pattern: `SP_Dictionaries_DL_To_Synapse` -- loads a staging intermediate (`Ext_Dim_Manager`) from `DWH_staging.etoro_BackOffice_Manager`, then merges into `Dim_Manager` (UPDATE existing rows, INSERT new rows). A post-load UPDATE sets `SFManagerID` from the Salesforce-to-BackOffice mapping table.

---

## 2. Business Logic

### 2.1 Incremental Merge Pattern (Soft-Delete)

**What**: Unlike most DWH Dim tables that use TRUNCATE+INSERT, Dim_Manager uses an incremental UPDATE+INSERT pattern that preserves historical manager records.

**Rules**:
- **UPDATE**: Existing ManagerID rows are updated with current FirstName, LastName, IsTeamLeader, IsActive, CalendlyID. This means a manager's name, active status, or team-leader flag can change.
- **INSERT**: New ManagerIDs from `etoro_BackOffice_Manager` that do not exist in Dim_Manager are appended. `InsertDate` is set to GETDATE() on first insert only.
- **No DELETE**: Managers who leave the company remain in the table with `IsActive=False`. The table is the full history of all managers.
- **SFManagerID**: Set via a separate post-load UPDATE joining to `SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping`. Managers not in Salesforce have NULL SFManagerID.

### 2.2 UserGroup / ParentUserGroup Not Populated

**What**: The DDL defines `UserGroup` and `ParentUserGroup` columns, but the ETL hardcodes both to `'Not Available'` for all rows.

**Rule**: Do not use `UserGroup` or `ParentUserGroup` for any analysis. Both columns have the literal string `'Not Available'` for every row. The intended team/group hierarchy data has not been implemented.

### 2.3 CalendlyID for Customer Scheduling

**What**: `CalendlyID` holds the manager's Calendly scheduling account identifier, used for customer-facing meeting booking.

**Rule**: Most inactive (historical) managers have `CalendlyID='etoro-club'`, suggesting a default value is set when a manager leaves the system rather than the CalendlyID being set to NULL. Active managers have their personal Calendly IDs. Do not use CalendlyID to infer active status.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE-distributed (5,152 rows trivially replicated). HEAP -- no clustered index. PK_ManagerID is NOT ENFORCED (Synapse syntax; uniqueness is not guaranteed at the DB level, though duplicates are not expected). Zero JOIN overhead.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get manager name for a customer account | `JOIN Dim_Manager ON ManagerID; SELECT FirstName, LastName` |
| Find all currently active managers | `WHERE IsActive = 1` (1,367 rows) |
| Find active team leaders | `WHERE IsActive = 1 AND IsTeamLeader = 1` (1 row currently) |
| Cross-reference with Salesforce | `WHERE SFManagerID IS NOT NULL` |

### 3.3 Gotchas

- **UserGroup = 'Not Available'**: Both `UserGroup` and `ParentUserGroup` are hardcoded placeholder strings. Do not use for grouping or filtering.
- **3,785 inactive managers**: Always filter `WHERE IsActive = 1` for current-state analysis. Leaving out this filter inflates manager counts 4x.
- **CalendlyID default 'etoro-club'**: This is a default value for departed/inactive managers, not a real Calendly account. Filter on IsActive=1 for meaningful CalendlyID usage.
- **HEAP index**: Full table scans on all queries. Acceptable at 5,152 rows.
- **PK NOT ENFORCED**: No database-level guarantee against duplicate ManagerIDs. Validate if using ManagerID as a join key in data quality checks.
- **SFManagerID is NULL for many managers**: Only managers that appear in the Salesforce-to-BackOffice mapping have SFManagerID populated.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ManagerID | int | NO | Auto-generated unique integer identifier for each BackOffice staff member. PK for the entire BackOffice authorization system. ManagerID=0 is the reserved System account; ManagerID=1 is the bootstrap Admin. All BackOffice action tables (BackOffice.Customer, Task, Downtime, etc.) store ManagerID as the 'acting staff' reference. (Tier 1 — BackOffice.Manager) |
| 2 | UserGroup | varchar(50) | NO | Hardcoded to 'Not Available' for all rows. The ETL SP sets this to a literal constant: `'Not Available' as UserGroup`. Intended to represent the manager's team/group but not populated. Do not use. (Tier 3 — SP_Dictionaries_DL_To_Synapse) |
| 3 | ParentUserGroup | varchar(50) | NO | Hardcoded to 'Not Available' for all rows. Same as UserGroup -- intended to represent the manager's parent team hierarchy but not populated. Do not use. (Tier 3 — SP_Dictionaries_DL_To_Synapse) |
| 4 | FirstName | varchar(50) | NO | Staff member's first name. Combined with LastName in views and procedures to produce display names (e.g., BackOffice.GetMyCustomers sets [Manager] = FirstName + ' ' + LastName). (Tier 1 — BackOffice.Manager) |
| 5 | LastName | varchar(50) | NO | Staff member's last name. Combined with FirstName for display. LastName='*' indicates a functional/shared account (e.g., the generic 'support' account). (Tier 1 — BackOffice.Manager) |
| 6 | IsActive | bit | NO | Logical soft-delete flag controlling login access and visibility. 1=active (staff currently employed, can authenticate). 0=deactivated (former staff or suspended; LOGIN is blocked). Do NOT physically delete manager rows — use IsActive=0 to preserve audit history. (Tier 1 — BackOffice.Manager) |
| 7 | IsTeamLeader | bit | NO | Marks this manager as a team leader within their department. 1=team leader role. 0=individual contributor. Used in LoadManagers/LoadManagerByUsername responses for role-based UI rendering. (Tier 1 — BackOffice.Manager) |
| 8 | DWHManagerID | int | YES | Always equal to ManagerID. Standard DWH DWH{X}ID redundancy pattern. Do not use for JOINs. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 9 | StatusID | int | YES | Hardcoded to 1 for all rows. Conveys no business information. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 10 | UpdateDate | datetime | YES | ETL run timestamp for the most recent UPDATE that touched this row. Set to GETDATE() on every daily UPDATE. Reflects last ETL run, not production modification. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 11 | InsertDate | datetime | YES | ETL run timestamp when the manager row was first inserted into Dim_Manager. Set once on INSERT; not updated on subsequent runs. Unlike most DWH tables, this may reflect the actual first-appearance date for the manager. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 12 | SFManagerID | nvarchar(18) | YES | Salesforce CRM 18-character object ID for this manager (e.g., 0050800000DitvwAAB). Set via post-load UPDATE from SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping. NULL for managers not present in the Salesforce mapping. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 13 | CalendlyID | nvarchar(50) | YES | Calendly scheduling identifier for this manager. Exposed via GetManagers procedure for the customer-facing scheduler that lets customers book calls with their account manager. (Tier 1 — BackOffice.Manager) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ManagerID | etoro.BackOffice.Manager | ManagerID | passthrough |
| UserGroup | -- | -- | ETL-computed: hardcoded 'Not Available' |
| ParentUserGroup | -- | -- | ETL-computed: hardcoded 'Not Available' |
| FirstName | etoro.BackOffice.Manager | FirstName | passthrough |
| LastName | etoro.BackOffice.Manager | LastName | passthrough |
| IsActive | etoro.BackOffice.Manager | IsActive | passthrough |
| IsTeamLeader | etoro.BackOffice.Manager | IsTeamLeader | passthrough |
| DWHManagerID | etoro.BackOffice.Manager | ManagerID | rename (= ManagerID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() on each UPDATE |
| InsertDate | -- | -- | ETL-computed: GETDATE() on first INSERT only |
| SFManagerID | Salesforce SalesForceToBOManagerMapping | SFManagerID | post-load UPDATE via ManagerID join |
| CalendlyID | etoro.BackOffice.Manager | CalendlyID | passthrough (UPDATE) |

### 5.2 ETL Pipeline

```
etoro.BackOffice.Manager  (BackOffice CRM)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_BackOffice_Manager
  |-- SP_Dictionaries_DL_To_Synapse ---|
      1. TRUNCATE Ext_Dim_Manager + INSERT from etoro_BackOffice_Manager
      2. UPDATE Dim_Manager (existing rows: name, active, team-leader, Calendly)
      3. INSERT Dim_Manager (new ManagerIDs not yet in table)
      4. UPDATE SFManagerID from SalesForce_DB_Prod_dbo_SalesForceToBOManagerMapping
  v
DWH_dbo.Dim_Manager  (5,152 rows; incremental, never truncated)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Manager/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Customer account dimension tables | ManagerID | Identifies the assigned BackOffice manager for each customer |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP; incremental pattern |

---

## 7. Sample Queries

### 7.1 List all currently active managers

```sql
SELECT ManagerID, FirstName, LastName, IsTeamLeader, SFManagerID, CalendlyID
FROM [DWH_dbo].[Dim_Manager]
WHERE IsActive = 1
ORDER BY IsTeamLeader DESC, LastName, FirstName;
```

### 7.2 Count customers per active manager

```sql
SELECT
    m.ManagerID,
    m.FirstName + ' ' + m.LastName AS ManagerName,
    COUNT(DISTINCT f.CustomerID) AS CustomerCount
FROM [DWH_dbo].[SomeFact] f
JOIN [DWH_dbo].[Dim_Manager] m ON f.ManagerID = m.ManagerID
WHERE m.IsActive = 1
GROUP BY m.ManagerID, m.FirstName, m.LastName
ORDER BY CustomerCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.4/10 (★★★★☆) | Phases: 8/14*
*Tiers: 6 T1, 5 T2, 2 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 13/13, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Manager | Type: Table | Production Source: etoro.BackOffice.Manager + Salesforce*
