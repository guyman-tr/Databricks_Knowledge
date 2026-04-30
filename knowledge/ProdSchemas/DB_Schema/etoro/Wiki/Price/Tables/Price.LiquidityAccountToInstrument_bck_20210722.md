# Price.LiquidityAccountToInstrument_bck_20210722

> Backup snapshot of Price.LiquidityAccountToInstrument taken on 2021-07-22, preserved as a point-in-time reference before a schema or data migration. Contains only the two key columns (LiquidityAccountID, InstrumentID) with no constraints, indexes, or temporal tracking. Stored on the [DICTIONARY] filegroup.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | None (no PK, no indexes) |
| **Partition** | No (ON [DICTIONARY] filegroup) |
| **Indexes** | 0 |

---

## 1. Business Meaning

Price.LiquidityAccountToInstrument_bck_20210722 is a dated backup copy of Price.LiquidityAccountToInstrument captured on July 22, 2021. It contains a snapshot of the liquidity account-to-instrument mapping as it existed on that date, preserved before a migration or restructuring event.

This follows eToro's recurring pattern of creating `_bck_{date}` backup tables before significant schema changes (also seen with Price.BuyRatio_old). The backup allows operations to compare the pre-migration state with the post-migration state, or to recover data if the migration introduced errors.

Key differences from the live table:
- **No PK**: no uniqueness enforcement on (LiquidityAccountID, InstrumentID)
- **No indexes**: no query optimization
- **No FK constraints**: no referential integrity checks
- **No temporal/audit columns**: no DbLoginName, AppLoginName, SysStartTime, SysEndTime, HostName
- **ON [DICTIONARY] filegroup**: stored on the DICTIONARY filegroup rather than PRIMARY - an operational choice for backup isolation

This table is inert - nothing reads from or writes to it in normal operations. Its 0-row count in this environment reflects that the backup was either not populated on this instance or was cleared.

For the active mapping configuration, see Price.LiquidityAccountToInstrument.

---

## 2. Business Logic

No active business logic. This table is a point-in-time backup. See Price.LiquidityAccountToInstrument for the live table's logic documentation.

---

## 3. Data Overview

| Note | Value |
|------|-------|
| Row count (this environment) | 0 |
| Active | No - backup/archive only |
| Backup date | 2021-07-22 (from table name) |
| Writers | None |
| Readers | None |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NOT NULL | - | CODE-BACKED | Liquidity account identifier. Same semantic as Price.LiquidityAccountToInstrument.LiquidityAccountID. No FK constraint in this backup copy. |
| 2 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. Same semantic as Price.LiquidityAccountToInstrument.InstrumentID. No FK constraint in this backup copy. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FK constraints).

### 5.2 Referenced By (other objects point to this)

No objects reference this backup table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.LiquidityAccountToInstrument_bck_20210722 (table) - isolated backup, no dependencies
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No objects depend on this table.

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

*Note: ON [DICTIONARY] filegroup - backup stored on DICTIONARY filegroup rather than PRIMARY, likely for storage isolation from operational data.*

---

## 8. Sample Queries

### 8.1 Verify backup table state

```sql
SELECT COUNT(*) AS RowCount FROM Price.LiquidityAccountToInstrument_bck_20210722 WITH (NOLOCK);
```

### 8.2 Compare backup with current state (if data exists)

```sql
-- Mappings in backup but not in current table (deleted since backup)
SELECT bck.LiquidityAccountID, bck.InstrumentID
FROM Price.LiquidityAccountToInstrument_bck_20210722 bck WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Price.LiquidityAccountToInstrument live WITH (NOLOCK)
    WHERE live.LiquidityAccountID = bck.LiquidityAccountID
      AND live.InstrumentID = bck.InstrumentID
);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 7/10, Logic: 6/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.LiquidityAccountToInstrument_bck_20210722 | Type: Table | Source: etoro/etoro/Price/Tables/Price.LiquidityAccountToInstrument_bck_20210722.sql*
