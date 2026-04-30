# Trade.GetMirrorEquity

> Returns the realized equity of a CopyTrader mirror relationship in cents, for equity calculation services.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: MirrorID + MirrorEquityCents |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMirrorEquity is a lightweight procedure that returns the realized equity of a specific mirror relationship, converted to cents (multiplied by 100). This supports the equity calculation pipeline where financial values are processed in cent units for precision.

This procedure exists as a simple equity lookup used by services that need just the mirror's equity value without the full mirror data payload. The realized equity represents the mirror's cash value (investment + realized PnL - withdrawals), excluding unrealized PnL from open positions.

---

## 2. Business Logic

### 2.1 Equity in Cents Conversion

**What**: Returns mirror realized equity multiplied by 100 for cent-based processing.

**Columns/Parameters Involved**: `@MirrorID`, `Trade.Mirror.RealizedEquity`

**Rules**:
- MirrorEquityCents = RealizedEquity * 100
- Returns the @MirrorID as an echo for correlation
- Empty result if MirrorID doesn't exist

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @MirrorID | int | IN | - | CODE-BACKED | The CopyTrader mirror ID to look up equity for. |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | MirrorID | int | NO | CODE-BACKED | Echo of the input MirrorID for correlation. |
| 2 | MirrorEquityCents | money | YES | CODE-BACKED | Mirror realized equity in cents (RealizedEquity * 100). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Mirror | SELECT (READER) | Reads RealizedEquity for the mirror |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Equity services) | Direct call | Application | Mirror equity calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorEquity (procedure)
+-- Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | SELECT RealizedEquity by MirrorID |

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

### 8.1 Get mirror equity

```sql
EXEC Trade.GetMirrorEquity @MirrorID = 12345;
```

### 8.2 Compare equity across mirrors

```sql
SELECT  MirrorID,
        RealizedEquity,
        RealizedEquity * 100 AS EquityCents,
        Amount,
        IsActive
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   ParentCID = 11111
ORDER BY RealizedEquity DESC;
```

### 8.3 Check equity vs investment

```sql
SELECT  MirrorID,
        InitialInvestment,
        DepositSummary,
        WithdrawalSummary,
        RealizedEquity,
        RealizedEquity - (InitialInvestment + DepositSummary - WithdrawalSummary) AS RealizedPnL
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   MirrorID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorEquity | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorEquity.sql*
