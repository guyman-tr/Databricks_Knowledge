# History.PositionDataFixLog

> Audit log of manual data fix operations applied to trading positions, recording the before/after state of each corrected field.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No primary key - clustered on (PositionID, Occurred) |
| **Partition** | No |
| **Indexes** | 1 (1 clustered) |

---

## 1. Business Meaning

`History.PositionDataFixLog` captures the audit trail of manual data corrections applied to trading positions. When an operational data fix is performed - for example, correcting a corrupted column value, adjusting a rate after a pricing incident, or patching a field following a bug - the change is logged here with full before/after state: which column was changed, what the old value was, what the new value is, and a human-readable description of the fix.

This table exists to maintain accountability and traceability for non-standard position modifications that fall outside the normal trading lifecycle (open, close, edit SL/TP). Without it, data fix operations would leave no audit trail, making it impossible to audit corrections during compliance reviews or post-incident investigations.

Data flows into this table when a data fix operation is executed against one or more positions. Rows are surfaced through `History.PositionChangeLogFull`, which UNION ALLs this table with `History.PositionChangeLog`, assigning these rows a synthetic `PositionChangeLogID = -1` (sentinel value) and defaulting `ChangeTypeID` to `14` (Data Fix) when NULL. This means data fix events appear seamlessly alongside normal position change log events in any system reading through `PositionChangeLogFull`.

---

## 2. Business Logic

### 2.1 Integration with Position Change Log

**What**: Data fix events surface as position change log entries with type "Data Fix" through the `PositionChangeLogFull` view.

**Columns/Parameters Involved**: `PositionID`, `Occurred`, `ChangeTypeID`, `ColumnName`, `OldValue`, `NewValue`, `ChangeDescription`

**Rules**:
- `History.PositionChangeLogFull` UNIONs this table with `History.PositionChangeLog`
- Rows from this table appear with `PositionChangeLogID = -1` (sentinel - not a real PCL row)
- `ChangeTypeID` defaults to `14` (Data Fix) via `ISNULL(ChangeTypeID, 14)` in the view
- Columns `ColumnName`, `OldValue`, `NewValue`, `ChangeDescription` are populated from THIS table; the corresponding positions in `PositionChangeLog` receive NULLs for those columns
- Most `PositionChangeLog` columns (amount, rates, fees, etc.) are NULL for data fix rows - only the audit fields carry meaning

**Diagram**:
```
History.PositionDataFixLog
  (PositionID, Occurred, ChangeTypeID, ColumnName, OldValue, NewValue, ChangeDescription)
                    |
                    | UNION ALL (via History.PositionChangeLogFull)
                    |
History.PositionChangeLog
  (full PCL columns, NULLs for ColumnName/OldValue/NewValue/ChangeDescription)
                    |
                    v
         PositionChangeLogFull
         - Data fix rows: PositionChangeLogID=-1, ChangeTypeID=14
         - Normal rows:   PositionChangeLogID>0, ChangeTypeID=0..13
```

### 2.2 ChangeType Values (Dictionary.PCL_ChangeType)

**What**: The type of position change event recorded in the position change log system.

**Columns/Parameters Involved**: `ChangeTypeID`

**Rules**:
- Value `14` (Data Fix) is the canonical type for all rows from this table
- Other values (0-13) represent normal trading lifecycle events captured in `PositionChangeLog` instead
- NULL `ChangeTypeID` in this table is treated as `14` by the consuming view

**Known values**:
```
0  = Open Position
1  = Edit Stop Loss
2  = Edit Take Profit
3  = Edit Over Weekend
4  = EOW Fee (End Of Week Fee)
5  = Detach from Mirror
6  = Close Position
7  = Enable/Disable TSL
8  = PositionRedeemCancel
9  = PositionRedeemPending
10 = PositionRedeemClose
11 = Partial close
12 = Edit due to partial close
13 = Edit Is Settled
14 = Data Fix  <-- entries from this table
```

---

## 3. Data Overview

Table currently contains 0 rows. It is populated only during operational data fix operations - an infrequent, exception-based activity. Representative row would look like:

| PositionID | Occurred | ColumnName | OldValue | NewValue | ChangeDescription | ChangeTypeID |
|---|---|---|---|---|---|---|
| 123456789 | 2025-06-15 10:32:00 | OpenRate | 1.08543 | 1.08561 | Corrected open rate after pricing feed incident | 14 |
| 987654321 | 2025-07-01 09:15:00 | IsBuy | 0 | 1 | Fixed trade direction recorded incorrectly at open | NULL |

*Note: Table is empty in the current environment. Sample rows above are illustrative of the expected data pattern based on schema design.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | Identifier of the trading position that was corrected. Part of the clustered index (with Occurred), enabling efficient lookup of all fix events for a given position. References the position in Trade/History position tables (implicit relationship - no explicit FK). |
| 2 | Occurred | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when the data fix was applied. Defaults to the current time at insert. Forms the second key in the clustered index, ordering fix events chronologically per position. Used in `PositionChangeLogFull` as the event timestamp. |
| 3 | ColumnName | varchar(255) | YES | - | NAME-INFERRED | Name of the column that was corrected in this data fix operation. Together with OldValue and NewValue, provides field-level granularity of the correction. Passed through to `PositionChangeLogFull` as a unique audit field not present in the standard PositionChangeLog. |
| 4 | OldValue | varchar(255) | YES | - | NAME-INFERRED | The previous value of the corrected column before the fix was applied, stored as a string regardless of the original data type. Enables rollback auditing and confirms the starting state of the correction. |
| 5 | NewValue | varchar(255) | YES | - | NAME-INFERRED | The replacement value applied to the corrected column, stored as a string. Together with OldValue, provides the complete before/after record of the data correction. |
| 6 | ChangeDescription | varchar(255) | YES | - | NAME-INFERRED | Human-readable explanation of why the data fix was performed - e.g., "Corrected open rate after pricing feed incident". Provides context that column names and values alone cannot convey. Surfaced in `PositionChangeLogFull` alongside the technical change details. |
| 7 | ChangeTypeID | int | YES | - | CODE-BACKED | Type of position change event. For rows in this table, should be 14 (Data Fix) or NULL (treated as 14 by `PositionChangeLogFull` via `ISNULL(ChangeTypeID, 14)`). FK to Dictionary.PCL_ChangeType: 0=Open Position, 1=Edit Stop Loss, 2=Edit Take Profit, 3=Edit Over Weekend, 4=EOW Fee, 5=Detach from Mirror, 6=Close Position, 7=Enable/Disable TSL, 8=PositionRedeemCancel, 9=PositionRedeemPending, 10=PositionRedeemClose, 11=Partial close, 12=Edit due to partial close, 13=Edit Is Settled, 14=Data Fix. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl (and History equivalents) | Implicit | Identifies the trading position that was data-fixed. No explicit FK constraint. |
| ChangeTypeID | Dictionary.PCL_ChangeType | Implicit | Lookup for the type of position change. Expected value: 14 (Data Fix). No explicit FK. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PositionChangeLogFull | - | UNION ALL | UNIONs this table with PositionChangeLog to create a unified position change event feed. Assigns PositionChangeLogID=-1 and defaults ChangeTypeID to 14 for rows from this table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionDataFixLog (table)
(leaf - no code-level dependencies)
```

This object has no code-level dependencies. Dictionary.PCL_ChangeType and position tables are implicit lookup/reference relationships (see Section 5).

---

### 6.1 Objects This Depends On

No dependencies. (No explicit FK constraints, no computed columns referencing other objects.)

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PositionChangeLogFull | View | UNION ALL - includes rows from this table as ChangeType=14 (Data Fix) events in the unified position change log feed |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| Cix | CLUSTERED | PositionID ASC, Occurred ASC | - | - | Active |

*FILLFACTOR=95, PAD_INDEX=OFF. Clustered on (PositionID, Occurred) supports efficient retrieval of all fix events for a specific position in chronological order.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_PositionDataFixLog_Occurred | DEFAULT | `getutcdate()` on Occurred - automatically sets the fix timestamp to current UTC time if not supplied by the caller |

---

## 8. Sample Queries

### 8.1 All data fix events for a specific position

```sql
SELECT
    PositionID,
    Occurred,
    ColumnName,
    OldValue,
    NewValue,
    ChangeDescription,
    ChangeTypeID
FROM History.PositionDataFixLog WITH (NOLOCK)
WHERE PositionID = @PositionID
ORDER BY Occurred ASC
```

### 8.2 Recent data fix events with change type label

```sql
SELECT
    pdfl.PositionID,
    pdfl.Occurred,
    pdfl.ColumnName,
    pdfl.OldValue,
    pdfl.NewValue,
    pdfl.ChangeDescription,
    ct.ChangeTypeName
FROM History.PositionDataFixLog pdfl WITH (NOLOCK)
LEFT JOIN Dictionary.PCL_ChangeType ct WITH (NOLOCK)
    ON ct.ChangeTypeID = ISNULL(pdfl.ChangeTypeID, 14)
ORDER BY pdfl.Occurred DESC
```

### 8.3 View data fix events through the unified position change log

```sql
-- PositionDataFixLog rows appear with PositionChangeLogID = -1 and ChangeTypeID = 14
SELECT
    PositionChangeID,
    PositionID,
    Occurred,
    ChangeTypeID,
    ColumnName,
    OldValue,
    NewValue,
    ChangeDescription
FROM History.PositionChangeLogFull WITH (NOLOCK)
WHERE PositionID = @PositionID
  AND ChangeTypeID = 14  -- Data Fix events only
ORDER BY Occurred ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.3/10 (Elements: 7.1/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionDataFixLog | Type: Table | Source: etoro/etoro/History/Tables/History.PositionDataFixLog.sql*
