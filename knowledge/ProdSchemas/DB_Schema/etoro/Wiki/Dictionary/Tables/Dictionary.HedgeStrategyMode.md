# Dictionary.HedgeStrategyMode

> Lookup table defining the 3 hedging strategy modes for eToro's internal risk management.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | HedgeStrategyModeID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HedgeStrategyMode defines the strategies used by eToro's internal risk management (Hedge) team to manage the company's net market exposure from client positions. When users open CFD positions, eToro takes the counterparty side and must hedge its aggregate exposure to avoid unacceptable market risk.

This table classifies the hedging approach applied to different instrument groups or market conditions. The Hedge schema contains the operational tables that implement these strategies.

HedgeStrategyModeID is referenced by Hedge strategy configuration tables that define which strategy applies to which instruments.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| HedgeStrategyModeID | Description | Meaning |
|---|---|---|
| 1 | Auto | Fully automated hedging — the system automatically opens/closes hedge positions based on aggregate client exposure thresholds. No manual intervention needed. Default for liquid instruments. |
| 2 | Manual | Manually managed hedging — the risk team decides when and how to hedge. Used for illiquid instruments, unusual market conditions, or when automated systems are paused. |
| 3 | Disabled | No hedging applied — eToro absorbs the full counterparty risk. Used for instruments with negligible exposure or during specific market events where hedging is impractical. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | HedgeStrategyModeID | int | NO | - | CODE-BACKED | Primary key. 1=Auto (automated hedging), 2=Manual (risk team managed), 3=Disabled (no hedging). See [Hedge Strategy Mode](_glossary.md#hedge-strategy-mode). (Dictionary.HedgeStrategyMode) |
| 2 | Description | varchar(50) | NO | - | CODE-BACKED | Human-readable strategy description. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge strategy config tables | HedgeStrategyModeID | Implicit Lookup | Determines hedging behavior per instrument group |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeStrategyModeID | CLUSTERED PK | HedgeStrategyModeID ASC | - | - | Active |

---

## 8. Sample Queries

### 8.1 List all hedge strategy modes
```sql
SELECT HedgeStrategyModeID, Description
FROM [Dictionary].[HedgeStrategyMode] WITH (NOLOCK) ORDER BY HedgeStrategyModeID;
```

---

*Generated: 2026-03-13 | Quality: 7.0/10*
*Object: Dictionary.HedgeStrategyMode | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgeStrategyMode.sql*
