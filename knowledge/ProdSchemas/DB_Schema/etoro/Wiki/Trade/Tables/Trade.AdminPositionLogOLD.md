# Trade.AdminPositionLogOLD

> Legacy archive of administrative position operations, superseded by Trade.AdminPositionLog after schema evolution added CompensationCreditID and OrderID columns.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | AdminPositionID (BIGINT IDENTITY(1,1), PK CLUSTERED) |
| **Partition** | No (DICTIONARY filegroup) |
| **Indexes** | 8 active |

---

## 1. Business Meaning

This table is the **legacy predecessor** of `Trade.AdminPositionLog`. It has an identical schema minus two columns (`CompensationCreditID` and `OrderID`) that were added to the current table. The IDENTITY seed difference (1 vs 3747184 in the current table) confirms data was migrated: the current table's seed picks up after the last ID in this OLD table.

The table exists to preserve historical admin position records from before the schema change. It currently contains 0 rows, indicating all historical data has been either migrated or purged. No active procedures write to this table.

No procedures reference `AdminPositionLogOLD` for writes. It is retained in the schema as a historical artifact. The business logic, state machine, and all operational context are identical to `Trade.AdminPositionLog` - see that table's documentation for full details.

---

## 2. Business Logic

### 2.1 Legacy Migration Pattern

**What**: This table represents the pre-migration version of the admin position log.

**Columns/Parameters Involved**: All columns (identical to AdminPositionLog minus CompensationCreditID and OrderID)

**Rules**:
- IDENTITY(1,1) seed confirms this was the original table
- AdminPositionLog IDENTITY(3747184,1) picks up where this table's last ID ended
- 0 rows indicates migration is complete and data has been cleaned up
- Same State machine applies: 1=Pending, 2=Placed, 3=Filled, 4=Rejected (Dictionary.AdminPositionState)

---

## 3. Data Overview

Table is empty (0 rows). All historical data has been migrated to `Trade.AdminPositionLog` or purged.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AdminPositionID | bigint IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-generated surrogate key. Original IDENTITY starting at 1 (vs 3747184 in current table). |
| 2 | AdminPositionRequestID | uniqueidentifier | YES | - | CODE-BACKED | Correlation GUID grouping entries from the same batch request. Same as AdminPositionLog. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer identifier. Implicit FK to Customer.CustomerStatic. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument. Implicit FK to Trade.Instrument. |
| 5 | OpenActionType | int | NO | - | VERIFIED | Why this admin position was created. Maps to Dictionary.OpenPositionActionType (see Trade.AdminPositionLog for full value map). |
| 6 | AdminPositionEventID | uniqueidentifier | YES | - | CODE-BACKED | Event correlation ID for distributed tracing. |
| 7 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Number of units/shares. NULL when Amount is used instead. |
| 8 | Amount | money | YES | - | CODE-BACKED | Monetary amount. NULL when AmountInUnits is used instead. |
| 9 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server assigned. Implicit FK to Trade.HedgeServer. |
| 10 | RequestOccurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the request was created. |
| 11 | UserName | varchar(100) | YES | - | CODE-BACKED | Operator who initiated the request. |
| 12 | ExecutionOccurred | datetime | YES | - | CODE-BACKED | UTC timestamp of execution. NULL if not filled. |
| 13 | PositionID | bigint | YES | - | CODE-BACKED | Resulting position ID after successful execution. |
| 14 | State | int | NO | - | VERIFIED | Lifecycle state: 1=Pending, 2=Placed, 3=Filled, 4=Rejected (Dictionary.AdminPositionState). |
| 15 | FailReason | varchar(8000) | YES | - | CODE-BACKED | Error description when State=4. |
| 16 | ErrorCode | int | YES | - | CODE-BACKED | Numeric error code when State=4. |
| 17 | Cusip | varchar(100) | YES | - | NAME-INFERRED | CUSIP identifier for US securities. |
| 18 | ApexID | varchar(100) | YES | - | NAME-INFERRED | Apex Clearing account/transaction identifier. |
| 19 | Rate | decimal(16,6) | YES | - | CODE-BACKED | Execution rate/price. |
| 20 | RateTime | datetime | YES | - | CODE-BACKED | Timestamp of execution rate. |
| 21 | CheckBalance | bit | NO | - | CODE-BACKED | Whether to validate customer balance before opening. 0=Skip, 1=Enforce. |
| 22 | IsComputeForHedge | bit | NO | - | CODE-BACKED | Whether position is included in hedge calculations. 0=Exclude, 1=Include. |
| 23 | IsFunded | bit | NO | - | CODE-BACKED | Whether this is a funded/real position. 1=Funded, 0=CFD. |
| 24 | CompensationReasonID | int | NO | - | CODE-BACKED | Reason code for the compensation. Same as AdminPositionLog. |
| 25 | ValidatePositionWorth | bit | NO | - | CODE-BACKED | Whether to validate minimum position value. 0=Skip, 1=Enforce. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Customer receiving the admin position |
| InstrumentID | Trade.Instrument | Implicit FK | Financial instrument |
| HedgeServerID | Trade.HedgeServer | Implicit FK | Hedge server for execution |
| OpenActionType | Dictionary.OpenPositionActionType | Implicit Lookup | Action type classification |
| State | Dictionary.AdminPositionState | Implicit Lookup | Request lifecycle state |

### 5.2 Referenced By (other objects point to this)

No active procedures reference this legacy table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | AdminPositionID ASC | - | - | Active |
| IX_AdminPositionLog_AdminPositionEventID | NC | AdminPositionEventID ASC | - | - | Active |
| IX_AdminPositionLog_AdminPositionRequestID_CID | NC | AdminPositionRequestID ASC, CID ASC | - | - | Active |
| IX_AdminPositionLog_CID | NC | CID ASC | - | - | Active |
| IX_AdminPositionLog_OpenActionType | NC | OpenActionType ASC | - | - | Active |
| IX_AdminPositionLog_PositionID | NC | PositionID ASC | - | - | Active |
| IX_AdminPositionLog_RequestOccurred | NC | RequestOccurred ASC | - | - | Active |
| IX_ExecutionOccurred | NC | ExecutionOccurred ASC | - | - | Active (ROW compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if legacy table still has data
```sql
SELECT  COUNT(*) AS RowCount
FROM    Trade.AdminPositionLogOLD WITH (NOLOCK)
```

### 8.2 Compare schema with current table
```sql
SELECT  c.name, c.system_type_id, c.max_length, c.is_nullable
FROM    sys.columns c
JOIN    sys.tables t ON c.object_id = t.object_id
JOIN    sys.schemas s ON t.schema_id = s.schema_id
WHERE   s.name = 'Trade' AND t.name = 'AdminPositionLogOLD'
ORDER BY c.column_id
```

### 8.3 Verify IDENTITY seed gap between OLD and current
```sql
SELECT  'OLD' AS TableVersion, IDENT_CURRENT('Trade.AdminPositionLogOLD') AS CurrentIdentity
UNION ALL
SELECT  'Current', IDENT_CURRENT('Trade.AdminPositionLog')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 9.2/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (legacy) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AdminPositionLogOLD | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.AdminPositionLogOLD.sql*
