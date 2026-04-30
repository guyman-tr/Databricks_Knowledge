# Billing.ZotapayConfiguration

> Key-value configuration store for the Zotapay third-party payment gateway integration, holding endpoint URLs, merchant credentials, and routing identifiers.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered + 1 unique on Name) |

---

## 1. Business Meaning

Billing.ZotapayConfiguration is a name-value settings table that drives the Zotapay payment gateway integration. Zotapay is a third-party payment processor used by eToro for card-based deposit flows. Each row stores one configuration parameter identified by a unique name key and its corresponding value string.

This table exists to allow the Zotapay integration to be reconfigured without a code deployment. URLs, merchant identifiers, and endpoint IDs can be updated in place. Without this table, Zotapay credentials and routing targets would be hardcoded, making environment changes or credential rotations require a release cycle.

Data is read by application services that construct Zotapay API requests. The five rows represent the complete set of connection parameters: the gateway API base URL, the callback notification endpoint, the post-payment redirect URL, the merchant control GUID (authentication), and the endpoint routing identifier.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| ID | Name | Value | Meaning |
|----|------|-------|---------|
| 1 | RedirectUrl | http://52.166.244.157:8443/api/Unionpay/ZotapayPostback?TransID= | The URL to which Zotapay redirects the browser after a payment attempt. The TransID query parameter is appended dynamically by Zotapay so eToro can match the postback to the original transaction. |
| 2 | ZotapayUrl | https://sandbox.zotapay.com/paynet/api/v2/sale-form/ | The Zotapay gateway base URL used to initiate sale-form payment requests. Currently points to the sandbox environment - production deployments would use the live Zotapay domain. |
| 3 | MerchentControl | 704877C9-4C57-4424-9F4D-1EA23E196F10 | Merchant authentication GUID sent to Zotapay to identify and authorize eToro as a merchant. This credential is required for all API calls. (Note: column name has a typo - "Merchent" is intentional in the stored value name.) |
| 4 | EndpointId | 1372 | Zotapay endpoint routing identifier that selects the correct processing channel or merchant account within the Zotapay platform. |
| 5 | CallbackUrl | http://52.166.244.157:8080/Zotapay/Notification.ashx | The server-to-server notification URL Zotapay calls asynchronously to confirm payment outcomes. This is distinct from RedirectUrl - the callback is machine-to-machine, the redirect is browser-based. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key, auto-incremented. Not FOR REPLICATION - value is generated locally and not replicated from a publisher. No business meaning beyond row identity. |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Configuration parameter name (key). Unique constraint Idx_Billing_ZotapayConfiguration_Name enforces one row per parameter. Known values from live data: RedirectUrl, ZotapayUrl, MerchentControl, EndpointId, CallbackUrl. Acts as the lookup key for application code reading configuration. |
| 3 | Value | varchar(max) | YES | - | CODE-BACKED | Configuration parameter value. varchar(max) accommodates both short identifiers (EndpointId = "1372") and long URL strings. Contains URLs, GUIDs, and numeric endpoint identifiers depending on the Name key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SQL files. This configuration table is consumed by application-layer services (not stored procedures).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Billing_ZotapayConfiguration | CLUSTERED PK | ID ASC | - | - | Active |
| Idx_Billing_ZotapayConfiguration_Name | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Billing_ZotapayConfiguration | PRIMARY KEY | Enforces row uniqueness on ID. |
| Idx_Billing_ZotapayConfiguration_Name | UNIQUE | Enforces that each configuration key (Name) appears at most once - prevents duplicate configuration entries for the same parameter. |

---

## 8. Sample Queries

### 8.1 Retrieve all Zotapay configuration parameters

```sql
SELECT ID, Name, Value
FROM Billing.ZotapayConfiguration WITH (NOLOCK)
ORDER BY ID;
```

### 8.2 Look up a specific configuration value by name

```sql
SELECT Value
FROM Billing.ZotapayConfiguration WITH (NOLOCK)
WHERE Name = 'ZotapayUrl';
```

### 8.3 Retrieve gateway URL and merchant credentials together

```sql
SELECT
    MAX(CASE WHEN Name = 'ZotapayUrl'       THEN Value END) AS GatewayUrl,
    MAX(CASE WHEN Name = 'MerchentControl'  THEN Value END) AS MerchantControlGUID,
    MAX(CASE WHEN Name = 'EndpointId'       THEN Value END) AS EndpointId,
    MAX(CASE WHEN Name = 'CallbackUrl'      THEN Value END) AS CallbackUrl,
    MAX(CASE WHEN Name = 'RedirectUrl'      THEN Value END) AS RedirectUrl
FROM Billing.ZotapayConfiguration WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 5.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.ZotapayConfiguration | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.ZotapayConfiguration.sql*
