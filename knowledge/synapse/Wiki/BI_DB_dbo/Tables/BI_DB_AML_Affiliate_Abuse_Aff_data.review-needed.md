# Review Needed: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Aff_data

**Generated**: 2026-04-23 | **Quality**: 8.5/10 | **Reviewer**: BI / AML team

---

## Items Requiring Human Review

### 1. TotalDeposit Currency Unit
- **Flag**: `TotalDeposit` is a float sum but the currency unit is not specified in the SP or DDL
- **Why**: BI_DB_MarketingMonthlyRawData may store amounts in USD, EUR, or a mix. If multi-currency, summing without FX conversion would be misleading.
- **Action**: Confirm with BI/Marketing team whether TotalDeposit is normalised to a single currency (likely USD) or raw mixed-currency

### 2. SameDayFTD Definition
- **Flag**: Column described as "deposited on registration day" but the exact same-day definition in BI_DB_MarketingMonthlyRawData is not verified from source SP
- **Why**: This table is a passthrough from BI_DB_MarketingMonthlyRawData; the computation logic lives upstream
- **Action**: Check BI_DB_MarketingMonthlyRawData wiki or source SP for exact SameDayFTD definition

### 3. Contact Column PII Status
- **Flag**: `Contact` contains email addresses or contact names for affiliate representatives
- **Why**: May contain PII (external email addresses) — GDPR/data governance implications for retaining this in the knowledge wiki
- **Action**: Confirm with data governance team whether Contact values can be exposed in documentation or should be redacted

### 4. ContractType Passthrough vs Dim_Affiliate
- **Flag**: ContractType comes from BI_DB_MarketingMonthlyRawData (passthrough) but Dim_Affiliate is the authoritative source — values may diverge if they were populated at different times
- **Action**: If ContractType analysis is critical, cross-validate against DWH_dbo.Dim_Affiliate for the same AffiliateID

---

## No Review Needed

- SP disable date (2024-12-31): confirmed in SP header comment
- Row count (37,933): reasonable for 2 years × 5 channels × ~2,600+ affiliates
- Profitability computation (NetRevenues - TotalCost): confirmed in SP Step 02
- ISNULL→0 treatment for all SUM aggregates: explicitly coded in SP
- YearMonthID range (202301–202412): confirmed from SP filter (YearMonthID>=202301) and disable date
- SubChannelID filter values: confirmed in SP Step 01
