# Review Flags: BI_DB_Compliance_Surveillance_KYC_PnL_Monitoring

## Flag 1 — KYC Question ID Mapping (SOFT)
The SP uses fixed QuestionIds (10=net income, 11=savings, 14=planned investment). Confirmed via live KYC table lookup (2026-04-23). If the KYC questionnaire is restructured and question IDs are reassigned, these fields will silently pull wrong answers. Recommend periodic validation that QuestionId=10 still maps to "What is your net annual income?".

## Flag 2 — Legacy KYC Answer Bands (SOFT)
DeclaredNetIncome contains a mix of legacy ("$10K-25K", "Less than $25K", "More than $500K") and current ("$10K-$50K", "$50K-$200K") band formats. 14 distinct values observed. Normalization required for quantitative analysis. No standard lookup table found in Synapse.

## Flag 3 — Equity Gate Exclusion (SOFT)
Only clients with `UnrealisedEquity > 0` are included in the output. Clients with zero or negative equity (e.g., accounts with only cash and no open positions) are excluded. This means the surveillance population may miss some L3-verified clients with declining account balances — a potentially relevant compliance risk group.

## Flag 4 — Date Fields as varchar(50) (SOFT)
BirthDate, FirstDepositDate, LastTradeDate, VerificationLevel3Date, UpdateDate are stored as varchar(50). This prevents index-based date filtering and requires explicit casting. Particularly notable for LastTradeDate — the 12-month activity filter is applied IN the SP, but downstream consumers must cast before date arithmetic.

## Flag 5 — PII Exposure (INFO)
Table contains high-sensitivity PII: FirstName, LastName, BirthDate, Email. Dynamic data masking should be applied in Unity Catalog if this table is migrated to UC. Manager field also exposes internal employee names.
