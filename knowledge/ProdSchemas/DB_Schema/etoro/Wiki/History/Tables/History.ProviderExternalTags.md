# History.ProviderExternalTags

> Temporal history backing table for Hedge.ProviderExternalTags - storing all past versions of the external tag assignments that map liquidity provider accounts to tag values sent with orders to external execution systems.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (SysEndTime, SysStartTime) |
| **Partition** | No (ON [DICTIONARY] filegroup) |
| **Indexes** | 1 (1 clustered temporal) |

---

## 1. Business Meaning

`History.ProviderExternalTags` is the **temporal history backing table** for `Hedge.ProviderExternalTags`. SQL Server's system-versioned temporal tables automatically move old rows here whenever the live table is updated or deleted. This table is never written to directly.

The live table `Hedge.ProviderExternalTags` defines static and dynamic tags sent with orders to external liquidity providers/execution systems. When eToro sends a hedge order to a prime broker or ECN, these tags are included as order metadata that the external system uses for routing, attribution, compliance, or account identification.

Two types of tag modes are supported:
- **Static**: a fixed literal value (e.g., "ETORO", "MNGDFTE") is sent as the tag value
- **Dynamic**: a template value (e.g., "{CID}") is resolved at runtime to the actual customer or account ID

With 76 history rows spanning multiple provider types and liquidity accounts, this table reflects active configuration of how eToro identifies itself and its customers to external execution venues.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Table - Automatic Versioning

**What**: Every change to Hedge.ProviderExternalTags automatically writes the previous version here.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- `SysStartTime` = UTC timestamp when this tag assignment became active
- `SysEndTime` = UTC timestamp when this assignment was superseded
- Composite PK on live table: (ProviderTypeID, TagID, LiquidityAccountID, Mode) - allows the same tag to exist in both Static and Dynamic mode simultaneously

### 2.2 Static vs Dynamic Tag Mode

**What**: Tags can carry fixed values (Static) or templated values resolved at order time (Dynamic).

**Columns/Parameters Involved**: `Mode`, `TagValue`

**Rules**:
- `Mode = 'Static'` (DEFAULT): TagValue is sent exactly as stored (e.g., "ETORO", "MNGDFTE", "ranlev")
- `Mode = 'Dynamic'`: TagValue is a template with placeholders resolved at runtime (e.g., "{CID}" resolves to the customer ID)
- Same (ProviderTypeID, TagID, LiquidityAccountID) can have BOTH Static and Dynamic rows - the mode is part of the PK
- From live data: ProviderTypeID=10002, TagID=10115, LiquidityAccountID=2150 has both Static ("ranlev") and Dynamic ("{CID}") rows
- LiquidityAccountID DEFAULT=0 means the tag applies to the default/global account for that provider type

### 2.3 Provider Account Scoping

**What**: Each tag assignment is scoped to a specific liquidity account within a provider type.

**Columns/Parameters Involved**: `ProviderTypeID`, `LiquidityAccountID`, `TagID`

**Rules**:
- Different liquidity accounts (LiquidityAccountIDs) at the same provider type can have different tag values
- TagID identifies the semantic purpose of the tag in the external system (e.g., TagID=100="account identifier", TagID=10001="firm code", TagID=10115="trader ID")
- From live data: TagValue "ETORO" suggests TagID=10001 is a firm identifier; "{CID}" suggests TagID=10115 is a customer reference

---

## 3. Data Overview

76 rows. Multiple provider types. Both Static and Dynamic modes present. Most recent change: 2026-02-25.

| ProviderTypeID | TagID | TagValue | LiquidityAccountID | Mode | SysEndTime | Context |
|---|---|---|---|---|---|---|
| 40 | 100 | MNGDFTE | 14 | Static | 2026-02-25 | Provider 40, Account 14: static firm/desk code |
| 10002 | 10115 | ranlev | 2150 | Static | 2026-02-25 | Provider 10002, Account 2150: static trader ID |
| 10002 | 10115 | {CID} | 2150 | Dynamic | 2026-02-25 | Same provider/account: dynamic customer ID template |
| 10002 | 10001 | ETORO | 2152 | Static | 2026-02-25 | Provider 10002, Account 2152: static firm code "ETORO" |
| 10002 | 10001 | {CID} | 2152 | Dynamic | 2026-02-25 | Same provider/account: dynamic customer template |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderTypeID | int | NO | - | VERIFIED | The liquidity provider type these tags are configured for. Part of the composite PK on the live table. Identifies the external execution venue (prime broker, ECN, etc.). Observed values: 40 and 10002. |
| 2 | TagID | int | NO | - | VERIFIED | The external tag type identifier. Part of the composite PK. Defines the semantic meaning of the tag in the external system (e.g., account code, firm identifier, trader reference). Observed values: 100, 10001, 10115. |
| 3 | TagValue | varchar(500) | NO | - | VERIFIED | The value to send for this tag. For Static mode: a literal string (e.g., "ETORO", "MNGDFTE", "ranlev"). For Dynamic mode: a template with {PLACEHOLDER} syntax resolved at order execution time (e.g., "{CID}" = customer ID). |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL login captured via suser_name() at write time on the live table. Identifies who modified the tag configuration. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application identity from context_info() at write time. May contain null-byte padding from varchar(500) context_info() storage. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this tag assignment became active. Set by SQL Server temporal engine. Starting boundary of validity period (inclusive). |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this assignment was superseded. Set by SQL Server temporal engine. Ending boundary (exclusive). Clustered index leading column. |
| 8 | LiquidityAccountID | int | NO | DEFAULT 0 | CODE-BACKED | The specific liquidity account (sub-account) within the provider type. DEFAULT 0 = applies to the default/global account for this provider type. When non-zero, scopes the tag to a specific trading account. Part of composite PK on live table. |
| 9 | Mode | varchar(10) | NO | DEFAULT 'Static' | VERIFIED | Tag resolution mode. 'Static': TagValue is sent as-is. 'Dynamic': TagValue is a template (e.g., "{CID}") resolved at runtime. Part of composite PK - same (ProviderTypeID, TagID, LiquidityAccountID) can have both Static and Dynamic rows simultaneously. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderTypeID | Trade.LiquidityProviderType | Implicit | The liquidity provider type these tags apply to |
| (all columns) | Hedge.ProviderExternalTags | Temporal | This is the history backing table for the live Hedge table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server temporal engine | (auto) | System | Rows moved here automatically when Hedge.ProviderExternalTags is modified |
| Hedge.Tr_T_ProviderExternalTags_INSERT | Trigger | Related | No-op touch trigger on live table that forces temporal versioning on INSERT |
| Hedge.GetProviderExternalTags | Stored Procedure | READER | Reads live table to retrieve tag assignments for order construction |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ProviderExternalTags (table)
(temporal history backing table - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies. Written entirely by SQL Server temporal table engine.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ProviderExternalTags | Table | Live table - SQL Server moves expired rows here automatically |
| Hedge.GetProviderExternalTags | Stored Procedure | Reads live table to get tag assignments for outbound orders |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ProviderExternalTags | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

*DATA_COMPRESSION=PAGE. ON [DICTIONARY] filegroup. Standard temporal history clustering.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_HistoryLiquidityAccountID | DEFAULT | `0` on LiquidityAccountID |
| CK_ProviderExternalTags_Mode | DEFAULT | `'Static'` on Mode |

---

## 8. Sample Queries

### 8.1 Full change history for a specific provider type and tag

```sql
SELECT ProviderTypeID, TagID, TagValue, LiquidityAccountID, Mode,
    DbLoginName, SysStartTime, SysEndTime
FROM History.ProviderExternalTags WITH (NOLOCK)
WHERE ProviderTypeID = @ProviderTypeID AND TagID = @TagID
ORDER BY SysStartTime ASC
```

### 8.2 Point-in-time tag configuration (via live table)

```sql
SELECT ProviderTypeID, TagID, TagValue, LiquidityAccountID, Mode
FROM Hedge.ProviderExternalTags
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
WHERE ProviderTypeID = @ProviderTypeID
```

### 8.3 Recent tag changes across all providers

```sql
SELECT ProviderTypeID, TagID, TagValue, LiquidityAccountID, Mode,
    DbLoginName, SysStartTime, SysEndTime
FROM History.ProviderExternalTags WITH (NOLOCK)
WHERE SysEndTime >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ProviderExternalTags | Type: Table | Source: etoro/etoro/History/Tables/History.ProviderExternalTags.sql*
