# Dictionary.TimeZone

> Maps GMT offset time zones for customer profile geographic classification.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TimeZoneID (int, PK) |
| **Row Count** | 27 |
| **Indexes** | 2 (clustered PK + unique nonclustered on Name) |
| **Filegroup** | DICTIONARY |

---

## 1. Business Meaning

### What It Is
Dictionary.TimeZone is a lookup table containing 27 time zone definitions spanning GMT-12 through GMT+13, plus an "Unknown" placeholder. Each entry maps a numeric offset from Greenwich Mean Time.

### Why It Exists
Customer registration and profile management require recording the user's time zone for display preferences, communication scheduling, and regulatory reporting. This table provides the canonical list of UTC offsets used across the customer profile system.

### How It Works
The `TimeZoneID` is stored in `Customer.CustomerStatic`, `Customer.RegistrationRequest`, and `History.Customer`. During registration (`Customer.RegisterReal`, `Customer.RegisterIB`) and profile updates (`Customer.DemographyEdit`, `Customer.P_UpdateCustomer`), the customer's time zone is persisted. Multiple customer views (`Customer.Customer`, `Customer.CustomerSafty`, `Customer.GetDemography`) expose this value for display.

---

## 2. Business Logic

### Value Map (27 rows — key entries shown)

| TimeZoneID | Name | Offset | Example Regions |
|------------|------|--------|-----------------|
| 0 | Unknown | 0.00 | Default/unspecified |
| 1 | GMT -12 | -12.00 | Baker Island |
| 5 | GMT -08 | -8.00 | US Pacific (PST) |
| 8 | GMT -05 | -5.00 | US Eastern (EST) |
| 13 | GMT +00 | 0.00 | UK/GMT |
| 14 | GMT +01 | 1.00 | Central Europe (CET) |
| 15 | GMT +02 | 2.00 | Israel/Cyprus (IST/EET) |
| 20 | GMT +07 | 7.00 | Southeast Asia |
| 26 | GMT +13 | 13.00 | Tonga/Samoa |

### Design Notes
- Sequential IDs from 0-26 covering the full UTC offset range
- Fixed-width `char(50)` Name field with trailing spaces
- `numeric(4,2)` Offset allows half-hour zones (e.g., +5.50 for India), though current data only uses whole hours

---

## 3. Data Overview

| TimeZoneID | Name | Offset | Scenario |
|------------|------|--------|----------|
| 0 | Unknown | 0.00 | New registration before timezone is detected |
| 8 | GMT -05 | -5.00 | US customer from New York |
| 15 | GMT +02 | 2.00 | Israeli customer (eToro HQ timezone) |
| 22 | GMT +09 | 9.00 | Japanese customer |
| 24 | GMT +11 | 11.00 | Australian customer (Sydney) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TimeZoneID | int | NO | — | HIGH | Primary key identifying the time zone. `0`=Unknown, `1-26`=GMT-12 through GMT+13. Referenced by Customer.CustomerStatic, Customer.RegistrationRequest, History.Customer. |
| 2 | Name | char(50) | NO | — | HIGH | Time zone label (e.g., "GMT +02"). Fixed-width with trailing spaces. Unique via DTMZ_NAME index. |
| 3 | Offset | numeric(4,2) | NO | — | HIGH | UTC offset in hours. Range -12.00 to +13.00. Allows decimal for half-hour zones (though currently only whole-hour values used). |

---

## 5. Relationships

### Referenced By (Implicit — no declared FK)

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| Customer.CustomerStatic | TimeZoneID | Implicit FK | Customer profile static data |
| Customer.RegistrationRequest | TimeZoneID | Implicit FK | Registration request data |
| Customer.ZeroCustomer | TimeZoneID | Implicit FK | Default/template customer |
| History.Customer | TimeZoneID | Implicit FK | Historical customer snapshots |

### View Consumers

| View | Purpose |
|------|---------|
| Customer.Customer | Main customer view with TimeZoneID |
| Customer.CustomerSafty | Schema-bound customer view |
| Customer.GetDemography | Demographics including timezone |
| Customer.IsCustomerFund | Fund customer view |
| DWH.GetCustomerCurrentInfo | Data warehouse customer extract |
| dbo.FilteredCustomer | Filtered customer access |
| IBUser1.FilteredCustomer | IB user filtered view |
| IBUser2.FilteredCustomer | IB user filtered view |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Customer.RegisterReal | INSERT | Sets timezone during registration |
| Customer.RegisterIB | INSERT | IB user registration |
| Customer.InsertRealCustomer | INSERT | Customer creation |
| Customer.DemographyEdit | UPDATE | Demographics editing |
| Customer.P_UpdateCustomer | UPDATE | General customer update |
| BackOffice.GetCustomerByCID | SELECT | Customer lookup with timezone |
| BackOffice.GetHistoryCustomer | SELECT | Historical customer data |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- `Customer.CustomerStatic` — stores TimeZoneID per customer
- 7+ procedures for registration and profile management
- 8+ views for customer data access

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_DTMZ | CLUSTERED PK | TimeZoneID ASC | FILLFACTOR 90 |
| DTMZ_NAME | UNIQUE NONCLUSTERED | Name ASC | FILLFACTOR 90 — enforces unique timezone labels |

| Property | Value |
|----------|-------|
| Filegroup | DICTIONARY |

---

## 8. Sample Queries

```sql
-- Get all time zones
SELECT  TimeZoneID,
        RTRIM(Name) AS Name,
        [Offset]
FROM    Dictionary.TimeZone WITH (NOLOCK)
ORDER BY [Offset];

-- Count customers by timezone
SELECT  RTRIM(tz.Name) AS TimeZone,
        COUNT(*) AS CustomerCount
FROM    Customer.CustomerStatic cs WITH (NOLOCK)
JOIN    Dictionary.TimeZone tz WITH (NOLOCK)
        ON cs.TimeZoneID = tz.TimeZoneID
GROUP BY tz.Name
ORDER BY CustomerCount DESC;

-- Find customers in Israel timezone
SELECT  cs.CID
FROM    Customer.CustomerStatic cs WITH (NOLOCK)
WHERE   cs.TimeZoneID = 15;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `Dictionary.TimeZone`.

---

*Generated: 2026-03-14 | Quality: 9.2/10*
*Object: Dictionary.TimeZone | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TimeZone.sql*
