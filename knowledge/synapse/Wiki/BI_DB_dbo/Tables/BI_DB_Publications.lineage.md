# Lineage: BI_DB_dbo.BI_DB_Publications

## Source Chain

| Level | Object | Type | Role |
|-------|--------|------|------|
| L0 | UserApiDB.dbo.Publications (production) | Production DB | User profile publications (bio text, sticky notes, language) |
| L1 | BI_DB_dbo.External_UserApiDB_dbo_Publications | External Table | Lake bridge for UserApiDB.dbo.Publications |
| L2 | BI_DB_dbo.BI_DB_Publications | **THIS TABLE** | Incrementally maintained copy of user bio data |

## ETL Pipeline

```
UserApiDB.dbo.Publications (production — CID, Sticky, AboutMe, LanguageCode)
  |-- Generic Pipeline (Bronze export to lake) ---|
  v
BI_DB_dbo.External_UserApiDB_dbo_Publications (external table — lake bridge)
  |-- SP_Publications (daily, no parameters) ---|
  |   INSERT new CIDs not yet in table          |
  |   UPDATE AboutMe when value changes         |
  |   (Sticky, LanguageCode: set on INSERT only)|
  v
BI_DB_dbo.BI_DB_Publications (266,266 rows, accumulating since 2020-05-17)
  |-- UC: Not Migrated ---|
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | External_UserApiDB_dbo_Publications | CID | Direct — UserApiDB.dbo.Publications customer ID; INSERT-only (new CIDs only) | Tier 2 |
| 2 | Sticky | External_UserApiDB_dbo_Publications | Sticky | Direct — set at INSERT only; SP does NOT update Sticky on subsequent runs | Tier 3 |
| 3 | AboutMe | External_UserApiDB_dbo_Publications | AboutMe | Set at INSERT for new CIDs; actively UPDATE'd when value changes from live source | Tier 3 |
| 4 | LanguageCode | External_UserApiDB_dbo_Publications | LanguageCode | Direct — set at INSERT only; SP does NOT update LanguageCode on subsequent runs | Tier 3 |
| 5 | UpdateDate | SP-computed | GETDATE() | Timestamp of INSERT (for new CIDs) or UPDATE (for AboutMe changes) | Tier 2 |

## UC External Lineage

UC Target: Not Migrated
