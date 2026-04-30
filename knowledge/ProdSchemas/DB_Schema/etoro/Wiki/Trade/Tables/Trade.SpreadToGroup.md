# Trade.SpreadToGroup

> Many-to-many bridge table linking spread groups (e.g., Default, Expert) to spread definitions, enabling customer tiers to share or override bid/ask spreads per instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | SpreadGroupID, SpreadID (composite PK) |
| **Partition** | Yes - ON [MAIN] |
| **Indexes** | 2 active (PK + TS2G_SPREAD) |

---

## 1. Business Meaning

Trade.SpreadToGroup is the many-to-many bridge table that connects Trade.SpreadGroup (named spread tiers such as Default, Expert, One Pip Plus) to Trade.Spread (individual bid/ask definitions per ProviderID, InstrumentID). Each row represents one association: "Spread Group X includes Spread Y." A single SpreadID can belong to multiple groups, and a single group can include many spreads. This design allows different customer segments to share the same underlying spread definitions while enabling overrides (e.g., Expert group includes tighter spreads not available to Default customers).

This table exists because eToro needs flexible spread assignment. Without it, each spread group would require a separate copy of all spread values. The bridge pattern lets one Spread row serve multiple groups and lets groups be composed from subsets. Trade.GetSpreadGroup, Trade.GetForexRates, Trade.GetPendingOrders, and spread resolution at order time all depend on this mapping.

Data flows: rows are created by `Trade.SpreadToGroupLink` (INSERT one pair), bulk-inserted by `Trade.InsertInstrumentRealTable` (during instrument onboarding from ##Trade_SpreadToGroup), and deleted by `Trade.SpreadToGroupUnLink` (DELETE all spreads for a group). Trade.CheckValidInstruments builds ##Trade_SpreadToGroup and updates Spread + SpreadToGroup. Triggers SpreadToGroupInsert and SpreadToGroupDelete maintain History.SpreadToGroup (ValidFrom, ValidTo) for audit.

---

## 2. Business Logic

### 2.1 Many-to-Many Bridge Pattern

**What**: SpreadToGroup resolves which spreads apply for each spread group without duplicating spread data.

**Columns/Parameters Involved**: `SpreadGroupID`, `SpreadID`

**Rules**:
- (SpreadGroupID, SpreadID) is the composite PK - no duplicate pairs
- SpreadGroupID references Trade.SpreadGroup (FK_TSPG_TS2G)
- SpreadID references Trade.Spread (FK_TSPR_TS2G)
- Trade.GetSpreadGroup: TSPG JOIN TS2G JOIN TSPR produces Bid, Ask per (SpreadGroupID, ProviderID, InstrumentID)
- SpreadGroupID=0 (Default) typically includes the largest set of spreads - Trade.GetForexRates joins on SpreadGroupID=0 for base forex

**Diagram**:
```
Trade.SpreadGroup (SpreadGroupID, Name)         Trade.SpreadToGroup (bridge)         Trade.Spread (SpreadID, ProviderID, InstrumentID, Bid, Ask)
+------------------+                           +----------------------+             +------------------------------------------+
| 0 = Default      |<-------------------------| SpreadGroupID        |------------->| SpreadID 1 = EUR/USD, 2 = GBP/USD, etc.  |
| 1 = Expert       |                           | SpreadID             |             | Bid, Ask per provider+instrument          |
| 3 = One Pip Plus |                           +----------------------+             +------------------------------------------+
+------------------+
```

### 2.2 Instrument Onboarding Flow

**What**: New instruments get spread mappings via CheckValidInstruments and InsertInstrumentRealTable.

**Columns/Parameters Involved**: `SpreadGroupID`, `SpreadID`

**Rules**:
- CheckValidInstruments creates ##Trade_SpreadToGroup and populates it from existing SpreadToGroup or new spread definitions
- InsertInstrumentRealTable inserts from ##Trade_SpreadToGroup into Trade.SpreadToGroup
- Same SpreadID can appear in multiple groups (e.g., SpreadID 1 in both Default and Expert)

---

## 3. Data Overview

| SpreadGroupID | SpreadID | Meaning |
|---------------|----------|---------|
| 0 | 1 | Default group includes EUR/USD spread (Instrument 1). Used for base forex rate resolution. |
| 0 | 2 | Default includes GBP/USD (Instrument 2) spread. |
| 0 | 3 | Default includes NZD/USD (Instrument 3) spread. |
| 0 | 5 | Default includes JPY pair spread (Instrument 5). |
| 0 | 10 | Default includes EUR/JPY (Instrument 10) spread. |

**Selection criteria for the 5 rows:**
- All from SpreadGroupID=0 (Default) - the base group used when no customer-specific tier applies
- SpreadIDs 1-10 map to major forex and cross pairs per Trade.Spread
- First 5 of many rows linking Default to its spread set (14,087 total rows in table)

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SpreadGroupID | int | NO | - | CODE-BACKED | FK to Trade.SpreadGroup. Part of composite PK. Identifies the spread tier (0=Default, 1=Expert, etc.) that includes this spread. |
| 2 | SpreadID | int | NO | - | CODE-BACKED | FK to Trade.Spread. Part of composite PK. Identifies the spread definition (ProviderID, InstrumentID, Bid, Ask) included in this group. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SpreadGroupID | Trade.SpreadGroup | FK | FK_TSPG_TS2G. Spread tier (Default, Expert, etc.). |
| SpreadID | Trade.Spread | FK | FK_TSPR_TS2G. Spread definition (Bid/Ask per provider+instrument). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetSpreadGroup | FROM | Reader | Joins SpreadGroup, Spread, SpreadToGroup for Bid/Ask per group. |
| Trade.GetPendingOrders | JOIN | Reader | Resolves spread via SpreadToGroup for pending order display. |
| Trade.CheckValidInstruments | temp/INSERT | Writer | Builds ##Trade_SpreadToGroup, merges into Trade.SpreadToGroup. |
| Trade.InsertInstrumentRealTable | INSERT | Writer | Bulk inserts from ##Trade_SpreadToGroup during instrument onboarding. |
| Trade.SpreadToGroupLink | INSERT | Writer | Links one spread to one group. |
| Trade.SpreadToGroupUnLink | DELETE | Deleter | Removes all spreads from a group. |
| History.SpreadToGroup | Trigger | History | SpreadToGroupInsert/Delete maintain ValidFrom/ValidTo. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SpreadToGroup (table)
├── Trade.SpreadGroup (table)
└── Trade.Spread (table)
      └── Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SpreadGroup | Table | FK SpreadGroupID |
| Trade.Spread | Table | FK SpreadID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetSpreadGroup | View | JOIN for spread resolution |
| Trade.GetPendingOrders | Procedure | JOIN for spread |
| Trade.CheckValidInstruments | Procedure | temp table merge, validation |
| Trade.InsertInstrumentRealTable | Procedure | INSERT |
| Trade.SpreadToGroupLink | Procedure | INSERT |
| Trade.SpreadToGroupUnLink | Procedure | DELETE |
| History.SpreadToGroup | Table | Trigger history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TS2G | CLUSTERED | SpreadGroupID, SpreadID | - | - | Active |
| TS2G_SPREAD | NC | SpreadID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TSPG_TS2G | FK | SpreadGroupID -> Trade.SpreadGroup(SpreadGroupID) |
| FK_TSPR_TS2G | FK | SpreadID -> Trade.Spread(SpreadID) |

### 7.3 Triggers

| Trigger | Event | Action |
|---------|-------|--------|
| SpreadToGroupInsert | INSERT | Insert into History.SpreadToGroup (ValidFrom, ValidTo) |
| SpreadToGroupDelete | DELETE | Update History.SpreadToGroup ValidTo = GETDATE() for deleted row |

---

## 8. Sample Queries

### 8.1 List spreads in Default group (SpreadGroupID=0)
```sql
SELECT TS2G.SpreadGroupID, SG.Name AS GroupName, TS2G.SpreadID, S.ProviderID, S.InstrumentID, S.Bid, S.Ask
  FROM Trade.SpreadToGroup TS2G WITH (NOLOCK)
  JOIN Trade.SpreadGroup SG WITH (NOLOCK) ON TS2G.SpreadGroupID = SG.SpreadGroupID
  JOIN Trade.Spread S WITH (NOLOCK) ON TS2G.SpreadID = S.SpreadID
 WHERE TS2G.SpreadGroupID = 0
 ORDER BY S.InstrumentID
```

### 8.2 Count spreads per group
```sql
SELECT SG.SpreadGroupID, SG.Name, COUNT(TS2G.SpreadID) AS SpreadCount
  FROM Trade.SpreadGroup SG WITH (NOLOCK)
  LEFT JOIN Trade.SpreadToGroup TS2G WITH (NOLOCK) ON SG.SpreadGroupID = TS2G.SpreadGroupID
 GROUP BY SG.SpreadGroupID, SG.Name
 ORDER BY SG.SpreadGroupID
```

### 8.3 Find which groups include a specific spread
```sql
SELECT SG.SpreadGroupID, SG.Name
  FROM Trade.SpreadToGroup TS2G WITH (NOLOCK)
  JOIN Trade.SpreadGroup SG WITH (NOLOCK) ON TS2G.SpreadGroupID = SG.SpreadGroupID
 WHERE TS2G.SpreadID = 1
 ORDER BY SG.SpreadGroupID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.SpreadToGroup | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.SpreadToGroup.sql*
