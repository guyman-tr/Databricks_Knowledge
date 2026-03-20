# DWH_dbo.Dim_RedeemReason

> Lookup table classifying why a copy-fund exit (redeem) failed, was rejected, or was cancelled - covering pre-validation blocks, processing failures, operational decisions, and technical errors.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.RedeemReason |
| **Refresh** | Daily via SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (RedeemReasonID ASC) |
| | |
| **UC Target** | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason |
| **UC Format** | Parquet |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | Gold (Synapse export) |

---

## 1. Business Meaning

Dim_RedeemReason classifies why a redeem (copy-fund exit / CopyTrading liquidation) failed, was rejected, or was cancelled. When a copier exits a copy relationship, the system must close positions, calculate final value, and transfer funds - this multi-step process can fail at various points. The RedeemReasonID explains what went wrong or why the operation was blocked. (Tier 1 - upstream wiki, Dictionary.RedeemReason)

The reasons fall into several categories: pre-validation blocks (trade blocked, funding blocked, dispute, internal user, verification level), processing failures (failed by trading, failed by wallet, server errors), operational decisions (rejected by ops, canceled by ops, canceled by user), and technical errors (data integrity, DB error, NWA validation). ID 20 (TransferNegativeBalanceTerminated) handles copy exits terminated due to negative balance conditions. (Tier 1 - upstream wiki, Dictionary.RedeemReason)

Loaded daily by SP_Dictionaries_DL_To_Synapse via TRUNCATE+INSERT from DWH_staging.etoro_Dictionary_RedeemReason. The DWH version has 19 rows (IDs 1-20, gap at 17); the production wiki documented 18 rows (gaps at 17 and 19). DWH now includes ID 19 (FailedByDelta) which was added after the upstream wiki was written. The DWH drops Description (always NULL in production) and DisplayName (duplicates Name) from the source, renaming Name to RedeemReasonName.

---

## 2. Business Logic

### 2.1 Reason Categories

**What**: Redeem failure/rejection reasons grouped by cause type.

**Columns Involved**: `RedeemReasonID`, `RedeemReasonName`

**Rules**:
- Pre-Validation Blocks (IDs 1-5, 16): Customer doesn't meet requirements for redemption
- Processing Failures (IDs 8-9, 11-14): Technical or system failures during processing
- Operational Decisions (IDs 7, 10, 15, 18): Human or automated cancellations
- Data Issues (ID 6): ValidationDataIntegrity - data consistency check failed
- Trading-Specific (ID 19): FailedByDelta - Delta product-specific failure
- Special (ID 20): TransferNegativeBalanceTerminated

**Diagram**:
```
Pre-Validation Blocks:
  1=RreTradeBlocked, 2=RreFundingBlocked, 3=RreDisputeProcess
  4=RreInternalUser, 5=RreVerificationLevel, 16=NwaValidation

Processing Failures:
  8=FailedByTrading, 9=FailedByWallet, 19=FailedByDelta (DWH-only)
  11=ServerErrorTrading, 12=ServerErrorWallet, 13=ServerErrorSettings, 14=DbError

Operational Decisions:
  7=RejectedByOps, 10=CanceledByOps, 15=CanceledByUser, 18=CancelledByTrading

Data Issues: 6=ValidationDataIntegrity
Special:     20=TransferNegativeBalanceTerminated
Gaps:        ID 17 skipped
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with CLUSTERED INDEX on RedeemReasonID. With 19 rows, REPLICATE is optimal. Join on RedeemReasonID directly.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, the Gold export at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason` is Parquet. With 19 rows, read the entire table without filtering.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve RedeemReasonID to name in Fact_BillingRedeem | `LEFT JOIN DWH_dbo.Dim_RedeemReason rr ON fbr.RedeemReasonID = rr.RedeemReasonID` |
| Count redeems by failure category | Group by RedeemReasonName, use CASE to assign category |
| Operational cancellations only | `WHERE RedeemReasonID IN (7, 10, 15, 18)` |
| Technical failures only | `WHERE RedeemReasonID IN (8, 9, 11, 12, 13, 14, 19)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_BillingRedeem | ON fbr.RedeemReasonID = rr.RedeemReasonID | Resolve redeem failure reason names |

### 3.4 Gotchas

- **ID 17 is skipped**: Gap in the sequence between IDs 16 and 18. This is a production-side gap, not a DWH issue.
- **ID 19 (FailedByDelta) is in DWH but not in upstream wiki**: The upstream wiki was written before Delta product was added. DWH data is more current on this entry.
- **Name prefixes are internal codes**: "Rre" prefix = Redeem Rejection, not a human-readable label. For reporting, consider mapping to business-friendly labels.
- **DisplayName dropped**: Production DisplayName duplicates Name for all rows. DWH correctly omits it.
- **UpdateDate 2026-03-11**: 7 days stale as of session date. Follows the SP_Dictionaries_DL_To_Synapse batch schedule.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 - Upstream wiki verbatim | `(Tier 1 - upstream wiki, Dictionary.RedeemReason)` |
| ★★★☆☆ | Tier 2 - Synapse SP code | `(Tier 2 - SP code)` |
| ★★☆☆☆ | Tier 3 - Live data | `(Tier 3 - live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RedeemReasonID | int | YES | Primary key identifying the failure/rejection reason (DDL nullable - PK not enforced). Range 1-20, gaps at 17. Referenced by Fact_BillingRedeem.RedeemReasonID. (Tier 1 - upstream wiki, Dictionary.RedeemReason) |
| 2 | RedeemReasonName | varchar(50) | YES | Internal reason code name. DWH note: renamed from Name in production source. Prefix convention: Rre = Redeem Rejection, ServerError = service failure, Failed = processing failure. Values: RreTradeBlocked(1), RreFundingBlocked(2), RreDisputeProcess(3), RreInternalUser(4), RreVerificationLevel(5), ValidationDataIntegrity(6), RejectedByOps(7), FailedByTrading(8), FailedByWallet(9), CanceledByOps(10), ServerErrorTrading(11), ServerErrorWallet(12), ServerErrorSettings(13), DbError(14), CanceledByUser(15), NwaValidation(16), CancelledByTrading(18), FailedByDelta(19), TransferNegativeBalanceTerminated(20). (Tier 1 - upstream wiki, Dictionary.RedeemReason) |
| 3 | UpdateDate | datetime | YES | ETL reload timestamp - set to GETDATE() by SP_Dictionaries_DL_To_Synapse on each daily reload. Not a business date. Current value: 2026-03-11. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RedeemReasonID | etoro.Dictionary.RedeemReason | RedeemReasonID | passthrough |
| RedeemReasonName | etoro.Dictionary.RedeemReason | Name | rename (Name -> RedeemReasonName) |
| UpdateDate | - | - | ETL-computed: GETDATE() |

Full production documentation: see upstream wiki Dictionary/Tables/Dictionary.RedeemReason.md

### 5.2 ETL Pipeline

```
etoro.Dictionary.RedeemReason -> Generic Pipeline -> Bronze -> DWH_staging.etoro_Dictionary_RedeemReason -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_RedeemReason
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.RedeemReason | 18 rows in production (upstream wiki); DWH has 19 (FailedByDelta added) |
| Staging | DWH_staging.etoro_Dictionary_RedeemReason | Raw import from Generic Pipeline |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Drops Description and DisplayName. Renames Name -> RedeemReasonName. |
| Target | DWH_dbo.Dim_RedeemReason | 19 rows |
| Export | Generic Pipeline (daily) | dwh.gold_sql_dp_prod_we_dwh_dbo_dim_redeemreason |

---

## 6. Relationships

### 6.1 References To (this object points to)

N/A - no foreign key columns.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_BillingRedeem | RedeemReasonID | Billing redeem transactions reference the failure/rejection reason |

---

## 7. Sample Queries

### 7.1 All redeem reasons with categories
```sql
SELECT
    RedeemReasonID,
    RedeemReasonName,
    CASE
        WHEN RedeemReasonID IN (1,2,3,4,5,16) THEN 'Pre-Validation Block'
        WHEN RedeemReasonID IN (8,9,11,12,13,14,19) THEN 'Processing Failure'
        WHEN RedeemReasonID IN (7,10,15,18) THEN 'Operational Decision'
        WHEN RedeemReasonID = 6 THEN 'Data Issue'
        WHEN RedeemReasonID = 20 THEN 'Special'
        ELSE 'Unknown'
    END AS Category
FROM [DWH_dbo].[Dim_RedeemReason]
ORDER BY RedeemReasonID
```

### 7.2 Count redeems by failure reason
```sql
SELECT
    rr.RedeemReasonName,
    COUNT(*) AS redeem_count
FROM [DWH_dbo].[Fact_BillingRedeem] fbr
LEFT JOIN [DWH_dbo].[Dim_RedeemReason] rr
    ON fbr.RedeemReasonID = rr.RedeemReasonID
GROUP BY rr.RedeemReasonName
ORDER BY redeem_count DESC
```

### 7.3 Operational cancellations in the last 30 days
```sql
SELECT
    fbr.CID,
    fbr.RedeemDateID,
    rr.RedeemReasonName
FROM [DWH_dbo].[Fact_BillingRedeem] fbr
JOIN [DWH_dbo].[Dim_RedeemReason] rr
    ON fbr.RedeemReasonID = rr.RedeemReasonID
WHERE rr.RedeemReasonID IN (7, 10, 15, 18)
  AND fbr.RedeemDateID >= CONVERT(INT, CONVERT(VARCHAR(8), DATEADD(DAY,-30,GETDATE()), 112))
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-19 | Quality: 8.5/10 (★★★★☆) | Phases: 7/14 (fast-path)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 9/10*
*Object: DWH_dbo.Dim_RedeemReason | Type: Table | Production Source: etoro.Dictionary.RedeemReason*
