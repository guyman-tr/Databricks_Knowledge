# Wallet.HostingCompanies

> Reference list of known cryptocurrency exchanges and hosting platforms (VASPs) used for Travel Rule compliance to identify counterparty custodians during address whitelisting.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table stores a comprehensive catalog of cryptocurrency exchanges, wallets, and other Virtual Asset Service Providers (VASPs) that host customer crypto assets. When a user whitelists an external address for sending crypto, they must declare whether the address is self-hosted (private wallet) or hosted by a VASP - and if hosted, which company. This table provides the dropdown/selection list of known hosting companies.

The table is critical for Travel Rule compliance. International regulations require VASPs to collect and share beneficiary information for crypto transfers above certain thresholds. When a user declares their destination address is hosted by "Binance" or "Coinbase", this triggers different compliance flows than a self-hosted wallet. Without this table, users could not specify which VASP hosts their external addresses.

Data is manually curated and inserted by the compliance/operations team. All 235 entries were created on the same date (2022-07-24), indicating a bulk initial load. The `OrderIndex` column controls the display order in the UI, with eToro entities (eToroX, eToro) appearing first. Referenced by `Wallet.GetHostingCompanies` procedure for API/UI listing.

---

## 2. Business Logic

### 2.1 Display Ordering

**What**: Hosting companies are displayed in a prioritized order, with eToro entities first.

**Columns/Parameters Involved**: `OrderIndex`, `Name`

**Rules**:
- OrderIndex increments by 100 (100, 200, 300...) allowing future insertions between existing entries
- eToroX (OrderIndex=100) and eToro (OrderIndex=200) appear first - users sending to another eToro wallet are a common case
- Major exchanges follow (Binance=300, Coinbase=400, etc.)
- Smaller/regional platforms have higher OrderIndex values

---

## 3. Data Overview

| Id | Name | OrderIndex | Meaning |
|---|---|---|---|
| 1 | eToroX | 100 | eToro's own crypto exchange entity - appears first since intra-eToro transfers are the most common hosted scenario |
| 2 | eToro | 200 | eToro's main platform - separate from eToroX for regulatory distinction |
| 3 | Binance | 300 | World's largest crypto exchange by volume - high priority in the list |
| 4 | Coinbase | 400 | Major US-regulated exchange - key for compliance with US customers |
| 25 | BitGo | 2500 | eToro's own custody provider - listed as a hosting company since it technically holds the keys |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | Name | varchar(255) | NO | - | VERIFIED | Display name of the crypto exchange or hosting platform (e.g., "Binance", "Coinbase", "Kraken"). Unique constraint enforced. Names match the commonly known brand names of each VASP. Used in UI dropdowns and compliance reports. |
| 3 | OrderIndex | int | NO | - | CODE-BACKED | Controls display order in the UI selection list. Increments by 100 to allow future insertions. Lower values appear first. eToro entities have the lowest values (100, 200). |
| 4 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this hosting company was added to the registry. All initial entries share the same date (2022-07-24) from the bulk seed load. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetHostingCompanies | - | Reader | Reads all hosting companies for API/UI dropdown listing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetHostingCompanies | Stored Procedure | Reads all entries for UI listing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HostingCompanies | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_HostingCompanies__Name | NC UNIQUE | Name ASC | - | - | Active |
| IX_Wallet_HostingCompanies__OrderIndex | NC | OrderIndex ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (Created) | DEFAULT | getutcdate() - auto-sets creation timestamp |

---

## 8. Sample Queries

### 8.1 List hosting companies in display order
```sql
SELECT Id, Name, OrderIndex
FROM Wallet.HostingCompanies WITH (NOLOCK)
ORDER BY OrderIndex
```

### 8.2 Search for a specific hosting company
```sql
SELECT Id, Name
FROM Wallet.HostingCompanies WITH (NOLOCK)
WHERE Name LIKE '%Binance%'
```

### 8.3 Count total hosting companies in the registry
```sql
SELECT COUNT(*) AS TotalHostingCompanies
FROM Wallet.HostingCompanies WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.HostingCompanies | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.HostingCompanies.sql*
