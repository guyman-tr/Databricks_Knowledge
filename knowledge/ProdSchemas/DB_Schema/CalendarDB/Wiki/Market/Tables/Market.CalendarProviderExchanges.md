# Market.CalendarProviderExchanges

> Registry that maps calendar data providers to the specific exchanges they cover, storing each exchange's Xignite-assigned ID and its ISO MIC code.

| Property | Value |
|----------|-------|
| **Schema** | Market |
| **Object Type** | Table |
| **Key Identifier** | (ProviderID, ExchangeID) composite PK |
| **Partition** | No |
| **Indexes** | 1 (composite PK clustered) |

---

## 1. Business Meaning

`Market.CalendarProviderExchanges` is the registration table that defines which stock exchanges are covered by each calendar data provider. It acts as the canonical mapping between a provider (such as Xignite), the provider's internal numeric exchange identifier (`ExchangeID`), and the exchange's standardized ISO 10383 Market Identifier Code (MIC) stored in `ExchangeName` — for example, `XNAS` for NASDAQ, `XLON` for the London Stock Exchange, or `XETR` for Deutsche Börse XETRA.

This table is the foundational configuration layer for the exchange calendar system. Without a `(ProviderID, ExchangeID)` entry here, no daily schedule data from that provider can be attributed to a known exchange. It defines the universe of exchanges for which the CalendarDB system is expected to receive and store open/close schedule data.

Data flows as follows: when a calendar ingestion service receives exchange schedule data from a provider (such as Xignite's API), it uses the registered `ExchangeID` values from this table to identify which exchange each schedule record belongs to. It then calls `Market.SetProviderExchangeCalendarBulk` (which takes `@ProviderID` and a TVP containing `ExchangeID`-keyed schedule records) to write those schedules into `Market.ProvidersExchangeDailySchedules`. This table was initially populated in bulk on 2026-03-05 with 27 Xignite exchanges. No eToro (ProviderID=0) exchanges are currently registered.

---

## 2. Business Logic

### 2.1 Provider-Specific Exchange Identification

**What**: Each provider maintains its own internal numbering system for exchanges. The same real-world stock exchange may have multiple internal IDs assigned by a data provider.

**Columns/Parameters Involved**: `ProviderID`, `ExchangeID`, `ExchangeName`

**Rules**:
- `ExchangeID` is the provider's internal identifier for an exchange — not a universal standard. For Xignite, the same MIC code can map to multiple `ExchangeID` values, representing different trading segments, listing tiers, or product classes within the same physical exchange.
- `ExchangeName` stores the ISO 10383 MIC code (e.g., `XNYS`, `XNAS`) — the standardized international identifier for the venue. Multiple `ExchangeID` values can share the same MIC (e.g., XNYS appears for ExchangeIDs 5, 19, 20, and 33 — reflecting NYSE's different trading segments as defined in Xignite's data model).
- The composite primary key `(ProviderID, ExchangeID)` enforces that each provider's exchange ID is unique within that provider, but the same ExchangeID could theoretically belong to different providers (without conflict).
- All 27 registered exchanges belong to ProviderID=1 (Xignite). ProviderID=0 (eToro) has no registered exchanges, meaning eToro's own calendar data either uses a different pathway or has not been onboarded.

**Diagram**:
```
Real-world Exchange: NYSE (New York Stock Exchange)
    ↓ Xignite assigns multiple segment IDs
ExchangeID=5  → ExchangeName="XNYS" (ProviderID=1)
ExchangeID=19 → ExchangeName="XNYS" (ProviderID=1)
ExchangeID=20 → ExchangeName="XNYS" (ProviderID=1)
ExchangeID=33 → ExchangeName="XNYS" (ProviderID=1)
    ↓ Each has its own schedule entries
Market.ProvidersExchangeDailySchedules (per ExchangeID + Date)
```

### 2.2 Temporal Audit via Trigger + System Versioning

**What**: Every add, change, or removal of a provider-exchange registration is automatically logged for full temporal auditability.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`, `SysStartTime`, `SysEndTime`

**Rules**:
- SQL Server manages `SysStartTime` and `SysEndTime` automatically. Active registrations always have `SysEndTime = '9999-12-31 23:59:59.9999999'`.
- The `TRG_T_CalendarProviderExchanges` INSERT trigger performs a self-referential UPDATE immediately after any INSERT to force the temporal system to log the new record into `History.CalendarProviderExchanges`.
- `DbLoginName` captures the SQL Server login (`suser_name()`) of the session that performed the write.
- `AppLoginName` captures the application session identity (`context_info()`) — a GUID identifying the specific service instance that made the registration change.
- Historical versions of all exchange registrations are preserved in `History.CalendarProviderExchanges` with PAGE compression.

**Diagram**:
```
INSERT (ProviderID=1, ExchangeID=4, ExchangeName="XNAS")
    ↓
TRG_T_CalendarProviderExchanges fires (self-update)
    ↓
Temporal system writes to History.CalendarProviderExchanges
    ↓
Current row stays in Market.CalendarProviderExchanges
```

### 2.3 Current Exchange Coverage (Reference)

**What**: The complete set of exchanges currently registered for Xignite (ProviderID=1), expressed as ISO MIC codes.

**Exchanges covered**:
- **Americas**: XNAS (NASDAQ), XNYS (NYSE, 4 segments)
- **Europe**: XLON (London), XPAR (Paris), XMAD (Madrid), XMIL (Milan), XSWX (Swiss), XOSL (Oslo), XSTO (Stockholm), XCSE (Copenhagen), XHEL (Helsinki), XLIS (Lisbon), XBRU (Brussels), XAMS (Amsterdam), XWBO (Vienna), XDUB (Dublin), XPRA (Prague), XWAR (Warsaw), XBUD (Budapest), XETR (XETRA/Frankfurt)
- **Middle East**: XSAU (Saudi Exchange/Tadawul), XDFM (Dubai Financial Market, 2 segments)
- **Asia-Pacific**: XASX (ASX Australia)

---

## 3. Data Overview

Representative rows from the 27 registered exchanges (all added 2026-03-05 by Xignite onboarding):

| ProviderID | ExchangeID | ExchangeName | Meaning |
|---|---|---|---|
| 1 | 4 | XNAS | Xignite's ID for NASDAQ — the primary US technology stock exchange. eToro offers many NASDAQ-listed stocks (e.g., Apple, Microsoft, Amazon). Schedule data from this ID drives NASDAQ trading hours in the platform. |
| 1 | 5 | XNYS | Xignite's first segment ID for NYSE. The New York Stock Exchange, the world's largest equity exchange by market cap. Multiple NYSE IDs (5, 19, 20, 33) reflect distinct Xignite product segments for this venue. |
| 1 | 7 | XLON | London Stock Exchange. Drives trading hours for UK-listed stocks (BP, HSBC, Unilever, etc.). Important for eToro's European customer base. |
| 1 | 38 | XETR | Deutsche Börse XETRA electronic trading platform — the main German equity exchange. Covers stocks like SAP, BMW, Volkswagen, Deutsche Bank. |
| 1 | 24 | XSAU | Saudi Exchange (Tadawul) — the primary stock exchange of Saudi Arabia. Reflects eToro's Middle East market expansion. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ProviderID | int | NO | — | CODE-BACKED | Identifies the calendar data provider that covers this exchange. Part 1 of composite PK. References `Market.CalenderProviders`: `0 = eToro` (internal, no exchanges currently registered), `1 = Xignite` (third-party financial data API, all 27 current entries). Used as `@ProviderID` parameter in `Market.SetProviderExchangeCalendarBulk` to route schedule bulk-loads to the correct provider's registration. |
| 2 | ExchangeID | int | NO | — | CODE-BACKED | Provider-internal numeric identifier for the exchange. Part 2 of composite PK. This is Xignite's own ID — not a universal standard. Values are non-sequential (4, 5, 7, 9...) reflecting Xignite's internal exchange catalog. The same real-world exchange may appear under multiple `ExchangeID` values representing different trading segments (e.g., NYSE appears as IDs 5, 19, 20, and 33). Used in `Market.ProviderExchangeCalendarTable` TVP when calling `Market.SetProviderExchangeCalendarBulk` to write daily schedules into `Market.ProvidersExchangeDailySchedules`. Also used as `@ExchangeID` parameter in `Market.SetPureProviderExchangeCalendarBulk` and `Market.ExchangeTimeZones` (PK). |
| 3 | ExchangeName | varchar(250) | NO | — | CODE-BACKED | ISO 10383 Market Identifier Code (MIC) for the exchange venue. Examples: `XNAS` = NASDAQ, `XNYS` = New York Stock Exchange, `XLON` = London Stock Exchange, `XPAR` = Euronext Paris, `XMAD` = Bolsa de Madrid, `XETR` = Deutsche Börse XETRA, `XASX` = ASX Australia. Multiple `ExchangeID` values can share the same MIC (e.g., `XNYS` appears 4 times, `XDFM` appears 2 times), representing different Xignite-assigned sub-segments of the same exchange. Note: this is a denormalized copy of the MIC for convenience — there is no separate Exchange master table in CalendarDB. |
| 4 | DbLoginName | varchar (computed) | NO | — | CODE-BACKED | Computed column: `suser_name()`. Captures the SQL Server login name of the session that last wrote to this row. Read-only; set automatically on every insert or update. Shows which service account or DBA registered or modified this provider-exchange mapping. |
| 5 | AppLoginName | varchar(500) (computed) | NO | — | CODE-BACKED | Computed column: `CONVERT(varchar(500), context_info())`. Captures the application-level session identity stored in SQL Server's `context_info` buffer. The calling application sets this to a session GUID before executing, enabling attribution of registration changes to specific service instances or deployment versions. |
| 6 | SysStartTime | datetime2(7) | NO | `getutcdate()` | CODE-BACKED | Temporal ROW START column managed by SQL Server. Records the UTC timestamp when this version of the provider-exchange registration became current. All current rows show `2026-03-05T12:55:37` (the initial bulk registration date). Used to query historical registration state via `History.CalendarProviderExchanges`. |
| 7 | SysEndTime | datetime2(7) | NO | `9999-12-31 23:59:59.9999999` | CODE-BACKED | Temporal ROW END column managed by SQL Server. Active registrations always have this set to `9999-12-31 23:59:59.9999999`. When a registration is removed or changed, the prior version is moved to `History.CalendarProviderExchanges` with this column set to the removal timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID | Market.CalenderProviders | Implicit FK | Each registration belongs to one provider. ProviderID here must match a ProviderID in CalenderProviders (0=eToro, 1=Xignite). No DDL constraint enforced. |
| ExchangeID | Market.ExchangeTimeZones | Implicit FK | ExchangeID is the PK of ExchangeTimeZones — each registered exchange should have a corresponding timezone entry. |
| ExchangeID | Market.ProvidersExchangeDailySchedules | Lookup relationship | ExchangeID registered here flows into the daily schedule table via SetProviderExchangeCalendarBulk, linking calendar data to known exchanges. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Market.ProvidersExchangeDailySchedules | (ProviderID, ExchangeID) | Implicit FK | Daily open/close schedule records are attributed to the provider-exchange combination registered here. |
| Market.SetProviderExchangeCalendarBulk | @ProviderID + ExchangeID (via TVP) | Parameter / Lookup | Takes @ProviderID and exchange schedule data (with ExchangeIDs) and writes to ProvidersExchangeDailySchedules. The ExchangeIDs in the TVP should match registered entries here. |
| History.CalendarProviderExchanges | (ProviderID, ExchangeID) | Temporal history | Automatically maintained by SQL Server system versioning — stores prior versions of all registrations. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Market.CalendarProviderExchanges (table)
└── Market.CalenderProviders (table) [ProviderID — implicit FK, no code dependency]
```

> Note: Tables are leaf nodes in the code dependency chain. The relationship to `Market.CalenderProviders` is an implicit FK reference (no executable FROM/JOIN in DDL), so it appears in Section 5 (Relationships) rather than as a code-level dependency above.

This object has no code-level dependencies.

---

### 6.1 Objects This Depends On

No dependencies. (The implicit FK to `Market.CalenderProviders` is a relationship, not a DDL-level dependency.)

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Market.ProvidersExchangeDailySchedules | Table | References (ProviderID, ExchangeID) — each daily schedule entry belongs to a registered provider-exchange pair |
| History.CalendarProviderExchanges | Table | Temporal history table — automatically receives prior versions of all rows on any change |
| Market.SetProviderExchangeCalendarBulk | Stored Procedure | Takes @ProviderID and ExchangeID-keyed schedule data; ExchangeIDs should match entries registered here |
| Market.SetPureProviderExchangeCalendarBulk | Stored Procedure | Takes @ExchangeID directly; ExchangeID should be a registered exchange |
| Market.ExchangeTimeZones | Table | Shares ExchangeID space — each registered exchange should have a timezone entry |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_CalendarProviderToExchange | CLUSTERED PK | ProviderID ASC, ExchangeID ASC | — | — | Active |

**History table index** (`History.CalendarProviderExchanges`):
- `ix_CalendarProviderExchanges` — CLUSTERED on (SysEndTime ASC, SysStartTime ASC) with PAGE compression. Optimized for temporal queries that filter by time range.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| pk_CalendarProviderToExchange | PRIMARY KEY | Composite key (ProviderID, ExchangeID) — one registration per provider per exchange ID. Prevents duplicate exchange registrations for the same provider. |
| DF_CalendarProviderExchanges_SysStart | DEFAULT | `SysStartTime` defaults to `getutcdate()` — records UTC creation timestamp when a new exchange is registered. |
| DF_CalendarProviderExchanges_SysEnd | DEFAULT | `SysEndTime` defaults to `'9999-12-31 23:59:59.9999999'` — marks new registrations as currently active. |

**Trigger**: `TRG_T_CalendarProviderExchanges` — fires FOR INSERT. Performs a self-referential no-op UPDATE (`SET ProviderID = ProviderID`) to force the SQL Server temporal versioning engine to write an audit entry to `History.CalendarProviderExchanges` for every new registration, ensuring INSERTs are audited alongside UPDATEs.

---

## 8. Sample Queries

### 8.1 List all registered exchanges with provider names
```sql
SELECT cp.ProviderName,
       cpe.ExchangeID,
       cpe.ExchangeName AS MICCode
FROM [Market].[CalendarProviderExchanges] cpe WITH (NOLOCK)
INNER JOIN [Market].[CalenderProviders] cp WITH (NOLOCK)
    ON cpe.ProviderID = cp.ProviderID
ORDER BY cp.ProviderName, cpe.ExchangeName, cpe.ExchangeID;
```

### 8.2 Find exchanges where the same MIC has multiple Xignite IDs
```sql
SELECT ExchangeName AS MICCode,
       COUNT(*) AS SegmentCount,
       STRING_AGG(CAST(ExchangeID AS varchar), ', ') AS ExchangeIDs
FROM [Market].[CalendarProviderExchanges] WITH (NOLOCK)
WHERE ProviderID = 1
GROUP BY ExchangeName
HAVING COUNT(*) > 1
ORDER BY SegmentCount DESC;
```

### 8.3 Check registration history for an exchange
```sql
SELECT h.ProviderID, h.ExchangeID, h.ExchangeName,
       h.SysStartTime, h.SysEndTime,
       h.DbLoginName
FROM [History].[CalendarProviderExchanges] h WITH (NOLOCK)
WHERE h.ExchangeID = 4  -- Replace with ExchangeID to audit
ORDER BY h.SysStartTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: — | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Market.CalendarProviderExchanges | Type: Table | Source: CalendarDB/CalendarDB/Market/Tables/Market.CalendarProviderExchanges.sql*
