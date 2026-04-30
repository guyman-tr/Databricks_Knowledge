# History.ProviderMarginMarkupByInstrument

> Temporal history backing table for Trade.ProviderMarginMarkupByInstrument - storing all past versions of the per-instrument margin markup percentage applied to specific liquidity providers.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (SysEndTime, SysStartTime) |
| **Partition** | No (ON [PRIMARY] filegroup) |
| **Indexes** | 1 (1 clustered temporal) |

---

## 1. Business Meaning

`History.ProviderMarginMarkupByInstrument` is the **temporal history backing table** for `Trade.ProviderMarginMarkupByInstrument`. SQL Server's system-versioned temporal tables automatically move old rows here whenever the live table is updated or deleted. This table is never written to directly.

The live table `Trade.ProviderMarginMarkupByInstrument` stores an additional margin markup percentage applied on top of the base margin requirement for specific instrument-provider combinations. This allows the trading platform to impose different margin requirements depending on which liquidity provider is currently servicing an instrument - for example, if a provider is less liquid or carries higher hedging costs, a higher markup is applied.

With only 20 history rows, this is a rarely-changed configuration. All observed rows show `MarkupPercentage=10` (10% markup) and `DbLoginName=OpsFlowAPI`, indicating these changes are made through an operations API rather than direct SQL access. The composite PK on the live table is `(InstrumentID, ProviderID)`, providing one markup rate per instrument per provider.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Table - Automatic Versioning

**What**: Every change to Trade.ProviderMarginMarkupByInstrument automatically writes the previous version here.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- `SysStartTime` = UTC when this markup became active
- `SysEndTime` = UTC when this markup was superseded
- Composite PK on live table: (InstrumentID, ProviderID)

### 2.2 Margin Markup Application

**What**: The MarkupPercentage is added to the base margin requirement for this instrument when routed through this provider.

**Columns/Parameters Involved**: `InstrumentID`, `ProviderID`, `MarkupPercentage`

**Rules**:
- `MarkupPercentage` (decimal 10,2): percentage points added to the base margin
- Observed value: 10 (10% markup)
- Changes are made via OpsFlowAPI, suggesting this is managed through an operations workflow tool
- A 10% markup means: if base margin is 5%, effective margin becomes 5% + 10% additional of base = varies by calculation

---

## 3. Data Overview

20 rows. MarkupPercentage consistently 10 in observed data. Written by OpsFlowAPI.

| InstrumentID | ProviderID | MarkupPercentage | DbLoginName | SysStartTime | SysEndTime |
|---|---|---|---|---|---|
| 204013 | 99 | 10 | OpsFlowAPI | 2026-02-03 15:37:32 | 2026-02-03 15:37:32 |
| 203004 | 99 | 10 | OpsFlowAPI | 2026-02-03 15:36:55 | 2026-02-03 15:36:55 |
| 200007 | 99 | 10 | OpsFlowAPI | 2026-02-03 15:32:55 | 2026-02-03 15:32:55 |

*ProviderID=99 with high InstrumentIDs (200000+) suggesting this is applied to newer instruments on a specific provider. SysStartTime = SysEndTime: very short-lived configurations that were immediately superseded.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument to which this markup applies. Part of the composite PK (InstrumentID, ProviderID) in the live Trade.ProviderMarginMarkupByInstrument table. |
| 2 | ProviderID | int | NO | - | CODE-BACKED | The liquidity provider to which this markup applies. Part of the composite PK. Observed value: 99. When eToro routes a position in InstrumentID through this ProviderID, the margin markup is applied. |
| 3 | MarkupPercentage | decimal(10,2) | NO | - | VERIFIED | Additional margin percentage applied on top of the base margin requirement. Observed value: 10 (10%). Provides per-provider, per-instrument margin adjustment to account for provider-specific liquidity or hedging cost differences. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL login or service account that modified the live table. Observed value: "OpsFlowAPI" - an operations workflow API service, indicating changes are made through an operations management tool rather than direct DBA access. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application identity from context_info() at write time. May contain null-byte padding from varchar(500) context_info() storage. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this markup configuration became active. Set by SQL Server temporal engine. Starting boundary of validity period (inclusive). |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this markup was superseded. Set by SQL Server temporal engine. Ending boundary (exclusive). Clustered index leading column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Instrument lookup | Implicit (FK on live table) | The instrument this margin markup applies to |
| ProviderID | Provider lookup | Implicit (FK on live table) | The liquidity provider this markup applies to |
| (all columns) | Trade.ProviderMarginMarkupByInstrument | Temporal | This is the history backing table for the live Trade table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server temporal engine | (auto) | System | Rows moved here automatically when Trade.ProviderMarginMarkupByInstrument is modified |
| Trade.UpsertProviderMarginMarkupByInstrument | Stored Procedure | WRITER (via live table) | UPSERT operation that creates or updates margin markup configurations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ProviderMarginMarkupByInstrument (table)
(temporal history backing table - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies. Written entirely by SQL Server temporal table engine.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderMarginMarkupByInstrument | Table | Live table - SQL Server moves expired rows here automatically |
| Trade.UpsertProviderMarginMarkupByInstrument | Stored Procedure | Creates/updates markup configurations on live table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_ProviderMarginMarkupByInstrument | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

*DATA_COMPRESSION=PAGE. Standard temporal history clustering pattern.*

### 7.2 Constraints

None (FK/PK constraints enforced on live Trade.ProviderMarginMarkupByInstrument table).

---

## 8. Sample Queries

### 8.1 Point-in-time markup configuration (via live table)

```sql
SELECT InstrumentID, ProviderID, MarkupPercentage, DbLoginName, SysStartTime, SysEndTime
FROM Trade.ProviderMarginMarkupByInstrument
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
WHERE InstrumentID = @InstrumentID
```

### 8.2 Full markup history for a specific instrument-provider pair

```sql
SELECT InstrumentID, ProviderID, MarkupPercentage, DbLoginName, SysStartTime, SysEndTime
FROM History.ProviderMarginMarkupByInstrument WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID AND ProviderID = @ProviderID
ORDER BY SysStartTime ASC
```

### 8.3 Recent markup changes

```sql
SELECT InstrumentID, ProviderID, MarkupPercentage, DbLoginName, SysStartTime, SysEndTime
FROM History.ProviderMarginMarkupByInstrument WITH (NOLOCK)
WHERE SysEndTime >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ProviderMarginMarkupByInstrument | Type: Table | Source: etoro/etoro/History/Tables/History.ProviderMarginMarkupByInstrument.sql*
