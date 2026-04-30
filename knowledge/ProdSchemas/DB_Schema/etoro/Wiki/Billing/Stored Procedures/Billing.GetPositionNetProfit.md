# Billing.GetPositionNetProfit

> Returns the current net PnL in USD dollars for a specific trading position by looking up Trade.PositionForExternalUseWithPnL, used by the redeem service and SecurePay to determine position profit before executing a redemption or payment.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single value: PnLInDollars (DECIMAL) for @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPositionNetProfit` retrieves the current profit-and-loss figure in USD for a specific trading position. It reads `Trade.PositionForExternalUseWithPnL` (a Trade schema view that exposes live PnL data for external consumers) joined to `Trade.CurrencyPrice` on InstrumentID, returning `PnLInDollars` - the position's net profit expressed in USD.

The procedure exists in the Billing schema to give billing-layer services (the redeem service and SecurePay) a cross-schema read interface to live trading PnL data without requiring direct access to the Trade schema. Before executing a redemption or a secure payment tied to a position's value, these services need to know the current net profit of the position.

Data flows: the redeem service or SecurePay calls this during redemption processing, passing the position ID. The procedure returns the USD PnL as a single value, which the caller uses to determine payment eligibility, fee calculations, or redemption amounts.

Change history: Created 2021-04-08 (Shay O.), PositionID changed from INT to BIGINT (2021-06-20), PnL calculation source changed 2023-12-31 (Dor I. - likely updated the Trade view or join logic).

---

## 2. Business Logic

### 2.1 Trade.CurrencyPrice JOIN for Current PnL

**What**: The JOIN to `Trade.CurrencyPrice` on InstrumentID is required to access the current PnL calculation - the view `Trade.PositionForExternalUseWithPnL` exposes per-instrument PnL context that depends on current currency prices.

**Columns/Parameters Involved**: `GP.InstrumentID`, `CP.InstrumentID`, `GP.PnLInDollars`

**Rules**:
- `FROM Trade.PositionForExternalUseWithPnL GP INNER JOIN Trade.CurrencyPrice CP ON CP.InstrumentID = GP.InstrumentID`
- `TOP 1` - returns only the first row (there should be at most one row per PositionID in the view, but TOP 1 guards against duplicates)
- `WHERE GP.PositionID = @PositionID` - filters to the specific position
- Both tables use WITH (NOLOCK) - non-blocking read acceptable for real-time PnL checks

### 2.2 Cross-Schema PnL Access Pattern

**What**: This procedure gives Billing-schema services access to Trade-schema PnL data via a controlled interface.

**Rules**:
- The caller (RedeemServiceUser, SQL_SecurePay) has EXECUTE on this procedure but not direct SELECT on Trade schema tables
- The procedure uses NOLOCK to avoid blocking Trade writes
- If PositionID doesn't exist or is no longer in the view (closed position), the procedure returns 0 rows (caller receives NULL/empty result)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The trading position identifier. FK to Trade.PositionTbl.PositionID. BIGINT since 2021-06-20 (originally INT). |

**Return columns:**

| # | Column | Source | Confidence | Description |
|---|--------|--------|------------|-------------|
| 2 | PnLInDollars | Trade.PositionForExternalUseWithPnL.PnLInDollars | CODE-BACKED | Current net profit/loss of the position expressed in USD. Positive = profit, negative = loss. Sourced from the Trade schema's external-use PnL view joined with current currency prices. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.PositionForExternalUseWithPnL.PositionID | Lookup | Primary filter - finds the position's PnL record |
| (JOIN) | Trade.CurrencyPrice | JOIN | INNER JOINed on InstrumentID to provide current price context for PnL calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay | GRANT EXECUTE | Permission | SecurePay service checks position PnL before payment operations |
| RedeemServiceUser | GRANT EXECUTE | Permission | Redeem service checks position PnL before executing redemptions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPositionNetProfit (procedure)
├── Trade.PositionForExternalUseWithPnL (view - cross-schema)
└── Trade.CurrencyPrice (table - cross-schema)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionForExternalUseWithPnL | View | Primary source of PnLInDollars; filtered by PositionID |
| Trade.CurrencyPrice | Table | INNER JOINed on InstrumentID - provides current currency price context for PnL |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay | DB Security Principal | EXECUTE permission - position PnL check before payment |
| RedeemServiceUser | DB Security Principal | EXECUTE permission - position PnL check before redemption |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Change history**:
- 2021-04-08 (Shay O.): Initial version
- 2021-06-20 (Shay O.): Changed @PositionID parameter from INT to BIGINT (position IDs exceeded INT range)
- 2023-12-31 (Dor I.): PnL calculation change (likely updated view or join to reflect new PnL methodology)

---

## 8. Sample Queries

### 8.1 Get PnL for a specific position
```sql
EXEC [Billing].[GetPositionNetProfit] @PositionID = 1234567890
```

### 8.2 Equivalent direct query
```sql
SELECT TOP 1 GP.PnLInDollars
FROM Trade.PositionForExternalUseWithPnL GP WITH (NOLOCK)
INNER JOIN Trade.CurrencyPrice CP WITH (NOLOCK)
    ON CP.InstrumentID = GP.InstrumentID
WHERE GP.PositionID = 1234567890
```

### 8.3 Check range of PnL values for positions
```sql
SELECT TOP 20
    GP.PositionID,
    GP.InstrumentID,
    GP.PnLInDollars
FROM Trade.PositionForExternalUseWithPnL GP WITH (NOLOCK)
INNER JOIN Trade.CurrencyPrice CP WITH (NOLOCK)
    ON CP.InstrumentID = GP.InstrumentID
ORDER BY ABS(GP.PnLInDollars) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPositionNetProfit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPositionNetProfit.sql*
