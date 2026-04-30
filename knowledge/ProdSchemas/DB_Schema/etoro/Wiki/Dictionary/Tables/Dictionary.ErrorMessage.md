# Dictionary.ErrorMessage

## 1. Business Meaning

### What It Is
A configuration table storing parameterized message templates for server-side logging and error reporting, organized by server type and message ID.

### Why It Exists
Rather than hardcoding log messages in server code, message templates are stored centrally. Each server component uses its server type + message ID pair to look up the appropriate template, then fills in parameters at runtime. This enables consistent logging formats and makes it possible to update message text without redeploying server binaries.

### How It's Used
Referenced by `History.ErrorLogAdd` (writes error log entries using these templates) and `Broker.actDispatcher` (dispatches messages based on server type and message ID). The `ServerTypeID` FK points to `Dictionary.ServerType` which identifies the source server component.

---

## 2. Business Logic

### Message Template System
Messages use `{placeholder}` syntax for runtime parameter substitution. Examples:
- `"Failed to deliver message {1} to port {2} on IP address {3}"` — positional parameters
- `"Exception in {function} due to {reason}"` — named parameters
- `"Hedging instrument {id} by {difference}"` — domain-specific parameters

### Server Type Distribution
| ServerTypeID | Server | Message Count | Purpose |
|-------------|--------|--------------|---------|
| 2 | Distributor | 1 | Network delivery errors |
| 6 | HedgeServer | 46 | Hedge operations, position management, recovery, auto-hedge |
| 7 | PriceServer | 24 | Client connections, instrument activity, price feeds, volatility |
| 8 | PriceProviders | 3 | Provider connectivity, exceptions |
| 13 | PriceDetector | 21 | OMPD price difference detection, notifications, feed status |

> **HedgeServer** (type 6) has the most messages — reflecting the complexity of hedge position management, provider interactions, and recovery workflows.

### Unique Constraint
The composite unique index on `(ServerTypeID, ServerMessageID)` ensures each server component has its own sequential message numbering. Message IDs are local to each server type, not global.

---

## 3. Data Overview

98 message templates across 5 server types. Representative samples per server:

| ErrorMessageID | Server | ServerMessageID | MessageText |
|---------------|--------|----------------|-------------|
| 1 | Distributor | 1 | Failed to deliver message {1} to port {2} on IP address {3} |
| 7 | HedgeServer | 6 | Hedging initiated by {initiator} |
| 35 | HedgeServer | 34 | Recovery initiated by {initiator} |
| 62 | PriceServer | 13 | Price feed online |
| 86 | PriceDetector | 9 | Service is Available |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **ErrorMessageID** | `int` | NO | Primary key. Global sequential message identifier (1-98 with gaps). | `MCP` |
| **ServerTypeID** | `int` | NO | FK to Dictionary.ServerType. Identifies which server component owns this message template. Values: 2 (Distributor), 6 (HedgeServer), 7 (PriceServer), 8 (PriceProviders), 13 (PriceDetector). | `DDL+MCP` |
| **ServerMessageID** | `int` | NO | Server-local message sequence number. Unique within each ServerTypeID. Range varies per server (1-46 for HedgeServer, 1-24 for PriceServer). | `MCP` |
| **MessageText** | `varchar(max)` | NO | Parameterized message template with `{placeholder}` syntax for runtime substitution. | `MCP` |

---

## 5. Relationships

### References To
| Table | Column | FK Name | Relationship |
|-------|--------|---------|-------------|
| Dictionary.ServerType | ServerTypeID | FK_DSVT_DEMS | Explicit FK — which server component this message belongs to |

### Referenced By
| Consumer | Relationship |
|----------|-------------|
| History.ErrorLogAdd | Procedure — writes error log entries referencing these message templates |
| Broker.actDispatcher | Procedure — dispatches messages using server type + message ID lookup |

---

## 6. Dependencies

### Depends On
- `Dictionary.ServerType` — parent lookup identifying the server component

### Depended On By
- `History.ErrorLogAdd` — error logging procedure
- `Broker.actDispatcher` — message dispatch procedure

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `ErrorMessageID` (clustered, PK_DEMS) |
| **Indexes** | `DEMS_SERVER` — unique on (ServerTypeID, ServerMessageID) |
| **Foreign Keys** | FK_DSVT_DEMS → Dictionary.ServerType(ServerTypeID) |
| **Filegroup** | DICTIONARY (TEXTIMAGE_ON DICTIONARY for varchar(max)) |
| **Row Count** | 98 |
| **Identity** | No |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all messages for a specific server type
SELECT  em.ErrorMessageID,
        em.ServerMessageID,
        em.MessageText
FROM    Dictionary.ErrorMessage em WITH (NOLOCK)
WHERE   em.ServerTypeID = 6  -- HedgeServer
ORDER BY em.ServerMessageID;

-- Get message template count per server type
SELECT  st.Name             AS ServerType,
        COUNT(*)            AS MessageCount
FROM    Dictionary.ErrorMessage em WITH (NOLOCK)
JOIN    Dictionary.ServerType st WITH (NOLOCK)
        ON em.ServerTypeID = st.ServerTypeID
GROUP BY st.Name
ORDER BY MessageCount DESC;

-- Look up a specific message by server type and local ID
SELECT  em.MessageText
FROM    Dictionary.ErrorMessage em WITH (NOLOCK)
WHERE   em.ServerTypeID = 7
AND     em.ServerMessageID = 14;  -- "Price feed offline"
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
