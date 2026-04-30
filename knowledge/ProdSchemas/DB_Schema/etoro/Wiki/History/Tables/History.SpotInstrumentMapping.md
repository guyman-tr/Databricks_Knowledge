# History.SpotInstrumentMapping

> System-versioned temporal history table for Price.SpotInstrumentMapping, recording all past states of the mapping between commodity/futures instruments and their spot and forward liquidity accounts and related instrument chain.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (SysEndTime, SysStartTime) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

This table is the **active system-versioned temporal history table** for `Price.SpotInstrumentMapping` (source declares `SYSTEM_VERSIONING = ON (HISTORY_TABLE = [History].[SpotInstrumentMapping])`). SQL Server automatically archives superseded rows here when spot instrument mappings are changed.

`Price.SpotInstrumentMapping` configures the relationship between an instrument and its liquidity accounts and related future/next instruments for **futures/commodity pricing**. The mapping defines: which liquidity account provides spot prices (`SpotLiquidityAccountID`), which provides futures prices (`FutureLiquidityAccountID`), and which instruments represent the next two contract expirations (`FirstNextInstrumentId`, `SecondNextInstrumentId`). This is used in the Price service to compute spot prices from futures contracts using a roll mechanism.

Both the source table (`Price.SpotInstrumentMapping`) and history table (`History.SpotInstrumentMapping`) currently have 0 rows. The spot instrument mapping configuration is not populated in this environment.

The table is stored on the `[MAIN]` filegroup. Source FKs: InstrumentID -> Trade.Instrument, SpotLiquidityAccountID -> Trade.LiquidityAccounts, FutureLiquidityAccountID -> Trade.LiquidityAccounts.

---

## 2. Business Logic

### 2.1 Spot-to-Futures Instrument Chain

**What**: Maps a commodity/futures instrument to its spot and futures liquidity accounts and the next contract instruments in the roll chain.

**Columns/Parameters Involved**: `InstrumentID`, `SpotLiquidityAccountID`, `FutureLiquidityAccountID`, `FirstNextInstrumentId`, `SecondNextInstrumentId`

**Rules**:
- PK in source: (InstrumentID, SpotLiquidityAccountID) - one instrument can have multiple spot account mappings
- `FirstNextInstrumentId` and `SecondNextInstrumentId` define the futures roll chain: when the current contract expires, pricing rolls to the FirstNext, then SecondNext
- Both SpotLiquidityAccountID and FutureLiquidityAccountID are FKs to Trade.LiquidityAccounts - validated liquidity accounts must exist
- The Price service uses this mapping to compute synthetic spot prices from futures contract data

---

## 3. Data Overview

Both source (`Price.SpotInstrumentMapping`) and history (`History.SpotInstrumentMapping`) have 0 rows. Not configured in this environment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The instrument this spot mapping applies to. Composite PK with SpotLiquidityAccountID. FK to Trade.Instrument. For commodity/futures instruments that have a spot pricing chain. |
| 2 | SpotLiquidityAccountID | int | NO | - | CODE-BACKED | The liquidity account that provides spot price data for this instrument. Composite PK member. FK to Trade.LiquidityAccounts. Used by the Price service as the spot price source. |
| 3 | FutureLiquidityAccountID | int | NO | - | CODE-BACKED | The liquidity account providing futures price data. FK to Trade.LiquidityAccounts. Used alongside SpotLiquidityAccountID to compute the basis (spot-futures spread) and roll costs. |
| 4 | FirstNextInstrumentId | int | NO | - | NAME-INFERRED | The instrument representing the first next futures contract expiration. When the current front-month contract expires, pricing rolls to this instrument. Forms part of the futures roll chain. |
| 5 | SecondNextInstrumentId | int | NO | - | NAME-INFERRED | The instrument representing the second next futures contract expiration. Used after FirstNextInstrumentId expires. Enables pre-computation of roll costs for two expiration cycles ahead. |
| 6 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Computed in source as `suser_name()` - SQL Server login that modified this mapping. Stored as plain value in history. |
| 7 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Computed in source as `CONVERT(varchar(500), context_info())` - application context at time of change. |
| 8 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC instant when this mapping became current. Automatically managed by SQL Server temporal versioning. |
| 9 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC instant when this mapping was superseded. Automatically set by SQL Server. Leading key of clustered index. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Price.SpotInstrumentMapping | Temporal History | Each row is a past state of the source mapping identified by InstrumentID + SpotLiquidityAccountID. |
| InstrumentID | Trade.Instrument | Implicit (FK on source) | The instrument being mapped. |
| SpotLiquidityAccountID | Trade.LiquidityAccounts | Implicit (FK on source) | Spot price liquidity account. |
| FutureLiquidityAccountID | Trade.LiquidityAccounts | Implicit (FK on source) | Futures price liquidity account. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.SpotInstrumentMapping | HISTORY_TABLE | Temporal History | Active source table; SQL Server archives expired rows here. |

---

## 6. Dependencies

No dependencies. Temporal history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_SpotInstrumentMapping | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE. Stored on [MAIN] filegroup.

---

## 8. Sample Queries

### 8.1 View all past spot instrument mapping changes
```sql
SELECT
    InstrumentID,
    SpotLiquidityAccountID,
    FutureLiquidityAccountID,
    FirstNextInstrumentId,
    SecondNextInstrumentId,
    DbLoginName,
    SysStartTime AS ValidFrom,
    SysEndTime AS ValidTo
FROM [History].[SpotInstrumentMapping] WITH (NOLOCK)
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.5/10 (Elements: 7.5/10, Logic: 7.5/10, Relationships: 7.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SpotInstrumentMapping | Type: Table | Source: etoro/etoro/History/Tables/History.SpotInstrumentMapping.sql*
