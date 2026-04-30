# Dictionary.EventType

## 1. Business Meaning

### What It Is
A lookup table defining customer lifecycle event types that trigger automated actions (such as notifications, messages, or internal workflows) within the platform.

### Why It Exists
The platform tracks significant customer milestones — registration, first deposit, first trade, etc. — to trigger automated engagement (welcome messages, promotional offers, re-engagement campaigns). This table defines the event catalog and tracks which events are currently active in the system.

### How It's Used
Referenced by `Customer.SendEvent` (triggers event processing for a customer), `BackOffice.SendBirthDayMessage` (birthday-specific events), and `Maintenance.EventEdit` (enables/disables events). The `IsActive` flag controls whether the event type is currently operational.

---

## 2. Business Logic

### Event Categories

**Active Events** (currently triggering actions):
| ID | Name | Business Trigger |
|----|------|-----------------|
| 1 | Registration of demo customer | New demo account created |
| 2 | Registration of real customer | New real money account created |
| 3 | First deposit | Customer's first funding transaction |
| 6 | First position with positive net profit | Customer's first profitable closed trade |
| 9 | Money is over | Account balance depleted |
| 10 | Any customer login | Login event (demo + real) |
| 11 | Any customer logout | Logout event (demo + real) |
| 28 | First position | Customer's first-ever trade opened |

**Inactive Events** (deprecated, no longer triggering):
| ID | Name | Notes |
|----|------|-------|
| 4 | First game | Legacy game model |
| 5 | Birthday | Birthday messages disabled |
| 7 | Championship win | Trading competitions feature |
| 8 | Championship registration | Trading competitions feature |
| 12-15 | Demo/Real login/logout (specific) | Replaced by unified events 10/11 |
| 29 | First Weekly Login | Weekly engagement tracking |

### Active vs Inactive
- **Active** events are processed by the event system and trigger downstream actions
- **Inactive** events are retained for historical reference but the system ignores them
- `Maintenance.EventEdit` toggles the `IsActive` flag to enable/disable events

---

## 3. Data Overview

| EventTypeID | IsActive | Name |
|------------|----------|------|
| 1 | true | Registration of demo customer |
| 2 | true | Registration of real customer |
| 3 | true | First deposit |
| 4 | false | First game |
| 5 | false | Birthday |
| 6 | true | First position with positive net profit |
| 7 | false | Championship win |
| 8 | false | Championship registration |
| 9 | true | Money is over |
| 10 | true | Any customer login |
| 11 | true | Any customer logout |
| 12 | false | Demo customer login |
| 13 | false | Demo customer logout |
| 14 | false | Real customer login |
| 15 | false | Real customer logout |
| 28 | true | First position |
| 29 | false | First Weekly Login |

---

## 4. Elements

| Column | Type | Null | Description | Confidence |
|--------|------|------|-------------|------------|
| **EventTypeID** | `int` | NO | Primary key. Event type identifier (1-29 with gaps). | `MCP` |
| **IsActive** | `bit` | NO | Whether the event type is currently operational. Active=1 means the system processes this event; Inactive=0 means it is ignored. | `MCP+CODE` |
| **Name** | `varchar(50)` | NO | Human-readable event description. Unique index ensures no duplicates. | `MCP` |

---

## 5. Relationships

### Referenced By
No explicit FK constraints found. Implicit references via EventTypeID in event processing tables.

### References To
None — leaf lookup table.

---

## 6. Dependencies

### Depends On
None.

### Depended On By
- `Customer.SendEvent` — procedure that triggers event processing for a customer
- `BackOffice.SendBirthDayMessage` — birthday-specific event handling
- `Maintenance.EventEdit` — enables/disables event types by toggling IsActive

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| **Primary Key** | `EventTypeID` (clustered, PK_DEVT) |
| **Indexes** | `DEVT_NAME` — unique on Name |
| **Filegroup** | DICTIONARY |
| **Row Count** | 17 |
| **Identity** | No — manually assigned with gaps (16-27 unused) |
| **Temporal** | No |

---

## 8. Sample Queries

```sql
-- Get all event types with active status
SELECT  EventTypeID,
        Name,
        IsActive
FROM    Dictionary.EventType WITH (NOLOCK)
ORDER BY EventTypeID;

-- Get only active event types
SELECT  EventTypeID,
        Name
FROM    Dictionary.EventType WITH (NOLOCK)
WHERE   IsActive = 1
ORDER BY EventTypeID;

-- Count active vs inactive events
SELECT  CASE WHEN IsActive = 1 THEN 'Active' ELSE 'Inactive' END AS Status,
        COUNT(*) AS EventCount
FROM    Dictionary.EventType WITH (NOLOCK)
GROUP BY IsActive;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found for this table.

---

*Generated: 2026-03-14 | Quality Score: 9.2 | Phases: DDL ✓ MCP ✓ Codebase ✓ Procedures ✓*
