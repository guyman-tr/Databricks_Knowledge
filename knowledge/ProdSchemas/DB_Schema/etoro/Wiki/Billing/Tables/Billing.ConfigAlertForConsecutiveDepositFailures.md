# Billing.ConfigAlertForConsecutiveDepositFailures

> Monitoring configuration table defining per-payment-method thresholds for consecutive deposit failure alerts - when the number of customers experiencing only failures reaches the threshold, an ops alert fires.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (FundingTypeID, MaxConsecutiveFailuresAllowed) - composite clustered PK |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR 95) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

`Billing.ConfigAlertForConsecutiveDepositFailures` is an operations monitoring configuration table that defines per-payment-method alert thresholds for detecting systemic deposit failures. Each row specifies: "for FundingTypeID X, if Y or more distinct customers have had only deposit failures (no successes) in the last 14 days, fire an alert."

This table exists to provide configurable, payment-method-specific monitoring thresholds rather than a single hardcoded value for all payment types. Different payment methods have different expected failure rates - UnionPay (30 threshold) and OnlineBanking (30 threshold) operate with higher normal failure counts than CreditCard or PayPal (both 10 threshold). The alert notifies the NOC team when a provider may be experiencing systemic issues.

The alert procedure `Billing.ALERT_CheckConsecutiveDepositsFailures_New` joins this table to dynamically retrieve the threshold per funding type, then filters results where the actual failure count meets or exceeds the configured threshold. The older procedure `Billing.ALERT_CheckConsecutiveDepositsFailures` uses the same table.

---

## 2. Business Logic

### 2.1 Per-Provider Alert Threshold

**What**: Each payment method has its own maximum consecutive failure threshold before triggering an alert.

**Columns/Parameters Involved**: `FundingTypeID`, `MaxConsecutiveFailuresAllowed`

**Rules**:
- Threshold = 10 for 12 of 14 monitored payment methods (standard sensitivity).
- Threshold = 30 for FundingTypeID=22 (UnionPay) and FundingTypeID=28 (OnlineBanking) - these methods have higher normal failure rates and require less sensitive alerting.
- Alert fires when: distinct customers with only-failures since last success >= MaxConsecutiveFailuresAllowed.
- 14-day lookback window: the alert only considers deposits in the last 14 days.
- Two payment generations are tracked separately (PaymentGeneration=0 old system, PaymentGeneration=1 new system).

**Diagram**:
```
ALERT_CheckConsecutiveDepositsFailures_New (scheduled job)
        |
        v
Find last successful deposit per FundingType in 14-day window
        |
        v
Count distinct customers with failures AFTER last success
        |
        v
JOIN ConfigAlertForConsecutiveDepositFailures -> get MaxConsecutiveFailuresAllowed per FundingType
        |
        +-- NumOfCustomers >= MaxConsecutiveFailuresAllowed
                |
                v
        ALERT: Provider FundingType has systemic failures
              (result returned to calling job for NOC notification)
```

---

## 3. Data Overview

| FundingTypeID | FundingType Name | MaxConsecutiveFailuresAllowed | Meaning |
|--------------|-----------------|------------------------------|---------|
| 1 | CreditCard | 10 | Alert when 10+ customers have consecutive CC failures - low tolerance, CC is high-priority. |
| 2 | WireTransfer | 10 | Wire transfer failures are rare enough that 10 consecutive warrants attention. |
| 3 | PayPal | 10 | PayPal provider failure alert threshold. |
| 22 | UnionPay | 30 | Higher threshold - UnionPay has more inherent volatility; 30 failures needed before alerting. |
| 28 | OnlineBanking | 30 | Online banking (local bank transfers) has higher normal failure rate; 30 threshold. |
| 29 | ACH | 10 | ACH deposit failures alert at 10 customers. |

*(14 rows total: FundingTypeIDs 1, 2, 3, 6, 8, 10, 11, 15, 21, 22, 28, 29, 30, 32)*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method being monitored. Part of composite PK. FK to Dictionary.FundingType. Currently configured: 1=CreditCard, 2=WireTransfer, 3=PayPal, 6=Neteller, 8=MoneyBookers, 10=WebMoney, 11=Giropay, 15=Sofort, 21=Yandex, 22=UnionPay, 28=OnlineBanking, 29=ACH, 30=RapidTransfer, 32=PWMB. Used in INNER JOIN by both ALERT procedures: `JOIN ... ON NOCF.FundingTypeID = BCAFC.FundingTypeID`. |
| 2 | MaxConsecutiveFailuresAllowed | int | NO | - | CODE-BACKED | Maximum number of distinct customers experiencing consecutive deposit failures (no successes in 14-day window) before an alert is triggered. Part of composite PK. Values: 10 (12 payment methods), 30 (UnionPay, OnlineBanking). Alert condition: `WHERE NumOfCustomers >= MaxConsecutiveFailuresAllowed`. Higher values = lower alert sensitivity for that payment method. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit FK | Identifies the payment method being threshold-configured. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.ALERT_CheckConsecutiveDepositsFailures_New | FundingTypeID | READER | JOINs on FundingTypeID to get the threshold per payment method for old payment generation (PaymentGeneration=0) alerts. |
| Billing.ALERT_CheckConsecutiveDepositsFailures | FundingTypeID | READER | Older version of the same alert procedure using the same configuration. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.ALERT_CheckConsecutiveDepositsFailures_New | Stored Procedure | READER - retrieves per-FundingType alert thresholds |
| Billing.ALERT_CheckConsecutiveDepositsFailures | Stored Procedure | READER - retrieves per-FundingType alert thresholds (older version) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingConfigAlertForConsecutiveDepositFailures | CLUSTERED PK | FundingTypeID ASC, MaxConsecutiveFailuresAllowed ASC | - | - | Active |

FILLFACTOR=95. PRIMARY filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingConfigAlertForConsecutiveDepositFailures | PRIMARY KEY | (FundingTypeID, MaxConsecutiveFailuresAllowed) - unique configuration per payment method |

---

## 8. Sample Queries

### 8.1 View all alert thresholds with payment method names

```sql
SELECT c.FundingTypeID, f.Name AS FundingTypeName, c.MaxConsecutiveFailuresAllowed
FROM [Billing].[ConfigAlertForConsecutiveDepositFailures] c WITH (NOLOCK)
INNER JOIN [Dictionary].[FundingType] f WITH (NOLOCK) ON c.FundingTypeID = f.FundingTypeID
ORDER BY c.MaxConsecutiveFailuresAllowed DESC, f.Name;
```

### 8.2 Identify which payment methods are NOT monitored

```sql
SELECT f.FundingTypeID, f.Name
FROM [Dictionary].[FundingType] f WITH (NOLOCK)
WHERE f.FundingTypeID NOT IN (
    SELECT FundingTypeID FROM [Billing].[ConfigAlertForConsecutiveDepositFailures] WITH (NOLOCK)
)
AND f.IsActive = 1
ORDER BY f.FundingTypeID;
```

### 8.3 Check current threshold for a specific payment method

```sql
SELECT FundingTypeID, MaxConsecutiveFailuresAllowed
FROM [Billing].[ConfigAlertForConsecutiveDepositFailures] WITH (NOLOCK)
WHERE FundingTypeID = 1;  -- CreditCard
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ConfigAlertForConsecutiveDepositFailures | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ConfigAlertForConsecutiveDepositFailures.sql*
