# DWH_dbo.Dim_ClientWithdrawReason

> Lookup dimension listing the 7 customer-facing reasons displayed in the eToro withdrawal form - used for withdrawal UX and churn analytics.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.Dictionary.ClientWithdrawReason` |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full reload) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ClientWithdrawReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason` |
| **UC Format** | Parquet (Override/full load, daily) |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_ClientWithdrawReason` lists the predefined reasons a customer can select when submitting a withdrawal request. These options appear in the withdrawal form UI during the cash-out flow, allowing customers to indicate why they are withdrawing funds. The reasons range from "Withdrawing profits" (indicating trading success) to "Moving to a competitor" (competitive churn signal). This dimension enables churn analysis and product improvement by revealing withdrawal motivations.

Data flows from `etoro.Dictionary.ClientWithdrawReason` via the Generic Pipeline (daily Override to Bronze), through `DWH_staging.etoro_Dictionary_ClientWithdrawReason`, and into DWH via `SP_Dictionaries_DL_To_Synapse`. The ETL applies two changes: (1) the production `Name` column is renamed to `ClientWithdrawReasonName`, and (2) `UpdateDate` is replaced by `GETDATE()`. The production `IsActive` and `DisplayOrder` columns (used to control UI display) are **not loaded into DWH**. All 7 production active reasons are present (IDs 1-7). No ID=0 placeholder exists in this table. See upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ClientWithdrawReason.md`.

---

## 2. Business Logic

### 2.1 Withdrawal Intent Categories

**What**: The 7 reasons span three analytical categories relevant to churn analysis.

**Columns Involved**: `ClientWithdrawReasonID`, `ClientWithdrawReasonName`

**Rules**:
- **Positive intent (2)**: "Withdrawing profits" - customer had a good experience, taking gains. Not a churn risk.
- **Financial need (3)**: "Fulfill other financial commitments" - neutral, external need for funds.
- **Dissatisfaction/Churn (4, 5, 7)**: "Not achieved trading goals", "Platform not for me", "Moving to competitor" - strong churn signals for retention analytics.
- **Account closure (6)**: "Would like to close my account" - explicit closure intent, may trigger compliance workflows.
- **Fallback (1)**: "None of the reasons above" - customer provides free-text via ClientWithdrawReasonComment in Billing.Withdraw.

**Diagram**:
```
Withdrawal Intent Classification:
  Positive Intent  -> ID 2: Withdrawing profits
  Financial Need   -> ID 3: Other financial commitments
  Dissatisfaction  -> ID 4: Goals not achieved
                      ID 5: Platform not suitable
                      ID 7: Moving to competitor  (churn signal)
  Account Closure  -> ID 6: Close my account
  Fallback         -> ID 1: None of the above (see free-text comment)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed with CLUSTERED INDEX on `ClientWithdrawReasonID`. 7 rows - zero-cost JOIN on any node.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, stored as Parquet at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason`. 7 rows, daily Override.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode ClientWithdrawReasonID to label | `LEFT JOIN Dim_ClientWithdrawReason ON ClientWithdrawReasonID` |
| Find competitor churn withdrawals | `WHERE ClientWithdrawReasonID = 7` |
| Identify "I want to close my account" | `WHERE ClientWithdrawReasonID = 6` |
| Find withdrawals with free-text reason | `WHERE ClientWithdrawReasonID = 1` (check ClientWithdrawReasonComment on fact table) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingWithdraw (planned) | ON ClientWithdrawReasonID | Decode customer-stated reason per withdrawal |

### 3.4 Gotchas

- **Name column renamed**: Production calls it `Name`; DWH calls it `ClientWithdrawReasonName`. Cross-join queries between DWH and production staging need to account for this rename.
- **IsActive and DisplayOrder dropped**: DWH does not carry the production `IsActive` flag or `DisplayOrder`. All 7 rows in DWH are the currently active reasons - no way to tell from DWH alone which reasons are UI-visible or in what order they appear.
- **ID=1 is the fallback**: "None of the reasons above" (ID=1) means the customer typed a free-text reason. The actual text is stored in `ClientWithdrawReasonComment` on `Billing.Withdraw` / `Fact_BillingWithdraw` - not in this dimension table.
- **No ID=0 placeholder**: This table starts at ID=1. Fact rows with ClientWithdrawReasonID=0 (if any) will return NULL on JOIN.
- **UpdateDate is ETL time**: Reflects SP_Dictionaries_DL_To_Synapse execution time, not when reasons were added/changed in production.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Meaning |
|-------|------|-----|---------|
| **** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Verbatim from upstream production wiki |
| *** | Tier 2 | `(Tier 2 - SP code, ...)` | Confirmed from Synapse ETL SP code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ClientWithdrawReasonID | int | YES | Primary key. Values 1-7. Referenced by Billing.Withdraw via FK on production. Passed as @ClientWithdrawReasonID to WithdrawalService_WithdrawRequestAdd on production. DWH DDL defines as nullable - this is a DDL quirk (production column is NOT NULL). (Tier 1 - upstream wiki, Dictionary.ClientWithdrawReason) |
| 2 | ClientWithdrawReasonName | varchar(50) | YES | Human-readable reason label shown in the withdrawal form. DWH note: column renamed from production `Name` to `ClientWithdrawReasonName` by SP_Dictionaries_DL_To_Synapse. E.g., "Withdrawing profits", "Moving to a competitor", "None of the reasons above". (Tier 1 - upstream wiki, Dictionary.ClientWithdrawReason) |
| 3 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() on each daily reload. Not a business change date - reflects SP_Dictionaries_DL_To_Synapse execution time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ClientWithdrawReasonID | etoro.Dictionary.ClientWithdrawReason | ClientWithdrawReasonID | Passthrough |
| ClientWithdrawReasonName | etoro.Dictionary.ClientWithdrawReason | Name | Rename (Name -> ClientWithdrawReasonName) |
| UpdateDate | (ETL-computed) | - | GETDATE() at load |

Dropped production columns not loaded into DWH: `IsActive`, `DisplayOrder`.

### 5.2 ETL Pipeline

```
etoro.Dictionary.ClientWithdrawReason
  -> Generic Pipeline (daily Override, Bronze: general.bronze_etoro_dictionary_clientwithdrawreason)
  -> DWH_staging.etoro_Dictionary_ClientWithdrawReason
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, Name->ClientWithdrawReasonName)
  -> DWH_dbo.Dim_ClientWithdrawReason
  -> Generic Pipeline (daily Override, Gold: dwh.gold_sql_dp_prod_we_dwh_dbo_dim_clientwithdrawreason)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.ClientWithdrawReason | Production 7-reason withdrawal form lookup |
| Lake | Bronze/etoro/Dictionary/ClientWithdrawReason/ | Daily Override export |
| Staging | DWH_staging.etoro_Dictionary_ClientWithdrawReason | Raw import from lake |
| ETL | SP_Dictionaries_DL_To_Synapse (lines 456-466) | TRUNCATE + INSERT; Name renamed to ClientWithdrawReasonName, UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_ClientWithdrawReason | 7 rows (IDs 1-7) |

---

## 6. Relationships

### 6.1 References To (this object points to)

This table has no outgoing references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_BillingWithdraw (planned) | ClientWithdrawReasonID | Withdrawal fact - JOIN for customer-stated reason |
| Production: Billing.Withdraw | ClientWithdrawReasonID | FK - each withdrawal records selected reason |
| Production: BackOffice.GetCashOutRequests_Main | ClientWithdrawReasonID | BO proc returns reason for cash-out requests |
| Production: SalesForce.GetWithdraws | ClientWithdrawReasonID | SF integration surfaces withdrawal reason |

Note: No DWH_dbo SPs or Views currently JOIN this table (SSDT grep returned no matches).

---

## 7. Sample Queries

### 7.1 List all withdrawal reasons
```sql
SELECT  ClientWithdrawReasonID,
        ClientWithdrawReasonName
FROM    [DWH_dbo].[Dim_ClientWithdrawReason]
ORDER BY ClientWithdrawReasonID;
```

### 7.2 Count withdrawals by customer-stated reason
```sql
SELECT  ISNULL(r.ClientWithdrawReasonName, 'Not specified') AS WithdrawReason,
        COUNT(*) AS WithdrawalCount
FROM    [DWH_dbo].[Fact_BillingWithdraw] f
LEFT JOIN [DWH_dbo].[Dim_ClientWithdrawReason] r
        ON f.ClientWithdrawReasonID = r.ClientWithdrawReasonID
GROUP BY r.ClientWithdrawReasonName
ORDER BY WithdrawalCount DESC;
```

### 7.3 Find competitor churn withdrawals
```sql
SELECT  f.WithdrawID,
        f.CID,
        f.Amount,
        r.ClientWithdrawReasonName
FROM    [DWH_dbo].[Fact_BillingWithdraw] f
JOIN    [DWH_dbo].[Dim_ClientWithdrawReason] r
        ON f.ClientWithdrawReasonID = r.ClientWithdrawReasonID
WHERE   r.ClientWithdrawReasonID IN (4, 5, 7)  -- dissatisfaction/churn signals
ORDER BY f.Amount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from upstream wiki (Dictionary.ClientWithdrawReason, quality 9.2/10) and SP_Dictionaries_DL_To_Synapse ETL analysis.

---

*Generated: 2026-03-19 | Quality: 8.6/10 (★★★★☆) | Phases: 7/14 (Simple-Dict Fast-Path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_ClientWithdrawReason | Type: Table | Production Source: etoro.Dictionary.ClientWithdrawReason*
