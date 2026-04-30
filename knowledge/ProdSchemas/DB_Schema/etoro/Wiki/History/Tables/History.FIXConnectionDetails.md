# History.FIXConnectionDetails

> SQL Server system-versioned temporal history table for Hedge.FIXConnectionDetails, recording every change to the key-value FIX protocol parameters that configure each liquidity provider connection in eToro's hedging engine.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (ID, SysStartTime, SysEndTime) - no formal PK; temporal history semantics |
| **Partition** | No (stored on [MAIN] filegroup) |
| **Indexes** | 1 (CLUSTERED on SysEndTime ASC, SysStartTime ASC, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

This table is the automatically maintained historical version store for `Hedge.FIXConnectionDetails`. SQL Server's system-versioning manages this table transparently: whenever a row in `Hedge.FIXConnectionDetails` is inserted, updated, or deleted, the previous row state is written here with SysStartTime/SysEndTime bracketing the validity window.

`Hedge.FIXConnectionDetails` stores the individual configuration parameters for each FIX protocol session as a key-value store. Each row in `Hedge.FIXConnectionDetails` represents a single named parameter (Section + Key) with its value for a specific ConnectionID. The three sections map directly to a QuickFIX/n (or equivalent FIX engine library) configuration format:

- **General**: TCP transport parameters - Host, Port, Heartbeat interval, reconnect behavior, message logging
- **FIX**: FIX protocol identity fields - SenderCompID, TargetCompID, SenderSubID, TargetSubID, OnBehalfOfCompID, DeliverToCompID, PartyID
- **Encryption**: TLS/SSL parameters - Encrypt flag, Certificate, CertificateKey, CACertificate, CertificateFolder

When `Hedge.GetFIXConnectionDetails` is called with a ConnectionID, it returns all current Section/Key/Value rows for that connection; the FIX engine reads these to establish the session with the counterparty. The history table provides an audit trail of every parameter change - enabling reconstruction of exactly which Host, Port, SenderCompID, and Certificate were in use for any given FIX session at any point in time.

232 history rows span ConnectionIDs for multiple liquidity providers (ZBFX variants, Trafix UAT, DLT, Citadel, JPM, Marex, Virtu, BLP, Talos, internal market makers).

---

## 2. Business Logic

### 2.1 Key-Value Parameter Store per Connection

**What**: Each FIX connection's configuration is stored as multiple rows - one row per Section/Key pair. The (ConnectionID, Section, Key) triplet is the natural unique key for a current parameter value.

**Columns/Parameters Involved**: `ConnectionID`, `Section`, `Key`, `Value`

**Rules**:
- ConnectionID is the FK to Hedge.FIXConnections (the parent connection registry row)
- One ConnectionID has multiple rows: typically 6-8 General params + 2-4 FIX identity params + 0-5 Encryption params depending on whether the connection uses TLS
- The INSERT trigger join uses (ConnectionID, Section, Key) to correctly match which existing row to force-update when a new parameter row is created
- Hedge.GetFIXConnectionDetails returns ALL rows for a ConnectionID: `SELECT ConnectionID, Section, Key, Value FROM Hedge.FIXConnectionDetails WHERE ConnectionID = @ConnectionID`
- Observed distinct Section/Key combinations across all history: 3 sections, 18 distinct keys

**Known Parameter Dictionary**:

| Section | Key | Observed Values | Meaning |
|---------|-----|-----------------|---------|
| General | Host | IP addresses, hostnames | TCP host for counterparty FIX server |
| General | Port | 1053, 5001, 8228, 8585, 8945, 9089, 9090, 9999, 14920, 22318 | TCP port for FIX session |
| General | Heartbeat | 30, 60 | FIX heartbeat interval in seconds (FIX tag 108) |
| General | ReconnectAttempts | 5, 100, 9999 | Max reconnect retries on disconnection (9999=effectively infinite) |
| General | ReconnectIntervalSec | 5, 30, 60 | Seconds between reconnect attempts |
| General | LogInboundMessages | True | Whether to log incoming FIX messages |
| FIX | SenderCompID | TRAFIXUAT, ZBFX_Price1_client2, ETORHYB5, eToroDHedge22, ... | eToro's identity on this FIX session (FIX tag 49) |
| FIX | TargetCompID | ZBFX, ZBFX7, TRAFIXUAT, TALOS, BLPUAT, DEMO4-FD-DEAL, ... | Counterparty's identity (FIX tag 56) |
| FIX | SenderSubID | DLTSubID, eToroDHedge22, eToroDHedge23 | eToro's sub-identifier (FIX tag 50) |
| FIX | TargetSubID | MNGD, eToro.Pool | Counterparty sub-identifier (FIX tag 57) |
| FIX | OnBehalfOfCompID | ETORO | Client identity for intermediary routing (FIX tag 115) |
| FIX | DeliverToCompID | APCC, CDRG | Delivery target in multi-leg routing (FIX tag 128) |
| FIX | PartyID | ErezAccount | Additional party identification |
| Encryption | Encrypt | True | Enable TLS for this connection |
| Encryption | Certificate | cert-edf5, citadel-etoro-cert.crt, dlt-etoro-cert.crt, ... | Client TLS certificate filename |
| Encryption | CertificateKey | citadel-etoro-key.key, dlt-etoro-key.key, sandbox-*.pem, ... | Private key filename for client cert |
| Encryption | CACertificate | CACerts-citadel-etoro-key.key, eToro-Cert.pem, Test1CACerts.pem | CA cert file for verifying counterparty |
| Encryption | CertificateFolder | .\\Cert | Relative path to certificate directory |

### 2.2 SQL Server Temporal + INSERT Trigger Capture

**What**: Standard dual-capture pattern - temporal versioning for UPDATE/DELETE, INSERT trigger for creation events.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `DbLoginName`, `AppLoginName`

**Rules**:
- INSERT trigger `TRG_T_FIXConnectionDetails` fires a no-op UPDATE (SET ConnectionID=ConnectionID) on the matching (ConnectionID, Section, Key) row to force SQL Server to write the just-inserted row into this history table
- The trigger join uses (ConnectionID, Section, Key) as the match key - not the IDENTITY ID - correctly targeting only the newly inserted parameter row
- AppLoginName format: "username;ConfigurationManager" padded with null bytes from context_info() - identifying Configuration Manager tool changes
- When AppLoginName is NULL, the change was made directly via SQL (e.g., DevTradingSTG service account)
- Zero-duration history rows (SysStartTime = SysEndTime) are INSERT trigger captures

### 2.3 Connection Configuration Versioning Pattern

**What**: Because each parameter is stored as a separate row, a single logical "reconfigure connection" operation generates multiple history rows - one per changed parameter.

**Rules**:
- Changing SenderCompID from "ETOROUAT" -> "TRAFIXUAT" generates one history row for that key
- Changing Host AND Port simultaneously generates two history rows (one per parameter), typically with matching or near-matching SysEndTime timestamps
- The history table ID is a bigint IDENTITY (not int) to accommodate potentially large volumes as many connections each have many parameters updated over time
- To reconstruct the complete parameter set for a connection at a point in time: use `FOR SYSTEM_TIME AS OF` on the source table or join history rows with overlapping validity windows

---

## 3. Data Overview

| ConnectionID | Section | Key | Value | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|
| 8 | FIX | SenderCompID | ETOROUAT | 2026-02-25 | 2026-03-02 | Version 1 of SenderCompID for ConnectionID=8 (Trafix UAT). Changed by dotanva via ConfigurationManager. |
| 8 | FIX | SenderCompID | TRAFIXUAT | 2026-03-02 | 2026-03-02 | Version 2 - SenderCompID updated (same duration = INSERT capture for new value). Changed by dotanva. |
| 8 | FIX | SenderCompID | " ETOROUAT3" | 2026-03-02 | 2026-03-18 | Version 3 - final value before superseded. Note leading space in value. Changed by DevTradingSTG (direct SQL). |
| 8 | FIX | TargetCompID | ETOROUAT | 2026-02-25 | 2026-03-02 | INSERT capture for initial TargetCompID. Then changed to ETOROUAT3 by dotanva. |
| 8 | General | Host | 74.217.55.230 | 2026-02-25 | 2026-03-02 | INSERT capture for TCP host. Superseded ~5 days later. |
| 8 | General | Port | 22318 | 2026-02-25 | 2026-03-02 | INSERT capture for TCP port 22318 (Trafix UAT). |
| 8 | General | ReconnectAttempts | 9999 | 2026-02-25 | 2026-02-25 | INSERT capture (zero-duration): effectively infinite reconnect configured. |
| 8 | General | Heartbeat | 30 | 2026-02-25 | 2026-02-25 | INSERT capture: 30-second FIX heartbeat interval. |

Distribution: 232 total history rows. General section: 127 rows (55%), FIX section: 76 rows (33%), Encryption section: 29 rows (12%).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | - | CODE-BACKED | Surrogate identifier from Hedge.FIXConnectionDetails IDENTITY PK. bigint (not int) to support high row volumes as multiple parameters per connection each accumulate history. Multiple history rows with the same ID represent successive value versions for that single Section/Key parameter. |
| 2 | ConnectionID | int | NO | - | CODE-BACKED | FK to Hedge.FIXConnections.ConnectionID. Groups all parameters belonging to a single FIX protocol session. Used as the primary lookup key in Hedge.GetFIXConnectionDetails. Multiple rows share the same ConnectionID (one per Section/Key pair). |
| 3 | Section | varchar(256) | YES | - | CODE-BACKED | Configuration section grouping for the parameter. Three observed values: "General" (TCP transport: Host, Port, Heartbeat, reconnect settings), "FIX" (protocol identity: SenderCompID, TargetCompID, sub-IDs), "Encryption" (TLS: certificates, keys, CA). Maps to QuickFIX/n-style INI config section headers. |
| 4 | Key | varchar(256) | YES | - | CODE-BACKED | Parameter name within the section. See Section 2.1 parameter dictionary for all 18 known keys. Unique within (ConnectionID, Section) for current rows in the source table. VARCHAR(256) accommodates future extension with new FIX engine parameter names. |
| 5 | Value | varchar(256) | YES | - | CODE-BACKED | Parameter value as a string. Interpretation depends on Section+Key context: IP address or hostname for General.Host, integer string for General.Port, certificate filename for Encryption.Certificate, FIX CompID string for FIX.SenderCompID. VARCHAR(256) - note the observed leading space in " ETOROUAT3" (SenderCompID with accidental leading space) indicating values are stored verbatim without trimming. |
| 6 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login (suser_name()) that made the change. Computed in source, materialized here. Examples: "TRAD\\dotanva" (hedging team operator), "DevTradingSTG" (dev/staging service account for direct SQL changes). |
| 7 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application context from context_info() at time of change. Format when set by Configuration Manager: "username;ConfigurationManager" followed by null-byte padding (e.g., "dotanva;ConfigurationManager\\0\\0..."). NULL when change was made directly via SQL without Configuration Manager (e.g., DevTradingSTG changes). |
| 8 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this parameter value version became active. For INSERT-trigger-captured rows, equals SysEndTime (zero-duration version). Precision to 100-nanosecond ticks allows ordering of near-simultaneous parameter changes within the same operation. |
| 9 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this parameter version was superseded. CLUSTERED index leading column for temporal range scans. SysEndTime = SysStartTime marks INSERT trigger capture events (creation records). Rows with DurationMs > 100 represent actual value changes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConnectionID | History.FIXConnections | Implicit | Each FIXConnectionDetails history row belongs to a FIX connection registered in History.FIXConnections. The connection header (Name, LiquidityAccountID, ScheduleID) is in FIXConnections; the detailed parameters (Host, Port, SenderCompID, etc.) are here. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.FIXConnectionDetails | SYSTEM_VERSIONING | Temporal history source | All superseded row versions routed here; INSERT trigger forces creation capture using (ConnectionID, Section, Key) match. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.FIXConnectionDetails (table)
- no code-level dependencies (leaf table, temporal history)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.FIXConnectionDetails | Table | Source temporal table |
| Hedge.GetFIXConnectionDetails | Stored Procedure | Reads source table (not history directly) by ConnectionID to retrieve all Section/Key/Value parameters for the FIX engine |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_FIXConnectionDetails | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active (DATA_COMPRESSION=PAGE, OPTIMIZE_FOR_SEQUENTIAL_KEY=OFF, on [MAIN] filegroup) |

### 7.2 Constraints

None. Temporal history tables have no PK, FK, CHECK, UNIQUE, or DEFAULT constraints.

### 7.3 Source Table Notes

- Hedge.FIXConnectionDetails has CLUSTERED PK on ID (bigint) with FILLFACTOR=90 and DATA_COMPRESSION=PAGE
- INSERT trigger TRG_T_FIXConnectionDetails matches on (ConnectionID, Section, Key) to correctly target the newly inserted row
- ID is bigint to accommodate potentially large volumes over many connections and parameters

---

## 8. Sample Queries

### 8.1 Full parameter set for a FIX connection at a specific point in time

```sql
SELECT
    fd.ConnectionID,
    fd.Section,
    fd.[Key],
    fd.[Value],
    fd.SysStartTime,
    fd.SysEndTime
FROM Hedge.FIXConnectionDetails FOR SYSTEM_TIME AS OF '2026-01-01T00:00:00' fd WITH (NOLOCK)
WHERE fd.ConnectionID = @ConnectionID
ORDER BY fd.Section, fd.[Key];
```

### 8.2 Change history for a specific parameter across all connections

```sql
SELECT
    h.ConnectionID,
    h.Section,
    h.[Key],
    h.[Value] AS OldValue,
    h.SysStartTime AS ValidFrom,
    h.SysEndTime AS ValidUntil,
    h.DbLoginName AS ChangedBy,
    LEFT(h.AppLoginName, CHARINDEX(';', h.AppLoginName + ';') - 1) AS OperatorName,
    DATEDIFF(HOUR, h.SysStartTime, h.SysEndTime) AS HoursActive
FROM History.FIXConnectionDetails h WITH (NOLOCK)
WHERE h.Section = 'General'
  AND h.[Key] = 'Host'
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100  -- exclude INSERT captures
ORDER BY h.ConnectionID, h.SysStartTime;
```

### 8.3 Reconstruct complete connection configuration at a point in time

```sql
-- Join FIXConnections header with FIXConnectionDetails parameters for a full picture
SELECT
    fc.ConnectionID,
    fc.Name AS ConnectionName,
    fc.LiquidityAccountID,
    fc.ScheduleID,
    fd.Section,
    fd.[Key],
    fd.[Value]
FROM Hedge.FIXConnections FOR SYSTEM_TIME AS OF '2026-01-01T00:00:00' fc WITH (NOLOCK)
JOIN Hedge.FIXConnectionDetails FOR SYSTEM_TIME AS OF '2026-01-01T00:00:00' fd WITH (NOLOCK)
    ON fd.ConnectionID = fc.ConnectionID
WHERE fc.ConnectionID = @ConnectionID
ORDER BY fd.Section, fd.[Key];
```

### 8.4 All parameter changes in a time window (operations audit)

```sql
SELECT
    h.ConnectionID,
    h.Section,
    h.[Key],
    h.[Value] AS OldValue,
    h.SysEndTime AS ChangeTime,
    h.DbLoginName AS ChangedBy,
    LEFT(h.AppLoginName, CHARINDEX(';', h.AppLoginName + ';') - 1) AS OperatorName
FROM History.FIXConnectionDetails h WITH (NOLOCK)
WHERE h.SysEndTime >= @StartDate
  AND h.SysEndTime < @EndDate
  AND DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) > 100
ORDER BY h.SysEndTime DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Hedge.GetFIXConnectionDetails) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.FIXConnectionDetails | Type: Table | Source: etoro/etoro/History/Tables/History.FIXConnectionDetails.sql*
