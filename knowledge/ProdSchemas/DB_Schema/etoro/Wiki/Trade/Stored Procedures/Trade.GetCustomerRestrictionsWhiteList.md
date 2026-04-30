# Trade.GetCustomerRestrictionsWhiteList

> Returns the leverage restriction whitelist - customers who have custom min/max/default leverage overrides per instrument, enriched with country and player level.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Full whitelist scan (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetCustomerRestrictionsWhiteList retrieves the complete list of customers who have been granted custom leverage limits on specific instruments, overriding the platform's default leverage rules. Each row represents one customer-instrument override showing the minimum, maximum, and default leverage allowed for that customer on that instrument.

This procedure exists because certain customers (e.g., professional traders, high-net-worth individuals, or specific regulatory categories) may be granted different leverage limits than the standard platform defaults. Leverage restrictions are a key regulatory control - different jurisdictions cap leverage at different levels (e.g., EU ESMA rules limit retail leverage to 30:1 on forex). The whitelist allows specific customers to have custom overrides.

The procedure joins Customer.CustomerStatic (for GCID, username, country, player level) with Trade.LeveragesRestrictionsWhiteList (the override rules per GCID/instrument), enriched with Dictionary.PlayerLevel names and Dictionary.Country names. It returns all whitelist entries in a single scan with no input parameters.

---

## 2. Business Logic

### 2.1 Leverage Override Whitelist

**What**: Per-customer, per-instrument leverage limit overrides that bypass standard regulatory/platform defaults.

**Columns/Parameters Involved**: `GCID`, `InstrumentID`, `MaxLeverage`, `MinLeverage`, `DefaultLeverage`

**Rules**:
- Each whitelist entry specifies a GCID + InstrumentID combination with custom leverage bounds
- MaxLeverage: The maximum leverage this customer can use on this instrument
- MinLeverage: The minimum leverage (floor) for this customer on this instrument
- DefaultLeverage: The default leverage pre-selected in the UI for this customer on this instrument
- Enriched with CountryIDByIP and PlayerLevelID from CustomerStatic for context

**Diagram**:
```
Customer.CustomerStatic (GCID, UserName, CountryIDByIP, PlayerLevelID)
  |
  INNER JOIN Trade.LeveragesRestrictionsWhiteList (GCID, InstrumentID, leverage bounds)
  |
  +-- Dictionary.PlayerLevel (PlayerLevelID -> Name)
  +-- Dictionary.Country (CountryIDByIP -> Name)
  |
  Output: GCID, UserName, InstrumentID, Min/Max/DefaultLeverage, Country, PlayerLevel
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

This procedure has no input parameters - it returns the entire whitelist.

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | bigint | NO | - | CODE-BACKED | Global Customer ID. Identifies the customer with the leverage override. From Customer.CustomerStatic. |
| 2 | UserName | nvarchar | YES | - | CODE-BACKED | Customer's username on the platform. From Customer.CustomerStatic. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | Instrument for which leverage is overridden. FK to Trade.Instrument. From Trade.LeveragesRestrictionsWhiteList. |
| 4 | MaxLeverage | int | YES | - | CODE-BACKED | Maximum leverage allowed for this customer on this instrument. Overrides platform/regulatory default max. |
| 5 | MinLeverage | int | YES | - | CODE-BACKED | Minimum leverage for this customer on this instrument. |
| 6 | DefaultLeverage | int | YES | - | CODE-BACKED | Default leverage pre-selected in the UI for this customer-instrument pair. |
| 7 | CountryIDByIP | int | YES | - | CODE-BACKED | Country detected by IP for this customer. FK to Dictionary.Country. From Customer.CustomerStatic. |
| 8 | CountryName | varchar | YES | - | CODE-BACKED | Human-readable country name. From Dictionary.Country.Name via LEFT JOIN. |
| 9 | PlayerLevelID | int | YES | - | CODE-BACKED | Customer's player level/tier. FK to Dictionary.PlayerLevel. From Customer.CustomerStatic. |
| 10 | PlayerLevelName | varchar | YES | - | CODE-BACKED | Human-readable player level name (e.g., Silver, Gold, Platinum). From Dictionary.PlayerLevel.Name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | Customer.CustomerStatic | JOIN | Customer static data (username, country, player level) |
| GCID + InstrumentID | Trade.LeveragesRestrictionsWhiteList | JOIN | Per-customer leverage override rules |
| PlayerLevelID | Dictionary.PlayerLevel | JOIN | Player level lookup for display name |
| CountryIDByIP | Dictionary.Country | LEFT JOIN | Country lookup for display name |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCustomerRestrictionsWhiteList (procedure)
+-- Customer.CustomerStatic (table)
+-- Trade.LeveragesRestrictionsWhiteList (table)
+-- Dictionary.PlayerLevel (table)
+-- Dictionary.Country (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | INNER JOIN on GCID for customer details |
| Trade.LeveragesRestrictionsWhiteList | Table | INNER JOIN on GCID for leverage overrides |
| Dictionary.PlayerLevel | Table | INNER JOIN for player level name |
| Dictionary.Country | Table | LEFT JOIN for country name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | No SQL callers discovered |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get the full leverage whitelist

```sql
EXEC Trade.GetCustomerRestrictionsWhiteList;
```

### 8.2 Manually query whitelist for a specific instrument

```sql
SELECT  CS.GCID, CS.UserName, WL.InstrumentID, WL.MaxLeverage, WL.MinLeverage, WL.DefaultLeverage
FROM    Customer.CustomerStatic CS WITH (NOLOCK)
INNER JOIN Trade.LeveragesRestrictionsWhiteList WL WITH (NOLOCK) ON CS.GCID = WL.GCID
WHERE   WL.InstrumentID = 1001;
```

### 8.3 Count whitelist entries by country

```sql
SELECT  DC.Name AS Country, COUNT(*) AS WhitelistEntries
FROM    Customer.CustomerStatic CS WITH (NOLOCK)
INNER JOIN Trade.LeveragesRestrictionsWhiteList WL WITH (NOLOCK) ON CS.GCID = WL.GCID
LEFT JOIN Dictionary.Country DC WITH (NOLOCK) ON CS.CountryIDByIP = DC.CountryID
GROUP BY DC.Name
ORDER BY WhitelistEntries DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.2/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCustomerRestrictionsWhiteList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCustomerRestrictionsWhiteList.sql*
