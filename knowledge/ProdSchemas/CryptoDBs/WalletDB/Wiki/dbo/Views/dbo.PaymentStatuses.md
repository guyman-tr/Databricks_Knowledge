# dbo.PaymentStatuses

> Monitoring view that returns a single-row summary of recent payment activity counts by status (Initiated, Transmitted, Completed) for the last 24 hours.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base tables: Wallet.Payments, Wallet.PaymentStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view provides an operational health dashboard for the payment processing pipeline. It returns a single row with three columns showing the count of payments in each critical status stage over the last 24 hours: Initiated (PaymentStatusId=4), Transmitted (PaymentStatusId=11), and Completed (PaymentStatusId=9). This enables quick monitoring of whether payments are flowing through the pipeline normally or getting stuck at a stage.

Without this view, operators would need to run manual GROUP BY queries against the payment tables. The view is consumed by `Monitoring.TransmissionFailureSimplex`, which likely compares the Initiated/Transmitted/Completed counts to detect transmission failures (e.g., many initiated but few transmitted = transmission problem).

The view uses a CTE with a 1-day lookback window (`DATEADD(DAY, -1, GETDATE())`) and correlated subqueries to pivot the three status counts into a single row. NOLOCK hints are used on both base tables for monitoring safety.

---

## 2. Business Logic

### 2.1 Payment Pipeline Health Metrics

**What**: Three counts represent the three critical stages of payment processing in the last 24 hours.

**Columns/Parameters Involved**: `Initiated`, `Transmited`, `Completed`

**Rules**:
- Initiated (PaymentStatusId=4): Payments started but not yet sent to the provider
- Transmited (PaymentStatusId=11): Payments sent to the external payment provider (note: column name has a typo "Transmited" vs "Transmitted")
- Completed (PaymentStatusId=9): Payments fully processed and confirmed
- Time window: last 24 hours only (WHERE Occurred >= DATEADD(DAY, -1, GETDATE()))
- NULL values indicate no payments in that status during the window

**Diagram**:
```
Payment flow (last 24h counts):
  Initiated (4) --> Transmited (11) --> Completed (9)
  
Normal: Initiated >= Transmited >= Completed (pipeline flowing)
Alert:  Initiated >> Transmited (transmission failure)
Alert:  Transmited >> Completed (completion stuck)
```

---

## 3. Data Overview

| Initiated | Transmited | Completed | Meaning |
|---|---|---|---|
| NULL | NULL | NULL | No payments processed in the last 24 hours in any of the three monitored statuses |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Initiated | int | YES | - | VERIFIED | Count of payments with PaymentStatusId=4 (Initiated) in the last 24 hours. Source: subquery on the CTE filtering PaymentStatusId=4. NULL when no payments have been initiated. |
| 2 | Transmited | int | YES | - | VERIFIED | Count of payments with PaymentStatusId=11 (Transmitted) in the last 24 hours. Source: subquery filtering PaymentStatusId=11. Note: column name contains a typo ("Transmited" vs "Transmitted"). NULL when no payments have been transmitted. |
| 3 | Completed | int | YES | - | VERIFIED | Count of payments with PaymentStatusId=9 (Completed) in the last 24 hours. Source: subquery filtering PaymentStatusId=9. NULL when no payments have completed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base table) | Wallet.Payments | JOIN | Provides payment records with Occurred timestamp for 24h window filter |
| (base table) | Wallet.PaymentStatuses | JOIN | Provides payment status records with PaymentStatusId for counting |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Monitoring.TransmissionFailureSimplex | - | READER | Reads Initiated, Transmited, Completed counts to detect transmission failures |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.PaymentStatuses (view)
  +-- Wallet.Payments (table)
  +-- Wallet.PaymentStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Payments | Table | JOINed - provides payment records and Occurred timestamp |
| Wallet.PaymentStatuses | Table | JOINed on PaymentId - provides payment status entries with PaymentStatusId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Monitoring.TransmissionFailureSimplex | Stored Procedure | Reads all three columns for pipeline health alerting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed).

### 7.2 Constraints

None. View has no SCHEMABINDING.

---

## 8. Sample Queries

### 8.1 Check current payment pipeline status
```sql
SELECT Initiated, Transmited, Completed
FROM dbo.PaymentStatuses WITH (NOLOCK)
```

### 8.2 Alert condition: transmission failure detection
```sql
SELECT Initiated, Transmited, Completed,
       CASE WHEN ISNULL(Initiated, 0) > 0 AND ISNULL(Transmited, 0) = 0
            THEN 'ALERT: Payments initiated but none transmitted'
            ELSE 'OK' END AS AlertStatus
FROM dbo.PaymentStatuses WITH (NOLOCK)
```

### 8.3 Pipeline flow ratio
```sql
SELECT Initiated, Transmited, Completed,
       CASE WHEN Initiated > 0
            THEN CAST(Transmited AS FLOAT) / Initiated
            ELSE NULL END AS TransmitRatio
FROM dbo.PaymentStatuses WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.PaymentStatuses | Type: View | Source: WalletDB/dbo/Views/dbo.PaymentStatuses.sql*
