# BI_DB_dbo.BI_DB_RAF_Invitees_KPIs

> 710K-row Refer-A-Friend invitee abuse detection table. Each row represents one invitee CID, tracking their registration-to-FTD funnel, RAF compensation payments, trading activity, and computed abuse flags. Rolling 2-month refresh window via DELETE+INSERT WHERE registered >= @Last2months. Writer: SP_RAF_InviteeAbuser (Nitsan Sharabi, 2022-04-07). 14 legacy columns from prior SP versions are no longer populated.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_CIDFirstDates + History_Credit_Range + Fact_CustomerAction + Dim_Position via `SP_RAF_InviteeAbuser` |
| **Refresh** | Rolling 2-month window (DELETE+INSERT WHERE registered >= @Last2months) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Invitee ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |
| **Author** | Nitsan Sharabi (2022-04-07) |
| **Row Count** | ~710,361 (706,902 distinct invitees; registration range 2019-01-01 to 2026-04-11) |

---

## 1. Business Meaning

`BI_DB_RAF_Invitees_KPIs` is the central table for the Refer-A-Friend (RAF) abuse detection program. It tracks every invitee who registered via a referral link (SerialID=11 in CIDFirstDates), along with their deposit behavior, trading activity, RAF compensation payments, and computed abuse flags.

The table answers two core questions:
1. **Is this invitee an abuser?** -- flagged via `isAbuser` when the invitee and inviter share an IP address within 30 days of FTD, or when the invitee cashes out the RAF bonus shortly after receiving it.
2. **Is this invitee eligible for RAF compensation?** -- determined by regulation-specific rules (Global: traded >= $100 in positions; US: FTD >= $100).

RAF payments are $50 (Global) or $30 (US) for both invitee (CompensationReasonID=54) and inviter (CompensationReasonID=53). The table tracks both sides of the payment.

The table contains 14 legacy columns from prior SP versions that are no longer populated by the current SP. These columns may contain historical data for older rows but are NULL for all rows written by the current version. Approximately 314K rows predate the current SP and have NULL abuse flags.

---

## 2. Business Logic

### 2.1 Abuser Detection

**What**: Flags invitees who are likely gaming the RAF program.
**Columns Involved**: `isAbuser`, `MatualIPAdress30Days`, `isCashoutAfterCompensation`
**Rules**:
- `isAbuser` = 1 if `MatualIPAdress30Days` = 1 OR `isCashoutAfterCompensation` = 1
- `MatualIPAdress30Days` = 1 if the invitee and their inviter share any IP address (from login actions, ActionTypeID=14) within 30 days of the invitee's FTD
- `isCashoutAfterCompensation` = 1 if the invitee's total cashout within 7 days after receiving RAF compensation >= `PaymentToInvitee`
- Approximately 57K rows flagged as abusers (8%); mutual IP is the primary abuse signal

### 2.2 Eligibility for Compensation

**What**: Determines whether the invitee qualifies for RAF bonus payment.
**Columns Involved**: `EligibleForCompensation`, `NewTrades`, `FirstDepositAmount`
**Rules**:
- Global regulation: 1 if `NewTrades` (PositionsAmount) >= 100
- US regulation: 1 if `FirstDepositAmount` >= $100
- Approximately 147K rows marked eligible

### 2.3 Payment Amounts

**What**: RAF bonus paid to invitee and inviter.
**Columns Involved**: `PaymentToInvitee`, `PaymentToInviter`
**Rules**:
- PaymentToInvitee: from History_Credit_Range WHERE CompensationReasonID=54, CreditTypeID=6. $50 for Global, $30 for US
- PaymentToInviter: from History_Credit_Range WHERE CompensationReasonID=53, CreditTypeID=6, and invitee CID appears in the Description field. $50 for Global, $30 for US
- Inviter's RegulationID (from Dim_Customer) determines the payment amount tier

### 2.4 FTD Within 30 Days

**What**: Whether the invitee made their first deposit within 30 days of registration.
**Columns Involved**: `isFTD30days`, `FirstDepositDate`, `registered`
**Rules**:
- 1 if `FirstDepositDate` is within 30 days of `registered`
- Approximately 203K rows flagged

### 2.5 Funded Status After 14 Days

**What**: Whether the invitee is still funded 14 days after FTD.
**Columns Involved**: `IsFundedAfter14Days`
**Rules**:
- Reads `IsFunded_New` from `BI_DB_CID_DailyPanel_FullData` for the date 14 days after `FirstDepositDate`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Invitee ASC. No hash distribution key. Joins on Invitee (CID) are efficient due to the clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Abuse rate for recent invitees | `WHERE registered >= DATEADD(MONTH,-2,GETDATE()) AND isAbuser IS NOT NULL` |
| Invitees flagged as abusers | `WHERE isAbuser = 1` |
| Eligible but not yet compensated | `WHERE EligibleForCompensation = 1 AND PaymentToInvitee IS NULL` |
| RAF program cost by regulation | `GROUP BY CASE WHEN PaymentToInvitee = 50 THEN 'Global' ELSE 'US' END` |
| Legacy vs current data | `WHERE isAbuser IS NOT NULL` (current SP rows) vs `WHERE isAbuser IS NULL` (legacy) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `Invitee = RealCID` | Full invitee profile |
| DWH_dbo.Dim_Customer | `Inviter = RealCID` | Full inviter profile |
| BI_DB_dbo.BI_DB_CIDFirstDates | `Invitee = CID` | Extended registration metrics |

### 3.4 Gotchas

- **14 legacy columns**: FunnelName, DesignatedRegulationID, RevenueFromUser, NoOfTotalCashout, FirstPosOpenDate, Cashout_request, Cashout_date, Revenue14days, FTDMeanOfPayment, LastCashoutDate, TradesAmount, TradesAmount_tillRAFbonus, Date_AccTrade100_Invitee, Date_AccTrade100_Inviter are NOT populated by the current SP. Some contain historical data from prior versions; newer rows are NULL
- **314K rows with NULL abuse flags**: These predate the current SP and lack isAbuser, MatualIPAdress30Days, isCashoutAfterCompensation, etc. Always filter `WHERE isAbuser IS NOT NULL` for abuse analysis
- **Column name typo**: `MatualIPAdress30Days` -- "Matual" should be "Mutual" and "Adress" should be "Address". Preserved for backward compatibility
- **Rolling window**: Only rows with `registered >= @Last2months` are refreshed. Older rows are static snapshots from when they were last written
- **NewTrades rename**: Column `NewTrades` was originally named `PositionsAmount` in the SP logic -- it represents SUM of position amounts, not a count of trades

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Invitee | bigint | NO | Invitee CID (RealCID from BI_DB_CIDFirstDates). Clustered index key. (Tier 2 -SP_RAF_InviteeAbuser) |
| 2 | Country | varchar(255) | YES | Country name from BI_DB_CIDFirstDates. (Tier 2 -SP_RAF_InviteeAbuser) |
| 3 | State | varchar(255) | YES | State/province from BI_DB_CIDFirstDates. (Tier 2 -SP_RAF_InviteeAbuser) |
| 4 | Inviter | bigint | YES | Inviter CID (ReferralID from BI_DB_CIDFirstDates). (Tier 2 -SP_RAF_InviteeAbuser) |
| 5 | registered | datetime | YES | Registration date from BI_DB_CIDFirstDates. Used as refresh boundary (>= @Last2months). (Tier 2 -SP_RAF_InviteeAbuser) |
| 6 | FirstDepositDate | datetime | YES | First deposit date from BI_DB_CIDFirstDates. Anchor for 30-day trading window and isFTD30days calculation. (Tier 2 -SP_RAF_InviteeAbuser) |
| 7 | FirstDepositAmount | money | YES | First deposit amount from BI_DB_CIDFirstDates. Used in US eligibility check (>= $100). (Tier 2 -SP_RAF_InviteeAbuser) |
| 8 | FunnelName | varchar(255) | YES | LEGACY -- not populated by current SP. Registration funnel name from older SP version. (Tier 4 -legacy column) |
| 9 | DesignatedRegulationID | int | YES | LEGACY -- not populated by current SP. Regulation ID from older SP version. (Tier 4 -legacy column) |
| 10 | PaymentToInvitee | money | YES | RAF bonus paid to invitee: $50 Global, $30 US. From History_Credit_Range WHERE CompensationReasonID=54, CreditTypeID=6. NULL if no compensation. (Tier 2 -SP_RAF_InviteeAbuser) |
| 11 | PaymentToInviter | money | YES | RAF bonus paid to inviter: $50 Global, $30 US. From History_Credit_Range WHERE CompensationReasonID=53, CreditTypeID=6, invitee CID in Description. NULL if no matching compensation. (Tier 2 -SP_RAF_InviteeAbuser) |
| 12 | RevenueFromUser | decimal(18,0) | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 13 | NoOfTotalDeposits | int | YES | Total deposit count since registration. From Fact_CustomerAction ActionTypeID=7. (Tier 2 -SP_RAF_InviteeAbuser) |
| 14 | TotalDepositAmount | money | YES | Total deposit amount since registration. From Fact_CustomerAction ActionTypeID=7. (Tier 2 -SP_RAF_InviteeAbuser) |
| 15 | UpdateDate | datetime | YES | GETDATE() at SP execution. (Tier 5 -ETL metadata) |
| 16 | NoOfTotalCashout | int | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 17 | TotalCashoutAmount | money | YES | Total cashout amount since registration. From Fact_CustomerAction ActionTypeID=8. (Tier 2 -SP_RAF_InviteeAbuser) |
| 18 | FirstPosOpenDate | datetime | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 19 | Compensation_date | datetime | YES | Latest RAF compensation date for invitee (CompensationReasonID=54). From History_Credit_Range. (Tier 2 -SP_RAF_InviteeAbuser) |
| 20 | Cashout_request | datetime | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 21 | Cashout_date | datetime | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 22 | Revenue14days | decimal(38,2) | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 23 | NewTrades | int | YES | Total trading amount (SUM of Dim_Position.Amount) within 30 days of FTD. Renamed from PositionsAmount in SP logic. Used in Global eligibility check (>= 100). (Tier 2 -SP_RAF_InviteeAbuser) |
| 24 | FTDMeanOfPayment | nvarchar(max) | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 25 | LastCashoutDate | datetime | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 26 | MatualIPAdress30Days | int | YES | Mutual IP address flag. 1 if invitee and inviter shared an IP (login ActionTypeID=14) within 30 days of FTD. Column name has typo ("Matual" for "Mutual", "Adress" for "Address"). (Tier 2 -SP_RAF_InviteeAbuser) |
| 27 | TradesAmount | decimal(38,2) | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 28 | TradesAmount_tillRAFbonus | decimal(38,2) | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 29 | Date_AccTrade100_Invitee | date | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 30 | Date_AccTrade100_Inviter | date | YES | LEGACY -- not populated by current SP. (Tier 4 -legacy column) |
| 31 | NoOfTotalCashout14DaysFromFTD | int | YES | Count of cashouts within 14 days of FTD. From Fact_CustomerAction ActionTypeID=8. (Tier 2 -SP_RAF_InviteeAbuser) |
| 32 | TotalCashoutAmount14DaysFromFTD | money | YES | Cashout amount within 14 days of FTD. From Fact_CustomerAction ActionTypeID=8. (Tier 2 -SP_RAF_InviteeAbuser) |
| 33 | IsFundedAfter14Days | int | YES | IsFunded_New flag from BI_DB_CID_DailyPanel_FullData 14 days after FTD. (Tier 2 -SP_RAF_InviteeAbuser) |
| 34 | TotalCashoutAmountAfterCompensation | decimal(11,2) | YES | Total cashout within 7 days after RAF compensation date. From Fact_CustomerAction ActionTypeID=8. (Tier 2 -SP_RAF_InviteeAbuser) |
| 35 | EligibleForCompensation | int | YES | 1 if (Global regulation AND NewTrades >= 100) OR (US regulation AND FirstDepositAmount >= 100). (Tier 2 -SP_RAF_InviteeAbuser) |
| 36 | isCashoutAfterCompensation | int | YES | 1 if TotalCashoutAmountAfterCompensation >= PaymentToInvitee. Abuse signal. (Tier 2 -SP_RAF_InviteeAbuser) |
| 37 | isFTD30days | int | YES | 1 if FirstDepositDate within 30 days of registered. (Tier 2 -SP_RAF_InviteeAbuser) |
| 38 | isAbuser | int | YES | Final abuse flag: 1 if MatualIPAdress30Days=1 OR isCashoutAfterCompensation=1. NULL for legacy rows predating current SP. (Tier 2 -SP_RAF_InviteeAbuser) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Invitee | BI_DB_CIDFirstDates | RealCID | passthrough (PK, SerialID=11 filter) |
| Country, State | BI_DB_CIDFirstDates | Country, State | passthrough |
| Inviter | BI_DB_CIDFirstDates | ReferralID | passthrough |
| registered, FirstDepositDate, FirstDepositAmount | BI_DB_CIDFirstDates | same-name columns | passthrough |
| PaymentToInvitee | History_Credit_Range | Payment | CompensationReasonID=54 |
| PaymentToInviter | History_Credit_Range | Payment | CompensationReasonID=53, invitee CID in Description |
| NewTrades | Dim_Position | SUM(Amount) | 30-day window from FTD |
| MatualIPAdress30Days | Fact_CustomerAction | IP address match | ActionTypeID=14, invitee+inviter IP overlap |
| isAbuser | (computed) | -- | OR of MatualIPAdress30Days and isCashoutAfterCompensation |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_CIDFirstDates (SerialID=11, registered >= @Last2months)
  |-- Population: invitees who registered via referral
  |
  + BI_DB_dbo.History_Credit_Range (CreditTypeID=6)
  |   |-- CompensationReasonID=54 → PaymentToInvitee, Compensation_date
  |   |-- CompensationReasonID=53 → PaymentToInviter (invitee CID in Description)
  |
  + DWH_dbo.Dim_Position
  |   |-- SUM(Amount) within 30 days of FTD → NewTrades
  |
  + DWH_dbo.Fact_CustomerAction
  |   |-- ActionTypeID=7 → deposits (NoOfTotalDeposits, TotalDepositAmount)
  |   |-- ActionTypeID=8 → cashouts (TotalCashoutAmount, 14-day, 7-day-after-comp)
  |   |-- ActionTypeID=14 → login IPs for mutual IP detection
  |
  + BI_DB_dbo.BI_DB_CID_DailyPanel_FullData
  |   |-- IsFunded_New 14 days after FTD → IsFundedAfter14Days
  |
  + DWH_dbo.Dim_Customer (inviter)
  |   |-- RegulationID → payment amount tier ($50 Global / $30 US)
  |
  |-- SP_RAF_InviteeAbuser (DELETE+INSERT rolling 2-month window)
  |   Step 1: Build invitee population from CIDFirstDates
  |   Step 2: Resolve RAF compensation from History_Credit_Range
  |   Step 3: Aggregate deposits, cashouts, trades
  |   Step 4: Detect mutual IP addresses (invitee+inviter logins)
  |   Step 5: Compute eligibility, cashout-after-comp, FTD-30-days flags
  |   Step 6: Compute final isAbuser flag
  |   Step 7: DELETE WHERE registered >= @Last2months + INSERT
  v
BI_DB_dbo.BI_DB_RAF_Invitees_KPIs (710K rows, ROUND_ROBIN CI(Invitee))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Invitee | BI_DB_dbo.BI_DB_CIDFirstDates (RealCID) | Invitee's registration record |
| Inviter | BI_DB_dbo.BI_DB_CIDFirstDates (ReferralID) | Inviter's CID |
| Invitee, Inviter | DWH_dbo.Dim_Customer (RealCID) | Full customer profiles |
| PaymentToInvitee, PaymentToInviter | BI_DB_dbo.History_Credit_Range | RAF compensation records |
| NewTrades | DWH_dbo.Dim_Position | Trading activity |
| Deposit/Cashout/IP columns | DWH_dbo.Fact_CustomerAction | Action-level transaction data |
| IsFundedAfter14Days | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | Funded status |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 Abuse Rate Summary (Current SP Rows Only)

```sql
SELECT
    isAbuser,
    COUNT(*) AS cnt,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS pct
FROM BI_DB_dbo.BI_DB_RAF_Invitees_KPIs
WHERE isAbuser IS NOT NULL
GROUP BY isAbuser
```

### 7.2 Abuser Breakdown by Signal

```sql
SELECT
    CASE
        WHEN MatualIPAdress30Days = 1 AND isCashoutAfterCompensation = 1 THEN 'Both signals'
        WHEN MatualIPAdress30Days = 1 THEN 'Mutual IP only'
        WHEN isCashoutAfterCompensation = 1 THEN 'Cashout after comp only'
    END AS abuse_signal,
    COUNT(*) AS cnt
FROM BI_DB_dbo.BI_DB_RAF_Invitees_KPIs
WHERE isAbuser = 1
GROUP BY
    CASE
        WHEN MatualIPAdress30Days = 1 AND isCashoutAfterCompensation = 1 THEN 'Both signals'
        WHEN MatualIPAdress30Days = 1 THEN 'Mutual IP only'
        WHEN isCashoutAfterCompensation = 1 THEN 'Cashout after comp only'
    END
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 24 T2, 0 T3, 13 T4, 1 T5 | Elements: 38/38, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_RAF_Invitees_KPIs | Type: Table | Production Source: CIDFirstDates + History_Credit_Range + Fact_CustomerAction + Dim_Position via SP_RAF_InviteeAbuser*
