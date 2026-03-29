# DWH_dbo.V_Dim_Instrument_Correlation_Test_Full

> Test/validation view that reconstructs the full symmetric Pearson correlation matrix from `Dim_Instrument_Correlation_Half_Records` — a single test partition table, without the 20-way split or archive used in production.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | View |
| **Base Tables** | DWH_dbo.Dim_Instrument_Correlation_Half_Records |
| **Purpose** | Test/validation symmetric correlation matrix from a single partition table |

---

## 1. Business Meaning

`V_Dim_Instrument_Correlation_Test_Full` is a test/validation view that provides the full symmetric correlation matrix from a single partition table (`Dim_Instrument_Correlation_Half_Records`), as opposed to the production views which use 20 partition tables. It is used to validate correlation data before production deployment.

The view reconstructs the symmetric matrix by:
1. Selecting all rows from the half-records table (original direction)
2. Adding mirrored rows where InstrumentID_a < InstrumentID_b (swapping a/b and StdDev_a/b)

---

## 2. Elements

| # | Column | Type | Nullable | Source | Description |
|---|--------|------|----------|--------|-------------|
| 1 | DateID | int | NULL | Half_Records.DateID | Integer date key in YYYYMMDD format identifying the calculation date for this correlation snapshot. Matches the @auxdate parameter passed to SP_Dim_Instrument_Correlation_Half_Records. Filter by this column for performance. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 2 | InstrumentID_a | int | NULL | Half_Records.InstrumentID_a (+ swapped _b) | ID of the first financial instrument in the pair. In the full-symmetric output, this can be any instrument (not limited to <= InstrumentID_b). Resolves to Dim_Currency.CurrencyID for the instrument name. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 3 | InstrumentID_b | int | NULL | Half_Records.InstrumentID_b (+ swapped _a) | ID of the second financial instrument in the pair. In the full-symmetric output, this can be any instrument (not limited to >= InstrumentID_a). Resolves to Dim_Currency.CurrencyID for the instrument name. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 4 | SampleSize | int | NULL | Half_Records.SampleSize | Number of hourly candle data points where both instruments had valid prices in the 3-month lookback window. Higher values = more reliable correlation estimate. Low values (< 100) indicate sparse data. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 5 | StandardDeviation_a | decimal(38,20) | NULL | Half_Records.StandardDeviation_a (+ swapped _b) | Population standard deviation of hourly price returns for InstrumentID_a over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). Swapped with StandardDeviation_b in the symmetric reconstruction leg. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 6 | StandardDeviation_b | decimal(38,20) | NULL | Half_Records.StandardDeviation_b (+ swapped _a) | Population standard deviation of hourly price returns for InstrumentID_b over the 3-month window. Computed via STDEVP(PriceChange). Always > 0 (HAVING clause excludes zero-variance rows). Swapped with StandardDeviation_a in the symmetric reconstruction leg. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 7 | Covariance | decimal(38,20) | NULL | Half_Records.Covariance | Raw covariance between the hourly price returns of the two instruments. Formula: sum(a*b)/n - (sum(a)*sum(b))/n^2. Used as numerator in PearsonCorrelation formula. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 8 | PearsonCorrelation | decimal(38,20) | NULL | Half_Records.PearsonCorrelation | Pearson correlation coefficient between the two instruments' hourly price returns over the 3-month window. Range -1.0 (perfect negative) to +1.0 (perfect positive). 0 = no linear correlation. Formula: Covariance / (StandardDeviation_a * StandardDeviation_b). (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 9 | InsertDate | datetime | NULL | Half_Records.InsertDate | Timestamp when the correlation row was first computed. Set to GETDATE() by the ETL SP. (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |
| 10 | UpdateDate | datetime | NULL | Half_Records.UpdateDate | Timestamp when the correlation row was last updated. Set to GETDATE() by the ETL SP (same as InsertDate on initial load; may differ on re-computation). (Tier 1 — inherited from Dim_Instrument_Correlation_UnionedPartitions wiki) |

---

## 3. Relationships & JOINs

| Related Object | JOIN Condition | Relationship | Direction |
|----------------|----------------|--------------|-----------|
| DWH_dbo.Dim_Instrument_Correlation_Half_Records | Source table (2-leg UNION ALL) | Base table | Inbound |
| DWH_dbo.Dim_Currency | `ON InstrumentID_a = CurrencyID` / `ON InstrumentID_b = CurrencyID` | Instrument name resolution | Logical |

---

## 4. ETL & Data Pipeline

No ETL — computed view over the test partition table. Data freshness depends on `Dim_Instrument_Correlation_Half_Records` population.

---

## 5. Business Logic & Patterns

### Symmetric Matrix Reconstruction

```sql
SELECT * FROM (
    SELECT ... FROM Dim_Instrument_Correlation_Half_Records b
    UNION ALL
    SELECT DateID, InstrumentID_b AS a, InstrumentID_a AS b,
           SampleSize, StdDev_b AS a, StdDev_a AS b, ...
    FROM Dim_Instrument_Correlation_Half_Records b
    WHERE InstrumentID_a < InstrumentID_b
) a
```

Unlike `V_Dim_Instrument_Correlation`, this view has no date-based partition split — it applies symmetric expansion to all rows unconditionally.

---

*Generated: 2026-03-28 | Quality: 8.0/10 (★★★★☆) | Phases: 7/14 | Batch: 16*
*Tiers: 10 T1, 0 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10*
*Object: DWH_dbo.V_Dim_Instrument_Correlation_Test_Full | Type: View | Base Tables: DWH_dbo.Dim_Instrument_Correlation_Half_Records*
