# History.HedgeInstrumentTypeConfiguration

> SQL Server system-versioned temporal history table for Hedge.InstrumentTypeConfiguration, recording every change to the default hedge server assignment per instrument type (asset class).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentTypeID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [PRIMARY] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Hedge.InstrumentTypeConfiguration`. SQL Server's system-versioning manages this table transparently: whenever a row in `Hedge.InstrumentTypeConfiguration` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Hedge.InstrumentTypeConfiguration` is a compact routing table with one row per instrument type (asset class), mapping each type to its default hedge server. When the hedging engine needs to route a new instrument of type Forex, Crypto, Stocks, etc., it looks up the DefaultHedgeServerID for that instrument type to determine which hedge server should handle its positions by default.

The table has only two business columns (InstrumentTypeID and DefaultHedgeServerID) making it a pure routing lookup. It covers up to 10 instrument types: Forex (1), Commodity (2), CFD (3), Indices (4), Stocks (5), ETF (6), Bonds (7), TrustFunds (8), Options (9), Crypto (10).

**Note**: The FK references `Dictionary.CurrencyType(CurrencyTypeID)` - eToro's legacy naming where "CurrencyType" is used for the instrument asset class taxonomy. The column is named `InstrumentTypeID` in the hedging context. The two identifiers reference the same domain.

The INSERT trigger `TRG_T_InstrumentTypeConfiguration` fires a no-op UPDATE to force SQL Server to capture the newly inserted row in temporal history. 0 rows in this environment (table not deployed here).

---

## 2. Business Logic

### 2.1 Default Hedge Server per Instrument Type

**What**: Each instrument type has a designated default hedge server - the routing destination for newly added instruments of that type unless a more specific instrument-level override is configured.

**Columns/Parameters Involved**: `InstrumentTypeID`, `DefaultHedgeServerID`

**Rules**:
- One row per InstrumentTypeID - at most 10 rows (one per instrument asset class)
- FK: InstrumentTypeID -> Dictionary.CurrencyType(CurrencyTypeID): 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto
- FK: DefaultHedgeServerID -> Trade.HedgeServer(HedgeServerID) - the hedge server instance that handles routing for this instrument class
- FILLFACTOR=95 on source PK: near-full pages are appropriate since this is a very small, rarely-written table
- Changes to this configuration (e.g., routing Crypto from HedgeServer A to HedgeServer B) are captured in this history table

### 2.2 INSERT Trigger Capture Pattern

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT trigger `TRG_T_InstrumentTypeConfiguration` fires a no-op UPDATE (SET InstrumentTypeID=InstrumentTypeID) on InstrumentTypeID match to force SQL Server to write the newly inserted row into temporal history
- Zero-duration rows (SysStartTime = SysEndTime) mark INSERT captures
- DbLoginName: suser_name() computed column in source, materialized in history
- AppLoginName: CONVERT(varchar(500), context_info()) computed column in source, materialized in history

---

## 3. Data Overview

| Scale | Value |
|-------|-------|
| Total rows | 0 (dev environment - table not deployed) |
| Maximum rows | ~10 (one per instrument type) |
| Source table | Hedge.InstrumentTypeConfiguration |
| Filegroup | [PRIMARY] |

In production, this is a near-static configuration table. Changes are infrequent (routing changes happen when adding new asset classes or rebalancing hedge server capacity) and each change generates one history row.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | int | NO | - | VERIFIED | The instrument type (asset class) being configured. PK in source. FK to Dictionary.CurrencyType(CurrencyTypeID): 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. Named CurrencyType in the dictionary due to legacy naming conventions. |
| 2 | DefaultHedgeServerID | int | NO | - | CODE-BACKED | The hedge server assigned as the default routing destination for instruments of this type. FK to Trade.HedgeServer(HedgeServerID). Determines which hedging engine instance processes positions for this asset class. |
| 3 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) at time of change. Computed column in source, materialized here. Identifies the service account that updated the routing configuration. |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context from context_info() at time of change. Identifies the operator or service that triggered the routing change. |
| 5 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this instrument type routing version became active. Source DEFAULT=getutcdate(). For INSERT-trigger-captured rows, equals SysEndTime. |
| 6 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. CLUSTERED index leading column. Source DEFAULT='9999-12-31'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentTypeID | Dictionary.CurrencyType | Implicit | Instrument asset class. FK enforced on source as FK_HedgeInstrumentTypeConfiguration_InstrumentTypeID. |
| DefaultHedgeServerID | Trade.HedgeServer | Implicit | Default hedge server for this type. FK enforced on source as FK_HedgeInstrumentTypeConfiguration_DefaultHedgeServerID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InstrumentTypeConfiguration | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here; INSERT trigger captures creations. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HedgeInstrumentTypeConfiguration (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InstrumentTypeConfiguration | Table | Source temporal table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_HedgeInstrumentTypeConfiguration | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, on [PRIMARY] filegroup) |

### 7.2 Constraints

None on history table. Source table has:
- CLUSTERED PK on InstrumentTypeID (FILLFACTOR=95 - near-static small table)
- FK_HedgeInstrumentTypeConfiguration_InstrumentTypeID -> Dictionary.CurrencyType(CurrencyTypeID)
- FK_HedgeInstrumentTypeConfiguration_DefaultHedgeServerID -> Trade.HedgeServer(HedgeServerID)

### 7.3 Notes

- Only 2 data columns - this is a minimal routing table; the history table is correspondingly simple
- Unlike History.HedgeInstrumentConfiguration (which also has AuditHistory triggers for per-column logging), this table has only the temporal INSERT trigger - no separate AuditHistory trigger
- "CurrencyType" naming in the FK is a legacy artifact - this is an instrument type/asset class taxonomy, not a currency type

---

## 8. Sample Queries

### 8.1 Default hedge server routing on a specific date

```sql
SELECT
    itc.InstrumentTypeID,
    ct.Name AS InstrumentTypeName,
    itc.DefaultHedgeServerID,
    hs.Name AS HedgeServerName
FROM Hedge.InstrumentTypeConfiguration FOR SYSTEM_TIME AS OF '2026-01-01T00:00:00' itc WITH (NOLOCK)
JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON ct.CurrencyTypeID = itc.InstrumentTypeID
JOIN Trade.HedgeServer hs WITH (NOLOCK) ON hs.HedgeServerID = itc.DefaultHedgeServerID
ORDER BY itc.InstrumentTypeID;
```

### 8.2 History of hedge server routing changes

```sql
SELECT
    h.InstrumentTypeID,
    ct.Name AS InstrumentTypeName,
    h.DefaultHedgeServerID,
    h.DbLoginName AS ChangedBy,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil
FROM History.HedgeInstrumentTypeConfiguration h WITH (NOLOCK)
JOIN Dictionary.CurrencyType ct WITH (NOLOCK) ON ct.CurrencyTypeID = h.InstrumentTypeID
WHERE DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.InstrumentTypeID, h.SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.HedgeInstrumentTypeConfiguration | Type: Table | Source: etoro/etoro/History/Tables/History.HedgeInstrumentTypeConfiguration.sql*
