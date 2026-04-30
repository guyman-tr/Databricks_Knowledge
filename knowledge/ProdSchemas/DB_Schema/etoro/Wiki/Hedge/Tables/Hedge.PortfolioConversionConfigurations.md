# Hedge.PortfolioConversionConfigurations

> Maps synthetic non-expiry instruments to their underlying real futures contracts with a weighting multiplier - enables rolling futures hedge by setting Multiplier=0 on expiring contracts and Multiplier=1 on the next contract.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, InstrumentIDToHedge) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK only) |

---

## 1. Business Meaning

Hedge.PortfolioConversionConfigurations solves a fundamental tension in commodity hedging: eToro clients can hold "Oil (Non Expiry)" positions indefinitely without facing contract expiration, but the actual hedge positions in the market must use real futures contracts that expire monthly.

This table defines the mapping from each synthetic non-expiry instrument (InstrumentID) to one or more real futures contracts (InstrumentIDToHedge), with a Multiplier that controls what fraction of the hedge exposure goes to each contract. For a single active contract, Multiplier=1 (100%). During a contract roll, the expiring contract is set to Multiplier=0 (0% - no longer hedging) and the new front-month contract is set to Multiplier=1 (100%).

The table is tiny (2 rows) because this mechanism is only needed for synthetic instruments that roll across expiring futures - currently only Crude Oil. Each InstrumentID can have multiple rows (one per futures contract it maps to), forming a portfolio of futures that collectively replicate the synthetic instrument's exposure.

The same INSERT trigger pattern used in Hedge.OrderTypeConfiguration is applied here: `TRG_T_PortfolioConversionConfigurations` performs a self-update on INSERT to force the initial state into the History table (History.PortfolioConversionConfigurations), since SQL Server temporal versioning only captures pre-change state for UPDATE/DELETE.

---

## 2. Business Logic

### 2.1 Rolling Futures Contract Mechanism

**What**: The Multiplier column is the tool for rolling the hedge from an expiring futures contract to the next month's contract, without interrupting clients' synthetic non-expiry positions.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentIDToHedge`, `Multiplier`

**Rules**:
- For any given InstrumentID, all rows with that InstrumentID should sum to Multiplier=1.0 (fully covered) or 0.0 (inactive)
- Setting a row to Multiplier=0 signals that contract is no longer used for hedging (e.g., contract near expiry)
- Setting the new front-month contract row to Multiplier=1 activates it as the sole hedge
- The transition (both rows updated, or old=0 + new=1) implements the roll without a data gap
- During a roll, both the expiring and new contract rows exist - allowing a gradual transition if needed

**Diagram**:
```
Before roll (Jan 24 is active):
  Oil Non-Expiry (ID=17) -> Crude Oil Future Jan 24 (ID=289), Multiplier=1
  Oil Non-Expiry (ID=17) -> Crude Oil Future Feb 24 (ID=290), Multiplier=0

After roll (Feb 24 becomes active):
  Oil Non-Expiry (ID=17) -> Crude Oil Future Jan 24 (ID=289), Multiplier=0 (rolled out)
  Oil Non-Expiry (ID=17) -> Crude Oil Future Feb 24 (ID=290), Multiplier=1 (active)
```

**Current data state** (as of 2026-03-19):
- Multiplier=0 for Jan 24 contract (ID=289) - expired/rolled out
- Multiplier=1 for Feb 24 contract (ID=290) - active front-month hedge

### 2.2 INSERT Trigger for Temporal History Capture

**What**: `TRG_T_PortfolioConversionConfigurations` fires on INSERT and does a no-op self-update to force the INSERT state into the temporal history table.

**Columns/Parameters Involved**: `InstrumentID`, `InstrumentIDToHedge` (JOIN keys in trigger)

**Rules**:
- SQL Server temporal versioning only writes to History table on UPDATE and DELETE (captures the pre-change row)
- A pure INSERT creates no History entry - the row's initial state is never recorded in History
- The trigger workaround: immediately after INSERT, update the row with `SET InstrumentID = InstrumentID` (identity update)
- This no-op UPDATE causes SQL Server to write the "before" state (the just-inserted row) to History
- Result: the initial configuration state is preserved in History for complete audit trail

---

## 3. Data Overview

2 rows (live). 2 history rows (one prior configuration state per active row - from the trigger INSERT capture).

| InstrumentID | InstrumentIDToHedge | Instrument (synthetic) | Futures Contract | Multiplier | SysStartTime |
|---|---|---|---|---|---|
| 17 | 289 | Oil (Non Expiry) | Crude Oil Future January 24 | 0 | 2023-12-19 10:21:56 |
| 17 | 290 | Oil (Non Expiry) | Crude Oil Future February 24 | 1 | 2023-12-19 10:21:56 |

Both rows were inserted on the same date (2023-12-19), suggesting the Feb 24 contract was already made active (Multiplier=1) and the Jan 24 contract simultaneously deactivated (Multiplier=0) in a single roll operation.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | First component of composite PK. FK to Trade.Instrument (fk_potfolioConvertedInstrument). The synthetic non-expiry instrument visible to eToro clients - e.g., InstrumentID=17 = "Oil (Non Expiry)". This is the instrument being "converted" from synthetic to real-futures representation. |
| 2 | InstrumentIDToHedge | int | NO | - | VERIFIED | Second component of composite PK. FK to Trade.Instrument (fk_potfolioHedgedInstrument). The actual exchange-traded futures contract used to hedge the synthetic instrument - e.g., InstrumentID=290 = "Crude Oil Future February 24". One InstrumentID can map to multiple futures contracts (one row per contract). |
| 3 | Multiplier | decimal(16,8) | NO | - | VERIFIED | The weighting factor (0.0 to 1.0) defining what fraction of the synthetic instrument's exposure is hedged via this futures contract. Multiplier=1 = 100% of the hedge uses this contract (active). Multiplier=0 = this contract no longer carries any of the hedge (expired/rolled out). For rolling futures, exactly one row per InstrumentID will have Multiplier=1 at any given time. |
| 4 | SysStartTime | datetime2(2) | NO | getutcdate() | VERIFIED | System-generated temporal period start. Timestamp when this configuration row became effective. Used with SysEndTime for system versioning (SYSTEM_VERSIONING = ON). History retained in History.PortfolioConversionConfigurations. |
| 5 | SysEndTime | datetime2(2) | NO | '9999-12-31 23:59:59.9999999' | VERIFIED | System-generated temporal period end. '9999-12-31' for all active rows. Set to actual timestamp when a row is updated or deleted. |
| 6 | DbLoginName | varchar | NO (computed) | suser_name() | CODE-BACKED | Computed column. SQL Server login name of the session that last modified this row. Captures DBA/deployment identity. Same audit pattern as Hedge.OrderTypeConfiguration. |
| 7 | AppLoginName | varchar(500) | NO (computed) | CONVERT(varchar(500), context_info()) | CODE-BACKED | Computed column. Application-level user context from `context_info()`. Set by the application before DML operations to identify the calling service or user. Same audit pattern as Hedge.OrderTypeConfiguration. |
| 8 | HostName | varchar | NO (computed) | host_name() | CODE-BACKED | Computed column. The hostname of the client machine that made the last change. Not present in OrderTypeConfiguration - this table additionally captures the host for change attribution. Useful for identifying which hedge server instance or admin machine modified the config. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (explicit, WITH CHECK) - fk_potfolioConvertedInstrument | The synthetic non-expiry instrument being mapped |
| InstrumentIDToHedge | Trade.Instrument | FK (explicit, WITH CHECK) - fk_potfolioHedgedInstrument | The real futures contract used for hedging |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetPortfolioConversionConfigurations | InstrumentID, InstrumentIDToHedge | READER | Sole read path - optional filter by InstrumentID and/or InstrumentIDToHedge |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.PortfolioConversionConfigurations (table)
+-- Trade.Instrument (table) [FK target for InstrumentID - leaf]
+-- Trade.Instrument (table) [FK target for InstrumentIDToHedge - leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target for both InstrumentID (synthetic) and InstrumentIDToHedge (futures contract) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetPortfolioConversionConfigurations | Stored Procedure | READER - returns configuration rows, optionally filtered |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_PortfolioConversionConfigurations | CLUSTERED PK | InstrumentID ASC, InstrumentIDToHedge ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| pk_PortfolioConversionConfigurations | PRIMARY KEY | One row per (synthetic instrument, futures contract) pair |
| fk_potfolioConvertedInstrument | FOREIGN KEY (WITH CHECK) | InstrumentID must exist in Trade.Instrument |
| fk_potfolioHedgedInstrument | FOREIGN KEY (WITH CHECK) | InstrumentIDToHedge must exist in Trade.Instrument |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | SysStartTime/SysEndTime define the temporal period |
| SYSTEM_VERSIONING = ON | TEMPORAL | History retained in History.PortfolioConversionConfigurations |

### 7.3 Triggers

| Trigger | Event | Purpose |
|---------|-------|---------|
| TRG_T_PortfolioConversionConfigurations | FOR INSERT | Self-update workaround to capture INSERT state in temporal history table. Sets `InstrumentID = InstrumentID` (no-op) to trigger temporal history write. Same pattern as Hedge.OrderTypeConfiguration trigger. |

---

## 8. Sample Queries

### 8.1 Get all active (non-zero) portfolio conversion mappings
```sql
SELECT  pcc.InstrumentID,
        src.InstrumentDisplayName AS SyntheticInstrument,
        pcc.InstrumentIDToHedge,
        tgt.InstrumentDisplayName AS FuturesContract,
        pcc.Multiplier
FROM    [Hedge].[PortfolioConversionConfigurations] pcc WITH (NOLOCK)
INNER JOIN [Trade].[InstrumentMetaData] src WITH (NOLOCK)
        ON pcc.InstrumentID = src.InstrumentID
INNER JOIN [Trade].[InstrumentMetaData] tgt WITH (NOLOCK)
        ON pcc.InstrumentIDToHedge = tgt.InstrumentID
WHERE   pcc.Multiplier > 0
ORDER BY pcc.InstrumentID, pcc.Multiplier DESC;
```

### 8.2 View the full mapping for a synthetic instrument (incl. rolled-out contracts)
```sql
SELECT  pcc.InstrumentID,
        pcc.InstrumentIDToHedge,
        tgt.InstrumentDisplayName AS FuturesContract,
        pcc.Multiplier,
        CASE WHEN pcc.Multiplier = 1 THEN 'Active' ELSE 'Rolled Out' END AS HedgeStatus,
        pcc.SysStartTime
FROM    [Hedge].[PortfolioConversionConfigurations] pcc WITH (NOLOCK)
INNER JOIN [Trade].[InstrumentMetaData] tgt WITH (NOLOCK)
        ON pcc.InstrumentIDToHedge = tgt.InstrumentID
WHERE   pcc.InstrumentID = 17 -- Oil (Non Expiry)
ORDER BY pcc.Multiplier DESC;
```

### 8.3 View configuration history (audit trail via temporal)
```sql
SELECT  h.InstrumentID,
        h.InstrumentIDToHedge,
        h.Multiplier,
        h.SysStartTime AS ValidFrom,
        h.SysEndTime   AS ValidTo
FROM    [History].[PortfolioConversionConfigurations] h WITH (NOLOCK)
WHERE   h.InstrumentID = 17
ORDER BY h.InstrumentIDToHedge, h.SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly for this object. Confluence search for "PortfolioConversionConfigurations" and "portfolio conversion" returned unrelated results. The rolling futures mechanism for non-expiry instruments is an implicit design pattern not separately documented in Confluence.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.PortfolioConversionConfigurations | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.PortfolioConversionConfigurations.sql*
