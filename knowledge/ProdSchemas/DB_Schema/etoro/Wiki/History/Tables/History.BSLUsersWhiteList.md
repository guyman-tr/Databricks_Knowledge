# History.BSLUsersWhiteList

> Archive of completed BSL whitelist exemptions; each row records a customer who was temporarily exempt from Balance Stop Loss enforcement, capturing the period during which they were whitelisted.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (CID, DateDeleted) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.BSLUsersWhiteList is the completed-exemption archive for eToro's Balance Stop Loss (BSL) whitelist. When a customer is placed on the BSL whitelist, their record lives in the active table Trade.BSLUsersWhiteList; BSL processes skip or defer BSL enforcement for these customers. When the exemption ends, Trade.DeleteFromBSLUsersWhiteList atomically moves the record here using OUTPUT...INTO, preserving both when the exemption started (DateInserted) and when it ended (DateDeleted).

The whitelist is used by risk and operations teams to temporarily protect specific accounts from BSL-triggered actions - for example, during planned high-volatility events, account investigations, or regulatory review periods. With 17 historical entries, it is infrequently used and represents targeted interventions rather than broad policy.

Data flows exclusively from Trade.DeleteFromBSLUsersWhiteList via an atomic DELETE...OUTPUT...INTO pattern.

---

## 2. Business Logic

### 2.1 Whitelist Lifecycle - Active to Historical

**What**: Two-table pattern mirrors the BlockedCustomerOperations pattern: active exemptions in Trade.BSLUsersWhiteList, completed exemptions here.

**Columns/Parameters Involved**: `CID`, `DateInserted`, `DateDeleted`

**Rules**:
- ADD to whitelist: Trade.InsertIntoBSLUsersWhiteList(@CID) -> INSERT Trade.BSLUsersWhiteList if not already present
- REMOVE from whitelist: Trade.DeleteFromBSLUsersWhiteList(@CID) ->
  `DELETE Trade.BSLUsersWhiteList OUTPUT DELETED.CID, DELETED.DateInserted INTO History.BSLUsersWhiteList`
  DateDeleted is set by the DEFAULT constraint (getutcdate()) at insert time
- Duration of exemption = DateDeleted - DateInserted (ranges from seconds to ~7 hours in observed data)
- PK = (CID, DateDeleted) allows same customer to be whitelisted multiple times

**Diagram**:
```
Whitelist lifecycle:
  [Add exemption]
    Trade.InsertIntoBSLUsersWhiteList(@CID)
      -> INSERT Trade.BSLUsersWhiteList (CID, DateInserted=GETUTCDATE()) [if not exists]

  [Remove exemption]
    Trade.DeleteFromBSLUsersWhiteList(@CID)
      -> DELETE Trade.BSLUsersWhiteList
         OUTPUT DELETED.CID, DELETED.DateInserted
         INTO History.BSLUsersWhiteList  (DateDeleted = GETUTCDATE() via default)
```

---

## 3. Data Overview

| CID | DateInserted | DateDeleted | Meaning |
|---|---|---|---|
| 24855572 | 2026-01-21 02:38 | 2026-01-21 09:20 | ~6.7 hour BSL exemption in Jan 2026 - likely during a risk investigation or planned maintenance window |
| 23632629 | 2025-10-05 07:31 | 2025-10-05 07:32 | ~1 minute exemption - brief whitelist toggle, possibly automated or test |
| 3739184 | 2024-10-21 10:34 | 2024-10-21 10:34 | 9-second exemption for CID 3739184 - one of 3 whitelist events for this customer on the same day, suggesting a troubleshooting session |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID of the customer who was BSL-whitelisted. Implicit FK to Customer.Customer. PK component. Appears multiple times if customer was whitelisted/unwhitelisted multiple times. |
| 2 | DateInserted | datetime | NO | - | CODE-BACKED | UTC timestamp when the customer was first added to the active BSL whitelist (Trade.BSLUsersWhiteList). Copied from the active table via OUTPUT...INTO when the exemption ends. |
| 3 | DateDeleted | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the BSL exemption was removed (customer removed from Trade.BSLUsersWhiteList). Set automatically by the DEFAULT constraint at the moment of insertion into this history table. Note: DDL constraint name "DF_HistoryBSLUsersWhiteList_DateInserted" is a naming inconsistency but the DEFAULT applies to DateDeleted. PK component. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Trade.BSLUsersWhiteList | Temporal | Active whitelist counterpart - CID moves from Trade to History when exemption ends |
| CID | Customer.Customer | Implicit | The customer whose BSL exemption is recorded |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.DeleteFromBSLUsersWhiteList | CID, DateInserted | Writer | Atomic DELETE...OUTPUT...INTO - moves rows from active to history |
| Monitor.CheckBSLUsersWhiteList | CID | Monitor | Monitors whitelist health |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSLUsersWhiteList (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.DeleteFromBSLUsersWhiteList | Stored Procedure | Writer - inserts completed exemption records |
| Monitor.CheckBSLUsersWhiteList | Stored Procedure | Monitor/Reader |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBSLUsersWhiteList | CLUSTERED PK | CID ASC, DateDeleted ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBSLUsersWhiteList | PRIMARY KEY | (CID, DateDeleted) - allows multiple whitelist cycles per customer |
| DF_HistoryBSLUsersWhiteList_DateInserted | DEFAULT | DateDeleted = getutcdate() (naming inconsistency in DDL: constraint named "DateInserted" but applies to DateDeleted column) |

---

## 8. Sample Queries

### 8.1 Get full whitelist history for a customer
```sql
SELECT CID, DateInserted, DateDeleted,
       DATEDIFF(MINUTE, DateInserted, DateDeleted) AS DurationMinutes
FROM [History].[BSLUsersWhiteList] WITH (NOLOCK)
WHERE CID = @CID
ORDER BY DateInserted DESC
```

### 8.2 Find current whitelist exemptions (active state)
```sql
-- Current exemptions are in Trade.BSLUsersWhiteList, not History
SELECT CID, DateInserted, DATEDIFF(MINUTE, DateInserted, GETUTCDATE()) AS MinutesActive
FROM [Trade].[BSLUsersWhiteList] WITH (NOLOCK)
ORDER BY DateInserted
```

### 8.3 Combined view: all whitelist activity (active + completed)
```sql
SELECT CID, DateInserted, NULL AS DateDeleted, 'Active' AS Status
FROM [Trade].[BSLUsersWhiteList] WITH (NOLOCK)
UNION ALL
SELECT CID, DateInserted, DateDeleted, 'Completed' AS Status
FROM [History].[BSLUsersWhiteList] WITH (NOLOCK)
ORDER BY DateInserted DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSLUsersWhiteList | Type: Table | Source: etoro/etoro/History/Tables/History.BSLUsersWhiteList.sql*
