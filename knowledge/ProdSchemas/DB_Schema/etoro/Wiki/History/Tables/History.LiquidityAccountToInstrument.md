# History.LiquidityAccountToInstrument

> SQL Server temporal history table storing prior row versions of Price.LiquidityAccountToInstrument, capturing the full history of which instruments were routed through which liquidity accounts for price feed reception.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.LiquidityAccountToInstrument is the SQL Server system-versioning history table for Price.LiquidityAccountToInstrument. It is declared as `HISTORY_TABLE = [History].[LiquidityAccountToInstrument]` in the Price.LiquidityAccountToInstrument DDL. Whenever a row in Price.LiquidityAccountToInstrument is updated or deleted, the prior version is automatically written here.

Price.LiquidityAccountToInstrument is the routing table that maps specific financial instruments to the liquidity accounts (Trade.LiquidityAccounts) from which they receive price feed data. Each row means: "this instrument's prices are sourced from this liquidity account." When an instrument is onboarded or its price source changes, this mapping is updated, generating a history record in this table.

The active table (Price.LiquidityAccountToInstrument) has an INSERT trigger (TRG_T_LiquidityAccountToInstrument) that performs a no-op UPDATE on newly inserted rows, forcing SQL Server temporal versioning to generate an immediate INSERT artifact history row with SysStartTime = SysEndTime. The table currently holds 16,495 rows. The HostName column captures which pricing server (e.g., "STG-PRICE-WE01") processed each change, providing infrastructure-level provenance for routing decisions.

The active table also has Audit triggers (AuditInsert/Update/Delete) writing field-by-field changes to History.AuditHistory, providing dual audit coverage alongside temporal versioning.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Versioning Mechanics

**What**: SQL Server writes superseded row versions from Price.LiquidityAccountToInstrument into this table on every UPDATE or DELETE.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `LiquidityAccountID`, `InstrumentID`

**Rules**:
- INSERT trigger (TRG_T_LiquidityAccountToInstrument) forces immediate history on every INSERT - generates zero-duration INSERT artifact rows (SysStartTime = SysEndTime)
- 16,495 history rows vs a relatively small active table: suggests frequent instrument routing changes and many INSERT artifacts
- PK of active table is (LiquidityAccountID, InstrumentID) - one routing row per account-instrument pair

**Diagram**:
```
Price.LiquidityAccountToInstrument INSERT (new routing):
  Trigger fires -> no-op UPDATE -> SysVersioning closes & reopens immediately
  HistoryLiquidityAccountToInstrument row: SysStart = SysEnd = insert_time (artifact)

Price.LiquidityAccountToInstrument UPDATE/DELETE (routing change):
  Old version -> HistoryLiquidityAccountToInstrument: SysStart < SysEnd
```

### 2.2 Pricing Infrastructure Provenance

**What**: HostName captures which server instance executed each INSERT or UPDATE, providing infrastructure-level traceability.

**Columns/Parameters Involved**: `HostName`

**Rules**:
- HostName is a computed column AS host_name() in the active table - captured at write time
- Stored as a regular nullable column in this history table (materialized from computed)
- All observed rows: HostName = "STG-PRICE-WE01" - writes come from the staging pricing server
- Different host names in different environments indicate which pricing service instances are managing routing

---

## 3. Data Overview

16,495 rows total. Most recent changes observed:

| LiquidityAccountID | InstrumentID | HostName | SysStartTime | SysEndTime | Meaning |
|-------------------|-------------|---------|-------------|------------|---------|
| 7 | 100063 | STG-PRICE-WE01 | 2026-02-04 | 2026-02-04 | INSERT artifact - instrument 100063 was newly routed to account 7 on Feb 4 2026 |
| 102 | 3138 | STG-PRICE-WE01 | 2026-01-18 | 2026-01-18 | INSERT artifact - instrument 3138 newly routed to account 102 on Jan 18 2026 |
| 7 | 1234 | STG-PRICE-WE01 | 2026-01-15 | 2026-01-15 | INSERT artifact for account 7 / instrument 1234 routing setup |

All observed history rows have SysStartTime = SysEndTime = INSERT artifacts from TRG_T_LiquidityAccountToInstrument. Genuine update/delete history would show SysStartTime < SysEndTime.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | VERIFIED | ID of the liquidity account that sources prices for this instrument. Implicit FK to Trade.LiquidityAccounts. Mirrors the FK_LATI_LiquidityAccountID constraint in the active table. See History.LiquidityAccounts for account history. |
| 2 | InstrumentID | int | NO | - | VERIFIED | Financial instrument ID being routed to this liquidity account for pricing. Implicit FK to Trade.Instrument. Mirrors the FK_LATI_InstrumentID constraint in the active table. |
| 3 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | Materialized SQL Server login name (suser_name()) at the time this row version was closed. In active table this is computed; stored here as a snapshot. |
| 4 | AppLoginName | varchar(500) | YES | - | VERIFIED | Materialized application identity (context_info()) at version close time. NULL if not set by the writing application. |
| 5 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Start of the validity window for this history row. For INSERT artifacts: equals SysEndTime. For genuine state changes: the timestamp when that routing configuration became current. |
| 6 | SysEndTime | datetime2(7) | NO | - | VERIFIED | End of the validity window for this history row. Set to the UTC time when the routing was updated or removed. CLUSTERED INDEX leads with SysEndTime for optimal temporal query performance. |
| 7 | HostName | nvarchar(128) | YES | - | CODE-BACKED | Server hostname that executed the write that generated this history row. Computed AS host_name() in the active table; materialized as a stored string here. Observed value: "STG-PRICE-WE01" (staging pricing server). NULL if not evaluable at version-close time. Provides infrastructure provenance for routing decisions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | Implicit | The liquidity account this instrument was routed to for pricing. FK mirrors FK_LATI_LiquidityAccountID. See History.LiquidityAccounts for account configuration history. |
| InstrumentID | Trade.Instrument | Implicit | The financial instrument being routed. FK mirrors FK_LATI_InstrumentID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.LiquidityAccountToInstrument | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | Declares this as its HISTORY_TABLE. All closed row versions flow here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LiquidityAccountToInstrument (table)
  - leaf node: no code-level dependencies
  - auto-populated by SQL Server from: Price.LiquidityAccountToInstrument (temporal parent)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.LiquidityAccountToInstrument | Table | Declares this as its HISTORY_TABLE for SYSTEM_VERSIONING. All temporal version rows flow here. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_LiquidityAccountToInstrument | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

DATA_COMPRESSION=PAGE on [PRIMARY] filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION=PAGE | Storage option | Page-level compression applied to all data and index pages. |

No explicit FKs or check constraints. Integrity maintained through SYSTEM_VERSIONING contract with Price.LiquidityAccountToInstrument.

---

## 8. Sample Queries

### 8.1 View full routing history for a specific instrument
```sql
SELECT LiquidityAccountID, InstrumentID, HostName, SysStartTime, SysEndTime,
       CASE WHEN SysStartTime = SysEndTime THEN 'INSERT artifact' ELSE 'Genuine change' END AS VersionType
FROM History.LiquidityAccountToInstrument WITH (NOLOCK)
WHERE InstrumentID = 1234
ORDER BY SysStartTime;
```

### 8.2 Use FOR SYSTEM_TIME ALL to see complete routing history via active table
```sql
SELECT LiquidityAccountID, InstrumentID, SysStartTime, SysEndTime
FROM Price.LiquidityAccountToInstrument WITH (NOLOCK)
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 1234
ORDER BY SysStartTime;
```

### 8.3 Find instruments that changed their liquidity account routing (genuine updates)
```sql
SELECT h.InstrumentID, h.LiquidityAccountID AS OldAccountID,
       lati.LiquidityAccountID AS CurrentAccountID, h.SysEndTime AS ChangedAt
FROM History.LiquidityAccountToInstrument h WITH (NOLOCK)
JOIN Price.LiquidityAccountToInstrument lati WITH (NOLOCK) ON h.InstrumentID = lati.InstrumentID
WHERE h.LiquidityAccountID <> lati.LiquidityAccountID
  AND h.SysStartTime <> h.SysEndTime  -- exclude INSERT artifacts
ORDER BY h.SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 INSERT trigger + 3 audit triggers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.LiquidityAccountToInstrument | Type: Table | Source: etoro/etoro/History/Tables/History.LiquidityAccountToInstrument.sql*
