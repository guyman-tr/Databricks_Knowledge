# Hedge.FIXConnectionDetails

> FIX protocol session configuration store: child key-value table of Hedge.FIXConnections holding all FIX session parameters (network, identity, security) as (Section, Key, Value) triples per connection; versioned via SQL Server temporal tables with INSERT trigger workaround.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ID bigint IDENTITY (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on ID) |
| **Temporal** | Yes - SYSTEM_VERSIONING ON (HISTORY_TABLE = History.FIXConnectionDetails) |

---

## 1. Business Meaning

Hedge.FIXConnectionDetails is the configuration store for all FIX protocol session parameters, organized as key-value pairs under named sections. Each row represents one configuration setting for one FIX connection, identified by (ConnectionID, Section, Key) -> Value. The hedge server reads these settings at startup (or on connection reload) to build the FIX session - host/port to connect to, FIX identity (SenderCompID/TargetCompID), heartbeat interval, reconnect policy, and TLS certificate paths.

The three observed Sections map to distinct configuration concerns:

| Section | Purpose | Keys |
|---------|---------|------|
| **General** | Network and session behavior | Host, Port, Heartbeat, ReconnectAttempts, ReconnectIntervalSec, LogInboundMessages |
| **FIX** | FIX protocol identity | SenderCompID (eToro's identifier), TargetCompID (provider's identifier) |
| **Encryption** | TLS/SSL configuration | Encrypt (true/false), Certificate, CertificateKey, CACertificate |

This is a standard configuration-as-data pattern: rather than hard-coding FIX session parameters in application config files or deployment manifests, they are stored in the database where they can be updated via SQL (with full temporal audit trail) without requiring application redeployment.

The 146 rows across 18 connections average ~8 settings per connection. Not all connections have an Encryption section - OMS UAT connections (ConnectionID 2-6) use fewer settings (only General + FIX, 5 rows each) while production connections like ZBFX Price1 (ConnectionID 1) use all three sections including Encryption (8 rows).

Like its parent Hedge.FIXConnections, this table uses SQL Server temporal SYSTEM_VERSIONING. A FOR INSERT trigger (TRG_T_FIXConnectionDetails) performs a no-op UPDATE matching on (ConnectionID, Section, Key) to force the temporal engine to capture SysStartTime on initial INSERT.

---

## 2. Business Logic

### 2.1 Section-Key-Value Configuration Structure

**What**: FIX session parameters are organized into logical sections, each containing a set of named keys with string values.

**Columns/Parameters Involved**: `ConnectionID`, `Section`, `Key`, `Value`

**Section: General** (78 keys across all connections):
- `Host`: IP address or hostname of the liquidity provider's FIX endpoint. E.g., "10.161.32.132" (ZBFX), "10.82.4.31" (OMS UAT providers).
- `Port`: TCP port for the FIX session. E.g., "8945" (ZBFX), "14920" (OMS UAT).
- `Heartbeat`: FIX heartbeat interval in seconds. "60" for ZBFX, "30" for OMS UAT connections.
- `ReconnectAttempts`: Number of reconnect attempts after disconnect. E.g., "100".
- `ReconnectIntervalSec`: Seconds between reconnect attempts. E.g., "5".
- `LogInboundMessages`: "true"/"false" - whether to log received FIX messages (ZBFX uses "true").

**Section: FIX** (50 keys across all connections):
- `SenderCompID`: eToro's FIX identifier in sessions with this provider. E.g., "ZBFX_Price1_client2" (ZBFX), "ETORO_INTERNAL_03_UAT" (OMS UAT IM3), "ETORO_STG_VIRTU_UAT" (Virtu).
- `TargetCompID`: The provider's FIX identifier. E.g., "ZBFX" (ZBFX provider), "HORIZON_DMA" (OMS/DMA connections), "ETORO_MAREX_UAT" (Marex).

**Section: Encryption** (18 keys across some connections):
- `Encrypt`: "true"/"false" - enables TLS for the FIX session.
- `Certificate`: Path to eToro's client certificate file.
- `CertificateKey`: Path to the private key for eToro's certificate.
- `CACertificate`: Path to the CA certificate for validating the provider's certificate.

### 2.2 Temporal Versioning with INSERT Trigger

**What**: Configuration changes are versioned; the INSERT trigger ensures new settings get a proper SysStartTime.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`, `TRG_T_FIXConnectionDetails`

**Rules**:
- The FOR INSERT trigger matches on `(ConnectionID, Section, Key)` - the logical unique key of a configuration setting - and performs a no-op UPDATE to force the temporal engine to set SysStartTime on INSERT.
- This is the same pattern as Hedge.FIXConnections: SQL Server temporal versioning does not capture a SysStartTime on INSERT without an explicit UPDATE.
- When a setting is changed (UPDATE), the old value is preserved in History.FIXConnectionDetails with the SysEndTime set to the change time.
- The temporal history allows point-in-time recovery: "what was the FIX host for ConnectionID 1 on date X?"

### 2.3 No Unique Constraint on (ConnectionID, Section, Key)

**What**: The DDL has no unique constraint on the logical key (ConnectionID, Section, Key), only a PK on auto-increment ID.

**Columns/Parameters Involved**: `ID`, `ConnectionID`, `Section`, `Key`

**Rules**:
- Duplicate (ConnectionID, Section, Key) rows are technically possible. The INSERT trigger matches on this triple for its no-op UPDATE, so duplicates would affect all matching rows.
- In practice, the application enforces uniqueness at the configuration level.
- Section and Key are both varchar(256) NULLABLE - though all observed rows have non-null Section and Key values.

---

## 3. Data Overview

146 rows | ~8 settings per connection | 3 sections

| ConnectionID | Section | Key | Value |
|---|---|---|---|
| 1 | FIX | SenderCompID | ZBFX_Price1_client2 |
| 1 | FIX | TargetCompID | ZBFX |
| 1 | General | Host | 10.161.32.132 |
| 1 | General | Port | 8945 |
| 1 | General | Heartbeat | 60 |
| 1 | General | ReconnectAttempts | 100 |
| 1 | General | ReconnectIntervalSec | 5 |
| 1 | General | LogInboundMessages | true |
| 2 | FIX | SenderCompID | ETORO_INTERNAL_03_UAT |
| 2 | FIX | TargetCompID | HORIZON_DMA |
| 2 | General | Host | 10.82.4.31 |
| 2 | General | Port | 14920 |
| 2 | General | Heartbeat | 30 |

Section distribution: General=78, FIX=50, Encryption=18

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-increment surrogate PK. CLUSTERED PK. Not meaningful for queries - use (ConnectionID, Section, Key) as the logical unique key. Bigint chosen for future volume, though 146 rows indicates low churn. |
| 2 | ConnectionID | int | NO | - | CODE-BACKED | FK (implicit) to Hedge.FIXConnections.ConnectionID. Identifies which FIX connection this setting belongs to. All settings for a connection share the same ConnectionID. Used by Hedge.GetFIXConnectionDetails to retrieve all settings for a given connection. |
| 3 | Section | varchar(256) | YES | - | CODE-BACKED | Configuration section grouping related keys. Three observed values: "General" (network/session settings), "FIX" (FIX protocol identity), "Encryption" (TLS/SSL config). Nullable in DDL but non-null in practice. |
| 4 | Key | varchar(256) | YES | - | CODE-BACKED | The configuration parameter name within its Section. General keys: Host, Port, Heartbeat, ReconnectAttempts, ReconnectIntervalSec, LogInboundMessages. FIX keys: SenderCompID, TargetCompID. Encryption keys: Encrypt, Certificate, CertificateKey, CACertificate. |
| 5 | Value | varchar(256) | YES | - | CODE-BACKED | The configuration parameter value as a string. Numeric values (Port, Heartbeat) are stored as strings. Boolean values ("true"/"false") are stored as strings. Certificate paths stored as full file path strings. Max 256 chars - sufficient for IPs, ports, FIX IDs, and certificate paths. |
| 6 | DbLoginName | varchar(computed) | - | suser_name() | CODE-BACKED | Computed column: SQL Server login name of the session that last wrote this row. Audit trail for who changed configuration. |
| 7 | AppLoginName | varchar(500, computed) | - | context_info() | CODE-BACKED | Computed column: Application identity from session context_info(). Complements DbLoginName with an application-level identifier. |
| 8 | SysStartTime | datetime2(7) | NO | GENERATED ALWAYS | CODE-BACKED | Temporal row start time (UTC). Populated on INSERT via the FOR INSERT trigger. Tracks when this configuration value became effective. |
| 9 | SysEndTime | datetime2(7) | NO | GENERATED ALWAYS | CODE-BACKED | Temporal row end time (UTC). Set to 9999-12-31 for current rows; set to actual end time in History.FIXConnectionDetails for superseded versions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ConnectionID | Hedge.FIXConnections | Implicit (no DDL FK) | Parent FIX connection this setting belongs to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetFIXConnectionDetails | @ConnectionID | Reader | Returns all settings for a connection; called by hedge server at session init |
| History.FIXConnectionDetails | - | Temporal history | Stores superseded configuration values (SYSTEM_VERSIONING) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.FIXConnectionDetails (temporal table)
  - Implicit FK: Hedge.FIXConnections (ConnectionID) [parent]
  - History: History.FIXConnectionDetails (temporal versioning)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.FIXConnections | Table | Parent - ConnectionID references the FIX connection being configured |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetFIXConnectionDetails | Procedure | Reads all settings for a ConnectionID |
| History.FIXConnectionDetails | Table | Temporal history table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Hedge_FIXConnectionDetails | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR=90, PAGE compression, MAIN filegroup) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Hedge_FIXConnectionDetails | PRIMARY KEY (CLUSTERED) | ID - surrogate PK |

### 7.3 Triggers

| Trigger Name | Event | Purpose |
|-------------|-------|---------|
| TRG_T_FIXConnectionDetails | FOR INSERT | No-op UPDATE matching on (ConnectionID, Section, Key) forces temporal engine to capture SysStartTime on initial INSERT. Same pattern as TRG_T_FIXConnections on parent table. |

---

## 8. Sample Queries

### 8.1 All settings for a specific FIX connection
```sql
SELECT Section, [Key], [Value]
FROM Hedge.FIXConnectionDetails WITH (NOLOCK)
WHERE ConnectionID = 1
ORDER BY Section, [Key];
```

### 8.2 All connections with their Host and Port
```sql
SELECT fc.Name, fc.ConnectionID,
       h.Value AS Host, p.Value AS Port
FROM Hedge.FIXConnections fc WITH (NOLOCK)
LEFT JOIN Hedge.FIXConnectionDetails h WITH (NOLOCK)
    ON h.ConnectionID = fc.ConnectionID AND h.Section = 'General' AND h.[Key] = 'Host'
LEFT JOIN Hedge.FIXConnectionDetails p WITH (NOLOCK)
    ON p.ConnectionID = fc.ConnectionID AND p.Section = 'General' AND p.[Key] = 'Port'
ORDER BY fc.ConnectionID;
```

### 8.3 All TLS-enabled connections
```sql
SELECT fc.Name, fc.ConnectionID, d.Value AS EncryptEnabled
FROM Hedge.FIXConnectionDetails d WITH (NOLOCK)
JOIN Hedge.FIXConnections fc WITH (NOLOCK) ON fc.ConnectionID = d.ConnectionID
WHERE d.Section = 'Encryption' AND d.[Key] = 'Encrypt'
ORDER BY fc.ConnectionID;
```

### 8.4 Configuration history for a specific setting
```sql
SELECT [Value], SysStartTime, SysEndTime
FROM Hedge.FIXConnectionDetails FOR SYSTEM_TIME ALL
WHERE ConnectionID = 1 AND Section = 'General' AND [Key] = 'Host'
ORDER BY SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for Hedge.FIXConnectionDetails.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.FIXConnectionDetails | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.FIXConnectionDetails.sql*
