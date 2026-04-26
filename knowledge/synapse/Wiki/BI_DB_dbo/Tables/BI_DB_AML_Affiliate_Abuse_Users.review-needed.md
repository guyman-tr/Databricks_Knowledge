# Review Needed: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users

**Generated**: 2026-04-23 | **Quality**: 9.0/10 | **Reviewer**: BI / AML team

---

## Items Requiring Human Review

### 1. User_Age Sentinel Handling
- **Flag**: SP computes `DATEDIFF(YEAR, BirthDate, GETDATE())` for User_Age. BirthDate='1900-01-02' is the sentinel for unknown birth date. The resulting DATEDIFF would produce ~124, not 0 — the wiki documents it as "→ 0" but this may be incorrect if there's no CASE statement wrapping it.
- **Why**: The SP code was read but the exact CASE/ISNULL wrapping for the 1900-01-02 sentinel was not confirmed from the SQL. Could be a bare DATEDIFF or could have a CASE guard.
- **Action**: Re-read SP_AML_Affiliate_Abuse Step 03 to confirm exact User_Age computation for the 1900-01-02 sentinel

### 2. V_Liabilities INNER JOIN — Missing Customers
- **Flag**: INNER JOIN to V_Liabilities drops customers with no equity record. 1,208,122 rows is the V_Liabilities-filtered count, not the full activated affiliate customer count.
- **Why**: If an analyst expects all registered affiliate customers from 2023+, they will get fewer rows than expected.
- **Action**: Consider documenting the approximate total registered affiliate customer count (before V_Liabilities filter) for reference — requires a separate query against Dim_Customer

### 3. Is_Blocked PlayerStatusID=5 (Warning) Classification
- **Flag**: PlayerStatusID=5 (Warning) is treated as NOT blocked (Is_Blocked=0). This may be overly lenient for AML purposes — a "Warning" status customer may warrant investigation.
- **Why**: The SP explicitly includes StatusID IN (1,5) as unblocked. Whether Warning should be treated as blocked is a business decision.
- **Action**: Confirm with compliance/AML team whether Warning-status customers (StatusID=5) should be classified as blocked in AML context

### 4. 30-Day Window for Non-Depositors
- **Flag**: Is_CO_30, Is_Dep_30, Count_Positions_30 use FirstDepositDate as the window anchor. For customers where FirstDepositDate=1900-01-01 (never deposited), the window computation would be meaningless.
- **Why**: #co_30, #dep_30, #position30 are joined to #cidlevel — non-depositors likely get 0/NULL for all 30-day flags, but the exact LEFT vs INNER join type per step was not traced exhaustively.
- **Action**: Confirm that non-depositor customers appear in the final table with 0s (not excluded)

### 5. PII Sensitivity
- **Flag**: Table contains IP (registration IP address) and Gender — both PII fields
- **Why**: GDPR implications for retaining/exposing these in documentation queries
- **Action**: Confirm with data governance that IP and Gender exposure in this frozen table complies with retention policy

---

## No Review Needed

- 33 elements match DDL column count ✅
- Tier 1 assignments: CID, FirstDepositDate, RegisteredReal, FirstDepositAmount, VerificationLevelID, IsValidCustomer, IsDepositor, Gender, IP, Country all confirmed from DWH_dbo wiki
- SP disable date (2024-12-31): confirmed in SP header comment
- V_Liabilities snapshot date (2024-12-30 = @DateID): confirmed from SP parameter
- 30-day window logic (CashoutStatusID_Funding=3, PaymentStatusID=2): confirmed from SP Steps 05-06
- SubChannelID scope (20,31,39,40,41,42,44): confirmed from SP Step 03
- Is_Blocked formula (NOT IN 1,5): confirmed from SP Step 03
- FirstAction/FirstActionDate/FirstInstrument: confirmed from BI_DB_First5Actions wiki
