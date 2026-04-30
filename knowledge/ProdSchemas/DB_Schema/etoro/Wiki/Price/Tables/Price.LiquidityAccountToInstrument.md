# Price.LiquidityAccountToInstrument

> Many-to-many junction table mapping which liquidity accounts service which instruments - 13,901 rows linking 27 liquidity accounts to 6,339 instruments, forming the core of the pricing feed routing configuration that determines which price sources are eligible for each instrument.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | LiquidityAccountID + InstrumentID (CLUSTERED composite PK) |
| **Partition** | No |
| **Indexes** | 2 (CLUSTERED PK on LiquidityAccountID+InstrumentID; NC on InstrumentID) |

---

## 1. Business Meaning

Price.LiquidityAccountToInstrument is the eligibility mapping table for eToro's price feed routing system. It answers: "Which liquidity accounts are authorized to provide prices for which instruments?" Before the pricing engine can route a price request to a liquidity account, that account must have an entry here for the target instrument.

This table creates a many-to-many relationship between liquidity accounts (price feed connections - see Trade.LiquidityAccounts) and tradeable instruments. With 13,901 rows across 27 accounts and 6,339 instruments, the average instrument is covered by approximately 2.2 liquidity accounts, providing redundancy and fallback capability.

The routing hierarchy:
1. **LiquidityAccountToInstrument** (this table): defines which accounts CAN provide prices for an instrument (eligibility layer)
2. **Price.InstrumentRateSources** (derived via views): defines which accounts are CURRENTLY selected with priority ordering
3. **Price.GetAllowedAccountRateSources**: view joining this table to expose account-level source mappings

This table is consumed extensively by views (GetAccountRateSourceMapping, GetAllowedAccountRateSources, GetInstrumentAllocationData, GetRateSourceConfiguration, GetTopRateSourceAllocations) that form the read API for the pricing engine's source configuration.

Data lifecycle: rows are inserted when a liquidity account is configured to service an instrument. Managed by pricing operations via SPs (DelistInstrument removes entries when instruments are delisted; CleanUnmappedInstrumentRateSources removes orphaned entries). All changes are audited via ASM triggers and temporal system versioning.

---

## 2. Business Logic

### 2.1 Feed Eligibility Mapping

**What**: A row in this table is a permission: liquidity account X is authorized to supply prices for instrument Y.

**Columns/Parameters Involved**: `LiquidityAccountID`, `InstrumentID`

**Rules**:
- One row per LiquidityAccountID+InstrumentID pair
- Multiple liquidity accounts per instrument: enables redundancy (if one feed fails, another can take over)
- Multiple instruments per liquidity account: one account may service hundreds or thousands of instruments
- An instrument NOT in this table for a given account = that account cannot provide prices for it
- The clustered PK on (LiquidityAccountID, InstrumentID) optimizes the primary query: "given an account, list all its instruments"
- NC index on InstrumentID supports the reverse query: "given an instrument, find all eligible accounts"

**Data shape**:
- LiquidityAccountID=1 maps to instruments 1-N (first 10 rows show instruments 1-10; likely covers many more)
- 27 unique accounts, 6,339 unique instruments, 13,901 pairs = average 2.19 accounts per instrument

**Diagram**:
```
Trade.LiquidityAccounts          Trade.Instrument
  LiquidityAccountID=1             InstrumentID=1 (EUR/USD)
  LiquidityAccountID=2             InstrumentID=2 (GBP/USD)
  ...                              ...

Price.LiquidityAccountToInstrument (this table):
  (1, 1) -> Account 1 can price EUR/USD
  (1, 2) -> Account 1 can price GBP/USD
  (2, 1) -> Account 2 can also price EUR/USD (redundancy)
  (2, 5) -> Account 2 can price instrument 5 (Account 1 cannot)

Views read this to build:
  -> GetAllowedAccountRateSources: which sources are valid per instrument
  -> GetRateSourceConfiguration: full routing config
  -> GetTopRateSourceAllocations: priority-ranked source list
```

### 2.2 Instrument Delisting and Cleanup

**What**: When instruments are delisted or when rate source mappings become orphaned, specific SPs remove rows from this table.

**Columns/Parameters Involved**: `LiquidityAccountID`, `InstrumentID`

**Rules**:
- Price.DelistInstrument: removes all LiquidityAccountToInstrument rows for a delisted instrument (plus other cleanup)
- Price.CleanUnmappedInstrumentRateSources: removes rows where the corresponding InstrumentRateSources mapping no longer exists (consistency cleanup)
- Both SPs perform cascading cleanup across related tables

---

## 3. Data Overview

| Note | Value |
|------|-------|
| Row count | 13,901 |
| Unique liquidity accounts | 27 |
| Unique instruments covered | 6,339 |
| Average accounts per instrument | ~2.2 |
| Average instruments per account | ~515 |

| LiquidityAccountID | InstrumentID | Meaning |
|---|---|---|
| 1 | 1 | Liquidity account 1 is eligible to price instrument 1 (EUR/USD) |
| 1 | 2 | Liquidity account 1 is eligible to price instrument 2 (GBP/USD) |
| 1 | 3-10 | Liquidity account 1 covers instruments 3-10 (and more) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NOT NULL | - | CODE-BACKED | Liquidity account identifier. Part of the composite PK (primary sort key). FK to Trade.LiquidityAccounts. Represents a price feed connection (e.g., a specific Bloomberg feed, FIX session, or internal price source). Clustered PK sorts by account first, enabling fast "all instruments for this account" lookups. |
| 2 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. Part of the composite PK. FK to Trade.Instrument. NC index on InstrumentID alone enables fast reverse lookup: "all eligible accounts for this instrument." |
| 3 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set by SQL Server on every DML. Used for DB-level audit tracking. |
| 4 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). Populated when the calling service sets context_info before DML. NULL when not set. |
| 5 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal row validity start. Auto-managed by SQL Server system versioning. Enables point-in-time configuration queries. |
| 6 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31...' | CODE-BACKED | Temporal row validity end. Historical versions in History.LiquidityAccountToInstrument. |
| 7 | HostName | varchar (computed) | - | host_name() | CODE-BACKED | Computed: DB server hostname that processed the last DML on this row. Unusual column - captures the server host rather than user. Relevant in distributed/replicated environments to trace which server wrote a given mapping. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | FK (FK_LATI_LiquidityAccountID) | Maps to the liquidity account providing the price feed |
| InstrumentID | Trade.Instrument | FK (FK_LATI_InstrumentID) | Maps to the tradeable instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetAccountRateSourceMapping | LiquidityAccountToInstrument | VIEW JOIN | Exposes AccountRateSourceID+InstrumentID+LiquidityAccountID mapping |
| Price.GetAllowedAccountRateSources | LiquidityAccountToInstrument | VIEW JOIN | Lists all eligible rate sources per instrument |
| Price.GetInstrumentAllocationData | LiquidityAccountToInstrument | VIEW JOIN | Feeds instrument allocation configuration data |
| Price.GetRateSourceConfiguration | LiquidityAccountToInstrument | VIEW JOIN | Full rate source configuration listing |
| Price.GetTopRateSourceAllocations | LiquidityAccountToInstrument | VIEW JOIN | Priority-ranked top rate source per instrument |
| Price.CleanUnmappedInstrumentRateSources | LiquidityAccountToInstrument | READER/DELETER | Removes orphaned mappings where InstrumentRateSources no longer exists |
| Price.DelistInstrument | LiquidityAccountToInstrument | DELETER | Removes all account mappings for a delisted instrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.LiquidityAccountToInstrument (table)
  |-- FK -> Trade.LiquidityAccounts
  |-- FK -> Trade.Instrument
  ^-- Read by: 5 views (GetAccountRateSourceMapping, GetAllowedAccountRateSources,
                GetInstrumentAllocationData, GetRateSourceConfiguration, GetTopRateSourceAllocations)
  ^-- Modified by: Price.CleanUnmappedInstrumentRateSources, Price.DelistInstrument
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityAccounts | Table | FK - liquidity account must exist |
| Trade.Instrument | Table | FK - instrument must exist |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetAccountRateSourceMapping | View | JOINs to build instrument-to-account mapping with AccountRateSourceID |
| Price.GetAllowedAccountRateSources | View | JOINs to list eligible account sources per instrument |
| Price.GetInstrumentAllocationData | View | JOINs to expose allocation configuration data |
| Price.GetRateSourceConfiguration | View | JOINs to produce full rate source configuration |
| Price.GetTopRateSourceAllocations | View | JOINs to rank top source allocations per instrument |
| Price.CleanUnmappedInstrumentRateSources | Stored Procedure | Reads and deletes orphaned account-instrument mappings |
| Price.DelistInstrument | Stored Procedure | Deletes all mappings for a delisted instrument |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LiquidityAccountToInstrument | CLUSTERED PK | LiquidityAccountID ASC, InstrumentID ASC | - | - | Active |
| IX_InstrumentID | NONCLUSTERED | InstrumentID ASC | - | - | Active |

*The NC index on InstrumentID supports the reverse lookup pattern used extensively by the views: given an InstrumentID, find all eligible LiquidityAccountIDs.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_LATI_LiquidityAccountID | FK | LiquidityAccountID -> Trade.LiquidityAccounts(LiquidityAccountID) |
| FK_LATI_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| DF_LiquidityAccountToInstrument_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_LiquidityAccountToInstrument_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.LiquidityAccountToInstrument |
| AuditDelete_Price_LiquidityAccountToInstrument | TRIGGER (DELETE) | Logs LiquidityAccountID and InstrumentID to History.AuditHistory |
| AuditInsert_Price_LiquidityAccountToInstrument | TRIGGER (INSERT) | Logs new LiquidityAccountID and InstrumentID |
| AuditUpdate_Price_LiquidityAccountToInstrument | TRIGGER (UPDATE) | Logs changes to LiquidityAccountID or InstrumentID |
| TRG_T_LiquidityAccountToInstrument | TRIGGER (INSERT) | ASM no-op placeholder: self-update on composite PK |

---

## 8. Sample Queries

### 8.1 Find all instruments eligible for a specific liquidity account

```sql
SELECT LiquidityAccountID, InstrumentID
FROM Price.LiquidityAccountToInstrument WITH (NOLOCK)
WHERE LiquidityAccountID = 1
ORDER BY InstrumentID;
```

### 8.2 Find all eligible accounts for a specific instrument

```sql
SELECT LiquidityAccountID, InstrumentID
FROM Price.LiquidityAccountToInstrument WITH (NOLOCK)
WHERE InstrumentID = 1  -- EUR/USD
ORDER BY LiquidityAccountID;
```

### 8.3 Instruments covered by multiple accounts (redundancy)

```sql
SELECT InstrumentID, COUNT(*) AS AccountCount
FROM Price.LiquidityAccountToInstrument WITH (NOLOCK)
GROUP BY InstrumentID
HAVING COUNT(*) > 1
ORDER BY AccountCount DESC;
```

### 8.4 Account coverage statistics

```sql
SELECT
    LiquidityAccountID,
    COUNT(*) AS InstrumentsServiced
FROM Price.LiquidityAccountToInstrument WITH (NOLOCK)
GROUP BY LiquidityAccountID
ORDER BY InstrumentsServiced DESC;
```

### 8.5 View recent mapping changes (temporal)

```sql
SELECT LiquidityAccountID, InstrumentID, DbLoginName, HostName, SysStartTime, SysEndTime
FROM Price.LiquidityAccountToInstrument
FOR SYSTEM_TIME ALL
ORDER BY SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.LiquidityAccountToInstrument | Type: Table | Source: etoro/etoro/Price/Tables/Price.LiquidityAccountToInstrument.sql*
