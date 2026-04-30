# History.ShadowHedgeServerConfiguration

> System-versioned temporal history table for CEP.ShadowHedgeServerConfiguration, recording all past states of shadow hedge server configuration - the routing rules that mirror a fraction of hedge orders from a source hedge server to a shadow (test/comparison) hedge server.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (SysEndTime, SysStartTime) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

This table is the **active system-versioned temporal history table** for `CEP.ShadowHedgeServerConfiguration` (source declares `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[ShadowHedgeServerConfiguration])`). SQL Server automatically archives superseded rows here when shadow hedge server configurations are changed.

`CEP.ShadowHedgeServerConfiguration` controls **shadow hedging** - a mode where the CEP engine mirrors a subset of hedge orders from a real (source) hedge server to a shadow (test or comparison) hedge server. Each row defines: which real hedge server is being shadowed (`SourceHedgeServerID`), which shadow hedge server receives the mirrored orders (`ShadowHedgeServerID`), the sampling fraction (`Modulo`), and the maximum position tree size allowed on the shadow server (`MaxTreeSizeUSD`).

Shadow hedging is used for A/B testing hedge server configurations, validating new hedge servers before full deployment, or comparing execution quality between hedge servers without real risk.

Both the source table and history table currently have 0 rows. No shadow hedging configurations are active or have been historically recorded in this environment. The table structure is part of the CEP hedging infrastructure alongside `CEP.Rules` and `CEP.ShadowHedgeServerConfiguration`.

Note: `TRG_T_ShadowHedgeServerConfiguration` performs a no-op self-update on INSERT (same pattern as other CEP tables) to ensure consistent temporal registration.

---

## 2. Business Logic

### 2.1 Shadow Hedge Order Mirroring

**What**: Defines which fraction of hedge orders from a source server are mirrored to a shadow server.

**Columns/Parameters Involved**: `SourceHedgeServerID`, `ShadowHedgeServerID`, `Modulo`, `MaxTreeSizeUSD`

**Rules**:
- One row per SourceHedgeServerID (PK) - each real hedge server can have at most one shadow
- `Modulo` controls the sampling rate: only every Nth order (order_sequence % Modulo == 0) is mirrored to the shadow server. Modulo=1 would mirror all orders; Modulo=10 would mirror every 10th order
- `MaxTreeSizeUSD` caps the maximum total position tree value (in USD) that can accumulate on the shadow server - a risk safety limit
- Both SourceHedgeServerID and ShadowHedgeServerID are FKs to `Trade.HedgeServer` - only valid, configured hedge servers can participate

**Diagram**:
```
CEP Shadow Hedge Flow:
  Real hedge order arrives at SourceHedgeServer
  |
  IF order_sequence % Modulo == 0
    AND shadow tree size < MaxTreeSizeUSD
    -> Mirror order to ShadowHedgeServer
  ELSE
    -> Normal execution only (no shadow)
```

---

## 3. Data Overview

Both the source table (`CEP.ShadowHedgeServerConfiguration`) and history table (`History.ShadowHedgeServerConfiguration`) have 0 rows. No shadow hedging configurations are active in this environment.

| SourceHedgeServerID | ShadowHedgeServerID | Modulo | MaxTreeSizeUSD | Meaning |
|---|---|---|---|---|
| (no rows) | - | - | - | No shadow hedge configurations active |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SourceHedgeServerID | int | NO | - | CODE-BACKED | The real (production) hedge server whose orders are being shadowed. PK in the source table. FK to Trade.HedgeServer(HedgeServerID). Each source server can have at most one shadow configuration. |
| 2 | ShadowHedgeServerID | int | NO | - | CODE-BACKED | The shadow (test/comparison) hedge server that receives mirrored orders. FK to Trade.HedgeServer(HedgeServerID). Receives a sampled fraction of orders from the source server for comparison purposes. |
| 3 | Modulo | int | NO | - | NAME-INFERRED | Sampling rate divisor for shadow order mirroring. The CEP engine mirrors an order when (order_sequence % Modulo == 0). Modulo=1 mirrors all orders; higher values reduce the shadow load. Controls the trade-off between shadow fidelity and shadow server load. |
| 4 | MaxTreeSizeUSD | int | NO | - | NAME-INFERRED | Maximum total USD value of the position tree that can accumulate on the shadow hedge server. Acts as a risk safety ceiling: if the shadow server's position tree exceeds this value, mirroring stops. Prevents the shadow server from accumulating excessive synthetic exposure. |
| 5 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Computed in source as `suser_name()` - SQL Server login that last modified this shadow configuration. Stored as a plain value in history. |
| 6 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Computed in source as `CONVERT(varchar(500), context_info())` - application-set session context at time of change. NULL when context_info() was not set. |
| 7 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC instant when this shadow configuration became current in `CEP.ShadowHedgeServerConfiguration`. Automatically managed by SQL Server temporal system versioning. |
| 8 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC instant when this shadow configuration was superseded. Automatically set by SQL Server. Leading key of the clustered index. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SourceHedgeServerID | CEP.ShadowHedgeServerConfiguration | Temporal History | Each row is a past state of the source configuration; SourceHedgeServerID identifies which source hedge server. |
| SourceHedgeServerID | Trade.HedgeServer | Implicit (FK on source) | The real hedge server being shadowed. |
| ShadowHedgeServerID | Trade.HedgeServer | Implicit (FK on source) | The shadow hedge server receiving mirrored orders. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.ShadowHedgeServerConfiguration | HISTORY_TABLE | Temporal History | Active source table; SQL Server archives expired rows here. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ShadowHedgeServerConfiguration (table)
  (temporal history - no code-level dependencies; populated by SQL Server from CEP.ShadowHedgeServerConfiguration)
```

---

### 6.1 Objects This Depends On

No dependencies. Temporal history table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.ShadowHedgeServerConfiguration | Table | Active source table; expired rows archived here automatically. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ShadowHedgeServerConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE on both table and clustered index.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page compression for archival data. |

---

## 8. Sample Queries

### 8.1 View all past shadow hedge configuration changes
```sql
SELECT
    SourceHedgeServerID,
    ShadowHedgeServerID,
    Modulo,
    MaxTreeSizeUSD,
    DbLoginName,
    SysStartTime AS ValidFrom,
    SysEndTime AS ValidTo,
    DATEDIFF(minute, SysStartTime, SysEndTime) AS DurationMinutes
FROM [History].[ShadowHedgeServerConfiguration] WITH (NOLOCK)
ORDER BY SysEndTime DESC
```

### 8.2 Point-in-time shadow configuration
```sql
SELECT SourceHedgeServerID, ShadowHedgeServerID, Modulo, MaxTreeSizeUSD
FROM [CEP].[ShadowHedgeServerConfiguration]
FOR SYSTEM_TIME AS OF @PointInTime
ORDER BY SourceHedgeServerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 7.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ShadowHedgeServerConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.ShadowHedgeServerConfiguration.sql*
