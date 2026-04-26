# BI_DB_AML_Periodic_Review_MR — Review Needed

**Generated**: 2026-04-22  
**Reviewer**: AML / Data Engineering  

---

## Issues Requiring Human Review

### 1. Login_Rank1_2023 logic — possible SP bug
**Severity**: Medium  
**Column**: `Login_Rank1_2023`  
The SP logic for this flag (line 428–432) is:
```sql
WHERE fca.CountryIDByIP IN (SELECT pp.CountryRank FROM #pop pp WHERE pp.CountryRank = 1)
AND fca.DateID >= 20230101
```
The subquery `SELECT pp.CountryRank ... WHERE pp.CountryRank = 1` returns the constant value `1`. This means the filter is effectively `fca.CountryIDByIP = 1`, which filters on DWH country ID = 1 (a specific country in the DWH).

The apparent intent was to detect logins from **highest-risk-group countries** (CountryRank/RiskGroupID = 1). However, `CountryIDByIP` is a DWH country ID (DWHCountryID, typically ranging in the hundreds), not a risk group ID. Mixing these namespaces means the flag may only capture logins from a single specific country (whichever country has DWHCountryID = 1) rather than all highest-risk-group countries.

**Action**: Confirm with the SP author (Eyal Boas) whether the intent is "logins from countries with RiskGroupID=1" or "logins from country with DWHCountryID=1". If the former, the correct logic would be a JOIN to `Dim_Country WHERE RiskGroupID = 1`.

---

### 2. @3YearsAgo_DateID variable uses wrong base date
**Severity**: Low (no functional impact on MR)  
**Reference**: SP line 18  
```sql
DECLARE @3YearsAgo_DateID INT = CAST(CONVERT(CHAR(8),@YearAgo_Date,112) AS INT)
```
This incorrectly uses `@YearAgo_Date` (1 year ago) instead of `@3YearsAgo_Date` (3 years ago). The DateID variable contains the wrong value.

The MR population filter uses `@3YearsAgo_Date` (the DATE variable) directly, not `@3YearsAgo_DateID`, so MR results are not affected. However, any future code that uses `@3YearsAgo_DateID` for filtering will silently apply a 1-year filter instead of a 3-year filter.

**Action**: Flag to SP author. Low risk for existing output, but a latent bug for future SP modifications.

---

### 3. SP header date mismatch
**Severity**: Informational  
The SP header comment shows "Date: 2025-02-25" (inherited from the sibling SP template). The actual creation date is 2025-04-27 per the Change History block. No functional impact.

---

### 4. aml_compliance field sourcing
**Severity**: Low  
**Column**: `aml_compliance`, `aml_compliance_POB`  
These fields come from `External_Fivetran_google_sheets_grc_list` — a Google Sheets document synced via Fivetran. The meaning and update frequency of this sheet's `aml_compliance` column are not documented in the SP or SSDT repo. The values may change if the GRC team updates the sheet without notifying the data platform.

**Action**: Confirm with the GRC/Compliance team what `aml_compliance` values are expected and how frequently the sheet is updated.

---

### 5. Total_Withdraw is lifetime, not period-specific
**Severity**: Informational  
The `Total_Withdraw` column sums all cashouts (Fact_CustomerAction ActionTypeID=8) without a date filter — it is a lifetime total. The wiki documents this correctly. However, the field name does not indicate the time scope, which may confuse analysts expecting a recent-period cashout figure.

**Action**: Consider whether a period-scoped version would be more useful. Document the lifetime scope clearly in any downstream report using this field.
