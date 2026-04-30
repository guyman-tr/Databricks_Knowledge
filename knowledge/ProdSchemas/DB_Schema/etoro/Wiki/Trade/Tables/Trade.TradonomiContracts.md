# Trade.TradonomiContracts

> Maps instrument contract periods to human-readable identifiers and links them to liquidity provider contracts for hedging and execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ContractID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active (1 CLUSTERED PK, 2 NC) |

---

## 1. Business Meaning

Trade.TradonomiContracts defines contract periods for tradeable instruments, each identified by a unique ContractID. An instrument can have multiple contracts over time (e.g., different delivery months or validity windows). Each row represents a specific contract period for a given instrument, with a human-readable Description (e.g., EURUSD, GBP/USD), a validity window (FromDate, ToDate), and an active flag. The table serves as the bridge between eToro internal instruments and external liquidity provider (LP) contracts via Trade.TradonomiToLiquidityProviderContracts.

This table exists because trading and hedging require mapping eToro instruments to external LP contract identifiers and validity periods. Without it, the system could not determine which LP contracts are available for an instrument, nor which contract is currently active for routing. Procedures like Trade.CheckValidInstruments and Trade.InsertInstrumentRealTable depend on it when validating and onboarding instruments.

Data is created by Trade.InsertTradonomyContract (which calls Internal.GetTradonomiContractsID for ContractID allocation) and Trade.InsertInstrumentRealTable. Trade.MarkTradonomiContractAsActive sets IsActive=1 for one contract per instrument and 0 for others. Trade.RemoveTradonomiContract deletes rows. The table is read by views (Trade.GetTradonomiContracts, Trade.GetInstrumentContracts, Trade.GetInstrumentConfiguration), functions (Trade.GetAvailableLiquidityProviderContracts, Trade.GetLiguidityProviderContractsForTradonomiContract, Trade.FunGetInstrumentConfiguration), and procedures (Trade.CheckValidInstruments, Trade.SetTradonomiToLPContracts, Trade.UpdateTradonomiToLPContracts). System versioning stores history in History.TradonomiContracts; ASM audit triggers log changes to History.AuditHistory.

---

## 2. Business Logic

### 2.1 One Active Contract Per Instrument

**What**: Only one Tradonomi contract per instrument may be active (IsActive=1) at any time.

**Columns/Parameters Involved**: `IsActive`, `InstrumentID`, `ContractID`

**Rules**:
- IsActive=1: the currently active contract for this instrument - used for routing and LP mapping
- IsActive=0: historical or inactive contract - retained for audit and date-range queries
- Trade.MarkTradonomiContractAsActive sets IsActive=1 for the target contract and IsActive=0 for all other contracts with the same InstrumentID
- When switching active contract, the new contract becomes 1 and all siblings become 0

**Diagram**:
```
InstrumentID=1 (EUR/USD)
  ContractID=1  IsActive=1  FromDate=2010-04-01  ToDate=2010-04-30  -> ACTIVE
  ContractID=99 IsActive=0  ...                                    -> HISTORICAL
```

### 2.2 Contract Validity Window

**What**: Each contract has a validity period used for matching with LP contracts.

**Columns/Parameters Involved**: `FromDate`, `ToDate`, `InstrumentID`

**Rules**:
- FromDate/ToDate define when this contract is valid
- Trade.GetAvailableLiquidityProviderContracts matches LP contracts where LP.ToDate >= Tradonomi.FromDate (date overlap)
- Trade.GetInstrumentContracts joins TradonomiContracts to LiquidityProviderContracts on InstrumentID - used to expose available LP contracts for each instrument

---

## 3. Data Overview

| ContractID | InstrumentID | IsActive | FromDate | ToDate | Description | Meaning |
|---|---|---|---|---|---|---|
| 1 | 1 | 1 | 2010-04-01 | 2010-04-30 | EURUSD | Active EUR/USD contract - core forex pair with standard validity window |
| 2 | 2 | 1 | 2010-04-01 | 2010-04-30 | GBP/USD | Active GBP/USD contract - major forex pair |
| 3 | 3 | 1 | 2010-04-01 | 2010-04-30 | NZDUSD12 | Active NZD/USD contract - suffix may indicate series or tenor |
| 4 | 4 | 1 | 2010-04-01 | 2010-04-30 | USD/CAD | Active USD/CAD contract - North American forex pair |
| 5 | 5 | 1 | 2010-04-01 | 2010-04-30 | USD/JPY | Active USD/JPY contract - major yen pair |

**Selection criteria for the 5 rows:** Picked the first 5 contracts by ContractID to show major forex pairs (EUR/USD, GBP/USD, USD/JPY, etc.) with IsActive=1 and consistent date ranges.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ContractID | int | NO | - | CODE-BACKED | Primary key. Allocated by Internal.GetTradonomiContractsID. Referenced as TradonomiContractID in Trade.TradonomiToLiquidityProviderContracts and Trade.LiquidityProviderContracts consumers. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The tradeable instrument this contract belongs to. Used to join with LP contracts and to enforce one active contract per instrument. |
| 3 | IsActive | tinyint | NO | - | CODE-BACKED | 1 = currently active contract for this instrument (used for routing and LP mapping); 0 = historical/inactive. Only one row per InstrumentID may have IsActive=1. Set by Trade.MarkTradonomiContractAsActive. |
| 4 | FromDate | datetime | NO | - | CODE-BACKED | Start of contract validity period. Used in Trade.GetAvailableLiquidityProviderContracts for date-overlap matching with LP contracts. |
| 5 | ToDate | datetime | NO | - | CODE-BACKED | End of contract validity period. Used in LP contract availability logic (e.g., LP.ToDate >= Tradonomi.FromDate). |
| 6 | Description | varchar(150) | YES | - | CODE-BACKED | Human-readable contract identifier, often mirrors instrument symbol (e.g., EURUSD, GBP/USD, USD/JPY). Unique per UC_Description. Exposed in Trade.GetTradonomiContracts with instrument abbreviation. |
| 7 | DbLoginName | varchar(128) | YES | - | CODE-BACKED | Computed: suser_name(). Database login that performed the operation. Audit/debugging only. |
| 8 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Computed: CONVERT(varchar(500), context_info()). Application context from session. Audit/debugging only. |
| 9 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | System-versioning row start. Set automatically when row is inserted or updated. |
| 10 | SysEndTime | datetime2(7) | NO | 9999-12-31 23:59:59.9999999 | CODE-BACKED | System-versioning row end. 9999-12-31 for current rows; actual timestamp when superseded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK | The tradeable instrument (forex pair, stock, etc.) this contract describes. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.TradonomiToLiquidityProviderContracts | TradonomiContractID | FK | Maps this contract to LP contracts for hedging/execution |
| Trade.GetTradonomiContracts | - | JOIN | View exposing contracts with instrument abbreviation |
| Trade.GetInstrumentContracts | - | JOIN | View joining to LiquidityProviderContracts on InstrumentID |
| Trade.GetInstrumentConfiguration | - | JOIN | Configuration view for instrument + contract |
| Trade.GetAvailableLiquidityProviderContracts | @TradonomiContractID | Lookup | Returns available LP contracts for this contract |
| Trade.GetLiguidityProviderContractsForTradonomiContract | @TradonomiContractID | Lookup | Returns LP contracts already linked to this contract |
| Trade.InsertTradonomyContract | - | INSERT | Creates new contract |
| Trade.MarkTradonomiContractAsActive | - | UPDATE | Sets IsActive for contract and siblings |
| Trade.RemoveTradonomiContract | - | DELETE | Removes contract and TradonomiToLiquidityProviderContracts rows |
| Trade.CheckValidInstruments | - | SELECT/INSERT | Validates instrument and allocates ContractID when missing |
| Trade.InsertInstrumentRealTable | - | INSERT | Bulk instrument onboarding with contract creation |
| Trade.SetTradonomiToLPContracts | - | SELECT | Reads contracts for LP mapping |
| Trade.UpdateInstrumentsSymbolFull | - | SELECT | Updates instrument symbols using contract data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TradonomiContracts (table)
└── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradonomiToLiquidityProviderContracts | Table | FK TradonomiContractID -> ContractID |
| Trade.GetTradonomiContracts | View | FROM/JOIN |
| Trade.GetInstrumentContracts | View | FROM/JOIN |
| Trade.GetInstrumentConfiguration | View | JOIN |
| Trade.FunGetInstrumentConfiguration | Function | LEFT JOIN |
| Trade.GetAvailableLiquidityProviderContracts | Function | FROM |
| Trade.GetLiguidityProviderContractsForTradonomiContract | Function | INNER JOIN |
| Trade.InsertTradonomyContract | Procedure | INSERT |
| Trade.MarkTradonomiContractAsActive | Procedure | SELECT, UPDATE |
| Trade.RemoveTradonomiContract | Procedure | DELETE |
| Trade.CheckValidInstruments | Procedure | SELECT, INSERT |
| Trade.InsertInstrumentRealTable | Procedure | INSERT |
| Trade.SetTradonomiToLPContracts | Procedure | FROM |
| Trade.UpdateInstrumentsSymbolFull | Procedure | FROM |
| Trade.UpdateInstrumentsSymbolFullExtend | Procedure | FROM |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradonomiContracts | CLUSTERED | ContractID | - | - | Active |
| UC_Description | NC | Description | - | - | Active |
| IX_InstrumentID_Description | NC | InstrumentID | Description | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradonomiContracts | PRIMARY KEY | ContractID - unique identifier |
| UC_Description | UNIQUE | Description must be unique across all contracts |
| FK_TradonomiContracts____Instruments | FOREIGN KEY | InstrumentID -> Trade.Instrument.InstrumentID (NOCHECK) |
| DF_TradonomiContracts_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_TradonomiContracts_SysEnd | DEFAULT | SysEndTime = 9999-12-31 23:59:59.9999999 |
| PERIOD FOR SYSTEM_TIME | TEMPORAL | (SysStartTime, SysEndTime) for system versioning |

---

## 8. Sample Queries

### 8.1 List active contracts for major forex instruments

```sql
SELECT TC.ContractID, TC.InstrumentID, TC.Description, TC.FromDate, TC.ToDate
FROM Trade.TradonomiContracts TC WITH (NOLOCK)
INNER JOIN Trade.Instrument TI WITH (NOLOCK) ON TI.InstrumentID = TC.InstrumentID
WHERE TC.IsActive = 1
  AND TI.InstrumentID IN (1, 2, 5, 6);
```

### 8.2 Find all contracts for an instrument (including historical)

```sql
SELECT ContractID, InstrumentID, IsActive, FromDate, ToDate, Description
FROM Trade.TradonomiContracts WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY FromDate DESC;
```

### 8.3 Resolve contract to instrument name via view

```sql
SELECT ContractID, InstrumentID, Description, Abbreviation, FromDate, ToDate
FROM Trade.GetTradonomiContracts WITH (NOLOCK)
WHERE IsActive = 1
  AND InstrumentID <= 10;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2025-03-14 | Enriched: 2025-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TradonomiContracts | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.TradonomiContracts.sql*
