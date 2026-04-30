# Trade.SpreadGroup

> Configuration table that groups spread definitions by name, enabling customers and instruments to share customized bid/ask spreads (pips) per provider and instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | SpreadGroupID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK, 1 unique NC) |

---

## 1. Business Meaning

Trade.SpreadGroup is a small configuration table that defines named groups of spreads. Each row represents a logical spread profile - e.g., "Default", "Expert", "One Pip Plus", "Very High Spreads" - that can be assigned to customers or used for instrument-specific spread overrides. The table stores only the group identifier and human-readable name; the actual spread values (Bid, Ask per Provider/Instrument) live in Trade.Spread and are linked to groups via Trade.SpreadToGroup.

This table exists because eToro needs to offer different spread tiers to different customers (e.g., VIP customers get tighter spreads via "Expert" or "One Pip Plus" groups, while others use "Default"). Without it, the system could not associate multiple spread definitions with a single named profile or assign customers to spread tiers. Customer.Customer.SpreadGroupID, Trade.InstrumentSpread.SpreadGroupID, and Trade.PositionTbl.SpreadGroupID all depend on this table to resolve which spread profile applies at position open or rate lookup time.

Data flows: rows are created via `Trade.SpreadGroupAdd` (which calls `Internal.GetSpreadGroupID` for ID allocation), modified via `Trade.SpreadGroupEdit`, and deleted via `Trade.SpreadGroupDelete`. The view `Trade.GetSpreadGroup` joins SpreadGroup with Spread and SpreadToGroup to expose spread group names plus Bid/Ask per Provider/Instrument. Triggers copy all changes to History.SpreadGroup for audit. Spread groups are linked to spreads via `Trade.SpreadToGroupLink` and `Trade.SpreadToGroupUnLink`.

---

## 2. Business Logic

### 2.1 Spread Group to Spread Mapping

**What**: A spread group aggregates multiple Trade.Spread rows (each with ProviderID, InstrumentID, Bid, Ask) via the many-to-many link table Trade.SpreadToGroup.

**Columns/Parameters Involved**: `SpreadGroupID`, `Name`

**Rules**:
- Each SpreadGroupID maps to one or more SpreadID values in Trade.SpreadToGroup
- Trade.GetSpreadGroup produces one row per (SpreadGroupID, SpreadID) combination, joining SpreadGroup, Spread, and SpreadToGroup
- SpreadGroupID=0 ("Default") is special: Trade.GetForexRates joins on SpreadGroupID=0 to get base forex spreads when resolving prices
- Name must be unique (enforced by TSPG_NAME index)

**Diagram**:
```
Trade.SpreadGroup                    Trade.SpreadToGroup                  Trade.Spread
+------------------+                 +------------------+                 +------------------+
| SpreadGroupID    |<----------------| SpreadGroupID    |---------------->| SpreadID         |
| Name             |                 | SpreadID         |                 | ProviderID       |
+------------------+                 +------------------+                 | InstrumentID     |
       |                                                                  | Bid, Ask         |
       v                                                                  +------------------+
Customer.Customer.SpreadGroupID
Trade.InstrumentSpread.SpreadGroupID
Trade.PositionTbl.SpreadGroupID
```

### 2.2 Customer and Instrument Assignment

**What**: Spread groups are assigned to customers and instruments to determine which bid/ask spreads apply at order time.

**Columns/Parameters Involved**: `SpreadGroupID`

**Rules**:
- Customer.Customer.SpreadGroupID assigns a customer to a spread group; `Customer.SetSpreadGroup` and `Customer.DemographyEdit` update it
- Trade.InstrumentSpread.SpreadGroupID overrides the default spread for an instrument within a given spread group (used by CheckValidInstruments, Internal.Newcurrency)
- Trade.PositionTbl.SpreadGroupID records which spread group was in effect when the position was opened (from Customer or instrument override)
- New customers default to SpreadGroupID=0 unless specified in Customer.InsertRealCustomer

---

## 3. Data Overview

| SpreadGroupID | Name | Meaning |
|---|---|---|
| 0 | Default | Base spread group. Used when no custom tier applies. Trade.GetForexRates explicitly joins on SpreadGroupID=0 for forex rates. |
| 1 | Expert | Premium spread tier, typically for VIP or professional traders with tighter spreads. |
| 2 | Very High Spreads | Higher-spread tier, often for high-risk or restricted instruments. |
| 3 | One Pip Plus | Slightly better than default - one pip discount. |
| 4 | 1 pip discount on Instruments 1 & 6 | Instrument-specific discount group for EUR/USD (1) and related instrument (6). |
| 7 | instrument=spread, 1=2, 2=3, 4=3, 18=40, 17=10 | Custom mapping group: Instrument 1 gets 2 pips, 2 gets 3, etc. Used for targeted spread overrides. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SpreadGroupID | int | NO | - | CODE-BACKED | Primary key. Allocated by Internal.GetSpreadGroupID when creating a new group via Trade.SpreadGroupAdd. SpreadGroupID=0 is reserved for "Default" - the base group used when no customer-specific or instrument-specific override applies. Referenced by Customer.Customer, Trade.InstrumentSpread, Trade.PositionTbl, Trade.SpreadToGroup, and History.SpreadGroup. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the spread group (e.g., "Expert", "One Pip Plus", "CID=302302"). Must be unique (TSPG_NAME index). Updated via Trade.SpreadGroupEdit. Used in UI and back-office to identify spread tiers. CID-prefixed names indicate customer-specific custom groups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. SpreadGroupID is allocated internally; Name is a free-text label.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SpreadToGroup | SpreadGroupID | FK | Links spread groups to Trade.Spread rows. Many spreads can belong to one group. |
| History.SpreadGroup | SpreadGroupID | FK | History table storing all versioned changes (ValidFrom, ValidTo). Populated by INSERT/UPDATE/DELETE triggers. |
| Customer.Customer | SpreadGroupID | FK | Assigns each customer to a spread tier. Updated by Customer.SetSpreadGroup, Customer.DemographyEdit. |
| Trade.InstrumentSpread | SpreadGroupID | FK | Instrument-specific spread overrides per group. Used when validating and building spread config (CheckValidInstruments, Internal.Newcurrency). |
| Trade.PositionTbl | SpreadGroupID | FK | Records the spread group in effect when the position was opened. Used for P&L, recovery, and reporting. |
| Trade.GetSpreadGroup | SpreadGroupID | JOIN | View joining SpreadGroup, Spread, SpreadToGroup to expose group name + Bid/Ask per Provider/Instrument. |
| Trade.SpreadGroupAdd | - | Writer | Creates new spread group rows. |
| Trade.SpreadGroupEdit | - | Modifier | Updates Name by SpreadGroupID. |
| Trade.SpreadGroupDelete | - | Deleter | Removes spread group by SpreadGroupID. |
| Trade.SpreadToGroupLink | SpreadGroupID | Writer | Adds SpreadID to a group. |
| Trade.SpreadToGroupUnLink | SpreadGroupID | Modifier | Removes all SpreadIDs from a group. |
| Trade.CheckValidInstruments | - | Reader | Validates spread config; JOINs Trade.SpreadGroup to ensure referenced groups exist. |
| Trade.GetForexRates | - | Reader | JOINs Trade.GetSpreadGroup on SpreadGroupID=0 for default forex spreads. |
| Trade.PositionOpen | - | Reader | Reads Customer/Instrument SpreadGroupID to set position's SpreadGroupID at open. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SpreadGroup (table)
```

Tables have no code-level dependencies. Trade.SpreadGroup is a leaf table with no FROM/JOIN in its DDL.

### 6.1 Objects This Depends On

No dependencies. SpreadGroupID is allocated by Internal.GetSpreadGroupID (internal sequence); no explicit FK targets in CREATE TABLE.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SpreadToGroup | Table | FK SpreadGroupID -> Trade.SpreadGroup |
| History.SpreadGroup | Table | History copy via triggers |
| Trade.GetSpreadGroup | View | FROM Trade.SpreadGroup |
| Trade.SpreadGroupAdd | Procedure | INSERT into Trade.SpreadGroup |
| Trade.SpreadGroupEdit | Procedure | UPDATE Trade.SpreadGroup |
| Trade.SpreadGroupDelete | Procedure | DELETE from Trade.SpreadGroup |
| Trade.SpreadToGroupLink | Procedure | References group when linking spreads |
| Trade.SpreadToGroupUnLink | Procedure | References group when unlinking |
| Trade.CheckValidInstruments | Procedure | JOIN for validation |
| Trade.GetForexRates | Procedure | JOIN via GetSpreadGroup on SpreadGroupID=0 |
| Trade.PositionOpen | Procedure | Reads SpreadGroupID from Customer/Instrument |
| Customer.SetSpreadGroup | Procedure | Updates Customer.SpreadGroupID |
| Internal.Newcurrency | Procedure | JOIN for spread config validation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TSPG | CLUSTERED (PK) | SpreadGroupID | - | - | Active |
| TSPG_NAME | NC (UNIQUE) | Name | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TSPG | PK | SpreadGroupID primary key |
| TSPG_NAME | UNIQUE | Name must be unique across all spread groups |

---

## 8. Sample Queries

### 8.1 List all spread groups with their names
```sql
SELECT SpreadGroupID,
       Name
  FROM Trade.SpreadGroup WITH (NOLOCK)
 ORDER BY SpreadGroupID
```

### 8.2 Get spread group plus linked spreads (Bid/Ask per Provider/Instrument)
```sql
SELECT SpreadGroupID,
       Name,
       SpreadID,
       ProviderID,
       InstrumentID,
       Bid,
       Ask
  FROM Trade.GetSpreadGroup WITH (NOLOCK)
 WHERE SpreadGroupID = 0
```

### 8.3 Find spread groups used by customers
```sql
SELECT SG.SpreadGroupID,
       SG.Name,
       COUNT(DISTINCT C.CID) AS CustomerCount
  FROM Trade.SpreadGroup SG WITH (NOLOCK)
  JOIN Customer.Customer C WITH (NOLOCK) ON C.SpreadGroupID = SG.SpreadGroupID
 GROUP BY SG.SpreadGroupID, SG.Name
 ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SpreadGroup | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.SpreadGroup.sql*
