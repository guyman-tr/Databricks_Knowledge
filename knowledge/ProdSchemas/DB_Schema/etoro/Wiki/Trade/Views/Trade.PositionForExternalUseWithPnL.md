# Trade.PositionForExternalUseWithPnL

> Combines the full external-facing position dataset (Trade.PositionForExternalUse) with live PnL from Trade.PnL, serving as the primary source for position-with-PnL queries across BackOffice, Billing, and external reporting.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (from Trade.PositionForExternalUse) |
| **Partition** | PositionPartitionCol (aligned join with Trade.PnL) |
| **Indexes** | N/A |
| **Status** | Active / core infrastructure view |

---

## 1. Business Meaning

Trade.PositionForExternalUseWithPnL is a pivotal view that merges the full, sanitized position dataset from `Trade.PositionForExternalUse` with real-time unrealized PnL from `Trade.PnL`. This combination makes it the primary source for any consumer that needs both position details AND live PnL in a single query.

It is heavily referenced by:
- **BackOffice**: Customer open positions, copier tracking, redeems, and equity queries
- **Billing**: Withdrawal validation, profit calculation, redeem records
- **Trade**: As the base for `Trade.GetPositionDataForExternalUse` (UNION with closed positions)
- **Testing**: `Trade.Position_DataFactory_Test` wraps this view

The join uses both `PositionID` AND `PartitionCol` for partition-aligned efficiency.

---

## 2. Business Logic

### 2.1 Partition-Aligned PnL Join

**What**: Joins Trade.PnL using both PositionID and PartitionCol for partition elimination.

**Rules**:
- `INNER JOIN Trade.PnL ON PnL.PositionID = TPOS.PositionID AND PnL.PartitionCol = TPOS.PositionPartitionCol`
- INNER JOIN means only positions with PnL are returned (effectively only open positions)
- No NOLOCK hint on this view itself (consumers add their own)

---

## 3. Data Overview

Returns the complete Trade.PositionForExternalUse column set plus 5 PnL columns for every open position.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TPOS.* | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUse. |
| 2 | PnLInDollars | money | YES | - | CODE-BACKED | Live unrealized PnL in dollars. |
| 3 | PnLInCents | bigint | YES | - | CODE-BACKED | Live unrealized PnL in cents. |
| 4 | EndConversionRate | money | YES | - | CODE-BACKED | Current conversion rate (from PnL.ConversionRate). |
| 5 | CurrentClosingRate | decimal | YES | - | CODE-BACKED | Current closing rate used for PnL. |
| 6 | CurrentClosingRateID | bigint | YES | - | CODE-BACKED | PriceRateID of current closing rate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TPOS.* | Trade.PositionForExternalUse | FROM | Full position dataset |
| PnL.* | Trade.PnL | INNER JOIN | Live PnL (partition-aligned) |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionDataForExternalUse | View | INNER JOIN (open positions half of UNION ALL) |
| Trade.Position_DataFactory_Test | View | SELECT * (thin wrapper) |
| BackOffice.GetCustomerOpenPositions | Stored Procedure | Open positions display |
| BackOffice.GetCustomerOpenCopiedTraders | Stored Procedure | Copy trading positions |
| BackOffice.GetRedeemsInfo | Stored Procedure | Redeem position data |
| Billing.GetPositionNetProfit | Stored Procedure | Net profit lookup |
| Billing.GetRedeemValidationData | Stored Procedure | Withdrawal validation |
| Billing.GetRedeemRecords | Stored Procedure | Redeem record details |
| Billing.GetRedeemRecordsDynamic | Stored Procedure | Dynamic redeem records |
| BackOffice.GetUnrealizedPnL | Function | Unrealized PnL computation |
| Customer.PostMIMOOperationsDebug | Stored Procedure | Debug MIMO operations |
| dbo.SSRS_NWA_Calc | Stored Procedure | SSRS NWA calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionForExternalUseWithPnL (view)
+-- Trade.PositionForExternalUse (view)
|   +-- Trade.PositionTbl (table)
|   +-- (additional enrichment views/functions)
+-- Trade.PnL (view)
    +-- Trade.PositionTbl (table)
    +-- Trade.FnCalculatePnLWrapper (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUse | View | FROM - full position data |
| Trade.PnL | View | INNER JOIN - live PnL |

### 6.2 Objects That Depend On This

12+ objects across Trade, BackOffice, Billing, and dbo schemas.

---

## 7. Technical Details

### 7.1 Performance

- Partition-aligned join (PositionID + PartitionCol) enables partition elimination, critical for the large PositionTbl
- INNER JOIN with Trade.PnL naturally filters to open positions only (PnL view has StatusID=1)

---

## 8. Sample Queries

### 8.1 Get customer's open positions with PnL
```sql
SELECT  PositionID, InstrumentID, IsBuy, AmountInUnitsDecimal,
        PnLInDollars, CurrentClosingRate, EndConversionRate
FROM    Trade.PositionForExternalUseWithPnL WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.2 Total live exposure for a customer
```sql
SELECT  CID, COUNT(*) AS OpenPositions, SUM(PnLInDollars) AS TotalUnrealizedPnL
FROM    Trade.PositionForExternalUseWithPnL WITH (NOLOCK)
WHERE   CID = 12345
GROUP BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. Core infrastructure view with extensive cross-schema consumption.

---

*Generated: 2026-03-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12+ referencing | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionForExternalUseWithPnL | Type: View | Source: etoro/etoro/Trade/Views/Trade.PositionForExternalUseWithPnL.sql*
