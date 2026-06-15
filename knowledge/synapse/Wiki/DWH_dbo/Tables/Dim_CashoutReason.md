# DWH_dbo.Dim_CashoutReason

> 19-row replicated dimension table defining the reasons for initiating a cashout (withdrawal) -- from user-requested withdrawals and PI payments to risk refunds, account closures, and crypto transfers. Refreshed daily via TRUNCATE+INSERT from etoro.Dictionary.CashoutReason.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.CashoutReason via SP_Dictionaries_DL_To_Synapse |
| **Refresh** | Daily (TRUNCATE + INSERT, 1440 min cycle) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CashoutReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_CashoutReason` is the Synapse DWH replica of the production `Dictionary.CashoutReason` lookup table. It holds exactly 19 rows, each representing a distinct reason why a withdrawal (cashout) was initiated. Every withdrawal recorded in `Billing.Withdraw` carries a `CashoutReasonID` that classifies the business context: standard user request (16), Popular Investor payment (14), affiliate payment (15), risk refund (3), account closure (12, 19), crypto transfer (18), and others.

The ETL is a straightforward TRUNCATE + INSERT inside `SP_Dictionaries_DL_To_Synapse`, pulling from the staging table `DWH_staging.etoro_Dictionary_CashoutReason` (which mirrors production `Dictionary.CashoutReason` via the Generic Pipeline Bronze export). The only column not inherited from production is `UpdateDate`, which is set to `GETDATE()` on each load.

This dimension is joined by downstream fact tables and BackOffice reporting procedures to resolve `CashoutReasonID` into its human-readable `Name`.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: The 19 cashout reasons fall into distinct business categories.

**Columns Involved**: `CashoutReasonID`, `Name`

**Rules**:
- **User-Initiated (16)**: Standard withdrawal requested by the customer. Default value in WithdrawRequestAdd.
- **Partner Payments (14, 15)**: Automated payments to Popular Investors (PI Payment) and Affiliates (Affiliate Payment). Special processing in WithdrawToFundingProcess.
- **Risk/Compliance (3, 7, 8)**: Risk refunds, 3rd party payment returns, bonus abuse adjustments.
- **Account Closures (6, 12, 17, 19)**: Forced withdrawals when accounts are blocked, foreclosed, or failed verification. CashoutReasonID=12 and 19 trigger special handling in processing.
- **Adjustments (1, 4, 5)**: Financial corrections -- general adjustments, negative balance fixes, withdrawal fee adjustments.
- **Technical/Operational (9, 10, 11, 13)**: Returned withdrawals, technical issues, underage account closures, test transactions.
- **Crypto (18)**: Withdrawal via crypto wallet transfer.

### 2.2 Special Processing by Reason

**What**: Specific CashoutReasonIDs trigger different downstream processing logic.

**Columns Involved**: `CashoutReasonID`

**Rules**:
- `Billing.WithdrawToFundingProcess` checks `CashoutReasonID IN (12, 14, 15)` -- foreclose, PI payment, and affiliate payment get special routing.
- `Billing.WithdrawRequestAdd` defaults `@CashoutReasonID=16` for standard user-initiated withdrawals.
- `Billing.WithdrawAndWithdrawToFundingAdd` defaults `@CashoutReasonID=18` for crypto wallet transfers.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE-distributed (19 rows trivially replicated to all compute nodes). CLUSTERED INDEX on `CashoutReasonID ASC` -- zero JOIN overhead. All queries are instant at this table size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| List all cashout reasons | `SELECT * FROM DWH_dbo.Dim_CashoutReason ORDER BY CashoutReasonID` |
| Resolve reason name for a withdrawal | `JOIN Dim_CashoutReason ON CashoutReasonID` |
| Find closure-related reasons | `WHERE CashoutReasonID IN (6, 12, 17, 19)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| Fact tables with CashoutReasonID | `ON f.CashoutReasonID = dcr.CashoutReasonID` | Resolve reason name for reporting |

### 3.4 Gotchas

- **Static 19 rows**: This is a fixed enumeration. New reasons require a production DDL insert into `Dictionary.CashoutReason`.
- **UpdateDate is ETL timestamp**: Reflects the last SP run (GETDATE()), not when the reason was created or modified in production.
- **No DWH surrogate key**: Unlike many Dim tables, there is no `DWHCashoutReasonID` column -- `CashoutReasonID` is used directly.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- upstream production wiki | `(Tier 1 -Dictionary.CashoutReason)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -SP_Dictionaries_DL_To_Synapse)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CashoutReasonID | int | NO | Primary key identifying the withdrawal reason. Range 1-19. Stored in Billing.Withdraw, History.WithdrawAction. Default 16 (user request) in WithdrawRequestAdd. Special processing for IN (12, 14, 15) in WithdrawToFundingProcess. Joined by 15+ BackOffice/Billing/Trade procedures. Values: 1=Adjustment, 2=Partners withdraw, 3=Risk Refund, 4=Negative Balance adjustment, 5=Withdraw fees adjustment, 6=Block account -- Not communicative, 7=3rd party payment, 8=Bonus abuse adjustment, 9=Returned withdraw, 10=Technical issue -- Customer side, 11=Underage, 12=Foreclose account, 13=Test, 14=PI Payment, 15=Affiliate Payment, 16=Requested by User, 17=Failed Verification, 18=Transfered by CryptoWallet, 19=ForClose(GAP). (Tier 1 -Dictionary.CashoutReason) |
| 2 | Name | varchar(50) | NO | Human-readable reason label. No unique constraint. Displayed in BackOffice withdrawal screens via LEFT JOIN. Used in reports, audit trails, and customer-facing credit history. (Tier 1 -Dictionary.CashoutReason) |
| 3 | UpdateDate | datetime | NO | ETL run timestamp set to GETDATE() on each daily TRUNCATE+INSERT cycle. Reflects last SP_Dictionaries_DL_To_Synapse execution, not production modification time. (Tier 2 -SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CashoutReasonID | etoro.Dictionary.CashoutReason | CashoutReasonID | Passthrough |
| Name | etoro.Dictionary.CashoutReason | Name | Passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.CashoutReason (production, 19 rows)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_CashoutReason
  |-- SP_Dictionaries_DL_To_Synapse ---|
      TRUNCATE Dim_CashoutReason
      INSERT CashoutReasonID, Name, GETDATE() AS UpdateDate
  v
DWH_dbo.Dim_CashoutReason (19 rows; daily TRUNCATE+INSERT)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_CashoutReason/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutreason)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Billing.Withdraw | CashoutReasonID | Main withdrawal table stores reason |
| History.WithdrawAction | CashoutReasonID | Withdrawal action history stores reason |
| BackOffice.GetWithdrawRequests | CashoutReasonID | Withdrawal screen shows reason name |
| BackOffice.GetCashOutRequests_Main | CashoutReasonID | Main cashout screen shows reason |
| Billing.WithdrawToFundingProcess | CashoutReasonID | Special processing for IN (12, 14, 15) |
| Billing.WithdrawRequestAdd | @CashoutReasonID | Sets reason at withdrawal creation (default 16) |
| Billing.WithdrawAndWithdrawToFundingAdd | @CashoutReasonID | Crypto wallet transfers (default 18) |

---

## 7. Sample Queries

### 7.1 List all cashout reasons

```sql
SELECT CashoutReasonID,
       Name
FROM   [DWH_dbo].[Dim_CashoutReason]
ORDER BY CashoutReasonID;
```

### 7.2 Count withdrawals by cashout reason

```sql
SELECT dcr.Name            AS CashoutReason,
       COUNT(*)            AS WithdrawalCount
FROM   [DWH_dbo].[Fact_BillingWithdraw] fw
JOIN   [DWH_dbo].[Dim_CashoutReason] dcr
       ON fw.CashoutReasonID = dcr.CashoutReasonID
GROUP BY dcr.Name
ORDER BY WithdrawalCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from upstream Dictionary.CashoutReason wiki and SP code analysis.

---

*Generated: 2026-04-28 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 | Elements: 3/3, Logic: 9/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_CashoutReason | Type: Table | Production Source: etoro.Dictionary.CashoutReason*
