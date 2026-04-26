# BI_DB_dbo.BI_DB_CID_DailyCluster — Column Lineage

> SCD2 cluster history table. Each row = one period during which a customer held a specific cluster assignment. Sources: BI_DB_ClusteringLog (daily assignments) + BI_DB_ClusteringDailyPrepData (asset ratios for ClusterDynamic).

| Column | Source Table | Source Column | Transform |
|--------|-------------|---------------|-----------|
| CID | BI_DB_dbo.BI_DB_ClusteringLog | CID | Passthrough |
| ClusterDetail | BI_DB_dbo.BI_DB_ClusteringLog | ClusterDesc | Direct alias rename |
| ClusterSF | SP_CID_DailyCluster logic | — | CASE: 'Equities Investors'→'Investors'; ('Equities Traders','Diversified Traders','Leveraged Traders')→'Traders'; ('Crypto','Equities Crypto')→'Crypto' |
| FromDateID | BI_DB_dbo.BI_DB_ClusteringLog | DateID | Passthrough |
| ToDateID | SP_CID_DailyCluster logic | — | 99991231 (open) until MERGE closes period with yesterday's DateID |
| FromDate | BI_DB_dbo.BI_DB_ClusteringLog | Date | Passthrough |
| ToDate | SP_CID_DailyCluster logic | — | '9999-12-31' (open) until MERGE sets DATEADD(DAY,-1,@LoadDate) |
| IsLastCluster | SP_CID_DailyCluster logic | — | 1=open/current period (ToDateID=99991231); set to 0 by MERGE when cluster changes |
| IsFirstCluster | SP_CID_DailyCluster logic | — | 1=no prior cluster record existed for this CID at time of insert |
| IsSFCluster | SP_CID_DailyCluster logic | — | Salesforce sync flag. Set to 1 on even-month refresh for recent active clusters; corrected on re-load |
| UpdateDate | SP_CID_DailyCluster | — | GETDATE() at INSERT or UPDATE |
| UpdateDateIDSF | SP_CID_DailyCluster | @Date | CAST(CONVERT(CHAR(8),@Date,112) AS INT) — YYYYMMDD of the SP run date |
| ClusterDynamic | BI_DB_ClusteringLog + BI_DB_ClusteringDailyPrepData | ClusterDesc + CryptoRatio | CASE: ClusterDetail='Diversified Traders' AND CryptoRatio>=0.4 → 'Equities Crypto'; ELSE ClusterDetail |

## Upstream Chain

```
BI_DB_dbo.BI_DB_ClusteringLog (daily cluster assignments — ML model output)
  + BI_DB_dbo.BI_DB_ClusteringDailyPrepData (InvestingRatio, TradingRatio, CryptoRatio)
  |
  v [SP_CID_DailyCluster @Date — Priority 0, Daily, SB_Daily]
    For each day in [@MaxDate+1 .. @Date]:
      1. #ratio = ClusteringDailyPrepData WHERE CalculationDateID = @LoadDateID
      2. #cid = ClusteringLog JOIN #ratio → ClusterDetail + ClusterDynamic
      3. #newcluster = open-ended periods (ToDateID=99991231) for today's cluster assignments
      4. #lastcluster = current open clusters (IsLastCluster=1)
      5. #finalcluster = new clusters WHERE cluster changed (LEFT JOIN #lastcluster ON CID+ClusterDetail+ClusterDynamic WHERE lc.CID IS NULL)
      6. MERGE: close old periods (IsLastCluster=0, ToDate=yesterday) for changed clusters
      7. INSERT new cluster periods from #finalcluster
      8. On even months: SET IsSFCluster=1 for recent active clusters
BI_DB_dbo.BI_DB_CID_DailyCluster (SCD2 history, ROUND_ROBIN, CLUSTERED FromDateID)
```

## T1 Verbatim Copy Verification Log

No upstream wiki columns available for this table — BI_DB_ClusteringLog has no DWH_dbo wiki entry. All columns are Tier 2 (SP ETL logic).
