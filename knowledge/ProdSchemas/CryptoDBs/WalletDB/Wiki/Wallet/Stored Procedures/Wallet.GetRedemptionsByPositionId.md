# Wallet.GetRedemptionsByPositionId

> Returns only the redemption status values for a trading position - a lightweight version of GetRedemptionByPositionId for quick status checks without full record details.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns redemption statuses for a position ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a lightweight status-check companion to `Wallet.GetRedemptionByPositionId`. While the latter returns the full redemption record, this procedure returns only the redemption status value(s), making it faster and less resource-intensive for scenarios where the caller just needs to know "what state is this redemption in?"

This supports quick decision-making in the trading platform - for example, determining whether a position's redemption is still pending before allowing a user action, or checking if all redemption attempts for a position have completed.

Data comes from `Wallet.Redemptions` with NOLOCK hint. The status is explicitly CAST to INT for compatibility with callers that expect integer types rather than tinyint.

---

## 2. Business Logic

### 2.1 Status-Only Lookup

**What**: Returns just the redemption status for each redemption associated with a position.

**Columns/Parameters Involved**: `@PositionId`, `Redemptions.RedemptionStatus`

**Rules**:
- Returns one row per redemption record for the position
- Status is CAST to INT (from tinyint) for caller compatibility
- Values: 0=Pending, 1=Processing, 2=WasSent
- Multiple rows indicate multiple redemption attempts for the same position

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionId | bigint | NO | - | CODE-BACKED | The eToro trading position ID to check redemption status for. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RedemptionStatus | int | NO | - | CODE-BACKED | Redemption workflow status cast to INT: 0=Pending (awaiting processing), 1=Processing (being executed), 2=WasSent (blockchain transaction submitted). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Wallet.Redemptions | FROM | Status lookup by PositionId |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No SQL callers found) | - | - | Called from trading/application layer for quick status checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetRedemptionsByPositionId (procedure)
└── Wallet.Redemptions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | SELECT with NOLOCK - status lookup by PositionId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (No dependents found in SQL) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK hint | Read isolation | Non-blocking read for real-time status checks |
| CAST(RedemptionStatus AS INT) | Type compatibility | Converts tinyint to int for caller compatibility |

---

## 8. Sample Queries

### 8.1 Quick redemption status check
```sql
EXEC Wallet.GetRedemptionsByPositionId @PositionId = 123456789;
```

### 8.2 Check if any redemptions for a position are still in progress
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Wallet.Redemptions WITH (NOLOCK)
    WHERE PositionId = 123456789 AND RedemptionStatus < 2
) THEN 1 ELSE 0 END AS HasPendingRedemptions;
```

### 8.3 Compare full vs lightweight redemption lookups
```sql
-- Full details (GetRedemptionByPositionId equivalent)
SELECT Id, PositionId, RequestedAmount, RedemptionStatus
FROM Wallet.Redemptions WITH (NOLOCK) WHERE PositionId = 123456789;

-- Status only (GetRedemptionsByPositionId equivalent)
SELECT CAST(RedemptionStatus AS INT) AS RedemptionStatus
FROM Wallet.Redemptions WITH (NOLOCK) WHERE PositionId = 123456789;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetRedemptionsByPositionId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetRedemptionsByPositionId.sql*
