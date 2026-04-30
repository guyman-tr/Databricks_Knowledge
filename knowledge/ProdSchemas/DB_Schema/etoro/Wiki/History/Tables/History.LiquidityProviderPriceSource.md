# History.LiquidityProviderPriceSource

> SQL Server temporal history table automatically maintained by the database engine, recording every past mapping state of Price.LiquidityProviderPriceSource - the configuration table that assigns each liquidity provider instance to its price data source (exchange or feed).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite: (SysEndTime, SysStartTime) - temporal history clustered index |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

History.LiquidityProviderPriceSource is the temporal history backing table for Price.LiquidityProviderPriceSource. It is automatically populated by SQL Server's SYSTEM_VERSIONING mechanism whenever rows in Price.LiquidityProviderPriceSource are updated or deleted.

Price.LiquidityProviderPriceSource assigns each liquidity provider instance (LiquidityProviderID from Trade.LiquidityProviders) to exactly one price source (PriceSourceID from Dictionary.PriceSourceName). The price source defines which market data feed or exchange provides price data for instruments routed through that LP. For example, an LP configured with PriceSourceID=3 (NASDAQ) receives NASDAQ price data for its instruments.

This is a one-to-one mapping: each LP has exactly one price source (PK = LiquidityProviderID alone). When an LP's price source is changed - for example, migrating from one exchange feed to another, or reassigning an LP during infrastructure changes - the prior assignment is archived in this history table.

With 0 rows in the test environment, this table contains data only in production where LP-to-price-source assignments are actively managed. Changes are managed exclusively through stored procedures (Price.InsertLiquidityProviderPriceSource, Price.UpdateLiquidityProviderPriceSource, Price.DeleteLiquidityProviderPriceSource) with validation and optional AppLoginName context capture.

**Note**: Unlike similar tables (Price.LiquidityProviderQuantities, CEP.ListCIDMappings), there is NO INSERT trigger on Price.LiquidityProviderPriceSource. This means only UPDATE and DELETE events generate history rows - the initial INSERT of a mapping does not appear in this history table.

---

## 2. Business Logic

### 2.1 One LP -> One Price Source Mapping

**What**: Each liquidity provider instance is assigned exactly one price data source. This controls which market data feed the Price Control System (PCS) uses for that LP's instruments.

**Columns/Parameters Involved**: `LiquidityProviderID`, `PriceSourceID`

**Rules**:
- PK on live table = LiquidityProviderID alone: strictly one price source per LP
- NC index on PriceSourceID: supports reverse lookup ("which LPs use NASDAQ pricing?")
- FK LiquidityProviderID -> Trade.LiquidityProviders (enforced on live table)
- FK PriceSourceID -> Dictionary.PriceSourceName (enforced on live table)
- Price.InsertLiquidityProviderPriceSource validates: LP must exist, PriceSource must exist, no duplicate mapping
- Price.UpdateLiquidityProviderPriceSource validates: mapping must exist, new PriceSource must exist
- Changing PriceSourceID is the most common modification and generates a history row capturing the old source

### 2.2 PriceSourceID Values - Price Data Sources

**What**: PriceSourceID references Dictionary.PriceSourceName, which defines all recognized market data sources.

**Complete PriceSourceName dictionary**:

| PriceSourceID | Name | Type |
|---|---|---|
| 0 | eToro | Internal |
| 1 | Xignite | Data vendor |
| 2 | CME | US futures exchange |
| 3 | NASDAQ | US equity exchange |
| 4 | Chi-Ex | European exchange (CBOE Europe) |
| 5 | LSE PLC | London Stock Exchange |
| 6 | Xetra | Deutsche Boerse electronic platform |
| 7 | Euronext | Pan-European exchange |
| 8 | DFM | Dubai Financial Market |
| 9 | HKEX | Hong Kong Exchange |
| 10 | TMX | Toronto/Montreal exchange |
| 11 | ADX | Abu Dhabi Securities Exchange |
| 12 | BME | Spanish stock exchange |
| 13 | Nasdaq Nordic | Nordic markets |
| 14 | CBOE Japan | Japan exchange via CBOE |
| 15 | SGX | Singapore Exchange |
| 16 | TWSE | Taiwan Stock Exchange |
| 17 | CBOE EU | CBOE European operations |
| 18 | CBOE AUS | CBOE Australian operations |
| 19 | Wiener Borse | Vienna Stock Exchange |
| 20 | Prague SE | Prague Stock Exchange |
| 21 | Warsaw SE | Warsaw Stock Exchange |
| 22 | Budapest SE | Budapest Stock Exchange |
| 27 | NSE | National Stock Exchange (India) |
| 28 | Nasdaq Baltic | Baltic markets |
| 29 | KRX | Korea Exchange |
| 30 | Blue Ocean | After-hours US trading venue |

### 2.3 Managed Write Operations - SP-Controlled with Context Capture

**What**: All modifications to Price.LiquidityProviderPriceSource are channeled through dedicated stored procedures that validate inputs and optionally capture the operator identity via context_info.

**Rules**:
- Price.InsertLiquidityProviderPriceSource: new LP-to-source mapping. Sets context_info if @AppLoginName != ''. No duplicate allowed.
- Price.UpdateLiquidityProviderPriceSource: changes PriceSourceID for an existing LP. Sets context_info if @AppLoginName != ''. Mapping must already exist.
- Price.DeleteLiquidityProviderPriceSource: removes a mapping. Generates temporal history.
- AppLoginName in history: populated only when SPs are called with a non-empty @AppLoginName parameter. NULL for automated or direct SQL changes.
- Both SPs return the affected record (joined with Trade.LiquidityProviders and Dictionary.PriceSourceName) for confirmation.

### 2.4 No INSERT Trigger - History Coverage Gap

**What**: Price.LiquidityProviderPriceSource does NOT have an INSERT trigger to force new mappings into temporal history. This is different from similar tables in the system.

**Rules**:
- An LP's initial price source assignment (INSERT) does NOT appear in History.LiquidityProviderPriceSource
- Only subsequent changes (UPDATE -> source changed) and removals (DELETE) generate history rows
- To see the full lifecycle: combine history rows with the current live table row
- This gap means it is impossible to determine the initial price source assignment date from history alone

---

## 3. Data Overview

0 rows in test environment. In production, rows represent each time an LP's price source was changed or the mapping was removed.

**Expected production patterns**:
- Each row pairs one LiquidityProviderID with the PriceSourceID it was previously assigned to
- ValidForSec = SysEndTime - SysStartTime shows how long the LP used that price source
- Clusters of SysEndTime changes indicate batch LP migrations (e.g., moving multiple LPs from one exchange feed to another)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityProviderID | int | NO | - | CODE-BACKED | The liquidity provider instance whose price source changed. Matches Trade.LiquidityProviders.LiquidityProviderID. FK enforced on live table (not in history). PK on live table - one row per LP per time period in history. References LPs documented in History.LiquidityProviders. |
| 2 | PriceSourceID | int | NO | - | CODE-BACKED | The price data source this LP was previously assigned to. FK to Dictionary.PriceSourceName on live table (not in history). Full enum: 0=eToro, 1=Xignite, 2=CME, 3=NASDAQ, 4=Chi-Ex, 5=LSE PLC, 6=Xetra, 7=Euronext, 8=DFM, 9=HKEX, 10=TMX, 11=ADX, 12=BME, 13=Nasdaq Nordic, 14=CBOE Japan, 15=SGX, 16=TWSE, 17=CBOE EU, 18=CBOE AUS, 19=Wiener Borse, 20=Prague SE, 21=Warsaw SE, 22=Budapest SE, 27=NSE, 28=Nasdaq Baltic, 29=KRX, 30=Blue Ocean. |
| 3 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that changed this LP-to-price-source mapping. Computed column on live table (= suser_name()); stored as snapshot in history. Identifies the database session that executed the INSERT/UPDATE/DELETE (via stored procedure). |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level identity of the operator who changed the mapping. Computed column on live table (= CONVERT(varchar(500), context_info())). Populated when the calling stored procedure received a non-empty @AppLoginName parameter and set context_info accordingly. NULL when context_info was not set. varchar(50) input truncated to 128-byte varbinary then stored as varchar(500). |
| 5 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this LP-to-price-source assignment became active in Price.LiquidityProviderPriceSource. Set automatically by SQL Server SYSTEM_VERSIONING. The clustered index (SysEndTime, SysStartTime) optimizes temporal range queries. |
| 6 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this LP's price source assignment was changed or removed. For all history rows, always a past timestamp. The duration [SysStartTime, SysEndTime) shows how long this LP used this price source before it was reassigned. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityProviderID | Trade.LiquidityProviders | Implicit | FK enforced on live table; not in history. The LP instance whose price source changed. History in History.LiquidityProviders. |
| PriceSourceID | Dictionary.PriceSourceName | Implicit | FK enforced on live table; not in history. The price feed/exchange source previously assigned. 30 named sources. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.LiquidityProviderPriceSource | SYSTEM_VERSIONING | Writer (automatic) | Live temporal table - SQL Server archives old mappings here on UPDATE/DELETE |
| Price.UpdateLiquidityProviderPriceSource | PriceSourceID | Writer (indirect) | Updates live table, triggering temporal archival of the old mapping |
| Price.DeleteLiquidityProviderPriceSource | LiquidityProviderID | Writer (indirect) | Deletes from live table, triggering temporal archival of the deleted mapping |

---

## 6. Dependencies

```
History.LiquidityProviderPriceSource (table)
  - No code-level dependencies (temporal history leaf table)
  - Source: Price.LiquidityProviderPriceSource (live temporal table, SYSTEM_VERSIONING = ON)
    - FK dependencies on live table: Trade.LiquidityProviders, Dictionary.PriceSourceName
    - Writers: Price.InsertLiquidityProviderPriceSource (INSERT - does NOT appear in history)
               Price.UpdateLiquidityProviderPriceSource (UPDATE -> generates history)
               Price.DeleteLiquidityProviderPriceSource (DELETE -> generates history)
    - Reader: Price.GetAllLiquidityProviderPriceSource
    - No INSERT trigger: initial LP creation does NOT appear in this history table
```

### 6.1 Objects This Depends On

No dependencies. Populated automatically by temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.LiquidityProviderPriceSource | Table | Live temporal table - this is its HISTORY_TABLE |
| Price.GetAllLiquidityProviderPriceSource | Stored Procedure | Reader of live table (audit of all current mappings) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_LiquidityProviderPriceSource | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression applied. ON [MAIN] filegroup.

### 7.2 Constraints

No constraints on history table. Price.LiquidityProviderPriceSource live table: CLUSTERED PK on LiquidityProviderID (FILLFACTOR=90), NC on PriceSourceID (FILLFACTOR=90); FK_LiquidityProviderPriceSource_LiquidityProvider (LiquidityProviderID -> Trade.LiquidityProviders); FK_LiquidityProviderPriceSource_PriceSource (PriceSourceID -> Dictionary.PriceSourceName).

---

## 8. Sample Queries

### 8.1 Full price source assignment history for a specific LP

```sql
SELECT LiquidityProviderID, PriceSourceID,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime,
       DATEDIFF(DAY, SysStartTime, SysEndTime) AS ValidForDays
FROM [History].[LiquidityProviderPriceSource] WITH (NOLOCK)
WHERE LiquidityProviderID = @LiquidityProviderID
UNION ALL
SELECT LiquidityProviderID, PriceSourceID,
       DbLoginName, AppLoginName, SysStartTime, SysEndTime, NULL
FROM [Price].[LiquidityProviderPriceSource] WITH (NOLOCK)
WHERE LiquidityProviderID = @LiquidityProviderID
ORDER BY SysStartTime ASC
```

### 8.2 LPs that switched price sources (historical reassignments)

```sql
SELECT h.LiquidityProviderID,
       h.PriceSourceID AS OldPriceSourceID,
       h.SysEndTime AS ChangedAt,
       h.DbLoginName AS ChangedBy
FROM [History].[LiquidityProviderPriceSource] h WITH (NOLOCK)
ORDER BY h.SysEndTime DESC
```

### 8.3 Current LP-to-price-source assignments with names

```sql
SELECT lps.LiquidityProviderID,
       lp.LiquidityProviderName,
       lps.PriceSourceID,
       psn.Name AS PriceSourceName,
       lps.DbLoginName,
       lps.SysStartTime AS AssignedSince
FROM [Price].[LiquidityProviderPriceSource] lps WITH (NOLOCK)
INNER JOIN [Trade].[LiquidityProviders] lp WITH (NOLOCK) ON lp.LiquidityProviderID = lps.LiquidityProviderID
INNER JOIN [Dictionary].[PriceSourceName] psn WITH (NOLOCK) ON psn.PriceSourceID = lps.PriceSourceID
ORDER BY lp.LiquidityProviderName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Price.InsertLiquidityProviderPriceSource, Price.UpdateLiquidityProviderPriceSource) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.LiquidityProviderPriceSource | Type: Table | Source: etoro/etoro/History/Tables/History.LiquidityProviderPriceSource.sql*
