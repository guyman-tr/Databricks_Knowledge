# Dictionary.PositionOpenOpenOperationType

> Lookup table defining 2 CopyTrading position-open operation types — RegisterMirror (new copy relationship) and MirrorAddFunds (adding funds to existing copy).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PositionOpenOpenOperationTypeID (INT, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PositionOpenOpenOperationType defines the two CopyTrading operations that trigger position opens on behalf of a copying investor. When a customer starts copying a trader (RegisterMirror) or adds funds to an existing copy relationship (MirrorAddFunds), the platform automatically opens positions in the copier's account to match the copied trader's portfolio.

This table exists because these two CopyTrading flows — initial registration and subsequent fund additions — follow different position allocation logic. RegisterMirror creates a full set of positions matching the copied trader's current portfolio, while MirrorAddFunds proportionally increases existing copied positions based on the additional funds.

The PositionOpenOpenOperationTypeID is used internally by the CopyTrading position allocation engine to determine which allocation algorithm to apply.

---

## 2. Business Logic

### 2.1 CopyTrading Position Open Triggers

**What**: Two distinct CopyTrading operations cause automatic position opens for copying investors.

**Columns/Parameters Involved**: `PositionOpenOpenOperationTypeID`, `Name`

**Rules**:
- **RegisterMirror (1)** — Customer starts copying a new trader. The system snapshots the copied trader's current portfolio and opens proportional positions in the copier's account. Uses the initial allocated amount for position sizing.
- **MirrorAddFunds (2)** — Customer adds more funds to an existing copy relationship. The system proportionally increases the copier's positions to match the new total allocation. Position sizing is based on the incremental funds added.

**Diagram**:
```
CopyTrading Position Open Flows
├── 1 = RegisterMirror
│     Customer → "Start Copying Trader X with $1000"
│     System → Snapshot Trader X portfolio
│     System → Open proportional positions ($1000 allocation)
│
└── 2 = MirrorAddFunds
      Customer → "Add $500 to my copy of Trader X"
      System → Calculate proportional increase
      System → Increase existing positions / open new ones
```

---

## 3. Data Overview

| PositionOpenOpenOperationTypeID | Name | Meaning |
|---|---|---|
| 1 | RegisterMirror | Initial CopyTrading registration — customer starts copying a trader. The system opens a full set of proportional positions matching the copied trader's current portfolio. The founding event of a copy relationship. |
| 2 | MirrorAddFunds | Adding funds to an existing copy relationship — customer increases their allocation to a copied trader. The system proportionally scales up existing positions. Only valid for active copy relationships. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionOpenOpenOperationTypeID | int | NO | - | CODE-BACKED | Primary key identifying the position-open operation type. 1=RegisterMirror (new copy relationship), 2=MirrorAddFunds (add funds to existing copy). Used by the CopyTrading position allocation engine. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the operation type. "RegisterMirror" or "MirrorAddFunds". Used in CopyTrading audit logs and allocation reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct FK consumers found in the SSDT codebase. Used by the CopyTrading position allocation engine at the application layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryPositionOpenOpenOperationType | CLUSTERED PK | PositionOpenOpenOperationTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DictionaryPositionOpenOpenOperationType | PRIMARY KEY | Unique position-open operation type identifier |

---

## 8. Sample Queries

### 8.1 List all position-open operation types
```sql
SELECT  PositionOpenOpenOperationTypeID,
        Name
FROM    [Dictionary].[PositionOpenOpenOperationType] WITH (NOLOCK)
ORDER BY PositionOpenOpenOperationTypeID;
```

### 8.2 Lookup the RegisterMirror type
```sql
SELECT  PositionOpenOpenOperationTypeID,
        Name
FROM    [Dictionary].[PositionOpenOpenOperationType] WITH (NOLOCK)
WHERE   Name = 'RegisterMirror';
```

### 8.3 Map types to business descriptions
```sql
SELECT  PositionOpenOpenOperationTypeID,
        Name,
        CASE PositionOpenOpenOperationTypeID
            WHEN 1 THEN 'New copy relationship — full portfolio replication'
            WHEN 2 THEN 'Fund addition — proportional position scaling'
        END AS BusinessDescription
FROM    [Dictionary].[PositionOpenOpenOperationType] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PositionOpenOpenOperationType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PositionOpenOpenOperationType.sql*
