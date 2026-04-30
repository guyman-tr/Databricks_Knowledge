# Trade.GetMaxAmountToWithdraw

> Calculates the maximum amount a customer can withdraw, accounting for open position PnL, BSL (Balance Stop Loss) liquidation thresholds, pending orders, bonus credit, and redeemed stock positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT parameters: @MaxAmountToWithdrawWithBSL, @RequestedPositionUnrealized, @MaxAmountToWithdrawForRedeem |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMaxAmountToWithdraw calculates how much money a customer can safely withdraw without triggering liquidation or leaving insufficient margin. This is a critical financial safety procedure - it prevents customers from withdrawing funds that would put their account below the BSL (Balance Stop Loss) threshold, which would trigger automatic position liquidation.

This procedure exists because eToro must enforce withdrawal limits that account for: (1) open position unrealized PnL, (2) the BSL liquidation threshold percentage, (3) pending manual orders that reserve funds, (4) bonus credit that cannot be withdrawn, and (5) special treatment for redeemed (real stock) positions. Without this calculation, customers could withdraw too much and trigger forced liquidation.

Called by TAPIUser (Trading API) when a customer requests a withdrawal, and by PROD_BIadmins for analytics. The procedure also optionally returns the unrealized PnL for a specific position (used in position-level withdrawal validation).

---

## 2. Business Logic

### 2.1 BSL-Adjusted Maximum Withdrawal

**What**: Calculates how much can be withdrawn while keeping the account above the BSL liquidation threshold.

**Columns/Parameters Involved**: `@CID`, `@PositionID`, `@MaxAmountToWithdrawWithBSL`, `RealizedEquity`, `BonusCredit`, `@PnL`, `@PercentForLiquidation`, `@TotalOrdersAmount`

**Rules**:
- Formula: MaxAmountToWithdrawWithBSL = RealizedEquity - TotalOrdersAmount - BonusCredit + PnL / (1 - PercentForLiquidation)
- @PercentForLiquidation comes from Dictionary.BSLOperationThreshold (ID=1), the BSL percentage threshold
- @TotalOrdersAmount = Trade.GetTotalManualOrdersForOpenAmount(@CID) - funds reserved for pending orders
- @PnL = total unrealized PnL across all open positions (StatusID=1)
- RealizedEquity and BonusCredit from Customer.CustomerMoney
- Result is rounded to 2 decimal places

### 2.2 Redeem-Adjusted Maximum Withdrawal

**What**: Calculates withdrawal limit excluding redeemed (real stock) positions that cannot be liquidated for cash.

**Columns/Parameters Involved**: `@MaxAmountToWithdrawForRedeem`, `@RedeemPositionsPnL`, `@RedeemPositionsAmount`

**Rules**:
- Formula: MaxAmountToWithdrawForRedeem = RealizedEquity - TotalOrdersAmount - BonusCredit + PnL - (RedeemPositionsAmount + RedeemPositionsPnL)
- Redeemed positions (RedeemStatus > 0) are excluded from the withdrawal pool because they represent actual stock ownership
- The requested position (@PositionID) is excluded from redeem calculations even if it has RedeemStatus > 0

### 2.3 Requested Position Unrealized PnL

**What**: Returns the unrealized PnL for a specific position to support position-level validation.

**Columns/Parameters Involved**: `@PositionID`, `@RequestedPositionUnrealized`

**Rules**:
- Calculated as: Amount + PnL for the requested @PositionID
- NULL if @PositionID is NULL or not found
- Used by the application to validate whether closing a specific position would bring the account below thresholds

**Diagram**:
```
@CID, @PositionID
     |
     v
Trade.GetTotalManualOrdersForOpenAmount(@CID) -> @TotalOrdersAmount
Dictionary.BSLOperationThreshold (ID=1) -> @PercentForLiquidation
     |
     v
Trade.PositionTbl (StatusID=1) JOIN Trade.PnL -> @PnL (total unrealized)
     |                                         -> @RequestedPositionUnrealized
     |                                         -> @RedeemPositionsPnL, @RedeemPositionsAmount
     |
     v
Customer.CustomerMoney -> RealizedEquity, BonusCredit
     |
     +--> @MaxAmountToWithdrawWithBSL = RealizedEquity - Orders - Bonus + PnL/(1-LiqPct)
     +--> @MaxAmountToWithdrawForRedeem = RealizedEquity - Orders - Bonus + PnL - RedeemValue
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @CID | int | IN | - | CODE-BACKED | Customer ID to calculate withdrawal limits for. |
| 2 | @PositionID | bigint | IN | NULL | CODE-BACKED | Optional specific position to calculate unrealized PnL for. When NULL, only account-level maximums are calculated. |
| 3 | @MaxAmountToWithdrawWithBSL | money | OUTPUT | NULL | CODE-BACKED | Maximum withdrawal amount that keeps the account above the BSL liquidation threshold. Accounts for all open PnL, pending orders, and bonus credit. |
| 4 | @RequestedPositionUnrealized | money | OUTPUT | NULL | CODE-BACKED | Unrealized value (Amount + PnL) of the specific @PositionID. NULL if no position specified. |
| 5 | @MaxAmountToWithdrawForRedeem | money | OUTPUT | NULL | CODE-BACKED | Maximum withdrawal amount excluding redeemed stock positions. Lower than @MaxAmountToWithdrawWithBSL because real stock positions cannot be liquidated for cash withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Trade.PositionTbl | SELECT (READER) | Reads all open positions for the customer to calculate PnL |
| JOIN | Trade.PnL | SELECT (READER) | Gets unrealized PnL per position |
| SELECT | Customer.CustomerMoney | SELECT (READER) | Reads RealizedEquity and BonusCredit for the customer |
| SELECT | Dictionary.BSLOperationThreshold | SELECT (READER) | Gets the BSL liquidation percentage threshold (ID=1) |
| CALL | Trade.GetTotalManualOrdersForOpenAmount | Function Call | Gets total reserved amount for pending manual orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TAPIUser | GRANT EXECUTE | Application User | Trading API calls during withdrawal validation |
| PROD_BIadmins | GRANT EXECUTE | Application User | BI analytics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMaxAmountToWithdraw (procedure)
+-- Trade.PositionTbl (table)
+-- Trade.PnL (view)
+-- Customer.CustomerMoney (table)
+-- Dictionary.BSLOperationThreshold (table)
+-- Trade.GetTotalManualOrdersForOpenAmount (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT open positions for PnL aggregation |
| Trade.PnL | View | JOIN to get PnLInDollars per position |
| Customer.CustomerMoney | Table | SELECT RealizedEquity, BonusCredit |
| Dictionary.BSLOperationThreshold | Table | SELECT BSL liquidation threshold percentage |
| Trade.GetTotalManualOrdersForOpenAmount | Function | Called to get total pending order amount |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TAPIUser | Application User | Withdrawal validation |
| PROD_BIadmins | Application User | Analytics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Error handling via TRY/CATCH with THROW.

---

## 8. Sample Queries

### 8.1 Get max withdrawal for a customer

```sql
DECLARE @maxBSL MONEY, @posUnreal MONEY, @maxRedeem MONEY;
EXEC Trade.GetMaxAmountToWithdraw
    @CID = 12345,
    @PositionID = NULL,
    @MaxAmountToWithdrawWithBSL = @maxBSL OUTPUT,
    @RequestedPositionUnrealized = @posUnreal OUTPUT,
    @MaxAmountToWithdrawForRedeem = @maxRedeem OUTPUT;
SELECT @maxBSL AS MaxWithBSL, @posUnreal AS PositionUnrealized, @maxRedeem AS MaxForRedeem;
```

### 8.2 Get withdrawal limit with a specific position's unrealized PnL

```sql
DECLARE @maxBSL MONEY, @posUnreal MONEY, @maxRedeem MONEY;
EXEC Trade.GetMaxAmountToWithdraw
    @CID = 12345,
    @PositionID = 9876543210,
    @MaxAmountToWithdrawWithBSL = @maxBSL OUTPUT,
    @RequestedPositionUnrealized = @posUnreal OUTPUT,
    @MaxAmountToWithdrawForRedeem = @maxRedeem OUTPUT;
SELECT @maxBSL AS MaxWithBSL, @posUnreal AS PositionUnrealized, @maxRedeem AS MaxForRedeem;
```

### 8.3 Check BSL threshold configuration

```sql
SELECT  ID,
        ValueInPercent,
        Description
FROM    Dictionary.BSLOperationThreshold WITH (NOLOCK)
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| TRADEX-1633 | Jira | Pre-execution on-read credit validation changes (2021) |
| RD-4460 | Jira | Fix Transfer BSL Validation (2019) |

---

*Generated: 2026-03-16 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMaxAmountToWithdraw | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMaxAmountToWithdraw.sql*
