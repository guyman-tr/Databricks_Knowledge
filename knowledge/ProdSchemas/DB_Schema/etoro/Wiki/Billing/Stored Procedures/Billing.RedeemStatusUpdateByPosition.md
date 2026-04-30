# Billing.RedeemStatusUpdateByPosition

> Convenience wrapper for Billing.RedeemStatusUpdate that resolves the RedeemID from a PositionID before updating the redeem's status.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID - caller knows position, not redeem |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Some systems (particularly the trading engine) work primarily with `PositionID` rather than `RedeemID`. `Billing.RedeemStatusUpdateByPosition` allows them to update a redeem's status using only the PositionID - it looks up the RedeemID internally and then delegates to `Billing.RedeemStatusUpdate`, which enforces the state machine.

The lookup joins `Billing.Redeem` with `Dictionary.RedeemStatus` but does not filter by status - it finds the RedeemID for any redeem associated with the given position. If no non-terminated active redeem exists (RedeemID stays 0), it raises error 60025. This is a thin orchestration layer with no business logic of its own - all state machine enforcement, validation, and field updates happen in `Billing.RedeemStatusUpdate`.

---

## 2. Business Logic

### 2.1 PositionID-to-RedeemID Resolution

**What**: Maps a PositionID to its active RedeemID before calling the state machine update.

**Columns/Parameters Involved**: `@PositionID`, `RedeemID`

**Rules**:
- SELECT RedeemID FROM Billing.Redeem INNER JOIN Dictionary.RedeemStatus WHERE PositionID = @PositionID (no status filter applied in the SELECT).
- If RedeemID > 0: delegates to EXEC Billing.RedeemStatusUpdate with all provided parameters.
- If RedeemID = 0 (no record found): raises RAISERROR(60025) "attempt to process from illegal position id."
- Does NOT filter out terminated redeems in the lookup - if there are multiple redeems for a position, the behavior depends on which one is returned (non-deterministic without a filter).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Trading position ID. Used to look up the associated RedeemID from Billing.Redeem. BIGINT since June 2021. |
| 2 | @RedeemStatusID | INT | NO | - | CODE-BACKED | Target status. Passed through to Billing.RedeemStatusUpdate which validates it against Dictionary.RedeemStatusStateMachine. |
| 3 | @RedeemReasonID | INT | YES | NULL | CODE-BACKED | Optional reason code. Passed through to RedeemStatusUpdate. |
| 4 | @Remark | VARCHAR(500) | YES | NULL | CODE-BACKED | Optional free-text remark. Passed through. |
| 5 | @Amount | MONEY | YES | NULL | CODE-BACKED | Settlement amount. Only used by RedeemStatusUpdate when transitioning to status 6 (PositionClosed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Billing.Redeem | READ | Looks up RedeemID by PositionID |
| All params | Billing.RedeemStatusUpdate | EXEC callee | Delegates all status update logic |
| (join in lookup) | Dictionary.RedeemStatus | READ (join) | Joined in the RedeemID lookup query |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by external services that work with PositionID.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RedeemStatusUpdateByPosition (procedure)
├── Billing.Redeem (table)
├── Dictionary.RedeemStatus (table)
└── Billing.RedeemStatusUpdate (procedure)
      ├── Billing.Redeem (table)
      └── Dictionary.RedeemStatusStateMachine (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | SELECT to resolve RedeemID from @PositionID |
| Dictionary.RedeemStatus | Table | JOIN in the RedeemID lookup (not filtered, just joined) |
| Billing.RedeemStatusUpdate | Procedure | EXEC - all state machine logic delegated here |

### 6.2 Objects That Depend On This

No SQL dependents found. Called by external trading services.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RedeemID > 0 check | Business rule | If no active redeem found for PositionID, error 60025. |

---

## 8. Sample Queries

### 8.1 Update redeem status using PositionID

```sql
EXEC Billing.RedeemStatusUpdateByPosition
    @PositionID = 9876543210,
    @RedeemStatusID = 6,
    @Amount = 485.50
```

### 8.2 Find the RedeemID for a given position (what this procedure resolves internally)

```sql
SELECT r.RedeemID, r.RedeemStatusID, rs.Name AS StatusName, r.RequestDate
FROM Billing.Redeem r WITH (NOLOCK)
INNER JOIN Dictionary.RedeemStatus rs WITH (NOLOCK) ON r.RedeemStatusID = rs.RedeemStatusID
WHERE r.PositionID = 9876543210
```

### 8.3 Check redeem history for a position

```sql
SELECT r.RedeemID, r.RedeemStatusID, r.AmountOnRequest, r.AmountOnClose,
       r.RequestDate, r.LastModificationDate
FROM Billing.Redeem r WITH (NOLOCK)
WHERE r.PositionID = 9876543210
ORDER BY r.RequestDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 callee analyzed (RedeemStatusUpdate) | App Code: skipped | Corrections: 0 applied*
*Object: Billing.RedeemStatusUpdateByPosition | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.RedeemStatusUpdateByPosition.sql*
