# Billing.QuotaManagement

> Per-payment-protocol monthly processing quota configuration used by the CC routing engine to determine which processors have capacity remaining and whether priority routing is valid.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Billing.QuotaManagement defines the minimum and maximum monthly transaction volume thresholds for each credit card payment protocol (processor). Each row specifies how much volume (in monetary units) should flow through a given protocol per quota period (daily/weekly/monthly/yearly). In practice, all current configurations use the monthly period.

This table is a cornerstone of the CC payment routing system. When a customer initiates a deposit, the routing engine evaluates which processors still have quota capacity. A processor's quota is "filled" when its actual monthly processed amount (tracked in Billing.MonthlyQuota) exceeds the QuotaMin threshold. The routing engine uses this to enforce contractual minimum volume commitments with payment processors and to avoid over-routing to any single provider.

QuotaManagement data flows into three key routing procedures: GetCCProcessingBundle (general CC routing), GetCCProcessingBundleByBin (BIN-based routing), and GetCCProcessingBundleByBinUS (US-specific BIN routing). Each procedure JOINs this table to append quota data to the processor selection result. The monitoring procedure CreditCardRoutingTransactionsVerification uses QuotaManagement to verify that routing decisions are consistent with quota utilization.

---

## 2. Business Logic

### 2.1 Quota Threshold and FilledQuota Calculation

**What**: The minimum monthly volume commitment per processor that triggers a "quota filled" state, used to route deposits away from full processors.

**Columns/Parameters Involved**: `QuotaMin`, `QuotaMax`, `ProtocolID`

**Rules**:
- FilledQuota = 1 when actual monthly processed amount exceeds QuotaMin: `CASE WHEN QuotaMin < ProcessedAmount THEN 1 ELSE 0 END`
- Percentage fill = `(ProcessedAmount / QuotaMin) * 100`
- QuotaMax is currently always 0 in production - no upper cap is enforced
- Priority routing (RoutingReasonID=2) is valid ONLY when at least one provider has not yet reached 100% quota fill
- If ALL providers are at or above threshold, CreditCardRoutingTransactionsVerification flags deposits routed via priority as incorrect

**Diagram**:
```
Billing.MonthlyQuota (current month processed amount)
   ProcessedAmount per ProtocolID
          |
          v
Billing.QuotaManagement
   QuotaMin per ProtocolID
          |
          v
  FilledQuota = (ProcessedAmount > QuotaMin) ? 1 : 0
  Percentage  = (ProcessedAmount / QuotaMin) * 100
          |
          v
GetCCProcessingBundle* procedures return this to routing engine
Routing engine uses FilledQuota to select available processor
```

### 2.2 Routing Validity Monitoring

**What**: CreditCardRoutingTransactionsVerification uses QuotaManagement to detect invalid CC routing decisions.

**Columns/Parameters Involved**: `ProtocolID`, `QuotaMin`

**Rules**:
- The monitoring proc snapshots current month fill percentages for all protocols with MonthlyQuota data
- If no protocol has reached the threshold (@Threshold parameter, default 100%), then routing deposits via Priority (RoutingReasonID=2) is considered an error
- This enforces that priority routing only occurs when processors are at capacity
- Alerts are inserted into #RoutingDiscrepancies when violations are found

---

## 3. Data Overview

| ID | ProtocolID | Protocol Name | QuotaType | QuotaMin | QuotaMax | Meaning |
|----|-----------|---------------|-----------|----------|----------|---------|
| 1 | 18 | WireCard | 2 (Monthly) | 10,000,000 | 0 | WireCard Bank must process at least $10M/month before being considered "quota filled". WireCard is a European CC acquirer. |
| 2 | 23 | WorldPay | 2 (Monthly) | 1 | 0 | WorldPay quota minimum is effectively $1 (no real minimum) - all volume qualifies immediately. Common for high-priority default processor. |
| 3 | 31 | Adyen | 2 (Monthly) | 6,000,000 | 0 | Adyen must process $6M/month. Adyen is a global payment platform used for EU/APAC routing. |
| 5 | 43 | Checkout | 2 (Monthly) | 58,000,000 | 0 | Checkout.com has a $58M/month minimum commitment - the largest quota in the system, indicating it is the primary processor. |
| 6 | 46 | IxopayNuvei | 2 (Monthly) | 54,000,000 | 0 | Nuvei (via Ixopay gateway) requires $54M/month - indicates a major processing relationship with volume guarantees. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | - | CODE-BACKED | Surrogate primary key. Auto-increment integer uniquely identifying each quota configuration row. Not a business key - ProtocolID is the meaningful identifier. |
| 2 | ProtocolID | INT | NO | - | VERIFIED | Payment protocol (processor) this quota applies to. FK to Dictionary.Protocol(ProtocolID). All current rows reference major CC processors: 18=WireCard, 23=WorldPay, 31=Adyen, 43=Checkout, 46=IxopayNuvei. JOINed by GetCCProcessingBundle* procedures on `BDPT.ProtocolID = BQMT.ProtocolID`. |
| 3 | QuotaType | INT | NO | - | CODE-BACKED | Time period for quota measurement. Implicit FK to Billing.QuotaType: 1=Yearly, 2=Monthly, 3=Weekly, 4=Daily. All current rows = 2 (Monthly). Determines the aggregation window in Billing.MonthlyQuota comparison. |
| 4 | QuotaMax | DECIMAL(18,2) | NO | - | CODE-BACKED | Maximum monthly processing volume cap. Currently always 0 in production - no upper ceiling is enforced on any processor. Read by GetCCProcessingBundle* procedures as `COALESCE(BQMT.QuotaMax, 0) as MaxQuota` in the result set. Upper-cap enforcement would require application-layer change. |
| 5 | QuotaMin | DECIMAL(18,2) | NO | - | VERIFIED | Minimum monthly processing volume threshold. When actual processed amount (Billing.MonthlyQuota.Amount) exceeds this value, the processor is considered "quota filled". Used in: `CASE WHEN BQMT.QuotaMin < BMQ.Amount THEN 1 ELSE 0 END AS FilledQuota` and `CAST(((BMQ.Amount/BQMT.QuotaMin)*100) AS NUMERIC(18,2)) as Percentage`. Range in data: 1 (WorldPay - no real minimum) to 58,000,000 (Checkout - major volume commitment). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProtocolID | Dictionary.Protocol | FK (BillingQuotaMgmt_ProtocolID) | Each quota row is tied to one payment protocol. Protocol defines the payment class, name (e.g., "Adyen"), and ClassKey used by the payment DLL. |
| QuotaType | Billing.QuotaType | Implicit FK | QuotaType values: 1=Yearly, 2=Monthly, 3=Weekly, 4=Daily. No FK constraint defined in DDL. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetCCProcessingBundle | ProtocolID | INNER JOIN | Core CC routing procedure - JOINs to append MinQuota, MaxQuota, FilledQuota, and Percentage to processor selection results |
| Billing.GetCCProcessingBundleByBin | ProtocolID | INNER JOIN | BIN-based CC routing - same pattern as GetCCProcessingBundle, adds BIN filtering |
| Billing.GetCCProcessingBundleByBinUS | ProtocolID | INNER JOIN | US-specific BIN routing variant |
| Billing.GetCCProtocolQuotas | ProtocolID | INNER JOIN | Returns quota status per protocol for a given currency/card type combination |
| Billing.CreditCardRoutingTransactionsVerification | ProtocolID | INNER JOIN (via MonthlyQuota) | Monitoring procedure that validates routing decisions against quota fill levels |
| MIMOAlerts.FinancialDiscrepancies_GetMonthlyQuota | - | Reference | MIMO alerting system references quota context for financial discrepancy monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.QuotaManagement (table)
├── Dictionary.Protocol (table) [FK: ProtocolID]
└── Billing.QuotaType (table) [implicit FK: QuotaType]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Protocol | Table | FK constraint BillingQuotaMgmt_ProtocolID - ProtocolID must exist in Dictionary.Protocol |
| Billing.QuotaType | Table | Implicit FK - QuotaType values correspond to Billing.QuotaType.ID (no DDL constraint) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCCProcessingBundle | Stored Procedure | READER - JOINs by ProtocolID to get quota thresholds for routing result |
| Billing.GetCCProcessingBundleByBin | Stored Procedure | READER - BIN-based routing, same quota JOIN pattern |
| Billing.GetCCProcessingBundleByBinUS | Stored Procedure | READER - US variant of BIN routing |
| Billing.GetCCProtocolQuotas | Stored Procedure | READER - Returns quota data per protocol for a given currency and card type |
| Billing.CreditCardRoutingTransactionsVerification | Stored Procedure | READER - Validates routing against quota thresholds |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_QuotaManagement | CLUSTERED PK | ID ASC | - | - | Active |

Index options: FILLFACTOR=95, OPTIMIZE_FOR_SEQUENTIAL_KEY=OFF.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_QuotaManagement | PRIMARY KEY CLUSTERED | ID must be unique |
| BillingQuotaMgmt_ProtocolID | FOREIGN KEY | ProtocolID must exist in Dictionary.Protocol(ProtocolID) |

---

## 8. Sample Queries

### 8.1 Get current quota status for all CC processors this month

```sql
SELECT
    qm.ProtocolID,
    p.Name AS ProtocolName,
    qt.Name AS QuotaTypeName,
    qm.QuotaMin,
    qm.QuotaMax,
    COALESCE(mq.Amount, 0) AS ProcessedAmount,
    COALESCE(CAST(((mq.Amount / qm.QuotaMin) * 100) AS NUMERIC(18,2)), 0) AS FillPercentage,
    CASE WHEN qm.QuotaMin < COALESCE(mq.Amount, 0) THEN 1 ELSE 0 END AS FilledQuota
FROM [Billing].[QuotaManagement] qm WITH (NOLOCK)
INNER JOIN [Dictionary].[Protocol] p WITH (NOLOCK) ON p.ProtocolID = qm.ProtocolID
LEFT JOIN [Billing].[QuotaType] qt WITH (NOLOCK) ON qt.ID = qm.QuotaType
LEFT JOIN [Billing].[MonthlyQuota] mq WITH (NOLOCK)
    ON mq.ProtocolID = qm.ProtocolID
    AND mq.[Year] = YEAR(GETUTCDATE())
    AND mq.[Month] = MONTH(GETUTCDATE())
ORDER BY FillPercentage DESC
```

### 8.2 Identify processors that have reached quota threshold

```sql
DECLARE @Year INT = YEAR(GETUTCDATE())
DECLARE @Month INT = MONTH(GETUTCDATE())

SELECT
    qm.ProtocolID,
    p.Name AS ProcessorName,
    qm.QuotaMin,
    mq.Amount AS ProcessedAmount,
    CAST((mq.Amount / qm.QuotaMin * 100) AS NUMERIC(18,2)) AS FillPct,
    CASE WHEN qm.QuotaMin < mq.Amount THEN 'QUOTA FILLED' ELSE 'Available' END AS Status
FROM [Billing].[QuotaManagement] qm WITH (NOLOCK)
INNER JOIN [Dictionary].[Protocol] p WITH (NOLOCK) ON p.ProtocolID = qm.ProtocolID
INNER JOIN [Billing].[MonthlyQuota] mq WITH (NOLOCK)
    ON mq.ProtocolID = qm.ProtocolID
    AND mq.[Year] = @Year AND mq.[Month] = @Month
ORDER BY FillPct DESC
```

### 8.3 Full quota configuration with protocol details

```sql
SELECT
    qm.ID,
    qm.ProtocolID,
    p.Name AS ProtocolName,
    p.ClassKey,
    qt.Name AS QuotaType,
    qm.QuotaMin,
    qm.QuotaMax
FROM [Billing].[QuotaManagement] qm WITH (NOLOCK)
INNER JOIN [Dictionary].[Protocol] p WITH (NOLOCK) ON p.ProtocolID = qm.ProtocolID
LEFT JOIN [Billing].[QuotaType] qt WITH (NOLOCK) ON qt.ID = qm.QuotaType
ORDER BY qm.QuotaMin DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Routing Tool Mapping](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13998850143) | Confluence | Describes routing tool capabilities including quota-based CC routing configuration managed via the backoffice routing tool (MEDIUM confidence - general routing context) |
| [Configuration Management in Payments](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1576993235) | Confluence | Describes three tools managing payment configuration: Backoffice, Routing tool, and CCM - QuotaManagement is a routing configuration table (MEDIUM confidence) |

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.6/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.QuotaManagement | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.QuotaManagement.sql*
