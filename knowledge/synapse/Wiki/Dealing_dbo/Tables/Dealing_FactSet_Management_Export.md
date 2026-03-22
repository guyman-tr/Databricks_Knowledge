# Dealing_dbo.Dealing_FactSet_Management_Export

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_FactSet_Management_Export |
| **Type** | External Table |
| **Data Source** | `internal-sources` → `Gold/Dealing/FactSet_stg/Dealing_FactSet_Management_Export/*.parquet` |
| **Columns** | 4 |
| **Primary Source** | Databricks Gold layer (FactSet export pipeline) |
| **ETL SP** | `Dealing_dbo.SP_FactSet_HistorySuccess` (consumer, not writer) |
| **Refresh** | Populated upstream by Databricks; SP recreates the external table definition daily |
| **PII** | YES — contains CID |
| **Tags** | dealing, factset, copy-trading, PI, external-table, data-export |

---

## 1. Business Meaning

`Dealing_FactSet_Management_Export` is a **staging external table** that lists Popular Investor (PI) CIDs whose FactSet historical data has been successfully exported. It acts as an acknowledgment list consumed by `SP_FactSet_HistorySuccess`, which uses it to mark PIs in the main `Dealing_FactSet_Management` table as "history sent" (`HistorySendFlag = 0`).

FactSet is a third-party financial data provider. eToro exports PI portfolio/trading history to FactSet so that PIs can be listed on the FactSet platform. This table records which CIDs have had their data successfully exported on a given day.

The SP dynamically drops and recreates this external table each run to point to the latest parquet files in the Gold layer.

---

## 2. Business Logic

### SP_FactSet_HistorySuccess(@Date)

1. **DROP + CREATE**: Drops the existing external table and recreates it pointing to `Gold/Dealing/FactSet_stg/Dealing_FactSet_Management_Export/*.parquet`
2. **UPDATE**: Sets `HistorySendFlag = 0`, `HistorySentDate = @Date`, `UpdateDate = GETDATE()` on `Dealing_FactSet_Management` for all CIDs that appear in either this export table OR `Dealing_FactSet_NewPIs_History`, where `IsActive = 1 AND HistorySendFlag = 1`

The SP does NOT write to this table — it reads from it. The parquet files are produced upstream by a Databricks pipeline.

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `Dealing_dbo.Dealing_FactSet_Management` | `CID` | Target table updated by SP |
| `Dealing_dbo.Dealing_FactSet_NewPIs_History` | `CID` | Additional CID source in the same UPDATE |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_FactSet_HistorySuccess)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer account ID of the PI whose FactSet history was exported. Joined to `Dealing_FactSet_Management.CID` to mark as sent. (Tier 2 — SP_FactSet_HistorySuccess) |
| 2 | CopyType | nvarchar(4000) | YES | Copy trading classification. Expected values: `PI` (Popular Investor). Identifies the type of copy-trading participant. (Tier 2 — DDL + live data) |
| 3 | RegistrationDateID | bigint | YES | DateID (YYYYMMDD format) of the PI's registration date. Used for tracking when the PI joined. (Tier 2 — DDL + live data) |
| 4 | DailyFirstSentDateID | bigint | YES | DateID (YYYYMMDD format) of the first day the PI's data was sent to FactSet. Used for deduplication and tracking export history. (Tier 2 — DDL + live data) |

---

## 5. Usage Notes

**External table is ephemeral**: SP_FactSet_HistorySuccess drops and recreates this table on every run. The data reflects whatever is currently in the Gold parquet files.

**Not a historical store**: This table contains only the current batch of exported CIDs. For historical tracking, use `Dealing_FactSet_Management.HistorySentDate`.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Databricks Gold layer → `Gold/Dealing/FactSet_stg/` |
| **Refresh** | External table definition recreated daily by SP_FactSet_HistorySuccess |
| **PII** | YES — CID |
| **Owner** | Dealing team |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 4/5 | Sampled successfully |
| SP Logic | 5/5 | Short SP (41 lines) fully analyzed |
| Upstream Wiki | 2/5 | No upstream production wiki for Gold layer source |
| Business Context | 3/5 | No specific Atlassian hits; purpose clear from SP |
| **Total** | **7.5/10** | |

---

*Generated: 2026-03-21 | Batch 19 | Schema: Dealing_dbo*
