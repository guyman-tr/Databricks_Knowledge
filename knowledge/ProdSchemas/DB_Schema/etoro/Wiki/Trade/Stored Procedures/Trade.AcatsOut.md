# Trade.AcatsOut

> Processes an ACATS (Automated Customer Account Transfer Service) outbound transfer by closing the position at its original init rate, adjusting the mirror/copy-trade amount if applicable, and compensating the customer for the position value.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID (position being transferred out) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.AcatsOut handles the database side of an ACATS (Automated Customer Account Transfer Service) outbound transfer. ACATS is the US regulatory framework that allows customers to transfer brokerage positions between firms. When a customer initiates an outbound transfer, this procedure closes the position at its original opening rate (zero PnL), adjusts the copy-trade mirror amounts if the position was part of a copy relationship, and compensates the customer's balance for the full position value (CompensationReasonID=108).

The close uses ActionType=22 (ACATS Out) and sets EndForexRate = InitForexRate to ensure zero PnL on the close. The customer is then compensated via Customer.SetBalanceCompensation with a negative DeltaAmountInCents (position amount × -100, converting to cents), effectively moving the investment value from the position back to the customer's available balance as a compensation.

The procedure validates that the position is not already being closed (no entry in Trade.CloseExecutionPlan) and is not a mirrored/copy-trade position (MirrorID must be 0 for non-mirror logic, though mirror positions ARE handled with Trade.ChangeMirrorAmount).

---

## 2. Business Logic

### 2.1 Zero-PnL Close

**What**: Closes the position at InitForexRate to achieve zero profit/loss.

**Rules**:
- @EndForexRate = InitForexRate (from Trade.Position)
- @EndForexRateID = 0 (no real price snapshot)
- @LastOpConversionRate = 1 (no conversion adjustment)
- ActionType = 22 (ACATS Out close action)
- BidSpread = AskSpread = @EndForexRate (no spread impact)

### 2.2 Mirror Amount Adjustment

**What**: When the position is part of a copy-trade mirror, adjusts the mirror's amount.

**Rules**:
- Only when MirrorID > 0
- DeltaAmountInCents = Amount × -100 (removes the position's amount from mirror)
- Calls Trade.ChangeMirrorAmount with @EditMirrorSL=1 to recalculate mirror stop loss
- SessionID = -1 (system operation)

### 2.3 Customer Compensation

**What**: Compensates the customer for the transferred position value.

**Rules**:
- Payment = DeltaAmountInCents (negative = debit from position, credit to balance)
- CompensationReasonID = 108 (ACATS Out)
- ManagerID from BackOffice.Customer
- Description = 'Compensation caused by AcatsOut'

### 2.4 Pre-Close Validation

**What**: Validates the position exists and is not already being closed.

**Rules**:
- If MirrorID IS NULL (position not found): prints error, returns 1
- If exists in Trade.CloseExecutionPlan: prints error, returns 1 (position already being closed)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position to transfer out via ACATS. Must be open and not already in the close pipeline. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Position | SELECT | Reads position details (rate, mirror, instrument) |
| FROM | Trade.CloseExecutionPlan | SELECT | Validates position is not already closing |
| FROM | Trade.CurrencyPrice | SELECT | Gets skew values for spread calculation |
| FROM | BackOffice.Customer | SELECT | Gets ManagerID for compensation |
| EXEC | Trade.ManualPositionClose | EXEC | Closes the position at init rate |
| EXEC | Trade.ChangeMirrorAmount | EXEC | Adjusts mirror copy-trade amount |
| EXEC | Customer.SetBalanceCompensation | EXEC | Compensates customer for position value |
| FROM | Trade.Mirror | SELECT | Gets mirror RealizedEquity for mirror adjustment |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none found) | - | - | Likely called from application code or job scheduler |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AcatsOut (procedure)
+-- Trade.Position (view)
+-- Trade.CloseExecutionPlan (table)
+-- Trade.CurrencyPrice (table)
+-- BackOffice.Customer (table)
+-- Trade.Mirror (table)
+-- Trade.ManualPositionClose (procedure)
+-- Trade.ChangeMirrorAmount (procedure)
+-- Customer.SetBalanceCompensation (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT - position data |
| Trade.CloseExecutionPlan | Table | SELECT - close-in-progress check |
| Trade.CurrencyPrice | Table | SELECT - skew values |
| BackOffice.Customer | Table | SELECT - manager ID |
| Trade.Mirror | Table | SELECT - mirror realized equity |
| Trade.ManualPositionClose | Procedure | EXEC - closes position |
| Trade.ChangeMirrorAmount | Procedure | EXEC - adjusts mirror amount |
| Customer.SetBalanceCompensation | Procedure | EXEC - customer compensation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found in SSDT) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Position exists | Validation | MirrorID IS NULL → return 1 |
| Not already closing | Validation | CloseExecutionPlan exists → return 1 |
| Transaction commented out | Note | BEGIN TRANSACTION/COMMIT are commented out; each sub-call manages its own transaction |

---

## 8. Sample Queries

### 8.1 Check if a position is eligible for ACATS out

```sql
SELECT  p.PositionID, p.MirrorID, p.InitForexRate, p.Amount, p.StatusID,
        CASE WHEN cep.PositionID IS NOT NULL THEN 'Already closing' ELSE 'Eligible' END AS Status
FROM    Trade.Position p WITH (NOLOCK)
LEFT JOIN Trade.CloseExecutionPlan cep WITH (NOLOCK) ON p.PositionID = cep.PositionID
WHERE   p.PositionID = 12345;
```

### 8.2 Execute ACATS out transfer

```sql
EXEC Trade.AcatsOut @PositionID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AcatsOut | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AcatsOut.sql*
