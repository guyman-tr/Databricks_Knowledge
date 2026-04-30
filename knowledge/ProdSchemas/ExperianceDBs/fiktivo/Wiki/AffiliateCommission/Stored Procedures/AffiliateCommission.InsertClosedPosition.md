# AffiliateCommission.InsertClosedPosition

> Atomically inserts a closed position and its commission records within a single transaction, with an idempotency guard that skips duplicate position IDs.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1 (success) or 0 (duplicate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

InsertClosedPosition is the primary data writer for closed positions entering the affiliate commission system. When a trading position is closed and eligible for commission calculation, this procedure creates the ClosedPosition record and all associated ClosedPositionCommission records (one per affiliate tier) in a single atomic transaction.

This procedure exists as the ingest endpoint for the closed position pipeline. Data flows from the trading platform through ClosedPositionFromEtoro (staging) -> GetClosedPositionsFromEtoro (dequeue) -> commission calculation -> InsertClosedPosition (persist). The procedure's idempotency guard (IF EXISTS check on ClosedPositionID) ensures that duplicate messages from the trading platform do not create duplicate commission records.

The commission data is passed as a table-valued parameter (PositionCommissionType TVP), allowing multiple affiliate-tier commission rows to be inserted atomically alongside the position. The transaction ensures either both the position and all commissions are created, or neither is.

---

## 2. Business Logic

### 2.1 Idempotent Insert Pattern

**What**: Prevents duplicate position records while supporting at-least-once delivery.

**Columns/Parameters Involved**: `@ClosedPositionID`

**Rules**:
- Before inserting, checks IF EXISTS on ClosedPosition.ClosedPositionID
- If position already exists: returns 0 immediately (no-op, idempotent)
- If position is new: proceeds with transactional insert, returns 1
- This pattern allows the upstream pipeline to safely retry failed deliveries

### 2.2 Atomic Position + Commission Insert

**What**: Creates position and commission records in a single transaction.

**Columns/Parameters Involved**: `@AffiliateCommission` (TVP), ClosedPosition, ClosedPositionCommission

**Rules**:
- BEGIN TRAN wraps both inserts
- First INSERT: ClosedPosition with financial and attribution data
- Second INSERT: ClosedPositionCommission from the TVP (AffiliateID, Commission, Tier, Paid, PaymentID per row)
- Error handling: ROLLBACK on last transaction, COMMIT on nested transactions, always re-THROW

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ClosedPositionID | bigint (IN) | NO | - | CODE-BACKED | Unique position identifier from the trading platform. Becomes the PK in ClosedPosition. Also used for idempotency check. |
| 2 | @CommissionDate | datetime (IN) | NO | - | CODE-BACKED | When the commission was calculated/assigned. |
| 3 | @Amount | decimal(16,6) (IN) | NO | - | CODE-BACKED | Position trade amount. |
| 4 | @HedgeCommission | decimal(16,6) (IN) | NO | - | CODE-BACKED | Hedge commission deducted from the position. Total = Amount - HedgeCommission. |
| 5 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID who owned the position. |
| 6 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | Primary affiliate attributed to this position (not stored in ClosedPosition directly, used contextually). |
| 7 | @ProviderID | bigint (IN) | NO | - | CODE-BACKED | Current provider in the broker chain. |
| 8 | @OriginalProviderID | bigint (IN) | NO | - | CODE-BACKED | Original broker/provider entity. |
| 9 | @RealProviderID | bigint (IN) | NO | - | CODE-BACKED | Actual executing provider. |
| 10 | @CountryID | bigint (IN) | NO | - | CODE-BACKED | Customer's country for commission rate lookup. |
| 11 | @NetProfit | money (IN) | NO | - | CODE-BACKED | Position net profit/loss at close. |
| 12 | @LotCount | decimal(16,6) (IN) | NO | - | CODE-BACKED | Trade lot count. |
| 13 | @TrackingDate | datetime (IN) | NO | - | CODE-BACKED | When the position was first tracked by the commission system. |
| 14 | @Valid | bit (IN) | NO | - | CODE-BACKED | Whether the position is eligible for commission. 1=eligible, 0=disqualified. |
| 15 | @AffiliateCommission | PositionCommissionType (IN, TVP) | NO | - | CODE-BACKED | Table-valued parameter containing per-affiliate, per-tier commission rows (AffiliateID, Commission, Tier, Paid, PaymentID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.ClosedPosition | WRITE (INSERT) + READ (EXISTS check) | Creates position record; checks for duplicates |
| - | AffiliateCommission.ClosedPositionCommission | WRITE (INSERT) | Creates commission records from TVP |
| @AffiliateCommission | AffiliateCommission.PositionCommissionType | TVP | Table-valued parameter type for commission rows |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission engine after processing positions from GetClosedPositionsFromEtoro.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.InsertClosedPosition (procedure)
+-- AffiliateCommission.ClosedPosition (table)
+-- AffiliateCommission.ClosedPositionCommission (table)
+-- AffiliateCommission.PositionCommissionType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPosition | Table | INSERT + EXISTS check for idempotency |
| AffiliateCommission.ClosedPositionCommission | Table | INSERT from TVP |
| AffiliateCommission.PositionCommissionType | UDT | TVP parameter type for commission rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission engine) | External | Persists processed closed positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction semantics | TRAN | Atomic insert of position + commissions. Nested transaction handling with conditional ROLLBACK/COMMIT. |

---

## 8. Sample Queries

### 8.1 Insert a closed position (requires TVP)
```sql
DECLARE @CommData AffiliateCommission.PositionCommissionType
INSERT @CommData (AffiliateID, Commission, Tier, Paid, PaymentID)
VALUES (3, 1.50, 1, 0, 0)

EXEC [AffiliateCommission].[InsertClosedPosition]
    @ClosedPositionID = 500000,
    @CommissionDate = '2026-04-12',
    @Amount = 100.00,
    @HedgeCommission = 2.50,
    @CID = 12345,
    @AffiliateID = 3,
    @ProviderID = 1,
    @OriginalProviderID = 1,
    @RealProviderID = 1,
    @CountryID = 1,
    @NetProfit = 50.00,
    @LotCount = 1.000000,
    @TrackingDate = '2026-04-12',
    @Valid = 1,
    @AffiliateCommission = @CommData
```

### 8.2 Check if a position was already inserted
```sql
SELECT ClosedPositionID, CID, Amount, CommissionDate
FROM [AffiliateCommission].[ClosedPosition] WITH (NOLOCK)
WHERE ClosedPositionID = 500000
```

### 8.3 View position with its commission breakdown
```sql
SELECT cp.ClosedPositionID, cp.CID, cp.Amount, cp.NetProfit,
       cc.AffiliateID, cc.Commission, cc.Tier, cc.Paid
FROM [AffiliateCommission].[ClosedPosition] AS cp WITH (NOLOCK)
INNER JOIN [AffiliateCommission].[ClosedPositionCommission] AS cc WITH (NOLOCK)
    ON cp.ClosedPositionID = cc.ClosedPositionID
WHERE cp.ClosedPositionID = 500000
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-2448: CPA New Compensation Design + CountryID (2023-12-17)
- PART-1278: Add update of IsProcess field (2023-03-22)
- Unlabeled: Remove old tblaff tables (2023-07-19, Ran Ovadia)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.InsertClosedPosition | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.InsertClosedPosition.sql*
