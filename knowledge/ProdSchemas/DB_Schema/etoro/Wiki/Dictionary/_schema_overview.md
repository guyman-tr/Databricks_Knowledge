# Dictionary Schema — Overview

> The Dictionary schema is eToro's centralized reference data repository, containing 359 lookup tables, 9 views, 4 stored procedures, and 1 synonym that define every classification, status, type, and configuration value used across the platform.

---

## 1. Purpose

The Dictionary schema serves as the **single source of truth for all enumerated values** across the eToro trading platform. Every status code, type classification, country definition, payment method, regulatory category, and instrument configuration lives here. Other schemas (Trade, Customer, Billing, Hedge, BackOffice) reference Dictionary tables via foreign keys and implicit lookups.

This schema is **read-heavy, write-rare** — values are configured by operations/compliance teams and cached by application services. Several tables use system versioning (temporal tables) to track configuration changes with full audit history.

---

## 2. Key Business Domains

| Domain | Key Tables | Description |
|--------|-----------|-------------|
| **Trading** | Currency, CurrencyType, Leverage, SettlementTypes, PositionType, OpenPositionActionType, ClosePositionActionType, DelayedOrderStatus, InstrumentOperationMode | Core trading instrument definitions, position lifecycle, order types |
| **Copy Trading** | MirrorType, MirrorStatus, AllocationType, MirrorCalculationType, RedeemStatus, CloseMirrorActionType | CopyTrading relationship types, states, and fund redemption lifecycle |
| **User Management** | PlayerStatus, AccountStatus, AccountType, KycState, VerificationLevel, SuitabilityTestStatus | User account states, classification, and verification status |
| **Compliance / KYC** | DocumentType, DocumentStatus, WorldCheck, RiskCategories, MifidCategorization, AsicClassification, SeychellesCategorization | Identity verification, risk assessment, regulatory classification |
| **Payments / Billing** | FundingType, PaymentStatus, CashoutStatus, DepositType, CreditType, FundingStatus, BonusStatus | Payment methods, deposit/withdrawal lifecycle, fee management |
| **Geographic** | Country, Region, Language, CountryGroup, SubRegion, RegionByIP, TimeZone | Country/region definitions, localization, IP geolocation |
| **Cards / BINs** | Bank, BankBin, CardType, CardTypeToBank, CountryBin6, CountryBin8 | Credit card issuer identification and routing |
| **Risk / Hedging** | HedgeStrategyMode, HedgeOrderState, HedgeEventType, HedgeAccountType, TradingRiskStatus | Internal risk management and hedging configuration |
| **Notifications** | NotificationType, NotificationStatus, MessageType, NotificationTrigger | User communication and notification system |
| **Platform** | Platform, ApplicationIdentifier, Feature, ServerType, ServiceType | Client application and infrastructure classification |

---

## 3. Architecture Patterns

### 3.1 Table Design Patterns

- **Simple Lookup (ID + Name)**: ~70% of tables follow the pattern of `{TypeID} INT PK, {TypeName} VARCHAR(50)`. These are pure enumeration tables.
- **Rich Lookup (ID + Name + Flags)**: ~15% include boolean flags (IsActive, IsFinalStatus, IsBlocked) that add behavioral metadata to the classification.
- **Configuration Tables**: ~10% store operational configuration with multiple columns controlling system behavior (e.g., FundingType with 12 operational flags).
- **Junction Tables**: ~5% map many-to-many relationships (CountryToCountryGroup, CardTypeToBank, etc.).

### 3.2 System Versioning (Temporal Tables)

The following Dictionary tables use system versioning for change tracking:

| Table | History Table | Purpose |
|-------|--------------|---------|
| FundingType | History.FundingType | Track payment method config changes |
| InterestRate | History.InterestRate | Track interest rate changes |
| InterestRateOverride | History.InterestRateOverride | Track rate override changes |
| ConditionOperators | History.ConditionOperators | Track CEP operator changes |
| ConditionProperties | History.ConditionProperties | Track CEP property changes |
| CountryBin6 | History.CountryBin6 | Track 6-digit BIN changes |
| CountryBin8 | History.CountryBin8 | Track 8-digit BIN changes |
| FeeCalculationTypes | History.FeeCalculationTypes | Track fee config changes |
| OverNightFeePattern | History.OverNightFeePattern | Track overnight fee pattern changes |
| TradingInstrumentGroups | History.TradingInstrumentGroups | Track instrument group changes |

### 3.3 Memory-Optimized Tables

| Table | Purpose |
|-------|---------|
| DelayedOrderStatus | High-frequency order matching engine lookups |
| ExecutionServicesOpeartionType | Real-time execution service operations |
| OrderForExecutionStatus | In-memory order execution state |

### 3.4 DDL Anomalies (Heap Tables — No PK)

Several tables lack primary key constraints (stored as heaps):

AdminPositionState, AllowedOpenOrderType, AmountFormula, BadBinBlockReason, DesignatedExecutionSystem, EncryptionKeyStatus, ExecuteEntryMethod, InstrumentTypeSubCategory, OrderFillBehaviorType, PositionTimeOuts, RankToCountry, RankToCountryConfiguration, TradeActivity_ExecutionTypes, TradeUnitType, UnitsQuantityType, UpdateApexID, AggregationLastValue

---

## 4. Object Counts

| Object Type | Count | Documentation |
|------------|-------|---------------|
| Tables | 359 | 355 documented |
| Views | 9 | 9 documented |
| Stored Procedures | 4 | 4 documented |
| Synonyms | 1 | 1 documented |
| **Total** | **373** | **369 documented** |

---

## 5. Dependency Levels

| Level | Description | Example Tables |
|-------|-------------|---------------|
| 0 (Leaf) | No dependencies — most Dictionary tables | AccountStatus, PlayerStatus, Leverage, Language |
| 1 | Depends on other Dictionary tables | BankBin→Bank, Currency→CurrencyType, ApplicationIdentifier→Platform |
| 2 | Depends on Level 1 tables | Country→Region+Language+Currency, Regulation→Bank |
| 3+ | Deep chains | CountryBin6→Country+CardType, CountryToCountryGroup→CountryGroup+Country |

---

## 6. Related Schemas

| Schema | Relationship | Examples |
|--------|-------------|----------|
| Trade | Positions/orders reference Dictionary lookups | PositionTbl.SettlementTypeID → SettlementTypes |
| Customer | User profiles reference Dictionary classifications | CustomerStatic.AccountTypeID → AccountType |
| Billing | Payment records reference Dictionary payment types | Deposit.FundingTypeID → FundingType |
| Hedge | Risk positions reference Dictionary hedge config | HedgeOrder.HedgeStrategyModeID → HedgeStrategyMode |
| History | Temporal table history storage | History.FundingType stores FundingType version history |

---

*Generated: 2026-03-13 | Documentation Phase: Complete*
*Schema: Dictionary | Database: etoro | Total Objects: 373 | Documented: 369*
