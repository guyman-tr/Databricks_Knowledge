# BI_DB_CID_DailyCluster — Items Requiring Review

## RN-1 — OpsDB Priority Mismatch

**Issue**: OpsDB declares `SP_CID_DailyCluster` at Priority 0 (base layer — no intra-schema dependencies), but the SP explicitly reads from `BI_DB_dbo.BI_DB_ClusteringDailyPrepData` (produced by `SP_ClusteringDailyPrepData`, a Priority 20 process). It also reads from `BI_DB_dbo.BI_DB_ClusteringLog`.

**Current behavior**: The ClusteringDailyPrepData join is a LEFT JOIN, so if the P20 source isn't ready, CryptoRatio will be NULL and ClusterDynamic will equal ClusterDetail (graceful degradation). This likely explains why it's scheduled at P0 without hard failure.

**Action**: Confirm with the pipeline team whether the ClusteringLog and ClusteringDailyPrepData tables are populated before SP_CID_DailyCluster runs, or whether the LEFT JOIN degradation is intentional.

---

## RN-2 — ClusterDetail Varchar Length Not Validated

**Issue**: The DDL for ClusterDetail, ClusterSF, ClusterDynamic was not available for DDL type inspection (varchar size unclear from current query sample).

**Action**: Read `BI_DB_dbo.BI_DB_CID_DailyCluster.sql` DDL to confirm exact varchar lengths for these columns.

---

## RN-3 — BI_DB_ClusteringLog Source Not Documented

**Issue**: `BI_DB_ClusteringLog` is the primary source for daily cluster assignments but has no wiki documentation. Its schema, ETL source (ML model output?), and update cadence are unknown.

**Action**: Document `BI_DB_ClusteringLog` to establish the full upstream chain for cluster assignments. The ML model producing ClusterDesc values is the ultimate source.

---

## RN-4 — IsFirstCluster Logic Note

**Issue**: `IsFirstCluster=1` does NOT mean the customer was just added to the clustering model today. It means that at the time of this row's INSERT, the customer had no prior row in `#lastcluster` (IsLastCluster=1 in BI_DB_CID_DailyCluster). For customers who were previously clustered but whose history was deleted/re-loaded, IsFirstCluster could be set to 1 incorrectly.

**Action**: No code change needed, but analysts should be aware that `IsFirstCluster` is "first record in this table" not "newly clustered customer."

---

## RN-5 — IsSFCluster Bi-Monthly Logic

**Issue**: The IsSFCluster=1 flag is set only on the first day of even months. For analysts using this flag to find Salesforce sync candidates, queries run on odd months may show IsSFCluster=0 for customers whose clusters changed recently. The flag is only refreshed every 2 months.

**Action**: Document in any Salesforce integration runbooks that IsSFCluster reflects the last even-month sync state, not real-time status.
