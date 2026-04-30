# Customer Schema - Overview

> The Customer schema is the foundational identity and account management layer of the eToro platform. It owns the master record for all 18.7M customers, their financial balances, authentication, privacy, messaging, and all registration/update workflows.

**Database**: etoro
**Schema**: Customer
**Documentation Status**: 100% complete (253/253 objects, 11 batches)
**Last Updated**: 2026-03-17

---

## 1. Purpose and Scope

The Customer schema answers one fundamental question for the entire platform: *Who is this customer, what is their current state, and what can they do?*

Every eToro workflow starts here. Registration creates the CustomerStatic row and the CustomerMoney row. Trading reads CustomerStatic for the customer's provider, spread group, and status. Compliance checks PlayerStatusID and AccountStatusID. Billing reads CustomerMoney for the Credit balance. The 2FA layer writes to TwoFactorVerificationDetails on every login challenge. GDPR erasure cascades through GDPRDeleteUser to wipe PII from all schema tables.

With 18,746,933 real accounts and 253 documented objects (35 tables, 22 views, 13 functions, 178 stored procedures, 4 UDTs, 1 synonym), the Customer schema is the highest-traffic, most widely referenced schema in the etoro database.

---

## 2. Architecture

### 2.1 Core Data Model

```
Customer.CustomerStatic (84 cols, 18.7M rows)
|- PK: CID (int)
|- Identity: UserName, Email, GCID, ID (GUID), ExternalID (APEX), ApexID, DltID
|- Demographics: FirstName, LastName, BirthDate, Gender, Address, CountryID, CitizenshipCountryID
|- Status: PlayerStatusID, AccountStatusID, PlayerLevelID, TradeLevelID
|- Config: ProviderID, SpreadGroupID, CurrencyID, LabelID, LotCountGroupID
|- Acquisition: SerialID (Affiliate), CampaignID, FunnelID, ReferralID
|- Triggers: CustomerVersionInsert, CustomerVersionUpdate, CustomerVersionDelete
|    -> History.Customer (full point-in-time version history)
|    -> Customer.LastChanges (email change audit)
|    -> BackOffice.Customer (FXEligibilityDate on PlayerLevel change)

Customer.CustomerMoney (7 cols, 18.7M rows, 1:1 with CustomerStatic)
|- PK: CID (int)
|- Credit (money) - available USD balance
|- BonusCredit (money) - promotional credits
|- RealizedEquity (money) - running realized value total
|- TotalCash (dtPrice) - reconciliation total via Trade.UpdateTotalCash
|- BSLRealFunds (money) - Balance Stop Loss threshold
|- [MIGRATION IN PROGRESS: Will become a VIEW over CustomerMoneyByCurrency + CustomerAccount]

Customer.Login (session/password data)
Customer.PrivacyUniqueIdentity (GDPR pseudonymization)
Customer.TwoFactorVerificationDetails (2FA OTP audit log)
Customer.MessageQueue + CustomerToMessageQueue (internal messaging)
Customer.TrackingId (marketing tracking)
Customer.RegistrationRequest (pre-registration workflow)
```

### 2.2 Balance Write Architecture

All financial events flow through a two-tier router:

```
Any financial event (deposit, withdrawal, position, bonus, etc.)
    |
    v
Customer.SetBalance (@CreditTypeID)
    |
    |- CreditTypeID 1 (Deposit)          -> Customer.SetBalanceDeposit
    |- CreditTypeID 2 (CashOut)          -> Customer.SetBalanceCashOut
    |- CreditTypeID 4 (ClosePosition)    -> Customer.SetBalanceClosePosition
    |- CreditTypeID 6 (Compensation)     -> Customer.SetBalanceCompensation
    |- CreditTypeID 7 (Bonus)            -> Customer.SetBalanceBonus
    |- CreditTypeID 11 (ChargeBack)      -> Customer.SetBalanceChargeBack
    |- CreditTypeID 12 (Refund)          -> Customer.SetBalanceRefund
    |- CreditTypeID 16 (RefundAsChgBack) -> Customer.SetBalanceRefundAsChargeBack
    |- CreditTypeID 22 (CloseMirror)     -> Customer.SetBalanceClosePosition
    |- CreditTypeID 33 (CashoutRollback) -> Customer.SetBalanceCashoutRollback
    |- 20+ legacy CreditTypeIDs          -> Inline legacy path (monolithic code)
    |
    v
Customer.CustomerMoney (Credit, BonusCredit, RealizedEquity, BSLRealFunds updated)
```

After Deposit/CashOut/Bonus: BackOffice.UpsertMIMOAggregation is called for real-time MIMO aggregation.

### 2.3 2FA Security Architecture

```
Application generates OTP + ReferenceID GUID
    |
    v
Customer.InsertTwoFactorVerificationDetails (ReferenceID, GCID, OTP, SendMethodType)
    -> Creates row in Customer.TwoFactorVerificationDetails: Success=0, Tries=0

On wrong entry:
Customer.UpdateTwoFactorVerificationTries (ReferenceID, GCID) -> VerificationTries += 1

On correct entry:
Customer.UpdateTwoFactorVerificationDetails (ReferenceID, GCID) -> Success=1, VerifySuccessDate=NOW

Rate limiting: GetTwoFactorVerificationFailedRequestCount (count Success=0 rows in window)
Abuse detection: GetOTPAbusers (multi-signal over 7-day window -> Customer.OTPAbusers)
```

---

## 3. Object Inventory

| Type | Count | Key Objects |
|------|-------|-------------|
| Tables | 35 | CustomerStatic, CustomerMoney, Login, TwoFactorVerificationDetails, PrivacyUniqueIdentity, MessageQueue, RAFGiven, RegistrationRequest |
| Views | 22 | Customer (the view), CustomerSafty, GetDemography, GetUserCredit, LoggedCustomer, OpenAndClosePositions, GetRealCustomersShort* (marketing views) |
| Functions | 13 | GetCustomerRelation*, GetCurrentFinancialDataByCID, GetMirrorValidationValues*, IsUniqueName, VerificationTitle_Default |
| Stored Procedures | 178 | SetBalance* (balance writes), Get* (data reads), Register* (registrations), Update* (profile edits), Set* (status/config changes) |
| User Defined Types | 4 | CustomerCIDsTableType, GCIDs, CustomerLatinNameType, TBL_CustomerComment |
| Synonyms | 1 | Customer.Settings (points to external settings DB) |
| **Total** | **253** | - |

---

## 4. Business Domain Coverage

### 4.1 Customer Lifecycle

| Stage | Objects |
|-------|---------|
| Registration | RegisterReal, RegisterDemo, RegisterIB, InsertRealCustomer, PostRegisterOperations, DeleteRegistrationFailedUser |
| Identity & Profile | CustomerStatic, UpdateBasicUserInfo, UpdateContactUserInfo, UpdateRiskUserInfo, DemographyEdit, P_UpdateCustomer |
| Session & Auth | Login, GetCidBySessionID, Ins_HistoryLoginOpenBook, ChangePassword, RetrievePassword, 2FA suite |
| Status Management | SetStatus, OperationBlockForCID, OperationUnBlockForCID, SetPlayerLevel, SetTradeLevel, SetSpreadGroup, SetLabel |
| Account Closure | GDPRDeleteUser, SetAccountExpirationDate |

### 4.2 Financial Operations

| Operation | Objects |
|-----------|---------|
| Balance Reads | GetUserFinancialData, GetFinancialDataByCIDs, GetAggregatedInfoOnlyReadFields, GetCurrentFinancialDataByCID (fn), GetUserCredit (view) |
| Balance Writes | SetBalance (router), SetBalanceDeposit, SetBalanceCashOut, SetBalanceClosePosition, SetBalanceBonus, SetBalanceChargeBack, SetBalanceRefund, SetBalanceCompensation, SetBalanceClameFee, SetBalanceOpenPosition, SetBalanceChangeMirrorAmount, SetBalanceDataFix |
| Credit | CreditEdit, CreditExtended (table), SetBalanceChangeCredit, SetBalanceInsertCredit_Native |
| Post-MIMO | PostMIMOOperations, PostMIMOOperationsDebug, PostUpdateBasicUserInfo, PostUpdateContactUserInfo, PostUpdateRiskUserInfo |

### 4.3 Compliance & Risk

| Domain | Objects |
|--------|---------|
| KYC | GetRiskUserInfo, UpdateManyRiskClassificationInfo, IsTestAccount |
| Fraud | CheckFraudUsers_NogaJunk210725, FraudUsers_NogaJunk210725 (table), GetOTPAbusers, OTPAbusers (table) |
| GDPR | GDPRDeleteUser, GDPRIsDepositor, DeletePrivacyUniqueIdentity, DeletePrivacyUniqueIdentityByUserID |
| Privacy | PrivacyUniqueIdentity (table), GetPrivacyUniqueIdentity, SetPrivacyUniqueIdentityNew, GetUsersPrivacyPoliciesByCIDs, SetPrivacyPolicyID |
| Blocked Operations | BlockedCustomerOperations (table), GetBlockedOperationsForCID, OperationBlockForCID, OperationUnBlockForCID |

### 4.4 Social / CopyTrading

| Domain | Objects |
|--------|---------|
| Mirror Validation | GetMirrorValidationsByCID, GetMirrorValidationsByGCID, GetMirrorValidationValuesByCID (fn), GetMirrorValidationValuesByGCID (fn), P_GetMirrorValidationValuesByUserNameAndPassword |
| Player Level | PlayerLevelGetData, PlayerLevelGetRealizedEquityData, SetPlayerLevel, SetPlayerLevelNoLot |
| Dynamics (CRM) | DynamicsInsert, GenerateMirrorDataForDynamics, GenerateTradeDateFromDynamics, AggregateUserMirrorData, CorrectDynamicsGaps |

### 4.5 Refer-a-Friend (RAF)

Tables: RAFGiven, RafCIDInProcess, CountryRafConfiguration_NogaJunk210725, RafConfigurationModels_NogaJunk210725, RafEligibleCustomers_NogaJunk210725, RafFraudCustomers_NogaJunk210725, RafSuspectedAbuser_NogaJunk210725, FailedRAFCompensation

Procedures: SetRafCompensation, RAFCompensationProcess_NogaJunk210725, RafGetByReferedGCIDs, RafGetReferralHistory_NogaJunk210725, RafMarkSuspectedAbuser_NogaJunk210725, RafSetFraud_NogaJunk210725, CheckFraudUsers_NogaJunk210725, GetRafStatusByGCID_NogaJunk210725, GetRafConfiguration_NogaJunk210725

Note: Multiple JUNK-suffix objects in the RAF cluster indicate experimental/deprecated variants from a specific sprint (July 2025, Noga).

---

## 5. Key Facts & Statistics

| Metric | Value |
|--------|-------|
| Total rows in CustomerStatic | 18,746,933 |
| Real accounts | 18,746,933 (100% in this environment) |
| Accounts with PlayerStatus=1 (Normal) | ~18.3M (97.5%) |
| Accounts with PlayerLevel=1 (Standard) | ~17.6M (94%) |
| Accounts with Popular Investor status (Level=4) | ~0.4M (est.) |
| CustomerMoney rows | ~18,744,975 |
| Indexes on CustomerStatic | 17 (1 clustered PK + 16 nonclustered) |
| Columns in CustomerStatic | 84 |
| PII columns protected by Dynamic Data Masking | 11 (IP, BirthDate, FirstName, LastName, Address, Zip, Email, Phone, Mobile, BuildingNumber, PhoneBody) |
| Stored procedures that write to CustomerMoney | 56 (25 direct, 31 indirect via SetBalance) |
| Objects that read from CustomerMoney | 107+ (95 SPs, 9 views, 3 functions) |
| JUNK-suffix deprecated objects | 15 (all RAF cluster + some compliance-related) |

---

## 6. Cross-Schema Dependencies

### 6.1 Customer schema depends on

| Schema | Objects | Dependency Type |
|--------|---------|-----------------|
| Dictionary | Country, PlayerStatus, PlayerLevel, Language, Currency, TradeLevel, LotCountGroup, Label, Funnel, PrivacyPolicy, SubRegion, EmailVerificationProvider, PlayerStatusSubReasons, TwoFactorVerificationSendMethodType | FK constraints from CustomerStatic and TwoFactorVerificationDetails |
| Trade | Trade.Provider, Trade.SpreadGroup | FK constraints from CustomerStatic |
| BackOffice | BackOffice.Affiliate, BackOffice.Campaign | FK constraints from CustomerStatic |
| History | History.Customer | Trigger-managed version history for CustomerStatic |

### 6.2 Other schemas depend on Customer

| Schema | How They Use Customer |
|--------|-----------------------|
| Trade | Reads CustomerStatic (CID, GCID, ProviderID, PlayerStatusID) for position open/close eligibility |
| Billing | Reads CustomerMoney (Credit) for deposit/withdrawal processing; calls SetBalance |
| Compliance | Reads CustomerStatic (GCID, PlayerStatusID, AccountTypeID, CountryID) for compliance population queries |
| BackOffice | Reads CustomerStatic for customer profiles; Customer views feed BO screens |
| Trade server | Calls Customer SPs for authentication, mirror validation, balance updates |

---

## 7. Important Design Decisions & Known Issues

### 7.1 Multi-Currency Migration (In Progress, March 2026)

**Decision**: On March 8, 2026 (Mor/Architect, unanimous), CustomerMoney will be replaced by:
- `Customer.CustomerMoneyByCurrency`: per-currency Credit rows (CID + CurrencyId)
- `Customer.CustomerAccount`: account-level row (BonusCredit, RealizedEquity, BSLRealFunds)
- `CustomerMoney` itself will become a backward-compatible VIEW

Impact: All 107 consumers of CustomerMoney will continue to work unchanged. The VIEW will aggregate per-currency Credits to USD for backward compatibility.

### 7.2 JUNK/Deprecated Objects

15 objects carry a `_JUNK`/`_NogaJunk210725` suffix, marking them as deprecated:
- RAF cluster (7 objects): `CountryRafConfiguration_NogaJunk210725`, `RafConfigurationModels_NogaJunk210725`, `RafEligibleCustomers_NogaJunk210725`, `RafFraudCustomers_NogaJunk210725`, `RafSuspectedAbuser_NogaJunk210725`, `CheckFraudUsers_NogaJunk210725` (SP), `ContactVerificationPhoneGetMany_JunkNoga240325`
- GetDocumentTypes: `Customer.GetDocumentTypes_JUNKYulia0325`
- GetOTPAbusers has a `RETURN` at line 14 (disabled shortcut by Ran Ovadia, 04/07/23) - logic preserved but bypassed

### 7.3 History Versioning via Triggers

CustomerStatic has 3 triggers creating a full audit trail. Key nuances:
- Password changes are NOT versioned (hash implementation decision)
- ValidTo sentinel = `'30000101 00:00:00.000'` (NOT '9999-12-31') for current active version
- UPDATE trigger checks 50+ columns before creating a new version (no-op guard)

### 7.4 IsHedged Logic

CustomerStatic.IsHedged is managed entirely by triggers (not application code):
- Set to 0 when: LabelID=26 OR PlayerLevelID=4 OR CID in CEP.ListCIDMappings(NamedListID=3) OR in BackOffice.BonusOnlyCustomers
- Default = 1 (hedged)

### 7.5 PII Protection

11 columns in CustomerStatic are protected by SQL Server Dynamic Data Masking. Unauthorized users see `XXXX` (default mask) instead of real values. This is transparent to application code but affects ad-hoc queries by non-privileged users.

---

## 8. Documentation Quality Summary

| Category | Avg Quality | Notes |
|----------|-------------|-------|
| Tables (35) | 8.6/10 | CustomerStatic 9.7, CustomerMoney 9.5 lead; some temp/legacy tables lower |
| Views (22) | 7.9/10 | Marketing views consistently 7.5-8.3; GetDemography 8.2 |
| Functions (13) | 8.1/10 | GetCustomerRelation* variants 8.3-8.5 |
| Stored Procedures (178) | 8.3/10 | SetBalance* suite 8.5-9.2; Registration SPs 8.5-9.0; Update* SPs 7.3-8.5 |
| User Defined Types (4) | 8.5/10 | Well-documented table-valued types |
| **Overall (253)** | **8.3/10** | - |

---

## 9. Related Documentation

- [_index.md](_index.md) - Full object inventory with quality scores
- [_glossary.md](../_glossary.md) - Business terms including Account Status, Player Status, Language
- [_semantic_index.md](../_semantic_index.md) - Cross-schema business concepts (Customer schema section)
- [Customer.CustomerStatic](Tables/Customer.CustomerStatic.md) - Master customer record (9.7/10)
- [Customer.CustomerMoney](Tables/Customer.CustomerMoney.md) - Live balance table (9.5/10)
- [Customer.SetBalance](Stored%20Procedures/Customer.SetBalance.md) - Central balance router (9.2/10)
- [Customer.TwoFactorVerificationDetails](Tables/Customer.TwoFactorVerificationDetails.md) - 2FA audit log (8.8/10)

---

*Generated: 2026-03-17 | Schema: Customer | Database: etoro | Objects: 253/253 (100%)*
