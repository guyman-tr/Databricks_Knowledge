# Dictionary.Funnel

> Lookup table defining 120+ customer acquisition and registration funnels — the specific marketing channel, campaign, or product entry point through which a customer registered on eToro.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FunnelID (INT, NONCLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK + unique Name index) |

---

## 1. Business Meaning

Dictionary.Funnel catalogs every customer acquisition channel and registration entry point that eToro uses. Each funnel represents a specific marketing campaign, product page, mobile app variant, or partner integration through which a customer first registered. This is one of the most marketing-critical lookup tables in the system — it enables attribution of customer registrations to specific campaigns and platforms.

This table exists because eToro runs a multi-channel global acquisition strategy. Customers can register through the main website, mobile apps (iOS/Android), landing pages for specific campaigns (crypto incentives, stock offerings), affiliate programs, partner integrations (Finder, Forbes), and social investment features (CopyTrading). Each entry point needs a distinct funnel ID so the marketing team can measure conversion rates, cost-per-acquisition, and lifetime value by channel.

FunnelID is stored on Customer.CustomerStatic (via explicit FK) and Customer.RegistrationRequest when a customer registers. It is also recorded on Billing.Deposit for first-time deposits to track the acquisition-to-deposit funnel. BackOffice billing reports join to this table to display the registration source for each customer or deposit.

---

## 2. Business Logic

### 2.1 Funnel Categories

**What**: Funnels are organized by platform type and campaign purpose.

**Columns/Parameters Involved**: `FunnelID`, `Name`, `PlatformID`

**Rules**:
- **Core platform funnels** (1-9): Main eToro products — WebTrader, OpenBook, Mobile, BackOffice, Cashier
- **Marketing landing pages** (12-51): Specific campaign pages — stocks offerings, crypto incentives, CFD campaigns, regional promotions
- **Mobile app variants** (15-17, 25, 33, 42-43, 52-53): Platform-specific mobile entry points — Android/iOS for eToro Trader, OpenBook, wallet, reToro
- **Affiliate & partner** (104, 107-109, 115, 118-119): Traffic from affiliate partnerships and content collaborations
- **Regional campaigns** (37-39, 65-68, 112-114): Geo-targeted campaigns for specific markets (China, UAE, Australia, Brazil, SEA)
- **AI chatbot funnels** (123-126): Registrations originating from AI assistants (ChatGPT, Gemini, Copilot, Perplexity)
- PlatformID links to Dictionary.Platform to classify the device/client type (0=Unknown, 1=Web, 2=iOS, 3=Android)
- FunnelID -9 is reserved for automated testing

### 2.2 Funnel-to-Platform Mapping

**What**: Each funnel is associated with a platform type, indicating the device category.

**Columns/Parameters Involved**: `PlatformID`

**Rules**:
- PlatformID 0 (Unknown/Cross-platform): Funnels that are platform-agnostic or server-side (BackOffice, campaigns, incentives)
- PlatformID 1 (Web): Desktop browser funnels — WebTrader, eToro Homepage, landing pages, website registration
- PlatformID 2 (iOS): Apple mobile app funnels — iOS eToro Trader, OpenBook for iOS, wallet iOS, reToro iOS
- PlatformID 3 (Android): Android mobile app funnels — Android eToro Trader, Trade/Social Alerts, OpenBook Android, wallet Android

---

## 3. Data Overview

| FunnelID | Name | PlatformID | Meaning |
|---|---|---|---|
| 1 | eToro Client | 1 | Primary eToro web client registration — the main desktop trading platform entry point. Captures customers who register directly through the standard web interface. |
| 17 | iOS eToro Trader | 2 | Registrations through the eToro trading app on iOS. The primary Apple mobile acquisition channel, capturing customers who download the app from the App Store. |
| 15 | Android eToro Trader | 3 | Registrations through the eToro trading app on Android. The primary Google Play acquisition channel. |
| 74 | eToro Money | 0 | Registrations originating from the eToro Money (wallet/banking) product. Captures customers who enter the ecosystem through the financial services product rather than trading. |
| 123 | Chatgpt | 0 | Registrations originating from ChatGPT referrals — tracks customers who were directed to eToro through AI chatbot recommendations, reflecting eToro's presence in AI-driven discovery channels. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FunnelID | int | NO | - | VERIFIED | Primary key identifying the acquisition funnel. Ranges from -9 (AutomationTest) through 130+. Stored on Customer.CustomerStatic via FK and on Customer.RegistrationRequest at registration time. Also stored on Billing.Deposit for first-deposit attribution. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics. Describes the campaign/channel/product that drove registration. Enforced unique via DFNL_NAME index. |
| 3 | PlatformID | int | NO | 0 | VERIFIED | Platform category for this funnel. 0=Unknown/Cross-platform, 1=Web, 2=iOS, 3=Android. Defaults to 0 for server-side or platform-agnostic funnels. Links to Dictionary.Platform for platform name resolution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlatformID | Dictionary.Platform | Implicit Lookup | Classifies funnel by device/client platform |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerStatic | FunnelID | FK | Records which funnel each customer registered through |
| Customer.RegistrationRequest | FunnelID | Implicit Lookup | Records funnel at registration request time |
| Billing.Deposit | FunnelID | Implicit Lookup | Records funnel for first-deposit attribution |
| Customer.InsertRealCustomer | FunnelID | Write | Sets funnel when creating a real customer account |
| Customer.RegisterReal | FunnelID | Write | Sets funnel during real account registration |
| Customer.RegisterDemo | FunnelID | Write | Sets funnel during demo account registration |
| BackOffice.BillingDepositsPCIVersion | FunnelID | Read | Displays funnel in deposit billing reports |
| Internal.GetFunnels | - | Read | Returns all funnels for configuration/UI consumption |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK to FunnelID — records registration channel |
| Customer.RegistrationRequest | Table | References FunnelID at registration time |
| Billing.Deposit | Table | References FunnelID for first-deposit attribution |
| Customer.InsertRealCustomer | Stored Procedure | Sets FunnelID on new real customer records |
| Customer.RegisterReal | Stored Procedure | Uses FunnelID during registration |
| Customer.RegisterDemo | Stored Procedure | Uses FunnelID during demo registration |
| BackOffice.BillingDepositsPCIVersion | Stored Procedure | JOINs for deposit billing reports |
| Internal.GetFunnels | Stored Procedure | Reads all funnels for UI/configuration |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DFNL | NC PK | FunnelID ASC | - | - | Active |
| DFNL_NAME | UNIQUE NC | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DFNL | PRIMARY KEY | Unique funnel identifier |
| DFNL_NAME | UNIQUE INDEX | Each funnel has a unique name |
| Df_Dictionary_Funnel_PlatformID | DEFAULT | PlatformID defaults to 0 (Unknown/Cross-platform) |

---

## 8. Sample Queries

### 8.1 List all active funnels with platform
```sql
SELECT  f.FunnelID,
        f.Name,
        f.PlatformID,
        p.PlatformName
FROM    [Dictionary].[Funnel] f WITH (NOLOCK)
LEFT JOIN [Dictionary].[Platform] p WITH (NOLOCK)
        ON f.PlatformID = p.PlatformID
WHERE   f.FunnelID > 0
ORDER BY f.FunnelID;
```

### 8.2 Count customer registrations by funnel
```sql
SELECT  TOP 20
        df.Name         AS FunnelName,
        COUNT(*)        AS CustomerCount
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[Funnel] df WITH (NOLOCK)
        ON cs.FunnelID = df.FunnelID
GROUP BY df.Name
ORDER BY CustomerCount DESC;
```

### 8.3 Find all mobile app funnels (iOS + Android)
```sql
SELECT  f.FunnelID,
        f.Name,
        CASE f.PlatformID
            WHEN 2 THEN 'iOS'
            WHEN 3 THEN 'Android'
        END AS Platform
FROM    [Dictionary].[Funnel] f WITH (NOLOCK)
WHERE   f.PlatformID IN (2, 3)
ORDER BY f.PlatformID, f.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Funnel | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Funnel.sql*
