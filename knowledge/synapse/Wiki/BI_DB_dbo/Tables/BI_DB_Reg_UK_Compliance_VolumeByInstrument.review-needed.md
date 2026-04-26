# Review Needed — BI_DB_dbo.BI_DB_Reg_UK_Compliance_VolumeByInstrument

**Generated**: 2026-04-21 | **Batch**: 12 | **Quality**: 9.0/10

## Tier 4/5 Items Requiring Review

No Tier 4 or Tier 5 items — all 8 columns are Tier 2/3 with strong SP code authority.

## Questions for Domain Expert

### 1. Double-count risk for same-day open+close positions
- The SP uses UNION ALL of positions opened on last weekday (Leg 1: `OpenDateID = @startdateid`) and positions closed on last weekday (Leg 2: `CloseDateID = @startdateid`). A position opened and closed on the same business day would appear in **both** legs and its notional would be summed twice in `FullNotionalAmount`. Reviewer should confirm whether this double-count is intentional (report wants to capture both open-side and close-side flows independently) or a bug.

### 2. Dim_Country dead JOIN
- `DWH_dbo.Dim_Country` is JOINed in both SP legs (`JOIN Dim_Country dc ON dc.CountryID = c.CountryID`) but `dc` is not referenced in the SELECT or WHERE clauses. This dead JOIN adds query cost with no output effect. Reviewer should confirm whether this JOIN was intentional for an implicit row filter (e.g., only customers with a valid CountryID), or whether it is a legacy remnant that can be safely removed.

### 3. No business date column in output
- The table has no date column representing *which* business day the data covers. `UpdateDate` is the SP runtime timestamp, not the `@startdate`. If the SP runs at different times across days, `UpdateDate` cannot be used to derive the business date. Reviewer should confirm whether adding a `BusinessDate` or `SnapshotDate` column is desirable for auditability and historical comparison.

### 4. Table name vs. data scope mismatch
- The table is named `Reg_UK_Compliance_VolumeByInstrument` suggesting UK/FCA-specific content, but the SP has no regulation filter — all 16+ regulation values appear. The UK compliance team filters the data themselves. Reviewer should confirm whether this naming is intentional or whether the table should be understood as a platform-wide instrument volume snapshot used *by* the UK compliance team.

## No ALTER Script Generated

ALTER script deferred to `/generate-alter-dwh` pass. UC Target = `_Not_Migrated`, so no ALTER will be generated unless UC migration occurs.
