# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdraw

> AML dashboard summary table — 20,282 rows identifying funding instruments (payment methods) shared by 2+ customers for withdrawal activity. Each row aggregates withdrawal metrics per FundingID for multi-account suspicious activity monitoring. Refreshed daily via SP_AML_Multiple_Accounts (TRUNCATE + INSERT). **CRITICAL**: SP Step 12 has a column-swap bug — `IsBlocked` and `Total_Users` values are transposed in the INSERT statement.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_BillingWithdraw + BI_DB_dbo.External_etoro_Billing_Funding (via SP_AML_Multiple_Accounts Step 12) |
| **Refresh** | Daily (SP_AML_Multiple_Accounts, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_AML_Multiple_Accounts_Withdraw` is one of seven tables populated by `SP_AML_Multiple_Accounts` for the eToro AML (Anti-Money Laundering) Multiple Accounts Dashboard. This specific table stores the **withdrawal-side summary** — one row per shared funding instrument (FundingID) that has been used by 2 or more distinct customers for withdrawals.

The table enables compliance analysts to identify payment instruments (credit cards, bank accounts, e-wallets) being shared across multiple accounts for withdrawal activity, which is a key AML red flag. Funding instruments with IDs 1-7 are excluded (these are system/internal instruments). Only customers who are valid (IsValidCustomer=1), depositors (IsDepositor=1), and verified (VerificationLevelID >= 2) are counted.

**Companion tables** in the same SP:
- `BI_DB_AML_Multiple_Accounts_Dep` — deposit-side summary (Step 11)
- `BI_DB_AML_Multiple_Accounts_Withdrawfulldata` — per-CID detail for each shared withdrawal FundingID (Step 14)
- `BI_DB_AML_Multiple_Accounts_Dep_fulldata` — per-CID detail for shared deposit FundingIDs (Step 13)
- `BI_DB_AML_Multiple_Accounts_DeviceID` / `_FullData` — shared device IDs (Steps 14-15)
- `BI_DB_AML_Multiple_Accounts_SameIP` / `_FullData` — shared registration IPs (Steps 16-17)

**Known bug (SP Step 12 column swap)**: The INSERT statement in Step 12 lists the column order as `(FundingID, IsBlocked, Total_Users, ...)` but the SELECT provides `FundingID, Total_Users, IsBlocked, ...`. Since both `IsBlocked` (int) and `Total_Users` (int) are the same type, SQL Server silently inserts the values into the wrong columns. As a result, the `IsBlocked` column in this table actually contains user count values, and the `Total_Users` column contains the blocked flag. This bug does NOT affect the deposit counterpart (`BI_DB_AML_Multiple_Accounts_Dep`, Step 11) which has the correct column order. The `Group_Type` column is computed correctly before the swap.

---

## 2. Business Logic

### 2.1 Shared Funding Instrument Detection

**What**: Identifies funding instruments used by multiple customers for withdrawals — a multi-account AML indicator.

**Columns Involved**: `FundingID`, `Total_Users`, `Group_Type`

**Rules**:
- Only funding instruments with `COUNT(DISTINCT CID) >= 2` are included
- FundingID values 1-7 are excluded (system/internal instruments)
- Only valid, depositing, verified customers are counted: `IsValidCustomer=1 AND IsDepositor=1 AND VerificationLevelID >= 2`
- `Total_Users` is the count of distinct customers using this FundingID for withdrawals (but see column swap bug)
- `Group_Type` buckets the user count: '5-20', '21-50', '51-500', '500+'. Note: despite HAVING >= 2, the bucket labels start at 5 (the CASE has no explicit 2-4 bucket — those rows get NULL Group_Type, though none appear in current data)

### 2.2 Approved Withdrawal Aggregation

**What**: Summarizes approved withdrawal volume per shared funding instrument.

**Columns Involved**: `Total_Approved_Withdraw`, `Num_Approved_Withdraw`

**Rules**:
- `Total_Approved_Withdraw` = SUM of `Amount_WithdrawToFunding` (payout amount in processing currency) WHERE `CashoutStatusID_Funding = 3` (Processed/Approved)
- `Num_Approved_Withdraw` = COUNT of DISTINCT `WithdrawID` WHERE `CashoutStatusID_Funding = 3`
- Note: `Total_Approved_Withdraw` is stored as `int`, which truncates the money/decimal sum from the source

### 2.3 Column Swap Bug (SP Step 12)

**What**: The INSERT statement in SP_AML_Multiple_Accounts Step 12 transposes `IsBlocked` and `Total_Users`.

**Columns Involved**: `IsBlocked`, `Total_Users`

**Rules**:
- INSERT column list position 2 = `IsBlocked`, but SELECT position 2 = `Total_Users` (user count)
- INSERT column list position 3 = `Total_Users`, but SELECT position 3 = `IsBlocked` (block flag)
- Live data confirms: `IsBlocked` column has values 2-151 (user counts), `Total_Users` has values 0-1 (block flags)
- The deposit counterpart (Step 11) does NOT have this bug — its column order matches correctly
- `Group_Type` is unaffected — it is computed from the original user count in `#fid_Withdraw` before the swap

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP — no clustering or partitioning. With 20,282 rows, full table scans are trivial. No special query strategy needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Find high-risk shared instruments | ORDER BY IsBlocked DESC (note: this is actually the user count due to bug) |
| Filter by user count bucket | WHERE Group_Type = '51-500' |
| Most recent shared withdrawals | ORDER BY Last_Withdraw_Date DESC |
| Largest approved withdrawal volumes | ORDER BY Total_Approved_Withdraw DESC |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdrawfulldata | ON FundingID | Per-CID detail breakdown for each shared instrument |
| DWH_dbo.Fact_BillingWithdraw | ON FundingID | Drill into individual withdrawal transactions |

### 3.4 Gotchas

- **Column swap bug**: `IsBlocked` actually contains user counts; `Total_Users` actually contains block flags. Any dashboard consuming this table has inverted semantics for these two columns unless it was built with awareness of the bug.
- **Total_Approved_Withdraw is int**: The source `Amount_WithdrawToFunding` is money type but the target column is int — decimal amounts are truncated. This loses precision for fractional withdrawal amounts.
- **No 500+ bucket in data**: Despite the CASE expression defining a '500+' bucket, current data has no FundingIDs shared by more than ~151 users for withdrawals.
- **Snapshot table**: Entire table is TRUNCATE + INSERT daily. No history is preserved. All rows share the same UpdateDate.
- **Stale data**: As of sampling (2026-04-28), UpdateDate is 2025-03-13 — over a year stale. The SP may not be running in the current schedule.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim | (Tier 1 — Billing.Withdraw) |
| Tier 2 — SP ETL code | (Tier 2 — SP_AML_Multiple_Accounts) |
| Tier 3 — no upstream wiki | (Tier 3 — External_etoro_Billing_Funding, no upstream wiki) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FundingID | int | YES | FK to Billing.Funding — the payment instrument to which the withdrawal is paid. Used here as the grouping key for multi-account detection. Only FundingIDs shared by 2+ customers and with ID > 7 are included. (Tier 1 — Billing.Withdraw) |
| 2 | IsBlocked | int | YES | Intended: whether this funding instrument is blocked in the Billing.Funding system (from External_etoro_Billing_Funding.IsBlocked). **BUG**: Due to column-order swap in SP Step 12, this column actually contains the `Total_Users` value (COUNT of distinct customers using this FundingID for withdrawals). Live data range: 2-151. (Tier 3 — External_etoro_Billing_Funding, no upstream wiki; column swap bug in SP_AML_Multiple_Accounts Step 12) |
| 3 | Total_Users | int | YES | Intended: count of distinct customers who used this FundingID for withdrawals (COUNT(DISTINCT CID) from Fact_BillingWithdraw). **BUG**: Due to column-order swap in SP Step 12, this column actually contains the `IsBlocked` flag value (0=not blocked, 1=blocked). Live data range: 0-1. (Tier 2 — SP_AML_Multiple_Accounts; column swap bug in SP Step 12) |
| 4 | Group_Type | nvarchar(250) | YES | User count bucket label based on the number of distinct customers sharing this FundingID. Values: '5-20', '21-50', '51-500', '500+'. Computed correctly from the original user count before the column swap occurs. 99.7% of rows are '5-20'. (Tier 2 — SP_AML_Multiple_Accounts) |
| 5 | Last_Withdraw_Date | datetime | YES | Most recent withdrawal modification date across all withdrawals using this FundingID. Computed as MAX(Fact_BillingWithdraw.ModificationDate). Range: 2013-12-18 to 2025-03-12. (Tier 2 — SP_AML_Multiple_Accounts) |
| 6 | Total_Approved_Withdraw | int | YES | Total approved withdrawal amount (in processing currency) for this FundingID. Computed as SUM(Fact_BillingWithdraw.Amount_WithdrawToFunding) WHERE CashoutStatusID_Funding=3 (Processed). Stored as int, truncating decimal precision from the money-type source. (Tier 2 — SP_AML_Multiple_Accounts) |
| 7 | Num_Approved_Withdraw | int | YES | Count of distinct approved withdrawal transactions for this FundingID. Computed as COUNT(DISTINCT Fact_BillingWithdraw.WithdrawID) WHERE CashoutStatusID_Funding=3 (Processed). (Tier 2 — SP_AML_Multiple_Accounts) |
| 8 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at SP_AML_Multiple_Accounts execution time. All rows share the same value per daily refresh. Not a business date. (Tier 2 — SP_AML_Multiple_Accounts) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| FundingID | Fact_BillingWithdraw | FundingID | Passthrough (grouping key; filtered NOT IN 1-7, HAVING COUNT >= 2) |
| IsBlocked | External_etoro_Billing_Funding | IsBlocked | Intended passthrough; **BUG: receives Total_Users value** |
| Total_Users | Fact_BillingWithdraw | CID | COUNT(DISTINCT CID); **BUG: receives IsBlocked value** |
| Group_Type | Fact_BillingWithdraw | CID | CASE on COUNT(DISTINCT CID): <=20→'5-20', 21-50→'21-50', 51-500→'51-500', >500→'500+' |
| Last_Withdraw_Date | Fact_BillingWithdraw | ModificationDate | MAX(ModificationDate) |
| Total_Approved_Withdraw | Fact_BillingWithdraw | Amount_WithdrawToFunding | SUM WHERE CashoutStatusID_Funding=3 |
| Num_Approved_Withdraw | Fact_BillingWithdraw | WithdrawID | COUNT(DISTINCT) WHERE CashoutStatusID_Funding=3 |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_BillingWithdraw (withdrawal transactions)
  + DWH_dbo.Dim_Customer (filter: IsValidCustomer=1, IsDepositor=1, VerificationLevelID>=2)
  |
  v [SP_AML_Multiple_Accounts Step 02]
#fid_Withdraw (FundingIDs shared by 2+ customers, excluding IDs 1-7)
  |
  v [Step 02 continued]
#Withdraw_info (approved withdrawal sums per FundingID, CashoutStatusID_Funding=3)
  |
  v [Step 02 final]
#final_Withdraw = #fid_Withdraw + #Withdraw_info
  |
  + BI_DB_dbo.External_etoro_Billing_Funding (IsBlocked flag per FundingID)
  |
  v [SP_AML_Multiple_Accounts Step 04]
#finalWithdraw (summary with IsBlocked joined)
  |
  v [SP_AML_Multiple_Accounts Step 12 — TRUNCATE + INSERT]
BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdraw (20,282 rows)
  ⚠ NOTE: IsBlocked and Total_Users are SWAPPED in the INSERT column order
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| FundingID | Billing.Funding (production) | Payment instrument used for withdrawals |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| AML Multiple Accounts Dashboard | FundingID | Power BI / reporting dashboard for AML compliance analysts |

---

## 7. Sample Queries

### 7.1 Funding instruments with highest user sharing (accounting for column swap bug)

```sql
-- IsBlocked column actually contains user counts due to SP bug
SELECT FundingID,
       IsBlocked AS Actual_Total_Users,    -- swapped: contains user count
       Total_Users AS Actual_IsBlocked,    -- swapped: contains block flag
       Group_Type,
       Last_Withdraw_Date,
       Total_Approved_Withdraw,
       Num_Approved_Withdraw
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Withdraw]
ORDER BY IsBlocked DESC;  -- sorts by actual user count
```

### 7.2 High-volume shared instruments with approved withdrawals

```sql
SELECT FundingID,
       Group_Type,
       Total_Approved_Withdraw,
       Num_Approved_Withdraw,
       Last_Withdraw_Date
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Withdraw]
WHERE Total_Approved_Withdraw > 10000
ORDER BY Total_Approved_Withdraw DESC;
```

### 7.3 Join to full data for per-customer breakdown

```sql
SELECT w.FundingID,
       w.Group_Type,
       w.Total_Approved_Withdraw,
       wf.CID,
       wf.UserName,
       wf.Country,
       wf.Regulation,
       wf.PlayerStatus
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Withdraw] w
JOIN [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Withdrawfulldata] wf
  ON w.FundingID = wf.FundingID
WHERE w.Group_Type IN ('51-500', '500+')
ORDER BY w.FundingID, wf.CID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian MCP available this session. Phase 10 skipped.

---

*Generated: 2026-04-28 | Quality: 7.5/10*
*Tiers: 1 T1, 6 T2, 1 T3, 0 T4 | Phases: 1,2,3,4,5,6,8,9,9B,10A,10B,11*
*Object: BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdraw | Type: Table | Production Source: Fact_BillingWithdraw + External_etoro_Billing_Funding via SP_AML_Multiple_Accounts*
