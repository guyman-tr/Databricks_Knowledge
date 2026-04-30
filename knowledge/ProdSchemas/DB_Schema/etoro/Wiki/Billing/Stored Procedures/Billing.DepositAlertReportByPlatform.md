# Billing.DepositAlertReportByPlatform

> Returns a two-period deposit comparison report grouped by client platform (Web/iOS/Android) and payment method, using DepositID ranges as a time proxy, for use by the DepositAlert monitoring service.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositIDFrom/@DepositIDTo define current vs. previous windows; @excludeFundingTypeTxt excludes payment types |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositAlertReportByPlatform` powers the DepositAlert monitoring service (ticket 46780, Geri Reshef, 11/07/2017) by producing a platform-by-payment-type breakdown of deposit activity across two consecutive DepositID windows. The report allows the service to compare the current period against the immediately preceding period and detect anomalous drops or spikes in deposit volume or approval rates.

DepositID is used as a time proxy: since DepositID is a monotonically increasing identity, `@DepositIDFrom` acts as the boundary between "current" and "previous", and `@DepositIDTo` defines how far back the previous window extends. This is a performant approach that avoids timestamp range scans on non-indexed columns.

The platform dimension is derived by joining `Billing.Deposit` to `dbo.STS_Audit_LoginHistory` on `SessionID`, resolving the `ApplicationIdentifier` of the browser/app session that created the deposit. The `ApplicationIdentifier` is normalized to human-readable labels:
- `retoro` -> Web
- `retoroios` -> iOS
- `retoroandroid` -> Android
- Anything else -> Other

Deposits without a `SessionID` or without a matching `STS_Audit_LoginHistory` record are excluded (INNER JOIN; `SessionID IS NOT NULL` filter). This is by design - only session-tracked deposits can be attributed to a platform.

The `@excludeFundingTypeTxt` parameter accepts a comma-separated list of FundingTypeIDs to omit, allowing the alerting service to exclude specific payment methods (e.g., internal test types, deprecated instruments) from the comparison.

Confluence: "DepositAlert: Overview of Active and Ina" (MIMO Group space) - the service overview that orchestrates calls to this and related report procedures.

---

## 2. Business Logic

### 2.1 FundingType Exclusion Parsing

**What**: Parses the comma-separated exclusion list into a table variable for efficient filtering.

**Columns/Parameters Involved**: `@excludeFundingTypeTxt`, `@excludeFundingType` (table variable), `Dictionary.FundingType.FundingTypeID`

**Rules**:
- Wraps the input string with commas: `(','+@excludeFundingTypeTxt+',') LIKE ('%,'+CAST(FundingTypeID AS VARCHAR(8000))+',%')`
- This correctly handles any position in the CSV (first, middle, last)
- Filters Dictionary.FundingType -> inserts matching FundingTypeID values into @excludeFundingType
- If @excludeFundingTypeTxt is empty string '' -> no IDs match -> all funding types included

### 2.2 Current vs. Previous Period UNION

**What**: Produces two separate aggregations (current and prior period) using DepositID ranges, then pivots them into side-by-side columns.

**Columns/Parameters Involved**: `@DepositIDFrom`, `@DepositIDTo`, `Billing.Deposit.DepositID`

**Rules**:
- **Period 1 (current)**: `DepositID >= @DepositIDFrom` - all deposits from the current window forward
- **Period 2 (previous)**: `DepositID >= @DepositIDTo AND DepositID < @DepositIDFrom` - deposits in the previous window
- Both periods share identical JOIN logic (Deposit -> STS_Audit_LoginHistory -> Funding -> FundingType)
- UNION (not UNION ALL) - deduplicates across periods (safe since Period column is a discriminator)
- Deposits without SessionID or ApplicationIdentifier are excluded by INNER JOIN and IS NOT NULL filters

### 2.3 Aggregation and Pivoting

**What**: Aggregates by platform + payment type + approval flag, then pivots current/previous into separate Amount and Count columns.

**Columns/Parameters Involved**: `ApplicationIdentifier`, `ft.Name`, `PaymentStatusID`, `Amount`, `ExchangeRate`

**Rules**:
- `Pased` (sic - typo for "Passed"): `CASE WHEN PaymentStatusID=2 THEN 1 ELSE 0 END` - 2=Approved
- `Amount = SUM(Amount * ExchangeRate)`: converts deposit amount to USD using the deposit-time exchange rate
- Outer query pivots: `SUM(CASE WHEN Period=1 THEN Amount ELSE 0 END)` -> current; Period=2 -> previous
- Ordered by ApplicationIdentifierFrom, PaymentTypeName, Pased

**Output columns**:
| Column | Description |
|--------|-------------|
| ApplicationIdentifierFrom | Platform: Web/IOS/Android/Other |
| PaymentTypeName | Funding type name (e.g., CreditCard, ACH, PayPal) |
| Pased | 1=Approved deposits, 0=Non-approved deposits |
| Amount | Current period total USD amount |
| AmountPrev | Previous period total USD amount |
| Count | Current period deposit count |
| CountPrev | Previous period deposit count |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositIDFrom | INT | NO | - | CODE-BACKED | The lower bound of the current period. Deposits with DepositID >= this value are "current". Also acts as the upper exclusive bound for the previous period. Used as a time proxy since DepositID is monotonically increasing. |
| 2 | @DepositIDTo | INT | NO | - | CODE-BACKED | The lower bound of the previous period. Deposits with DepositID >= @DepositIDTo AND < @DepositIDFrom constitute the "previous" period for comparison. |
| 3 | @excludeFundingTypeTxt | VARCHAR(8000) | NO | - | CODE-BACKED | Comma-separated list of FundingTypeIDs to exclude from both periods (e.g., '1,29,55'). Allows the DepositAlert service to filter out specific payment methods that would skew the comparison. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID range filter | Billing.Deposit | Read | Source of deposit amounts, payment statuses, and session IDs. See [Billing.Deposit](../Tables/Billing.Deposit.md). |
| Platform attribution | dbo.STS_Audit_LoginHistory | Read (cross-schema) | Resolves ApplicationIdentifier (platform) from the deposit's SessionID. |
| Payment method name | Billing.Funding | Read | Gets FundingTypeID for each deposit's payment instrument. See [Billing.Funding](../Tables/Billing.Funding.md). |
| Payment method name | Dictionary.FundingType | Read | Gets FundingType.Name for grouping and the exclusion list lookup. |
| Exclusion filter | Dictionary.FundingType | Read | Parses @excludeFundingTypeTxt into FundingTypeIDs to exclude. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by the DepositAlert monitoring service to generate platform-level deposit trend reports.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositAlertReportByPlatform (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table)
└── dbo.STS_Audit_LoginHistory (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source - amounts, status, SessionID, DepositID range filter |
| Billing.Funding | Table | JOIN to get FundingTypeID from deposit's FundingID |
| Dictionary.FundingType | Table | FundingType.Name for grouping + FundingTypeID for exclusion filter |
| dbo.STS_Audit_LoginHistory | Table (cross-schema) | ApplicationIdentifier for platform categorization via SessionID JOIN |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositAlert monitoring service | External (App) | Calls this procedure to generate platform-level deposit comparison reports |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Compare last 500 deposits vs. previous 500 deposits by platform, excluding internal test types

```sql
-- Find a reference DepositID for the window boundary
DECLARE @From INT, @To INT;
SELECT @From = MAX(DepositID) - 500,
       @To   = MAX(DepositID) - 1000
FROM Billing.Deposit WITH (NOLOCK);

EXEC Billing.DepositAlertReportByPlatform
    @DepositIDFrom         = @From,
    @DepositIDTo           = @To,
    @excludeFundingTypeTxt = '99,100';  -- exclude test funding types
```

### 8.2 Include all funding types (empty exclusion list)

```sql
EXEC Billing.DepositAlertReportByPlatform
    @DepositIDFrom         = 5000000,
    @DepositIDTo           = 4990000,
    @excludeFundingTypeTxt = '';
```

### 8.3 Check current deposit approval rate by platform manually

```sql
SELECT
    CASE
        WHEN alh.ApplicationIdentifier = 'retoro'        THEN 'Web'
        WHEN alh.ApplicationIdentifier = 'retoroios'     THEN 'IOS'
        WHEN alh.ApplicationIdentifier = 'retoroandroid' THEN 'Android'
        ELSE 'Other'
    END AS Platform,
    COUNT(*) AS Total,
    SUM(CASE WHEN d.PaymentStatusID = 2 THEN 1 ELSE 0 END) AS Approved,
    CAST(SUM(CASE WHEN d.PaymentStatusID = 2 THEN 1.0 ELSE 0 END) / COUNT(*) * 100 AS DECIMAL(5,2)) AS ApprovalRate
FROM Billing.Deposit d WITH (NOLOCK)
    INNER JOIN dbo.STS_Audit_LoginHistory alh WITH (NOLOCK)
        ON d.SessionID = alh.SessionIdentifier
WHERE d.SessionID IS NOT NULL
  AND alh.ApplicationIdentifier IS NOT NULL
  AND d.DepositID >= 5000000
GROUP BY alh.ApplicationIdentifier
ORDER BY Total DESC;
```

---

## 9. Atlassian Knowledge Sources

Confluence: "DepositAlert: Overview of Active and Ina" (MIMO Group space) - service overview for the DepositAlert monitoring system that calls this procedure. Page content not accessible. Ticket 46780 (Geri Reshef, 11/07/2017): "Queries used under DepositAlert service, please verify" - the original deployment of the DepositAlert report procedures family.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 1 Confluence (not accessible) + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositAlertReportByPlatform | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositAlertReportByPlatform.sql*
