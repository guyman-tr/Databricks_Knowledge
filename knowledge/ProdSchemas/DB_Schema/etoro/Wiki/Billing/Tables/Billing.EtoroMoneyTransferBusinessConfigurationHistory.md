# Billing.EtoroMoneyTransferBusinessConfigurationHistory

> Temporal history table for Billing.EtoroMoneyTransferBusinessConfiguration - automatically maintains a full audit trail of every fee configuration change. Currently empty (no configuration changes have occurred since the table was created).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | None (no PK - temporal history table) |
| **Partition** | No (MAIN filegroup, PAGE compression) |
| **Indexes** | 1 (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

`Billing.EtoroMoneyTransferBusinessConfigurationHistory` is the system-versioned temporal history table for `Billing.EtoroMoneyTransferBusinessConfiguration`. SQL Server automatically populates it with the previous row version whenever a row in the parent table is updated or deleted. It enables point-in-time fee auditing: "what was the fee for PlayerLevel 3 on a specific past date?"

The table is currently empty (0 rows) - no fee configuration changes have occurred since the current configuration was loaded. This means either the current 29-row configuration represents the initial setup, or any previous configuration predates the SYSTEM_VERSIONING being enabled.

Unlike other temporal history tables in this schema (e.g., History.BillingAftRouting, History.BillingEncryptionKeyManagement), this history table resides in the **Billing** schema rather than the **History** schema - an inconsistency likely reflecting when/how the table was created.

The `Trace` column is stored as `nvarchar(733)` here (the computed column's materialized length), whereas in the parent table it is a non-persisted computed column. This is standard SQL Server temporal behavior: computed columns become stored nvarchar in the history table.

PAGE compression is applied to reduce storage footprint for potentially large history data over time.

---

## 2. Business Logic

No independent business logic. This table is solely populated and queried by SQL Server's temporal versioning engine via the parent table `Billing.EtoroMoneyTransferBusinessConfiguration`.

To query historical data, use the `FOR SYSTEM_TIME` clause on the parent table:
```sql
SELECT * FROM [Billing].[EtoroMoneyTransferBusinessConfiguration] FOR SYSTEM_TIME AS OF '2024-01-01';
```

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 0 |
| History date range | None (empty) |
| Page compression | YES |

---

## 4. Elements

All elements mirror `Billing.EtoroMoneyTransferBusinessConfiguration` exactly, except:

| # | Element | Type | Nullable | Difference from Parent |
|---|---------|------|----------|----------------------|
| 1 | ID | int | NO | Same as parent (no IDENTITY in history) |
| 2 | FlowID | int | NO | Same as parent |
| 3 | PlayerLevelID | int | YES | Same as parent |
| 4 | SourceCurrencyID | int | YES | Same as parent |
| 5 | TargetCurrencyID | int | YES | Same as parent |
| 6 | AssetCurrencyID | int | YES | Same as parent |
| 7 | PercentageFee | decimal(18,2) | NO | Same as parent |
| 8 | Trace | nvarchar(733) | NO | Materialized as nvarchar(733); in parent it is a NOT NULL non-persisted computed column |
| 9 | ValidFrom | datetime2(7) | NO | Row version start time |
| 10 | ValidTo | datetime2(7) | NO | Row version end time (when this version was superseded) |

For full element descriptions, see [Billing.EtoroMoneyTransferBusinessConfiguration](Billing.EtoroMoneyTransferBusinessConfiguration.md).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all IDs) | Same as parent table | Inherited | All implicit FKs from parent are carried into history rows. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.EtoroMoneyTransferBusinessConfiguration | ValidFrom/ValidTo | SYSTEM VERSIONING | Parent table automatically populates this on UPDATE/DELETE via SYSTEM_VERSIONING. |

---

## 6. Dependencies

### 6.0 Dependency Chain

Billing.EtoroMoneyTransferBusinessConfiguration -> Billing.EtoroMoneyTransferBusinessConfigurationHistory (temporal versioning)

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.EtoroMoneyTransferBusinessConfiguration | Table | Parent table - this history table exists solely as its temporal history store |

### 6.2 Objects That Depend On This

None. Not directly queried - accessed through the parent table using `FOR SYSTEM_TIME` syntax.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_EtoroMoneyTransferBusinessConfigurationHistory | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

The (ValidTo, ValidFrom) clustered index is the standard SQL Server pattern for temporal history tables - optimized for point-in-time queries that filter by temporal range.

### 7.2 Constraints

None. History tables have no PK, FK, UNIQUE, DEFAULT, or CHECK constraints.

### 7.3 Storage

PAGE compression applied - reduces storage footprint for historical rows which tend to be append-only and compressible.

---

## 8. Sample Queries

### 8.1 View all historical fee configurations (once history accumulates)

```sql
SELECT ID, FlowID, PlayerLevelID, SourceCurrencyID, TargetCurrencyID,
    PercentageFee, ValidFrom, ValidTo
FROM [Billing].[EtoroMoneyTransferBusinessConfigurationHistory] WITH (NOLOCK)
ORDER BY ValidTo DESC;
```

### 8.2 Point-in-time query via parent table

```sql
-- What were the fees as of a specific date?
SELECT FlowID, PlayerLevelID, SourceCurrencyID, TargetCurrencyID, PercentageFee, ValidFrom
FROM [Billing].[EtoroMoneyTransferBusinessConfiguration]
FOR SYSTEM_TIME AS OF '2024-06-01 00:00:00'
ORDER BY FlowID, PlayerLevelID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.EtoroMoneyTransferBusinessConfigurationHistory | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.EtoroMoneyTransferBusinessConfigurationHistory.sql*
