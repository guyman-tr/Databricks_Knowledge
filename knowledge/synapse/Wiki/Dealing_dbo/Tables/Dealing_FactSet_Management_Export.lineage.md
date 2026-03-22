# Lineage — Dealing_dbo.Dealing_FactSet_Management_Export

## Source Mapping

| Layer | Object | Method |
|-------|--------|--------|
| **Gold (Data Lake)** | `Gold/Dealing/FactSet_stg/Dealing_FactSet_Management_Export/*.parquet` | External table (Synapse PolyBase) |
| **Databricks** | Unknown pipeline | Produces parquet files in Gold layer |

## Column Lineage

| Column | Source | Confidence |
|--------|--------|------------|
| CID | Gold parquet → unknown upstream | Tier 3 |
| CopyType | Gold parquet → unknown upstream | Tier 3 |
| RegistrationDateID | Gold parquet → unknown upstream | Tier 3 |
| DailyFirstSentDateID | Gold parquet → unknown upstream | Tier 3 |

## Downstream Consumers

| Consumer | Usage |
|----------|-------|
| `SP_FactSet_HistorySuccess` | Reads CIDs to update `Dealing_FactSet_Management.HistorySendFlag` |

---

*Generated: 2026-03-21 | Batch 19*
