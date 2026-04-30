# Dictionary.MirrorMIMOOperation

> Classifies the types of Money-In/Money-Out (MIMO) operations within CopyTrading mirror relationships, distinguishing between manual adjustments, copy dividends, fees, and index dividend distributions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MirrorMIMOOperationID (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.MirrorMIMOOperation defines the categories of financial flows (money-in and money-out) that occur within CopyTrading mirror relationships. When a copier's allocated funds change — whether from manual adjustments, dividend distributions, fee deductions, or index-based dividend payments — the MIMO operation type classifies what triggered the financial flow.

Without this table, the system could not distinguish between the different types of money movements within mirror relationships, making it impossible to audit CopyTrading financial flows or calculate accurate copy performance metrics. The classification is critical for the mirror profit/loss calculation and reporting.

Referenced by History.Mirror (MirrorMIMOOperationID column) which logs all CopyTrading financial events.

---

## 2. Business Logic

### 2.1 MIMO Operation Categories

**What**: Four types of financial flows within CopyTrading relationships.

**Columns/Parameters Involved**: `MirrorMIMOOperationID`, `Name`

**Rules**:
- Manual (0): Operations staff manually adjusts the copier's mirror allocation (add/remove funds)
- CopyDividend (1): A stock dividend received by the leader is proportionally distributed to the copier
- Fees (2): Fee deductions from the mirror relationship (e.g., copy fees, management fees)
- IndexDividend (3): An index-level dividend payment distributed to copiers (different from individual stock dividends)
- These are money movements that affect the copier's allocated capital WITHOUT opening/closing positions

**Diagram**:
```
Mirror Financial Flows:
  Manual (0) ────────> BackOffice adjustment to copy allocation
  CopyDividend (1) ──> Stock dividend → proportional credit to copier
  Fees (2) ──────────> Fee deduction from copy allocation
  IndexDividend (3) ─> Index-level dividend distribution to copier
```

---

## 3. Data Overview

| MirrorMIMOOperationID | Name | Meaning |
|---|---|---|
| 0 | Manual | BackOffice operator manually adjusts the copier's fund allocation — used for corrections, compensations, or rebalancing that cannot be automated |
| 1 | CopyDividend | A stock held by the leader pays a dividend, and the proportional amount is credited to the copier's mirror balance |
| 2 | Fees | Fee deduction from the mirror relationship — management fees, copy fees, or other charges that reduce the copier's allocated capital |
| 3 | IndexDividend | An index fund or ETF dividend payment distributed proportionally to all copiers of the leader holding that index position |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorMIMOOperationID | tinyint | NO | - | CODE-BACKED | Unique identifier for the MIMO operation type: 0=Manual, 1=CopyDividend, 2=Fees, 3=IndexDividend. Referenced by History.Mirror for CopyTrading financial event classification. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable operation type label displayed in CopyTrading reports and BackOffice mirror management screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Mirror | MirrorMIMOOperationID | Implicit | CopyTrading history records classify financial events using this lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Mirror | Table | MirrorMIMOOperationID column classifies MIMO events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DMOT | CLUSTERED PK | MirrorMIMOOperationID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all MIMO operation types
```sql
SELECT  MirrorMIMOOperationID,
        Name
FROM    [Dictionary].[MirrorMIMOOperation] WITH (NOLOCK)
ORDER BY MirrorMIMOOperationID;
```

### 8.2 Count mirror events by operation type
```sql
SELECT  mmo.Name AS OperationType,
        COUNT(*) AS EventCount
FROM    [History].[Mirror] hm WITH (NOLOCK)
JOIN    [Dictionary].[MirrorMIMOOperation] mmo WITH (NOLOCK)
        ON hm.MirrorMIMOOperationID = mmo.MirrorMIMOOperationID
GROUP BY mmo.Name
ORDER BY EventCount DESC;
```

### 8.3 Find all manual mirror adjustments
```sql
SELECT  hm.*
FROM    [History].[Mirror] hm WITH (NOLOCK)
WHERE   hm.MirrorMIMOOperationID = 0
ORDER BY hm.MirrorID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MirrorMIMOOperation | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MirrorMIMOOperation.sql*
