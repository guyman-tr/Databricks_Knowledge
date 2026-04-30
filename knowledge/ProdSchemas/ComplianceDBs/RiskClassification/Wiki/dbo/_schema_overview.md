# Schema Overview: RiskClassification.dbo

## Purpose

The `dbo` schema in the RiskClassification database implements a customer risk scoring system for AML/KYC compliance across multiple regulatory jurisdictions (CySEC, FCA, ASIC, FinCEN, FINRA, etc.). It calculates, stores, and serves per-customer risk classification scores based on ~45 individual risk parameters covering country of residence, age, income, occupation, screening status, and CySEC-specific Enhanced Due Diligence factors.

## Architecture

```
External Risk Engine
        |
        v
T_ScoresTemporary (staging)
        |
    P_RiskClassification (MERGE + PIVOT)
        |
   +----+----+
   |         |
T_Scores    T_RiskClassification
(normalized) (denormalized/wide)
   |         |
V_Scores    V_RiskClassification
(enriched)  (enriched + explanation + history)
   |         |
   +----+----+
        |
   Export Views
   (Synapse, DataLake, History)
```

## Data Flow

1. **External risk engine** calculates scores and loads them into `T_ScoresTemporary`
2. **P_RiskClassification** MERGEs staged scores into `T_Scores` (normalized), then PIVOTs into `T_RiskClassification` (wide-column, one row per customer)
3. **TruncateTempTable** clears the staging area
4. **V_Scores** and **V_RiskClassification** provide enriched views with regulation names, parameter names, risk level labels, score explanations, and previous-risk tracking
5. **Export views** (SynapseExport, DataLake, History) feed downstream analytics pipelines

## Key Tables

| Table | Purpose | Rows | Key |
|-------|---------|------|-----|
| T_RiskClassification | Main customer risk scores (wide-column, temporal) | ~5M | GCID |
| T_Scores | Normalized per-parameter scores (temporal) | ~222M | GCID + ParameterID |
| T_ScoresTemporary | Staging for new scores | Transient | GCID + ParameterID |
| RiskFix | Worklist of customers needing re-scoring | ~8K | GCID |
| ReplCheck_RiskClassification_etoro | Replication health sentinel | 1 | ID |

## Key Views

| View | Purpose | Base |
|------|---------|------|
| V_Scores | Enriched normalized scores with names | T_Scores + Dictionary |
| V_RiskClassification | Full customer risk profile with explanation | T_RiskClassification + V_Scores + Dictionary + History |
| V_RiskClassificationParameter | Scoring rules configuration matrix | BackOffice.RiskClassificationParameter + Dictionary |
| V_RiskClassificationDataLake | BI export with sanitized column names | T_RiskClassification (same as V_RiskClassification) |

## Cross-Schema Dependencies

- **Dictionary**: Regulation, RiskClassificationParameter, RiskClassificationRegulation, CySecRiskClassificationParameter
- **BackOffice**: RiskClassificationParameter (scoring rules configuration)
- **History**: T_RiskClassification, T_Scores, T_RiskClassification20200122, T_Scores20200122 (temporal history tables)

## Risk Scoring Model

- ~45 parameters, each scored 0/50/100 (Low/Medium/High)
- Two tiers: Standard (IDs 2-21, weighted) and CySEC EDD (IDs 1001-1025, zero weight)
- Final score mapped to named levels via Dictionary.RiskClassificationRegulation
- Score thresholds vary by regulation: CySEC/FCA use 6 tiers (Low through Unacceptable), US regulations use 4 tiers (Low through Block)
- Temporal versioning preserves full score change history

## Regulatory Jurisdictions

| ID | Name | Entity | Tiers |
|----|------|--------|-------|
| 1 | CySEC | eToro EU | 6 (Low to Unacceptable) |
| 2 | FCA | eToro UK | 6 (Low to Unacceptable) |
| 4 | ASIC | eToro AUS | 4 (Low to Block) |
| 7 | FinCEN | US AML | 4 (Low to Block) |
| 8 | FinCEN+FINRA | US combined | 4 (Low to Block) |
| 10 | ASIC & GAML | eToro AUS enhanced | 4 (Low to Block) |

---

*Generated: 2026-04-14 | Objects: 25 (7 tables, 8 views, 10 stored procedures) | Average quality: 8.2*
