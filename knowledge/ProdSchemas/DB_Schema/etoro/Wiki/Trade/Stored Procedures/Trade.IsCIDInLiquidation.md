# Trade.IsCIDInLiquidation

> Sets the @InLiquidation OUTPUT bit to 1 if the given CID exists in Trade.CIDsInLiquidation (currently being liquidated), or 0 if not.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the customer to check; @InLiquidation OUTPUT - result bit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IsCIDInLiquidation is a fast predicate procedure that tells the caller whether a specific customer's account is currently in an active liquidation process. When a customer's account is being liquidated (positions being force-closed due to margin breach or regulatory action), their CID is present in Trade.CIDsInLiquidation. This procedure encapsulates the membership check into a single call with an OUTPUT bit parameter, making it easy for services to gate logic based on liquidation state without directly querying the registry table.

Use cases include: preventing new order placement for customers in liquidation, skipping certain processing steps, or routing to liquidation-specific workflows. The procedure uses an OUTPUT parameter (bit) rather than a result set, making it suitable for integration in T-SQL control flow (IF @InLiquidation = 1).

Data flow: Liquidation state is written by the liquidation management procedures (InsertCIDIntoLiquidation, RemoveCIDFromLiquidation) which add/remove rows in Trade.CIDsInLiquidation. This procedure is the read-side check.

---

## 2. Business Logic

### 2.1 Liquidation State Check

**What**: IF EXISTS on Trade.CIDsInLiquidation, sets @InLiquidation OUTPUT to 1 or 0.

**Columns/Parameters Involved**: `@CID`, `@InLiquidation OUTPUT`, `Trade.CIDsInLiquidation.CID`

**Rules**:
- IF EXISTS (SELECT * FROM Trade.CIDsInLiquidation WHERE CID = @CID): SET @InLiquidation = 1.
- ELSE: SET @InLiquidation = 0.
- Always returns via OUTPUT param; no result set rows are emitted.
- No NOCOUNT, no transaction, no error handling - minimal overhead for a frequently-called predicate.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | The customer ID to check for active liquidation. FK to Trade.CIDsInLiquidation.CID. |
| 2 | @InLiquidation | bit OUTPUT | NO | - | CODE-BACKED | OUTPUT. 1 if CID is currently in Trade.CIDsInLiquidation (active liquidation). 0 if not in liquidation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IF EXISTS | Trade.CIDsInLiquidation | Reader | Checks whether @CID has an active liquidation record |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called by trading and order management services to check liquidation state before processing operations for a customer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IsCIDInLiquidation (procedure)
└── Trade.CIDsInLiquidation (table) - IF EXISTS check
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CIDsInLiquidation | Table | Existence check: is @CID currently in liquidation? |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Order/trading services | External (Application) | Calls to gate operations for customers currently in active liquidation |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OUTPUT bit pattern | Design | Returns result via @InLiquidation OUTPUT rather than result set - suitable for T-SQL IF conditions |
| No NOCOUNT | Design | Row count messages may be emitted; no explicit suppression in this procedure |

---

## 8. Sample Queries

### 8.1 Check if a CID is in liquidation

```sql
DECLARE @InLiq BIT;
EXEC Trade.IsCIDInLiquidation @CID = 12345, @InLiquidation = @InLiq OUTPUT;
SELECT @InLiq AS IsInLiquidation;
-- 1 = currently in liquidation, 0 = not in liquidation
```

### 8.2 View current liquidation records

```sql
SELECT CID, IsManual, InsertionDate
FROM Trade.CIDsInLiquidation WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IsCIDInLiquidation | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IsCIDInLiquidation.sql*
