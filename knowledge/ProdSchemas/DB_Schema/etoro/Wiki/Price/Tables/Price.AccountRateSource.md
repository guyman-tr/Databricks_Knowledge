# Price.AccountRateSource

> Master registry of market data sources and liquidity feed connections used by the eToro pricing engine - each row represents a distinct named provider (Bloomberg, Xignite, ZBFX, Goldman Sachs, etc.) that can supply real-time prices for instruments.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | AccountRateSourceID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

AccountRateSource is the master lookup table for price data providers - the entities or services that supply real-time market price feeds to eToro's pricing engine. Each row represents a distinct named source: a third-party market data vendor (Bloomberg, Xignite, QuantHouse, ICE), a liquidity provider/broker operating as a price feed (ZBFX, Goldman Sachs, Exante, IG), a direct exchange connection (GDAX/Coinbase, Kraken), an internal eToro pricing model, or a FIX protocol session with a specific counterparty.

This table is the naming layer of the feed infrastructure. The actual routing configuration - which instruments get prices from which sources - is defined in the child tables (Price.InstrumentRateSources, Price.TemplateRateSourceAllocations) that FK to this table. Without AccountRateSource, those tables would have anonymous integer IDs with no human-readable meaning.

Data lifecycle: rows are inserted manually or via tooling when a new price source is onboarded (e.g., adding a new broker integration). Rows are never deleted (IDs 0 = "Do not use!" indicates soft-deprecation rather than deletion to preserve FK integrity). The table is small (~44 rows) and rarely changes. System versioning (temporal table) records the full history of every change for audit purposes.

---

## 2. Business Logic

### 2.1 Price Source Categorization by Naming Pattern

**What**: The Name column reveals the category of each price source through naming conventions.

**Columns/Parameters Involved**: `AccountRateSourceID`, `Name`

**Rules**:
- IDs 1-6: Simulation feeds ("Simulation Non Stocks", "Simulation Stocks BATS/DAX/FTSE") - used for demo accounts, market-closed scenarios, or simulation mode
- IDs 8-9, 14, 200-201: Xignite data vendor variants (BATS real-time, global quotes, global real quotes, Nasdaq LastSale, EHT variants)
- IDs 20-24, 196-197, 268, 555: External providers (Goldman Sachs, ZBFX, BTC-e, FD/EtoroAll, Bloomberg RAW/Price, BBG Futures)
- IDs 54, 217: Crypto exchange direct connections (GDAX=Coinbase, Kraken)
- IDs 100+, 302, 304: Institutional data providers (QuantHouse MBO/MBL, OMS Bloomberg, ICE Price Provider)
- IDs 9001-9006: FIX protocol session connections (FIX_ZBFX, FIX_EXANTE, FIX_FD, FIX_FXCM, FIX_IG, FIX_BITA) - 9xxx = FIX range
- ID -1: Special "US" source with negative ID (special routing logic)
- ID 0: "Do not use!" - explicitly deprecated source, preserved for FK integrity

**Diagram**:
```
AccountRateSource registry
  |-1: US (special)
  | 0: Do not use! (deprecated)
  | 1-6: Simulation feeds (demo/simulation mode)
  | 8-9, 14, 200-201: Xignite variants (stock market data)
  | 20-24: Legacy brokers/providers (Goldman, ZBFX, BTC-e, FD)
  | 54, 217: Crypto exchanges (GDAX/Coinbase, Kraken)
  | 196-197, 268, 555: Bloomberg feed variants
  | 290: Internal market maker (EtoroXMarketMakerHTTP)
  | 300-304: Modern institutional feeds (FX NDF, QuantHouse, OMS)
  | 9001-9010: FIX protocol sessions
  | 100017-100019: Large-ID OMS/ICE feeds
```

### 2.2 Temporal Auditing via System Versioning

**What**: Every INSERT, UPDATE, and DELETE is automatically tracked in History.AccountRateSource via SQL Server temporal table, plus manual audit trigger logging to History.AuditHistory.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- SysStartTime and SysEndTime define the validity period of each row version in the temporal history
- SysEndTime = '9999-12-31...' means the row is currently active
- DbLoginName (computed: suser_name()) captures the SQL login that last modified the row - auto-set, not manually provided
- AppLoginName (computed: context_info()) captures the application context - populated when the calling service sets context_info before the DML
- Audit triggers additionally write to History.AuditHistory for application-level audit trail with UserName, AppName, HostName

---

## 3. Data Overview

| AccountRateSourceID | Name | Meaning |
|---|---|---|
| -1 | US | Special-purpose source with negative ID. Likely used for US-specific routing logic or as a sentinel value in source allocation queries. |
| 0 | Do not use! | Explicitly deprecated source. Preserved with this name to prevent accidental use; FK integrity requires keeping the row rather than deleting it. |
| 1 | Simulation Non Stocks | Simulated price feed for non-stock instruments (forex, crypto, indices, commodities) in demo/simulation mode. Clients on demo accounts receive prices from this source. |
| 5 | eToro Custom Price Provider | Internal eToro pricing model. Used when eToro itself generates prices rather than routing to an external provider - typically for proprietary instruments or custom pricing logic. |
| 196 | Bloomberg RAW | Raw (unprocessed) Bloomberg price feed. "RAW" indicates prices are passed through without additional transformation. Used for instruments sourced directly from Bloomberg terminal data. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AccountRateSourceID | int | NOT NULL | - | VERIFIED | Primary key. Integer identifier for a price data source. Negative values (-1) are valid special cases. ID 0 = deprecated. IDs 1-6 = simulation feeds. IDs 9001-9006 = FIX protocol connections. IDs 100000+ = large-numbered OMS/institutional feeds. |
| 2 | Name | varchar(50) | NOT NULL | - | VERIFIED | Human-readable name of the price source. Used in operations tooling, configuration UIs, and monitoring dashboards. Naming conventions reveal type: "Simulation" = demo feed, "FIX_" prefix = FIX protocol, "Bloomberg" = Bloomberg variants, provider names (ZBFX, Xignite, QuantHouse, etc.) = external vendors. |
| 3 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed column: captures the SQL Server login name of the user/service account that last modified this row. Set automatically by SQL Server on every DML operation; cannot be overridden by callers. Used for DB-level audit tracking. |
| 4 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed column: captures the application-level identity via SQL Server context_info(). Populated when the calling application sets context_info before executing DML (e.g., the pricing management service sets its service name). NULL when context_info is not set. Used for app-level audit tracking alongside DbLoginName. |
| 5 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal row validity start: timestamp when this version of the row became current. Auto-managed by SQL Server temporal table mechanism. Used with SysEndTime to query point-in-time states of the table via FOR SYSTEM_TIME AS OF. |
| 6 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal row validity end: '9999-12-31...' = currently active row. When a row is updated, its current version's SysEndTime is set to now, and a new version starts. Historical versions are in History.AccountRateSource. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.InstrumentRateSources | AccountRateSourceID | FK (FK_PARS_PIRS) | Links instruments to their allowed rate sources; this is the primary consumer of AccountRateSource IDs |
| Price.BenchmarkFeedConfiguration | BenchmarkAccountRateSourceID | FK (FK_PriceBenchmark_BenchmarkARSID) | Designates one source as the benchmark feed for a currency type |
| Price.TemplateRateSourceAllocations | AccountRateSourceID | FK (FK_Price_TemplateRateSourceAllocations_ARSID) | Assigns a rate source to a pricing template |
| Trade.LiquidityAccounts | AccountRateSourceID | Implicit/Lookup | LiquidityAccounts carry the AccountRateSourceID; views join LiquidityAccounts to expose the source mapping to instruments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.AccountRateSource (table) - leaf node, no code-level dependencies
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentRateSources | Table | FK child - maps instruments to their rate sources |
| Price.BenchmarkFeedConfiguration | Table | FK child - designates benchmark feed per currency type |
| Price.TemplateRateSourceAllocations | Table | FK child - assigns sources to pricing templates |
| Price.GetAccountRateSourceMapping | View | Exposes instrument-to-source mapping via LiquidityAccounts |
| Price.GetAllowedAccountRateSources | View | Resolves which sources are allowed per instrument |
| Price.GetInstrumentRateSources | View | JOINs to expose AccountRateSource.Name alongside instrument-source config |
| Price.GetInstrumentAllocationData | View | Reads source ID as part of instrument allocation data |
| Price.GetInstrumentPriceSources | View | Includes source ID in instrument price source enumeration |
| Price.GetMarkupInstrumentAccounts | View | Includes source ID in markup instrument account data |
| Price.GetPriceAccounts | View | Exposes source ID in price account listing |
| Price.GetPriceServerAccountAllocation | View | Includes source ID in price server allocation data |
| Price.GetRateSourceConfiguration | View | Lists source ID as part of rate source configuration |
| Price.GetTopRateSourceAllocations | View | Uses source ID to rank top rate allocations per instrument |
| Price.CleanUnmappedInstrumentRateSources | Stored Procedure | Reads AccountRateSourceID via InstrumentRateSources |
| Price.DelistInstrument | Stored Procedure | Reads AccountRateSourceID for instruments being delisted |
| Price.InstrumentRateSourceAdd | Stored Procedure | Accepts AccountRateSourceID as parameter to add instrument-source mapping |
| Price.UpdateInstrumentRateSources | Stored Procedure | References AccountRateSourceID in bulk update |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | AccountRateSourceID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_AccountRateSource_SysStart | DEFAULT | SysStartTime = getutcdate() - temporal period start defaults to now |
| DF_AccountRateSource_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' - active row end sentinel |
| SYSTEM_VERSIONING = ON | Temporal | Full row history maintained in History.AccountRateSource |
| AuditDelete_Price_AccountRateSource | TRIGGER (DELETE) | Writes D-operation audit record to History.AuditHistory with old Name value |
| AuditInsert_Price_AccountRateSource | TRIGGER (INSERT) | Writes I-operation audit record to History.AuditHistory with new Name value |
| AuditUpdate_Price_AccountRateSource | TRIGGER (UPDATE) | Writes U-operation audit record to History.AuditHistory when Name changes |
| TRG_T_AccountRateSource | TRIGGER (INSERT) | ASM-generated placeholder trigger; performs a no-op self-update on insert |

---

## 8. Sample Queries

### 8.1 List all active price sources

```sql
SELECT
    AccountRateSourceID,
    Name,
    DbLoginName,
    SysStartTime
FROM Price.AccountRateSource WITH (NOLOCK)
ORDER BY AccountRateSourceID;
```

### 8.2 Find instruments mapped to a specific rate source

```sql
SELECT
    ARS.AccountRateSourceID,
    ARS.Name AS SourceName,
    IRS.InstrumentID,
    IRS.Priority
FROM Price.AccountRateSource ARS WITH (NOLOCK)
JOIN Price.InstrumentRateSources IRS WITH (NOLOCK)
    ON ARS.AccountRateSourceID = IRS.AccountRateSourceID
WHERE ARS.Name LIKE '%Bloomberg%'
ORDER BY IRS.InstrumentID, IRS.Priority;
```

### 8.3 View change history for a rate source (temporal query)

```sql
SELECT
    AccountRateSourceID,
    Name,
    DbLoginName,
    AppLoginName,
    SysStartTime,
    SysEndTime
FROM Price.AccountRateSource
FOR SYSTEM_TIME ALL
WHERE AccountRateSourceID = 196
ORDER BY SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Create Multiple Deployments - Bloomberg Connector](https://etoro-jira.atlassian.net/wiki/spaces/MDT/pages/13095699156) | Confluence | Bloomberg Connector onboarding creates a new LiquidityProviderType and assigns instruments - confirms the pattern where new sources (like Bloomberg feeds) are added to AccountRateSource and then linked to instruments via LiquidityAccounts/InstrumentRateSources |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 7, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.AccountRateSource | Type: Table | Source: etoro/etoro/Price/Tables/Price.AccountRateSource.sql*
