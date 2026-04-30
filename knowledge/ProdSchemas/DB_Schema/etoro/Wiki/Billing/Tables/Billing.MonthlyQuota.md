# Billing.MonthlyQuota

> Operational tracking table accumulating the total deposit value processed per payment protocol per calendar month, used for credit card routing decisions to balance load across payment processors.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) - natural key: (ProtocolID, Year, Month) |
| **Partition** | No |
| **Indexes** | 2 active (PK clustered + unique NC on ProtocolID+Year+Month) |

---

## 1. Business Meaning

Billing.MonthlyQuota tracks the cumulative dollar amount of deposit transactions processed through each payment protocol (WorldPay, Checkout, IxopayNuvei, etc.) for every calendar month. This running total is the input for the credit card routing algorithm: when routing a new deposit, the system uses these monthly volumes to balance load across payment processors and ensure no single processor exceeds its monthly processing capacity.

This table exists because eToro uses multiple payment processors simultaneously for credit card deposits, and each processor may have monthly processing limits or volume targets set by commercial agreements. By tracking actual volumes in real-time (TimeStamp updates throughout the day), the routing engine can direct new deposits to processors with remaining capacity. The Billing.GetMonthlyQuota function returns the existing monthly amounts PLUS zero-amount rows for any IsDynamicRouting=1 protocols that haven't processed anything yet - ensuring all eligible processors appear in routing calculations even with zero volume.

Data is updated by Billing.UpdateMonthlyProcessingQuota (called after each successful deposit), and read by Billing.GetCCProcessingBundle / GetCCProcessingBundleByBin / GetCCProcessingBundleByBinUS (credit card routing SPs). The CreditCardRoutingTransactionsVerification SP validates that the routing is working correctly. Active protocols in March 2026: WorldPay ($13.8M), Checkout ($16.9M), IxopayNuvei ($2.5M).

---

## 2. Business Logic

### 2.1 Monthly Rolling Accumulation

**What**: Each (ProtocolID, Year, Month) combination has exactly one row that accumulates the total deposit value for that period.

**Columns/Parameters Involved**: `ProtocolID`, `Year`, `Month`, `Amount`, `TimeStamp`

**Rules**:
- The UNIQUE constraint on (ProtocolID, Year, Month) ensures one row per protocol per month.
- Billing.UpdateMonthlyProcessingQuota adds to Amount as deposits are processed (likely an UPSERT pattern).
- TimeStamp reflects the last update time - active months show intraday timestamps (updated multiple times per day during business hours).
- Historical rows: once a month closes, its Amount represents the final total for that month (no further updates expected).
- Billing.GetMonthlyQuota supplements missing rows: if a protocol has IsDynamicRouting=1 but no row for the requested month yet, it returns Amount=0 for that protocol.

### 2.2 Routing Load Balancing

**What**: Monthly volumes feed directly into credit card routing decisions to balance between processors.

**Columns/Parameters Involved**: `ProtocolID`, `Amount`

**Rules**:
- Lower monthly volume -> higher probability of being selected for new deposits.
- GetCCProcessingBundle (used by GetCCProcessingBundleByBin, GetCCProcessingBundleByBinUS) reads this table's current month data to determine routing weights.
- Only protocols with Dictionary.Protocol.IsDynamicRouting=1 participate in dynamic routing.
- The three active protocols in 2026: WorldPay (23), Checkout (43), IxopayNuvei (46).

---

## 3. Data Overview

| ID | ProtocolID | Protocol | Year | Month | Amount (USD) | TimeStamp | Meaning |
|---|---|---|---|---|---|---|---|
| 125 | 23 | WorldPay | 2026 | 3 | $13,840,693 | 2026-03-17 16:19 | WorldPay's March 2026 running total as of mid-month. Updated multiple times today - live operational data. |
| 126 | 43 | Checkout | 2026 | 3 | $16,949,892 | 2026-03-17 15:42 | Checkout.com is processing the most volume this month (largest share). Updated hourly. |
| 127 | 46 | IxopayNuvei | 2026 | 3 | $2,483,787 | 2026-03-17 04:59 | IxopayNuvei (Nuvei gateway via Ixopay platform) processing smallest share - likely receives overflow or specific card types. |
| 122 | 23 | WorldPay | 2026 | 2 | $22,983,250 | 2026-02-28 | WorldPay's February 2026 final total. Larger than March mid-month as expected for a full closed month. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. Business lookups use (ProtocolID, Year, Month). |
| 2 | ProtocolID | int | NO | - | VERIFIED | Payment processing protocol/gateway identifier. Explicit FK to Dictionary.Protocol. Active protocols: 23=WorldPay, 43=Checkout, 46=IxopayNuvei. Only protocols with IsDynamicRouting=1 in Dictionary.Protocol participate in dynamic routing. |
| 3 | Year | int | NO | - | VERIFIED | Calendar year of the quota period (e.g., 2026). Combined with Month to define the monthly bucket. |
| 4 | Month | int | NO | - | VERIFIED | Calendar month number (1-12) of the quota period. Combined with Year to define the monthly bucket. The UNIQUE constraint on (ProtocolID, Year, Month) enforces one row per protocol per month. |
| 5 | Amount | decimal(18,2) | NO | - | VERIFIED | Cumulative total deposit value processed through this protocol in this month, in USD dollars. Updated by Billing.UpdateMonthlyProcessingQuota as deposits complete. Active months are updated multiple times daily. Range: $2.5M-$38M per processor per month based on 2025-2026 data. |
| 6 | TimeStamp | datetime | NO | - | CODE-BACKED | UTC timestamp of the last update to this row's Amount. Used to verify the routing system is actively updating quotas. Intraday updates (multiple per day) indicate an active period; a timestamp at month-end indicates a closed/final record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProtocolID | Dictionary.Protocol | FK (explicit BillingMonthlyQuota_ProtocolID) | References the payment processor protocol. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetMonthlyQuota | ProtocolID, Year, Month, Amount | SELECT reader | Primary reader. Returns existing rows UNION zero-amount rows for unstarted months. |
| Billing.UpdateMonthlyProcessingQuota | Amount, TimeStamp | UPSERT writer | Increments Amount as deposits process. |
| Billing.MonthlyQuoteAdd | - | INSERT writer | Adds new rows (initial setup per period). |
| Billing.GetCCProcessingBundle | (via GetMonthlyQuota) | Indirect reader | Credit card routing SP that uses monthly volumes for load balancing. |
| Billing.GetCCProcessingBundleByBin | (via GetMonthlyQuota) | Indirect reader | BIN-based credit card routing SP. |
| Billing.GetCCProcessingBundleByBinUS | (via GetMonthlyQuota) | Indirect reader | US-specific BIN-based routing SP. |
| Billing.CreditCardRoutingTransactionsVerification | - | Reader | Validates routing correctness using monthly quota data. |
| Billing.GetCCProtocolQuotas | - | Reader | Reports on monthly quota utilization per protocol. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.MonthlyQuota (table)
  (leaf - tables have no code-level dependencies)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Protocol | Table | Explicit FK target for ProtocolID column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetMonthlyQuota | Function | SELECT reader - routing calculation input |
| Billing.UpdateMonthlyProcessingQuota | Stored Procedure | UPSERT writer |
| Billing.MonthlyQuoteAdd | Stored Procedure | INSERT writer |
| Billing.GetCCProcessingBundle | Stored Procedure | Indirect reader via GetMonthlyQuota |
| Billing.GetCCProcessingBundleByBin | Stored Procedure | Indirect reader |
| Billing.GetCCProcessingBundleByBinUS | Stored Procedure | Indirect reader |
| Billing.CreditCardRoutingTransactionsVerification | Stored Procedure | Reader - validation |
| Billing.GetCCProtocolQuotas | Stored Procedure | Reader - reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MonthlyQuota | CLUSTERED PK | ID ASC | - | - | Active (FILLFACTOR=95) |
| BillingMonthlyQuota_UK | NC UNIQUE | ProtocolID ASC, Year ASC, Month ASC | - | - | Active (FILLFACTOR=95) - enforces one row per protocol per month |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MonthlyQuota | PRIMARY KEY | ID clustered |
| BillingMonthlyQuota_UK | UNIQUE | (ProtocolID, Year, Month) - one quota row per protocol per month |
| BillingMonthlyQuota_ProtocolID | FK | ProtocolID -> Dictionary.Protocol(ProtocolID) |

---

## 8. Sample Queries

### 8.1 Get current month's protocol volumes

```sql
SELECT
    p.Name AS Protocol,
    mq.Year,
    mq.Month,
    mq.Amount AS TotalDepositsUSD,
    mq.TimeStamp AS LastUpdated
FROM Billing.MonthlyQuota mq WITH (NOLOCK)
JOIN Dictionary.Protocol p WITH (NOLOCK) ON mq.ProtocolID = p.ProtocolID
WHERE mq.Year = YEAR(GETDATE())
  AND mq.Month = MONTH(GETDATE())
ORDER BY mq.Amount DESC
```

### 8.2 Get monthly volumes with routing quotas (using the function)

```sql
SELECT
    p.Name AS Protocol,
    q.Year,
    q.Month,
    q.Amount AS AccumulatedUSD
FROM Billing.GetMonthlyQuota(YEAR(GETDATE()), MONTH(GETDATE())) q
JOIN Dictionary.Protocol p WITH (NOLOCK) ON q.ProtocolID = p.ProtocolID
ORDER BY q.Amount DESC
```

### 8.3 Year-over-year protocol volume comparison

```sql
SELECT
    p.Name AS Protocol,
    mq.Year,
    SUM(mq.Amount) AS AnnualTotalUSD
FROM Billing.MonthlyQuota mq WITH (NOLOCK)
JOIN Dictionary.Protocol p WITH (NOLOCK) ON mq.ProtocolID = p.ProtocolID
GROUP BY p.Name, mq.Year
ORDER BY mq.Year DESC, AnnualTotalUSD DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.MonthlyQuota | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.MonthlyQuota.sql*
