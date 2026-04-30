# Billing.Alert_Deposits

> Monitoring alert procedure that returns deposit activity for a configurable time window (default: last 1 hour), enriched with country, payment status, and funding type lookups; signals 0 (no deposits) or 1 (deposits found) to alerting systems.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset (ModificationDate, DepositID, Country, IsFTD, PaymentStatus, FundingType, Amount) + RETURN value (0=no rows, 1=rows found) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.Alert_Deposits` is an operational monitoring procedure that retrieves deposit activity within a specified time window, enriched with human-readable country, payment status, and funding type information. It is called by monitoring dashboards or alerting workflows to surface a view of recent deposit transactions.

The procedure was introduced on 21/07/2021 (Shay O., initial version) and extended on 23/11/2021 (KateM) to include the Amount column. It follows the same alert pattern as `Billing.Alert_CashoutSentToProvider`: return the relevant records plus a 0/1 RETURN value that allows a calling monitor to determine at a glance whether any records exist without parsing the resultset.

The default time window (last 1 hour) makes it suitable for near-real-time monitoring checks run on an hourly or more frequent schedule. A deposit monitoring system can call this procedure, check the return value, and escalate if zero deposits have been seen in the last hour (which might indicate a payment processing outage) or if unusual patterns appear in the result.

---

## 2. Business Logic

### 2.1 Time Window and Enriched Output

**What**: Deposits in the specified time window are returned with full business context by joining to lookup tables.

**Parameters/Columns Involved**: `@FromDate`, `@ToDate`, `Billing.Deposit`, `Customer.Customer`, `Dictionary.Country`, `Dictionary.PaymentStatus`, `Billing.Funding`, `Dictionary.FundingType`

**Rules**:
- Filter: `ModificationDate BETWEEN ISNULL(@FromDate, DATEADD(HOUR, -1, GETUTCDATE())) AND ISNULL(@ToDate, GETUTCDATE())`.
- Default window: the last 1 hour up to now.
- Note: `@FromDate` and `@ToDate` follow conventional usage here (unlike `Alert_CashoutSentToProvider`) - @FromDate is the start (earlier) and @ToDate is the end (later) of the window.
- The ModificationDate column drives filtering rather than the creation date - this means re-processed or status-updated deposits are included if their modification falls in the window.
- `Billing.Funding` is joined to resolve the FundingTypeID for the deposit's payment instrument.
- `IsFTD` (First Time Deposit) flag from `Billing.Deposit` is returned directly, enabling monitoring systems to track first-deposit rates.

### 2.2 Alert Signal Return Value

**What**: Returns 0 if no deposits were found in the window; 1 if any deposits were found.

**Rules**:
- `RETURN(CASE @@ROWCOUNT WHEN 0 THEN 0 ELSE 1 END)`.
- Return value 0 may be the alert condition itself: no deposits in the last hour could signal a payment system outage.
- Return value 1 confirms normal deposit activity is occurring.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | YES | NULL | VERIFIED | Start of the monitoring time window (lower bound). When NULL, defaults to DATEADD(HOUR, -1, GETUTCDATE()) - 1 hour ago. Conventional usage: @FromDate is the earlier/older boundary (unlike Alert_CashoutSentToProvider which inverts this). |
| 2 | @ToDate | DATETIME | YES | NULL | VERIFIED | End of the monitoring time window (upper bound). When NULL, defaults to GETUTCDATE() - now. |

**Result set columns**:

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | ModificationDate | Billing.Deposit.ModificationDate | Last modification timestamp of the deposit record. Used as the window filter. |
| 2 | DepositID | Billing.Deposit.DepositID | Primary key of the deposit record. |
| 3 | Country | Dictionary.Country.Name | Customer's country of residence (via Customer.Customer.CountryID). |
| 4 | IsFTD | Billing.Deposit.IsFTD | First Time Deposit flag: 1=this is the customer's first deposit, 0=subsequent deposit. |
| 5 | Payment Status | Dictionary.PaymentStatus.Name | Human-readable deposit status name (e.g., "Approved", "Declined"). |
| 6 | Funding Type | Dictionary.FundingType.Name | Human-readable payment method name (e.g., "CreditCard", "PayPal"). Resolved via Billing.Funding. |
| 7 | Amount | Billing.Deposit.Amount | Deposit amount in the deposit's currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BD.CID | Customer.Customer | READER (JOIN) | Resolves customer record to get CountryID for country name lookup. |
| CC.CountryID | Dictionary.Country | READER (JOIN) | Resolves CountryID to country name for the output. |
| BD.PaymentStatusID | Dictionary.PaymentStatus | READER (JOIN) | Resolves PaymentStatusID to human-readable status name. |
| BD.FundingID | Billing.Funding | READER (JOIN) | Resolves FundingID to get FundingTypeID for payment method lookup. |
| BF.FundingTypeID | Dictionary.FundingType | READER (JOIN) | Resolves FundingTypeID to payment method name. |
| (SELECT base) | Billing.Deposit | READER | Main data source - filtered by ModificationDate window. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from monitoring/alerting systems on a scheduled basis.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Alert_Deposits (procedure)
|- Billing.Deposit (table)             [SELECT base - time window filter]
|- Customer.Customer (table)           [JOIN - get customer CountryID]
|- Dictionary.Country (table)          [JOIN - resolve country name]
|- Dictionary.PaymentStatus (table)    [JOIN - resolve payment status name]
|- Billing.Funding (table)             [JOIN - resolve FundingTypeID from FundingID]
+- Dictionary.FundingType (table)      [JOIN - resolve payment method name]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Main SELECT source; filtered by ModificationDate within the time window |
| Customer.Customer | Table | JOIN on CID to get customer's CountryID |
| Dictionary.Country | Table | JOIN on CountryID to get country name |
| Dictionary.PaymentStatus | Table | JOIN on PaymentStatusID to get status name |
| Billing.Funding | Table | JOIN on FundingID to get FundingTypeID |
| Dictionary.FundingType | Table | JOIN on FundingTypeID to get payment method name |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from monitoring/alerting tooling.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Check deposits in the last hour (default monitoring call)
```sql
DECLARE @AlertStatus INT;
EXEC @AlertStatus = Billing.Alert_Deposits;
SELECT @AlertStatus AS DepositsFound;  -- 0 = no deposits (possible outage), 1 = deposits present
```

### 8.2 Check deposits in a specific window
```sql
DECLARE @AlertStatus INT;
EXEC @AlertStatus = Billing.Alert_Deposits
    @FromDate = '2026-03-17 09:00:00',
    @ToDate   = '2026-03-17 10:00:00';
SELECT @AlertStatus AS DepositsFound;
```

### 8.3 Direct query equivalent (debugging the monitoring result)
```sql
SELECT  BD.ModificationDate,
        BD.DepositID,
        DC.Name       AS Country,
        BD.IsFTD,
        DPS.Name      AS PaymentStatus,
        DFT.Name      AS FundingType,
        BD.Amount
FROM    Billing.Deposit BD WITH (NOLOCK)
JOIN    Customer.Customer CC WITH (NOLOCK) ON BD.CID = CC.CID
JOIN    Dictionary.Country DC              ON CC.CountryID = DC.CountryID
JOIN    Dictionary.PaymentStatus DPS       ON BD.PaymentStatusID = DPS.PaymentStatusID
JOIN    Billing.Funding BF WITH (NOLOCK)   ON BF.FundingID = BD.FundingID
JOIN    Dictionary.FundingType DFT         ON DFT.FundingTypeID = BF.FundingTypeID
WHERE   BD.ModificationDate BETWEEN DATEADD(HOUR, -1, GETUTCDATE()) AND GETUTCDATE()
ORDER BY BD.DepositID ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 10/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.Alert_Deposits | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.Alert_Deposits.sql*
