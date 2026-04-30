# Dictionary.FeeOperationTypes

> Lookup table defining the trading operation phases (Open, Close, or All) at which fees can be applied.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FeeOperationTypeID (TINYINT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FeeOperationTypes defines at which phase of a trading operation a fee is charged — when a position is opened, when it is closed, or at both phases. This controls the timing dimension of the platform's fee engine: different fee configurations (spread markups, fixed-per-lot charges, percentage-based fees) can be applied at different stages of a trade's lifecycle.

This table is a building block of the fee system. It is referenced by fee configuration tables (`Trade.FixPerLotConfigurations`, `Trade.FeeInPercentageConfigurations`) and related validation procedures to determine when a fee kicks in. For example, a spread fee might apply only at Open, while a withdrawal conversion fee applies at Close.

The table is loaded by `Trade.GetFeeOperationTypesDictionary` for caching in the trading engine, and is validated by `Trade.ValidateFeeInPercentageConfigurations` and `Trade.ValidateFixPerLotConfigurations` before fee configuration changes are accepted.

---

## 2. Business Logic

### 2.1 Fee Timing Phases

**What**: Fees can be charged at position open, position close, or both — this table defines those phases.

**Columns/Parameters Involved**: `FeeOperationTypeID`, `Name`

**Rules**:
- **Open (1)**: Fee charged when the position is first opened. Examples: opening spread, entry commission.
- **Close (2)**: Fee charged when the position is closed. Examples: exit spread, close commission.
- **All (3)**: Fee applies to both open and close operations. Examples: per-lot charges that apply symmetrically.

**Diagram**:
```
Position Lifecycle:
  OPEN ──────────────── CLOSE
   │                      │
   ├─ FeeOperationType=1  ├─ FeeOperationType=2
   │  (Open fees)         │  (Close fees)
   │                      │
   └──── FeeOperationType=3 ────┘
         (Applied at both phases)
```

---

## 3. Data Overview

| FeeOperationTypeID | Name | Meaning |
|---|---|---|
| 1 | Open | Fee is charged at position opening — e.g., opening spread markup, entry commission. Applied once when the trade executes. |
| 2 | Close | Fee is charged at position closing — e.g., closing spread, exit commission. Applied when the user closes or the system auto-closes the position. |
| 3 | All | Fee applies symmetrically at both open and close — e.g., a per-lot charge that is applied at each phase of the trade. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FeeOperationTypeID | tinyint | NO | - | VERIFIED | Fee timing phase: **1**=Open (at position entry), **2**=Close (at position exit), **3**=All (both phases). Referenced by Trade.FixPerLotConfigurations, Trade.FeeInPercentageConfigurations, and fee validation procedures. Also linked from Dictionary.OperationType for fee operation categorization. |
| 2 | Name | varchar(100) | NO | - | VERIFIED | Human-readable phase label: "Open", "Close", "All". Used in trading engine configuration and admin UIs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.FixPerLotConfigurations | FeeOperationTypeID | Implicit | Fixed-per-lot fee configs specify when the fee applies |
| Trade.FeeInPercentageConfigurations | FeeOperationTypeID | Implicit | Percentage-based fee configs specify when the fee applies |
| Dictionary.OperationType | FeeOperationTypeID | Implicit | Links trading operation types to fee timing phases |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.FeeOperationTypes (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FixPerLotConfigurations | Table | References FeeOperationTypeID |
| Trade.FeeInPercentageConfigurations | Table | References FeeOperationTypeID |
| Dictionary.OperationType | Table | References FeeOperationTypeID |
| Trade.GetFeeOperationTypesDictionary | Stored Procedure | Full read for trading engine cache |
| Trade.ValidateFeeInPercentageConfigurations | Stored Procedure | Validates fee config references valid operation type |
| Trade.ValidateFixPerLotConfigurations | Stored Procedure | Validates fix-per-lot config references valid operation type |
| Trade.AddFeeInPercentageConfigurations | Stored Procedure | Creates new percentage fee configs |
| Trade.AddFixPerLotConfigurations | Stored Procedure | Creates new fixed-per-lot fee configs |
| Trade.FnGetCloseFixPerLot | Function | Retrieves close-phase fixed fees |
| Trade.FnGetCloseFeeInPercentage | Function | Retrieves close-phase percentage fees |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_FeeOperationTypes | CLUSTERED PK | FeeOperationTypeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_FeeOperationTypes | PRIMARY KEY | Unique fee operation type, FILLFACTOR 95, DICTIONARY filegroup |

---

## 8. Sample Queries

### 8.1 List all fee operation types
```sql
SELECT  FeeOperationTypeID,
        Name
FROM    Dictionary.FeeOperationTypes WITH (NOLOCK)
ORDER BY FeeOperationTypeID;
```

### 8.2 Find all fee configurations by operation phase
```sql
SELECT  fot.Name            AS FeePhase,
        COUNT(*)            AS ConfigCount
FROM    Trade.FixPerLotConfigurations fpl WITH (NOLOCK)
JOIN    Dictionary.FeeOperationTypes fot WITH (NOLOCK)
        ON fpl.FeeOperationTypeID = fot.FeeOperationTypeID
GROUP BY fot.Name;
```

### 8.3 Show all close-phase fee configurations
```sql
SELECT  fpl.InstrumentID,
        fot.Name            AS FeePhase,
        fpl.Value           AS FeeAmount
FROM    Trade.FixPerLotConfigurations fpl WITH (NOLOCK)
JOIN    Dictionary.FeeOperationTypes fot WITH (NOLOCK)
        ON fpl.FeeOperationTypeID = fot.FeeOperationTypeID
WHERE   fpl.FeeOperationTypeID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FeeOperationTypes | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FeeOperationTypes.sql*
