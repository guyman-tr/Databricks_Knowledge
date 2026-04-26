# BI_DB_dbo.BI_DB_Daily_CID_Dividend_TaxReport — Review Needed

## Tier 4 Items

None — all columns traced to SP logic or DWH dimension joins.

## Questions for Reviewer

1. **TaxCode semantics**: What do the numeric TaxCode values (6, 33, 999, 0) represent? Are they jurisdiction codes or internal classification IDs?
2. **PositionType empty strings**: Legacy rows have empty PositionType. Was this column added later? What should empty values be interpreted as?
3. **RealCID vs CID**: This table uses RealCID (not CID) as the customer identifier, consistent with DailyDividendsByPosition but different from some other BI_DB tables.

## Validation

- Element count: 15 (DDL) = 15 (wiki) — MATCH
- All tier suffixes present: YES
- .lineage.md written: YES
