---
object: Dealing_Monitoring_ADV_MoreThanPercent
review_date: 2026-03-21
reviewer: ""
status: Needs Review
---

# Dealing_Monitoring_ADV_MoreThanPercent — Review Notes

## Auto-Generated Flags

- **Threshold value unknown**: The exact PercentfromADV threshold for inclusion is not visible from the partial SP read. Reviewer: what is the cutoff (e.g., 1%, 0.5%)?
- **Volume units (USD vs. units)**: The Volume column description says "in USD or units — TBD". Reviewer: confirm whether Volume is in native instrument units or USD-converted.
- **RowNumber ordering**: Direction of ranking (ascending vs. descending by PercentfromADV) is not confirmed from partial SP read. Reviewer: confirm sort order.
- **ADV source**: Same open question as parent table — exact market data source for ADV not traced in partial SP read.
- **PercentfromADV rounding**: Sample values (1.0, 3.0) appear as integers despite decimal(16,4) type. Reviewer: are values truly rounded to 1% increments, or is this coincidence in the sample?

## Reviewer Corrections

<!-- Add corrections here. Mark resolved issues with [RESOLVED]. -->
