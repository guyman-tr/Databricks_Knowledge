# History.LiquidityProviders

> SQL Server temporal history table automatically maintained by the database engine, recording every past configuration state of Trade.LiquidityProviders - the registry of individual liquidity provider connection instances used by eToro's hedging engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite: (SysEndTime, SysStartTime) - temporal history clustered index |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

History.LiquidityProviders is the temporal history backing table for Trade.LiquidityProviders. It is automatically populated by SQL Server's SYSTEM_VERSIONING mechanism whenever rows in Trade.LiquidityProviders are updated or deleted.

Trade.LiquidityProviders is the registry of individual liquidity provider (LP) connection instances - the specific broker accounts, trading venues, and market access points that eToro connects to for hedge execution and price feeds. Each row represents one configured connection: a named LP instance (e.g., "FD Provider UAT", "ZBFX3", "Marex OMS") assigned to a provider type (via LiquidityProviderTypeID) with XML-based connection settings.

With 185 history rows, this table is infrequently updated - LP connections are stable configurations that change only during infrastructure changes, deprecations, or new LP onboarding. The data shows two distinct patterns:

1. **Provider deprecation**: A batch of providers (IDs 63-67) were renamed to "Obsolete! Use Hedge Account" in Dec 2025-Feb 2026 by TRAD\danielma and TRAD\dotanva - decommissioning old-style LP connections in favor of the hedge account model.
2. **Configuration changes**: Individual LPs like "ZBFX3" (ID 103) and "Marex OMS" (ID 130) had their settings XML updated as provider configurations evolved.

The `LiquidityProviderSettingsXML` column contains provider-specific connection parameters, mirrors the XML configuration pattern in Trade.LiquidityProviderType.TypeSettingsXML, and allows the hedging engine to instantiate connections at runtime.

---

## 2. Business Logic

### 2.1 LP Instance vs LP Type

**What**: Trade.LiquidityProviders represents specific instances of a connection, while Trade.LiquidityProviderType (archived in History.LiquidityProviderType) defines the technology class/implementation. Many LP instances can share the same LiquidityProviderTypeID (same technology, different accounts).

**Columns/Parameters Involved**: `LiquidityProviderID`, `LiquidityProviderTypeID`, `LiquidityProviderName`, `LiquidityProviderSettingsXML`

**Rules**:
- LiquidityProviderTypeID FK to Trade.LiquidityProviderType (enforced on live table, not in history)
- Multiple LiquidityProviders can have the same LiquidityProviderTypeID (e.g., multiple FD broker accounts all using TypeID=3 "FD")
- LiquidityProviderSettingsXML: instance-specific settings (account credentials, connection endpoints, risk limits) that override or complement the type-level TypeSettingsXML
- LiquidityProviderName is the operational label used in monitoring, reporting, and the Configuration Manager UI

### 2.2 Deprecation Pattern - "Obsolete! Use Hedge Account"

**What**: Legacy LP connections were systematically renamed in late 2025 to signal deprecation, generating history rows capturing their pre-deprecation names and settings.

**Rules**:
- Providers renamed to "Obsolete! Use Hedge Account" are retired LP connections replaced by the hedge account architecture
- The batch deprecation (Dec 2025 - Feb 2026) affected LiquidityProviderIDs 63-67, covering TypeIDs 3 (FD), 7, 40, 69, 10002
- ValidForSec=0 rows (SysStartTime=SysEndTime) indicate a configuration was immediately superseded - the row existed for zero duration before being updated again
- The "Hedge Account" model replaced direct LP connections for many instruments

### 2.3 Computed Identity Capture

**What**: DbLoginName and AppLoginName are computed columns on Trade.LiquidityProviders that capture operator identity at change time. These computed values are stored as snapshots in the history table.

**Rules**:
- DbLoginName = suser_name() on the live table - captured as the domain\username of the SQL session (e.g., "TRAD\danielma", "TRAD\dotanva", "DevTradingSTG")
- AppLoginName = CONVERT(varchar(500), context_info()) on the live table - application context set before DML. NULL in all sampled history rows - Config Manager may not set context_info for LP changes
- Changes made via the Configuration Manager tool use domain accounts (TRAD\*) without application context

---

## 3. Data Overview

185 rows.

| LiquidityProviderID | LiquidityProviderName | LiquidityProviderTypeID | DbLoginName | SysStartTime | SysEndTime | ValidForSec |
|---|---|---|---|---|---|---|
| 67 | Obsolete! Use Hedge Account | 40 | TRAD\dotanva | 2026-02-25 20:07:44 | 2026-02-25 20:07:44 | 0 | Zero-duration history - instantly deprecated |
| 66 | Obsolete! Use Hedge Account | 7 | TRAD\danielma | 2025-12-22 11:24:00 | 2025-12-25 11:35:42 | 259,902 | Valid for ~3 days before further update |
| 103 | ZBFX3 | 69 | TRAD\danielma | 2023-03-08 07:59:15 | 2025-06-19 08:52:00 | ~76M | Active for 2+ years before settings changed |
| 130 | Marex OMS | 84 | TRAD\dotanva | 2024-11-04 13:28:37 | 2024-11-04 13:28:37 | 0 | Instantly updated after creation |
| 35454 | FD Provider UAT | 3 | DevTradingSTG | 2025-08-13 08:33:24 | 2025-08-13 08:33:24 | 0 | STG environment test LP |

Zero-duration history rows (ValidForSec=0) indicate immediate reconfiguration - the provider was created and its settings updated in the same transaction or back-to-back.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderID | int | NO | - | CODE-BACKED | The unique identifier of the liquidity provider instance. Matches Trade.LiquidityProviders.LiquidityProviderID (PK on the live table). Multiple history rows share the same LiquidityProviderID across different time periods as the provider was reconfigured. References the same LP whose settings changed. |
| 2 | LiquidityProviderName | varchar(250) | YES | - | CODE-BACKED | The human-readable name of the LP instance used in operational tooling. Examples: "FD Provider UAT", "ZBFX3", "Marex OMS". Naming convention "Obsolete! Use Hedge Account" signals deprecated LP connections replaced by the hedge account model. Name changes generate new temporal history rows. |
| 3 | LiquidityProviderSettingsXML | xml | YES | - | CODE-BACKED | Instance-specific connection settings in XML format. Mirrors the structure of Trade.LiquidityProviderType.TypeSettingsXML but at the instance level - contains account-specific parameters (endpoints, credentials, risk limits, lot sizes) that override or extend the type-level configuration. NULL for LPs without automated XML configuration. History of this XML tracks how connection settings evolved over time. |
| 4 | LiquidityProviderTypeID | int | YES | - | CODE-BACKED | The technology class of this LP instance. FK to Trade.LiquidityProviderType on the live table (not enforced in history). Multiple LP instances share the same LiquidityProviderTypeID (e.g., multiple FD accounts all using TypeID=3). Values from data: 3=FD, 7, 40=APEX, 69=ZBFX, 84=Marex, 10002=OMS. NULL if the LP is not typed (legacy or decommissioned). |
| 5 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login name that changed this LP configuration. Computed column on Trade.LiquidityProviders (= suser_name()); stored as a snapshot in history. Format: domain\username (e.g., "TRAD\danielma", "TRAD\dotanva") or service account ("DevTradingSTG"). Identifies the operator who made the configuration change. NULL if the session context was unavailable. |
| 6 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level identity from context_info(). Computed column on live table; stored as snapshot in history. NULL in all observed history rows - LP configuration changes appear to be made directly via SQL or Configuration Manager without setting application context. varchar(500) accommodates the "username;ConfigurationManager" pattern seen in other tables. |
| 7 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this LP configuration became current in Trade.LiquidityProviders. Set automatically by SQL Server SYSTEM_VERSIONING. The clustered index (SysEndTime, SysStartTime) supports efficient temporal range queries. |
| 8 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this LP configuration was superseded. For all history rows, always a past timestamp. When SysEndTime = SysStartTime (ValidForSec=0), the LP was reconfigured immediately after the prior update - often seen during complex configuration workflows where settings are applied in rapid succession. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderTypeID | Trade.LiquidityProviderType | Implicit | FK enforced on Trade.LiquidityProviders (not in history). Identifies the provider technology. History in History.LiquidityProviderType. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.LiquidityProviders | SYSTEM_VERSIONING | Writer (automatic) | Live temporal table - SQL Server archives old states here on UPDATE/DELETE |
| History.LiquidityProviderQuantities | LiquidityProviderID | Implicit | Historical quantity limits per LP instance reference the same provider IDs |
| History.LiquidityProviderPriceSource | LiquidityProviderID | Implicit | Historical price source assignments reference provider instances |

---

## 6. Dependencies

```
History.LiquidityProviders (table)
  - No code-level dependencies (temporal history leaf table)
  - Source: Trade.LiquidityProviders (live temporal table, SYSTEM_VERSIONING = ON)
    - Modified by: Configuration Manager tool (TRAD domain accounts)
                  Trading operations (DevTradingSTG in STG)
```

### 6.1 Objects This Depends On

No dependencies. Populated automatically by temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviders | Table | Live temporal table - this is its HISTORY_TABLE |
| History.LiquidityProviderQuantities | Table | Co-dependent temporal history - shares LiquidityProviderID key |
| History.LiquidityProviderPriceSource | Table | Co-dependent temporal history - shares LiquidityProviderID key |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_LiquidityProviders | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression applied. ON [MAIN] filegroup. TEXTIMAGE_ON [MAIN] for xml column.

### 7.2 Constraints

No constraints on history table. Trade.LiquidityProviders live table: CLUSTERED PK on LiquidityProviderID, FK to Trade.LiquidityProviderType on LiquidityProviderTypeID.

---

## 8. Sample Queries

### 8.1 Full configuration change history for a specific LP instance

```sql
SELECT LiquidityProviderID, LiquidityProviderName, LiquidityProviderTypeID,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime,
       DATEDIFF(SECOND, SysStartTime, SysEndTime) AS ValidForSec
FROM [History].[LiquidityProviders] WITH (NOLOCK)
WHERE LiquidityProviderID = 103
UNION ALL
SELECT LiquidityProviderID, LiquidityProviderName, LiquidityProviderTypeID,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime, NULL
FROM [Trade].[LiquidityProviders] WITH (NOLOCK)
WHERE LiquidityProviderID = 103
ORDER BY SysStartTime ASC
```

### 8.2 LP instances at a specific point in time

```sql
SELECT LiquidityProviderID, LiquidityProviderName, LiquidityProviderTypeID
FROM [Trade].[LiquidityProviders]
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
ORDER BY LiquidityProviderID
```

### 8.3 All LP names that have been renamed (changed name detected in history)

```sql
SELECT h1.LiquidityProviderID,
       h1.LiquidityProviderName AS OldName,
       h1.SysEndTime AS ChangedAt,
       h1.DbLoginName AS ChangedBy
FROM [History].[LiquidityProviders] h1 WITH (NOLOCK)
WHERE EXISTS (
    SELECT 1 FROM [History].[LiquidityProviders] h2 WITH (NOLOCK)
    WHERE h2.LiquidityProviderID = h1.LiquidityProviderID
      AND h2.SysStartTime = h1.SysEndTime
      AND h2.LiquidityProviderName <> h1.LiquidityProviderName
)
ORDER BY h1.SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (temporal history - written by Config Manager tool) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.LiquidityProviders | Type: Table | Source: etoro/etoro/History/Tables/History.LiquidityProviders.sql*
