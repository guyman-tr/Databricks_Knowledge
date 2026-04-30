# Billing.DepositAlertReportByPlatformCountry

> Returns a two-period deposit comparison report grouped by customer country, client platform (Web/iOS/Android), payment method, and payment status, for use by the DepositAlert monitoring service.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositIDFrom/@DepositIDTo define current vs. previous windows; @excludeFundingTypeTxt excludes payment types |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositAlertReportByPlatformCountry` is the country-dimensional variant of `Billing.DepositAlertReportByPlatform`, produced as part of the same DepositAlert monitoring service deployment (ticket 46780, Geri Reshef, 11/07/2017). It adds a `CountryName` grouping dimension and a full payment status breakdown, allowing the alerting service to detect geographic anomalies in deposit activity.

This procedure is used when the alerting service needs to drill into which countries are seeing changes in deposit behaviour. For example, a sudden drop in approved credit card deposits from a specific country might indicate a regional payment gateway outage, a compliance block, or a fraud pattern.

Unlike `DepositAlertReportByPlatform` which only tracks "approved vs. not approved" (`Pased` flag), this procedure tracks distinct payment statuses with normalization: statuses `2=Approved`, `3=Decline`, `4=Technical`, `35=DeclineByRRE` (Risk Rules Engine declined) are shown by name; all other statuses are bucketed as `'Uncompleted'` (e.g., Pending, Processing). This gives a richer status breakdown for country-level analysis.

Country is resolved via the customer's registration country (`Customer.CustomerStatic.CountryID -> Dictionary.Country`), not the deposit's IP address. The IP address is selected in the subquery but only used as a `GROUP BY` key (CountryId alias), not surfaced in the final output columns - it acts as a deduplication dimension within the subquery aggregation.

One notable difference from `DepositAlertReportByPlatform`: the previous period uses `UNION ALL` instead of `UNION`, which could theoretically produce duplicate rows across periods if the subquery data overlaps. In practice, the Period discriminator (1 vs 2) ensures the outer pivot works correctly.

Confluence: "DepositAlert: Overview of Active and Ina" (MIMO Group space).

---

## 2. Business Logic

### 2.1 FundingType Exclusion Parsing

**What**: Same CSV-parsing pattern as DepositAlertReportByPlatform.

**Rules**: Identical to `Billing.DepositAlertReportByPlatform` section 2.1 - see that procedure for details.

### 2.2 Current vs. Previous Period UNION ALL

**What**: Two result sets using DepositID as a time proxy, joined with Country and PaymentStatus dimensions.

**Columns/Parameters Involved**: `@DepositIDFrom`, `@DepositIDTo`, all JOIN tables

**Rules**:
- **Period 1 (current)**: `DepositID >= @DepositIDFrom`
- **Period 2 (previous)**: `DepositID >= @DepositIDTo AND DepositID < @DepositIDFrom`
- Period 1 uses INNER JOIN to Billing.Deposit (explicit WITH NOLOCK); Period 2 uses JOIN without NOLOCK hint on Billing.Deposit (potential inconsistency in lock behavior)
- UNION ALL (not UNION) - relies on the outer GROUP BY to deduplicate
- Country joins: `Customer.CustomerStatic -> Dictionary.Country` via CountryID

### 2.3 Payment Status Normalization

**What**: Maps raw PaymentStatusID to grouped status labels for the alert report.

**Columns/Parameters Involved**: `Dictionary.PaymentStatus.PaymentStatusID`, `Dictionary.PaymentStatus.Name`

**Rules**:
- `CASE WHEN ps.PaymentStatusID IN (2,3,4,35) THEN ps.Name ELSE 'Uncompleted' END`
- PaymentStatusID=2 -> 'Approved'
- PaymentStatusID=3 -> 'Decline' (gateway declined)
- PaymentStatusID=4 -> 'Technical' (technical/communication failure)
- PaymentStatusID=35 -> 'DeclineByRRE' (declined by Risk Rules Engine)
- All others -> 'Uncompleted' (pending, processing, etc.)
- This normalization means the alert distinguishes between risk-declined vs. gateway-declined vs. approved

### 2.4 Aggregation and Pivoting

**What**: Groups by country + platform + payment type + payment status, pivots periods into side-by-side columns.

**Columns/Parameters Involved**: `Amount`, `ExchangeRate`, `Count(FundingID)`

**Rules**:
- `Amount = SUM(Amount * ExchangeRate)`: converts to USD equivalent
- `Count = COUNT(FundingID)`: deposit count per group
- Outer pivot: SUM(CASE WHEN Period=1 ...) for current, Period=2 for previous
- Ordered by CountryName, PaymentType, PaymentStatus, Amount, AmountPrev

**Output columns**:
| Column | Description |
|--------|-------------|
| CountryName | Customer's registration country name |
| Platform | Web/IOS/Android/Other (from ApplicationIdentifier) |
| PaymentType | Funding type name |
| PaymentStatus | Approved/Decline/Technical/DeclineByRRE/Uncompleted |
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
| 1 | @DepositIDFrom | INT | NO | - | CODE-BACKED | Lower bound of the current period window. Same semantics as Billing.DepositAlertReportByPlatform. |
| 2 | @DepositIDTo | INT | NO | - | CODE-BACKED | Lower bound of the previous period window. Previous window = [@DepositIDTo, @DepositIDFrom). |
| 3 | @excludeFundingTypeTxt | VARCHAR(8000) | NO | - | CODE-BACKED | Comma-separated FundingTypeIDs to exclude from the report. Same semantics as Billing.DepositAlertReportByPlatform. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Deposit data | Billing.Deposit | Read | Primary data source. See [Billing.Deposit](../Tables/Billing.Deposit.md). |
| Payment instrument | Billing.Funding | Read | Gets FundingTypeID for each deposit. See [Billing.Funding](../Tables/Billing.Funding.md). |
| Payment type name | Dictionary.FundingType | Read | Gets FundingType.Name + exclusion filter. |
| Customer country | Customer.CustomerStatic | Read (cross-schema) | Gets CountryID for the customer. |
| Country name | Dictionary.Country | Read | Resolves CountryID to CountryName and LongAbbreviation. |
| Platform | dbo.STS_Audit_LoginHistory | Read (cross-schema) | ApplicationIdentifier for platform via SessionID. |
| Status names | Dictionary.PaymentStatus | Read | PaymentStatus.Name for 2/3/4/35 normalization. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by the DepositAlert monitoring service for country-level deposit trend analysis.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositAlertReportByPlatformCountry (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Dictionary.FundingType (table)
├── Dictionary.PaymentStatus (table)
├── Dictionary.Country (table)
├── Customer.CustomerStatic (table) [cross-schema]
└── dbo.STS_Audit_LoginHistory (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source - amounts, status, SessionID, CID, DepositID filter |
| Billing.Funding | Table | JOIN to get FundingTypeID |
| Dictionary.FundingType | Table | FundingType.Name + exclusion filter |
| Dictionary.PaymentStatus | Table | Status name for 2/3/4/35 normalization |
| Dictionary.Country | Table | Country name and abbreviation from CountryID |
| Customer.CustomerStatic | Table (cross-schema) | Customer's CountryID |
| dbo.STS_Audit_LoginHistory | Table (cross-schema) | ApplicationIdentifier via SessionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DepositAlert monitoring service | External (App) | Country-level deposit trend comparison report |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run the country-platform report for last 500 vs prior 500 deposits

```sql
DECLARE @From INT, @To INT;
SELECT @From = MAX(DepositID) - 500,
       @To   = MAX(DepositID) - 1000
FROM Billing.Deposit WITH (NOLOCK);

EXEC Billing.DepositAlertReportByPlatformCountry
    @DepositIDFrom         = @From,
    @DepositIDTo           = @To,
    @excludeFundingTypeTxt = '';
```

### 8.2 Check payment status distribution by country for the same window

```sql
SELECT
    cnt.Name AS CountryName,
    CASE
        WHEN ps.PaymentStatusID IN (2,3,4,35) THEN ps.Name
        ELSE 'Uncompleted'
    END AS PaymentStatus,
    COUNT(*) AS DepositCount,
    SUM(d.Amount * d.ExchangeRate) AS TotalUSD
FROM Billing.Deposit d WITH (NOLOCK)
    JOIN Customer.CustomerStatic cust WITH (NOLOCK) ON d.CID = cust.CID
    JOIN Dictionary.Country cnt WITH (NOLOCK) ON cust.CountryID = cnt.CountryID
    JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON d.PaymentStatusID = ps.PaymentStatusID
WHERE d.DepositID >= 5000000
GROUP BY cnt.Name,
    CASE WHEN ps.PaymentStatusID IN (2,3,4,35) THEN ps.Name ELSE 'Uncompleted' END
ORDER BY TotalUSD DESC;
```

---

## 9. Atlassian Knowledge Sources

Confluence: "DepositAlert: Overview of Active and Ina" (MIMO Group space) - service overview for the DepositAlert monitoring system. Page not accessible. Ticket 46780 (Geri Reshef, 11/07/2017): original deployment of the DepositAlert report procedures family.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 1 Confluence (not accessible) + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositAlertReportByPlatformCountry | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositAlertReportByPlatformCountry.sql*
