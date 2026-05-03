MCP PRE-FLIGHT: PASS

Now let me read the remaining rule files and search for any SPs that reference this table.
Good. Now let me read the writer SP and run the live sampling queries.
PHASE 1 CHECKPOINT: PASS — 28 columns from DDL parsed.
PHASE 2 CHECKPOINT: PASS — 36.8M rows, sample retrieved.

Now let me read how SP_Marketing_Cube uses this table after loading, and run distribution queries.
PHASE 3 CHECKPOINT: PASS — Distribution on CountryID (>15 values), Valid (2 values), IsProcessed (2 values).

Now let me check for date range and any views referencing this table, and read the LabelID situation.
Now let me check for Jira context quickly and gather remaining data.
PHASE 4 CHECKPOINT: PASS — FK lookups identified (CountryID→Dim_Country, AffiliateID→Dim_Affiliate, FunnelID→Dim_Funnel).
PHASE 5 CHECKPOINT: PASS — JOINs in SP_Marketing_Cube: ClosedPositionCommission ON ClosedPositionID, Dim_Affiliate ON AffiliateID.
PHASE 6 CHECKPOINT: PASS — Commission logic: Amount - HedgeCommission = net revenues; Valid/IsProcessed filter.
PHASE 7 CHECKPOINT: PASS — No views reference this table.
PHASE 8 CHECKPOINT: PASS — Writer: SP_Create_fiktivo_AffiliateCommission_ClosedPosition; Orchestrator: SP_Marketing_Cube.
PHASE 9 CHECKPOINT: PASS — COPY INTO from Bronze/fiktivo/AffiliateCommission/ClosedPositionVW/ Parquet. No SQL column transforms.
PHASE 9B CHECKPOINT: PASS — Daily rebuild via SP_Marketing_Cube: DROP + COPY INTO loop over date range.
PHASE 10 CHECKPOINT: PASS — Confluence: "Affiliate Commissions: Trading Metadata", "Separate Meta data from tracking tables".
PHASE 10A CHECKPOINT: PASS — No upstream wiki; _no_upstream_found.txt present.

Now writing the three output files.
PHASE 10B CHECKPOINT: PASS — lineage file written.

Now writing the main wiki.
Now writing the review-needed sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube/regen/attempt_2/fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube/regen/attempt_2/fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube/regen/attempt_2/fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 9    Tier3: 19    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
