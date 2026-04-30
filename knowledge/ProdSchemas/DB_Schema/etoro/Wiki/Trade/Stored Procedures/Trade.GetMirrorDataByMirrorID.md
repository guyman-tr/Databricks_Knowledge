# Trade.GetMirrorDataByMirrorID

> Returns the core CopyTrader mirror relationship details (investment amount, PnL, stop-loss, status) for a specific MirrorID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Trade.Mirror record by MirrorID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorDataByMirrorID is a simple, direct lookup of a CopyTrader mirror relationship by its ID. It returns the core financial and status fields: who is copying whom, the current investment amount, accumulated deposits/withdrawals, net profit, stop-loss settings, and activation status.

This procedure exists as a lightweight mirror data reader - unlike the more complex GetMirrorDataWithCIDAndMirrorIdForAPI (which also returns positions, orders, and hierarchy), this returns only the mirror record itself. It's suitable for quick status checks and summaries.

---

## 2. Business Logic

### 2.1 Direct Mirror Lookup

**What**: Simple SELECT from Trade.Mirror by primary key.

**Columns/Parameters Involved**: `@MirrorID`, `Trade.Mirror`

**Rules**:
- Returns a single row for the matching MirrorID
- Occurred column is aliased as StartedCopyDate for API clarity
- All financial amounts are in dollars (not cents - unlike Trade.GetMirrorData)
- Returns empty if MirrorID doesn't exist

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @MirrorID | int | IN | - | CODE-BACKED | The CopyTrader mirror relationship ID to look up. |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | MirrorID | int | NO | CODE-BACKED | Unique mirror relationship identifier. |
| 2 | CID | int | NO | CODE-BACKED | Copier's customer ID. |
| 3 | ParentCID | int | YES | CODE-BACKED | The trader being copied. |
| 4 | ParentUserName | varchar | YES | CODE-BACKED | Display name of the copied trader. |
| 5 | Amount | money | YES | CODE-BACKED | Current mirror investment amount in dollars. |
| 6 | IsActive | bit | YES | CODE-BACKED | Whether the copy relationship is active. |
| 7 | InitialInvestment | money | YES | CODE-BACKED | Original investment when copying started. |
| 8 | DepositSummary | money | YES | CODE-BACKED | Total additional deposits into this mirror. |
| 9 | WithdrawalSummary | money | YES | CODE-BACKED | Total withdrawals from this mirror. |
| 10 | NetProfit | money | YES | CODE-BACKED | Accumulated net profit/loss from all copied positions. |
| 11 | MirrorStatusID | int | YES | CODE-BACKED | Mirror lifecycle status. |
| 12 | MirrorSLPercentage | decimal | YES | CODE-BACKED | Stop-loss percentage threshold. |
| 13 | MirrorSL | money | YES | CODE-BACKED | Stop-loss absolute amount in dollars. |
| 14 | StartedCopyDate | datetime | YES | CODE-BACKED | When the copy relationship was created. Aliased from Trade.Mirror.Occurred. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Mirror | SELECT (READER) | Reads mirror relationship record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No explicit DB-level callers found) | - | - | Likely called from application services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorDataByMirrorID (procedure)
+-- Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | SELECT by MirrorID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No DB-level dependents found) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get mirror data

```sql
EXEC Trade.GetMirrorDataByMirrorID @MirrorID = 12345;
```

### 8.2 Check active mirrors for a trader

```sql
SELECT  MirrorID, CID, Amount, NetProfit, IsActive, Occurred AS StartedCopyDate
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   ParentCID = 11111
        AND IsActive = 1
ORDER BY Occurred DESC;
```

### 8.3 Mirror investment summary

```sql
SELECT  MirrorID,
        CID,
        ParentCID,
        InitialInvestment,
        DepositSummary,
        WithdrawalSummary,
        Amount AS CurrentAmount,
        NetProfit,
        MirrorSLPercentage
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   MirrorID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorDataByMirrorID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorDataByMirrorID.sql*
