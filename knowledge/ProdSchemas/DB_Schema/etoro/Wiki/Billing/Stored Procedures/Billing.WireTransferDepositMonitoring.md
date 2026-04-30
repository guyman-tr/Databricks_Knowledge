# Billing.WireTransferDepositMonitoring

> Monitoring report for wire transfer deposits (FundingTypeID=2): returns the percentage distribution of payment statuses for deposits modified within a date window (default: last 4 days). Used for operational health monitoring of the wire transfer payment channel.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate, @ToDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WireTransferDepositMonitoring` is an operational monitoring procedure for the wire transfer deposit channel. It calculates the percentage breakdown of payment statuses for all wire transfer deposits (FundingTypeID=2) whose `ModificationDate` falls within the specified window.

Wire transfer deposits are manual payment methods that can remain in various states (Pending, Approved, Rejected) for days. A healthy channel shows a high percentage of Approved deposits. Spikes in Pending or Rejected percentages indicate operational issues with the wire transfer processing team or external bank reconciliation.

The default window is the last 4 days from now (DBA-804). The percentage calculation was added in DBA-907. SET NOCOUNT ON was added in DBA-923.

Returns a result set of `PaymentStatus` (name string) and `Value` (percentage as FLOAT). Returns `0, 0` if no matching deposits exist.

---

## 2. Business Logic

### 2.1 Wire Transfer Deposit Filter

**What**: Selects payment status names for all wire transfer deposits in the modification window.

**Rules**:
- Filter: `BF.FundingTypeID = 2` (Wire Transfer only)
- Window: `BD.ModificationDate BETWEEN ISNULL(@FromDate, DATEADD(DAY, -4, GETUTCDATE())) AND ISNULL(@ToDate, GETUTCDATE())`
- Default window: last 4 days if both parameters are NULL
- Joins: Billing.Deposit, Customer.Customer, Dictionary.Country, Dictionary.PaymentStatus, Billing.Funding, Dictionary.FundingType
- Result stored in temp table `#PercentageCalc` containing only `PaymentStatus.Name`

### 2.2 Percentage Calculation

**What**: Calculates what percentage of all deposits in the window have each payment status.

**Rules**:
- Formula: `COUNT(PaymentStatus) * 100.0 / SUM(COUNT(*)) OVER()` - uses window function to get total count
- CAST to FLOAT with ROUND to 2 decimal places
- Groups by PaymentStatus name
- Result: `PaymentStatus` (name) + `Value` (percentage as FLOAT, 0.00-100.00)

**Example Output**:
```
PaymentStatus  | Value
Pending        | 45.23
Approved       | 50.00
Rejected       |  4.77
```

### 2.3 Empty Result Handling

**Rules**:
- `IF EXISTS(SELECT 1 FROM #PercentageCalc)`: runs the percentage query if data exists
- `ELSE`: returns `0 AS PaymentStatus, 0 AS [Value]` - a sentinel row indicating no data
- Callers should check if PaymentStatus = 0 to detect the no-data case

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | YES | NULL | CODE-BACKED | Start of the modification date window (inclusive). When NULL, defaults to 4 days ago from GETUTCDATE(). |
| 2 | @ToDate | DATETIME | YES | NULL | CODE-BACKED | End of the modification date window (inclusive). When NULL, defaults to GETUTCDATE(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Billing.Deposit | SELECT (main source) | Wire transfer deposit records |
| BD.FundingID | Billing.Funding | JOIN | Provides FundingTypeID=2 filter |
| BD.PaymentStatusID | Dictionary.PaymentStatus | JOIN | Payment status name for grouping |
| BD.CID | Customer.Customer | JOIN | Customer record (joined but not used in output) |
| CC.CountryID | Dictionary.Country | JOIN | Country lookup (joined for context) |
| BF.FundingTypeID | Dictionary.FundingType | JOIN | FundingType name (joined for context) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Operations monitoring (application) | Wire transfer dashboard | Application call | Monitors health of wire transfer processing channel |
| SQL Agent job / alerting (operations) | Scheduled monitoring | Scheduled call | Triggered to detect payment processing anomalies |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WireTransferDepositMonitoring (procedure)
+-- Billing.Deposit (table) [SELECT - wire transfer deposits]
+-- Billing.Funding (table) [JOIN - FundingTypeID=2 filter]
+-- Customer.Customer (table) [JOIN]
+-- Dictionary.Country (table) [JOIN]
+-- Dictionary.PaymentStatus (table) [JOIN - status name]
+-- Dictionary.FundingType (table) [JOIN]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data: ModificationDate, PaymentStatusID, FundingID |
| Billing.Funding | Table | Filter: FundingTypeID=2 (Wire Transfer) |
| Dictionary.PaymentStatus | Table | Status name for percentage grouping |
| Customer.Customer | Table | JOIN (no output columns used) |
| Dictionary.Country | Table | JOIN (no output columns used) |
| Dictionary.FundingType | Table | JOIN (no output columns used) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Operations / monitoring dashboards (application) | Application | Monitors wire transfer deposit processing health |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Default window = last 4 days | Design | Chosen to cover the typical wire transfer processing cycle (DBA-804) |
| Empty result = 0,0 sentinel | Design | Returns `0 AS PaymentStatus, 0 AS [Value]` when no deposits found; callers must handle this sentinel |
| WITH(NOLOCK) hints | Concurrency | Most JOINs use NOLOCK for read performance on monitoring queries |
| SET NOCOUNT ON | Performance | Suppresses row count messages (added DBA-923) |

---

## 8. Sample Queries

### 8.1 Check current wire transfer deposit health (last 4 days)
```sql
EXEC Billing.WireTransferDepositMonitoring
    @FromDate = NULL,
    @ToDate   = NULL;
```

### 8.2 Check for a specific date range
```sql
EXEC Billing.WireTransferDepositMonitoring
    @FromDate = '2026-03-15 00:00',
    @ToDate   = '2026-03-18 23:59';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.1/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.WireTransferDepositMonitoring | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WireTransferDepositMonitoring.sql*
