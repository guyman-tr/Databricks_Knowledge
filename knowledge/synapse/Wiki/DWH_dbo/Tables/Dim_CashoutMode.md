# DWH_dbo.Dim_CashoutMode

> Lookup dimension defining the 4 withdrawal processing modes -- Manual, Auto Create, Mass Auto Create, and Instant Withdrawal -- with priority weights. Sourced daily from etoro.Dictionary.CashoutMode via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.CashoutMode |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (CashoutModeID) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_CashoutMode is the DWH version of etoro.Dictionary.CashoutMode. It classifies how a withdrawal request is processed -- whether it requires manual operator intervention, is automatically created and queued, is part of a mass automated batch, or is processed instantly.

The CashoutModeWeight establishes processing priority -- higher weights get processed first. Instant Withdrawal (weight 30) takes precedence over Mass Auto Create (20), Auto Create (10), and Manual (0). The CashoutModeID is stored on withdrawal transaction records and flows through to BackOffice reporting and payout processing systems.

Source: etoro.Dictionary.CashoutMode on etoroDB-REAL. Exported daily to Bronze/etoro/Dictionary/CashoutMode/ and staged into DWH_staging.etoro_Dictionary_CashoutMode. SP_Dictionaries_DL_To_Synapse loads using TRUNCATE + INSERT; all 3 production columns are passthrough; UpdateDate = GETDATE().

4 rows: IDs 0-3.

---

## 2. Business Logic

### 2.1 Withdrawal Processing Modes

**What**: The four modes of withdrawal processing, ordered by automation level and priority.

**Columns Involved**: `CashoutModeID`, `CashoutModeName`, `CashoutModeWeight`

| CashoutModeID | CashoutModeName | CashoutModeWeight | Meaning |
|---|---|---|---|
| 0 | Manual | 0 | Requires manual BackOffice operator processing. Lowest priority. Used for complex cases, large amounts, flagged accounts, or investigation-required withdrawals. |
| 1 | Auto Create | 10 | System automatically creates and queues the withdrawal. Standard automated flow for routine withdrawals. |
| 2 | Mass Auto Create | 20 | Batch automated processing -- multiple withdrawals grouped for efficient bulk execution. Higher priority than individual Auto Create. |
| 3 | Instant Withdrawal | 30 | Real-time processing -- withdrawal executed immediately. Highest priority. Customer receives funds within minutes. Premium feature. |

**Priority rule**: Higher CashoutModeWeight = processed first. Payout processing systems use this weight to prioritize execution queues.

### 2.2 Mode Assignment

**What**: The cashout mode is determined at withdrawal creation time based on customer eligibility.

**Rules**:
- Mode set when withdrawal is created (Billing.WithdrawToFundingAdd / BackOffice.WithdrawToFundingAdd)
- Instant Withdrawal (3) requires: verified customer, eligible funding type, amount within limits
- BackOffice operators can override to Manual (0) for investigation
- Mode stored on Billing.WithdrawToFunding (main withdrawal table)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE distributed with a CLUSTERED INDEX on CashoutModeID. Correct for a 4-row lookup -- eliminates JOIN data movement.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed for 4 rows. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Withdrawal volume by processing mode | JOIN withdrawal fact ON CashoutModeID, GROUP BY CashoutModeName |
| Instant withdrawal adoption rate | COUNT WHERE CashoutModeID = 3 / total withdrawals |
| Manual vs automated split | CASE WHEN CashoutModeID = 0 THEN 'Manual' ELSE 'Automated' END |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH withdrawal fact tables | ON CashoutModeID | Resolve mode name and weight for each withdrawal |

### 3.4 Gotchas

- **CashoutModeID starts at 0**: ID=0 is a legitimate value (Manual mode), not a placeholder. This differs from most DWH Dim_ tables where ID=0 is an N/A placeholder.
- **All columns nullable in DWH DDL**: Despite NOT NULL constraints in production (CashoutModeID and CashoutModeName are NOT NULL), the DWH DDL allows NULLs for all columns.
- **CashoutModeWeight DEFAULT 100 in production**: The production DEFAULT is 100, meaning new modes added in the future would have weight 100 (highest priority) by default. The current 4 values use 0/10/20/30.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 4 stars | Tier 1 - upstream wiki verbatim | (Tier 1 - upstream wiki, Dictionary.CashoutMode) |
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CashoutModeID | tinyint | YES | Primary key identifying the withdrawal processing mode. 0=Manual, 1=Auto Create, 2=Mass Auto Create, 3=Instant Withdrawal. Stored on withdrawal transaction records (Billing.WithdrawToFunding). Note: ID=0 is a legitimate value (Manual mode), NOT a DWH placeholder. (Tier 1 - upstream wiki, Dictionary.CashoutMode) |
| 2 | CashoutModeName | varchar(50) | YES | Human-readable mode name. 'Manual', 'Auto Create', 'Mass Auto Create', 'Instant Withdrawal'. Used in BackOffice withdrawal management screens and payout processing reports. (Tier 1 - upstream wiki, Dictionary.CashoutMode) |
| 3 | CashoutModeWeight | int | YES | Processing priority weight. Higher values are processed first: 0=Manual (lowest), 10=Auto Create, 20=Mass Auto Create, 30=Instant Withdrawal (highest). Used by payout processing to determine execution order. (Tier 1 - upstream wiki, Dictionary.CashoutMode) |
| 4 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CashoutModeID | etoro.Dictionary.CashoutMode | CashoutModeID | Passthrough |
| CashoutModeName | etoro.Dictionary.CashoutMode | CashoutModeName | Passthrough |
| CashoutModeWeight | etoro.Dictionary.CashoutMode | CashoutModeWeight | Passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
etoro.Dictionary.CashoutMode -> Generic Pipeline (daily, Override) -> Bronze/etoro/Dictionary/CashoutMode/ -> DWH_staging.etoro_Dictionary_CashoutMode -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_CashoutMode
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.CashoutMode | 4-row processing mode catalog (etoroDB-REAL) |
| Lake | Bronze/etoro/Dictionary/CashoutMode/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.etoro_Dictionary_CashoutMode | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; all 3 production columns passthrough; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_CashoutMode | 4 rows (IDs 0-3) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CashoutModeID | etoro.Dictionary.CashoutMode | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH withdrawal fact tables | CashoutModeID | Resolve processing mode for each withdrawal transaction |

---

## 7. Sample Queries

### 7.1 List all processing modes by priority

```sql
SELECT CashoutModeID, CashoutModeName, CashoutModeWeight
FROM [DWH_dbo].[Dim_CashoutMode]
ORDER BY CashoutModeWeight DESC
-- Returns: Instant Withdrawal (30), Mass Auto Create (20), Auto Create (10), Manual (0)
```

### 7.2 Withdrawal volume by mode (illustrative)

```sql
SELECT
    dcm.CashoutModeName,
    dcm.CashoutModeWeight AS Priority,
    COUNT(*) AS WithdrawalCount
FROM [DWH_dbo].[Fact_Withdrawal] fw    -- adjust to actual fact table name
JOIN [DWH_dbo].[Dim_CashoutMode] dcm ON fw.CashoutModeID = dcm.CashoutModeID
GROUP BY dcm.CashoutModeName, dcm.CashoutModeWeight
ORDER BY dcm.CashoutModeWeight DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP not available.)

---

*Generated: 2026-03-18 | Quality: 8.5/10 (4 stars) | Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)*
*Tiers: 3 T1, 1 T2, 0 T3, 0 T4-Inferred, 0 T5 | Elements: 10.0/10, Logic: 9.0/10, Relationships: 5.0/10, Sources: 9.0/10*
*Object: DWH_dbo.Dim_CashoutMode | Type: Table | Production Source: etoro.Dictionary.CashoutMode*
