# Dictionary.CryptoLiquidityOrderType

> Lookup table defining the direction (Buy/Sell) of crypto liquidity orders placed with external exchanges or OTC desks.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table classifies crypto liquidity orders by their direction — Buy or Sell. When eToro hedges customer crypto positions through external liquidity providers, each outbound order is either a purchase (acquiring crypto to cover a customer's buy position) or a sale (disposing of crypto when a customer sells). This two-value dictionary provides the human-readable label for the order type field.

Without this table, the SSRS crypto execution reports would display raw 0/1 values instead of meaningful Buy/Sell labels. The table is used exclusively by the `dbo.SSRS_Crypto_Executions_Report` and `dbo.SSRS_Crypto_Executions_Report_Summary` procedures, which JOIN it to resolve `OD.order_type` into readable names for operations dashboards.

Data in this table is static (only two possible values) and is not expected to change.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table is a simple two-value enumeration of order direction. See individual element descriptions in Section 4.

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | Buy | Liquidity order to purchase crypto assets from the exchange/OTC provider — placed when eToro needs to acquire crypto to hedge a customer's long (buy) position |
| 1 | Sell | Liquidity order to sell crypto assets to the exchange/OTC provider — placed when eToro needs to dispose of crypto to hedge a customer's short or closing position |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key identifying the order type. 0=Buy, 1=Sell. Used in SSRS crypto execution reports JOINed as `OD.order_type = CLOT.ID`. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable order direction label: Buy or Sell. Displayed in crypto execution SSRS report outputs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.SSRS_Crypto_Executions_Report | order_type | JOIN | Resolves order type ID to Buy/Sell label in detailed crypto execution report |
| dbo.SSRS_Crypto_Executions_Report_Summary | order_type | JOIN | Resolves order type ID to Buy/Sell label in summary crypto execution report |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CryptoLiquidityOrderType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.SSRS_Crypto_Executions_Report | Procedure | Reads — JOINs to resolve order type |
| dbo.SSRS_Crypto_Executions_Report_Summary | Procedure | Reads — JOINs to resolve order type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCryptoLiquidityOrderType | CLUSTERED | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all crypto liquidity order types
```sql
SELECT  ID,
        Name
FROM    Dictionary.CryptoLiquidityOrderType WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Join with order status for full order classification
```sql
SELECT  clot.Name AS OrderType,
        clos.Name AS OrderStatus
FROM    Dictionary.CryptoLiquidityOrderType clot WITH (NOLOCK)
        CROSS JOIN Dictionary.CryptoLiquidityOrderStatusType clos WITH (NOLOCK)
ORDER BY clot.ID, clos.ID
```

### 8.3 Crypto execution report pattern
```sql
SELECT  CLOT.Name AS OrderType,
        CLOS.Name AS OrderStatus,
        OD.instrument_id,
        OD.quantity,
        OD.price
FROM    Trade.CryptoLiquidityOrder OD WITH (NOLOCK)
        JOIN Dictionary.CryptoLiquidityOrderStatusType CLOS WITH (NOLOCK) ON OD.order_status = CLOS.ID
        JOIN Dictionary.CryptoLiquidityOrderType CLOT WITH (NOLOCK) ON OD.order_type = CLOT.ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CryptoLiquidityOrderType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CryptoLiquidityOrderType.sql*
