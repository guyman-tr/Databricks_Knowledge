# Billing.iDEALDepositApproveRatioForLastHour

> Real-time monitoring variant of iDEALDepositApproveRatio: no parameters - auto-computes a 1-hour window (previous complete UTC hour), returns per-bank per-hour iDEAL deposit approval stats segmented by Web/Mobile channel.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; auto-computes previous UTC hour window; returns one row per bank per hour |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.iDEALDepositApproveRatioForLastHour is the real-time monitoring companion to `Billing.iDEALDepositApproveRatio`. It requires no parameters and automatically calculates statistics for the most recently completed UTC hour, enabling operational dashboards or alerting systems to poll this procedure on a schedule to detect sudden drops in iDEAL approval rates.

Key differences from the date-range version:
- **No parameters**: Window is auto-computed from GETUTCDATE() rounded to the nearest whole hour
- **Hourly granularity**: Includes an `[Hour]` column (formatted as `H:00:00 - H+1:00:00`)
- **Simpler output**: No iOS/Android platform breakdown (Web + Mobile only)
- **No UNION totals row**: No 'SUM FOR ALL BANKS:' summary (not disabled like in the parent - simply not present)
- **Same core filters**: FundingTypeID=34 (iDEAL), PlayerLevelID<>4 (no test accounts), same session->channel resolution

Window calculation:
- `@EndDate = DATEADD(HOUR, DATEDIFF(HOUR, '20200601', GETUTCDATE()), '20200601')` - truncates GETUTCDATE() to the start of the current UTC hour
- `@StartDate = DATEADD(HOUR, -1, @EndDate)` - start of the previous hour
- Example: if GETUTCDATE() = 14:35 -> @EndDate = 14:00:00, @StartDate = 13:00:00

---

## 2. Business Logic

### 2.1 Auto-Computed Previous Hour Window

**What**: Computes the last complete UTC hour window without any caller input.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `GETUTCDATE()`

**Rules**:
- `@EndDate = DATEADD(HOUR, DATEDIFF(HOUR, '20200601', GETUTCDATE()), '20200601')` - floor to current hour start
- `@StartDate = DATEADD(HOUR, -1, @EndDate)` - one hour before
- '20200601' is an arbitrary epoch anchor; DATEDIFF counts hours since that date then re-adds them, effectively truncating to the hour
- Window covers: [@StartDate, @EndDate] - the hour BEFORE the current one (last complete hour)

### 2.2 Hour Label Column

**What**: Adds a human-readable hour range label to each row.

**Columns/Parameters Involved**: `[Hour]`, `PaymentDate`

**Rules**:
- `CONCAT(DATEPART(HOUR, PaymentDate), ':00:00 - ', DATEPART(HOUR, PaymentDate) + 1, ':00:00')` AS `[Hour]`
- Example: deposits at 13:xx -> Hour = '13:00:00 - 14:00:00'
- GROUP BY includes [Hour] for potential multi-hour result sets (though window is exactly 1 hour, both start and end of window timestamps could span midnight)

### 2.3 Channel Segmentation (Web + Mobile Only)

**What**: Simpler two-channel breakdown vs the date-range version's four-channel breakdown.

**Rules**:
- 'retoro' -> Web
- 'retoroios' / 'retoroandroid' -> Mobile (combined)
- No separate iOS / Android platform breakdown
- No Dictionary.ApplicationIdentifier or Dictionary.Platform JOINs (not needed without platform split)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | BankName | NVARCHAR(150) | YES | - | CODE-BACKED | iDEAL issuing bank name from PaymentData XML. One row per bank per hour. |
| - | PaymentDate | DATE | NO | - | CODE-BACKED | Date of the transactions (CAST of PaymentDate to DATE). |
| - | Hour | VARCHAR | NO | - | CODE-BACKED | Hour range label: 'H:00:00 - H+1:00:00'. Identifies the specific hour within the day. |
| - | TotalApproved | DECIMAL | NO | 0 | CODE-BACKED | USD-equivalent sum of approved deposits in this hour. |
| - | TotalApprovedFromWeb | DECIMAL | NO | 0 | CODE-BACKED | Approved amount from Web channel ('retoro'). |
| - | TotalApprovedFromMobile | DECIMAL | NO | 0 | CODE-BACKED | Approved amount from Mobile channel ('retoroios' + 'retoroandroid'). |
| - | AllTransactionsCountTotal / Web / Mobile | INT | NO | - | CODE-BACKED | Total transaction counts by channel. |
| - | ApprovedTransactionsCountTotal / Web / Mobile | INT | NO | - | CODE-BACKED | Approved transaction counts by channel. |
| - | DeclinedTransactionsCountTotal / Web / Mobile | INT | NO | - | CODE-BACKED | Declined transaction counts by channel. |
| - | CountFTD | INT | NO | - | CODE-BACKED | Count of approved FTD deposits in this hour. |
| - | TotalFTD | DECIMAL | NO | 0 | CODE-BACKED | USD-equivalent sum of approved FTD amounts. |
| - | TotalFTDFromMobile | DECIMAL | YES | - | CODE-BACKED | FTD amount from Mobile channel. |
| - | TotalFTDFromWeb | DECIMAL | YES | - | CODE-BACKED | FTD amount from Web channel. |
| - | ApproveRatioTotal | DECIMAL(10,2) | NO | 0 | CODE-BACKED | Approved/Total ratio for all channels. 0 if no transactions. |
| - | ApproveRatioWeb | DECIMAL(10,2) | NO | 0 | CODE-BACKED | Approve ratio for Web channel. |
| - | ApproveRatioMobile | DECIMAL(10,2) | NO | 0 | CODE-BACKED | Approve ratio for Mobile channel. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID=34, amount metrics | Billing.Deposit | SELECT | iDEAL deposits in auto-computed last hour window |
| CID, PlayerLevelID | Customer.CustomerStatic | INNER JOIN | Test account exclusion (PlayerLevelID<>4) |
| FundingID, FundingTypeID | Billing.Funding | INNER JOIN | iDEAL filter |
| SessionID | STS_AuditLoginHistoryActive | OUTER APPLY | Session to ApplicationIdentifierFrom for channel detection |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| iDEAL monitoring dashboard / alert system | (no params) | EXEC | Real-time hourly approval rate monitoring |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.iDEALDepositApproveRatioForLastHour (procedure)
+-- Billing.Deposit (table)
+-- Customer.CustomerStatic (table) [PlayerLevelID<>4]
+-- Billing.Funding (table) [FundingTypeID=34]
+-- STS_AuditLoginHistoryActive (table) [session->app identifier]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source; last UTC hour, FundingTypeID=34 |
| Customer.CustomerStatic | Table | PlayerLevelID<>4 filter |
| Billing.Funding | Table | FundingTypeID=34 (iDEAL) filter |
| STS_AuditLoginHistoryActive | Table | OUTER APPLY for ApplicationIdentifierFrom (channel) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| iDEAL monitoring system | External | Hourly polling for real-time approval rate alerting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UTC-based window | Design | Uses GETUTCDATE() consistently with PaymentDate UTC storage |
| '20200601' epoch anchor | Design | Arbitrary fixed date used as DATEDIFF anchor for hour truncation; functionally correct |
| No parameters | Usability | Cannot adjust window size; always exactly 1 hour back |
| NOLOCK on Deposit only | Concurrency | Same as parent procedure; CustomerStatic and Funding use default isolation |

---

## 8. Sample Queries

### 8.1 Run last-hour iDEAL approval rate check

```sql
EXEC [Billing].[iDEALDepositApproveRatioForLastHour]
-- Returns: per-bank per-hour stats for the previous complete UTC hour
-- No parameters needed
```

### 8.2 Verify the time window being used

```sql
DECLARE @EndDate DATETIME = DATEADD(HOUR, DATEDIFF(HOUR, '20200601', GETUTCDATE()), '20200601')
DECLARE @StartDate DATETIME = DATEADD(HOUR, -1, @EndDate)
SELECT @StartDate AS WindowStart, @EndDate AS WindowEnd
```

---

## 9. Atlassian Knowledge Sources

No direct Atlassian sources found. Related to Billing.iDEALDepositApproveRatio (same business context).

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.iDEALDepositApproveRatioForLastHour | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.iDEALDepositApproveRatioForLastHour.sql*
