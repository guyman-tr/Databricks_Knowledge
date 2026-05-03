# Review Needed: BI_DB_dbo.Group_LTV_Table

## Items for Human Review

### 1. Static Table — SP Guard Clause Expiration
- SP_Group_LTV_Table has a guard clause: `IF CAST(GETDATE() AS DATE) <= '2024-10-30'`. This means the SP can no longer execute as of 2024-10-31. The table has not been refreshed since 2024-10-30.
- **Question**: Is this table still actively used downstream? Should the guard clause be updated to allow future refreshes with newer cohort data?

### 2. Region-Specific Equity Tier Overrides — Business Validation
- The SP applies region-specific overrides that reclassify customers with EOM_Equity < $500 into Tier 2 for specific region×cluster combinations (Arabic any cluster, Latam Crypto/Leveraged, Spain Diversified, USA Equities Traders, UK Diversified).
- **Question**: What is the business rationale for these specific region×cluster overrides? Are these empirically derived or policy-driven?

### 3. Population Window Frozen
- The population is frozen to FTD between 2022-01-01 and 2024-06-30. Customers depositing after June 2024 are not represented.
- **Question**: Should the population window be extended for future refreshes?

### 4. 'Unknown' Region (1 row)
- One row has Region='Unknown' with Clients=1. This represents a customer whose country had no MarketingRegionManualName mapping in Dim_Country.
- **Recommendation**: Consider excluding Unknown region rows or investigating the unmapped country.

### 5. Relationship to BI_DB_LTV_BI_Actual.Revenue8Y_LTV_New_Group_LTV
- BI_DB_LTV_BI_Actual has its own `Revenue8Y_LTV_New_Group_LTV` column computed differently (by FirstFundedMonth × NewMarketingRegion × ClusterDetail × EquityTier). This table uses a different segmentation with region-specific tier overrides.
- **Question**: How do downstream consumers distinguish between the two group LTV signals? Is there documentation on when to use which?

---

*Generated: 2026-04-30*
