# Business Glossary - fiktivo

> Canonical definitions for business terms, value domains, and concepts.
> Object docs reference this glossary for shared terminology.
> Terms are progressively enriched as more objects are documented.

*Last updated: 2026-04-13 | Terms: 22 lookup-backed, 1 concept-based | Sources: 22 Dictionary tables, 278 object docs*

---

## Lookup-Backed Terms

## Account Status {#account-status}

**Definition**: Represents the lifecycle state of a customer trading account, controlling whether the account holder can trade, access funds, or has been permanently terminated.

**Source Table**: `Dictionary.AccountStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Terminated | Account has been permanently closed by the platform or user |
| 1 | Activated | Account is fully operational - customer can trade and access services |
| 2 | Deactivated | Account is temporarily suspended - may be reactivated |
| 3 | TerminatedRequirements | Account terminated because customer failed to meet regulatory/KYC requirements |
| 4 | TerminatedCompliance | Account terminated due to compliance violation or regulatory action |

**Used By**: AffiliateAdmin.GetGeneralAffiliateResource

---

## Account Type {#account-type}

**Definition**: Classifies the type of trading or financial account a customer holds. Determines available instruments and product features.

**Source Table**: `Dictionary.AccountType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Traiding | Standard trading account for CFDs, stocks, and other instruments |
| 2 | Options | Dedicated options trading account |
| 3 | IBAN | Bank-style IBAN account for money services |
| 4 | Moneyfarm | Managed investment portfolio via Moneyfarm integration |

**Used By**: AffiliateConfiguration.ISAPlan (SubAccountTypeID=4), AffiliateConfiguration.ISAPlanType (SubAccountTypeID=4)

---

## Action {#action}

**Definition**: Classifies the type of data modification recorded in audit/change logs. Used to track what operation was performed on a record.

**Source Table**: `Dictionary.Action`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Insert | A new record was created |
| 2 | Update | An existing record was modified |
| 3 | Delete | A record was removed |

**Used By**:

---

## Changed Sections {#changed-sections}

**Definition**: Identifies which business area or entity was modified in audit log entries. Maps audit records to the specific configuration or data section that changed.

**Source Table**: `Dictionary.ChangedSections`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Affiliates | Change to an affiliate's profile or settings |
| 2 | AffiliateTypes | Change to affiliate type classification or commission structure |
| 3 | Affiliate Group | Change to affiliate grouping or hierarchy |
| 4 | Announcements | Change to system announcements sent to affiliates |
| 5 | Categories | Change to banner/media categories |
| 6 | Countries | Change to country configuration or availability |
| 7 | Brands | Change to brand definitions |
| 8 | Languages | Change to supported languages |
| 9 | Payment Details | Change to affiliate payment information |
| 10 | MediaTag | Change to tracking media tags |
| 11 | RegistrationRates | Change to registration commission rates |
| 12 | FirstPositionAssetPlan | Change to first-position asset plan settings |
| 13 | BlockedCountries | Change to blocked country list for an affiliate |
| 14 | AffiliateURLs | Change to affiliate tracking URLs |
| 15 | Tier2Members | Change to tier-2 (sub-affiliate) membership |
| 16 | AffiliateTypeCategories | Change to affiliate type category assignments |
| 17 | AffiliatePixel | Change to conversion tracking pixel configuration |
| 18 | Banners | Change to marketing banner assets |
| 19 | IOBPlan | Change to IOB (Introducing Broker) plan settings |
| 20 | ISAPlan | Change to ISA (Individual Savings Account) plan settings |

**Used By**: AffiliateAdmin.UpdateInsertAffiliateGroup (SectionID for 'Affiliate Group' - audit logs group create/update/delete), AffiliateAdmin.DeleteAffiliateGroups

---

## Creation Source {#creation-source}

**Definition**: Identifies the system or method used to create an affiliate account. Tracks whether the account was manually created, synced from Azure AD, or created for testing.

**Source Table**: `Dictionary.CreationSource`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Local | Affiliate created manually in the local admin system |
| 2 | Azure | Affiliate synced from Azure Active Directory |
| 3 | Test | Test affiliate account created for QA/development purposes |

**Used By**:

---

## Credit Type {#credit-type}

**Definition**: Classifies the type of financial transaction or credit event in the affiliate system. Determines how the transaction affects commission calculations.

**Source Table**: `Dictionary.CreditType`

**Values**:

| ID | Description | Business Meaning |
|----|------------|-----------------|
| 1 | Deposit | Customer made a cash deposit into their trading account |
| 2 | Bonus | Bonus credit applied to the customer account (type A) |
| 3 | Bonus | Bonus credit applied to the customer account (type B - distinct processing rules) |
| 4 | Chargeback | Payment reversal or dispute - deducts from affiliate commissions (type A) |
| 5 | Chargeback | Payment reversal or dispute - deducts from affiliate commissions (type B - distinct processing rules) |

**Used By**:

---

## Currency {#currency}

**Definition**: ISO 4217 currency codes used across the platform for account denomination, deposits, and commission payments.

**Source Table**: `Dictionary.Currency`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | USD | United States Dollar - primary platform currency |
| 2 | EUR | Euro |
| 3 | GBP | British Pound Sterling |
| 4 | CAD | Canadian Dollar |
| 5 | AUD | Australian Dollar |
| 38 | RMB | Chinese Renminbi |

**Used By**:

---

## Event State {#event-state}

**Definition**: Tracks the processing state of affiliate commission events as they flow through the event-driven pipeline (tracking -> eligibility -> commission). Each state represents a step in the multi-stage processing workflow. GroupID clusters states by processing stage.

**Source Table**: `Dictionary.EventState`

**Values**:

| ID | Description | GroupID | Business Meaning |
|----|------------|---------|-----------------|
| 1 | event is read from SB | 1 | Event received from Service Bus for tracking processing |
| 2 | affiliate doesn't exist, event is removed | 1 | Event discarded - no matching affiliate found |
| 3 | added tracking | 1 | Tracking record created linking customer to affiliate |
| 4 | send event to eligibility queue | 1 | Event forwarded for commission eligibility evaluation |
| 5 | all rules are eligible for commission | 2 | All eligibility rules passed - event qualifies for commission |
| 6 | send event to commission queue | 2 | Event forwarded for final commission calculation |
| 7 | rule organic is not eligible | 2 | Organic rule failed - customer considered organic (no commission) |
| 8 | event is added to event db | 2 | Event stored for deferred eligibility checking |
| 9 | event is removed from event db due to expiration | 2 | Deferred event expired without meeting eligibility criteria |
| 10 | organic rule expiration has occurred | 2 | Organic attribution window expired |
| 11 | read event from event db | 0 | Event retrieved from store for reprocessing |
| 12 | save event commission | 3 | Commission calculated and saved to the database |
| 13 | event is removed from event db | 2 | Event removed from deferred store after processing |
| 14 | rule cpa is not eligible | 2 | CPA eligibility rule failed |
| 15 | event is removed from AffiliateTraderQueue | 1 | Event cleaned from trader queue after processing |
| 16 | event is read from AffiliateTraderQueue | 1 | Event received from trader-specific queue |
| 17 | event is read from eligibility queue | 2 | Event received for eligibility evaluation |
| 18 | lastCheckDate was updated in event db | 2 | Deferred event's check timestamp refreshed |
| 19 | couldn't insert tracking to DB | 1 | Tracking insertion failed (error state) |
| 20 | couldn't send message to eligibility queue | 1 | Queue send failure (error state) |
| 21 | event is not in eventdb but has expired or decided not to keep it | 2 | Event skipped - already expired or marked for removal |
| 22 | rule cpa is not eligible, can't get affiliate data | 2 | CPA check failed - unable to retrieve affiliate details |
| 23 | rule cpa is not eligible, not under cpa | 2 | CPA check failed - affiliate not on a CPA plan |
| 24 | rule cpa is eligible, not under minimum commission contract | 2 | CPA passed - affiliate has no minimum commission threshold |
| 25 | rule cpa is eligible, reached minimum commission | 2 | CPA passed - minimum commission threshold met |
| 26 | rule cpa is not eligible, didn't reach minimum commission | 2 | CPA failed - below minimum commission threshold |
| 27 | rule cpa is eligible, chargeback under cpa, earned deposit commission | 2 | CPA chargeback eligible - deposit commission already earned |
| 28 | rule cpa is not eligible, chargeback under cpa, didn't earn deposit commission | 2 | CPA chargeback ineligible - no prior deposit commission |
| 29 | rule cpa is not eligible, chargeback not under cpa | 2 | Chargeback ineligible - affiliate not on CPA plan |
| 30 | rule cpa: can't get customer finance details | 2 | CPA check failed - unable to retrieve customer financial data |
| 31 | rule cpa is not eligible, don't have customer finance details or investment | 2 | CPA failed - missing customer financial records |
| 32 | rule cpa is not eligible, not first deposit | 2 | CPA failed - deposit is not the customer's first |
| 33 | tracking dispose called | 1 | Tracking service shutdown initiated |
| 34 | deferred messages read messages from db | 4 | Deferred message service retrieved pending messages |
| 35 | deferred service stopped | 4 | Deferred message service shut down |
| 36 | tracking service stopped | 1 | Tracking service shut down |
| 37 | commission service stopped | 3 | Commission service shut down |
| 38 | eligibility service stopped | 2 | Eligibility service shut down |
| 39 | eligibility dispose called | 2 | Eligibility service shutdown initiated |
| 40 | commission dispose called | 3 | Commission service shutdown initiated |
| 41 | deferred dispose called | 4 | Deferred service shutdown initiated |
| 42 | event is removed from affiliateTraderQueue due to expiration | 1 | Trader queue event expired and removed |
| 43 | event is read from commission queue | 3 | Event received for commission processing |
| 44 | Incorrect message token | 3 | Commission event has invalid token (error state) |
| 45 | message token is empty | 3 | Commission event has no token (error state) |
| 46 | Rule cpa is eligible chargeback | 2 | CPA chargeback eligibility confirmed |
| 47 | eligibility incorrect message token | 2 | Eligibility event has invalid token (error state) |
| 48 | eligibility message token is empty | 2 | Eligibility event has no token (error state) |
| 49 | send FTDE Pixel | 3 | First-Time Deposit Eligible pixel fired for conversion tracking |
| 50 | update affiliate to non organic | 2 | Customer reclassified from organic to affiliate-attributed |
| 51 | message is not valid event is removed | 1 | Invalid message format - event discarded |

**Key Characteristics**:
- GroupID 0: General/reprocessing
- GroupID 1: Tracking stage (Service Bus intake, queue management)
- GroupID 2: Eligibility stage (rule evaluation, CPA checks, organic checks)
- GroupID 3: Commission stage (calculation, saving, pixel firing)
- GroupID 4: Deferred message processing

**Used By**:

---

## Form Of Incorporation {#form-of-incorporation}

**Definition**: Legal structure of a corporate affiliate entity. Used during KYP (Know Your Partner) onboarding for corporate affiliates.

**Source Table**: `Dictionary.FormOfIncorporation`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Other | Legal structure not covered by standard categories |
| 2 | Private | Privately held company - shares not publicly traded |
| 3 | Public | Publicly listed company - shares traded on an exchange |

**Used By**:

---

## Identification Type {#identification-type}

**Definition**: Type of government-issued identification document submitted during KYP verification. Determines validation rules and regulatory acceptance by jurisdiction.

**Source Table**: `Dictionary.IdentificationType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Passport | International travel document - accepted in all jurisdictions |
| 2 | ID Card | National identity card - acceptance varies by country |
| 3 | National Insurance Number | UK NI number - used for tax identification |
| 4 | Codice Fiscale | Italian tax identification code |
| 5 | Det Centrale Personregister | Danish civil registration number (CPR) |
| 6 | Social Insurance Number | Canadian social insurance number |
| 7 | Medicare Number | Australian Medicare card number |
| 8 | Social Security Number | US SSN - used for tax identification |

**Used By**:

---

## ISA Product {#isa-product}

**Definition**: Individual Savings Account product types available on the platform. ISAs are UK tax-advantaged investment accounts. Each product maps to a SubAccountType.

**Source Table**: `Dictionary.ISAProduct`

**Values**:

| SubAccountTypeID | ProductID | Name | Business Meaning |
|-----------------|-----------|------|-----------------|
| 4 | isa-cash | Cash ISA | Cash savings ISA - funds held as cash with interest |
| 4 | isa-discretionary | Managed ISA | Professionally managed ISA portfolio (discretionary management) |
| 4 | isa-execution-only | DIY ISA | Self-directed ISA - customer picks their own investments |

**Used By**: AffiliateConfiguration.ISAPlan (SubAccountTypeID + ProductID), AffiliateConfiguration.ISAPlanType (SubAccountTypeID + ProductID)

---

## KYP Doc Type {#kyp-doc-type}

**Definition**: Types of documents collected during Know Your Partner verification for affiliate onboarding. Each type has specific validation requirements.

**Source Table**: `Dictionary.KYPDocType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | ID_Front | Front side of government-issued identity document |
| 2 | ID_Back | Back side of government-issued identity document |
| 3 | Passport | Full passport document scan |
| 4 | Tax Form | Tax registration or identification document |
| 5 | Wallet Screenshot | Screenshot of crypto/payment wallet for payout verification |
| 6 | Company Proof Of Address | Corporate registered address documentation |
| 7 | 147C IRS Letter | US IRS employer identification verification letter |

**Used By**:

---

## KYP Marketing Method {#kyp-marketing-method}

**Definition**: Primary marketing channel used by an affiliate to drive traffic. Collected during KYP onboarding to understand affiliate's business model.

**Source Table**: `Dictionary.KYPMarketingMethod`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | PPC | Pay-Per-Click advertising (Google Ads, Bing, etc.) |
| 2 | SEO | Search Engine Optimization - organic search traffic |
| 3 | Social Media | Traffic driven through social media platforms |
| 4 | Email Marketing | Email campaigns and newsletter-based acquisition |
| 5 | Media Buying | Direct display/programmatic advertising purchases |

**Used By**:

---

## KYP Status {#kyp-status}

**Definition**: Lifecycle state of an affiliate's Know Your Partner verification process. Controls whether the affiliate can receive commissions.

**Source Table**: `Dictionary.KYPStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Unavailable | KYP not yet initiated or not applicable |
| 2 | Unverified | KYP required but no documents submitted yet |
| 3 | In Progress | Documents submitted, review underway |
| 4 | Submit Pending | Documents prepared but not yet sent for review |
| 5 | Submitted | All documents submitted, awaiting compliance decision |
| 6 | Cancel Pending | Cancellation of KYP process initiated |
| 7 | Verified | All KYP checks passed - affiliate is fully verified |

**Used By**:

---

## Marketing Region {#marketing-region}

**Definition**: Geographic/linguistic marketing region used for segmenting affiliate operations, reporting, and regional commission structures.

**Source Table**: `Dictionary.MarketingRegion`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | Unknown | Region not determined or not applicable |
| 1 | Arabic | Arabic-speaking markets (Middle East, North Africa) |
| 2 | Asia | Asian markets (excluding specific sub-regions) |
| 3 | Australia | Australian market |
| 4 | Canada | Canadian market |
| 5 | French | French-speaking markets |
| 6 | German | German-speaking markets (DACH region) |
| 7 | India | Indian market |
| 8 | Italian | Italian-speaking markets |
| 9 | North Europe | Northern European markets (Nordics, Benelux) |
| 10 | ROE | Rest of Europe - European markets not in other categories |
| 11 | ROW | Rest of World - markets not in any specific category |
| 12 | South Africa | South African market |
| 13 | Spanish & Portuguese | Spanish and Portuguese-speaking markets (Iberia, LATAM) |
| 14 | UK | United Kingdom market |
| 15 | USA | United States market |

**Used By**:

---

## Nature Of Business {#nature-of-business}

**Definition**: Industry sector of a corporate affiliate. Collected during KYP onboarding for compliance and risk assessment purposes.

**Source Table**: `Dictionary.NatureOfBusiness`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Other | Industry not covered by standard categories |
| 2 | Real Estate | Property development, investment, or management |
| 3 | Marketing | Digital marketing, advertising, or media services |
| 4 | Construction | Building, infrastructure, or civil engineering |
| 5 | Art | Fine art, design studios, or creative industries |
| 6 | Medical | Healthcare, pharmaceutical, or medical services |
| 7 | Education | Educational institutions or training services |
| 8 | Design | Product design, UX/UI, or industrial design |

**Used By**:

---

## Payment Methods {#payment-methods}

**Definition**: Available methods for paying affiliate commissions. Determines payment processing rules, fees, and settlement timelines.

**Source Table**: `Dictionary.PaymentMethods`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | None | No payment method selected - commissions will not be paid |
| 2 | PayPal | Payment via PayPal electronic transfer |
| 3 | Wire Transfer | International bank wire transfer |
| 4 | eToro Trading Account | Commission credited directly to affiliate's eToro trading account |
| 5 | Neteller | Payment via Neteller e-wallet |
| 6 | Skrill (Moneybookers) | Payment via Skrill e-wallet |
| 7 | Webmoney | Payment via WebMoney electronic system |
| 8 | Credit Card | Payment to affiliate's credit card |
| 9 | China Union Pay | Payment via China UnionPay network |

**Used By**:

---

## Payment Row Status {#payment-row-status}

**Definition**: Processing state of an individual commission payment row. Uses bitmask-style IDs (powers of 2) allowing potential bitwise combination for status queries.

**Source Table**: `Dictionary.PaymentRowStatus`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Pending | Payment created but not yet reviewed or approved |
| 2 | Partially Approved | Some line items approved, others still under review |
| 4 | Approved | Payment fully approved and queued for processing |
| 8 | Processed | Payment has been executed and funds transferred |
| 16 | Rejected | Payment denied - will not be processed |

**Used By**:

---

## Pixel Types {#pixel-types}

**Definition**: Types of conversion tracking pixels fired to affiliate tracking systems. Each pixel type corresponds to a specific customer lifecycle event that affiliates track for attribution.

**Source Table**: `Dictionary.PixelTypes`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Registration Pixel | Fired when a customer completes registration - tracks signups |
| 6 | Approved FTD Pixel | Fired when a customer's first deposit is approved - tracks qualified conversions |
| 8 | Eligible FTD Pixel | Fired when a customer's first deposit meets eligibility criteria - tracks potential conversions |

**Key Characteristics**:
- Non-sequential IDs suggest historical pixel types were deprecated
- FTD = First Time Deposit, a key affiliate conversion metric

**Used By**:

---

## Player Level {#player-level}

**Definition**: Customer loyalty tier based on trading activity (lot count) and deposit amount. Determines cashout processing speed and VIP benefits.

**Source Table**: `Dictionary.PlayerLevel`

**Values**:

| ID | Name | Cashout Hours | Lot Range | Deposit Range | Sort |
|----|------|--------------|-----------|---------------|------|
| 1 | Bronze | 120 | 1-3,000 | $0-$999 | 1 |
| 5 | Silver | 120 | 3,001-20,000 | $1,000-$4,999 | 2 |
| 3 | Gold | 72 | 20,001-100,000 | $5,000-$19,999 | 3 |
| 2 | V.I.P | 24 | 100,001+ | $20,000+ | 4 |
| 4 | Test | 120 | 0 | $0 | 0 |

**Key Characteristics**:
- Higher tiers get faster cashout processing (VIP = 24 hours vs Bronze = 120 hours)
- Dual criteria: both lot count AND deposit thresholds
- Test level (ID=4) is for QA/development purposes

**Used By**: BILoad.RevsharePositionSummary (PlayerLevelID)

---

## Position Asset Type {#position-asset-type}

**Definition**: Classifies the type of financial instrument or asset class for a trading position. Used for commission segmentation and reporting by asset class.

**Source Table**: `Dictionary.PositionAssetType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 0 | All | Wildcard/aggregate - represents all asset types in filter contexts |
| 1 | Forex | Foreign exchange currency pairs |
| 2 | Commodity | Physical commodities (gold, oil, etc.) |
| 3 | CFD | Contract for Difference on various underlyings |
| 4 | Indices | Stock market indices (S&P 500, FTSE, etc.) |
| 5 | Stocks | Individual company equities |
| 6 | ETF | Exchange-Traded Funds |
| 7 | Bonds | Government or corporate bonds |
| 8 | TrustFunds | Managed investment trust funds |
| 9 | Options | Options contracts |
| 10 | Crypto | Cryptocurrency assets |
| 11 | Copy | CopyTrader positions - mirroring another trader |

**Used By**: AffiliateConfiguration.FirstPositionAssetPlan (PositionAssetTypeID), AffiliateConfiguration.FirstPositionAssetPlanType (PositionAssetTypeID), AffiliateConfiguration.TraderFirstAssetPosition (FirstPositionAssetTypeID)

---

## Service Type {#service-type}

**Definition**: Classifies the type of affiliate service or event that triggers commission processing.

**Source Table**: `Dictionary.ServiceType`

**Values**:

| ID | Name | Business Meaning |
|----|------|-----------------|
| 1 | Credit | Financial credit event (deposit, bonus) triggers commission |
| 2 | Registration | Customer registration triggers commission |
| 3 | Sale | Trading activity/sale triggers commission |

**Used By**:

---

## Business Concepts

*No concept entries yet - will be populated as objects are documented.*
