# EXW_dbo.Hourly_OmnibusBalances — Review Needed

**Object**: EXW_dbo.Hourly_OmnibusBalances  
**Generated**: 2026-04-20  
**Review Priority**: Low (operational KPI table, no downstream SP consumers)

---

## Open Items

### RN-001 — CryptoID Tier Inconsistency Across Hourly Tables

**Category**: Cross-object consistency  
**Severity**: Low (documentation accuracy)

Hourly_OmnibusBalances documents CryptoID as **Tier 1** (verbatim from WalletDB.Wallet.V_BI_WalletBalances upstream wiki: "The cryptocurrency this balance measures. FK to Wallet.CryptoTypes.CryptoID. Combined with WalletId and DateTo for unique identification."). Hourly_CustomerBalances (Batch 6) documents CryptoID as **Tier 2** because the upstream wiki was not consulted at documentation time.

**Action needed**: Update `Hourly_CustomerBalances.md` §4 (Elements) to re-classify CryptoID as Tier 1 and use the verbatim upstream text. Also update `Hourly_CustomerBalances.lineage.md` tier summary row from Tier 2 → Tier 1.

---

### RN-002 — Downstream Tableau Consumers Not Identified

**Category**: Lineage completeness  
**Severity**: Medium (change impact)

No SSDT stored procedures or views reference EXW_dbo.Hourly_OmnibusBalances. The wiki notes the table is consumed directly by Tableau dashboards for operational KPI monitoring of omnibus wallet positions. The specific Tableau workbooks and data sources are not identified.

**Action needed**: Identify Tableau workbooks that query EXW_dbo.Hourly_OmnibusBalances directly (likely via Synapse ODBC or published data source). Without this, change impact assessment is incomplete when altering the table or SP.

---

### RN-003 — WalletType C2F and StakingRefund Low Row Counts

**Category**: Data completeness / business validation  
**Severity**: Low

Current footprint shows C2F = 4 rows (1 wallet) and StakingRefund = 4 rows (1 wallet). These represent the minimum possible — one wallet × 4 BalanceDates. It is unclear whether:
- These wallet types are still actively used (non-zero balances), or
- They are legacy/deprecated types retained in WalletPool but with zero balances

The SP includes no zero-balance filter for OmnibusBalances, so these rows persist regardless of balance value.

**Action needed**: Confirm with EXW team whether C2F and StakingRefund omnibus wallets are still operationally active. If deprecated, document expected zero-balance state in Business Meaning §1.

---

### RN-004 — InstrumentID NULL for 17% of Rows

**Category**: Data quality documentation  
**Severity**: Low (expected behavior, but underdocumented)

68 of 404 rows (17%) have NULL InstrumentID. The wiki documents this as "ERC-20 tokens without a direct eToro instrument mapping." It is not fully established whether:
- All ERC-20 tokens will always have NULL InstrumentID (by design), or
- Some ERC-20 tokens could gain an InstrumentID as new instruments are listed

**Action needed**: Confirm with EXW/Product whether new ERC-20 token listings always get an InstrumentID assigned, or whether NULL is permanent for some token categories. If permanent, the description should say "ERC-20 tokens without an eToro instrument — NULL is expected and permanent for these tokens."

---

### RN-005 — @d DATE Parameter Accepted but Ignored

**Category**: Interface documentation  
**Severity**: Informational

SP_EXW_Hourly accepts a `@d DATE` parameter but does not use it — all balance dates are derived from GETDATE() at runtime. This means callers cannot request a specific date via the parameter. The wiki documents this behavior correctly but it may surprise consumers who expect date-parameterized behavior consistent with other EXW SPs.

**Action needed**: No wiki change needed (already documented). Consider adding a code comment to SP_EXW_Hourly explaining why @d is retained but unused (backward compatibility? scheduler contract?).

---

*Review items: 5 | Blocking: 0 | Priority updates: RN-001 (CryptoID tier fix in CustomerBalances), RN-002 (Tableau lineage)*
