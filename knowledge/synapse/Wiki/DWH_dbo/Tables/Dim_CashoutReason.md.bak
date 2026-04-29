# DWH_dbo.Dim_CashoutReason

> Lookup dimension defining the 19 business reasons for initiating a cashout (withdrawal), from user-requested withdrawals and PI payments to risk refunds, account closures, and crypto transfers.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.Dictionary.CashoutReason` |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full reload) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CashoutReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason` |
| **UC Format** | Parquet (Override/full load, daily) |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CashoutReason` enumerates why a withdrawal was initiated on the eToro platform. Every withdrawal carries a `CashoutReasonID` that classifies the business context: was it a standard user request, a Popular Investor payment, an affiliate payment, a risk refund, an account closure, or a crypto transfer? This classification is critical for financial reporting, compliance auditing, and withdrawal processing logic - different reasons trigger different routing in the withdrawal pipeline.

Data flows from production `etoro.Dictionary.CashoutReason` via the Generic Pipeline (daily Override export to Bronze `general.bronze_etoro_dictionary_cashoutreason`), then through staging table `DWH_staging.etoro_Dictionary_CashoutReason`, and into DWH via `SP_Dictionaries_DL_To_Synapse` (TRUNCATE + INSERT). The DWH table is a clean passthrough of the production data with only `UpdateDate` replaced by `GETDATE()` at load time. See upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutReason.md`.

`SP_Dictionaries_DL_To_Synapse` refreshes this table daily as part of the dictionary batch. `UpdateDate` reflects the most recent ETL execution time, not the business change date. As of 2026-03-11 the table contains 19 rows. No ID=0 placeholder row exists (unlike tables loaded by other SP_Dictionaries sections).

---

## 2. Business Logic

### 2.1 Withdrawal Reason Categories

**What**: The 19 reasons group into functional categories that determine processing logic and financial reporting classification.

**Columns Involved**: `CashoutReasonID`, `Name`

**Rules**:
- **User-Initiated (16)**: Standard withdrawal requested by the customer. Default value in Billing.WithdrawRequestAdd on production. Most common cashout reason.
- **Partner Payments (14, 15)**: Automated payments to Popular Investors (PI Payment) and Affiliates. Special routing in Billing.WithdrawToFundingProcess on production.
- **Risk/Compliance (3, 7, 8)**: Risk refunds, 3rd party payment returns, bonus abuse adjustments.
- **Account Closures (6, 12, 17, 19)**: Forced withdrawals when accounts are blocked, foreclosed, or failed verification. IDs 12 and 19 trigger special handling in production.
- **Adjustments (1, 4, 5)**: Financial corrections - general adjustments, negative balance fixes, withdrawal fee adjustments.
- **Technical/Operational (9, 10, 11, 13)**: Returned withdrawals, technical issues, underage closures, test transactions.
- **Crypto (18)**: Withdrawal via crypto wallet transfer.

**Diagram**:
```
Cashout Reason Categories:
  User-Initiated  -> Requested by User (16)
  Partner         -> PI Payment (14), Affiliate Payment (15)
  Risk/Compliance -> Risk Refund (3), 3rd Party (7), Bonus Abuse (8)
  Account Closure -> Foreclose (12, 19), Block (6), Failed Verification (17)
  Adjustments     -> Adjustment (1), Negative Balance (4), Fee Adj (5)
  Special         -> Crypto Transfer (18), Returned (9), Underage (11), Test (13)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `CashoutReasonID`. With 19 rows, the full table is replicated to every compute node - JOINs on `CashoutReasonID` are zero-cost broadcast JOINs. No filter needed for performance.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is stored as Parquet in the `dwh` catalog at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason`. Full Override load daily (19 rows). No partition columns - full scan is trivial at this scale.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode a CashoutReasonID to its name | `JOIN DWH_dbo.Dim_CashoutReason ON CashoutReasonID` |
| Find all partner/PI payment withdrawals | `WHERE CashoutReasonID IN (14, 15)` |
| Find forced account closure withdrawals | `WHERE CashoutReasonID IN (6, 12, 17, 19)` |
| Find user-initiated withdrawals | `WHERE CashoutReasonID = 16` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingWithdraw (planned) | ON CashoutReasonID | Decode reason for each withdrawal |
| DWH_dbo.Fact_Cashout_State (planned) | ON CashoutReasonID | Withdrawal reason in cashout pipeline |

### 3.4 Gotchas

- **UpdateDate is the ETL load time**, not the date the reason was added or modified in production. Do not use `UpdateDate` to detect production data changes.
- **No ID=0 row** - unlike most SP_Dictionaries-loaded tables, `Dim_CashoutReason` does not have an N/A placeholder row at ID=0. JOINs on fact tables that store `0` as a default will return NULL.
- **IDs 12 and 19 are both foreclosure types** (Foreclose account, ForClose(GAP)) - they serve different scenarios in the production billing system but both represent forced account liquidation in DWH analytics.
- **ID 18 spelling**: Production name is "Transfered by CryptoWallet" (typo in source - single 'r' in Transferred). Match the exact value when filtering.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Meaning |
|-------|------|-----|---------|
| **** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Verbatim from upstream production wiki |
| *** | Tier 2 | `(Tier 2 - SP code, ...)` | Confirmed from Synapse ETL SP code |
| ** | Tier 3 | `(Tier 3 - live data)` | Observed from MCP live data sampling |
| * | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Column name inference only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CashoutReasonID | int | NO | Primary key identifying the withdrawal reason. Values 1-19 in DWH. Stored in Billing.Withdraw and History.WithdrawAction on production. Special routing for IN (12, 14, 15) in Billing.WithdrawToFundingProcess. Default 16 (Requested by User) set in Billing.WithdrawRequestAdd. See Section 2.1 for full value map. (Tier 1 - upstream wiki, Dictionary.CashoutReason) |
| 2 | Name | varchar(50) | NO | Human-readable withdrawal reason label. E.g., "Requested by User" (most common), "PI Payment", "Foreclose account". Displayed in BackOffice withdrawal screens and used in audit trails. (Tier 1 - upstream wiki, Dictionary.CashoutReason) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp set to GETDATE() on each daily reload. Reflects when SP_Dictionaries_DL_To_Synapse last ran - NOT when the reason was added or changed in production. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CashoutReasonID | etoro.Dictionary.CashoutReason | CashoutReasonID | Passthrough |
| Name | etoro.Dictionary.CashoutReason | Name | Passthrough |
| UpdateDate | (ETL-computed) | - | GETDATE() at load time |

Full production documentation: upstream wiki at `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.CashoutReason.md`

### 5.2 ETL Pipeline

```
etoro.Dictionary.CashoutReason
  -> Generic Pipeline (daily Override, Bronze: general.bronze_etoro_dictionary_cashoutreason)
  -> DWH_staging.etoro_Dictionary_CashoutReason
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, UpdateDate=GETDATE())
  -> DWH_dbo.Dim_CashoutReason
  -> Generic Pipeline (daily Override, Gold: dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.CashoutReason | Production lookup - 19 withdrawal reasons |
| Lake | Bronze/etoro/Dictionary/CashoutReason/ | Daily Override export |
| Staging | DWH_staging.etoro_Dictionary_CashoutReason | Raw import from lake |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT, UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_CashoutReason | DWH dimension (19 rows) |

---

## 6. Relationships

### 6.1 References To (this object points to)

This table has no outgoing references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_BillingWithdraw (planned) | CashoutReasonID | Withdrawal event fact table - JOIN to decode reason |
| DWH_dbo.Fact_Cashout_State (planned) | CashoutReasonID | Cashout pipeline state table - JOIN to decode reason |
| Production: Billing.Withdraw | CashoutReasonID | Main withdrawal table stores reason per withdrawal |
| Production: BackOffice withdrawal procs (22+) | CashoutReasonID | LEFT JOIN for reason display in BO screens |

Note: No DWH_dbo SPs or Views currently JOIN this table (grep of SSDT repo returned no matches). It serves as a UC Gold export for external consumers and direct querying.

---

## 7. Sample Queries

### 7.1 List all withdrawal reasons
```sql
SELECT  CashoutReasonID,
        Name
FROM    [DWH_dbo].[Dim_CashoutReason]
ORDER BY CashoutReasonID;
```

### 7.2 Decode reason for a withdrawal fact
```sql
SELECT  f.WithdrawID,
        f.CID,
        f.Amount,
        r.Name AS CashoutReason
FROM    [DWH_dbo].[Fact_BillingWithdraw] f
LEFT JOIN [DWH_dbo].[Dim_CashoutReason] r
        ON f.CashoutReasonID = r.CashoutReasonID
ORDER BY f.WithdrawID DESC;
```

### 7.3 Count withdrawals by reason category
```sql
SELECT  r.Name AS CashoutReason,
        COUNT(*) AS WithdrawalCount
FROM    [DWH_dbo].[Fact_BillingWithdraw] f
LEFT JOIN [DWH_dbo].[Dim_CashoutReason] r
        ON f.CashoutReasonID = r.CashoutReasonID
GROUP BY r.Name
ORDER BY WithdrawalCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from upstream wiki (Dictionary.CashoutReason, quality 9.2/10) and SP_Dictionaries_DL_To_Synapse ETL analysis.

---

*Generated: 2026-03-19 | Quality: 9.0/10 (★★★★★) | Phases: 7/14 (Simple-Dict Fast-Path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_CashoutReason | Type: Table | Production Source: etoro.Dictionary.CashoutReason*
