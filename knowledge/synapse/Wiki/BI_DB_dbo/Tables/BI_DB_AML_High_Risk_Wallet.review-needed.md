# Review Needed — BI_DB_dbo.BI_DB_AML_High_Risk_Wallet

**Generated**: 2026-04-22 | **Batch**: 45

---

## Items Requiring Human Review

### 1. Risk_before_Wallet Flag Semantics (CONFIRM)

The `Risk_before_Wallet` column uses this logic:
```sql
CASE WHEN pp.PreviousRiskUpdateDate IS NULL AND jj.FirstWalletDate >= pp.FirstDepositDate THEN 1
     WHEN jj.FirstWalletDate IS NOT NULL AND jj.FirstWalletDate >= pp.PreviousRiskUpdateDate THEN 1
     ELSE 0 END
```
The documented interpretation is: 1 = customer was already High Risk at or before wallet enrollment; 0 = wallet was opened before risk escalation.

However, CASE 2 (`FirstWalletDate >= PreviousRiskUpdateDate`) is ambiguous: `PreviousRiskUpdateDate` is the date when the PREVIOUS (pre-High) risk score was set. A wallet date on or after the previous risk date does not clearly indicate whether the customer was already High Risk at wallet time, since the current High risk was set AFTER PreviousRiskUpdateDate.

**Action**: Confirm with SP author (or AML team using this table) what 1 means operationally. In particular, clarify CASE 2 semantics: does `FirstWalletDate >= PreviousRiskUpdateDate` mean "wallet opened during or after the last risk score change" (which would include the transition TO High Risk)?

---

### 2. Multi-Regulation Duplicates (VERIFY)

566K total rows for 143K distinct CIDs = ~3.97 rows/CID average. Sample shows CID 18544 appearing 4 times with identical data (Regulation=FSA Seychelles, all other columns identical). This is higher than expected even for multi-regulation customers. The same ROUND_ROBIN HEAP duplicate artifact seen in BI_DB_AML_Documents_Request may be present here.

**Action**: Run `SELECT CID, Regulation, COUNT(*) FROM BI_DB_AML_High_Risk_Wallet GROUP BY CID, Regulation HAVING COUNT(*) > 1` to verify whether (CID, Regulation) is unique or if there are genuine duplicates.

---

### 3. HasWallet vs FirstWalletDate Discrepancy Possible

The `HasWallet` column comes from BackOffice.Customer (current state via Dim_Customer), while `FirstWalletDate` comes from EXW_Wallet.CustomerWalletsView (historical event). A customer may have `HasWallet=0` but `FirstWalletDate IS NOT NULL` if they deactivated their wallet after enrolling.

**Action**: Run `SELECT COUNT(*) FROM BI_DB_AML_High_Risk_Wallet WHERE HasWallet = 0 AND FirstWalletDate IS NOT NULL` to quantify. If significant, document this discrepancy more explicitly in the Business Logic section.

---

### 4. EXW_Wallet.CustomerWalletsView Schema Clarification (VERIFY)

The SP references `EXW_Wallet.CustomerWalletsView` — this appears to be a cross-schema reference within Synapse (EXW_dbo schema, via a wallet-specific view). The `Occurred` column is used as the wallet enrollment timestamp.

**Action**: Confirm that `EXW_Wallet.CustomerWalletsView` is indeed accessible from BI_DB_dbo in the production environment, and that `Occurred` represents wallet enrollment (not a transaction date). Add EXW_Wallet schema wiki path when the EXW_dbo wiki is complete.

---

### 5. UpdateDate Staleness (2026-04-13 — 9 days ago)

Same staleness issue as BI_DB_AML_Documents_Request. UpdateDate = 2026-04-13, 9 days before generation (2026-04-22).

**Action**: Check OpsDB execution logs for SP_AML_High_Risk_Wallet. Likely the same schema-wide disruption as the sibling AML tables.

---

### 6. T1 Coverage Verification

| Column | Claimed Tier | Upstream Wiki | Verified? |
|--------|-------------|---------------|-----------|
| CID | T1 — Customer.CustomerStatic | Via Dim_Customer wiki | ✓ |
| GCID | T1 — Customer.CustomerStatic | Via Dim_Customer wiki | ✓ |
| Regulation | T1 — Dictionary.Regulation | DB_Schema/etoro/Wiki/Dictionary/Tables/ | ✓ Exists |
| Country | T1 — Dictionary.Country | Via Dim_Country wiki | ✓ |
| RiskGroupID | T1 — Dim_Country | Dim_Country wiki in DWH_dbo | ✓ (0-4 mapping confirmed) |
| PlayerStatus | T1 — Dictionary.PlayerStatus | Via Dim_PlayerStatus wiki | ✓ |
| Club | T1 — Dictionary.PlayerLevel | Via Dim_PlayerLevel wiki | ✓ |
| RiskScoreName | T1 — V_RiskClassificationDataLake | ComplianceDBs/RiskClassification/Wiki/dbo/Views/ | ✓ File exists |
| RiskScore_Explanation | T1 — V_RiskClassificationDataLake | Same file | ✓ Element #1 confirmed |
| PreviousRiskUpdateDate | T1 — V_RiskClassificationDataLake | Same file | ✓ Element #92 confirmed |
| HasWallet | T1 — BackOffice.Customer | Via Dim_Customer wiki | ✓ |
| ScreeningStatus | T3 — live data | No upstream wiki for Dim_ScreeningStatus | ✓ Appropriately T3 |
