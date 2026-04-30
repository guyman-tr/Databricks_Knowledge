# Trade.SplitRealInDemoMap

> Bidirectional 1:1 mapping between real (production) and demo instrument IDs used during stock split operations so splits on real instruments can be replicated in the demo environment.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | RealID (int, PK), DemoID (int, UNIQUE) |
| **Partition** | No |
| **Indexes** | 2 active (PK CLUSTERED on RealID, UC_DemoID UNIQUE on DemoID) |

---

## 1. Business Meaning

Trade.SplitRealInDemoMap is a simple two-column mapping table that establishes a strict 1:1 relationship between real (production) instrument IDs and demo environment instrument IDs. It models the concept: "When instrument X in production undergoes a stock split, instrument Y in demo is the corresponding instrument that must receive the same split treatment."

This table exists because stock splits in the real trading environment must be mirrored in the demo environment for consistency. When a split is executed on a real instrument, the system needs to locate the demo counterpart so the same split logic can be applied to demo positions and orders. Without this mapping, demo users would experience incorrect position sizes and prices after a split occurs in production.

Data flows: Rows are inserted when a stock split is scheduled or executed for instruments that exist in both environments. Consumers read this table during split processing to look up either RealID from DemoID or DemoID from RealID. The table is intentionally kept empty when no splits are in progress; it is populated on demand during split operations. Live data is currently empty.

---

## 2. Business Logic

### 2.1 Bidirectional 1:1 Constraint

**What**: Both RealID and DemoID must be unique across all rows, enforcing strict one-to-one mapping.

**Columns/Parameters Involved**: `RealID`, `DemoID`

**Rules**:
- PK on RealID: each real instrument maps to at most one demo instrument
- UNIQUE on DemoID: each demo instrument maps to at most one real instrument
- Together: no duplicate mappings in either direction. Lookup by RealID or DemoID returns at most one row.
- When a split occurs on RealID=100, the system finds DemoID=200 (if mapped) and applies split to demo instrument 200

**Diagram**:
```
Real Environment          Demo Environment
RealID=100 (AAPL)   ->   DemoID=200 (AAPL_demo)
      |                          |
      +-- Stock split event ----> Replicate split on DemoID=200
```

---

## 3. Data Overview

| RealID | DemoID | Meaning |
|---|---|---|
| (Table is EMPTY in environment) | - | No live rows. When populated during a stock split: each row would map a production instrument (RealID) to its demo counterpart (DemoID). Example: RealID=1001 (AAPL in prod) -> DemoID=5001 (AAPL in demo) allows the split processor to apply the same split adjustment to demo positions. |

**Selection criteria:**
- Table is empty. Representative rows would show RealID (from Trade.Instrument) mapped to DemoID (from demo Trade.Instrument) for instruments that exist in both environments and are subject to a split.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RealID | int | NO | - | CODE-BACKED | Primary key. Instrument ID in the production (real) environment. References Trade.Instrument.InstrumentID. When a stock split is executed on this instrument, the system looks up the corresponding DemoID to replicate the split in demo. |
| 2 | DemoID | int | NO | - | CODE-BACKED | Instrument ID in the demo environment. UNIQUE constraint (UC_DemoID) ensures each demo instrument maps to exactly one real instrument. References the demo instance of Trade.Instrument.InstrumentID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RealID | Trade.Instrument | Implicit | Real environment instrument affected by the split. |
| DemoID | Trade.Instrument (demo) | Implicit | Demo environment instrument that receives the replicated split. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Procedures not analyzed in this phase) | - | Lookup | Split processing procedures read this table to map real to demo instruments. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SplitRealInDemoMap (table)
(No code-level dependencies - CREATE TABLE has no FROM/JOIN)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Not analyzed in this phase) | Procedure | Split replication logic likely reads this table. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SplitRealInDemoMap (or similar) | CLUSTERED | RealID | - | - | Active |
| UC_DemoID | UNIQUE NONCLUSTERED | DemoID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (RealID) | PRIMARY KEY | RealID is the primary key; each real instrument maps to at most one row |
| UC_DemoID | UNIQUE | DemoID must be unique; each demo instrument maps to at most one real instrument |

---

## 8. Sample Queries

### 8.1 Look up demo instrument for a real instrument

```sql
SELECT DemoID
FROM Trade.SplitRealInDemoMap WITH (NOLOCK)
WHERE RealID = 1001;
```

### 8.2 Look up real instrument for a demo instrument

```sql
SELECT RealID
FROM Trade.SplitRealInDemoMap WITH (NOLOCK)
WHERE DemoID = 5001;
```

### 8.3 List all real-to-demo mappings

```sql
SELECT s.RealID, s.DemoID, iReal.Symbol AS RealSymbol, iDemo.Symbol AS DemoSymbol
FROM Trade.SplitRealInDemoMap s WITH (NOLOCK)
LEFT JOIN Trade.Instrument iReal WITH (NOLOCK) ON iReal.InstrumentID = s.RealID
LEFT JOIN Trade.Instrument iDemo WITH (NOLOCK) ON iDemo.InstrumentID = s.DemoID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SplitRealInDemoMap | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.SplitRealInDemoMap.sql*
