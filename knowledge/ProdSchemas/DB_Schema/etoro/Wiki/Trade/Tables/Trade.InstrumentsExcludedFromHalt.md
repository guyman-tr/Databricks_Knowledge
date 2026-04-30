# Trade.InstrumentsExcludedFromHalt

> Registry of instruments excluded from market halt operations. When the platform halts trading on instruments (e.g., during volatility events or regulatory stops), instruments in this table continue to be tradeable.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) |

---

## 1. Business Meaning

Trade.InstrumentsExcludedFromHalt holds the list of instruments that are exempt from market halt operations. When eToro initiates a trading halt (e.g., extreme volatility, exchange closure, regulatory action), most instruments stop accepting new orders and closes. Instruments listed here are excluded - they remain tradeable during halt events. Typical use cases include major forex pairs (e.g., EUR/USD), system-critical instruments, or instruments where halting would cause operational issues.

This table exists to support selective halt behavior. Without it, halt logic would be all-or-nothing. Operations and risk teams use Trade.InsertInstrumentHalt and Trade.RemoveInstrumentHalt to add or remove instruments. Trade.GetExcludeHaltInstruments returns the current list for paginated consumption by dealing systems and UIs.

Data flow: Trade.InsertInstrumentHalt inserts new InstrumentIDs (from a table-valued parameter) when instruments must be excluded. Trade.RemoveInstrumentHalt deletes by InstrumentID when exclusions are revoked. Trade.GetExcludeHaltInstruments reads the table with pagination. The table is system-versioned (PERIOD FOR SYSTEM_TIME) - all changes are retained in History.InstrumentsExcludedFromHalt for audit and point-in-time queries.

---

## 2. Business Logic

### 2.1 Halting Exclusion

**What**: Presence in this table means the instrument is excluded from market halt operations.

**Columns/Parameters Involved**: `InstrumentID`

**Rules**:
- One row per excluded instrument; InstrumentID is the primary key
- If an instrument is in this table, it is NOT halted when a market halt is triggered
- If an instrument is NOT in this table, it is subject to normal halt logic
- No other columns store business data - InstrumentID alone defines the exclusion

**Diagram**:
```
Market Halt Event
    |
    v
For each instrument: IF NOT EXISTS (SELECT 1 FROM Trade.InstrumentsExcludedFromHalt WHERE InstrumentID = @id)
    THEN apply halt (block orders, etc.)
    ELSE skip (instrument stays tradeable)
```

### 2.2 System Versioning for Audit

**What**: All changes are versioned for compliance and forensics.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- SysStartTime: when the row became effective (INSERT or last update)
- SysEndTime: 9999-12-31 means current; when superseded, set to the modification time
- History.InstrumentsExcludedFromHalt holds superseded rows

---

## 3. Data Overview

| InstrumentID | DbLoginName | AppLoginName | SysStartTime | SysEndTime | Meaning |
|-------------|-------------|--------------|--------------|------------|---------|
| 1 | McpUserRO | null | 2024-05-19 13:11:30 | 9999-12-31 23:59:59 | EUR/USD - most traded forex pair. Excluded so forex liquidity remains available during halt events. |
| 12 | McpUserRO | null | 2024-05-15 12:06:59 | 9999-12-31 23:59:59 | Additional forex or system instrument. Excluded for operational continuity. |
| 1001 | McpUserRO | null | 2024-05-15 12:06:59 | 9999-12-31 23:59:59 | Instrument 1001. Excluded from halt - typical for high-volume or system-critical instruments. |

**Selection criteria for the rows:**
- All 3 current rows included (table has 3 rows total)
- InstrumentID 1 (EUR/USD) is the most significant - major forex always excluded from halt
- 12 and 1001 represent additional excluded instruments

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | PK and FK to Trade.Instrument(InstrumentID). The instrument excluded from market halt operations. Presence in table = excluded. |
| 2 | DbLoginName | varchar(128) | NO | computed | CODE-BACKED | Computed: suser_name(). SQL login that last modified the row. Audit context. |
| 3 | AppLoginName | varchar(500) | NO | computed | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context; often NULL when not set by caller. |
| 4 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning start. When this row became effective. GENERATED ALWAYS AS ROW START. |
| 5 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning end. When this row was superseded. GENERATED ALWAYS AS ROW END. 9999-12-31 means current. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | Each row references a tradeable instrument that is excluded from halt. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertInstrumentHalt | - | Writer | INSERTs new InstrumentIDs when adding exclusions. |
| Trade.RemoveInstrumentHalt | - | Deleter | DELETEs rows when revoking exclusions. |
| Trade.GetExcludeHaltInstruments | - | Reader | SELECTs InstrumentIDs with pagination for dealing systems. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentsExcludedFromHalt (table)
```

Tables have no code-level dependencies. This table is a leaf.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target for InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertInstrumentHalt | Procedure | INSERTs rows |
| Trade.RemoveInstrumentHalt | Procedure | DELETEs rows |
| Trade.GetExcludeHaltInstruments | Procedure | SELECTs with pagination |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InstrumentsExcludedFromHalt | CLUSTERED | InstrumentID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_InstrumentsExcludedFromHalt | PRIMARY KEY | Enforces unique InstrumentID |
| DF_InstrumentsExcludedFromHalt_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_InstrumentsExcludedFromHalt_SysEnd | DEFAULT | SysEndTime = 9999-12-31 23:59:59.9999999 |
| FK_InstrumentExcludedFromHalt_Instrument | FOREIGN KEY | InstrumentID must exist in Trade.Instrument |

### 7.3 Triggers

| Trigger | Action | Meaning |
|---------|--------|---------|
| TRG_T_InstrumentsExcludedFromHalt | FOR INSERT | No-op trigger: UPDATEs same row to same InstrumentID. Likely used to force row version/changelog capture or satisfy a framework requirement. |

---

## 8. Sample Queries

### 8.1 All excluded instruments with names
```sql
SELECT   ieh.InstrumentID,
         i.BuyCurrencyID,
         i.SellCurrencyID,
         ieh.SysStartTime
FROM     Trade.InstrumentsExcludedFromHalt ieh WITH (NOLOCK)
         INNER JOIN Trade.Instrument i WITH (NOLOCK)
           ON i.InstrumentID = ieh.InstrumentID
ORDER BY ieh.InstrumentID;
```

### 8.2 Check if instrument is excluded
```sql
SELECT   CASE WHEN EXISTS (
             SELECT 1
             FROM   Trade.InstrumentsExcludedFromHalt WITH (NOLOCK)
             WHERE  InstrumentID = 1
         ) THEN 1 ELSE 0 END AS IsExcludedFromHalt;
```

### 8.3 Paginated list (matches GetExcludeHaltInstruments pattern)
```sql
DECLARE @pageNumber INT = 1,
        @pageSize   INT = 10,
        @Offset     INT = (@pageNumber - 1) * @pageSize;

SELECT   InstrumentID
FROM     Trade.InstrumentsExcludedFromHalt WITH (NOLOCK)
ORDER BY InstrumentID
OFFSET @Offset ROWS
FETCH NEXT @pageSize ROWS ONLY;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentsExcludedFromHalt | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentsExcludedFromHalt.sql*
