---
name: domain-ops-and-onboarding
description: "OPS portal customer-360 + alert queue + CS workflow + monthly cost KPIs. Anchors on three rings: (1) Portal customer-360 ג€” main.bi_output_stg.bi_output_operations_ops_customer_info (45 cols, the denormalised customer view OPS agents work from: RealCID + GCID + VerificationLevelID + IsValidCustomer + IsDepositor + HasWallet + FirstDepositDate + BirthDate + Age + KYC_Country + CountryRiskGroupID + CitizenshipCountry + POB_Country + Regulation + RegulationID + DesignatedRegulationID + PlayerStatus + PlayerStatusReason + PlayerLevel + LastLoggedIn + VerificationLevel3Date + LastDepositDate + Equity + Balance + Has_eMoney_Account + eMoneyStatus + TotalDepositAmountUSD + Phone + FirstName + MiddleName + LastName + Address + ZipCode + Email + PendingClosureStatusID enum 1=No / 2=Suggested for Closure / 3=Approved for Closure + CountryByIP + PIN_Type + PIN + TAX_Type + TaxID), main.bi_output_stg.bi_output_operations_ops_customer_logins (login history per customer), _ops_deposits / _ops_withdrawals / _ops_emoney_customer_info / _ops_emoney_transactions (payment-flow OPS views ג€” authoritative ledger lives in domain-payments), _ops_positions_details / _ops_trading_summary (trading-state OPS rollups ג€” authoritative source in domain-trading), _ops_relations (related-customer graph for KycRelations / RiskRelations alerts). (2) Alerts & fraud detection ג€” main.bi_output_stg.bi_output_operations_risk_alert_management_tool (681k alerts, 102 cols ג€” a fat alert metadata bag with AlertID + CID + TicketID + AlertType + AlertTypeDescription + CategoryName + TriggerType + ResourceType + StatusType + StatusReason + Assignee + ModifiedBy + Comment + CreationDate + ModificationDate + FollowUpDate + ~80 string columns serving as per-rule metadata bags, with many _1 suffix duplicates from upstream merge artefacts; top AlertType values April 2026: MultipleAccounts ~6.8k, SiftScore ~4.5k, NegativeBalanceCheck ~2.2k, GeneralRisk ~1.8k, PossibleCompromisedAccount ~1.2k, HighCORedeem ~1.2k, DividendCheckRequired ~0.9k, BinToRegCountryConflict ~0.7k, MultipleBlockedAccounts ~0.5k, AnnualPlannedInvestmentsVsAnnualDeposits ~0.5k, DepositNameConflict, LinkedAccountRestriction, HighRiskLogin, UsMopUsedInNonUsAccount, AnnualIncomeVsDeposits, LifetimeDeposits, KycRelations, WithdrawNameConflict, RiskRelations, HighTotalDepositsWithin24HoursFromFtdOrHighFTD), main.bi_output_stg.bi_output_operations_opschange_fraud_indicator_report (fraud-indicator change log), main.bi_output_stg.bi_output_operations_yoni_davideresta_alerts (owner-prefixed personal sandbox ג€” treat as non-canonical), _ops_pending_tickets (Assignee-keyed work queue), _ops_audit_trail (action log for all OPS portal interactions). (3) CS workflow & monthly KPIs ג€” main.bi_output_stg.bi_output_operations_sf_cases_prioritization_dashboard (Salesforce-feed case prioritisation), _cs_intelligence_ai_analysis (AI-summarised CS case analysis), _monthly_kpis_cashouts / _monthly_kpis_wires (monthly transaction KPI rollups for cashout / wire-transfer ops), _opshighcashoutclientsemail (high-cashout client email-alert list), _telesign_sinch_cost (Telesign and Sinch SMS provider cost tracking for phone-verification 2FA flows ג€” both are SMS providers), _bi_cy_cost_budget / _cost_import_file (calendar-year cost & budget vs actual), _confluence_embeddings (Confluence document embeddings for OPS knowledge search)."
triggers:
  - ops_customer_info
  - bi_output_operations_ops_customer_info
  - ops_customer_logins
  - ops_deposits
  - ops_withdrawals
  - ops_emoney_customer_info
  - ops_emoney_transactions
  - ops_positions_details
  - ops_trading_summary
  - ops_relations
  - ops_pending_tickets
  - ops_audit_trail
  - risk_alert_management_tool
  - bi_output_operations_risk_alert_management_tool
  - opschange_fraud_indicator_report
  - sf_cases_prioritization_dashboard
  - cs_intelligence_ai_analysis
  - yoni_davideresta_alerts
  - monthly_kpis_cashouts
  - monthly_kpis_wires
  - opshighcashoutclientsemail
  - telesign_sinch_cost
  - telesign
  - sinch
  - bi_cy_cost_budget
  - cost_import_file
  - confluence_embeddings
  - AlertType
  - AlertTypeDescription
  - TriggerType
  - StatusType
  - StatusReason
  - Assignee
  - FollowUpDate
  - SiftScore
  - NegativeBalanceCheck
  - PossibleCompromisedAccount
  - HighCORedeem
  - DividendCheckRequired
  - BinToRegCountryConflict
  - MultipleBlockedAccounts
  - AnnualPlannedInvestmentsVsAnnualDeposits
  - DepositNameConflict
  - LinkedAccountRestriction
  - HighRiskLogin
  - UsMopUsedInNonUsAccount
  - AnnualIncomeVsDeposits
  - LifetimeDeposits
  - KycRelations
  - WithdrawNameConflict
  - RiskRelations
  - HighTotalDepositsWithin24HoursFromFtdOrHighFTD
  - PendingClosureStatusID
  - PendingClosureStatus
  - Approved for Closure
  - Suggested for Closure
  - Has_eMoney_Account
  - eMoneyStatus
  - PIN_Type
  - TAX_Type
  - TaxID
  - PlayerLevel
  - PlayerStatusReason
  - TicketID
  - AmopCustomerName
  - DepositCustomerName
  - KycCustomerName
sample_questions:
  - "Show me the alert queue for CID X"
  - "Top alert types this week"
  - "How many MultipleAccounts alerts last month?"
  - "Which agent is assigned the most pending tickets right now?"
  - "Show me customers in 'Approved for Closure' state"
  - "What's the total Telesign + Sinch SMS cost YTD?"
  - "Cashout monthly KPI April 2026 vs March 2026"
  - "Customers with HighCORedeem alert + low equity"
  - "How many open alerts older than 30 days?"
  - "Show CS cases prioritised AI-Critical this week"
  - "What does PendingClosureStatusID = 3 mean?"
  - "What's the LastLoggedIn freshness gap for our portal customer-360?"
  - "How do I look up an OPS-tagged eMoney customer's IBAN?"
  - "Find all CS-AI-flagged churn cases this month"
required_tables:
  - main.bi_output_stg.bi_output_operations_ops_customer_info
  - main.bi_output_stg.bi_output_operations_ops_customer_logins
  - main.bi_output_stg.bi_output_operations_ops_deposits
  - main.bi_output_stg.bi_output_operations_ops_withdrawals
  - main.bi_output_stg.bi_output_operations_ops_emoney_customer_info
  - main.bi_output_stg.bi_output_operations_ops_emoney_transactions
  - main.bi_output_stg.bi_output_operations_ops_positions_details
  - main.bi_output_stg.bi_output_operations_ops_trading_summary
  - main.bi_output_stg.bi_output_operations_ops_relations
  - main.bi_output_stg.bi_output_operations_ops_pending_tickets
  - main.bi_output_stg.bi_output_operations_ops_audit_trail
  - main.bi_output_stg.bi_output_operations_risk_alert_management_tool
  - main.bi_output_stg.bi_output_operations_opschange_fraud_indicator_report
  - main.bi_output_stg.bi_output_operations_sf_cases_prioritization_dashboard
  - main.bi_output_stg.bi_output_operations_cs_intelligence_ai_analysis
  - main.bi_output_stg.bi_output_operations_monthly_kpis_cashouts
  - main.bi_output_stg.bi_output_operations_monthly_kpis_wires
  - main.bi_output_stg.bi_output_operations_telesign_sinch_cost
domain_tags:
  - ops
  - alerts
  - cs
  - tickets
  - portal
  - sla
  - cost
  - fraud
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# OPS portal customer-360 + alert queue + CS workflow

Three concentric rings around the OPS team's daily work: the customer-360 view they LOOK UP, the alert queue they RESPOND TO, and the CS-workflow / cost tables they REPORT FROM.

## When to Use

Load for questions about:

- OPS portal customer-360 lookups (45-col denormalised view)
- Alert queue contents, types, assignee workload, age
- Fraud-indicator change log
- Pending tickets / CS case prioritisation
- Audit trail for an OPS-portal action
- Monthly cashout / wire KPIs
- Telesign / Sinch SMS-provider cost
- Cost / budget rollups
- Confluence-embedding search (rare; internal)

Do NOT load for:

- KYC document analysis ג€” see [`kyc-document-pipeline.md`](kyc-document-pipeline.md)
- Registration funnel / EV routing ג€” see [`electronic-verification-and-registration-funnel.md`](electronic-verification-and-registration-funnel.md)
- Customer master attributes (regulation, club, PlayerStatus) AT REGULATORY GRAIN ג€” `../domain-customer-and-identity/customer-master-record.md` (the OPS `ops_customer_info` is a denorm for portal use, not the master)
- Authoritative deposit / withdraw / eMoney ledger ג€” `../domain-payments/`. The `ops_deposits` / `ops_withdrawals` / `ops_emoney_*` are denormalised OPS-portal rollups.
- Authoritative trading positions ג€” `../domain-trading/`. The `ops_positions_details` is a denormalised view.
- AML risk-rule methodology behind an `AlertType` ג€” `../domain-compliance-and-aml/aml-risk-scoring.md`. This sub-skill describes the alert QUEUE; compliance owns the RULES.

## Scope

In scope: the 18 OPS-portal / alert / CS / cost tables above; the AlertType enum (live values listed in description); the PendingClosureStatusID enum (1=No, 2=Suggested for Closure, 3=Approved for Closure); the OPS-side denormalisation of customer + payment + position state into portal-friendly columns; the 102-column generic-bag shape of `risk_alert_management_tool` with its `_1`-suffix de-dupe artefacts; the Telesign + Sinch SMS provider cost tracking; the monthly KPI rollups (cashouts, wires).

Out of scope: the source-of-truth payment ledger / trading position / customer master tables; AML risk-scoring methodology; the OPS Tableau dashboard configuration; the BackOffice agent UI.

Last verified: 2026-05-28

## Critical Warnings

> **Tier 0 ג€” Filter Contract.** Per-CID rollups out of OPS portal tables (e.g. "open alerts by club tier", "monthly cashout count by regulation") MUST apply `../cross-cutting/valid-users-filter-contract.md`. Pure work-queue management ("Assignee X's pending tickets right now") does not need the contract ג€” but most analytical questions do.

1. **Tier 1 ג€” `risk_alert_management_tool` is a fat 102-column generic alert-metadata bag.** Most columns are `string`-typed and serve as per-rule metadata. The actual alert identity lives in `AlertType` / `AlertTypeDescription` / `CategoryName` / `TriggerType` / `RuleType`. Different alert types populate different metadata columns:
   - `MultipleAccounts` / `KycRelations` / `RiskRelations` ג†’ `RelatedCids` + `TotalCidsCount`
   - `SiftScore` ג†’ `SiftScore`
   - `NegativeBalanceCheck` ג†’ `Threshold` + `YearlySum`
   - `BinToRegCountryConflict` ג†’ `MopBankCountryCode` + `MopCountryCode`
   - `HighCORedeem` / `LifetimeDeposits` / `AnnualIncomeVsDeposits` ג†’ `TotalDeposit` + `Threshold`
   - `HighRiskLogin` ג†’ `DeviceId`
   - `DepositNameConflict` / `WithdrawNameConflict` ג†’ `NameConflictDescription` + `NameConflictScore` + `NameOnMop1` + `CustomerName`
   - `PhoneVerification`-related ג†’ `TelesignScore` + `AllowedTelesignScore`
   - `DividendCheckRequired` ג†’ `EventType`

   Always start filtering at `AlertType` before extracting rule-specific columns. Joining rule-specific columns across different AlertType rows is meaningless.

2. **Tier 1 ג€” The `_1`-suffix duplicate columns (`Gcid_1`, `MeansOfPayments1`, `DepositId1`, `ChangeDate1`, `RelatedCids1`, `ForceTriggerAlert1`, `DaysPeriod1`, `FundingId1`, `FundingTypeId1`, `ChangeType1`, `ForceTriggerAlertReason1`, `NumberOfMOPsWithinTimeFrame1`, `CustomerName`, `Name1`, `StatusChangeReason1`, `TotalDeposit1`, `StatusName1`, `SubReason1`, `WhenExpression1`, `DeviceId1`, `FtdDate1`, `NameOnMop1`, `RiskClassification1`) come from an upstream-merge artefact** ג€” two physical data sources were unioned with non-identical column sets, and the deduper appended `_1` to disambiguate. For active queries prefer the NON-suffixed column unless you are doing an audit reconciliation. Note `Gcid` appears in this table as `string` (not bigint) ג€” implicit-cast when joining to Mixpanel / customer.

3. **Tier 1 ג€” `ops_customer_info` is OPS-portal DENORM, NOT customer master.** It joins customer + dim + verification + payment + eMoney + extendeduserfield (for PIN, TaxID) + dim_country (for CountryByIP). Refresh cadence may lag the source-of-truth tables by hours. For "current customer master state" join to `customer_snapshot_v` in `../domain-customer-and-identity/customer-master-record.md`; for "what OPS sees right now" use `ops_customer_info`.

4. **Tier 2 ג€” `PendingClosureStatusID` enum is OPS-workflow state, not regulatory closure.** Values: 1 = No (default), 2 = Suggested for Closure (an OPS agent / rule has flagged), 3 = Approved for Closure (cleared for action). The actual closure event flows separately into `customer master` / `Dim_Customer` and downstream tables. "Approved for Closure" customers may still be active until the closure job runs.

5. **Tier 2 ג€” `Equity` and `Balance` on `ops_customer_info` are as-of "previous day".** Not real-time. For real-time / period-correct customer equity, use `BI_DB_PositionPnL` (`domain-trading`) or the customer-snapshot SCD walk.

6. **Tier 2 ג€” `ops_deposits` / `ops_withdrawals` / `ops_emoney_transactions` are OPS-portal flattenings; the authoritative ledger lives in `domain-payments`.** Use the OPS versions for case-investigation context (who-did-what-when from an OPS perspective with all the relevant metadata pre-joined). Use the payments-domain canonical tables (`v_payment_transactions_payment_transactions`, `bi_db.bronze_ribbon_paymentitems`, etc.) for revenue / accounting / period-correct truth.

7. **Tier 2 ג€” `ops_relations` is the related-customer graph for KycRelations and RiskRelations alerts.** Customers linked by IP, device, name, payment-method, IBAN, etc. Drives the `RelatedCids` and `TotalCidsCount` columns on `risk_alert_management_tool`. For network analysis ("show me everyone connected to CID X") this is the starting point.

8. **Tier 2 ג€” `yoni_davideresta_alerts` is OWNER-PREFIXED.** Personal sandbox of two named individuals. Likely temporary / experimental / data-quality investigation. Treat as non-canonical. Production alert tables are `risk_alert_management_tool` and `opschange_fraud_indicator_report`.

9. **Tier 3 ג€” Top AlertType values (April 2026 / 30-day sample): MultipleAccounts ~6.8k, SiftScore ~4.5k, NegativeBalanceCheck ~2.2k, GeneralRisk ~1.8k, PossibleCompromisedAccount ~1.2k, HighCORedeem ~1.2k, DividendCheckRequired ~0.9k, BinToRegCountryConflict ~0.7k, MultipleBlockedAccounts ~0.5k, AnnualPlannedInvestmentsVsAnnualDeposits ~0.5k, DepositNameConflict / LinkedAccountRestriction / HighRiskLogin / UsMopUsedInNonUsAccount / AnnualIncomeVsDeposits / LifetimeDeposits / KycRelations / WithdrawNameConflict / RiskRelations / HighTotalDepositsWithin24HoursFromFtdOrHighFTD ~100-500 each.** Use these as the primary filter dimension.

10. **Tier 3 ג€” `telesign_sinch_cost` tracks SMS-provider cost for phone-verification / 2FA flows.** Telesign and Sinch are the two SMS providers used. This is OPS-side cost, not customer-charged. Combined cost is one of the line items in `bi_cy_cost_budget`.

11. **Tier 3 ג€” `confluence_embeddings` is a OPS-side semantic-search aid over the internal Confluence wiki.** Embedding-vector storage for use by the OPS knowledge tools. Not analytical traffic.

12. **Tier 3 ג€” `cs_intelligence_ai_analysis` is GPT-summarised CS case analysis.** Useful for "what kinds of issues drove cases last week" ג€” search by AI-generated category. Like `exp_llm_description` on the product-analytics side, treat as a search/summary aid not authoritative.

13. **Tier 3 ג€” `ops_audit_trail` is the OPS-portal action log.** When an agent changes a customer's status, adds a comment, approves a document, etc. ג€” those actions land here. Useful for "who approved this document and when" beyond the manager-id-on-document. The actual MANAGER who decided is on `documentanalysis.ManagerID` / `ProofOfIdentity_Manager` etc.

## Canonical query patterns

```sql
-- Open alerts by type, this week
SELECT AlertType, COUNT(*) AS open_alerts
FROM main.bi_output_stg.bi_output_operations_risk_alert_management_tool
WHERE CreationDate >= TIMESTAMP'2026-05-21'
  AND StatusType IN ('Open', 'In Progress')
GROUP BY AlertType
ORDER BY open_alerts DESC;

-- Assignee workload distribution
SELECT Assignee, COUNT(*) AS open_alerts, MIN(CreationDate) AS oldest_open
FROM main.bi_output_stg.bi_output_operations_risk_alert_management_tool
WHERE StatusType IN ('Open', 'In Progress')
  AND Assignee IS NOT NULL AND Assignee <> ''
GROUP BY Assignee
ORDER BY open_alerts DESC;

-- MultipleAccounts alert with related customers
SELECT CID, AlertID, RelatedCids, TotalCidsCount,
       CreationDate, StatusType, Assignee, Comment
FROM main.bi_output_stg.bi_output_operations_risk_alert_management_tool
WHERE AlertType = 'MultipleAccounts'
  AND CreationDate >= TIMESTAMP'2026-05-01'
ORDER BY TotalCidsCount DESC NULLS LAST
LIMIT 50;

-- OPS customer-360 lookup for a single CID
SELECT *
FROM main.bi_output_stg.bi_output_operations_ops_customer_info
WHERE RealCID = <YOUR_CID>;

-- SMS cost trend
SELECT * FROM main.bi_output_stg.bi_output_operations_telesign_sinch_cost
ORDER BY <date_col> DESC LIMIT 50;
```

## Skill provenance

- **Primary sources.** UC live probes on 2026-05-28: `risk_alert_management_tool` 681k rows / 102 cols (generic-bag shape confirmed, `_1` suffix duplicates inventoried, top AlertType values measured for April 2026: MultipleAccounts ~6.8k, SiftScore ~4.5k, etc.); `ops_customer_info` 45 cols with business-commented schema confirming PendingClosureStatusID enum and the OPS-side denorm shape.
- **Usage data.** Class C: `ops_customer_info` 35q / 7-day; Genie "OPS - General Genie" 41 q/w. AlertType-bag pattern surfaces frequently in support-investigation queries.
- **Federation.** [`kyc-document-pipeline.md`](kyc-document-pipeline.md), [`electronic-verification-and-registration-funnel.md`](electronic-verification-and-registration-funnel.md), `../domain-payments/`, `../domain-trading/`, `../domain-compliance-and-aml/aml-risk-scoring.md`, `../cross-cutting/valid-users-filter-contract.md`.
