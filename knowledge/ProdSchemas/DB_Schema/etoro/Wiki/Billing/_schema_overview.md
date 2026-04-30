# Billing Schema - Overview

**Database**: etoro | **Schema**: Billing | **Documentation Status**: Complete (771/771 objects)

*Created: 2026-03-18 | Batches: 33 | Avg Quality: ~8.6/10*

---

## Business Purpose

The Billing schema is the financial operations backbone of the eToro trading platform. It owns the full lifecycle of all customer money movements: deposits into eToro accounts, withdrawals back to customers, cashouts (outgoing payment execution), and fund routing. It also manages the payment instrument registry (credit cards, bank accounts, e-wallets), acquirer/depot routing configuration, fee structures, and compliance controls for financial transactions.

The schema serves:
- **Cashout Service**: processes withdrawals through payment providers (WithdrawToFunding lifecycle)
- **Deposit Service**: handles incoming funds and payment matching
- **Withdrawal Service**: manages customer withdrawal requests and risk screening
- **BackOffice Payments team**: manual review, routing management, dispute handling
- **Risk/Compliance**: funding limits, blacklists, risk management checks
- **Finance/Reporting**: conversion fees, PnL, FX exchange rates

---

## Object Inventory

| Type | Count | Description |
|------|-------|-------------|
| Tables | 140 | Core data entities - payment instruments, transactions, routing config |
| Stored Procedures | 571 | Business logic - deposit/withdraw flows, routing, reporting, maintenance |
| Views | 22 | Reporting and service aggregation layers |
| Functions | 27 | Scalar and table-valued utility functions |
| User Defined Types | 11 | TVP types for batch operations (TBL_Withdraw, TBL_WithdrawToFunding*) |
| **Total** | **771** | |

---

## Core Business Entities

### Payment Instruments
| Table | Description |
|-------|-------------|
| [Billing.Funding](Tables/Billing.Funding.md) | Master registry of all customer payment instruments (cards, bank accounts, e-wallets). Central FK for all deposit/withdraw records. |
| [Billing.CreditCard](Tables/Billing.CreditCard.md) | Credit/debit card details for card-based payments |
| [Billing.Deposit](Tables/Billing.Deposit.md) | All incoming deposits - the money-in ledger |
| [Billing.Withdraw](Tables/Billing.Withdraw.md) | All withdrawal requests - the money-out request ledger |
| [Billing.WithdrawToFunding](Tables/Billing.WithdrawToFunding.md) | Withdrawal execution legs - tracks payment to a specific instrument |
| [Billing.Cashout](Tables/Billing.Cashout.md) | Cashout event records |
| [Billing.Payment](Tables/Billing.Payment.md) | Generic payment records across transaction types |
| [Billing.Redeem](Tables/Billing.Redeem.md) | Redemption events converting internal credits to real withdrawals |

### Routing & Configuration
| Table | Description |
|-------|-------------|
| [Billing.Depot](Tables/Billing.Depot.md) | Acquirers/payment gateways - the routing backbone |
| [Billing.DepotConfig](Tables/Billing.DepotConfig.md) | Per-depot configuration parameters |
| [Billing.ProtocolMIDSettings](Tables/Billing.ProtocolMIDSettings.md) | Merchant ID (MID) configuration per protocol/depot |
| [Billing.Terminal](Tables/Billing.Terminal.md) | Payment terminals linked to depots |
| [Billing.GatewayEndpoint](Tables/Billing.GatewayEndpoint.md) | API endpoints for each payment gateway |
| [Billing.CountryToDepot](Tables/Billing.CountryToDepot.md) | Country-based depot routing rules |
| [Billing.FundingTypeToDepot](Tables/Billing.FundingTypeToDepot.md) | Payment method to depot routing |

### Fees & Limits
| Table | Description |
|-------|-------------|
| [Billing.ConversionFee](Tables/Billing.ConversionFee.md) | FX conversion fee rates by currency pair and funding type |
| [Billing.FundingTypeLimit](Tables/Billing.FundingTypeLimit.md) | Min/max deposit limits per payment method |
| [Billing.MemberLimit](Tables/Billing.MemberLimit.md) | Customer-level deposit/withdrawal limits |
| [Billing.Quota](Tables/Billing.Quota.md) | Periodic (daily/monthly) transaction quotas |
| [Billing.Parameter](Tables/Billing.Parameter.md) | Global billing configuration key-value store |

### Risk & Compliance
| Table | Description |
|-------|-------------|
| [Billing.RiskManagementCheck](Tables/Billing.RiskManagementCheck.md) | Risk rules applied to withdrawal requests |
| [Billing.WithdrawToRiskManagementStatus](Tables/Billing.WithdrawToRiskManagementStatus.md) | Results of risk checks per withdrawal |
| [Billing.BadBin](Tables/Billing.BadBin.md) | Blacklisted card BIN ranges |
| [Billing.CFTWhiteList](Tables/Billing.CFTWhiteList.md) | Card-Funding-Type whitelist overrides |

---

## Core Business Flows

### 1. Deposit Flow (money-in)
```
Customer initiates deposit
  -> Billing.Funding (instrument lookup/create)
  -> Billing.Payment (payment record created)
  -> Billing.Deposit (deposit record + balance credit)
  -> Billing.CreditCard / Billing.NetellerToPayment / etc. (instrument-specific record)
  -> Billing.CustomerToFunding (funding history updated)
```

### 2. Withdrawal Flow (money-out request)
```
Customer submits withdrawal request
  -> Billing.WithdrawalService_WithdrawRequestAdd
    -> Billing.Withdraw (withdrawal record created, status=Pending)
    -> Customer.SetBalance (balance debited)
    -> Billing.WithdrawAdditionalParameters (optional EAV compliance data)
  -> Risk screening -> Billing.WithdrawToRiskManagementStatus
  -> BackOffice approval (or auto-approval for low-risk)
```

### 3. WithdrawToFunding (WTF) Execution Flow (money-out execution)
```
Cashout Service picks up approved withdrawal
  -> Billing.WithdrawToFundingAdd (WTF leg created, status=Pending)
  -> Billing.WithdrawToFundingToInProcess (status: Pending -> InProcess)
  -> Payment provider processing
  -> Billing.WithdrawToFundingChangePaymentStatus (status: InProcess -> 6/12/Processed)
  -> Billing.WithdrawToFundingProcess (final settlement, balance confirmation)
  OR
  -> Billing.WithdrawToFundingReject (rejection path)
  OR
  -> Billing.WithdrawToFundingReverse (reversal path)
```

### 4. Redeem-to-Withdrawal Flow (internal credit conversion)
```
Billing.Redeem record triggers payout
  -> Billing.WithdrawAndWithdrawToFundingAdd (orchestrates full lifecycle)
    -> Billing.WithdrawalService_WithdrawRequestAdd (creates Withdraw)
    -> BackOffice.WithdrawApprovalAdd / WithdrawRequestApprove (auto-approves)
    -> Billing.WithdrawToFundingAdd (creates WTF leg)
    -> Billing.WithdrawToFundingToInProcess (Pending -> InProcess)
    -> Billing.WithdrawToFundingChangePaymentStatus (InProcess -> status 12)
    -> Billing.Redeem.WithdrawToFundingID updated (idempotency link)
```

### 5. Batch Settlement Flow
```
Cashout Service sends bulk confirmation
  -> Billing.WithdrawToFundingProcessBatch (V3 TVP, current path)
     OR Billing.WithdrawToFundingProcessForBatch (V1 TVP, legacy path)
    -> Billing.WithdrawToFundingProcess (per-row, cursor-based)
```

---

## Key Stored Procedure Groups

| Group | Count (approx) | Purpose |
|-------|----------------|---------|
| Deposit* | ~60 | Deposit creation, matching, reporting |
| Withdraw* / WithdrawService* | ~80 | Withdrawal request handling, queries |
| WithdrawToFunding* | ~40 | WTF lifecycle management |
| WithdrawalService* | ~20 | Withdrawal Service API layer |
| Get* | ~150 | Read-only queries (reports, UI data) |
| Upsert* / Update* / Add* | ~120 | Write operations |
| Payment* | ~30 | Payment processing |
| Cashout* | ~20 | Cashout processing |
| Redeem* | ~20 | Redeem payout handling |
| BackOffice/Admin | ~30 | Manual ops, BO tools |

---

## Cross-Schema Dependencies

| Schema | Dependency Type | Key Objects |
|--------|----------------|-------------|
| Customer | Read | Customer.CustomerStatic (CID), Customer.SetBalance |
| Dictionary | Read | CashoutStatus, FundingType, Currency, ClientWithdrawReason, ClientWithdrawComment |
| BackOffice | Call | WithdrawApprovalAdd, WithdrawRequestApprove, Manager table |
| History | Write | History.WithdrawAction, History.WithdrawToFundingAction (audit log) |
| Trade | Read | Trade.Provider (routing), Trade.CashoutRange (fee groups) |
| dbo | Use | dbo.dtPrice (UDT for exchange rates) |

---

## Notable Design Patterns

| Pattern | Where Used | Purpose |
|---------|-----------|---------|
| **TVP Batch Processing** | TBL_WithdrawToFundingProcess*, TBL_Withdraw | High-throughput bulk settlement via cursor-iterated TVPs |
| **EAV for Parameters** | Billing.WithdrawAdditionalParameters | Flexible storage of optional payment/compliance metadata |
| **Idempotency Guards** | WithdrawAndWithdrawToFundingAdd, WithdrawToFundingAdd | `IF EXISTS` checks on FK columns prevent duplicate records on retry |
| **Temporal History** | Billing.Redeem -> History.Redeem | SQL Server temporal tables for full change history |
| **Outside-Transaction Calls** | WithdrawalService_WithdrawRequestAdd | OLTP memory tables (History.ActiveCredit) cannot participate in outer transactions |
| **Status State Machine** | WithdrawToFunding.CashoutStatusID | CashoutStatus defines strict valid transitions; each status-change SP enforces its precondition |

---

## Quality Summary

| Metric | Value |
|--------|-------|
| Total objects documented | 771 |
| Documentation batches | 33 |
| Average quality | ~8.6/10 |
| Objects >= 9.0 quality | ~35% |
| Objects < 7.5 quality | ~8% (mostly archive/junk tables) |
| Phases completed | 1, 5, 8, 9, 9B (SPs); 1-11 (Tables) |
| Last batch | Batch 33 (2026-03-18) |

---

## Documentation Index

Full object listing with quality scores and links: [_index.md](_index.md)

Business Glossary (shared across etoro DB): [_glossary.md](../_glossary.md)
