# Dictionary.CryptoLiquidityOrderStatusType

> Lookup table defining the lifecycle states of crypto liquidity orders placed with external exchange/OTC providers for hedging or filling customer crypto trades.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

When eToro executes crypto trades on behalf of customers, it places liquidity orders with external crypto exchanges or OTC desks to hedge its exposure. This table defines the possible states of those liquidity orders throughout their lifecycle — from initial placement (Open) through completion (Filled) or various failure modes (Canceled, TimeOut, InternalError).

Without this table, the platform would have no way to classify or report on the status of outbound crypto liquidity orders. The SSRS crypto execution reports (`dbo.SSRS_Crypto_Executions_Report` and `dbo.SSRS_Crypto_Executions_Report_Summary`) JOIN to this table to resolve order status IDs into human-readable names for operations dashboards.

Orders flow through the system starting as Open, then transition to a terminal state. Partial fills (status 3) indicate the exchange could only fill part of the requested quantity, while TimeOut (4) and InternalError (5) represent recoverable and non-recoverable failures respectively.

---

## 2. Business Logic

### 2.1 Crypto Liquidity Order Lifecycle

**What**: Liquidity orders follow a state machine from placement to terminal state.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- Open (0) is the initial state when an order is placed with the liquidity provider
- Filled (1) is the successful terminal state — full quantity executed
- Partial (3) means only part of the order was filled — remaining quantity may need a new order
- Canceled (2), TimeOut (4), InternalError (5) are failure terminal states with different retry implications
- NotExists (6) indicates the order ID was not found at the provider — may indicate a stale reference

**Diagram**:
```
Open (0) ──► Filled (1)         [success - full fill]
          ├─► Partial (3)        [partial success - needs follow-up]
          ├─► Canceled (2)       [provider canceled]
          ├─► TimeOut (4)        [no response within deadline]
          ├─► InternalError (5)  [system failure]
          └─► NotExists (6)      [order not found at provider]
```

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | Open | Order has been submitted to the crypto exchange/OTC desk and is awaiting execution — the liquidity provider has acknowledged receipt but not yet filled the order |
| 1 | Filled | Order was fully executed at the requested quantity — the crypto assets have been acquired/sold and the hedge position is complete |
| 2 | Canceled | Order was canceled either by the platform or by the liquidity provider — no execution occurred, the system may need to re-place the order |
| 3 | Partial | Only a portion of the requested quantity was filled by the provider — common during low-liquidity periods, the remaining amount may require a new order |
| 4 | TimeOut | The liquidity provider did not respond within the configured deadline — the order status is unknown and may need manual reconciliation |
| 5 | InternalError | A system-level error occurred during order processing — could be a connectivity failure, API error, or internal validation failure |
| 6 | NotExists | The order ID was not found when queried at the liquidity provider — may indicate the order was never received, was purged, or the ID is stale |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key identifying the order status. Starts at 0 (Open) through 6 (NotExists). Used in SSRS crypto execution reports JOINed as `OD.order_status = CLOS.ID`. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable status name: Open, Filled, Canceled, Partial, TimeOut, InternalError, NotExists. Displayed in SSRS crypto execution report columns. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.SSRS_Crypto_Executions_Report | order_status | JOIN | Resolves order status ID to name in detailed crypto execution report |
| dbo.SSRS_Crypto_Executions_Report_Summary | order_status | JOIN | Resolves order status ID to name in summary crypto execution report |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CryptoLiquidityOrderStatusType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.SSRS_Crypto_Executions_Report | Procedure | Reads — JOINs to resolve order status for SSRS report |
| dbo.SSRS_Crypto_Executions_Report_Summary | Procedure | Reads — JOINs to resolve order status for summary report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCryptoLiquidityOrderStatusType | CLUSTERED | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all crypto liquidity order statuses
```sql
SELECT  ID,
        Name
FROM    Dictionary.CryptoLiquidityOrderStatusType WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Identify terminal vs in-progress statuses
```sql
SELECT  ID,
        Name,
        CASE WHEN ID = 0 THEN 'In Progress' ELSE 'Terminal' END AS StatusCategory
FROM    Dictionary.CryptoLiquidityOrderStatusType WITH (NOLOCK)
ORDER BY ID
```

### 8.3 Count crypto orders by status (conceptual join)
```sql
SELECT  clos.Name AS OrderStatus,
        COUNT(*) AS OrderCount
FROM    Trade.CryptoLiquidityOrder clo WITH (NOLOCK)
        JOIN Dictionary.CryptoLiquidityOrderStatusType clos WITH (NOLOCK) ON clo.order_status = clos.ID
GROUP BY clos.Name
ORDER BY OrderCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CryptoLiquidityOrderStatusType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CryptoLiquidityOrderStatusType.sql*
