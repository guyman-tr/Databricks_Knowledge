# Review Needed: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Wires

## Tier 3 / Low Confidence Items

No Tier 3 or Tier 4 columns in this table. All 19 columns are either Tier 1 (upstream wiki) or Tier 2 (SP code analysis). This is the cleanest of the three tables in this batch.

## Open Questions

- **Table name is misleading**: "Wires" suggests wire transfers only, but the table contains ALL approved deposit types. Should the table be renamed or documented with a prominent alias?
- **ModificationDateID is NULL in all 27.7M rows** despite being in the clustered index. Is this intentional or a bug in the INSERT statement? Should the CI be rebuilt as CI(CID) only?
- **Amount is USD-converted** (bd.Amount * bd.ExchangeRate) which differs from the source Fact_BillingDeposit.Amount. Analysts accustomed to deposit-currency amounts may be confused. Should a column alias (AmountUSD) have been used instead?
- **HandlingDays vs FromStartToFinish**: For non-wire deposits, ValueDate = PaymentDate, so HandlingDays and FromStartToFinish should be identical. Is this expected, or does it indicate redundant data?
- **PlayerLevelID<>4 filter**: This excludes Popular Investors. Is this still the correct business rule, or should they now be included?
