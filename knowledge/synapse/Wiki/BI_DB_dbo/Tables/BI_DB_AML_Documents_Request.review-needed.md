# Review Needed — BI_DB_dbo.BI_DB_AML_Documents_Request

**Generated**: 2026-04-22 | **Batch**: 45

---

## Items Requiring Human Review

### 1. Multi-Regulation Row Duplication (VERIFY)

The live data sample shows 31M total rows for 16.4M distinct CIDs (~1.9 rows/CID average), consistent with customers registered under multiple eToro regulatory entities. However, the sample also showed CID 61 appearing 4 times with identical Regulation=CySEC data. This may indicate:
- True duplicate inserts from the SP (ROUND_ROBIN HEAP tables can exhibit phantom duplicates in small TOP N queries), OR
- A genuine data quality issue in the ETL if the same (CID, Regulation) combination is being inserted multiple times.

**Action**: Run `SELECT CID, Regulation, COUNT(*) FROM BI_DB_AML_Documents_Request GROUP BY CID, Regulation HAVING COUNT(*) > 1` to determine if duplicates exist at the (CID, Regulation) level. If duplicates exist, review SP for fan-out in dimension joins.

---

### 2. UpdateDate Staleness (2026-04-13 — 9 days ago)

The live sample shows UpdateDate = 2026-04-13, which is 9 days before generation date (2026-04-22). The SP is listed as Priority 0 Daily in OpsDB. A 9-day staleness gap suggests either:
- The SP has not been running successfully for 9 days, OR
- This is within a known ETL disruption window for the schema.

**Action**: Check OpsDB execution logs for SP_AML_Documents_Request failure history since 2026-04-13.

---

### 3. ScreeningStatus NULL vs NoMatch Distinction (CONFIRM)

In the live data sample, ScreeningStatus is empty (NULL) for several rows. The Dim_ScreeningStatus wiki shows 'Unknown' as one of the values. It is unclear whether NULL in this column means "no screening record exists" or "screening status is Unknown (ScreeningStatusID=0)". The LEFT JOIN on Dim_ScreeningStatus (ON dss.ScreeningStatusID = dc.ScreeningStatusID) would return NULL if Dim_Customer.ScreeningStatusID is NULL, but 'Unknown' if it equals the Unknown ID.

**Action**: Confirm with AML team what NULL ScreeningStatus means operationally. Update description to distinguish NULL (no join match) from 'Unknown' (explicit status).

---

### 4. OpsDB Metadata Error — SP_W_AML_PEP_Customers (CONFIRMED)

OpsDB lists SP_W_AML_PEP_Customers as writing to BI_DB_AML_Documents_Request (Priority 0, Daily, SB_Daily). The SP code clearly shows it writes to BI_DB_W_AML_PEP_Customers and BI_DB_W_AML_PEP_Customers_Trun, and only READS from BI_DB_AML_Documents_Request. This is an OpsDB metadata error — the dependency tracking incorrectly flagged the source table as the target.

**Action**: Flag to OpsDB metadata owner to correct the table-to-SP mapping for SP_W_AML_PEP_Customers.

---

### 5. Has_POI / Has_POA NULL vs 0 Semantics (CONFIRM)

The live data sample shows Has_POI and Has_POA as NULL (not 0) for CID 107. These fields come from Dim_Customer.IsIDProof and Dim_Customer.IsAddressProof. It is unclear whether NULL means "no POI/POA document" (same as 0) or "KYC flags not yet computed for this customer."

**Action**: Confirm with SP_Dim_Customer author whether NULL IsIDProof means the same as 0 (no POI) or has a distinct meaning.

---

### 6. VideoIdent Column Purpose (CONFIRM)

The `DocumentType_VideoIdent`, `DocumentDateAdded_VideoIdent`, and `SuggestedDocumentType_VideoIdent` columns track VideoIdent documents. Based on sibling table BI_DB_AML_German_Video_Ident (newly documented in Batch 45), VideoIdent is used for German AML regulation (BaFin requirements). Confirm whether VideoIdent columns here are exclusively used for German-regulation customers or apply across regulations.

**Action**: Check distribution of non-NULL DocumentDateAdded_VideoIdent by Regulation to determine scope.

---

### 7. T1 Coverage Verification

| Column | Claimed Tier | Upstream Wiki | Verified? |
|--------|-------------|---------------|-----------|
| Regulation | T1 — Dictionary.Regulation | DB_Schema/etoro/Wiki/Dictionary/Tables/ | ✓ File exists |
| Country / CitizenshipCountry / POBCountry | T1 — Dictionary.Country | DB_Schema/etoro/Wiki/Dictionary/Tables/ | ✓ Via Dim_Country wiki |
| PlayerStatus | T1 — Dictionary.PlayerStatus | DB_Schema/etoro/Wiki/Dictionary/Tables/ | ✓ Via Dim_PlayerStatus wiki |
| PlayerStatusReason | T1 — Dictionary.PlayerStatusReasons | Dim_PlayerStatusReasons wiki | ✓ Read in this batch |
| PlayerStatusSubReasonName | T1 — Dictionary.PlayerStatusSubReasons | Dim_PlayerStatusSubReasons wiki | ✓ Read in this batch |
| Club | T1 — Dictionary.PlayerLevel | Via Dim_PlayerLevel wiki | ✓ Confirmed |
| AccountType | T1 — Dictionary.AccountType | Via Dim_AccountType wiki | ✓ Confirmed |
| RiskScoreName | T1 — RiskClassification.dbo.V_RiskClassificationDataLake | ComplianceDBs/RiskClassification/Wiki/dbo/Views/ | ✓ File exists |
| CID | T1 — Customer.CustomerStatic | Via Dim_Customer wiki | ✓ Confirmed |
| RegisteredReal | T1 — Customer.CustomerStatic | Via Dim_Customer wiki | ✓ Confirmed |
| HasWallet | T1 — BackOffice.Customer | Via Dim_Customer wiki | ✓ Confirmed |
| VerificationLevelID | T1 — BackOffice.Customer | Via Dim_Customer wiki | ✓ Confirmed |
| AML_Rank (RiskGroupID) | T1 — Dim_Country | Via Dim_Country wiki | ✓ Confirmed (RiskGroupID mapping 0-4) |
| ScreeningStatus | T3 — live data | No upstream wiki for Dim_ScreeningStatus | ✓ Appropriately T3 |
| EvMatchStatusName | T2 — SP code | No upstream wiki for UserApiDB.Dictionary.EvMatchStatus | ✓ Appropriately T2 |
