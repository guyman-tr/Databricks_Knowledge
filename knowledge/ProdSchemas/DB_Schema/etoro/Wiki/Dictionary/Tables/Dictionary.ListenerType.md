# Dictionary.ListenerType

> Classifies the types of real-time event listeners that subscribe to broker message broadcasts in the platform's messaging infrastructure.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ListenerTypeID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 1 unique NC on Name |

---

## 1. Business Meaning

Dictionary.ListenerType defines the categories of consumers that subscribe to real-time message broadcasts in the Broker messaging subsystem. Each listener type represents a distinct application tier that receives market data, position updates, and system notifications through the Broker.Listener infrastructure.

Without this table, the broker messaging system would have no way to classify listeners, making it impossible to route messages to the correct application tier or filter broadcasts by subscriber type. The Broker.ListenerTypeToMessage mapping depends on this table to define which message types each listener category receives.

Data is static configuration. The Broker.ListenerAdd procedure inserts new listener registrations referencing this table. The Broker.Broadcast view joins through Broker.ListenerTypeToMessage to resolve which listeners should receive each broadcast. Currently only one active value exists (BackOffice), suggesting other listener types may have been deprecated or consolidated.

---

## 2. Business Logic

### 2.1 Message Routing by Listener Type

**What**: Listener types control which broadcast messages reach which application tiers.

**Columns/Parameters Involved**: `ListenerTypeID`, `Name`

**Rules**:
- Each listener type maps to one or more message types via Broker.ListenerTypeToMessage
- The Broker.Broadcast view filters messages based on listener type subscriptions
- A listener registers via Broker.ListenerAdd with a specific ListenerTypeID

**Diagram**:
```
Broker.ListenerType ──FK──> Broker.ListenerTypeToMessage ──FK──> Broker.Listener
       │                              │
       └── defines subscriber tier    └── maps allowed message types
                                           │
                                     Broker.Broadcast (view)
                                           └── routes messages to matching listeners
```

---

## 3. Data Overview

| ListenerTypeID | Name | Meaning |
|---|---|---|
| 1 | BackOffice | The BackOffice administration application subscribes to broker message broadcasts for real-time updates on trades, positions, and system events displayed to operations staff |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ListenerTypeID | int | NO | - | CODE-BACKED | Unique identifier for each listener category. Currently only 1 (BackOffice) exists. Referenced by Broker.Listener and Broker.ListenerTypeToMessage as the FK target. |
| 2 | Name | varchar(20) | NO | - | CODE-BACKED | Human-readable label for the listener type. Enforced unique by index DLST_NAME. Used in Broker.Broadcast view to identify subscriber tiers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Broker.Listener | ListenerTypeID | Implicit | Listener registrations reference this table to classify their subscriber tier |
| Broker.ListenerTypeToMessage | ListenerTypeID | Implicit | Maps which message types each listener type receives |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Broker.Listener | Table | References ListenerTypeID column |
| Broker.ListenerTypeToMessage | Table | References ListenerTypeID for message routing |
| Broker.ListenerAdd | Stored Procedure | Inserts listener registrations with ListenerTypeID |
| Broker.Broadcast | View | Joins through ListenerTypeToMessage to route messages |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DLST | CLUSTERED PK | ListenerTypeID | - | - | Active |
| DLST_NAME | NC UNIQUE | Name | - | - | Active |

### 7.2 Constraints

None beyond PK and unique index.

---

## 8. Sample Queries

### 8.1 List all listener types
```sql
SELECT  ListenerTypeID,
        Name
FROM    [Dictionary].[ListenerType] WITH (NOLOCK)
ORDER BY ListenerTypeID;
```

### 8.2 Find message types for each listener category
```sql
SELECT  lt.Name AS ListenerType,
        ltm.*
FROM    [Broker].[ListenerTypeToMessage] ltm WITH (NOLOCK)
JOIN    [Dictionary].[ListenerType] lt WITH (NOLOCK)
        ON ltm.ListenerTypeID = lt.ListenerTypeID
ORDER BY lt.Name;
```

### 8.3 Count active listeners by type
```sql
SELECT  lt.Name AS ListenerType,
        COUNT(*) AS ActiveListeners
FROM    [Broker].[Listener] l WITH (NOLOCK)
JOIN    [Dictionary].[ListenerType] lt WITH (NOLOCK)
        ON l.ListenerTypeID = lt.ListenerTypeID
GROUP BY lt.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ListenerType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ListenerType.sql*
