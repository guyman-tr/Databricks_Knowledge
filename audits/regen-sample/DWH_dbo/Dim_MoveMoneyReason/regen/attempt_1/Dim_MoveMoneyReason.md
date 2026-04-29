# DWH_dbo.Dim_MoveMoneyReason

> 4-row dictionary dimension classifying the business reasons for internal money movements (balance adjustments, staking, bonus abuse reversals) sourced from `etoro.Dictionary.MoveMoneyReason` via the Generic Pipeline. Last updated 2022-11-13. Replicated distribution.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.Dictionary.MoveMoneyReason` via Generic Pipeline (Override, daily) |
| **Refresh** | Daily (Override, 1440 min) via Generic Pipeline through `DWH_staging.etoro_Dictionary_MoveMoneyReason` |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (MoveMoneyReasonID ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override) |

---

## 1. Business Meaning

Dim_MoveMoneyReason is a small dictionary dimension (4 rows) that enumerates the valid business justifications for internal money movements recorded in the ActiveCredit ledger system. These are non-standard deposits/withdrawals: manual balance adjustments, bonus abuse clawbacks, crypto staking credits, and airdrops.

The table is sourced from `etoro.Dictionary.MoveMoneyReason` on etoroDB-REAL, loaded daily via the Generic Pipeline through `DWH_staging.etoro_Dictionary_MoveMoneyReason`. No dedicated writer SP exists in DWH_dbo; the load is handled by the generic dictionary pipeline.

The DWH copy currently holds only 4 of the 9+ reason codes in production (IDs 1-4). IDs 5-9 (InternalTransfer Trade, InternalTransfer, Not In Use, Recurring Deposit, Recurring Investment) exist in production but are absent from the DWH — the staging load or the load process may be filtering or the production table was truncated at the time of last sync. All rows have UpdateDate in 2022, indicating the table has not been refreshed recently.

Referenced by `DWH_dbo.Fact_CustomerAction` via `SP_Fact_CustomerAction` and `SP_Fact_CustomerAction_DL_To_Synapse` for classifying credit history reason codes.

---

## 2. Business Logic

### 2.1 Money Movement Reason Codes

**What**: Classifies non-standard financial operations into named categories.
**Columns Involved**: `MoveMoneyReasonID`, `MoveMoneyReason`
**Rules**:
- 1 = Adjustment — manual balance correction by operations/compliance staff
- 2 = Bonus Abuser — clawback of bonus funds from customers flagged for bonus abuse
- 3 = Staking — crypto staking reward credits
- 4 = Airdrop — crypto airdrop credits (present in DWH; production wiki noted ID 4 as missing/deprecated, suggesting it was added or repurposed)

### 2.2 Data Staleness

**What**: The DWH copy is significantly behind the production source.
**Columns Involved**: `UpdateDate`
**Rules**:
- Production `Dictionary.MoveMoneyReason` contains at least 9 reason codes (IDs 1-3, 5-9)
- DWH contains only 4 (IDs 1-4), with ID 4 = Airdrop not documented in the upstream wiki
- All UpdateDate values are from 2022, indicating no recent refresh has modified rows

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE distribution — the table is copied to every compute node. Ideal for small lookups. Clustered index on `MoveMoneyReasonID` supports fast point lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What are the valid move money reasons? | `SELECT * FROM DWH_dbo.Dim_MoveMoneyReason ORDER BY MoveMoneyReasonID` |
| How many customer actions per reason? | JOIN to `Fact_CustomerAction` on `MoveMoneyReasonID` with GROUP BY |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_CustomerAction | `ON f.MoveMoneyReasonID = d.MoveMoneyReasonID` | Resolve reason labels for credit/debit actions |

### 3.4 Gotchas

- Only 4 of 9+ production reason codes are present in the DWH — queries filtering on IDs 5-9 will return no matches
- ID 4 (Airdrop) exists in DWH but is not documented in the upstream production wiki (may be a recent addition or repurpose)
- All three columns are nullable despite MoveMoneyReasonID serving as the logical PK
- UpdateDate reflects the last ETL load time per row, not the business event time

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from ETL/SP code |
| Tier 3 | No upstream source; described from DDL + data evidence |
| Tier 4 | Inferred from name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | MoveMoneyReasonID | int | YES | Unique identifier for the money movement reason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer, 7=Not In Use, 8=Recurring Deposit, 9=Recurring Investment. Gap at ID 4. Referenced by 50+ credit/balance procedures. (Tier 1 — Dictionary.MoveMoneyReason) |
| 2 | MoveMoneyReason | varchar(30) | YES | Human-readable reason label. Note: column name matches table name (denormalized pattern). Displayed in account statements, credit history, and BackOffice audit screens. (Tier 1 — Dictionary.MoveMoneyReason) |
| 3 | UpdateDate | datetime | YES | ETL-added timestamp recording when each row was last loaded or refreshed by the generic dictionary pipeline. Not present in the production source table. (Tier 2 — Generic Pipeline ETL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| MoveMoneyReasonID | Dictionary.MoveMoneyReason | MoveMoneyReasonID | Passthrough |
| MoveMoneyReason | Dictionary.MoveMoneyReason | MoveMoneyReason | Passthrough |
| UpdateDate | — | — | ETL-added (GETDATE() at load time) |

### 5.2 ETL Pipeline

```
etoro.Dictionary.MoveMoneyReason (production, etoroDB-REAL)
  |-- Generic Pipeline (Bronze export, Override, daily) ---|
  v
Bronze/etoro/Dictionary/MoveMoneyReason/ (parquet)
  |-- Generic Pipeline (staging load) ---|
  v
DWH_staging.etoro_Dictionary_MoveMoneyReason (2 cols)
  |-- Generic dictionary load (adds UpdateDate) ---|
  v
DWH_dbo.Dim_MoveMoneyReason (4 rows, 3 cols)
  |-- Generic Pipeline (Gold export, Override, daily) ---|
  v
dwh.gold_sql_dp_prod_we_dwh_dbo_dim_movemoneyreason
```

---

## 6. Relationships

### 6.1 References To (this object points to)

This object has no outgoing foreign key references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DWH_dbo.Fact_CustomerAction | MoveMoneyReasonID | Implicit FK | Classifies the reason for credit/debit customer actions |
| DWH_dbo.SP_Fact_CustomerAction | MoveMoneyReasonID | SP reference | Writer SP for Fact_CustomerAction reads MoveMoneyReasonID |
| DWH_dbo.SP_Fact_CustomerAction_DL_To_Synapse | MoveMoneyReasonID | SP reference | Data lake loader for Fact_CustomerAction references MoveMoneyReasonID |

---

## 7. Sample Queries

### 7.1 List all move money reasons in DWH
```sql
SELECT  MoveMoneyReasonID,
        MoveMoneyReason,
        UpdateDate
FROM    DWH_dbo.Dim_MoveMoneyReason
ORDER BY MoveMoneyReasonID;
```

### 7.2 Count customer actions by move money reason
```sql
SELECT  d.MoveMoneyReason,
        COUNT(*) AS ActionCount
FROM    DWH_dbo.Fact_CustomerAction f
JOIN    DWH_dbo.Dim_MoveMoneyReason d
        ON f.MoveMoneyReasonID = d.MoveMoneyReasonID
WHERE   f.MoveMoneyReasonID IS NOT NULL
GROUP BY d.MoveMoneyReason
ORDER BY ActionCount DESC;
```

### 7.3 Find actions with reason codes missing from dim
```sql
SELECT  DISTINCT f.MoveMoneyReasonID
FROM    DWH_dbo.Fact_CustomerAction f
WHERE   f.MoveMoneyReasonID IS NOT NULL
        AND f.MoveMoneyReasonID NOT IN (
            SELECT MoveMoneyReasonID
            FROM DWH_dbo.Dim_MoveMoneyReason
            WHERE MoveMoneyReasonID IS NOT NULL
        );
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Tiers: 2 T1, 1 T2, 0 T3, 0 T4, 0 T5 | Elements: 3/3, Logic: 9/10, Relationships: 8/10, Sources: 7/10*
*Object: DWH_dbo.Dim_MoveMoneyReason | Type: Table | Production Source: etoro.Dictionary.MoveMoneyReason*
