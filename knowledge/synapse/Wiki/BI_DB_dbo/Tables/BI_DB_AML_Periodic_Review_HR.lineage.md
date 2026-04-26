# Lineage: BI_DB_dbo.BI_DB_AML_Periodic_Review_HR

**Writer SP**: `BI_DB_dbo.SP_AML_Periodic_Review @Date [DATE]`
**ETL Pattern**: TRUNCATE + INSERT (daily full refresh)
**Source DB**: Synapse sql_dp_prod_we (DWH_dbo + BI_DB_dbo + External schemas)

> HR shares all source objects with `BI_DB_AML_Periodic_Review_AR`. The only difference is the population filter applied before the final SELECT, and the addition of `Final_Decision`. See AR lineage for full source-object and column-lineage detail.

---

## Source Objects

Identical to `BI_DB_AML_Periodic_Review_AR` — all 14 source objects apply. See `BI_DB_AML_Periodic_Review_AR.lineage.md`.

Additional filter applied at population stage:
- `#risk_score.RiskScoreName = 'High'` (only High-risk customers)
- `Dim_Customer.PlayerStatusID IN (PlayerStatus 'Normal', 'Warning')` (no Block/other statuses)
- `Dim_Customer.FirstDepositDate <= @YearAgo_Date` (FTD older than 1 year — long-tenure high-risk customers)

---

## Column Lineage

Columns 1–43 and 45–46 are identical to `BI_DB_AML_Periodic_Review_AR`. Only the added column is listed below.

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 44 | Final_Decision | Derived | Multiple risk flags | CASE logic — see §2.5 of main wiki. Priority: Orange (doc expiry) > Red (risk hit) > Green (no flags). |

### Final_Decision Logic (Explicit)

```sql
Final_Decision = CASE
  WHEN Is_POI_ExpiryDate = 1 OR Is_POA_ExpiryDate = 1
    THEN 'Orange'
  WHEN IsHighRisk_Screening = 1
     OR (Is_High_Risk_SOF = 1 AND Has_Proof_Of_Income_FromLastYear = 0)
     OR Is_High_MOP_Deposit = 1
    THEN 'Red'
  ELSE 'Green'
END
```

**Priority rule**: Orange (document expiry) takes precedence over Red (risk indicators). A customer with expired documents AND sanctions hit → Orange, not Red.

---

## ETL Flow

```
[Identical to AR temp table build]
  → All shared temp tables: #risk_score, #fivetran, #evdate, #poi,
    #Q26_SOF, #mop, #Selfie, #bankIdent, #videoident, #Occupation,
    #ProofOfIncome, #amlSF, #Planned_Invested_Amount, #totalco,
    #login, #sofredflag

Additional population filter applied to #pop:
  → #pop2 = #pop JOIN #risk_score WHERE RiskScoreName='High'
             AND PlayerStatusID IN (Normal, Warning)
             AND Original_FTD <= @YearAgo_Date

Final_Decision CASE applied to #pop2 → #final_pop3

TRUNCATE BI_DB_AML_Periodic_Review_HR;
INSERT FROM #final_pop3 + Final_Decision + GETDATE() as UpdateDate

OpsDB: SP_AML_Periodic_Review | Priority 0 | Daily
```

*Batch 49 | Generated 2026-04-22*
