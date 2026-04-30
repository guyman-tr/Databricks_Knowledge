# BackOffice.GetComplianceReport

> Returns customer compliance requirement status records from the Compliance system (ComplianceStateDB), joined with customer player status, verification level, and regulation - the BackOffice compliance overview report for monitoring KYC/regulatory requirement fulfillment.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Cid (customer filter) OR @StartDate/@EndDate window (max 7 days without @Cid); returns one row per compliance requirement status event |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetComplianceReport` is the BackOffice window into the Compliance system's customer requirement tracking. Compliance requirements represent mandatory regulatory checks that must be fulfilled (e.g., re-verification after address change, enhanced due diligence for PEP customers, annual review for high-risk customers).

The procedure reads from the `ComplianceStateDB` Compliance database via unqualified table names (synonyms or default-database resolution), bridging etoro's BackOffice with the separate Compliance state tracking system. Key compliance tables accessed:
- `Compliance_CustomerRequirementsOverviewStatus`: The main compliance event log - when each requirement started and ended for each customer
- `Compliance_Requirements`: Requirement definitions (names/descriptions)
- `Dictionary_ComplianceOverviewStatus`, `Dictionary_ComplianceOwner`, `Dictionary_ComplianceStatusReason`: Compliance-specific lookup tables (not in etoro Dictionary schema)

**Guard**: If @Cid is NULL AND the date range is > 7 days (or missing), the procedure raises an error and returns. This prevents unintentionally large compliance scans.

**Dynamic SQL**: The first query populates `#Compliance_CustomerRequirementsOverviewStatus` using dynamic SQL (Exec(@S1)) to build an optimized WHERE clause. The compliance table can be large, and pre-filtering before the five temp table JOINs is critical for performance.

**ComplianceOverviewStatusID = -6 magic value**: The caller can pass -6 as a special sentinel meaning "exclude Completed (status 6)" - all non-completed requirements. Positive values filter to a specific status.

---

## 2. Business Logic

### 2.1 Date Range Guard

**What**: Prevents full-table compliance scans when no customer is specified.

**Columns/Parameters Involved**: `@Cid`, `@StartDate`, `@EndDate`

**Rules**:
- If @Cid IS NULL AND (@StartDate IS NULL OR @EndDate IS NULL OR DateDiff(Day, @StartDate, @EndDate) > 7): `RAISERROR` and RETURN.
- Allows up to 7-day windows for bulk compliance review without a CID.
- With @Cid, any date range is acceptable.

### 2.2 GCID Resolution

**What**: The compliance system uses GCID (not CID) as the primary customer identifier.

**Columns/Parameters Involved**: `@Cid`, `@Gcid`, `Customer.Customer`

**Rules**:
- If @Cid IS NOT NULL: `SELECT @Gcid = GCID FROM Customer.Customer WHERE CID = @Cid`.
- @Gcid is then used in the dynamic SQL WHERE clause for filtering compliance records.
- If @Cid IS NULL, @Gcid remains NULL (no customer filter, date range required).

### 2.3 Dynamic SQL Construction (INSERT INTO temp from @S1)

**What**: The compliance records are fetched via dynamic SQL to allow optimal pre-filtering.

**Columns/Parameters Involved**: `#Compliance_CustomerRequirementsOverviewStatus`, `@S1`, `Exec(@S1)`

**Rules**:
- Dynamic SQL built with `CONCAT()` chains and `IIF(condition, '', CONCAT(Char(13), 'And ...'))` pattern.
- Each filter is only added if the parameter is not null.
- @ComplianceOverviewStatusId: If >0, appends `OverviewStatusID=@value`; if -6, appends `OverviewStatusID != 6`.
- Date filters use `Format(@StartDate,'yyyyMMdd HH:mm:ss.fff')` for safe string embedding.
- After INSERT, a clustered index is created on GCID for the subsequent JOINs.

### 2.4 Multiple Temp Table Pattern

**What**: Four compliance lookup tables are loaded into temp tables with unique clustered indexes before the final JOIN.

**Columns/Parameters Involved**: `#Compliance_Requirements`, `#Dictionary_ComplianceOverviewStatus`, `#Dictionary_ComplianceOwner`, `#Dictionary_ComplianceStatusReason`

**Rules**:
- DROP TABLE IF EXISTS guards for re-execution safety.
- Each lookup table has RequirementID/OverviewStatusID/OwnerID/StatusReasonID as the clustered PK.
- Reads from unqualified table names (Compliance_Requirements, Dictionary_ComplianceOverviewStatus, etc.) - these resolve to synonyms or views pointing to ComplianceStateDB.
- Final SELECT JOINs all five temp tables with LEFT JOINs.

### 2.5 Final Filter (WHERE Clause Duplication)

**What**: The final SELECT re-applies the same filter predicates to the temp table.

**Columns/Parameters Involved**: All filter parameters

**Rules**:
- The WHERE clause of the final SELECT mirrors the dynamic SQL conditions.
- This is a performance/correctness pattern: the dynamic SQL pre-filters the large compliance table; the final WHERE provides optimizer hints on the temp table.
- The `OccurredEnd` filter is commented out in both passes - only `Occurred` (start date) is filtered by @EndDate, not the end date of the requirement.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Cid | INT | YES | NULL | CODE-BACKED | Customer ID filter. When provided, resolves to GCID for compliance system lookup. If NULL, @StartDate/@EndDate (max 7 days) required. |
| 2 | @ComplianceRequirementId | INT | YES | NULL | CODE-BACKED | Filter to a specific compliance requirement (FK to Compliance_Requirements.RequirementID). NULL=all requirements. |
| 3 | @ComplianceOverviewStatusId | INT | YES | NULL | CODE-BACKED | Filter by compliance status. NULL=all; positive integer=specific status; -6=all except Completed (status 6). |
| 4 | @ComplianceOwnerId | INT | YES | NULL | CODE-BACKED | Filter by compliance owner (team/system responsible for the requirement). |
| 5 | @ComplianceStatusReasonId | INT | YES | NULL | CODE-BACKED | Filter by compliance status reason. |
| 6 | @StartDate | DATETIME | YES | NULL | CODE-BACKED | Start of requirement Occurred date window. Required if @Cid IS NULL. |
| 7 | @EndDate | DATETIME | YES | NULL | CODE-BACKED | End of requirement Occurred date window. Max 7-day range if @Cid IS NULL. |
| 8 | @RegulationId | INT | YES | NULL | CODE-BACKED | Filter by regulatory jurisdiction (BackOffice.Customer.RegulationID). |
| 9 | CID | INT | YES | - | CODE-BACKED | Customer ID resolved via GCID. From Customer.Customer.CID LEFT JOIN. NULL if GCID has no Customer record. |
| 10 | Requirement start date | DATETIME | NO | - | CODE-BACKED | When this compliance requirement became active for the customer (Compliance_CustomerRequirementsOverviewStatus.Occurred). |
| 11 | Compliance Requirement | NVARCHAR | YES | - | CODE-BACKED | Human-readable requirement name from Compliance_Requirements.DisplayName. NULL if requirement not found. |
| 12 | Status | NVARCHAR | YES | - | CODE-BACKED | Current compliance status display name from Dictionary_ComplianceOverviewStatus.DisplayName. |
| 13 | Reason | NVARCHAR | YES | - | CODE-BACKED | Status reason from Dictionary_ComplianceStatusReason.DisplayName. |
| 14 | Requirement close date | DATETIME | YES | - | CODE-BACKED | When this requirement was resolved (Compliance_CustomerRequirementsOverviewStatus.OccurredEnd). NULL if still active. |
| 15 | Player Status | NVARCHAR | YES | - | CODE-BACKED | Customer's current player status (Dictionary.PlayerStatus.Name). |
| 16 | Verification Level | NVARCHAR | YES | - | CODE-BACKED | Customer's KYC verification level (Dictionary.VerificationLevel.Name via BackOffice.Customer). |
| 17 | GCID | INT | NO | - | CODE-BACKED | Global Customer ID from the compliance record. Primary key in compliance system. |
| 18 | Triggered by | NVARCHAR | YES | - | CODE-BACKED | System or team that triggered this compliance requirement (Dictionary_ComplianceOwner.DisplayName). |
| 19 | Regulation | NVARCHAR | YES | - | CODE-BACKED | Regulatory jurisdiction (Dictionary.Regulation.Name via BackOffice.Customer.RegulationID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Cid -> @Gcid | Customer.Customer | GCID resolution | Resolves CID to GCID for compliance system lookup. |
| GCID | Compliance_CustomerRequirementsOverviewStatus | Primary source (cross-DB dynamic SQL) | Main compliance event log. |
| RequirementID | Compliance_Requirements | LEFT JOIN (via temp table) | Requirement display name. |
| OverviewStatusID | Dictionary_ComplianceOverviewStatus | LEFT JOIN (via temp table) | Status display name. |
| OwnerID | Dictionary_ComplianceOwner | LEFT JOIN (via temp table) | Triggered-by team/system. |
| StatusReasonID | Dictionary_ComplianceStatusReason | LEFT JOIN (via temp table) | Status reason display name. |
| GCID | Customer.Customer | LEFT JOIN | Resolves GCID to CID for output. |
| PlayerStatusID | Dictionary.PlayerStatus | LEFT JOIN | Player status name. |
| CID | BackOffice.Customer | LEFT JOIN | VerificationLevelID, RegulationID. |
| VerificationLevelID | Dictionary.VerificationLevel | LEFT JOIN | Verification level name. |
| RegulationID | Dictionary.Regulation | LEFT JOIN | Regulation name. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BackOffice compliance review screen. No SQL procedure callers found in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetComplianceReport (procedure)
├── Customer.Customer (table) [cross-schema, GCID resolution + output CID]
├── Compliance_CustomerRequirementsOverviewStatus (synonym -> ComplianceStateDB)
├── Compliance_Requirements (synonym -> ComplianceStateDB)
├── Dictionary_ComplianceOverviewStatus (synonym -> ComplianceStateDB)
├── Dictionary_ComplianceOwner (synonym -> ComplianceStateDB)
├── Dictionary_ComplianceStatusReason (synonym -> ComplianceStateDB)
├── Dictionary.PlayerStatus (table) [cross-schema]
├── BackOffice.Customer (table)
├── Dictionary.VerificationLevel (table) [cross-schema]
└── Dictionary.Regulation (table) [cross-schema]
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by BackOffice compliance screen. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Creates 5 temp tables each with unique clustered index. Dynamic SQL inserts into #Compliance_CustomerRequirementsOverviewStatus first, then adds clustered index on GCID - optimal for the subsequent LEFT JOINs. DROP TABLE IF EXISTS guards throughout for safe re-execution.

### 7.2 Constraints

No SET NOCOUNT ON. NOLOCK on final SELECT temp table reads. Dynamic SQL via Exec(@S1) for compliance pre-filter. Commented-out alternative code block (the original non-dynamic version is preserved as a SQL comment). @ComplianceOverviewStatusId=-6 is a special sentinel value. The `Compliance_*` and `Dictionary_*` table names without schema qualification resolve through synonyms or linked server default context.

---

## 8. Sample Queries

### 8.1 Get compliance history for a specific customer
```sql
EXEC BackOffice.GetComplianceReport @Cid = 10848122;
```

### 8.2 Get all non-completed compliance requirements in date range
```sql
EXEC BackOffice.GetComplianceReport
    @ComplianceOverviewStatusId = -6,  -- all except Completed
    @StartDate = '2026-03-10',
    @EndDate = '2026-03-17';
```

### 8.3 Get specific requirement status for a regulation
```sql
EXEC BackOffice.GetComplianceReport
    @ComplianceRequirementId = 5,
    @RegulationId = 1,
    @StartDate = '2026-01-01',
    @EndDate = '2026-01-07';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetComplianceReport | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetComplianceReport.sql*
