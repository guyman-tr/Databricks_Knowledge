# Dictionary.ApplicationIdentifier

> Registry of 15 client application identifiers — mobile apps, web platforms, and internal services — each mapped to a platform type, enabling per-application tracking of deposits, logins, and customer activity.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ApplicationIdentifierID (INT, PK CLUSTERED) |
| **Partition** | DICTIONARY filegroup (PAGE compression) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ApplicationIdentifier maps each client application (mobile app, web platform, internal service) to a unique identifier and its parent platform type. This enables the system to distinguish which specific application a customer used to perform an action — not just "mobile" but specifically "iOSTrader" vs "iOSWrapper" vs "AndroideToro".

This granularity is critical for deposit analytics (which app drove the deposit?), login tracking (BackOffice.GetCustomerLogins), fraud detection (suspicious patterns from specific apps), and regulatory reporting. The PlatformID FK to Dictionary.Platform groups applications into broader platform categories (Web=1, iOS=2, Android=3).

Referenced by extensive billing and reporting procedures: Billing.REPORT_IdealDeposits, Billing.DepositAlertReportByPlatform, Billing.DepositAlertReportByPlatformCountry, Billing.iDEALDepositApproveRatio (and variants), Billing.DepositMetricByIdGet, Billing.GetScheduledTaskMonitorProcessingEntitiesById, dbo.P_GetApplicationIdentifiers (returns all identifiers), dbo.SSRS_DepositApproveRatio, BackOffice.GetCustomerLogins, and BackOffice.AddDocumentClassification.

---

## 2. Business Logic

### 2.1 Application-to-Platform Mapping

**What**: How client applications are grouped into platform categories.

**Columns/Parameters Involved**: `ApplicationIdentifierID`, `ApplicationIdentifier`, `PlatformID`

**Rules**:
- **PlatformID 1 (Web)**: Retoro, cashierweb, webtrader, localsts, pushstatusservice, registrationservice, referfriends.etoro.com, etoro.com/support — browser-based and server-side services
- **PlatformID 2 (iOS)**: iOSWrapper, iOSTrader, retoroios, iosopenbook — Apple mobile applications
- **PlatformID 3 (Android)**: ReToroAndroid, AndroidTrader, AndroideToro — Google mobile applications
- Each application has a unique string identifier used in API calls and logging
- Multiple application names per platform reflect different app versions, wrappers, and feature-specific clients

**Diagram**:
```
Platform Hierarchy:

  Dictionary.Platform
       │
       ├── PlatformID 1 (Web)
       │     ├── Retoro
       │     ├── cashierweb
       │     ├── webtrader
       │     ├── localsts
       │     ├── pushstatusservice
       │     ├── registrationservice
       │     ├── referfriends.etoro.com
       │     └── etoro.com/support
       │
       ├── PlatformID 2 (iOS)
       │     ├── iOSWrapper
       │     ├── iOSTrader
       │     ├── retoroios
       │     └── iosopenbook
       │
       └── PlatformID 3 (Android)
             ├── ReToroAndroid
             ├── AndroidTrader
             └── AndroideToro
```

---

## 3. Data Overview

| ApplicationIdentifierID | ApplicationIdentifier | PlatformID | Meaning |
|---|---|---|---|
| 2 | iOSTrader | 2 | Native iOS trading app. The primary mobile trading experience for iPhone/iPad users. Used for deposit tracking and login analytics. |
| 5 | AndroideToro | 3 | Primary Android app. The main eToro mobile app on Google Play. Most Android deposits and logins originate here. |
| 7 | cashierweb | 1 | Web cashier/payment page. Handles deposit and withdrawal flows in the browser. Billing reports (iDEAL, deposit metrics) segment by this identifier. |
| 8 | webtrader | 1 | Web trading platform. The full browser-based trading interface. Login sessions and trading activity tracked separately from mobile. |
| 12 | registrationservice | 1 | Backend registration service. Tracks signups initiated through server-side registration flows rather than direct client interaction. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ApplicationIdentifierID | int | NO | - | VERIFIED | Primary key identifying the client application. Values 1-15. Used in billing reports, login tracking, and deposit analytics to identify which specific application performed an action. |
| 2 | ApplicationIdentifier | nvarchar(100) | NO | - | VERIFIED | Unique string identifier for the application (e.g., 'iOSTrader', 'webtrader', 'cashierweb'). Sent by client applications in API calls. Used as a filter/group-by column in deposit reports (Billing.REPORT_IdealDeposits, Billing.DepositAlertReportByPlatform). |
| 3 | PlatformID | int | NO | - | VERIFIED | FK to Dictionary.Platform.Id. Groups applications into platform categories: 1=Web, 2=iOS, 3=Android. Enables platform-level analytics (e.g., "all iOS deposits") while ApplicationIdentifier provides app-level granularity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PlatformID | Dictionary.Platform | Explicit FK (FK_DAppIdent_PlatformID) | Groups this application under a platform category (Web/iOS/Android) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.REPORT_IdealDeposits | ApplicationIdentifierID | JOIN | iDEAL deposit reporting by application |
| Billing.DepositAlertReportByPlatform | ApplicationIdentifierID | JOIN | Deposit alerts segmented by app |
| Billing.DepositAlertReportByPlatformCountry | ApplicationIdentifierID | JOIN | Deposit alerts by app + country |
| Billing.iDEALDepositApproveRatio | ApplicationIdentifierID | JOIN | Deposit approval rates per app |
| Billing.DepositMetricByIdGet | ApplicationIdentifierID | JOIN | Deposit metrics lookup |
| BackOffice.GetCustomerLogins | ApplicationIdentifierID | JOIN | Customer login history by app |
| dbo.P_GetApplicationIdentifiers | - | SELECT ALL | Returns full application list |
| dbo.SSRS_DepositApproveRatio | ApplicationIdentifierID | JOIN | SSRS report data |
| BackOffice.AddDocumentClassification | ApplicationIdentifierID | Implicit | Document classification by app |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.ApplicationIdentifier (table)
└── Dictionary.Platform (table) — FK target for PlatformID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Platform | Table | FK — PlatformID references Platform.Id |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.REPORT_IdealDeposits | Stored Procedure | Reader — deposit reporting |
| Billing.DepositAlertReportByPlatform | Stored Procedure | Reader — deposit alerts |
| Billing.iDEALDepositApproveRatio | Stored Procedure | Reader — approval rates |
| BackOffice.GetCustomerLogins | Stored Procedure | Reader — login history |
| dbo.P_GetApplicationIdentifiers | Stored Procedure | Reader — full list |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_ApplicationIdentifier | CLUSTERED PK | ApplicationIdentifierID ASC | - | - | Active (FILLFACTOR 95, PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_ApplicationIdentifier | PRIMARY KEY | Unique application identifier |
| FK_DAppIdent_PlatformID | FOREIGN KEY | PlatformID → Dictionary.Platform(Id) |

---

## 8. Sample Queries

### 8.1 List all applications with platform names
```sql
SELECT  ai.ApplicationIdentifierID,
        ai.ApplicationIdentifier,
        dp.Name             AS Platform
FROM    Dictionary.ApplicationIdentifier ai WITH (NOLOCK)
JOIN    Dictionary.Platform dp WITH (NOLOCK)
        ON ai.PlatformID = dp.Id
ORDER BY ai.ApplicationIdentifierID;
```

### 8.2 Count applications per platform
```sql
SELECT  dp.Name             AS Platform,
        COUNT(*)            AS AppCount
FROM    Dictionary.ApplicationIdentifier ai WITH (NOLOCK)
JOIN    Dictionary.Platform dp WITH (NOLOCK)
        ON ai.PlatformID = dp.Id
GROUP BY dp.Name
ORDER BY AppCount DESC;
```

### 8.3 Find all mobile applications
```sql
SELECT  ai.ApplicationIdentifierID,
        ai.ApplicationIdentifier,
        dp.Name             AS Platform
FROM    Dictionary.ApplicationIdentifier ai WITH (NOLOCK)
JOIN    Dictionary.Platform dp WITH (NOLOCK)
        ON ai.PlatformID = dp.Id
WHERE   ai.PlatformID IN (2, 3);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ApplicationIdentifier | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ApplicationIdentifier.sql*
