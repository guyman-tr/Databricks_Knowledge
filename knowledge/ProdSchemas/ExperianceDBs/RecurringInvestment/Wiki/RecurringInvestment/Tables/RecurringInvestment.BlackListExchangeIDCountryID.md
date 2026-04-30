# RecurringInvestment.BlackListExchangeIDCountryID

> Blacklist table restricting recurring investment plans for specific exchange + country combinations.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Table |
| **Key Identifier** | ExchangeID + CountryID (NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table maintains a blacklist of exchange + country combinations that are restricted from recurring investment plans. When an instrument trades on a specific exchange and the user is from a specific country, this blacklist can block the recurring investment plan creation.

Without this table, the system could not enforce exchange-level restrictions per country - for example, blocking recurring investments in instruments from a specific exchange for users in certain jurisdictions due to regulatory requirements.

System-versioned with history in History.RecurringInvestmentBlackListExchangeIDCountryID. Currently empty (0 rows), suggesting this restriction is not actively used but the infrastructure exists for future regulatory needs.

---

## 2. Business Logic

No complex multi-column business logic beyond the composite key restriction.

---

## 3. Data Overview

Table is currently empty (0 rows). The infrastructure exists but no exchange+country combinations are currently blacklisted.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID | int | NO | - | CODE-BACKED | ID of the exchange/market. References the external instrument/exchange system. Instruments traded on this exchange are blocked for the specified country. |
| 2 | CountryID | int | NO | - | CODE-BACKED | Country ID of the user. Users from this country cannot create recurring investment plans for instruments on the specified exchange. |
| 3 | Trace | computed | NO | - | CODE-BACKED | Computed audit column: JSON with connection details. |
| 4 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. |
| 5 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioned period end. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.BlacklistExchangeIDAndCountryIDGetAll | - | Reader | Reads all entries |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlacklistExchangeIDAndCountryIDGetAll | Stored Procedure | Reads all entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BlackListExchangeIDCountryID | NONCLUSTERED PK | ExchangeID, CountryID | - | - | Active |

### 7.2 Constraints

None.

### 7.3 Temporal

System-versioned with history table `History.RecurringInvestmentBlackListExchangeIDCountryID`.

---

## 8. Sample Queries

### 8.1 List all blacklisted exchange+country combinations
```sql
SELECT ExchangeID, CountryID FROM [RecurringInvestment].[BlackListExchangeIDCountryID] WITH (NOLOCK) ORDER BY ExchangeID, CountryID
```

### 8.2 Check if an exchange+country combo is blacklisted
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM [RecurringInvestment].[BlackListExchangeIDCountryID] WITH (NOLOCK) WHERE ExchangeID = @ExchangeID AND CountryID = @CountryID) THEN 1 ELSE 0 END AS IsBlacklisted
```

### 8.3 View blacklist history
```sql
SELECT ExchangeID, CountryID, ValidFrom, ValidTo FROM [RecurringInvestment].[BlackListExchangeIDCountryID] FOR SYSTEM_TIME ALL ORDER BY ExchangeID, CountryID, ValidFrom
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklists are used for eligibility configuration |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlackListExchangeIDCountryID | Type: Table | Source: RecurringInvestment/RecurringInvestment/Tables/RecurringInvestment.BlackListExchangeIDCountryID.sql*
