# ef.MigrationsHistory

> Entity Framework Core migrations history table, tracking which database schema migrations have been applied to this Sodreconciliation database.

| Property | Value |
|----------|-------|
| **Schema** | ef |
| **Object Type** | Table |
| **Key Identifier** | MigrationId (nvarchar(150), PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

This is the standard Entity Framework Core migrations tracking table (conventionally `__EFMigrationsHistory`, here placed in the `ef` schema). EF Core uses this table to track which code-first migrations have been applied to the database. Each row represents a migration that has been successfully run.

This is an infrastructure/framework table, not application data. It is managed entirely by EF Core's migration tooling (`dotnet ef database update`) and should never be modified manually.

**Live data insight**: 10 migrations have been applied, spanning from May 2022 to April 2023. The application upgraded from EF Core 3.1.21 to 6.0.10 between August 2022 and January 2023. Migration names reveal the schema evolution timeline: CUSIP unification, Hidden flag addition, average close price columns, mirror ID tracking, Apex trade activity FK, and the dict.SodFileProcessingStatuses table were all added through these migrations. No migrations since April 2023 indicates the schema has been stable for 3+ years.

---

## 2. Business Logic

No business logic. EF Core framework table.

---

## 3. Data Overview

10 migrations applied. EF Core versions upgraded from 3.1.21 to 6.0.10 over time:

| MigrationId | ProductVersion | Meaning |
|---|---|---|
| 20230418102535_Fix1036 | 6.0.10 | Latest migration - fix for EXT1036 W8 Recertification table. |
| 20230112081540_Add_SodFileProcessingStatuses | 6.0.10 | Added the dict.SodFileProcessingStatuses lookup table. |
| 20220817101126_AddColumn_ApexTradeActivityId_EtoroTrade | 3.1.21 | Added FK from etoro.Trades to apex.EXT872_TradeActivity. |
| 20220601145823_AddHiddenToReconTables | 3.1.21 | Added Hidden flag to recon tables for UI suppression. |
| 20220505111425_UnifyCusip | 3.1.21 | Earliest visible migration - unified CUSIP handling. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MigrationId | nvarchar(150) | NO | - | CODE-BACKED | Unique migration identifier. Format: `{Timestamp}_{MigrationName}` (e.g., "20240101120000_InitialCreate"). Primary key. |
| 2 | ProductVersion | nvarchar(32) | NO | - | CODE-BACKED | EF Core version that generated this migration (e.g., "8.0.0", "7.0.14"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No database objects reference this table. Managed by EF Core tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MigrationsHistory | CLUSTERED PK | MigrationId | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all applied migrations

```sql
SELECT MigrationId, ProductVersion
FROM ef.MigrationsHistory WITH (NOLOCK)
ORDER BY MigrationId;
```

### 8.2 Find the latest migration

```sql
SELECT TOP 1 MigrationId, ProductVersion
FROM ef.MigrationsHistory WITH (NOLOCK)
ORDER BY MigrationId DESC;
```

### 8.3 Check EF Core version used

```sql
SELECT DISTINCT ProductVersion
FROM ef.MigrationsHistory WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a standard EF Core framework table.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: ef.MigrationsHistory | Type: Table | Source: Sodreconciliation/Sodreconciliation/ef/Tables/ef.MigrationsHistory.sql*
