# Cluster 21 brief — `BI_DB_dbo.BI_DB_Tax_Compliance_TIN`

_Size: 7, intra-cluster weight: 18.0_
_Schema mix: {'BI_DB_dbo': 2, 'Customer': 1, 'DWH_dbo': 1, 'Dictionary': 2, 'KYC': 1}_
_Edge sources: {'wiki': 18}_

## Top members (ranked by intra-cluster weight)

- `BI_DB_dbo.BI_DB_Tax_Compliance_TIN` — w 15.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Tax_Compliance_TIN.md)
- `Customer.ExtendedUserField` — w 9.0 (no wiki)
- `Dictionary.ExtendedUserField` — w 4.0 (no wiki)
- `DWH_dbo.Dim_ExtendedUserField` — w 3.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_ExtendedUserField.md)
- `Dictionary.ExtendedUserValueType` — w 2.0 (no wiki)
- `KYC.ReasonsForNoTaxID` — w 2.0 (no wiki)
- `BI_DB_dbo.BI_DB_Tax_Compliance_W8` — w 1.0 (no wiki)

## Wiki §3.3 Common JOINs (top members)

### `BI_DB_dbo.BI_DB_Tax_Compliance_TIN`

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer demographics, regulation, status |
| DWH_dbo.Dim_Country | TIN_CountryID = CountryID | Additional country attributes (region, risk) |
| BI_DB_dbo.BI_DB_Tax_Compliance_W8 | CID = CID | W8 form submission dates |

### `DWH_dbo.Dim_ExtendedUserField`

| Join To | Join Condition | Purpose |
|---|---|---|
| (No active FK consumers) | FieldID | Field is not currently used as FK in DWH |

## KPI views in this cluster

## Genie spaces overlapping this cluster

## Out-cluster neighbors (likely cross-domain candidates)

- `DWH_dbo.Dim_Customer` — outflow weight 3.0
- `DWH_dbo.Dim_Country` — outflow weight 3.0
- `BI_DB_dbo.BI_DB_Tax_Compliance_Trade_CFD_US_Stocks` — outflow weight 2.0
- `BI_DB_dbo.BI_DB_Monthly_InterestPayment_Dashboard` — outflow weight 1.0
- `BI_DB_dbo.BI_DB_USA_FinanceReport_forTax_CreditID` — outflow weight 1.0
- `Dictionary.MandatoryType` — outflow weight 1.0
- `BI_DB_dbo.BI_DB_US_Citizens_Under_Non_US_Regulation` — outflow weight 1.0
