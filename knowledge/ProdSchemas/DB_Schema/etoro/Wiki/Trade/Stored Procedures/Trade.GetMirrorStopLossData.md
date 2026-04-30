# Trade.GetMirrorStopLossData

> Returns the Mirror Stop-Loss percentage for a specific mirror, used to check the current MSL threshold before mirror-level operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - identifies the mirror |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorStopLossData` retrieves the `MirrorSLPercentage` (Mirror Stop-Loss percentage) for a given mirror. The Mirror Stop-Loss (MSL) is the maximum loss a copy relationship can sustain, expressed as a percentage of the allocated amount. When the copier's portfolio loses this percentage, the mirror is automatically closed.

This procedure exists as a lightweight read to check the current MSL setting for a mirror, used by services that need the current stop-loss threshold for validation or display.

Data flows: Called when the MSL value is needed for a specific mirror - for example, to validate a new MSL edit request or to display the current threshold. Returns a single-column, single-row result.

---

## 2. Business Logic

### 2.1 Mirror Stop-Loss Percentage

**What**: The MSL percentage defines the loss threshold that triggers automatic mirror closure.

**Columns/Parameters Involved**: `MirrorSLPercentage`

**Rules**:
- `MirrorSLPercentage` is stored as a percentage value (e.g., 40 = 40% loss triggers closure).
- Valid range enforced by `GetMirrorValidation`: between `MinMirrorSLPercentage` and `MaxMirrorSLPercentage` for the mirror type.
- NULL = no MSL set for this mirror.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The mirror identifier. Returns MirrorSLPercentage for this mirror from Trade.Mirror. |

**Output columns** (result set):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | MirrorSLPercentage | Trade.Mirror | The Mirror Stop-Loss percentage threshold. When the copier's loss on this copy reaches this percentage of allocated amount, the mirror auto-closes. NULL = no MSL set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | Lookup | Reads MirrorSLPercentage for the specified mirror. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorStopLossData (procedure)
└── Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | SELECT MirrorSLPercentage WHERE MirrorID = @MirrorID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get mirror stop-loss percentage

```sql
EXEC Trade.GetMirrorStopLossData @MirrorID = 12345;
```

### 8.2 Find mirrors with high stop-loss thresholds

```sql
SELECT MirrorID, CID, ParentCID, MirrorSLPercentage
FROM Trade.Mirror WITH (NOLOCK)
WHERE MirrorSLPercentage > 50
  AND IsActive = 1
ORDER BY MirrorSLPercentage DESC;
```

### 8.3 Find mirrors with no stop-loss set

```sql
SELECT MirrorID, CID, ParentCID
FROM Trade.Mirror WITH (NOLOCK)
WHERE MirrorSLPercentage IS NULL
  AND IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9/10, Logic: 6/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorStopLossData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorStopLossData.sql*
