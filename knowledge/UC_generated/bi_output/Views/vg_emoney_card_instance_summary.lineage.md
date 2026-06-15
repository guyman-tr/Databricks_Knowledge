# Column Lineage: main.bi_output.vg_emoney_card_instance_summary

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_emoney_card_instance_summary` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_emoney_card_instance_summary.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_emoney_card_instance_summary.json` (rows: 6, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Card_Instance_Summary.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary   ←── primary upstream
        │
        ▼
main.bi_output.vg_emoney_card_instance_summary   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` | `CID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | CID |
| 2 | `Customer_Card_ID` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` | `DWH_CardInstanceId` | `rename` | (Tier 1 — dbo.FiatCardInstances) | DWH_CardInstanceId AS Customer_Card_ID |
| 3 | `Customer_Card_Status` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` | `InstanceStatus` | `rename` | (Tier 2 — SP_eMoney_Card_Instance_Summary) | InstanceStatus AS Customer_Card_Status |
| 4 | `Customer_Card_Order_Date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` | `InstanceCreatedDate` | `rename` | (Tier 2 — SP_eMoney_Card_Instance_Summary) | InstanceCreatedDate AS Customer_Card_Order_Date |
| 5 | `Customer_Card_Activation_Date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` | `InstanceActivationDate` | `rename` | (Tier 2 — SP_eMoney_Card_Instance_Summary) | InstanceActivationDate AS Customer_Card_Activation_Date |
| 6 | `Customer_Card_Expiration_Date` | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary` | `InstanceExpirationDate` | `rename` | (Tier 1 — dbo.FiatCardInstances) | InstanceExpirationDate AS Customer_Card_Expiration_Date |

## Cross-check vs system.access.column_lineage

- Total target columns: **6**
- OK: **6**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
