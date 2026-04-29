# BI_DB_dbo.BI_DB_ReverseCoReport

> 41.7K-row retention analytics table tracking high-value cashout cancellations (>= $5,000) and subsequent customer behavior. Records each cancelled cashout event with customer context (desk, country, manager) and follow-up metrics (did the customer cashout again within 30 days?). Sourced from Fact_CustomerAction (ActionTypeID=37/8) + Billing_Withdraw + Salesforce contacts. Data spans 2017 to November 2024. Refreshed daily via SP_ReverseCO_Report.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction + BI_DB_dbo.External_etoro_Billing_Withdraw via SP_ReverseCO_Report |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE+INSERT by CoCanceledDate + UPDATE for 30-day metrics |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC); NCI on CoCanceledDate |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table supports **retention team analytics** by capturing every cancelled cashout request above $5,000 and tracking what happens next. The business question it answers: "When a customer cancels a large withdrawal, do they eventually cash out anyway? Was there AM (Account Manager) contact before the cancellation?"

Each row represents one **cancelled cashout event** (ActionTypeID=37 in Fact_CustomerAction). A single customer can have multiple rows if they cancel multiple large cashouts over time.

**Two-phase ETL design**:
1. **INSERT phase** (same day): Captures the cancelled event with request details, customer context, and whether the AM contacted the customer between the original request and the cancellation.
2. **UPDATE phase** (ongoing): Fills in follow-up metrics — first subsequent cashout date, count of cashouts within 30 days, and total amount. These fields start as NULL and are populated as subsequent cashout events (ActionTypeID=8) occur.

**Key observations from data**:
- 89% of customers who cancel a large cashout still cash out within 30 days
- Only 3% had AM contact (phone call or email) between request and cancellation
- The most common stated reason is "Fulfill other financial commitments" (44%)
- Data appears to have stopped flowing after November 2024

---

## 2. Business Logic

### 2.1 Cashout Cancellation Detection

**What**: Identifies high-value cancelled withdrawals.
**Columns Involved**: CID, CoRequestAmount, CoCanceledDate
**Rules**:
- ActionTypeID=37 in Fact_CustomerAction = cashout cancellation event
- Amount >= $5,000 (hardcoded threshold @MinCoAmount)
- CoCanceledDate = Fact_CustomerAction.Occurred (when the cancel action happened)
- CoRequestDate = Billing_Withdraw.RequestDate (when the original request was made)

### 2.2 Account Manager Context

**What**: Who was the assigned AM at the time of cancellation?
**Columns Involved**: AccountManagerID, Manager
**Rules**:
- Joined via Fact_SnapshotCustomer using Dim_Range (DateRangeID) to find the snapshot valid on the cancellation date
- Manager = FirstName + ' ' + LastName from Dim_Manager

### 2.3 Pre-Cancellation Contact Detection

**What**: Was the customer contacted between the request and cancellation?
**Columns Involved**: ContactedBeforCancel
**Rules**:
- Checks BI_DB_UsageTracking_SF for Salesforce activities
- Only counts Phone_Call_Succeed__c or Completed_Contact_Email__c
- Must be by the SAME AccountManagerID
- Must fall between CoRequestDate and CoCanceledDate
- 1 = contacted, 0 = not contacted

### 2.4 Post-Cancellation Follow-Up (UPDATE Phase)

**What**: Did the customer eventually cash out within 30 days?
**Columns Involved**: FirstCoAfterCancelDate, Count30DaysCO, Total30DaysCoAmount
**Rules**:
- Looks at Fact_CustomerAction WHERE ActionTypeID=8 (actual cashout)
- Occurred > CoCanceledDate AND within 30 days
- FirstCoAfterCancelDate = MIN(Occurred) of subsequent cashouts
- Count30DaysCO = COUNT DISTINCT WithdrawIDs
- Total30DaysCoAmount = SUM(Amount)
- Updated daily; NULL until 30 days have passed or a cashout occurs

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on CID. The NCI on CoCanceledDate supports the daily DELETE (by date) pattern. For customer-level analysis, filter by CID using the clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Retention success rate | `SUM(CASE WHEN FirstCoAfterCancelDate IS NULL THEN 1 END) / COUNT(*)` — customers who DIDN'T cashout after cancel |
| AM contact effectiveness | Compare Count30DaysCO WHERE ContactedBeforCancel=1 vs 0 |
| Monthly cancellation volume | `GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, CoCanceledDate), 0)` |
| Large churners | `WHERE Total30DaysCoAmount > CoRequestAmount` — cashed out more than they originally wanted |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Full customer profile |
| DWH_dbo.Dim_ActionType | ActionTypeID (if checking sub-types) | Action type name |

### 3.4 Gotchas

- **Column name typo**: `ContactedBeforCancel` (missing 'e' in "Before") — do not search for `ContactedBeforeCancel`
- **NULL follow-up columns**: NULL means either (a) 30 days haven't passed yet, or (b) customer hasn't cashed out. Check CoCanceledDate to distinguish.
- **WITH (NOLOCK)** in SP: Syntactically unnecessary for Synapse but present in legacy code. No functional impact.
- **Data appears inactive**: Last CoCanceledDate is 2024-11-22. SP may be disabled or the ActionTypeID=37 source has stopped.
- **Multiple rows per CID**: A customer can appear many times if they cancel multiple large cashouts.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning | Source |
|------|---------|--------|
| Tier 1 | Verified from upstream wiki (production DB documentation) | Upstream wiki verbatim |
| Tier 2 | Derived from SP code analysis | SP source code |
| Tier 3 | Inferred from live data / external lookup | Ext_Dim_Country |
| Tier 5 | ETL infrastructure / metadata | System convention |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Real-account Customer ID. HASH distribution key in source. References Dim_Customer.RealCID. Each customer has one real CID. Renamed from RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Desk | varchar(50) | YES | Sales/support desk assignment for this country. Loaded from Ext_Dim_Country_Region_Desk via MarketingRegionID join. Examples: "ROW", "Other EU", "Arabic", "USA". NULL if no desk mapping for this marketing region. Passthrough from Dim_Country. (Tier 3 — Ext_Dim_Country_Region_Desk) |
| 3 | CoRequestDate | datetime | NO | UTC timestamp when the original cashout request was submitted by the customer (from Billing.Withdraw.RequestDate). (Tier 2 — SP_ReverseCO_Report) |
| 4 | Country | varchar(50) | YES | Country of residence name. Resolved from Dim_Country.Name via CountryID. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates, Dim_Country) |
| 5 | Region | varchar(50) | YES | Geographic region name. Resolved from Dim_Country.Region via CountryID. Values: North Europe, French, Eastern Europe, Other EU, LATAM, etc. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates, Dim_Country) |
| 6 | Manager | varchar(50) | YES | Account manager full name (FirstName + ' ' + LastName from Dim_Manager). Resolved via Fact_SnapshotCustomer at the cancellation date. (Tier 2 — SP_ReverseCO_Report) |
| 7 | AccountManagerID | int | YES | Account manager ID from Fact_SnapshotCustomer. The AM assigned to the customer at the time of cashout cancellation (via Dim_Range date bracketing). (Tier 2 — SP_ReverseCO_Report) |
| 8 | CoRequestAmount | money | NO | Amount (USD) of the cancelled cashout request. Must be >= $5,000 (SP filter @MinCoAmount). From Fact_CustomerAction.Amount. (Tier 1 — Trade.PositionTbl) |
| 9 | CoCanceledDate | datetime | NO | UTC timestamp when the customer cancelled the cashout request. From Fact_CustomerAction.Occurred where ActionTypeID=37. (Tier 1 — source-dependent) |
| 10 | ClientWithdrawReason | varchar(50) | YES | Customer-selected reason for the original withdrawal. 7 values: Fulfill other financial commitments, None of the reasons above, Withdrawing profits, I Have not achieved my trading goals, This platform is not for me, I Would like to close my account, Moving to a competitor. From Dim_ClientWithdrawReason. (Tier 2 — SP_ReverseCO_Report) |
| 11 | ClientWithdrawReasonComment | varchar(250) | YES | Free-text comment provided by the customer on the withdrawal request. From External_etoro_Billing_Withdraw.ClientWithdrawReasonComment. Often empty. (Tier 2 — SP_ReverseCO_Report) |
| 12 | FirstCoAfterCancelDate | datetime | YES | UTC timestamp of the first actual cashout (ActionTypeID=8) after the cancellation within 30 days. NULL if no subsequent cashout within 30 days or if 30-day window hasn't elapsed. Populated by UPDATE phase. (Tier 2 — SP_ReverseCO_Report) |
| 13 | Count30DaysCO | int | YES | Number of distinct cashout events (ActionTypeID=8) within 30 days after the cancellation. NULL if no subsequent cashouts. Populated by UPDATE phase. (Tier 2 — SP_ReverseCO_Report) |
| 14 | Total30DaysCoAmount | money | YES | Total amount of all cashouts (ActionTypeID=8) within 30 days after the cancellation. NULL if no subsequent cashouts. Populated by UPDATE phase. (Tier 2 — SP_ReverseCO_Report) |
| 15 | ContactedBeforCancel | int | YES | 1 = AM contacted the customer (phone call or email via Salesforce) between CoRequestDate and CoCanceledDate. 0 = no contact. From BI_DB_UsageTracking_SF. Note: column name has typo ("Befor" vs "Before"). (Tier 2 — SP_ReverseCO_Report) |
| 16 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted or updated by the pipeline (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-----------------|---------------|-----------|
| CID | DWH_dbo.Fact_CustomerAction | RealCID | Rename |
| Desk | DWH_dbo.Dim_Country | Desk | Dim-lookup passthrough |
| CoRequestDate | External_etoro_Billing_Withdraw | RequestDate | Rename |
| Country | BI_DB_dbo.BI_DB_CIDFirstDates | Country | Passthrough |
| Region | BI_DB_dbo.BI_DB_CIDFirstDates | Region | Passthrough |
| Manager | DWH_dbo.Dim_Manager | FirstName + LastName | Concatenation |
| AccountManagerID | DWH_dbo.Fact_SnapshotCustomer | AccountManagerID | Passthrough (date-ranged) |
| CoRequestAmount | DWH_dbo.Fact_CustomerAction | Amount | Rename |
| CoCanceledDate | DWH_dbo.Fact_CustomerAction | Occurred | Rename (ActionTypeID=37) |
| ClientWithdrawReason | DWH_dbo.Dim_ClientWithdrawReason | ClientWithdrawReasonName | Rename |
| ClientWithdrawReasonComment | External_etoro_Billing_Withdraw | ClientWithdrawReasonComment | Passthrough |
| FirstCoAfterCancelDate | DWH_dbo.Fact_CustomerAction | MIN(Occurred) | Aggregation (ActionTypeID=8, within 30d) |
| Count30DaysCO | DWH_dbo.Fact_CustomerAction | COUNT(DISTINCT WithdrawID) | Aggregation |
| Total30DaysCoAmount | DWH_dbo.Fact_CustomerAction | SUM(Amount) | Aggregation |
| ContactedBeforCancel | BI_DB_dbo.BI_DB_UsageTracking_SF | CreatedDate_SF | MAX(CASE) flag |
| UpdateDate | — | GETDATE() | ETL generated |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (ActionTypeID=37, Amount >= $5K)
  + BI_DB_dbo.External_etoro_Billing_Withdraw (request details)
  + DWH_dbo.Dim_ClientWithdrawReason (reason name)
  + BI_DB_dbo.BI_DB_CIDFirstDates (country, region)
  + DWH_dbo.Dim_Country (desk)
  + DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Manager (AM context)
  + BI_DB_dbo.BI_DB_UsageTracking_SF (Salesforce contact)
    |-- SP_ReverseCO_Report @dd (Daily, Priority 0)
    |-- Phase 1: DELETE+INSERT cancelled COs for @dd
    |-- Phase 2: UPDATE 30-day follow-up metrics for all rows
    v
BI_DB_dbo.BI_DB_ReverseCoReport (41.7K rows, ROUND_ROBIN CI(CID))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension lookup |
| AccountManagerID | DWH_dbo.Dim_Manager.ManagerID | Account manager details |
| Country/Region | BI_DB_dbo.BI_DB_CIDFirstDates | Customer geography |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in SSDT.

---

## 7. Sample Queries

### 7.1 Retention Success Rate by Desk

```sql
SELECT
    Desk,
    COUNT(*) AS TotalCancellations,
    SUM(CASE WHEN FirstCoAfterCancelDate IS NULL AND DATEDIFF(DAY, CoCanceledDate, GETDATE()) > 30 THEN 1 ELSE 0 END) AS Retained,
    CAST(SUM(CASE WHEN FirstCoAfterCancelDate IS NULL AND DATEDIFF(DAY, CoCanceledDate, GETDATE()) > 30 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100 AS RetentionPct
FROM [BI_DB_dbo].[BI_DB_ReverseCoReport]
GROUP BY Desk
ORDER BY RetentionPct DESC
```

### 7.2 AM Contact Effectiveness

```sql
SELECT
    ContactedBeforCancel,
    COUNT(*) AS Events,
    AVG(CAST(Count30DaysCO AS FLOAT)) AS AvgSubsequentCOs,
    AVG(Total30DaysCoAmount) AS AvgSubsequentAmount
FROM [BI_DB_dbo].[BI_DB_ReverseCoReport]
WHERE DATEDIFF(DAY, CoCanceledDate, GETDATE()) > 30
GROUP BY ContactedBeforCancel
```

### 7.3 Monthly Cancellation Trend

```sql
SELECT
    DATEADD(MONTH, DATEDIFF(MONTH, 0, CoCanceledDate), 0) AS Month,
    COUNT(*) AS Cancellations,
    SUM(CoRequestAmount) AS TotalAmount,
    AVG(CoRequestAmount) AS AvgAmount
FROM [BI_DB_dbo].[BI_DB_ReverseCoReport]
GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, CoCanceledDate), 0)
ORDER BY Month DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 3 T1, 11 T2, 1 T3, 0 T4, 1 T5 | Elements: 16/16, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_ReverseCoReport | Type: Table | Production Source: Fact_CustomerAction + Billing_Withdraw*
