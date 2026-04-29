# BI_DB_dbo.BI_DB_TicketsForOPS_NEW — Review Sidecar

## Tier 4 Items (None)

No Tier 4 columns in this object.

## Open Questions

1. **Type column unpopulated**: The DDL includes a Type column but the SP INSERT statement does not populate it. Is this intentional or a bug? The column exists in Customer_Support_Case and is selected in #details but not in the INSERT column list.
2. **Very small table (105 rows)**: Is this table actively used? The latest CreatedDate is April 2024, suggesting no new tickets have entered since then. May be obsolete or replaced.
3. **No UC mapping**: Not exported to Unity Catalog. Confirm if this is intentional.
4. **Google Sheets source**: Wire deposit data comes from Fivetran-synced Google Sheets — this is a non-standard, potentially fragile data source.
5. **CID cleanup logic**: The SP filters out specific CID patterns (15716479574216, '?') — what are these? Test accounts?

## Reviewer Corrections

None pending.

## Cross-Object Consistency

- CID description matches DWH_dbo.Dim_Customer.RealCID (Tier 1 — Customer.CustomerStatic) ✓
