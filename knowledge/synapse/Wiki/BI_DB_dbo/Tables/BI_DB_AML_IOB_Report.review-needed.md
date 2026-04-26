# Review Needed — BI_DB_dbo.BI_DB_AML_IOB_Report

**Generated**: 2026-04-22 | **Batch**: 45

---

## Items Requiring Human Review

### 1. CRITICAL: Row Fan-out from BI_DB_AML_Documents_Request Join (FIX NEEDED)

The SP performs:
```sql
LEFT JOIN BI_DB_dbo.BI_DB_AML_Documents_Request bdadr ON pp.CID = bdadr.CID
```
`BI_DB_AML_Documents_Request` has ~1.9 rows per CID on average (multi-regulation). The result is ~4.97M rows in this table for only ~318K distinct CIDs (~15.6x fan-out). Every column except `DateAdded_Proof_of_Income` is duplicated on these rows.

This means every COUNT(*), SUM(), or AVG() query on this table will over-count by ~15.6x unless explicitly deduplicated. This is almost certainly unintentional.

**Action**: SP author (Lior Ben Dor) should fix the join to use a deduplicated subquery:
```sql
LEFT JOIN (
    SELECT DISTINCT CID, DocumentDateAdded_POIncome
    FROM BI_DB_dbo.BI_DB_AML_Documents_Request
) bdadr ON pp.CID = bdadr.CID
```
Or alternatively, join only for a specific regulation match. Until fixed, all users MUST use `SELECT DISTINCT CID, ...` or equivalent deduplication.

---

### 2. CRITICAL: Payment_interest_June Has Hardcoded June 2025 Date (DESIGN ISSUE)

The SP computes:
```sql
WHERE Occurred >= '20250601' AND Occurred < '20250701'
```
This column captures June 2025 interest only and will never update. If the SP runs in July 2026, `Payment_interest_June` still shows June 2025 data.

The column name makes the intent clear, but it means this table only has correct current-month interest data for June 2025. For subsequent months, a new column (or parameterized approach) would be needed.

**Action**: Confirm with the AML team whether this is intentional (a one-time snapshot of the first interest payment month) or a bug. If ongoing monthly interest monitoring is needed, the SP needs to be updated with dynamic date calculation.

---

### 3. Is_Eligible Hardcoded Country and Regulation IDs (DOCUMENT-VERIFY)

The eligibility flag uses:
- `RegulationID IN (1,2,4,10,11,9)` → CySEC, FCA, ASIC, ASIC & GAML, FSRA, FSA Seychelles (verified via live query)
- `CountryID NOT IN (250,219)` → "eToro" entity (250) and United States (219) (verified via live query)
- `PlayerLevelID IN (1,5,3,2,6,7)` → Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond (verified via live query)

These mappings were verified by querying the Dim_ tables. However, the hardcoded IDs in the SP are fragile — if a new regulation is added to eToro's platform and should be IOB-eligible, the SP must be updated manually.

**Action**: Verify with the AML/Product team that the current set of IOB-eligible regulations (CySEC, FCA, ASIC, ASIC & GAML, FSRA, FSA Seychelles) matches the live product configuration. Confirm whether FSRA (UAE) is actually IOB-eligible.

---

### 4. External_Interest_Trade_InterestConsent Schema (VERIFY)

The SP uses `BI_DB_dbo.External_Interest_Trade_InterestConsent`. This is an external table pointing to the `Interest_Trade` schema, which appears to be an interest/consent management system. The columns used are `CID`, `GCID`, `ConsentStatusID`, `ValidFrom`, `ValidTo`. ConsentStatusID=1 = opted-in.

**Action**: Confirm the source system for this external table and whether `ValidFrom` always represents the first opt-in date (or could be reset on re-enrollment). Check if a customer who opted in, opted out, and re-opted in appears once or multiple times (if multiple, the MIN(ValidFrom) may not be the current opt-in start).

---

### 5. etoro_History_Credit Source (VERIFY)

The SP reads from `DWH_dbo.etoro_History_Credit WHERE CompensationReasonID IN (57,62) AND CreditTypeID=6`. These hardcoded IDs need confirmation:
- CompensationReasonID 57 and 62: What IOB reasons do these represent? (e.g., monthly interest credit vs. bonus credit)
- CreditTypeID 6: What credit type does this represent?

**Action**: Look up the Dictionary.CompensationReason and Dictionary.CreditType tables for IDs 57, 62, and 6 to confirm they exclusively map to IOB interest payments and not other credit types that might contaminate the June 2025 interest figure.

---

### 6. UpdateDate Staleness (2026-04-13 — 9 days ago)

Same staleness as sibling AML tables. All three Batch 45 objects have UpdateDate = 2026-04-13.

**Action**: Check OpsDB execution logs for schema-wide disruption since 2026-04-13.

---

### 7. T1 Coverage Verification

| Column | Claimed Tier | Upstream Wiki | Verified? |
|--------|-------------|---------------|-----------|
| CID | T1 — Customer.CustomerStatic | Via Dim_Customer wiki | ✓ |
| Regulation | T1 — Dictionary.Regulation | DB_Schema/etoro/Wiki/Dictionary/Tables/ | ✓ Exists |
| Country/CitizenshipCountry/POBCountry | T1 — Dictionary.Country | Via Dim_Country wiki | ✓ |
| PlayerStatus | T1 — Dictionary.PlayerStatus | Via Dim_PlayerStatus wiki | ✓ |
| PlayerStatusReason | T1 — Dictionary.PlayerStatusReasons | Dim_PlayerStatusReasons wiki | ✓ |
| PlayerStatusSubReasonName | T1 — Dictionary.PlayerStatusSubReasons | Dim_PlayerStatusSubReasons wiki | ✓ |
| Club | T1 — Dictionary.PlayerLevel | Via Dim_PlayerLevel wiki | ✓ |
| RegisteredReal | T1 — Customer.CustomerStatic | Via Dim_Customer wiki | ✓ |
| VerificationLevelID | T1 — BackOffice.Customer | Via Dim_Customer wiki | ✓ |
