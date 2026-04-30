# Apex.ApexData

> Core mapping table linking each customer (GCID) to their Apex Clearing brokerage account (ApexID) and tracking the high-level account status.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | ApexID (VARCHAR(8), CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) + 1 unique constraint (GCID) |

---

## 1. Business Meaning

Apex.ApexData is the central record linking the platform's internal customer identifier (GCID) to the external Apex Clearing account identifier (ApexID). Every customer who has a brokerage account at Apex Clearing has exactly one row in this table. It serves as the primary bridge between the platform's user management system and the third-party clearing house.

This table is essential because it holds the authoritative mapping between the platform's customer ID space and Apex's account ID space. Without it, the system cannot determine which Apex account belongs to which customer, making all brokerage operations (trading, settlement, account updates) impossible. The StatusID column provides the high-level lifecycle status of the account, enabling quick checks on whether an account is active, rejected, restricted, or closed.

Data flows through this table via Apex.SaveApexData, which uses a MERGE pattern to insert new accounts or update status changes. On INSERT, a trigger (ApexDataInsert) copies the new row to Apex.TradingApexData for the trading platform's consumption. The system versioning (History.ApexData) provides a full audit trail of every status change. Multiple procedures read this table: GetApexData for single-customer lookups, GetApexDataAndState for combined account+state retrieval, and GetApexDataByApexId for reverse lookups by Apex account ID.

---

## 2. Business Logic

### 2.1 ApexID-to-GCID Immutable Binding

**What**: Once an ApexID is assigned to a GCID, that binding cannot change. An ApexID is permanently associated with one customer.

**Columns/Parameters Involved**: `ApexID`, `GCID`

**Rules**:
- SaveApexData checks if the ApexID already exists with a different GCID before any operation
- If the existing GCID does not match the incoming GCID, the procedure throws error 51000 with a descriptive message
- This prevents accidental reassignment of Apex accounts between customers, which would be a critical compliance violation
- The UNIQUE constraint on GCID also ensures one customer cannot have multiple Apex accounts

**Diagram**:
```
SaveApexData(@ApexID, @GCID, @StatusID)
    |
    v
Existing ApexID found?
    |-- No  --> MERGE INSERT (new account)
    |-- Yes --> ExistingGCID = @GCID?
                    |-- Yes --> Update StatusID (if changed)
                    |-- No  --> THROW 51000 (binding violation!)
```

### 2.2 Status-Change-Only Updates with Sync Flag Reset

**What**: Updates only occur when the StatusID actually changes, and the UpdatedSync flag is reset to 0 to signal the trading platform needs to pick up the change.

**Columns/Parameters Involved**: `StatusID`, `UpdatedSync`

**Rules**:
- The MERGE update clause includes `Not Target.StatusID = Source.StatusID` - no-op if status hasn't changed
- On status change, UpdatedSync is set to 0 (false), marking the record as needing synchronization to the trading platform
- The trading platform reads UpdatedSync=0 records and sets it to 1 (true) after syncing
- Distribution: ~722K rows have UpdatedSync=false (synced), ~42K have UpdatedSync=true (pending sync or permanently flagged)

### 2.3 Insert Trigger Replication to TradingApexData

**What**: Every new account record is automatically copied to TradingApexData via an INSERT trigger, providing the trading platform with its own copy of the account mapping.

**Columns/Parameters Involved**: `ApexID`, `GCID`, `StatusID`, `UpdatedSync`, `BeginTime`

**Rules**:
- Trigger ApexDataInsert fires on INSERT only (not UPDATE)
- Copies ApexID, GCID, StatusID, UpdatedSync, and BeginTime to Apex.TradingApexData
- TradingApexData is the trading platform's local copy, allowing it to operate independently from the Apex integration workflow

---

## 3. Data Overview

| ApexID | GCID | StatusID | BeginTime | UpdatedSync | Meaning |
|--------|------|----------|-----------|-------------|---------|
| 3ER05011 | 19533157 | 12 | 2022-02-27 | false | Completed (COMPLETE) account - customer has an active, fully-set-up brokerage account at Apex. The most common state (~604K accounts). |
| 3ER05013 | 29100986 | 15 | 2025-05-14 | false | Restricted (RESTRICTED) account - trading is blocked, likely due to compliance or regulatory hold. Third most common state (~47K accounts). |
| 3ER05012 | 27497960 | 12 | 2022-02-27 | false | Another completed account created during the initial bulk migration in Feb 2022. ApexID format: 3ER + 5-digit sequence. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ApexID | varchar(8) | NO | - | CODE-BACKED | The unique account identifier assigned by Apex Clearing. Format observed: "3ER" prefix + 5-digit numeric sequence (e.g., "3ER05011"). This is the primary key and the external identifier used in all API calls to Apex. Maximum 8 characters. Immutably bound to one GCID - SaveApexData throws error 51000 if an attempt is made to reassign an ApexID to a different customer. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID - the platform's unique identifier for a user. Each GCID appears at most once (UNIQUE constraint), enforcing a 1:1 relationship between platform customers and Apex accounts. Used as the primary lookup key by GetApexData and as the JOIN key across all Apex schema tables. |
| 3 | StatusID | int | NO | - | VERIFIED | High-level lifecycle status of the Apex brokerage account. FK to Dictionary.ApexStatus. Distribution: 12=COMPLETE (604,566 - 79%), 11=REJECTED (68,370 - 9%), 15=RESTRICTED (46,871 - 6%), 4=ACTION_REQUIRED (40,010 - 5%), 5=SUSPENDED (3,476), 10=ERROR (39), 3=INVESTIGATION_SUBMITTED (12), 2=PENDING (4), 7=BACK_OFFICE (2), 8=ACCOUNT_SETUP (1). See [Apex Status](_glossary.md#apex-status) for full definitions. (Dictionary.ApexStatus) |
| 4 | BeginTime | datetime2(0) | NO | dateadd(second,(-1),sysutcdatetime()) | CODE-BACKED | System versioning row start time. Records when this version of the row became active. Default is 1 second before current UTC time (offset to avoid temporal table edge cases). Used by GetApexData to return creation/modification timestamps to callers. Part of SYSTEM_TIME period for temporal table History.ApexData. |
| 5 | EndTime | datetime2(0) | NO | '9999.12.31 23:59:59.99' | CODE-BACKED | System versioning row end time. Value of '9999-12-31' indicates the current active row. When a row is updated, the old version's EndTime is set to the update time and moved to History.ApexData. Part of SYSTEM_TIME period. |
| 6 | UpdatedSync | bit | NO | 0 | CODE-BACKED | Synchronization flag for the trading platform. Set to 0 (false) by SaveApexData whenever StatusID changes, signaling the trading platform that this account's status needs to be re-synced. The trading platform reads records with UpdatedSync=0, processes them, and sets it to 1 (true). Default is 0 (needs sync) for new records. Distribution: ~722K false (synced), ~42K true. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StatusID | Dictionary.ApexStatus | FK | Account lifecycle status - 16 possible values from NEW through COMPLETE/REJECTED/CLOSED |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.TradingApexData | (trigger copy) | Trigger | INSERT trigger copies new rows to TradingApexData for trading platform consumption |
| Apex.SaveApexData | @ApexID, @GCID, @StatusID | Writer | Upserts account records via MERGE |
| Apex.GetApexData | @GCID | Reader | Retrieves account by GCID |
| Apex.GetApexDataAndState | GCID | Reader | JOINs with State and UserData for combined retrieval |
| Apex.GetApexDataByApexId | ApexID | Reader | Reverse lookup by Apex account ID |
| Apex.DeleteApexData | @GCID | Deleter | Removes account record by GCID |
| Apex.GetStuckUsers | (referenced) | Reader | Identifies users stuck in processing |
| Apex.SaveStuckUser | (referenced) | Writer | Manages stuck user records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.ApexData (table)
└── Dictionary.ApexStatus (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ApexStatus | Table | FK target for StatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.TradingApexData | Table | Receives INSERT trigger copies |
| Apex.SaveApexData | Stored Procedure | Writer - upserts via MERGE |
| Apex.GetApexData | Stored Procedure | Reader - lookup by GCID |
| Apex.GetApexDataAndState | Stored Procedure | Reader - JOINs with State, UserData |
| Apex.GetApexDataByApexId | Stored Procedure | Reader - reverse lookup by ApexID |
| Apex.DeleteApexData | Stored Procedure | Deleter - removes by GCID |
| Apex.GetStuckUsers | Stored Procedure | Reader - stuck user detection |
| Apex.SaveStuckUser | Stored Procedure | Writer - stuck user management |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ApexData | CLUSTERED PK | ApexID ASC | - | - | Active |
| UC_ApexData_GCID | NC UNIQUE | GCID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_ApexData | PRIMARY KEY | Clustered on ApexID - each Apex account ID is unique |
| UC_ApexData_GCID | UNIQUE | Each GCID appears at most once - one customer, one Apex account |
| FK_ApexData_ApexStatus | FOREIGN KEY | StatusID -> Dictionary.ApexStatus(StatusID) |
| DF_ApexData_BeginTime | DEFAULT | BeginTime = dateadd(second,(-1),sysutcdatetime()) - temporal table row start |
| DF_ApexData_EndTime | DEFAULT | EndTime = '9999.12.31 23:59:59.99' - temporal table row end |
| (unnamed) | DEFAULT | UpdatedSync = 0 - new records need sync |
| SYSTEM_VERSIONING | TEMPORAL | History table: History.ApexData |

---

## 8. Sample Queries

### 8.1 Get a customer's Apex account with status name

```sql
SELECT d.ApexID, d.GCID, d.StatusID, s.Name AS StatusName,
       d.BeginTime, d.UpdatedSync
FROM Apex.ApexData d WITH (NOLOCK)
INNER JOIN Dictionary.ApexStatus s WITH (NOLOCK) ON s.StatusID = d.StatusID
WHERE d.GCID = 19533157;
```

### 8.2 Find accounts pending sync to the trading platform

```sql
SELECT d.ApexID, d.GCID, d.StatusID, s.Name AS StatusName, d.BeginTime
FROM Apex.ApexData d WITH (NOLOCK)
INNER JOIN Dictionary.ApexStatus s WITH (NOLOCK) ON s.StatusID = d.StatusID
WHERE d.UpdatedSync = 1
ORDER BY d.BeginTime DESC;
```

### 8.3 View status change history for a specific account

```sql
SELECT ApexID, GCID, StatusID, BeginTime, EndTime
FROM Apex.ApexData WITH (NOLOCK)
WHERE GCID = 19533157
UNION ALL
SELECT ApexID, GCID, StatusID, BeginTime, EndTime
FROM History.ApexData WITH (NOLOCK)
WHERE GCID = 19533157
ORDER BY BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.ApexData | Type: Table | Source: USABroker/Apex/Tables/Apex.ApexData.sql*
