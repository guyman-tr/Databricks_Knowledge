# Hedge.GetFIXConnectionDetails

> Returns all FIX protocol session configuration parameters (Section/Key/Value triples) for a specific connection, used by the hedge server to initialize a FIX session.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ConnectionID - the FIX connection to retrieve settings for |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetFIXConnectionDetails loads the complete FIX protocol session configuration for a single connection. The hedge server calls this procedure at session startup (or on connection reload) to retrieve all parameters it needs to establish a FIX connection: the provider host and port (Section=General), the FIX identity SenderCompID/TargetCompID (Section=FIX), and TLS certificate paths if applicable (Section=Encryption).

The procedure exists because FIX session parameters are stored as a key-value store in Hedge.FIXConnectionDetails rather than as fixed columns. This design allows adding new configuration parameters without schema changes. The caller receives the full set of (Section, Key, Value) rows and assembles the FIX session configuration map in application code.

Called directly by the hedge server process during initialization; not called by any other stored procedures in the schema.

---

## 2. Business Logic

### 2.1 Configuration Section Structure

**What**: All FIX session parameters for a connection are organized into Section/Key/Value rows; the procedure returns all of them for the requested connection.

**Columns/Parameters Involved**: `ConnectionID`, `Section`, `Key`, `Value`

**Rules**:
- Three sections are observed: "General" (network settings), "FIX" (FIX identity), "Encryption" (TLS/SSL - not all connections).
- The procedure does not filter by Section - it returns ALL rows for the ConnectionID. The caller must process all sections.
- See Hedge.FIXConnectionDetails Section 2.1 for the full key inventory per section.

**Diagram**:
```
@ConnectionID = 1 (ZBFX Price1 Execution):
  General / Host                 -> 10.161.32.132
  General / Port                 -> 8945
  General / Heartbeat            -> 60
  General / ReconnectAttempts    -> 100
  General / ReconnectIntervalSec -> 5
  General / LogInboundMessages   -> true
  FIX     / SenderCompID         -> ZBFX_Price1_client2
  FIX     / TargetCompID         -> ZBFX
  Encryption / Encrypt           -> true
  ... (certificate paths)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ConnectionID | int | NO | - | CODE-BACKED | The FIX connection to retrieve settings for. References Hedge.FIXConnections.ConnectionID (implicit FK). E.g., 1=ZBFX Price1 Execution, 2=OMS UAT IM3. Passed by the hedge server at session init time. |

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | ConnectionID | int | NO | - | CODE-BACKED | The FIX connection identifier, echoed from the filter. All rows will have this same value (= @ConnectionID). |
| 3 | Section | varchar(256) | YES | - | CODE-BACKED | Configuration section grouping. Observed values: "General" (network/session behavior), "FIX" (FIX protocol identity), "Encryption" (TLS/SSL). Inherited from Hedge.FIXConnectionDetails.Section. |
| 4 | Key | varchar(256) | YES | - | CODE-BACKED | The parameter name within its Section. General keys: Host, Port, Heartbeat, ReconnectAttempts, ReconnectIntervalSec, LogInboundMessages. FIX keys: SenderCompID, TargetCompID. Encryption keys: Encrypt, Certificate, CertificateKey, CACertificate. Inherited from Hedge.FIXConnectionDetails.Key. |
| 5 | Value | varchar(256) | YES | - | CODE-BACKED | The configuration parameter value as a string. Numeric values (Port, Heartbeat) stored as strings. Boolean values as "true"/"false". Certificate paths as file system paths. Inherited from Hedge.FIXConnectionDetails.Value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ConnectionID filter | Hedge.FIXConnectionDetails | Lookup / Read | Retrieves all key-value settings for the FIX connection. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | ConnectionID | Caller | Hedge server reads FIX session config at startup; not called by any other SQL procedures. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetFIXConnectionDetails (procedure)
└── Hedge.FIXConnectionDetails (table)
      └── Hedge.FIXConnections (table) [implicit FK - ConnectionID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.FIXConnectionDetails | Table | SELECT all rows WHERE ConnectionID = @ConnectionID. Returns Section, Key, Value columns. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server (external) | Application | Calls at FIX session startup to load the full connection configuration. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute for the primary ZBFX connection

```sql
EXEC Hedge.GetFIXConnectionDetails @ConnectionID = 1;
```

### 8.2 Verify settings manually against the table

```sql
SELECT ConnectionID, [Section], [Key], [Value]
FROM   Hedge.FIXConnectionDetails WITH (NOLOCK)
WHERE  ConnectionID = 1
ORDER BY [Section], [Key];
```

### 8.3 Compare settings across two connections

```sql
SELECT a.Section, a.[Key], a.Value AS Conn1_Value, b.Value AS Conn2_Value
FROM   Hedge.FIXConnectionDetails a WITH (NOLOCK)
FULL JOIN Hedge.FIXConnectionDetails b WITH (NOLOCK)
    ON  b.ConnectionID = 2
    AND b.Section = a.Section
    AND b.[Key] = a.[Key]
WHERE  a.ConnectionID = 1
ORDER BY a.Section, a.[Key];
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetFIXConnectionDetails | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetFIXConnectionDetails.sql*
