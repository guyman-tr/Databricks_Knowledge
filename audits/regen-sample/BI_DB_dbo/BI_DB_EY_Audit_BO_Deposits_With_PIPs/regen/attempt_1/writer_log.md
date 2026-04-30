MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis**

DDL from bundle: 38 columns, ROUND_ROBIN distribution, HEAP index. This is a BI_DB reporting table populated by `SP_EY_Audit_BO_Deposits_With_PIPs`.

PHASE 1 CHECKPOINT: PASS

**PHASE 2 — Live Data Sampling**
15.1M rows, date range 2023-01-01 to 2025-10-27. All sampled rows have PaymentStatusID=2 (Approved) and IsCreditReportValidCB=1, consistent with the SP's WHERE filter.

PHASE 2 CHECKPOINT: PASS

**PHASE 3 — Distribution Analysis (capped at 3 categorical columns)**

Matching regex: Status, Currency, Regulation, FundingType, CardType, DepositType. Picking: Status, Regulation, FundingType.
PHASE 3 CHECKPOINT: PASS

**PHASE 4 — Lookup Resolution**: All dimension tables referenced (Dim_Customer, Dim_Label, Dim_Country, Dim_Regulation, Dim_Funnel, Dim_Currency, Dim_PaymentStatus, Dim_FundingType, Dim_CardType, Dim_Range, Fact_SnapshotCustomer, Fact_BillingDeposit, Fact_CustomerAction) have wikis in the bundle.

PHASE 4 CHECKPOINT: PASS

**PHASE 5 — JOIN Analysis**: SP code analyzed from bundle. Key JOINs:
- `#hcDeposits` (History Credit CreditTypeID=1) LEFT JOIN `External_etoro_Billing_Deposit` on DepositID
- LEFT JOIN `Dim_Customer` on CID=RealCID → ExternalID, LabelID, CountryIDByIP, RegulationID, PlayerLevelID, FirstName, LastName
- LEFT JOIN `Dim_Label`, `Dim_Country`, `Dim_Regulation`, `Dim_Funnel`, `Dim_Currency`, `Dim_PaymentStatus` for lookups
- JOIN `Fact_SnapshotCustomer` + `Dim_Range` for IsCreditReportValidCB
- LEFT JOIN `Fact_BillingDeposit` for CardTypeIDAsInteger, BankNameAsString, Depot, FundingType
- LEFT JOIN `Dim_CardType` for CarTypeName
- LEFT JOIN `External_etoro_Billing_ConversionFeeOverride` for DepositFee (→ ConversionOverridePIPSConfig)

PHASE 5 CHECKPOINT: PASS

**PHASE 6 — Business Logic**:
1. **CB-Valid Deposit Filter**: Only deposits where `IsCreditReportValidCB=1` at the time of deposit (point-in-time via Fact_SnapshotCustomer + Dim_Range)
2. **PIPs Calculation**: `(Amount * BaseExchangeRateComputed) - (Amount * ExchangeRate)` — the conversion fee (Payment In Pips)
3. **Reciprocal Flag**: `CurrencyID=1 → 1` (USD deposits have reciprocal=1)
4. **BaseExchangeRateComputed**: For Wire (FundingTypeID=2) non-USD deposits, base rate is adjusted by `ExchangeRate + ExchangeRate/10000`
5. **Missing Date Auto-Fill**: SP recursively calls itself for any dates between last loaded DateID and @date
6. **Rollback Amount**: Computed from `DepositRollbackTracking` or from History.Credit chargeback/refund entries

PHASE 6 CHECKPOINT: PASS

**PHASE 7 — View Dependency Scan**: No views reference this table in the bundle.

PHASE 7 CHECKPOINT: PASS ([-] no views found)

**PHASE 8 — SP Scan**: Writer SP is `SP_EY_Audit_BO_Deposits_With_PIPs` (in bundle). No other SPs reference this table based on bundle resolution.

PHASE 8 CHECKPOINT: PASS

**PHASE 9 — SP Logic**: Full SP code analyzed (in bundle). Column-to-source mapping traced. All 38 columns traced to their source tables via the SP's multi-step temp table pipeline.

PHASE 9 CHECKPOINT: PASS

**PHASE 9B — ETL Orchestration**: Daily refresh, DELETE+INSERT pattern on ModificationDate window. Auto-fills missing dates by recursive SP call.

PHASE 9B CHECKPOINT: PASS

**PHASE 10 — Jira**: [-] Atlassian MCP not available in this session.

PHASE 10 CHECKPOINT: PASS (skipped — no Atlassian MCP)

**PHASE 10A — Upstream Wiki**: Bundle contains 13 upstream wikis. All key dimension and fact table wikis resolved. Rich Tier 1 inheritance available.

PHASE 10A CHECKPOINT: PASS

**PHASE 10B — Column Lineage**: Writing lineage file first.

```
PHASE GATE — BI_DB_dbo.BI_DB_EY_Audit_BO_Deposits_With_PIPs:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views         [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files. Lineage first, then wiki, then review-needed.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_EY_Audit_BO_Deposits_With_PIPs:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_BO_Deposits_With_PIPs/regen/attempt_1/BI_DB_EY_Audit_BO_Deposits_With_PIPs.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_BO_Deposits_With_PIPs/regen/attempt_1/BI_DB_EY_Audit_BO_Deposits_With_PIPs.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_EY_Audit_BO_Deposits_With_PIPs/regen/attempt_1/BI_DB_EY_Audit_BO_Deposits_With_PIPs.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 20    Tier2: 19    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
