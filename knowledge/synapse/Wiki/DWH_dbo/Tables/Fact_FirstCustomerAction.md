# DWH_dbo.Fact_FirstCustomerAction

> Records the first time each customer performed each type of action on the platform — first deposit, first trade, first withdrawal, etc. — enabling funnel analysis and customer lifecycle milestone tracking.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Fact — milestone/snapshot) |
| **Row Count** | Millions (one row per GCID × ActionTypeID, growing as new customers act) |
| **Production Source** | DWH_dbo.Fact_CustomerAction (DWH-internal derivation) |
| **Refresh** | Daily incremental — DELETE yesterday + re-MERGE from Fact_CustomerAction |
| | |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **Synapse NCI** | IX_Fact_FirstCustomerAction_ActionTypeID (DateID, ActionTypeID, FirstEver) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Fact_FirstCustomerAction` captures the milestone moment when a customer performs each type of action for the first time. While `Fact_CustomerAction` logs every action event, this table filters down to only the **first occurrence** per customer per action type. It answers:

- "When did this customer make their first deposit?" (ActionTypeID for deposit)
- "When was their first trade?" (ActionTypeID for trade)
- "What was the funnel conversion path — registration → first deposit → first trade?"

The table enables:
- **Customer funnel analysis** — time between registration and first deposit (FTD), first trade, etc.
- **Cohort analysis** — grouping customers by the date of their first key action
- **Marketing attribution** — linking first actions to acquisition campaigns via CampaignID
- **Lifecycle milestones** — tracking which customers have completed key activation steps

### FirstEver flag

The `FirstEver` column distinguishes:
- **FirstEver = 1**: This is the absolute first time this customer performed this ActionTypeID. One row per (GCID, ActionTypeID).
- **FirstEver = 0**: A unique event (by HistoryID) captured via a secondary MERGE. These represent "first occurrences" at a more granular level — first with a specific instrument, first from a specific platform, etc.

---

## 2. Business Logic

### 2.1 Two-Stage MERGE Pattern

**What**: The SP uses two sequential MERGE operations to capture "firsts" at different granularity levels.

**MERGE 1 — First per Action Type**:
```
Source: Fact_CustomerAction WHERE DateID = @dateid
        → Deduplicated by HistoryID (keep first by Occurred, PositionID, SessionID)
        → Ranked by (ActionTypeID, GCID) → rn2 = row_number
        
MERGE INTO Fact_FirstCustomerAction ON ActionTypeID = ActionTypeID AND GCID = GCID
WHEN NOT MATCHED AND rn2 = 1 → INSERT with FirstEver = 1
```

**MERGE 2 — First per HistoryID**:
```
MERGE INTO Fact_FirstCustomerAction ON HistoryID = HistoryID
WHEN NOT MATCHED → INSERT with FirstEver = 0
```

### 2.2 Daily Re-Processing

**What**: The orchestrator SP deletes and re-processes yesterday's data.

```
DELETE FROM Fact_FirstCustomerAction WHERE FirstOccurred >= @Yesterday
EXEC SP_Fact_FirstCustomerAction @Yesterday
```

This ensures idempotency — running for the same date twice produces the same result.

### 2.3 Default Values

Many FK columns default to 0 (not NULL), indicating "not applicable" rather than "unknown":
InstrumentID, PositionID, CampaignID, BonusTypeID, FundingTypeID, LoginID, MirrorID, WithdrawID, CaseID, CompensationReasonID, WithdrawPaymentID.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH(RealCID) with a CLUSTERED INDEX on RealCID, enabling efficient customer-level lookups. A non-clustered index on (DateID, ActionTypeID, FirstEver) supports date-range and action-type filtered queries.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's first deposit date | `WHERE GCID = @gcid AND ActionTypeID = @depositActionType AND FirstEver = 1` |
| All first milestones for a customer | `WHERE GCID = @gcid AND FirstEver = 1 ORDER BY FirstOccurred` |
| Daily first-deposit cohort | `WHERE ActionTypeID = @depositType AND FirstEver = 1 AND DateID = @dt` |
| Time-to-first-trade after registration | JOIN with customer registration date, filter FirstEver = 1 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON GCID = GCID | Customer demographics |
| DWH_dbo.Dim_ActionType | ON ActionTypeID = ActionTypeID | Action type description |
| DWH_dbo.Dim_Instrument | ON InstrumentID = InstrumentID | Instrument of first trade |
| DWH_dbo.Dim_Campaign | ON CampaignID = CampaignID | Attribution campaign |
| DWH_dbo.Dim_Date | ON DateID = DateID | Calendar attributes |
| DWH_dbo.Fact_CustomerAction | ON HistoryID = HistoryID | Full event details |

### 3.4 Gotchas

- **0 vs NULL**: Most FK columns use 0 (not NULL) for "not applicable". JOIN with `WHERE InstrumentID > 0` to exclude irrelevant lookups
- **FirstEver flag**: For standard funnel analysis, always filter `FirstEver = 1`. FirstEver = 0 rows are supplementary granular events
- **Re-processing window**: Yesterday's data is DELETE+re-MERGEd daily. Querying during ETL may show gaps
- **RealCID distribution**: HASH(RealCID) — JOINs on GCID may require data movement. Use RealCID when possible for co-located JOINs

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Global Customer ID — unique cross-platform identifier. (Tier 2 — Fact_CustomerAction passthrough) |
| 2 | RealCID | int | NO | Real-money account Customer ID. Distribution key and clustered index. (Tier 2 — Fact_CustomerAction passthrough) |
| 3 | DemoCID | int | NO | Demo account Customer ID. (Tier 2 — Fact_CustomerAction passthrough) |
| 4 | FirstOccurred | datetime | NO | Timestamp when this action type was first performed by the customer. Mapped from Fact_CustomerAction.Occurred. (Tier 2 — SP_Fact_FirstCustomerAction) |
| 5 | IPNumber | bigint | NO | IP address (as integer) from which the first action was performed. (Tier 2 — Fact_CustomerAction passthrough) |
| 6 | IsReal | tinyint | NO | Whether the first action was on a Real (1) or Demo (0) account. (Tier 2 — Fact_CustomerAction passthrough) |
| 7 | ActionTypeID | smallint | NO | Type of customer action (e.g., deposit, trade, withdrawal). JOINs to Dim_ActionType. Part of the business key with GCID. (Tier 2 — SP_Fact_FirstCustomerAction) |
| 8 | PlatformTypeID | smallint | NO | Platform used for the first action (web, iOS, Android). JOINs to Dim_PlatformType. (Tier 2 — Fact_CustomerAction passthrough) |
| 9 | InstrumentID | int | NO | Instrument involved in the first action (for trades). Default 0 = not applicable. JOINs to Dim_Instrument. (Tier 2 — Fact_CustomerAction passthrough) |
| 10 | Amount | decimal(11,2) | NO | Monetary amount of the first action (e.g., first deposit amount). (Tier 2 — Fact_CustomerAction passthrough) |
| 11 | PositionID | bigint | NO | Position ID for trade-related first actions. Default 0 = not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 12 | CampaignID | int | NO | Marketing campaign active at time of first action. Default 0 = no campaign. JOINs to Dim_Campaign. (Tier 2 — Fact_CustomerAction passthrough) |
| 13 | BonusTypeID | smallint | NO | Bonus type associated with the first action. Default 0 = none. JOINs to Dim_BonusType. (Tier 2 — Fact_CustomerAction passthrough) |
| 14 | FundingTypeID | smallint | NO | Funding method for the first deposit/withdrawal. Default 0 = not applicable. JOINs to Dim_FundingType. (Tier 2 — Fact_CustomerAction passthrough) |
| 15 | LoginID | int | NO | Login session ID for the first action. Default 0 = not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 16 | MirrorID | int | NO | Copy trading mirror ID if the first action was a copy trade. Default 0 = not a copy trade. (Tier 2 — Fact_CustomerAction passthrough) |
| 17 | WithdrawID | int | NO | Withdrawal transaction ID for first withdrawal actions. Default 0 = not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 18 | PostID | uniqueidentifier | YES | Social feed post ID if the first action was a social interaction. NULL if not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 19 | CaseID | int | NO | Support case ID if the first action was case-related. Default 0 = not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 20 | UpdateDate | datetime | NO | ETL timestamp — GETDATE() during MERGE execution. (Tier 2 — SP_Fact_FirstCustomerAction) |
| 21 | UpdateDateID | int | YES | Date portion of UpdateDate in YYYYMMDD format (ETL lineage key; BI Dictionary references first-deposit and milestone dates in DWH). (Tier 4 — Confluence, BI Dictionary) |
| 22 | DateID | int | NO | Date of the first action in YYYYMMDD format. JOINs to Dim_Date. (Tier 2 — Fact_CustomerAction passthrough) |
| 23 | TimeID | int | NO | Time of the first action in HHMMSS format. JOINs to Dim_Time. (Tier 2 — Fact_CustomerAction passthrough) |
| 24 | CompensationReasonID | int | NO | Reason for compensation if the first action was a compensation event. Default 0 = not applicable. JOINs to Dim_CompensationReason. (Tier 2 — Fact_CustomerAction passthrough) |
| 25 | WithdrawPaymentID | int | NO | Payment method ID for first withdrawal. Default 0 = not applicable. (Tier 2 — Fact_CustomerAction passthrough) |
| 26 | DepositID | int | YES | Deposit transaction ID for first deposit actions. NULL if not a deposit. (Tier 2 — Fact_CustomerAction passthrough) |
| 27 | HistoryID | decimal(38,0) | YES | Unique history event identifier from production. Links back to Fact_CustomerAction.HistoryID. Used as secondary MERGE key. (Tier 2 — SP_Fact_FirstCustomerAction) |
| 28 | FirstEver | int | YES | 1 = absolute first time this GCID performed this ActionTypeID. 0 = unique HistoryID event captured via secondary MERGE. (Tier 2 — SP_Fact_FirstCustomerAction) |

---

## 5. Lineage

### 5.1 Source Pipeline

```
Production → Data Lake → DWH_staging → SP_Fact_CustomerAction_DL_To_Synapse → Fact_CustomerAction
                                                                                    │
                                        SP_Fact_FirstCustomerAction_DL_To_Synapse ──┘
                                            │
                                            └─ SP_Fact_FirstCustomerAction (MERGE ×2)
                                                → Fact_FirstCustomerAction
```

### 5.2 Column Mapping

All columns except `FirstOccurred`, `UpdateDate`, `UpdateDateID`, and `FirstEver` are direct passthroughs from `Fact_CustomerAction`. `FirstOccurred` maps to `Fact_CustomerAction.Occurred`.

---

## 6. Relationships

### 6.1 References To (this table points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID, RealCID, DemoCID | DWH_dbo.Dim_Customer | Customer who performed the action |
| ActionTypeID | DWH_dbo.Dim_ActionType | Type of action |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument (for trades) |
| CampaignID | DWH_dbo.Dim_Campaign | Marketing campaign |
| PlatformTypeID | DWH_dbo.Dim_PlatformType | Platform used |
| BonusTypeID | DWH_dbo.Dim_BonusType | Bonus type |
| FundingTypeID | DWH_dbo.Dim_FundingType | Funding method |
| CompensationReasonID | DWH_dbo.Dim_CompensationReason | Compensation reason |
| DateID | DWH_dbo.Dim_Date | Calendar date |
| HistoryID | DWH_dbo.Fact_CustomerAction | Source event |

### 6.2 Referenced By

No known downstream consumers — this is a terminal analytical table used for ad-hoc funnel queries.

---

## 7. Sample Queries

### 7.1 Time to first deposit after registration

```sql
SELECT
    f.GCID,
    c.RegistrationDateID,
    f.DateID AS FirstDepositDateID,
    DATEDIFF(DAY,
        CAST(CAST(c.RegistrationDateID AS VARCHAR) AS DATE),
        CAST(CAST(f.DateID AS VARCHAR) AS DATE)
    ) AS DaysToFirstDeposit
FROM DWH_dbo.Fact_FirstCustomerAction f
JOIN DWH_dbo.Dim_Customer c ON f.GCID = c.GCID
WHERE f.ActionTypeID = @depositActionTypeID
  AND f.FirstEver = 1
  AND f.DateID >= 20260101;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862/BI+Dictionary) | Confluence | DWH usage: first deposit date, first login, customer actions — aligns with “first occurrence” analytics. |
| [Unified FTD Event & API](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/12815073330/Unified+FTD+Event+API) | Confluence | First-time deposit API (`/customers/{gcid}/first-time-deposit`) — parallel concept to first-deposit milestones. |
| [Minimum / Maximum Deposit limitations](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11706499284/Minimum+Maximum+Deposit+limitations) | Confluence | **FTD** (first-time deposit) business rules. |
| [Global Deposit/FTD - Integrating with new account](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13558218769/Global+Deposit+FTD+-+Integrating+with+new+account) | Confluence | Unified FTD metrics and API paths in payments. |

---

*Generated: 2026-03-19 | Quality: 7.7/10 (★★★★☆) | Phases: 7/14 (P2,P3 skipped — Synapse MCP unavailable)*
*Tiers: 0 T1, 27 T2, 0 T3, 0 T4 [UNVERIFIED], 1 T4 — Confluence, 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 8/10*
*Object: DWH_dbo.Fact_FirstCustomerAction | Type: Table | Production Source: Fact_CustomerAction (DWH-internal)*
