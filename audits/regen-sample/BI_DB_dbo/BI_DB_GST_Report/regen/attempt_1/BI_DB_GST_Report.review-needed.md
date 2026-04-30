# Review Needed: BI_DB_dbo.BI_DB_GST_Report

## Items for Human Review

### 1. UC Target Resolution
- UC target not resolved in this regen run. Needs mapping from `_generic_pipeline_mapping.json` or confirmation that this table is not exported to Unity Catalog.

### 2. CashoutFee Composite Semantics
- CashoutFee in this table = DDR.CashoutFee + DDR.TransferCoinFees. Confirm whether downstream consumers (e.g., GST filing systems) expect this composite value or need them separated.

### 3. Entity NULL Coverage
- Entity is NULL for CySEC, FSA Seychelles, MAS, FSRA, and BVI regulations (~334K rows). Confirm whether this is intentional or if additional entity mappings should be added for Singapore GST reporting.

### 4. Staking RevShare Tier Percentages
- RevShare percentages were updated (from 0.75/0.85/0.90 to 0.45/0.55/0.65/0.75/0.85/0.90). The old values are commented out in the SP. Confirm the current percentages are correct and when the change took effect.

### 5. TicketingFee Sign Convention
- Both TicketingFee and TicketingFeeByPercent are negated in the SP (`-SUM(...)`). Confirm that positive values in the table represent company revenue (not customer cost).

### 6. Downstream Consumers
- No downstream consumers were identified. Verify if this table feeds into any reporting dashboards, regulatory filings, or downstream aggregation tables.

### 7. Commission Columns — Close-Side Only
- All 12 commission columns use `CommissionOnClose` (not `FullCommission` or open-side commissions). Confirm this is the correct commission measure for GST reporting purposes.
