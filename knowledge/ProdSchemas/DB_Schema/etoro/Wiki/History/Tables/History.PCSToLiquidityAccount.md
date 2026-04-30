# History.PCSToLiquidityAccount

> SQL Server temporal history table storing prior row versions of Price.PCSToLiquidityAccount, preserving the full audit trail for changes to the mapping between Price Consolidation Sources and their assigned liquidity accounts.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.PCSToLiquidityAccount is the SQL Server system-versioning history table for Price.PCSToLiquidityAccount (declared as `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[PCSToLiquidityAccount])`). Whenever a mapping row in Price.PCSToLiquidityAccount is updated or deleted, the prior version is automatically written here.

Price.PCSToLiquidityAccount maps Price Consolidation Sources (PCS - internal price feed aggregation nodes identified by PCSID) to the liquidity accounts (LiquidityAccountID) through which their price data flows. This mapping determines which LP connection account each price source feeds into, enabling the pricing engine to route price data correctly for execution. Managed via the ConfigurationManager application (from AppLoginName evidence in the data).

This history table is part of a dual-audit architecture: in addition to temporal history, the source table also has ASM-generated triggers (AuditInsert/AuditUpdate/AuditDelete) writing to History.AuditHistory, and an INSERT-capture trigger (Tr_T_LiquidityProviders_INSERT) for the standard temporal INSERT logging pattern.

---

## 2. Business Logic

### 2.1 Temporal History Pattern

**What**: This table automatically receives prior versions of Price.PCSToLiquidityAccount rows.

**Columns/Parameters Involved**: `PCSID`, `LiquidityAccountID`, `SysStartTime`, `SysEndTime`

**Rules**:
- The composite PK in the source table is (PCSID, LiquidityAccountID); history rows may repeat the same pair across multiple time windows.
- SysStartTime=SysEndTime: INSERT-capture record from the Tr_T_LiquidityProviders_INSERT trigger.
- Normal UPDATE/DELETE history: SysEndTime records when this version was superseded.
- DbLoginName/AppLoginName are computed in the source table from SUSER_NAME() and CONTEXT_INFO() at write time.

### 2.2 Dual Audit Architecture

**What**: Price.PCSToLiquidityAccount maintains both temporal history AND AuditHistory entries for all changes.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- ASM-generated triggers (AuditInsert, AuditDelete, AuditUpdate) write to History.AuditHistory for every INSERT/UPDATE/DELETE, recording old/new values per column.
- Temporal history (this table) captures the complete row snapshot per version.
- The two mechanisms are complementary: AuditHistory is column-level (what changed), temporal history is row-level (full row per version).
- AppLoginName typically contains the ConfigurationManager application login with trailing nulls (nvarchar padding).

---

## 3. Data Overview

| PCSID | LiquidityAccountID | DbLoginName | SysStartTime | SysEndTime | Meaning |
|-------|-------------------|-------------|-------------|------------|---------|
| 2 | 7 | TRAD\danielma | 2026-02-19 07:31 | 2026-02-19 07:31 | INSERT-capture record for PCSID=2 -> LA=7 mapping; created and immediately captured via trigger |
| 2 | 7 | TRAD\danielma | 2024-03-20 09:43 | 2026-02-19 07:31:07 | Prior version active ~2 years; the same PCS/LA mapping was re-inserted in Feb 2026 (zero-duration records bracket) |
| 3 | 308 | TRAD\danielma | 2026-02-19 07:19 | 2026-02-19 07:19 | INSERT-capture record for PCSID=3 -> LA=308 mapping via ConfigurationManager |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PCSID | int | NO | - | CODE-BACKED | Price Consolidation Source identifier. Identifies the internal price feed node being mapped. Part of the composite key in the source table (Price.PCSToLiquidityAccount). |
| 2 | LiquidityAccountID | int | NO | - | CODE-BACKED | Liquidity account this price source feeds into. FK to Trade.LiquidityAccounts in the source table. Identifies the LP connection account that receives price data from the PCSID source. |
| 3 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that made the change, computed from SUSER_NAME() in the source table. Captured at write time for audit. Typically "TRAD\{username}" format. |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context info at change time, from CONTEXT_INFO() in the source. Set by ConfigurationManager before the change. Includes the username and application name, padded with nulls to 500 chars. |
| 5 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this mapping version became active in Price.PCSToLiquidityAccount. Set by the SQL Server temporal engine. |
| 6 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this mapping version was superseded. SysStartTime=SysEndTime indicates an INSERT-capture record from the Tr_T_LiquidityProviders_INSERT trigger. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source table) | Price.PCSToLiquidityAccount | Temporal History | This table is the declared HISTORY_TABLE for Price.PCSToLiquidityAccount. |
| LiquidityAccountID | Trade.LiquidityAccounts | Implicit | The liquidity account the PCS maps to (FK in source table). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.PCSToLiquidityAccount | HISTORY_TABLE | Temporal system versioning | All row version changes are automatically written here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.PCSToLiquidityAccount | Table | Source of all history writes via SQL Server temporal system versioning |
| Internal.PCSToLiquidityAccount_Report | Stored Procedure | READER - reporting on PCS-to-LA mapping history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PCSToLiquidityAccount | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

None. Temporal history tables have no PK or FK constraints.

---

## 8. Sample Queries

### 8.1 View full change history for a specific PCS-to-LA mapping

```sql
SELECT PCSID, LiquidityAccountID, DbLoginName, SysStartTime, SysEndTime,
       DATEDIFF(MINUTE, SysStartTime, SysEndTime) AS ActiveMinutes
FROM History.PCSToLiquidityAccount WITH (NOLOCK)
WHERE PCSID = 2
ORDER BY SysStartTime;
```

### 8.2 Show all changes made by ConfigurationManager in the last 6 months

```sql
SELECT PCSID, LiquidityAccountID, DbLoginName, SysStartTime, SysEndTime
FROM History.PCSToLiquidityAccount WITH (NOLOCK)
WHERE AppLoginName LIKE 'ConfigurationManager%'
  AND SysStartTime >= DATEADD(MONTH, -6, GETUTCDATE())
ORDER BY SysStartTime DESC;
```

### 8.3 Compare current mapping with historical mapping at a point in time

```sql
SELECT 'Current' AS Version, PCSID, LiquidityAccountID, SysStartTime
FROM Price.PCSToLiquidityAccount WITH (NOLOCK)
UNION ALL
SELECT 'History', PCSID, LiquidityAccountID, SysStartTime
FROM History.PCSToLiquidityAccount WITH (NOLOCK)
ORDER BY PCSID, SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PCSToLiquidityAccount | Type: Table | Source: etoro/etoro/History/Tables/History.PCSToLiquidityAccount.sql*
