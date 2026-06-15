# DWH_dbo.Dim_PaymentStatus

> 40-row reference dictionary mapping PaymentStatusID to the deposit/funding transaction outcome code -- covering the complete lifecycle from submission (New, InProcess) through approval (Approved, Confirmed), various decline reasons (fraud, limits, blocked payment methods, country restrictions), chargebacks, refunds, and internal operational states.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.PaymentStatus (etoroDB-REAL) |
| **Refresh** | Daily (TRUNCATE + INSERT via SP_Dictionaries_DL_To_Synapse; PaymentStatusID=-1 is a manually-inserted sentinel) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (PaymentStatusID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` |
| **UC Format** | parquet |
| **UC Partitioned By** | None (40 rows) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_PaymentStatus` is the lookup table for payment/deposit transaction status codes on the eToro platform. Every deposit or funding transaction carries a PaymentStatusID that identifies where in the payment lifecycle it is, or how it was resolved.

The 40 statuses span 6 functional categories:

| Category | IDs | Examples |
|----------|-----|---------|
| **Active/Pending** | 1, 4, 5, 13, 36 | New, Technical, InProcess, Pending, PendingReview |
| **Success** | 2, 7 | Approved, Confirmed |
| **Generic Decline** | 3, 31-35 | Decline, DeclineBinConflictCountry, DeclineSecurityValidation |
| **Block-based Decline** | 8-12, 14-24, 28-29 | DeclineBlockCard, DeclinedBlockedPayPal, DeclinedBlockedCountry |
| **Chargeback/Refund** | 11, 12, 25-27, 37-39 | Chargeback, Refund, ChargebackReversal, MigratedToDepositTable |
| **Cancellation** | 6 | Canceled |

PaymentStatusID=-1 is a DWH null-sentinel (manually inserted, UpdateDate at midnight vs. 02:12 for SP-loaded rows). PaymentStatusIDs 1-39 are loaded from `etoro_Dictionary_PaymentStatus` by `SP_Dictionaries_DL_To_Synapse`.

---

## 2. Business Logic

### 2.1 Payment Status Lifecycle

**What**: A payment transaction moves through statuses as it is processed. The final status determines the financial outcome.

**Standard flow**:
```
New (1) -> InProcess (5) -> [Approved (2) | Confirmed (7)]
        or -> Technical (4) [processing issue, may retry]
        or -> Pending (13) / PendingReview (36)
        or -> Decline (3) / Declined* (8-24, 28-35)
        or -> Canceled (6)
```

**Post-settlement flows**:
```
Approved/Confirmed -> Chargeback (11) -> ChargebackReversal (37)
                   -> Refund (12) -> RefundReversal (38)
                   -> RefundAsChargeback (26)
                   -> ReversedDeposit (39)
```

### 2.2 Decline Status Taxonomy

**What**: Most decline statuses encode the specific reason for rejection, which is valuable for fraud analytics and payment operations.

**Rules**:
- **Method-specific blocks** (14-24, 28): `DeclinedBlockedPayPal`, `DeclinedBlockedNeteller`, `DeclinedBlockedMoneyBookers`, `DeclinedBlockedWebMoney`, `DeclinedBlockedGiropay`, `DeclinedBlockedELV`, `DeclinedBlockedDirect24`, `DeclinedBlockedSofort` -- the customer's specific payment method is blocked by eToro's risk rules.
- **Country blocks** (18, 29, 34): `DeclinedBlockedCountry`, `DeclinedDepositCountryConflict`, `DeclineHighRiskCountry` -- blocked due to regulatory or risk reasons related to the customer's country.
- **Limit blocks** (10, 20, 30): `DeclineMemberLimits`, `DeclinedOverTheLimit`, `DeclinedOverTheLimitSingleDeposit` -- deposit exceeds the customer's allowed limits.
- **Fraud/risk** (9, 19, 31, 32, 35): `DeclineBadBins`, `DeclinedHighRiskCID`, `DeclineBinConflictCountry`, `DeclineSecurityValidation`, `DeclineByRRE` -- flagged by fraud or risk systems.
- **FTD limit** (33): `DeclineFtdOverTheLimit` -- first-time deposit exceeds allowed amount.

### 2.3 PaymentStatusID=-1 Sentinel

**Rule**: PaymentStatusID=-1 (Name='N/A') is a manually-inserted sentinel row. Its UpdateDate is `2026-03-11 00:00:00` (midnight), compared to `02:12` for SP-loaded rows. `DWHPaymentStatusID=0` for this row (vs. `PaymentStatusID` for all others). Always filter `WHERE PaymentStatusID > 0` for real status analysis.

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Successful deposits | `WHERE PaymentStatusID IN (2, 7)` |
| All declined payments | `WHERE Name LIKE 'Decline%' OR Name LIKE 'Declined%'` or `WHERE PaymentStatusID IN (3, 8, 9, 10, 14-24, 28-35)` |
| Payments in progress | `WHERE PaymentStatusID IN (1, 4, 5, 13, 36)` |
| Chargebacks and refunds | `WHERE PaymentStatusID IN (11, 12, 26, 37, 38, 39)` |
| Exclude sentinel | `WHERE PaymentStatusID > 0` (or `<> -1`) |

### 3.2 Gotchas

- **PaymentStatusID=-1 has DWHPaymentStatusID=0**: Anomaly -- the -1 row was manually inserted (not by SP_Dictionaries) and has DWHPaymentStatusID=0 instead of -1. Indicates this is a special-case sentinel.
- **UpdateDate is GETDATE() at load**: Does not reflect production modification date.
- **Method-blocked declines reference legacy payment methods**: `DeclinedBlockedMoneyBookers`, `DeclinedBlockedGiropay`, `DeclinedBlockedELV`, `DeclinedBlockedDirect24`, `DeclinedBlockedSofort` -- some of these payment methods may no longer be active on the platform.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 — Dictionary (upstream wiki) | `(Tier 1 — Dictionary.PaymentStatus)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PaymentStatusID | int | NO | Primary key identifying the payment state. 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 7=Confirmed. (Tier 1 — Dictionary.PaymentStatus) |
| 2 | Name | varchar(50) | NO | Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports. (Tier 1 — Dictionary.PaymentStatus) |
| 3 | DWHPaymentStatusID | int | YES | Always equal to PaymentStatusID for IDs >= 1. Exception: PaymentStatusID=-1 has DWHPaymentStatusID=0 (manual sentinel). Standard DWH DWH{X}ID pattern. Do not use for JOINs. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded to 1 for all SP-loaded rows. Conveys no information. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() at load time for SP-loaded rows; midnight timestamp for PaymentStatusID=-1 (manually inserted). (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL load timestamp -- GETDATE() at load time (same as UpdateDate). Midnight for PaymentStatusID=-1. (Tier 2 -- SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| PaymentStatusID | etoro.Dictionary.PaymentStatus | PaymentStatusID | passthrough (IDs >= 1); -1 row is manual sentinel |
| Name | etoro.Dictionary.PaymentStatus | Name | passthrough |
| DWHPaymentStatusID | etoro.Dictionary.PaymentStatus | PaymentStatusID | rename (= PaymentStatusID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| InsertDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.PaymentStatus  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_PaymentStatus
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_PaymentStatus  (40 rows; 39 from SP + 1 manual sentinel ID=-1)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_PaymentStatus/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Deposit/payment fact tables | PaymentStatusID | Every deposit transaction has a PaymentStatusID |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP |

---

## 7. Sample Queries

### 7.1 Count deposits by status category

```sql
SELECT
    ps.PaymentStatusID,
    ps.Name AS PaymentStatus,
    COUNT(DISTINCT f.TransactionID) AS TransactionCount
FROM [DWH_dbo].[SomePaymentFact] f
JOIN [DWH_dbo].[Dim_PaymentStatus] ps ON f.PaymentStatusID = ps.PaymentStatusID
WHERE ps.PaymentStatusID > 0
GROUP BY ps.PaymentStatusID, ps.Name
ORDER BY TransactionCount DESC;
```

### 7.2 Decline rate by method-specific block

```sql
SELECT
    ps.Name AS DeclineReason,
    COUNT(DISTINCT f.TransactionID) AS DeclineCount
FROM [DWH_dbo].[SomePaymentFact] f
JOIN [DWH_dbo].[Dim_PaymentStatus] ps ON f.PaymentStatusID = ps.PaymentStatusID
WHERE ps.Name LIKE 'Declined%' OR ps.Name LIKE 'Decline%'
GROUP BY ps.Name
ORDER BY DeclineCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.6/10 (★★★★☆) | Phases: 6/14 (Simple Dictionary Fast-Path)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 6/6, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: DWH_dbo.Dim_PaymentStatus | Type: Table | Production Source: etoro.Dictionary.PaymentStatus*
