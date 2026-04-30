# BackOffice Schema - Overview

**Database**: etoro | **Schema**: BackOffice
**Documentation**: [Full Index](_index.md) | **Glossary**: [Business Glossary](../_glossary.md) | **Semantic Index**: [Semantic Index](../_semantic_index.md)

---

## What Is the BackOffice Schema?

The BackOffice schema is eToro's internal operations platform layer - the system used by BackOffice staff (sales agents, compliance officers, risk analysts, account managers, operations) to govern every customer account on the platform. While Customer.CustomerStatic stores who the customer is, and Trade.PositionTbl stores what they trade, BackOffice.Customer stores how eToro treats them: their regulatory assignment, KYC verification level, sales agent, MiFID II categorization, AML flags, and risk status.

The schema serves two primary audiences:
- **BackOffice agents**: Through a web application that reads/writes these tables via stored procedures
- **Downstream systems**: DWH/data lake pipelines, SalesForce CRM, Dynamics CRM, and compliance reporting systems

---

## Scale

| Metric | Value |
|--------|-------|
| Total objects | 502 |
| Tables | 68 |
| Views | 28 |
| Functions | 58 |
| Stored Procedures | 348 |
| Customers governed | 18.744M (one row per CID in BackOffice.Customer) |
| KYC documents | 8.78M (BackOffice.CustomerDocument) |
| Active risk flags | 1.46M (BackOffice.CustomerRisk) |
| Affiliates | 45,621 (BackOffice.Affiliate) |
| BackOffice staff | 960 (505 active) (BackOffice.Manager) |
| Lifetime financial summaries | 6.736M rows (BackOffice.CustomerAllTimeAggregatedData_1) |

---

## Core Business Domains

### 1. Customer Governance (BackOffice.Customer)

The single most important table. 50 columns covering every operational dimension of a customer account:

- **Regulatory**: RegulationID (CySEC 39.4%, BVI 38.9%, FCA 6.2%), DesignatedRegulationID, TradingRiskStatusID (computed)
- **KYC/Compliance**: VerificationLevelID (0-3), Verified, KycState, DocumentStatusID, IsEDD, EIDStatusID, EvMatchStatus
- **MiFID II**: MifidCategorizationID (1=Retail 97.3%), AsicClassificationID, SeychellesCategorizationID
- **Sales**: ManagerID (assigned agent), FTDPoolManagerID (FTD-credited agent), SalesStatusID
- **AML**: WorldCheckID, GDCCheckID, AMLComment (auto-date-prefixed by trigger), RiskClassificationID
- **Product**: AccountTypeID, HasWallet, GuruStatusID, IsCopyBlocked, FXEligibilityDate

Full audit trail via three triggers writing to History.BackOfficeCustomer with ValidFrom/ValidTo timestamps. RegulationID changes additionally write to BackOffice.RegulationChangeLog.

### 2. KYC Document Management

```
Customer uploads document
        |
        v
BackOffice.CustomerDocument (metadata, AI suggestion via Au10tix/Onfido)
        |
        v
BackOffice.CustomerDocumentToDocumentType (formal classification by agent)
        |
        v
BackOffice.DocumentVendors (vendor processing results)
BackOffice.DocumentAuthenticationReasons (rejection reasons)
```

8.78M documents from 2009 to present. GCID-indexed for cross-account person-level retrieval. AI vendors suggest document types; agents confirm or override. Only 249 of 8.78M documents marked Obsolete.

### 3. Risk Alert Management

BackOffice.CustomerRisk is the Risk team's alert registry. Composite PK on (GCID, RiskStatusID) - one row per risk type per person. 90 alert types in 17 categories:

- **Deposit velocity**: OverTheLimit, FTDOverDailyLimit, CreditCardVelocity (Cat 1-2)
- **Fraud**: BinInBlackList, FraudRequestResponseMismatch, CreditCardBruteForce (Cat 7)
- **High-risk country**: HighRiskFATFCountry, HighRiskAccountCountry (Cat 9)
- **Document quality**: FakeID, FakeBills, PendingVerification (Cat 11)
- **Withdraw behavior**: WithdrawWithShortTermTrades, WithdrawWithLowTradingRatio (Cat 17)

Lifecycle: automated rule fires (RiskEventStatusID=1/On) -> agent investigates (2/InProcess) -> resolves (3/Off). Active flags may trigger deposit blocks, withdrawal suspensions, or account freezes.

### 4. Customer Financial Aggregation (MIMO)

Three parallel aggregation tables updated continuously by UpsertIntoAggregationTablesAction:

| Table | Granularity | Rows | Key Use |
|-------|------------|------|---------|
| CustomerAllTimeAggregatedData_1 | Lifetime per CID | 6.736M | Customer header, risk reports, SF CRM sync, DWH |
| CustomerMTDAggregatedData_1 | Month-to-date by year/month | varies | Monthly performance reporting |
| CustomerDTDAggregatedData_1 | Day-to-date by date | varies | Daily activity tracking |

Event source: History.ActiveCredit (CreditTypeID mapping: 1=Deposit, 2=Cashout, 4=Position close P&L, 7=Bonus, etc.). Near-real-time delta upsert pattern. SalesForce CRM re-sync triggered by LastOccurredTriggerToSF.

### 5. Affiliate Program

BackOffice.Affiliate is the affiliate settings table. 45,621 affiliates whose AffiliateID = their own customer CID. Status changes sync to Dynamics CRM via Service Broker. SpreadGroupID changes cascade to all referred customers (Customer.Customer.SpreadGroupID update). Campaign/CampaignGroup track marketing acquisition channels.

### 6. Staff Management and Authentication

BackOffice.Manager is the authentication anchor for 960 staff (505 active). Every operational action in BackOffice carries ManagerID for audit trail. Authentication via BackOffice.LogIn (Login+IsActive=1 check). ManagerGroupID routes queries to multi-environment DBs (346 managers, primarily MIMO ops).

---

## Object Type Breakdown

### Tables (68)

| Table | Purpose | Scale |
|-------|---------|-------|
| BackOffice.Customer | Customer governance - regulatory, KYC, sales, AML state | 18.744M rows |
| BackOffice.CustomerDocument | KYC document registry | 8.78M rows |
| BackOffice.CustomerRisk | Risk alert flags | 1.46M rows |
| BackOffice.CustomerAllTimeAggregatedData_1 | Lifetime financial aggregates | 6.736M rows |
| BackOffice.Manager | BackOffice staff directory | 960 rows |
| BackOffice.Affiliate | Affiliate partner settings | 45,621 rows |
| BackOffice.CustomerDocumentToDocumentType | Formal document type classifications | high volume |
| BackOffice.CustomerNotes | Customer notes history | high volume |
| BackOffice.Bonus / BonusType | Bonus definitions and types | low volume |
| BackOffice.Task | Agent task management | low volume |
| BackOffice.KYC | US NFA/CFTC KYC questionnaire responses | 0 rows (US entity) |
| BackOffice.RegulationChangeLog | Audit log of RegulationID changes | audit table |

### Views (28)

Key operational views for the BackOffice application:

| View | Purpose |
|------|---------|
| BackOffice.CustomerAllTimeAggregatedData | Backward-compatible wrapper over CustomerAllTimeAggregatedData_1 |
| BackOffice.CustomerMTDAggregatedData | MTD wrapper view |
| BackOffice.CustomerDTDAggregatedData | DTD wrapper view |
| BackOffice.GetManager | Active managers with UserGroupName join (legacy UI data source) |
| BackOffice.GetCustomerNote | Customer note history with manager names |
| BackOffice.GetOpenPositionSummary | Open position summary for risk monitoring |
| BackOffice.GetHedgePositionSummary | Hedge exposure reporting |
| BackOffice.V_AuditAction | Audit action view |
| BackOffice.CustomerFirstTimeLogged | First login tracking |
| BackOffice.CustomerSafty | Customer safety/risk exposure view |
| BackOffice.JUNK_* (5 views) | Deprecated legacy views - do not use |

### Functions (58)

Scalar and table-valued functions supporting BackOffice calculations:

| Function Category | Examples |
|------------------|---------|
| Financial calculations | CalculateDepositPIPsUSD, CalculatePIPsUSD, CalculateWithdrawPIPsUSD, GetSaleCommission |
| Customer state queries | GetCustomerManager, GetManagerID, GetCustomerStatus, GetUserRisksByCID |
| Registration checks | IsFirstLogin, IsRegisteredBefore24Hrs, IsRegisteredBeforeMonth |
| PnL and margin | GetUnrealizedPnL, GetUnrealizedPnLNoFunctions, GetUsedMargin, GetUsedMarginInLine |
| Time-series aggregates | GetAggregateCashout/LoginCount By Day/Week/Month Interval |
| JUNK deprecated (17) | All JUNK_ prefix functions - decommissioned, do not call |

### Stored Procedures (348)

Organized by operational domain:

| Domain | Count | Key Procedures |
|--------|-------|---------------|
| Customer data reads | ~50 | GetCustomerByCID, GetCustomerHeader, GetAllUserDocuments, GetBlockedCustomers |
| Customer state changes | ~40 | CustomerSetDocumentStatus, CustomerSetRiskClassification, CustomerSetRiskStatus, ChangeCustomerRegulation |
| KYC/Document management | ~30 | AddKYC, AddDocumentClassification, CustomerDocumentObsoleteSign, SetElectronicIdentityCheck |
| Risk management | ~15 | CustomerSetRiskStatus, SetRiskStatus, GetCustomerRisks, NewRiskAlertsPCIVersion |
| Withdrawal/cashout | ~20 | GetWithdrawRequests, WithdrawRequestApprove, CalculateDailyLimitForRedeem, AmendCashoutState |
| MIMO aggregation | ~10 | UpsertIntoAggregationTablesAction, UpsertIntoAggregationTables, UpsertMIMOAggregation |
| Affiliate/campaign | ~20 | AffiliateEdit, CampaignAdd, CampaignEdit, CampaignBunchAdd |
| Bonus management | ~10 | BonusAdd, BonusEdit, BonusLinkToCampaign |
| Staff/auth | ~10 | LogIn, LogOut, LoadManagers, LoadManagerByUsername, GetManagers |
| Reporting | ~25 | AccountStatement_GetTaxReport (v1-v3), GetRiskExposureReportPCIVersion, SSRS reports |
| Task management | ~8 | TaskAdd, TaskAssign, TaskClose, TaskEdit |
| JUNK deprecated (~20) | ~20 | All JUNK_ prefix SPs - decommissioned, do not call in production |

---

## Key Business Logic Patterns

### Pattern 1: Customer Onboarding State Machine

```
Registration (Customer.RegisterReal)
    |
    v
BackOffice.Customer row created (VerificationLevelID=0, AcceptanceStatusID=0)
    |
    v
Customer uploads documents -> BackOffice.CustomerDocument
    |
    v
Agent reviews -> BackOffice.CustomerDocumentToDocumentType
    |
    v
Agent approves -> BackOffice.CustomerSetDocumentStatus
    (VerificationLevelID advances 0 -> 1 -> 2 -> 3)
    |
    v
Full KYC (VerificationLevelID=3) -> full withdrawal access
```

### Pattern 2: Risk Flag Lifecycle

```
Automated rule fires (e.g., deposit velocity exceeded)
    |
    v
INSERT BackOffice.CustomerRisk (RiskEventStatusID=1/On, Occurred=NOW)
    |
    v
Risk agent opens customer in BackOffice
    |
    v
UPDATE RiskEventStatusID=2 (InProcess) + ManagerID=agent
    |
    v
Investigation complete -> UPDATE RiskEventStatusID=3 (Off)
    OR
Account action taken (deposit block, freeze, etc.)
```

### Pattern 3: MIMO Aggregation Pipeline

```
Customer deposits / withdraws / trades
    |
    v
History.ActiveCredit (new credit event row)
    |
    v
BackOffice.UpsertIntoAggregationTablesAction (runs continuously)
    |-- CreditTypeID=1 -> TotalDeposit delta (AllTime + MTD + DTD)
    |-- CreditTypeID=2 -> TotalCashout delta
    |-- CreditTypeID=4 -> TotalProfit + TotalPositionCount (from History.Position)
    |-- etc.
    |
    v
UPSERT BackOffice.CustomerAllTimeAggregatedData_1
UPSERT BackOffice.CustomerMTDAggregatedData_1
UPSERT BackOffice.CustomerDTDAggregatedData_1
    |
    v
DWH reads via BackOffice.CustomerAllTimeAggregatedData (view)
SalesForce syncs WHERE LastOccurredTriggerToSF > last_sync_time
```

---

## Cross-Schema Dependencies

| Direction | This Schema | External Schema | Object | Usage |
|-----------|------------|----------------|--------|-------|
| BackOffice -> Customer | BackOffice.Customer | Customer.CustomerStatic | CID FK (WITH CHECK) - identity anchor |
| BackOffice -> Customer | BackOffice.CustomerDocument | Customer.CustomerStatic | CID FK (WITH CHECK) - document owner |
| BackOffice -> Customer | BackOffice.GetCustomerHeader | Customer.Customer | Name, balance, GCID source |
| BackOffice -> Dictionary | BackOffice.Customer | Dictionary.Regulation, VerificationLevel, MifidCategorization, SalesStatus, AcceptanceStatus, CashoutFeeGroup, GuruStatus, RiskClassification, GDCCheck, WorldCheck, UserGroup, EIDStatus | 14 FK-referenced lookup tables |
| BackOffice -> Dictionary | BackOffice.CustomerRisk | Dictionary.RiskStatus, RiskEventStatus | Risk type and lifecycle FKs |
| BackOffice -> History | BackOffice.Customer (via trigger) | History.BackOfficeCustomer | Full change history (ValidFrom/ValidTo) |
| BackOffice -> Billing | BackOffice.CustomerAllTimeAggregatedData_1 | Billing.Deposit | FTD milestone date calculation |
| Customer -> BackOffice | Compliance SPs | BackOffice.CustomerDocument, BackOffice.CustomerDocumentToDocumentType, BackOffice.Customer | Document expiration population queries |
| Customer -> BackOffice | Customer.SetBalance | BackOffice.UpsertMIMOAggregation | MIMO aggregation triggered after Deposit/CashOut/Bonus |

---

## Deprecated Object Convention

BackOffice follows the platform-wide naming conventions for deprecated objects:

| Convention | Meaning | Action |
|-----------|---------|--------|
| `JUNK_` prefix (functions/views) | Decommissioned. Retained for audit history. | Do NOT call in production. |
| `_JUNK{Name}{Date}` suffix (SPs) | Decommissioned. Author and date encoded in name. | Do NOT call in production. |
| `_Del` suffix (SPs) | Marked for deletion. Near-term removal planned. | Do NOT call. |
| `_OLD` suffix (SPs) | Legacy version retained alongside active replacement. | Use the version without suffix. |
| `_Test` / `Test` in name | Experimental or QA-only procedure. | Do NOT call in production. |

---

## Quality Summary

| Object Type | Count | Avg Quality | Notes |
|------------|-------|-------------|-------|
| Tables | 68 | 9.1/10 | High VERIFIED confidence on core tables |
| Views | 28 | 8.8/10 | Legacy JUNK_ views documented at lower quality |
| Functions | 58 | 8.6/10 | JUNK_ functions noted as deprecated |
| Stored Procedures | 348 | 8.7/10 | Wide range: complex multi-join SPs to simple CRUD |
| **Total** | **502** | **8.8/10** | Batches 1-21, documented 2026-03-17 to 2026-03-18 |

---

*Generated: 2026-03-18 | Schema: BackOffice | Database: etoro | Documentation batches: 21 | Phase 12 enrichment: 2026-03-18*
*Total objects: 502 (68 Tables + 28 Views + 58 Functions + 348 Stored Procedures)*
