# BackOffice.MessageTypeToManager

> Junction table that defines which Broker message types each BackOffice manager is subscribed to or responsible for handling.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_BM2M: ManagerID + MessageTypeID (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (1 clustered PK + 2 nonclustered) |

---

## 1. Business Meaning

`BackOffice.MessageTypeToManager` is a many-to-many junction table linking BackOffice managers to the Broker message types they are configured to handle. The Broker layer is eToro's real-time trading platform that fires typed event messages (e.g., `mtUserRegister`, `mtUserLogin`, `mtUserDeposit`) when platform events occur. This table determines which back-office manager receives or is responsible for processing each category of event message.

This table exists to route Broker-sourced event notifications to the appropriate back-office personnel. Without this mapping, the system would have no way to direct trading platform events to specific managers for review or action.

Data in this table is populated through back-office administration. Rows are added when a manager is assigned responsibility for a message type category, and removed when that assignment changes. The table is currently empty in the connected environment, suggesting it may be populated in production or may be used in a specific flow not currently active.

---

## 2. Business Logic

### 2.1 Manager-to-MessageType Routing

**What**: Each row grants a specific manager responsibility/visibility for a specific message type from the Broker platform.

**Columns/Parameters Involved**: `ManagerID`, `MessageTypeID`

**Rules**:
- The combination (ManagerID, MessageTypeID) is unique (enforced by PK).
- One manager can be mapped to many message types.
- One message type can be mapped to many managers (fan-out routing).
- No cascading: deleting a manager or message type would require explicit FK-managed cleanup.

**Diagram**:
```
BackOffice.Manager                    Broker.MessageType
(ManagerID=12, Name='...')     <-->   (MessageTypeID=65538, 'mtUserRegister')
                                <-->  (MessageTypeID=65541, 'mtUserDeposit')

(ManagerID=45, Name='...')     <-->   (MessageTypeID=65541, 'mtUserDeposit')
```

---

## 3. Data Overview

Table is currently empty in the connected environment. Based on FK targets:

| ManagerID | MessageTypeID | Meaning |
|-----------|--------------|---------|
| (example) | 65538 | Manager receives mtUserRegister notifications - new customer registrations |
| (example) | 65541 | Manager receives mtUserDeposit notifications - customer deposit events |
| (example) | 65542 | Manager receives mtDataIntegrity notifications - data integrity alerts |

Known Broker.MessageType values (from live data):
- 65538 = mtUserRegister
- 65539 = mtUserLogin
- 65540 = mtUserLogout
- 65541 = mtUserDeposit
- 65542 = mtDataIntegrity

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManagerID | int | NO | - | CODE-BACKED | Foreign key to BackOffice.Manager.ManagerID. Identifies the back-office manager who is assigned responsibility for the message type. Part of the composite PK. |
| 2 | MessageTypeID | int | NO | - | CODE-BACKED | Foreign key to Broker.MessageType.MessageTypeID. Identifies the category of Broker platform event this manager handles. Examples: 65538=mtUserRegister, 65541=mtUserDeposit. Part of the composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerID | BackOffice.Manager.ManagerID | FK (FK_BMNG_BM2M) | References the back-office manager record |
| MessageTypeID | Broker.MessageType.MessageTypeID | FK (FK_DCNT_BM2M) | References the Broker platform message type definition |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.MessageTypeToManager (table)
├── BackOffice.Manager (table) [FK_BMNG_BM2M]
└── Broker.MessageType (table) [FK_DCNT_BM2M]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Manager | Table | FK_BMNG_BM2M: ManagerID must exist in BackOffice.Manager |
| Broker.MessageType | Table | FK_DCNT_BM2M: MessageTypeID must exist in Broker.MessageType |

### 6.2 Objects That Depend On This

No dependents found in BackOffice schema procedures or views.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BM2M | CLUSTERED PK | ManagerID ASC, MessageTypeID ASC | - | - | Active |
| BM2M_MANAGER | NONCLUSTERED | ManagerID ASC | - | - | Active |
| BM2M_MESSAGETYPE | NONCLUSTERED | MessageTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BMNG_BM2M | FK | ManagerID -> BackOffice.Manager.ManagerID |
| FK_DCNT_BM2M | FK | MessageTypeID -> Broker.MessageType.MessageTypeID |

---

## 8. Sample Queries

### 8.1 List all message types assigned to a specific manager

```sql
SELECT m.ManagerID, mt.MessageTypeID, mt.Name AS MessageTypeName
FROM BackOffice.MessageTypeToManager m WITH (NOLOCK)
JOIN Broker.MessageType mt WITH (NOLOCK)
    ON mt.MessageTypeID = m.MessageTypeID
WHERE m.ManagerID = 12;
```

### 8.2 Find all managers assigned to a specific message type

```sql
SELECT mgr.ManagerID, mgr.UserName, m.MessageTypeID
FROM BackOffice.MessageTypeToManager m WITH (NOLOCK)
JOIN BackOffice.Manager mgr WITH (NOLOCK)
    ON mgr.ManagerID = m.ManagerID
WHERE m.MessageTypeID = 65541;  -- mtUserDeposit
```

### 8.3 Full mapping with manager names and message type names

```sql
SELECT
    mgr.UserName,
    mt.Name AS MessageTypeName,
    mt.MessageTypeID
FROM BackOffice.MessageTypeToManager m WITH (NOLOCK)
JOIN BackOffice.Manager mgr WITH (NOLOCK)
    ON mgr.ManagerID = m.ManagerID
JOIN Broker.MessageType mt WITH (NOLOCK)
    ON mt.MessageTypeID = m.MessageTypeID
ORDER BY mgr.UserName, mt.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Live Data, FK, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.MessageTypeToManager | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.MessageTypeToManager.sql*
