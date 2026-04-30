# History.Exchange

> Temporal system-versioned history table storing all past versions of stock exchange definitions - recording every change to the exchanges (NYSE, NASDAQ, XETRA, etc.) where eToro's tradeable instruments are listed.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; rows identified by (ExchangeID) + SysStartTime + SysEndTime |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

This table is the **SQL Server temporal history store** for `Price.Exchange`. SQL Server automatically moves rows here whenever an exchange definition is updated or deleted.

`Price.Exchange` defines the **stock exchanges and trading venues** where eToro's instruments are listed. Each exchange has a unique identifier (`ExchangeID`), a short code (`Name`), a full description, an ISO 10383 Market Identifier Code (`Mic`), an optional Reuters Instrument Code (`Ric`), and the country where the exchange is located (`CountryID`).

Key active exchanges on the current system:

| ExchangeID | Name | Description | Mic | Ric |
|---|---|---|---|---|
| 1 | DEFAULT_EXCHANGE | XIGNITE Default | DEFEXC | null |
| 2 | GLOBAL_EXCHANGE | XIGNITE Global | GLBEXC | null |
| 3 | NYSE | New York Stock Exchange | XNYS | N |
| 4 | NASDAQ | NASDAQ Stock Market | XNAS | OQ |
| 5 | XETRA | Frankfurt-Deutsche Boerse | XETR | DE |
| 69 | FRA | Frankfurt | XFRA | null |
| 72 | NYSE (American) | NYSE American | XASE | null |
| 73 | OTC US | OTC US | OOTC | null |
| 75 | STO | Stockholm | XSTO | null |
| 81 | DFM | Dubai Financial Market | XDFM | null |
| 93 | Abu_Dhabi | Abu Dhabi Stock Exchange | XADS | null |

With 135 historical rows spanning from September 2021, this table captures changes across 94 distinct exchange records. Most changes were made by `TRAD\bonniegr` in August-September 2025, representing a bulk configuration update that added new exchanges and updated existing ones.

Exchange data is consumed by:
- `Trade.InsertInstrumentMetaData` - links instruments to exchanges when setting up instrument metadata
- `OMS.GetOMSInstrumentsforSync` - syncs instrument-exchange mappings to the OMS (Order Management System)
- `Price.GetTickerInfo` - retrieves price feed ticker information per exchange
- `Price.GetInstrumentsOMPDThresholdByExchangeIds` - gets OMPD thresholds for instrument risk management

---

## 2. Business Logic

### 2.1 Temporal Versioning - How History Is Recorded

**What**: SQL Server automatically populates this table via system-versioning whenever an exchange row is modified or deleted.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `ExchangeID`

**Rules**:
- When a row is **updated**: SQL Server moves the old version here with `SysEndTime` = the moment of update.
- When a row is **deleted**: SQL Server moves the row here with `SysEndTime` = deletion timestamp.
- Active rows in `Price.Exchange` have `SysEndTime = '9999-12-31...'` and are NOT in this history table.
- CLUSTERED index on `(SysEndTime, SysStartTime)` enables efficient `FOR SYSTEM_TIME AS OF` temporal queries.

### 2.2 INSERT Trigger Creates Zero-Duration History Rows

**What**: `TRG_T_Exchange` fires a no-op UPDATE after every INSERT, generating a zero-duration history row for each new exchange.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- After INSERT, trigger does `UPDATE A SET A.ExchangeID = A.ExchangeID` (no-op self-update by ExchangeID).
- SQL Server temporal moves the just-inserted row to history with `SysStartTime = SysEndTime` (zero duration).
- This ensures every exchange ever created has a history record even if immediately deleted.
- Zero-duration rows (SysStartTime = SysEndTime) are INSERT artifacts; rows with SysStartTime < SysEndTime represent actual active periods.

### 2.3 MIC and RIC Exchange Identification Standards

**What**: Exchanges are identified by both ISO 10383 MIC and (optionally) Reuters RIC codes.

**Columns/Parameters Involved**: `Mic`, `Ric`

**Rules**:
- `Mic` (Market Identifier Code): ISO 10383 standard 4-character exchange identifier. Required (NOT NULL). Examples: XNYS (NYSE), XNAS (NASDAQ), XETR (XETRA/Deutsche Boerse), XASE (NYSE American), OOTC (OTC US). Used by OMS and price feed systems.
- `Ric` (Reuters Instrument Code): Reuters' exchange code suffix used to construct Reuters tickers (e.g., "IBM.N" for IBM on NYSE where "N" is the RIC). Optional (NULL for many exchanges). Only populated for major US and European exchanges in current data.
- The two virtual/synthetic exchange entries (`DEFAULT_EXCHANGE`, `GLOBAL_EXCHANGE`) use non-standard synthetic MIC codes (DEFEXC, GLBEXC) and are tied to CountryID=0.

### 2.4 Audit Attribution

**What**: `DbLoginName` and `AppLoginName` capture who made each change.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- `DbLoginName = suser_name()` - SQL Server login. Historical values include `TRAD\bonniegr` (developer/DBA account for Aug 2025 bulk update).
- `AppLoginName = CONVERT(varchar(500), context_info())` - application user email, padded with null bytes. NULL when not set by the application (most historical changes).
- Historical changes were made directly via SSMS (no AppLoginName set).

---

## 3. Data Overview

| ExchangeID | Name | Mic | CountryID | DbLoginName | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|---|
| 72 | NYSE | XASE | 219 (US) | TRAD\bonniegr | 2025-08-10 | 2025-09-28 | NYSE American (ExchangeID=72) had its description updated from an earlier value to "NYSEAmerican" in Aug 2025, then superseded again in Sep 2025. |
| 69 | FRA | XFRA | 79 (Germany) | TRAD\bonniegr | 2025-08-10 | 2025-09-28 | Frankfurt exchange update - was active from Aug 10 to Sep 28, 2025. |
| 93 | Abu_Dhabi | XADS | 217 (UAE) | TRAD\bonniegr | 2025-08-10 | 2025-09-28 | Abu Dhabi Stock Exchange - added Aug 2025 (one of many new exchanges added in that batch), superseded Sep 2025. |

135 history rows, 94 distinct ExchangeIDs, oldest version from Sep 2021. The Sep 2025 bulk update superseded the most rows simultaneously (most rows have SysEndTime in that batch window).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | NO | - | CODE-BACKED | The exchange identifier (IDENTITY in Price.Exchange). Identifies the exchange across all its historical versions. Core production exchanges: 1=DEFAULT_EXCHANGE, 2=GLOBAL_EXCHANGE, 3=NYSE, 4=NASDAQ, 5=XETRA. ExchangeIDs up to 99 are active real-world exchanges; IDs above 100 may be test or niche exchanges. |
| 2 | Name | varchar(16) | NO | - | VERIFIED | Short exchange code/ticker used within eToro systems (16 char max). Examples: NYSE, NASDAQ, XETRA, FRA, STO, DFM, OTC US. Not necessarily the ISO standard abbreviation - varies by convention. |
| 3 | Description | varchar(150) | NO | - | VERIFIED | Full descriptive name of the exchange. Examples: "New York Stock Exchange", "NASDAQ Stock Market", "FrankFurt-Deutsche Boerse", "StockHolm", "Dubai". Max 150 characters. |
| 4 | Mic | varchar(16) | NO | - | VERIFIED | ISO 10383 Market Identifier Code. 4-character standard exchange code used globally. Examples: XNYS (NYSE), XNAS (NASDAQ), XETR (XETRA), XASE (NYSE American), XFRA (Frankfurt), XSTO (Stockholm). Used by OMS and price feed systems for exchange identification. |
| 5 | CountryID | int | NO | - | CODE-BACKED | The country where the exchange operates. FK to Dictionary.Country (explicit constraint on source table). CountryID=0 for virtual/synthetic exchanges (DEFAULT_EXCHANGE, GLOBAL_EXCHANGE). CountryID 219=US, 79=Germany, 196=Sweden, 217=UAE. |
| 6 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login captured via suser_name() computed column on source. Identifies who made the DML change at the database level. Historical value: `TRAD\bonniegr` for Aug-Sep 2025 bulk updates (direct SSMS edits). NULL if unavailable. |
| 7 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application user identity captured via context_info() computed column. Set by the application with SET CONTEXT_INFO before DML. Contains email address padded with null bytes. NULL for all current history rows (changes were made directly, not via application). |
| 8 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this exchange version became active. Managed by SQL Server temporal system-versioning. Equal to SysEndTime for INSERT-triggered zero-duration rows. |
| 9 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this version was superseded. Clustered index leading column for temporal range lookups. Equal to SysStartTime for INSERT-triggered zero-duration rows. |
| 10 | Ric | varchar(16) | YES | - | VERIFIED | Reuters Instrument Code exchange suffix. Used to construct Reuters tickers: `{ticker}.{Ric}` (e.g., IBM.N for NYSE). NULL for many exchanges. Active values: N=NYSE (XNYS), OQ=NASDAQ (XNAS), DE=XETRA. Populating Ric enables Reuters price feed integration for that exchange. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CountryID | Dictionary.Country | Implicit (explicit FK on source) | The country where the exchange is located (0=virtual/synthetic) |
| (all columns) | Price.Exchange | Temporal | This row is a historical version of the source table row with matching ExchangeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.Exchange | (all columns) | Temporal (SYSTEM_VERSIONING) | Source table - SQL Server writes superseded rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Exchange (table)
- Temporal history leaf node - no code-level dependencies
- Populated automatically from Price.Exchange (table)
- INSERT trigger on source creates additional zero-duration history rows
```

### 6.1 Objects This Depends On

No dependencies. Temporal history table populated automatically by SQL Server.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.Exchange | Table | Source table - SQL Server writes old row versions here automatically on UPDATE/DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Exchange | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

**Filegroup**: [PRIMARY] - matching source table.
**Storage**: DATA_COMPRESSION = PAGE (table-level and index-level).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | Temporal history tables cannot have PK, UNIQUE, FK, or CHECK constraints in SQL Server |

---

## 8. Sample Queries

### 8.1 Exchange configuration as of a specific date
```sql
SELECT ExchangeID, Name, Description, Mic, Ric, CountryID, SysStartTime, SysEndTime
FROM [History].[Exchange] WITH (NOLOCK)
WHERE '2025-01-01' BETWEEN SysStartTime AND SysEndTime
  AND SysStartTime < SysEndTime  -- exclude zero-duration INSERT artifacts
ORDER BY ExchangeID
```

### 8.2 Full change history for a specific exchange
```sql
-- Historical versions
SELECT 'History' AS Source, ExchangeID, Name, Description, Mic, Ric,
       DbLoginName, SysStartTime, SysEndTime
FROM [History].[Exchange] WITH (NOLOCK)
WHERE ExchangeID = 3  -- NYSE
UNION ALL
-- Current version
SELECT 'Current' AS Source, ExchangeID, Name, Description, Mic, Ric,
       DbLoginName, SysStartTime, SysEndTime
FROM [Price].[Exchange] WITH (NOLOCK)
WHERE ExchangeID = 3
ORDER BY SysStartTime
```

### 8.3 All exchanges by country (current + history combined view)
```sql
SELECT he.ExchangeID, he.Name, he.Mic, he.CountryID,
       he.SysStartTime, he.SysEndTime, he.DbLoginName
FROM [History].[Exchange] he WITH (NOLOCK)
WHERE he.SysStartTime < he.SysEndTime  -- exclude INSERT artifacts
ORDER BY he.CountryID, he.ExchangeID, he.SysStartTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Exchange | Type: Table | Source: etoro/etoro/History/Tables/History.Exchange.sql*
