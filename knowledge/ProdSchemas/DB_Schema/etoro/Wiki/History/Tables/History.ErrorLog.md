# History.ErrorLog

> Legacy system event log recording infrastructure errors and operational events from eToro's 2014 trading server components, using a template-based message system where structured error codes are combined with free-text parameter substitution strings.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ErrorLogID (int IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (CLUSTERED PK only) |

---

## 1. Business Meaning

This table is the centralized error and event log for eToro's server infrastructure circa 2014. Each row records a single event emitted by a server component: a severity level, the server entity that generated it, a reference to a structured message template in `Dictionary.ErrorMessage`, and a free-text `Parameters` string containing the runtime values to substitute into that template. Together, `ErrorMessageID + Parameters` reconstruct a human-readable event description.

Without this table, it would be impossible to answer audit questions such as "why did Instrument 17 go inactive on 2014-06-29?" or "when did PriceServer instance 702 register to the SCB cluster?" The CID column (nullable FK to Customer.CustomerStatic) allows customer-specific errors to be linked to an account, though in practice all 2,969 rows in this table have CID=NULL - all events are system-level, not customer-specific.

**Note**: Based on live data analysis, this table contains only 2,969 rows spanning 2014-06-19 to 2014-07-31 - it is a legacy artifact from eToro's 2014 infrastructure era. All rows originate from PriceServer instances (ServerTypeID=7). The designated writer `History.ErrorLogAdd` has its INSERT code commented out and is effectively dead. The only active writer is `Broker.actDispatcher`, which logs failed message delivery events. Modern system event logging does not appear to use this table.

---

## 2. Business Logic

### 2.1 Template-Based Message System

**What**: Structured event messages composed of a reusable template (in Dictionary.ErrorMessage) combined with runtime parameter values stored in History.ErrorLog.Parameters.

**Columns/Parameters Involved**: `ErrorMessageID`, `Parameters`

**Rules**:
- `Dictionary.ErrorMessage` stores message templates with placeholders: e.g., `"{instrument} set to inactive by {component}: {reason}"` (ErrorMessageID=73)
- `History.ErrorLog.Parameters` stores the runtime substitution values as a semicolon-delimited string: e.g., `"17;_TimeoutAdapter;availability changed"` resolves to Instrument 17, _TimeoutAdapter component, reason "availability changed"
- The `Dictionary.ErrorMessage` row also carries `ServerTypeID` and `ServerMessageID` linking it to the server component that generated the template, enabling filtering by server type
- In `Broker.actDispatcher`, this pattern is used as: INSERT with ErrorMessageID=1 ("Failed to deliver message {1} to port {2} on IP address {3}") and Parameters containing `"{errorMsg};{port};{IPAddress};"` for failed network deliveries

**Diagram**:
```
ErrorMessageID 73 -> Dictionary.ErrorMessage: "{instrument} set to inactive by {component}: {reason}"
Parameters:         "17;_TimeoutAdapter;availability changed"
Reconstructed:      "Instrument 17 set to inactive by _TimeoutAdapter: availability changed"

ErrorMessageID 49 -> Dictionary.ErrorMessage: "General message: {msg}"
Parameters:         "Registered to SCB at 10.160.46.11:50000"
Reconstructed:      "General message: Registered to SCB at 10.160.46.11:50000"
```

### 2.2 Severity Classification

**What**: Five-level severity hierarchy used to classify event importance, from fatal system failures down to verbose trace messages.

**Columns/Parameters Involved**: `SeverityTypeID`

**Rules**:
- SeverityTypeID 1 = Fatal: unrecoverable failure (0 rows in data - not reached in 2014 dataset)
- SeverityTypeID 2 = Error: recoverable failure (0 rows in data - Broker.actDispatcher would insert these for failed deliveries, but none occurred in the 2014 dataset)
- SeverityTypeID 3 = Warning: abnormal but non-fatal condition (296 rows - volatility spikes causing instrument state changes)
- SeverityTypeID 4 = Informatory: normal operational event (1,873 rows - majority; instrument active/inactive transitions)
- SeverityTypeID 5 = Verbose: detailed trace (800 rows - server registration and general messages)
- The live data shows no Fatal or Error rows; all 2,969 rows are Warning, Informatory, or Verbose

---

## 3. Data Overview

| ErrorLogID | SeverityTypeID | ErrorMessageID | Entity | Parameters | Meaning |
|---|---|---|---|---|---|
| 3862 | 5 (Verbose) | 49 (General message) | 702 | "Registered to SCB at 10.160.46.11:50000" | PriceServer instance 702 completed registration to the SCB (Shared Connection Broker) cluster node, emitting a verbose trace event. |
| 3857 | 4 (Informatory) | 73 (inactive by component) | 702 | "17;_TimeoutAdapter;availability changed" | Instrument 17 was marked inactive by the TimeoutAdapter component because its availability changed - a normal operational state transition recorded at Informatory level. |
| 3855 | 3 (Warning) | 73 (inactive by component) | 702 | "17;VolatilityAdapter;volatile (difference 87,87 pips)" | Instrument 17 was forced inactive by the VolatilityAdapter due to excessive price volatility (87.87 pip difference) - a Warning-level event because volatility-driven suspension is abnormal. |
| 3854 | 4 (Informatory) | 60 (active) | 702 | "17" | Instrument 17 was marked active (returned to tradeable state) - a simple activation event with only the instrument ID as parameter. |
| 3858 | 4 (Informatory) | 61 (inactive) | 702 | "17" | Instrument 17 was marked inactive - transition to non-tradeable state. Paired with an activation event (ErrorLogID 3854) within seconds, indicating a brief connectivity disruption. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ErrorLogID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Auto-incrementing unique identifier for each event log entry. NOT FOR REPLICATION prevents identity gaps during replication. CLUSTERED PK on HISTORY filegroup. |
| 2 | SeverityTypeID | int | NO | - | CODE-BACKED | Severity level of the event. FK to `Dictionary.SeverityType.SeverityTypeID` (WITH CHECK). Values: 1=Fatal, 2=Error, 3=Warning, 4=Informatory, 5=Verbose. Live data shows only values 3-5 used in this table (no Fatal or Error events recorded in 2014 dataset). |
| 3 | CID | int | YES | - | CODE-BACKED | Customer account ID associated with the error. FK to `Customer.CustomerStatic.CID` (WITH CHECK). NULL for system-level events. Live data confirms CID is NULL for all 2,969 rows in this table - all events are server infrastructure events, not customer-specific errors. Designed to support customer-linked error logging but never utilized. |
| 4 | ErrorMessageID | int | NO | - | CODE-BACKED | Reference to the structured message template. FK to `Dictionary.ErrorMessage.ErrorMessageID` (WITH CHECK). Dictionary.ErrorMessage stores parameterized templates (e.g., "{instrument} set to inactive by {component}: {reason}") keyed by ServerTypeID + ServerMessageID. The 5 most common IDs in live data: 49 (800 rows, "General message"), 73 (705, instrument inactive by component), 72 (675, instrument active by component), 61 (408, instrument inactive), 60 (381, instrument active). All from ServerTypeID=7 (PriceServer). |
| 5 | Entity | int | NO | - | CODE-BACKED | Numeric identifier of the server entity that generated the event. In `Broker.actDispatcher`, Entity=2 corresponds to the Distributor server type (Dictionary.ServerType.ServerTypeID=2). In live PriceServer data, Entity values 701, 702, 703 represent specific PriceServer instance IDs within the cluster. Entity encodes the originating server instance or component, enabling filtering of events by specific infrastructure nodes. |
| 6 | Parameters | varchar(max) | YES | - | CODE-BACKED | Semicolon-delimited runtime values substituted into the ErrorMessageID template to form the full human-readable message. For example, ErrorMessageID=73 template "{instrument} set to inactive by {component}: {reason}" with Parameters="17;_TimeoutAdapter;availability changed" produces "Instrument 17 set to inactive by _TimeoutAdapter: availability changed". NULL for events with no parameterized data. Stored on TEXTIMAGE_ON [HISTORY] (varchar(max) off-row storage). |
| 7 | Occurred | datetime | NO | getdate() | CODE-BACKED | Timestamp when the event occurred, defaulting to the database server's local time at INSERT. Used for chronological ordering of events. No index on this column - queries should filter by ErrorMessageID or Entity first, then order by Occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (WITH CHECK) | Optional link to the customer account that experienced the error. NULL for all system-level events. |
| ErrorMessageID | Dictionary.ErrorMessage | FK (WITH CHECK) | The structured message template. Joined with Parameters to reconstruct the full event description. |
| SeverityTypeID | Dictionary.SeverityType | FK (WITH CHECK) | Severity classification lookup. Values: 1=Fatal through 5=Verbose. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Broker.actDispatcher | INSERT | WRITER | Logs failed message delivery events to this table when CLR.Dispatcher cannot reach a network listener. Inserts with SeverityTypeID=2 (Error), ErrorMessageID=1, Entity=2 (Distributor). |
| History.ErrorLogAdd | INSERT (commented out) | DISABLED WRITER | Stored procedure designed as the standard writer for this table. The INSERT code is entirely enclosed in a `/* ... */` comment block and the SP body only executes `RETURN 0`. Dead/disabled code - this SP cannot insert records. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ErrorLog (table)
- no code-level dependencies (leaf table)
```

This object has no code-level dependencies (it is a target table, not a view or procedure with FROM/JOIN logic).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK target - CID references Customer.CustomerStatic.CID |
| Dictionary.ErrorMessage | Table | FK target - ErrorMessageID references Dictionary.ErrorMessage.ErrorMessageID |
| Dictionary.SeverityType | Table | FK target - SeverityTypeID references Dictionary.SeverityType.SeverityTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Broker.actDispatcher | Stored Procedure | WRITER - INSERTs error log entries when service broker message delivery fails |
| History.ErrorLogAdd | Stored Procedure | DISABLED WRITER - designed to write here but INSERT code is commented out (dead code) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HERR | CLUSTERED PK | ErrorLogID ASC | - | - | Active |

FILLFACTOR=90 on the clustered PK. No secondary indexes - with only 2,969 rows this table is small enough for full scans. The TEXTIMAGE_ON [HISTORY] clause stores the varchar(max) Parameters column off-row on the HISTORY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HERR | PRIMARY KEY | CLUSTERED on ErrorLogID - identity sequence guarantees uniqueness |
| HERR_OCCURRED | DEFAULT | Occurred = getdate() - stamps event time at INSERT |
| FK_CCST_HERR | FOREIGN KEY (WITH CHECK) | CID -> Customer.CustomerStatic(CID) - optional customer link, WITH CHECK enforces referential integrity |
| FK_DEMS_HERR | FOREIGN KEY (WITH CHECK) | ErrorMessageID -> Dictionary.ErrorMessage(ErrorMessageID) |
| FK_DSEV_HERR | FOREIGN KEY (WITH CHECK) | SeverityTypeID -> Dictionary.SeverityType(SeverityTypeID) |

---

## 8. Sample Queries

### 8.1 Reconstruct full event messages for a time window

```sql
SELECT
    h.ErrorLogID,
    h.Occurred,
    st.Name AS Severity,
    em.MessageText AS Template,
    h.Parameters,
    h.Entity,
    h.CID
FROM History.ErrorLog h WITH (NOLOCK)
JOIN Dictionary.SeverityType st WITH (NOLOCK) ON h.SeverityTypeID = st.SeverityTypeID
JOIN Dictionary.ErrorMessage em WITH (NOLOCK) ON h.ErrorMessageID = em.ErrorMessageID
WHERE h.Occurred >= '2014-06-01'
  AND h.Occurred <  '2014-07-01'
ORDER BY h.Occurred ASC;
```

### 8.2 Find instrument state change events by instrument ID

```sql
-- ErrorMessageID 60 = active, 61 = inactive, 72 = active by component, 73 = inactive by component
SELECT
    h.ErrorLogID,
    h.Occurred,
    st.Name AS Severity,
    em.MessageText AS Template,
    h.Parameters,
    h.Entity
FROM History.ErrorLog h WITH (NOLOCK)
JOIN Dictionary.SeverityType st WITH (NOLOCK) ON h.SeverityTypeID = st.SeverityTypeID
JOIN Dictionary.ErrorMessage em WITH (NOLOCK) ON h.ErrorMessageID = em.ErrorMessageID
WHERE h.ErrorMessageID IN (60, 61, 72, 73)
  AND h.Parameters LIKE '17;%'  -- Filter by instrument ID (first semicolon-delimited value)
ORDER BY h.Occurred ASC;
```

### 8.3 Count events by severity and message template

```sql
SELECT
    st.Name AS Severity,
    em.MessageText AS Template,
    COUNT(*) AS EventCount,
    MIN(h.Occurred) AS FirstSeen,
    MAX(h.Occurred) AS LastSeen
FROM History.ErrorLog h WITH (NOLOCK)
JOIN Dictionary.SeverityType st WITH (NOLOCK) ON h.SeverityTypeID = st.SeverityTypeID
JOIN Dictionary.ErrorMessage em WITH (NOLOCK) ON h.ErrorMessageID = em.ErrorMessageID
GROUP BY st.Name, em.MessageText
ORDER BY EventCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.7/10 (Elements: 10/10, Logic: 7.0/10, Relationships: 10/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ErrorLog | Type: Table | Source: etoro/etoro/History/Tables/History.ErrorLog.sql*
