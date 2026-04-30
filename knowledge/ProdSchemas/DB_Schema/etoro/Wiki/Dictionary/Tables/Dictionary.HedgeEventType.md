# Dictionary.HedgeEventType

> Lookup table defining the eight types of hedge infrastructure events — connection status changes, recovery outcomes, exposure zeroing, and volume anomaly detection for the hedge server monitoring system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | EventTypeID (INT, CLUSTERED PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgeEventType classifies the types of infrastructure and operational events that occur in eToro's hedge server system. These events track connection health (reconnects and disconnects to primary and backoffice systems), disaster recovery outcomes, exposure state changes, and volume anomalies. Together, they provide a complete picture of hedge infrastructure health and operational integrity.

This table exists because the hedge server is mission-critical infrastructure. Any disruption — a connection drop, a failed recovery, or a volume mismatch — can leave eToro carrying unhedged exposure, creating significant financial risk. By classifying events into distinct types, the monitoring system can apply different alerting rules and escalation paths for each event category.

EventTypeID is used in the hedge event logging system. Connection events (1-4) track communication health, recovery events (5-6) track disaster recovery outcomes, and business events (7-8) track anomalous exposure conditions.

---

## 2. Business Logic

### 2.1 Hedge Event Categories

**What**: Events fall into three functional categories: connection health, recovery status, and business anomalies.

**Columns/Parameters Involved**: `EventTypeID`, `Name`

**Rules**:
- **Connection events (1-4)**: Track the health of connections between the hedge server and other systems
  - Reconnect Primary (1): Primary connection restored after an outage
  - Disconnect Primary (2): Primary connection lost — CRITICAL, hedge orders cannot be sent
  - Reconnect Backoffice (3): Backoffice connection restored
  - Disconnect Backoffice (4): Backoffice connection lost — reporting and management affected
- **Recovery events (5-6)**: Track disaster recovery outcomes
  - Recovery Success (5): The hedge server successfully recovered its state after a failure
  - Recovery Fail (6): Recovery failed — CRITICAL, manual intervention needed to reconcile positions
- **Business events (7-8)**: Track anomalous exposure conditions
  - Exposures change to 0 (7): All hedge exposure has zeroed out — may indicate market close, full position closure, or a data issue
  - Volume Account Larger than Volume Customers (8): The hedge account's volume exceeds customer volume — indicates potential over-hedging, which is a risk management concern

**Diagram**:
```
Hedge Event Types:
├── Connection Health
│     ├── Reconnect Primary (1)     ✓ Good
│     ├── Disconnect Primary (2)    ✗ Critical
│     ├── Reconnect Backoffice (3)  ✓ Good
│     └── Disconnect Backoffice (4) ⚠ Warning
│
├── Disaster Recovery
│     ├── Recovery Success (5)      ✓ Recovered
│     └── Recovery Fail (6)         ✗ Critical
│
└── Business Anomalies
      ├── Exposures to 0 (7)        ⚠ Investigate
      └── Volume Mismatch (8)       ⚠ Over-hedge risk
```

---

## 3. Data Overview

| EventTypeID | Name | Meaning |
|---|---|---|
| 1 | Reconnect Primary | Primary connection between hedge server and trading infrastructure has been restored after a disconnect. Indicates recovery from a communication failure. Normal post-outage event. |
| 2 | Disconnect Primary | Primary connection lost. CRITICAL event — the hedge server cannot send orders to liquidity providers. Unhedged exposure accumulates until reconnection. Triggers immediate alerting and escalation. |
| 5 | Recovery Success | The hedge server successfully recovered its position state after a system failure or restart. Positions, exposures, and pending orders have been reconciled and are consistent. |
| 6 | Recovery Fail | The hedge server failed to recover its state after a failure. CRITICAL — position data may be inconsistent between the hedge server and liquidity providers. Requires manual reconciliation by the hedge operations team. |
| 8 | Volume Account Larger than Volume Customers | The hedge account's total position volume exceeds the aggregated customer position volume. Indicates potential over-hedging — the broker is hedging more than customer exposure requires, creating unnecessary risk and cost. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EventTypeID | int | NO | - | VERIFIED | Primary key identifying the hedge event type. Connection: 1=Reconnect Primary, 2=Disconnect Primary, 3=Reconnect Backoffice, 4=Disconnect Backoffice. Recovery: 5=Success, 6=Fail. Business: 7=Exposures to 0, 8=Volume mismatch. Used in hedge event logging for monitoring and alerting. |
| 2 | Name | varchar(64) | YES | - | VERIFIED | Human-readable label for the event type. Used in hedge monitoring dashboards, alert notifications, and event log displays. Concisely describes what happened in the hedge infrastructure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No FK references found in the current SSDT codebase — the hedge event logging tables may reside outside the SSDT project or use the EventTypeID directly without a DDL-level FK.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT. Event logging consumers may reference this table at the application level.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | EventTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PRIMARY KEY | Unique event type identifier (unnamed constraint) |

---

## 8. Sample Queries

### 8.1 List all hedge event types
```sql
SELECT  EventTypeID,
        Name
FROM    [Dictionary].[HedgeEventType] WITH (NOLOCK)
ORDER BY EventTypeID;
```

### 8.2 Filter critical event types only
```sql
SELECT  EventTypeID,
        Name
FROM    [Dictionary].[HedgeEventType] WITH (NOLOCK)
WHERE   EventTypeID IN (2, 6, 8)
ORDER BY EventTypeID;
```

### 8.3 Categorize event types by severity
```sql
SELECT  EventTypeID,
        Name,
        CASE
            WHEN EventTypeID IN (2, 6)   THEN 'CRITICAL'
            WHEN EventTypeID IN (4, 7, 8) THEN 'WARNING'
            WHEN EventTypeID IN (1, 3, 5) THEN 'INFO'
        END AS Severity
FROM    [Dictionary].[HedgeEventType] WITH (NOLOCK)
ORDER BY EventTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgeEventType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgeEventType.sql*
