# Dictionary.TradeLevel

> Classifies customer trading platform access levels (Normal, eToro Pro, eToro Visual, etc.).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TradeLevelID (int, PK) |
| **Row Count** | 5 |
| **Indexes** | 2 (clustered PK + unique nonclustered on Name) |
| **Filegroup** | DICTIONARY |

---

## 1. Business Meaning

### What It Is
Dictionary.TradeLevel is a lookup table defining the trading platform access levels available to customers. Each level determines which trading interface/experience the customer uses.

### Why It Exists
eToro historically offered multiple trading interfaces — the standard platform ("Normal"), a professional-grade interface ("eToro Pro"), and a simplified visual interface ("eToro Visual"). This table codifies which platform experience each customer is assigned to, enabling the system to route users to the appropriate UI and apply platform-specific rules.

### How It Works
The `TradeLevelID` is stored in `Customer.CustomerStatic`, `Customer.RegistrationRequest`, and `History.Customer`. During registration (`Customer.RegisterReal`, `Customer.RegisterDemo`, `Customer.RegisterIB`), the trade level is set. `Customer.SetTradeLevel` allows changing a customer's level. Multiple customer views expose this field for UI routing.

---

## 2. Business Logic

### Value Map (Complete — 5 rows)

| TradeLevelID | Name | Business Meaning |
|-------------|------|------------------|
| 0 | Normal | Standard eToro trading platform — default for all users |
| 1 | eToro Pro | Professional trading interface with advanced charting/tools |
| 2 | eToro Visual | Simplified visual trading experience |
| 3 | Pro Only | Restricted to professional interface only |
| 4 | Visual Only | Restricted to visual interface only |

### Legacy Feature
The Pro/Visual distinction is largely historical — the current unified platform may not actively differentiate these levels, but the data structure remains for backward compatibility.

---

## 3. Data Overview

| TradeLevelID | Name | Scenario |
|-------------|------|----------|
| 0 | Normal | New user registers and gets standard platform access |
| 1 | eToro Pro | Experienced trader upgraded to professional interface |
| 2 | eToro Visual | User routed to simplified visual trading |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TradeLevelID | int | NO | — | HIGH | Primary key identifying the trade level. `0`=Normal (default), `1`=eToro Pro, `2`=eToro Visual, `3`=Pro Only, `4`=Visual Only. Referenced by Customer.CustomerStatic and History.Customer. |
| 2 | Name | char(50) | NO | — | HIGH | Platform level label. Fixed-width with trailing spaces. Unique via DTDL_NAME index. |

---

## 5. Relationships

### Referenced By (Implicit)

| Consumer Table | Column | Evidence |
|----------------|--------|----------|
| Customer.CustomerStatic | TradeLevelID | Customer profile |
| Customer.RegistrationRequest | TradeLevelID | Registration data |
| Customer.ZeroCustomer | TradeLevelID | Template customer |
| History.Customer | TradeLevelID | Historical snapshots |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Customer.RegisterReal | INSERT | Sets level during registration |
| Customer.RegisterDemo | INSERT | Demo account registration |
| Customer.RegisterIB | INSERT | IB user registration |
| Customer.SetTradeLevel | UPDATE | Changes customer trade level |
| Customer.PostRegisterOperations | UPDATE | Post-registration level setup |
| Customer.UpdateAccountUserInfoRemote | UPDATE | Remote account update |
| BackOffice.GetCustomerByCID | SELECT | Customer lookup |
| BackOffice.GetHistoryCustomer | SELECT | Historical customer |
| BackOffice.Bulk_UpdateAccountUserInfoRemote | UPDATE | Bulk updates |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table.

### Depended On By
- `Customer.CustomerStatic` — stores TradeLevelID per customer
- 9+ procedures for registration and customer management

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_DTDL | CLUSTERED PK | TradeLevelID ASC | FILLFACTOR 90 |
| DTDL_NAME | UNIQUE NONCLUSTERED | Name ASC | FILLFACTOR 90 |

---

## 8. Sample Queries

```sql
-- Get all trade levels
SELECT  TradeLevelID, RTRIM(Name) AS Name
FROM    Dictionary.TradeLevel WITH (NOLOCK)
ORDER BY TradeLevelID;

-- Count customers by trade level
SELECT  RTRIM(tl.Name) AS TradeLevel, COUNT(*) AS Customers
FROM    Customer.CustomerStatic cs WITH (NOLOCK)
JOIN    Dictionary.TradeLevel tl WITH (NOLOCK) ON cs.TradeLevelID = tl.TradeLevelID
GROUP BY tl.Name ORDER BY Customers DESC;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `TradeLevel`.

---

*Generated: 2026-03-14 | Quality: 9.2/10*
*Object: Dictionary.TradeLevel | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TradeLevel.sql*
