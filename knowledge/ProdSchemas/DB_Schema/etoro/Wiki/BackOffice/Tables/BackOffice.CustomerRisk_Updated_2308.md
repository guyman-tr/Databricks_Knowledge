# BackOffice.CustomerRisk_Updated_2308

> Empty archive snapshot table created in August 2023 (suffix "2308") as a backup before a bulk update operation on BackOffice.CustomerRisk. Column structure mirrors CustomerRisk exactly, without the PK, indexes, or FK constraints of the live table.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | None (no PK, no constraints) |
| **Partition** | No (stored ON [PRIMARY] filegroup) |
| **Indexes** | 0 |

---

## 1. Business Meaning

BackOffice.CustomerRisk_Updated_2308 is a point-in-time archive table created in August 2023 as part of a bulk data operation on the main BackOffice.CustomerRisk table. The `_Updated_2308` naming convention (2308 = year 2023, month 08) identifies this as a before-update or after-update snapshot from that period.

The table is currently empty (0 rows as of 2026-03-17) and is not referenced by any stored procedure, view, or function in the SSDT repo. It is a historical artifact left in the schema after the 2023 operation completed.

The column structure is identical to BackOffice.CustomerRisk (GCID, RiskStatusID, Occurred, ModifiedDate, Remark, RiskEventStatusID, ManagerID), but without the clustered PK, FK constraints, or DATA_COMPRESSION used in the live table - consistent with a temporary staging or backup table that was created quickly for a one-off DML operation.

**Live table**: BackOffice.CustomerRisk (PK on GCID+RiskStatusID, FKs to Dictionary.RiskStatus and Dictionary.RiskEventStatus, DATA_COMPRESSION=PAGE on [MAIN] filegroup) is the production risk record table tracking customer risk status events.

---

## 2. Business Logic

No active business logic. The table exists as an archive artifact and contains no data. It is not read, written, or maintained by any procedure in the current codebase.

Probable historical use: During the August 2023 operation, this table was populated with a SELECT INTO or INSERT...SELECT to preserve original CustomerRisk rows before applying a bulk UPDATE or DELETE. After the operation completed and was verified, the table was left in place (common practice for audit trail retention).

---

## 3. Data Overview

0 rows as of 2026-03-17. Table is empty.

---

## 4. Elements

The column structure mirrors BackOffice.CustomerRisk exactly:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. In CustomerRisk this is the PK leading key (with RiskStatusID). Here: no constraint. Matches CustomerRisk.GCID semantics - identifies the customer whose risk record was snapshotted. |
| 2 | RiskStatusID | int | NO | - | CODE-BACKED | Risk status code. In CustomerRisk this FK references Dictionary.RiskStatus. Here: no FK constraint. Values mirror the live table's RiskStatusID values as of August 2023. |
| 3 | Occurred | datetime | YES | NULL | CODE-BACKED | Timestamp when the risk event occurred. In CustomerRisk: DEFAULT GETUTCDATE(). Here: no default constraint. |
| 4 | ModifiedDate | datetime | NO | - | CODE-BACKED | Timestamp when the risk record was last modified. In CustomerRisk: DEFAULT GETUTCDATE(). Here: no default constraint. |
| 5 | Remark | varchar(255) | YES | NULL | CODE-BACKED | Free-text remark added by the BackOffice agent or system process during the risk event. Max 255 chars. |
| 6 | RiskEventStatusID | int | NO | - | CODE-BACKED | Risk event status code. In CustomerRisk this FK references Dictionary.RiskEventStatus. Here: no FK constraint. |
| 7 | ManagerID | int | YES | NULL | CODE-BACKED | ID of the BackOffice manager/agent who processed or reviewed this risk event. NULL for system-generated records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

No FK constraints. Logically mirrors BackOffice.CustomerRisk's relationships (Dictionary.RiskStatus, Dictionary.RiskEventStatus) but without enforcement.

### 5.2 Referenced By (other objects point to this)

No objects reference this table. It is not consumed by any procedure, view, or function in the SSDT repo.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerRisk_Updated_2308 (archive table)
- Mirrors structure of: BackOffice.CustomerRisk (live table)
- No active dependencies
```

### 6.1 Objects This Depends On

No dependencies (no FK constraints declared).

### 6.2 Objects That Depend On This

None.

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. Consistent with a temporary archive table not intended for queried access.

### 7.2 Constraints

No constraints of any kind (no PK, no FK, no CHECK, no DEFAULT). Minimal DDL - CREATE TABLE only.

---

## 8. Sample Queries

### 8.1 Verify the table is empty
```sql
SELECT COUNT(*) AS RowCount
FROM BackOffice.CustomerRisk_Updated_2308 WITH (NOLOCK)
```

### 8.2 Compare structure to live CustomerRisk (if data ever restored)
```sql
-- Live table for reference
SELECT TOP 10 GCID, RiskStatusID, Occurred, ModifiedDate, Remark, RiskEventStatusID, ManagerID
FROM BackOffice.CustomerRisk WITH (NOLOCK)
ORDER BY ModifiedDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. The 2308 suffix suggests a bulk operation in August 2023, but no specific Jira ticket was identified.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerRisk_Updated_2308 | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerRisk_Updated_2308.sql*
