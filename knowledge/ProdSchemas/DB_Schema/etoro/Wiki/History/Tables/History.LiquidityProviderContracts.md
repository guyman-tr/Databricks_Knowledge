# History.LiquidityProviderContracts

> SQL Server temporal history table storing prior row versions of Trade.LiquidityProviderContracts, capturing the complete history of which instruments were contractually available through which liquidity providers and exchanges over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.LiquidityProviderContracts is the SQL Server system-versioning history table for Trade.LiquidityProviderContracts. It is declared as `HISTORY_TABLE = [History].[LiquidityProviderContracts]` in the Trade.LiquidityProviderContracts DDL. Whenever a row in Trade.LiquidityProviderContracts is updated or deleted, the prior version is automatically written here by the SQL Server temporal engine.

Trade.LiquidityProviderContracts defines the contractual agreements between eToro and its external liquidity providers (LPs) for specific financial instruments. Each contract specifies: which LP (LiquidityProviderID), which instrument (InstrumentID), which exchange (ExchangeID), the LP's ticker symbol for that instrument, the contract date range (FromDate to ToDate), and an optional rate conversion factor. These contracts determine how instrument prices are sourced and how trades are routed to external markets.

This is the most active temporal history table in this batch with 404,406 rows, covering the period from 2021-09-13 to current (2026-03-19). The high row count reflects frequent contract updates as instruments are added, tickers change, and LP arrangements evolve. The active table also has an INSERT trigger (Tr_T_LiquidityProviderContracts_INSERT) that generates INSERT artifact history rows with SysStartTime = SysEndTime for every new contract. The duplicate Audit triggers (AuditInsert/Update/Delete) also write field-by-field changes to History.AuditHistory.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Versioning Mechanics

**What**: SQL Server writes superseded row versions from Trade.LiquidityProviderContracts into this table on every UPDATE or DELETE.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, all data columns

**Rules**:
- INSERT trigger (Tr_T_LiquidityProviderContracts_INSERT) on active table forces immediate history on every INSERT - generates a zero-duration artifact row (SysStartTime = SysEndTime)
- When a contract is updated (ticker changed, dates extended, rate factor adjusted): old version written here with the exact validity window
- PK of active table is (InstrumentID, LiquidityProviderID, ExchangeID) - one contract row per unique combination; ContractID is a surrogate IDENTITY column for auditing
- 404K history rows vs typical data: reflects the system bootstrapping (Sept 2021 bulk load of all existing contracts) plus ongoing daily updates

### 2.2 Contract Lifecycle Patterns

**What**: Contracts have a FromDate/ToDate range that governs when a given LP-instrument arrangement was active.

**Columns/Parameters Involved**: `FromDate`, `ToDate`, `ContractID`, `Ticker`

**Rules**:
- Some contracts have FromDate = ToDate (created and immediately superseded by the trigger mechanism)
- ToDate = '2100-01-01 00:00:00' indicates an open-ended/permanent contract
- ContractID is auto-incremented IDENTITY(1,1) - each new contract row in the active table gets a unique ContractID even if it replaces a prior contract for the same (InstrumentID, LP, Exchange) combination
- RateConversionFactor defaults to 1.0 (no currency conversion needed); non-1 values indicate instruments where the LP quotes in a different currency or unit

### 2.3 Ticker Formats Observed

**What**: The Ticker column contains the LP's symbol for the instrument, used to match price feed data with trade execution routing.

**Rules**:
- Bloomberg ticker format: "AAPL US@NBSC Equity" (exchange-specific Bloomberg format)
- Simple symbol: "BA" (just the stock symbol)
- Numeric instrument ID as ticker: "1016586" (when no standard symbol available)
- The same instrument may have different tickers at different LPs (observed: InstrumentID 1053988 has different tickers at LiquidityProviderID 41 vs 20000)

---

## 3. Data Overview

404,406 rows total. Date range: 2021-09-13 to 2026-03-19 (continuously active). Sample history rows (most recently closed):

| ContractID | LiquidityProviderID | InstrumentID | ExchangeID | Ticker | FromDate | ToDate | RateConversionFactor | SysStartTime | SysEndTime | Meaning |
|-----------|---------------------|-------------|-----------|--------|---------|--------|---------------------|-------------|------------|---------|
| 22837 | 40 | 1001 (AAPL) | 1 | AAPL US@NBSC Equity | 2023-12-27 | 2023-12-27 | 1.0 | 2025-03-17 | 2026-03-19 | AAPL contract at LP 40 was current from Mar 2025 until Mar 2026 - then updated |
| 294408 | 20000 | 1010 (Boeing) | 1 | BA | 2024-06-06 | 2024-06-06 | 1.0 | 2025-12-08 | 2026-02-23 | Boeing contract at LP 20000 was valid Dec 2025 to Feb 2026 |
| 395844 | 41 | 1053988 | 1 | TTAM US@NBSC Equity | 2026-02-17 | 2026-02-17 | 1.0 | 2026-02-17 | 2026-02-17 | INSERT artifact (trigger): zero-duration version created at instrument insert time |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ContractID | int | NO | - | VERIFIED | Auto-incremented contract identifier (IDENTITY in active table). Each new contract gets a unique sequential ID. Used in audit trail (History.AuditHistory) as a reference. Not a composite key component - the PK is (InstrumentID, LiquidityProviderID, ExchangeID). |
| 2 | LiquidityProviderID | int | NO | - | VERIFIED | ID of the liquidity provider. FK to Trade.LiquidityProviderType in active table. Identifies which external LP (broker, exchange connection, internalizer) this contract covers. |
| 3 | InstrumentID | int | NO | - | VERIFIED | Financial instrument ID. FK to Trade.Instrument in active table. Identifies which financial instrument this LP-exchange contract covers. |
| 4 | FromDate | datetime | NO | - | VERIFIED | Start date of the LP-instrument contract. When the contract became effective. FromDate = ToDate on many rows indicates a contract that was created and immediately superseded (trigger artifact or same-day replacement). |
| 5 | ToDate | datetime | NO | - | VERIFIED | End date of the LP-instrument contract. When the contract was replaced or terminated. ToDate = 2100-01-01 00:00:00 = open-ended contract with no planned expiry. The default in active table is '2100-01-01'. |
| 6 | Ticker | varchar(150) | YES | - | VERIFIED | The LP's symbol/ticker for this instrument. Used to map eToro instrument IDs to the LP's own identifiers in price feeds and order routing. Formats observed: Bloomberg equity tickers ("AAPL US@NBSC Equity"), simple symbols ("BA"), numeric IDs ("1016586"). NULL if no ticker assigned. |
| 7 | ExchangeID | int | NO | 1 | VERIFIED | Exchange through which this LP contract routes. FK to Price.Exchange in active table. DEFAULT 1 (the primary/default exchange). All observed rows: ExchangeID=1. |
| 8 | RateConversionFactor | decimal(20,10) | YES | 1 | CODE-BACKED | Multiplicative factor applied to prices from this LP for this instrument. DEFAULT 1.0 (no conversion). Non-1 values indicate instruments where the LP quotes in different units (e.g., pence vs pounds, cents vs dollars) or requires a fixed price scaling. NULL if not applicable. |
| 9 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | Materialized SQL Server login name (suser_name()) at the time this row version was closed. In active table this is a computed column; stored here as a snapshot. Identifies which DB login modified the contract. |
| 10 | AppLoginName | varchar(500) | YES | - | VERIFIED | Materialized application identity (context_info()) at version close time. Stored here as a snapshot. NULL if not set by the writing application. |
| 11 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Start of the validity window for this history row. Set by SQL Server temporal engine. For INSERT artifacts: SysStartTime = SysEndTime. For genuine updates: the timestamp when the previous contract state became current. |
| 12 | SysEndTime | datetime2(7) | NO | - | VERIFIED | End of the validity window for this history row. Set to the UTC time of the UPDATE/DELETE that closed this version. CLUSTERED INDEX leads with SysEndTime for optimal temporal query performance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderID | Trade.LiquidityProviderType | Implicit | The LP for this contract. FK mirrors active table's FK_LiquidityProviderContracts_LiquidityProviderType. |
| InstrumentID | Trade.Instrument | Implicit | The instrument covered by this contract. FK mirrors active table's FK_LiquidityProviderContracts__Instruments. |
| ExchangeID | Price.Exchange | Implicit | The exchange through which this contract routes. FK mirrors active table's FK_LiquidityProviderContracts_ExchangeID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.LiquidityProviderContracts | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | Declares this as its HISTORY_TABLE. All closed row versions flow here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.LiquidityProviderContracts (table)
  - leaf node: no code-level dependencies
  - auto-populated by SQL Server from: Trade.LiquidityProviderContracts (temporal parent)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderContracts | Table | Declares this as its HISTORY_TABLE for SYSTEM_VERSIONING. All temporal version rows flow here. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_LiquidityProviderContracts | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

DATA_COMPRESSION=PAGE on [PRIMARY] filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION=PAGE | Storage option | Page-level compression applied to all data and index pages. |

No explicit FKs or PKs. All integrity enforced through SYSTEM_VERSIONING contract with Trade.LiquidityProviderContracts.

---

## 8. Sample Queries

### 8.1 View all contract versions for a specific instrument-LP combination
```sql
SELECT ContractID, LiquidityProviderID, InstrumentID, ExchangeID, Ticker,
       FromDate, ToDate, RateConversionFactor, SysStartTime, SysEndTime,
       CASE WHEN SysStartTime = SysEndTime THEN 'INSERT artifact' ELSE 'Genuine version' END AS VersionType
FROM History.LiquidityProviderContracts WITH (NOLOCK)
WHERE InstrumentID = 1001 AND LiquidityProviderID = 40
ORDER BY SysStartTime;
```

### 8.2 Use FOR SYSTEM_TIME AS OF to see contract state at a historical date
```sql
SELECT ContractID, LiquidityProviderID, InstrumentID, ExchangeID, Ticker,
       FromDate, ToDate, SysStartTime, SysEndTime
FROM Trade.LiquidityProviderContracts WITH (NOLOCK)
FOR SYSTEM_TIME AS OF '2024-01-01 00:00:00'
WHERE InstrumentID = 1001
ORDER BY LiquidityProviderID;
```

### 8.3 Find instruments where the ticker changed (contract update, not INSERT artifact)
```sql
SELECT h.InstrumentID, h.LiquidityProviderID, h.Ticker AS OldTicker,
       lpc.Ticker AS CurrentTicker, h.SysEndTime AS ChangedAt
FROM History.LiquidityProviderContracts h WITH (NOLOCK)
JOIN Trade.LiquidityProviderContracts lpc WITH (NOLOCK)
     ON h.InstrumentID = lpc.InstrumentID
     AND h.LiquidityProviderID = lpc.LiquidityProviderID
     AND h.ExchangeID = lpc.ExchangeID
WHERE h.Ticker <> lpc.Ticker
  AND h.SysStartTime <> h.SysEndTime  -- exclude INSERT artifacts
ORDER BY h.SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Bloomberg Connector - Resubscribe per selected Subscription Plan](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/13788217345/Bloomberg+Connector+-+Resubscribe+per+selected+Subscription+Plan) | Confluence | Bloomberg connectivity context for LP instrument contracts and ticker format. |
| [ZBFX Adding Instruments](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/12789350431/ZBFX+Adding+Instruments) | Confluence | ZBFX liquidity provider instrument onboarding process and contract setup. |

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 INSERT trigger + 3 audit triggers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.LiquidityProviderContracts | Type: Table | Source: etoro/etoro/History/Tables/History.LiquidityProviderContracts.sql*
