# Price.SwapContracts

> Executes a futures contract roll by promoting the second-next contract to first-next and loading the nearest unexpired contract from FuturesContracts into the second-next slot, updating Trade.LiquidityProviderContracts with new ticker and date windows.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT @IsNotExpiredExist BIT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.SwapContracts is the futures contract roll procedure. Futures-based instruments (indices, commodities, certain forex pairs) trade through sequential delivery contracts - each contract has a defined date window and exchange ticker, and when the front-month contract approaches expiry, the pricing engine must seamlessly transition to the next contract. This is the "contract roll" operation.

SwapContracts performs this roll atomically: it checks whether any unexpired future contracts exist for the specified instrument and liquidity account, then promotes the two-contract chain forward - the second-next slot takes the old first-next values, and the first-next slot is loaded with the newly-nearest contract from `Price.FuturesContracts`. The consumed contract is marked as Expired=1.

The procedure also updates the spot instrument's price window in `Trade.LiquidityProviderContracts`, ensuring the pricing engine's active contract references are in sync with the new roll state.

The OUTPUT parameter `@IsNotExpiredExist` allows callers to detect whether the roll was skipped (no unexpired contracts available), in which case the procedure exits early with no changes made.

---

## 2. Business Logic

### 2.1 Contract Roll Chain Promotion

**What**: The roll moves the futures contract chain forward: second-next becomes first-next, and a new second-next is loaded from Price.FuturesContracts.

**Columns/Parameters Involved**: `@InstrumentID`, `@LiquidityAccountID`, `@FutureLiquidityTypeProviderID`, `@SpotLiquidityTypeProviderID`

**Rules**:
- Step 1: Check if any Expired=0 rows exist in Price.FuturesContracts. If NONE -> set @IsNotExpiredExist=0 and RETURN (no changes)
- Step 2: Load SpotInstrumentMapping to get FirstNextInstrumentId and SecondNextInstrumentId
- Step 3: Get current SecondNext contract values (Ticker, FromDate, ToDate) from Trade.LiquidityProviderContracts
- Step 4: Get nearest future (TOP 1 Expired=0 ORDER BY FromDate ASC) from Price.FuturesContracts
- Step 5: Update Trade.LiquidityProviderContracts for FirstNextInstrumentId <- SecondNext values (slide forward)
- Step 6: Update Trade.LiquidityProviderContracts for SecondNextInstrumentId <- nearest future values
- Step 7: Mark the nearest future contract as Expired=1 in Price.FuturesContracts
- Step 8: Update spot instrument's Trade.LiquidityProviderContracts date window using FirstNext dates

**Diagram**:
```
BEFORE ROLL:
  SpotInstrumentMapping: InstrumentID -> FirstNext=A, SecondNext=B
  FuturesContracts: C (Expired=0, nearest by FromDate)

Roll execution:
  LiquidityProviderContracts[FirstNext=A]  <- values from old SecondNext=B
  LiquidityProviderContracts[SecondNext=B] <- values from FuturesContracts[C]
  FuturesContracts[C].Expired = 1

AFTER ROLL:
  FirstNext=A now has B's contract window
  SecondNext=B now has C's contract window
  C is marked as consumed (Expired=1)
  Spot instrument date window updated to FirstNext's current FromDate/ToDate
```

### 2.2 Early Exit When No Unexpired Contracts

**What**: If Price.FuturesContracts has no Expired=0 rows, the roll cannot proceed and the OUTPUT flag signals this to the caller.

**Columns/Parameters Involved**: `@IsNotExpiredExist`

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM Price.FuturesContracts WHERE Expired=0) -> SET @IsNotExpiredExist=0, RETURN
- Caller must check @IsNotExpiredExist before assuming roll occurred
- @IsNotExpiredExist=1 means the roll proceeded normally

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | The spot instrument for which the contract roll is being executed. Used to look up Price.SpotInstrumentMapping and filter Price.FuturesContracts and Trade.LiquidityProviderContracts. |
| 2 | @LiquidityAccountID | INT | NOT NULL | - | CODE-BACKED | The futures liquidity account for this roll. Used to filter Price.FuturesContracts (WHERE LiquidityAccountID=@LiquidityAccountID) and to look up the spot mapping via SpotInstrumentMapping.FutureLiquidityAccountID. |
| 3 | @FutureLiquidityTypeProviderID | INT | NOT NULL | - | CODE-BACKED | The liquidity provider ID for futures contract rows in Trade.LiquidityProviderContracts. Used to identify which LiquidityProviderContracts rows represent the FirstNext and SecondNext contract slots. |
| 4 | @SpotLiquidityTypeProviderID | INT | NOT NULL | - | CODE-BACKED | The liquidity provider ID for the spot instrument in Trade.LiquidityProviderContracts. After the roll, the spot instrument's date window is updated to match the FirstNext contract's FromDate and ToDate. |
| 5 | @IsNotExpiredExist | BIT OUTPUT | - | - | CODE-BACKED | OUTPUT parameter. 1 = at least one unexpired contract exists and the roll was performed. 0 = no unexpired contracts found; roll was skipped. Caller must check this before assuming changes were made. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID + @LiquidityAccountID | Price.FuturesContracts | READER + MODIFIER | Reads nearest unexpired contract; sets Expired=1 on consumed row |
| @InstrumentID + @LiquidityAccountID | Price.SpotInstrumentMapping | READER | Retrieves FirstNextInstrumentId and SecondNextInstrumentId for the roll chain |
| FirstNextInstrumentId + @FutureLiquidityTypeProviderID | Trade.LiquidityProviderContracts | MODIFIER | Updates first-next slot with second-next contract values (slide forward) |
| SecondNextInstrumentId + @FutureLiquidityTypeProviderID | Trade.LiquidityProviderContracts | MODIFIER | Updates second-next slot with the new nearest future contract |
| @InstrumentID + @SpotLiquidityTypeProviderID | Trade.LiquidityProviderContracts | MODIFIER | Updates spot instrument's date window to match the promoted first-next contract |

### 5.2 Referenced By (other objects point to this)

No SQL callers found in the etoro SSDT repo. This procedure is called externally by the pricing infrastructure (contract roll scheduler).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SwapContracts (procedure)
├── Price.FuturesContracts (table - read unexpired contracts, mark Expired=1)
├── Price.SpotInstrumentMapping (table - read FirstNext/SecondNext instrument IDs)
└── Trade.LiquidityProviderContracts (table - update Ticker/FromDate/ToDate for roll)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.FuturesContracts | Table | READ nearest unexpired contract (TOP 1 Expired=0 ORDER BY FromDate ASC); UPDATE Expired=1 after roll |
| Price.SpotInstrumentMapping | Table | READ FirstNextInstrumentId and SecondNextInstrumentId for the chain |
| Trade.LiquidityProviderContracts | Table | UPDATE - promotes contract chain: FirstNext <- SecondNext values, SecondNext <- nearest future values, spot <- new FirstNext dates |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Called by external contract roll scheduling service.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Early exit guard | Logic | Checks Price.FuturesContracts WHERE Expired=0 before any DML. No changes made if no unexpired contracts. |
| Temp tables | Logic | Uses #Spotmap, #NearestFuture, #OldSecondNext for intermediate state across multiple UPDATE steps |
| No explicit transaction | Logic | Operations are not wrapped in a BEGIN TRANSACTION - partial roll is possible if a step fails mid-way |

---

## 8. Sample Queries

### 8.1 Check if any unexpired contracts exist before calling

```sql
SELECT COUNT(*) AS UnexpiredCount
FROM Price.FuturesContracts WITH (NOLOCK)
WHERE Expired = 0;
```

### 8.2 View current contract chain for an instrument before roll

```sql
SELECT
    SIM.InstrumentID,
    SIM.FirstNextInstrumentId,
    SIM.SecondNextInstrumentId,
    LPC1.Ticker AS FirstNextTicker,
    LPC1.FromDate AS FirstNextFrom,
    LPC1.ToDate AS FirstNextTo,
    LPC2.Ticker AS SecondNextTicker,
    LPC2.FromDate AS SecondNextFrom,
    LPC2.ToDate AS SecondNextTo
FROM Price.SpotInstrumentMapping SIM WITH (NOLOCK)
LEFT JOIN Trade.LiquidityProviderContracts LPC1 WITH (NOLOCK)
    ON LPC1.InstrumentID = SIM.FirstNextInstrumentId
LEFT JOIN Trade.LiquidityProviderContracts LPC2 WITH (NOLOCK)
    ON LPC2.InstrumentID = SIM.SecondNextInstrumentId
WHERE SIM.InstrumentID = 1005;
```

### 8.3 Execute a futures contract roll

```sql
DECLARE @IsNotExpiredExist BIT;
EXEC Price.SwapContracts
    @InstrumentID = 1005,
    @LiquidityAccountID = 22,
    @FutureLiquidityTypeProviderID = 10,
    @SpotLiquidityTypeProviderID = 5,
    @IsNotExpiredExist = @IsNotExpiredExist OUTPUT;

SELECT @IsNotExpiredExist AS RollPerformed;
-- 1 = roll executed, 0 = no unexpired contracts, roll skipped
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Price.SwapContracts | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.SwapContracts.sql*
