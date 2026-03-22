# DWH_dbo.Dim_MoveMoneyReason

> Lookup table for internal money movement reason codes - classifying why a credit/debit is a manual adjustment, staking reward, internal transfer, or recurring investment. DWH has 4 rows (IDs 1-4); production has 9 (IDs 1-9). MoveMoneyReasonID drives ActionTypeID derivation in Fact_CustomerAction.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.MoveMoneyReason (via Legacy DWH migration + manual updates) |
| **Refresh** | Partial/manual (4 rows current; 5 production rows missing from DWH) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (MoveMoneyReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason` |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

DWH_dbo.Dim_MoveMoneyReason enumerates the business reasons for internal money movements - balance credits and debits that are not standard customer deposits or withdrawals. These are recorded in the ActiveCredit system (History.ActiveCredit) and flow into DWH_dbo.Fact_CustomerAction via the MoveMoneyReasonID column passthrough.

In production, Dictionary.MoveMoneyReason has 9 reason codes spanning manual adjustments, bonus abuse reversals, crypto staking rewards, internal account transfers, and recurring automated investments. The DWH version is a truncated 4-row table covering only IDs 1-3 (Adjustment, Bonus Abuser, Staking) and ID 4 (Airdrop - which production marks as "missing/deprecated").

Critical gap: MoveMoneyReasonID=5 (InternalTransfer Trade) is used by SP_Fact_CustomerAction to classify ActionTypeID 44 (internal deposit) and 45 (internal withdrawal), but ID=5 does NOT appear in this DWH lookup table. Fact_CustomerAction rows with MoveMoneyReasonID=5 will not find a match in a JOIN to Dim_MoveMoneyReason.

No automated ETL pipeline writes to this table. UpdateDate values (2022-03-27 for IDs 1-3, 2022-11-13 for ID 4) suggest periodic manual DBA inserts rather than pipeline-driven refresh.

---

## 2. Business Logic

### 2.1 Money Movement Reason Classification

**What**: Classifies internal financial credits/debits by their business justification.

**Columns Involved**: `MoveMoneyReasonID`, `MoveMoneyReason`

**Rules** (DWH rows in DWH, production values from upstream wiki):

DWH rows (IDs 1-4):
- ID=1 (Adjustment): Manual balance correction by operations/compliance staff
- ID=2 (Bonus Abuser): Clawback of bonus funds from customers flagged for bonus abuse
- ID=3 (Staking): Crypto staking reward credits
- ID=4 (Airdrop): Airdrop credit - DWH-only label; production marks ID=4 as "missing/deprecated"

Production rows missing from DWH (Tier 1 from upstream wiki):
- ID=5 (InternalTransfer Trade): Inter-account transfer from a trading operation
- ID=6 (InternalTransfer): General inter-account transfer
- ID=7 (Not In Use): Reserved/deprecated placeholder
- ID=8 (Recurring Deposit): Automated periodic deposit from linked payment method
- ID=9 (Recurring Investment): Automated periodic investment allocation

**Diagram**:
```
MoveMoneyReasonID -> MoveMoneyReason (in DWH)
  1 -> Adjustment           (manual correction)
  2 -> Bonus Abuser         (abuse clawback)
  3 -> Staking              (crypto staking reward)
  4 -> Airdrop              (DWH-only label; deprecated in production)

Missing from DWH (in production):
  5 -> InternalTransfer Trade  (USED in SP_Fact_CustomerAction for ActionType 44/45)
  6 -> InternalTransfer
  7 -> Not In Use
  8 -> Recurring Deposit
  9 -> Recurring Investment
```

### 2.2 Impact on Fact_CustomerAction ActionTypeID Derivation

**What**: MoveMoneyReasonID=5 controls the final ActionTypeID assigned to Fact_CustomerAction rows.

**Columns Involved**: `MoveMoneyReasonID` (in fact) + CreditTypeID

**Rules**:
- When CreditTypeID=1 AND MoveMoneyReasonID<>5 -> ActionTypeID=7 (standard deposit)
- When CreditTypeID=1 AND MoveMoneyReasonID=5 -> ActionTypeID=44 (internal deposit)
- When CreditTypeID=2 AND MoveMoneyReasonID<>5 -> ActionTypeID=8 (standard withdrawal)
- When CreditTypeID=2 AND MoveMoneyReasonID=5 -> ActionTypeID=45 (internal withdrawal)

Note: Even though ID=5 is absent from Dim_MoveMoneyReason, the raw MoveMoneyReasonID=5 value flows from History_Credit to Fact_CustomerAction. This dimension is a decode reference for analysts; the SP uses raw integers for ActionType logic.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is REPLICATE-distributed with a CLUSTERED INDEX on `MoveMoneyReasonID ASC`. At 4 rows, REPLICATE gives each compute node a local copy for zero-movement JOINs.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, stored as Delta (MANAGED), no partitioning. Full scan is optimal at 4 rows.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode money movement reason in Fact_CustomerAction | LEFT JOIN DWH_dbo.Dim_MoveMoneyReason ON MoveMoneyReasonID |
| Find all adjustment credits | WHERE MoveMoneyReasonID = 1 (Adjustment) |
| Find staking credits | WHERE MoveMoneyReasonID = 3 (Staking) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_CustomerAction | ON f.MoveMoneyReasonID = d.MoveMoneyReasonID | Decode reason code for money movement analysis |

### 3.4 Gotchas

- **Missing IDs 5-9**: Only IDs 1-4 exist in DWH. Production has 9 codes. MoveMoneyReasonID=5 (InternalTransfer Trade) appears in Fact_CustomerAction but has no match in this table - always use LEFT JOIN.
- **ID=4 "Airdrop" mismatch**: Production wiki says ID=4 is "missing/deprecated" but DWH has it as "Airdrop". This is a DWH-specific label.
- **UpdateDate inconsistency**: ID=4 (Airdrop) was added 2022-11-13, 8 months after IDs 1-3. Suggests manual inserts over time.
- **Not a pipeline source**: MoveMoneyReasonID in Fact_CustomerAction comes from History_Credit passthrough, not from this dimension at ETL time. This table is for analyst decoding only.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Description |
|-------|------|-----|-------------|
| **5 stars** | Tier 5 | `(Tier 5 - domain expert)` | Domain expert confirmed |
| **4 stars** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Upstream production wiki verbatim |
| **3 stars** | Tier 2 | `(Tier 2 - ...)` | Synapse SP code or migration DDL |
| **2 stars** | Tier 3 | `(Tier 3 - ...)` | Live data sampling or DDL structure |
| **1 star** | Tier 4 | `[UNVERIFIED] (Tier 4 - inferred)` | Inferred from column name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MoveMoneyReasonID | int | YES | Internal money movement reason identifier. DWH values: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 4=Airdrop (DWH-only label). Production has additional IDs 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment - all absent from DWH. ID=5 is critical: used in SP_Fact_CustomerAction to derive ActionTypeID 44 (internal deposit) and 45 (internal withdrawal). (Tier 1 - upstream wiki, Dictionary.MoveMoneyReason) |
| 2 | MoveMoneyReason | varchar(30) | YES | Human-readable money movement reason label. DWH labels: Adjustment, Bonus Abuser, Staking, Airdrop. Column name intentionally matches table name (denormalized pattern per upstream wiki). Used in financial reporting and account statements. Note: DWH label "Airdrop" for ID=4 diverges from production where ID=4 is marked deprecated. (Tier 1 - upstream wiki, Dictionary.MoveMoneyReason + Tier 3 - live data sampling) |
| 3 | UpdateDate | datetime | YES | Last update timestamp for the row. IDs 1-3: 2022-03-27 (initial load batch); ID 4: 2022-11-13 (added 8 months later). Suggests manual DBA inserts; not populated by an automated pipeline. Not present in production Dictionary.MoveMoneyReason (DWH-specific audit field). (Tier 3 - live data sampling) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| MoveMoneyReasonID | etoro.Dictionary.MoveMoneyReason | MoveMoneyReasonID | passthrough (4 of 9 IDs in DWH) |
| MoveMoneyReason | etoro.Dictionary.MoveMoneyReason | MoveMoneyReason | passthrough (4 of 9 values; ID=4 label diverges) |
| UpdateDate | DWH ETL / Manual DBA | - | ETL-computed (not in production source; manual timestamps) |

Note: DWH receives MoveMoneyReasonID as a passthrough from etoro.History.ActiveCredit -> DWH_staging.etoro_History_Credit into Fact_CustomerAction. Dim_MoveMoneyReason itself is populated via one-time migration + manual inserts, NOT via an active ETL pipeline.

### 5.2 ETL Pipeline

```
etoro.Dictionary.MoveMoneyReason (production, 9 rows)
  -> Generic Pipeline (ID ???) -> Bronze/etoro/Dictionary/MoveMoneyReason/ [not confirmed consumed by DWH]
  -> Legacy DWH SQL Server (partial snapshot, 2022)
       -> DWH_Migration.Dim_MoveMoneyReason (NoDbObjectsScripts, 2024-09-16)
            -> DWH_dbo.Dim_MoveMoneyReason (4 rows, no active ETL refresh)

etoro.History.ActiveCredit (production)
  -> DWH_staging.etoro_History_Credit (Generic Pipeline, daily)
       -> SP_Fact_CustomerAction / SP_Fact_CustomerAction_DL_To_Synapse
            -> DWH_dbo.Fact_CustomerAction.MoveMoneyReasonID (raw passthrough)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.MoveMoneyReason | Production reason code master (9 rows) |
| Legacy | Legacy DWH SQL Server | Historical DWH dimension (partial, 2022 snapshot) |
| Migration | DWH_Migration.Dim_MoveMoneyReason | One-time migration staging DDL |
| Target | DWH_dbo.Dim_MoveMoneyReason | Current Synapse dimension (4 rows, manually maintained) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| (none) | - | Leaf dimension - no foreign keys |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_CustomerAction | MoveMoneyReasonID | Fact table stores raw MoveMoneyReasonID from History_Credit; analyst JOIN to Dim_MoveMoneyReason for decoding |
| DWH_dbo.SP_Fact_CustomerAction | MoveMoneyReasonID | Uses MoveMoneyReasonID=5 (absent from DWH dim) as switch to derive ActionTypeID 44/45 |
| DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse | MoveMoneyReasonID | Passes MoveMoneyReasonID from etoro_History_Credit into Fact_CustomerAction |

---

## 7. Sample Queries

### 7.1 All DWH money movement reasons
```sql
SELECT MoveMoneyReasonID, MoveMoneyReason, UpdateDate
FROM [DWH_dbo].[Dim_MoveMoneyReason]
ORDER BY MoveMoneyReasonID;
```

### 7.2 Decode MoveMoneyReason in customer actions (LEFT JOIN for missing IDs)
```sql
SELECT
    f.CID,
    f.Occurred,
    f.Credit,
    f.ActionTypeID,
    COALESCE(mmr.MoveMoneyReason, 'ID=' + CAST(f.MoveMoneyReasonID AS varchar)) AS ReasonLabel
FROM [DWH_dbo].[Fact_CustomerAction] f
LEFT JOIN [DWH_dbo].[Dim_MoveMoneyReason] mmr ON f.MoveMoneyReasonID = mmr.MoveMoneyReasonID
WHERE f.MoveMoneyReasonID IS NOT NULL
ORDER BY f.Occurred DESC;
```

### 7.3 Unmatched MoveMoneyReasonIDs (fact rows with no dim match)
```sql
SELECT DISTINCT f.MoveMoneyReasonID, COUNT(*) AS FactRows
FROM [DWH_dbo].[Fact_CustomerAction] f
LEFT JOIN [DWH_dbo].[Dim_MoveMoneyReason] mmr ON f.MoveMoneyReasonID = mmr.MoveMoneyReasonID
WHERE f.MoveMoneyReasonID IS NOT NULL AND mmr.MoveMoneyReasonID IS NULL
GROUP BY f.MoveMoneyReasonID
ORDER BY FactRows DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped - Atlassian MCP unavailable this session.)

---

*Generated: 2026-03-18 | Quality: 7.3/10 (★★★★☆) | Phases: 11/14*
*Tiers: 2 T1, 0 T2, 1 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 8/10*
*Object: DWH_dbo.Dim_MoveMoneyReason | Type: Table | Production Source: etoro.Dictionary.MoveMoneyReason (truncated 2022 snapshot, 4 of 9 IDs)*
