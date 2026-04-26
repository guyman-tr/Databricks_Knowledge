# BI_DB_AML_Singapore_Risk_Classification — Review Needed

**Generated**: 2026-04-22  
**Reviewer**: AML / Data Engineering  

---

## Issues Requiring Human Review

### 1. Customer with Final_Score=300 and Risk_Score='High' (not Blocked) — possible SP gap
**Severity**: Medium  
One customer has `Final_Score = 300` and `Risk_Score = 'High'` instead of `Risk_Score = 'Blocked'`.

The score of 300 can only come from a country ranked 'Blocked' in the Singapore GRC sheet contributing to the Max_Final_Score. When a country is 'Blocked', the corresponding `_B_` flag column should also be set, which triggers `Risk_Score = 'Blocked'`.

The SP uses two separate logic paths for blocked countries:
1. **Score path** (#natinonality, #KYC_Country, #POB, #Citizenship_Sec): Uses `JOIN DWH_dbo.Dim_Country dc1 ON dc1.DWHCountryID = ff.e_toro_country_id` → `JOIN #pop pp ON pp.Nationality_Country_ID = dc1.DWHCountryID`
2. **Block flag path** (#natinonalityB, etc.): Uses `JOIN #pop pp ON pp.Nationality_Country_ID = ff.e_toro_country_id`

The block flag path joins directly on `e_toro_country_id` (a raw value from the Fivetran sheet), while the score path uses an intermediate Dim_Country join. If `e_toro_country_id` contains a string value that Dim_Country resolves but is not directly comparable to `Nationality_Country_ID` (an integer), the score can match while the block flag does not, resulting in a country risk score of 300 without the corresponding 'Blocked' classification.

**Action**: Confirm with SP owner that all `sg_country_aml_rank = 'Blocked'` rows in the GRC sheet have properly typed `e_toro_country_id` values. The block path should use the same Dim_Country intermediary JOIN as the score path for consistency.

---

### 2. Column name typo: ScreeningStauts_Final_Score
**Severity**: Low (informational)  
The column name is `ScreeningStauts_Final_Score` (typo: "Stauts" not "Status"). This typo is present in both the DDL and the SP and is therefore in production.

**Action**: If the column is ever added to a Databricks table or API, document the typo explicitly. Any downstream query or view must use the misspelled column name. No immediate fix needed unless a breaking rename is acceptable.

---

### 3. @Yesterday variable is GETDATE()-2 and appears unused
**Severity**: Low  
SP line 13: `DECLARE @Yesterday AS DATE = CAST(GETDATE()-2 AS DATE)` declares "yesterday" as 2 days ago (not 1 day ago). Additionally, `@Yesterday` does not appear to be referenced anywhere in the SP body.

**Action**: Confirm whether this variable was intended for a filter that was later removed. If unused, it can be cleaned up in the next SP revision. If it should be used, the off-by-one date error should be corrected.

---

### 4. Partial-KYC customers (VerificationLevelID=2) included
**Severity**: Informational  
Unlike other AML tables (HR, MR, AR) which require VerificationLevelID=3, this table includes customers with VerificationLevelID=2 (partial KYC). For these customers, KYC Panel data (Q10, Q11, Q18, Q26) may be NULL, resulting in 0 scores for Occupation, SOF, Income, and Liquid Assets components. This could under-score partially-KYC customers.

**Action**: Confirm with the AML/MAS compliance team that including VerificationLevelID=2 customers is intentional per MAS regulatory requirements.

---

### 5. Max_Final_Score not stored as a column
**Severity**: Informational  
The `Max_Final_Score` (MAX of the 4 country-risk scores: Nationality, POB, KYC Country, Second Citizenship) is computed in `#final_Country` and contributes to `Final_Score`, but is not persisted in the output table. This makes it impossible to verify the country risk contribution from the stored data alone without recomputing it.

If analysts need to audit why a customer's Final_Score is at a particular level, they would need to manually compute `MAX(Nationality_Final_Score, POB_Final_Score, KYC_Country_Final_Score, Citizenship_Sec_Final_Score)` from the stored individual scores.

**Action**: Consider adding a `Max_Country_Score` column in a future SP revision for auditability.
