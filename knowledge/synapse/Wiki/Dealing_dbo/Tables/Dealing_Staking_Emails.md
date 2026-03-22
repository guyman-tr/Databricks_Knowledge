# Dealing_dbo.Dealing_Staking_Emails

> Monthly crypto staking reward email data — per-customer staking units, yield percentages, and rewards for each supported crypto, segmented for email notifications.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived (staking daily pool calculations) |
| **Refresh** | Monthly |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on StakingMonthID |

---

## 1. Business Meaning

This table contains monthly staking reward summaries per customer, prepared for email distribution. Each row represents one customer's staking performance for a calendar month, with separate columns for each supported cryptocurrency (Tron, Cardano, Solana, Ethereum, NearProtocol, Polygon).

For each crypto, four metrics are stored:
- **Units**: Average daily staked units during the month
- **MPercentage**: Monthly yield percentage (annualized APR / 12)
- **CPercentage**: Club tier percentage multiplier (higher tiers get more of the yield)
- **Reward**: Calculated reward in crypto units

Customers are segmented by `Mailing_Group` (e.g., "AirDropClubs") and include metadata for email personalization (Country, Language, ClubTier).

Loaded monthly by `SP_Staking_Emails` (non-US) and `SP_Staking_Emails_US` (US customers).

---

## 2. Business Logic

### 2.1 Multi-Crypto Column Pattern

**What**: Each crypto has 4 identically structured columns.

**Pattern**: `{Crypto}Units`, `{Crypto}MPercentage`, `{Crypto}CPercentage`, `{Crypto}Reward`

**Supported Cryptos**: Tron (TRX), Cardano (ADA), Solana (SOL), Ethereum (ETH), NearProtocol (NEAR), Polygon (POL)

**Rules**:
- NULL columns mean the customer had no staking position in that crypto during the month
- Reward = Units × MPercentage × CPercentage (approximately)
- CPercentage varies by ClubTier (e.g., 0.65 for Gold, 0.75 for Platinum)

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| This month's staking emails | `WHERE StakingMonthID = YYYYMM` |
| Total rewards by crypto | `SELECT SUM(TronReward), SUM(CardanoReward), ... WHERE StakingMonthID = @month` |
| Reward by club tier | `GROUP BY ClubTier WHERE StakingMonthID = @month` |

### 3.2 Gotchas

- **Wide table**: 33 columns. Most crypto columns will be NULL for any given customer (not all customers stake all cryptos).
- **Monthly granularity**: One row per customer per month. StakingMonthID is YYYYMM (e.g., 202502).
- **Not all cryptos populated**: A customer staking only ETH will have NULL for all Tron/Cardano/Solana/etc. columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | StakingMonthID | int | YES | Month identifier in YYYYMM format (e.g., 202502). Primary filter key. (Tier 2 — SP_Staking_Emails) |
| 2 | StakingYear | int | YES | Calendar year of the staking period. (Tier 2 — SP_Staking_Emails) |
| 3 | Country | varchar(100) | YES | Customer's country name. From Dim_Country. (Tier 2 — SP_Staking_Emails) |
| 4 | StakingMonth | varchar(100) | YES | Month name (e.g., "February"). For email display. (Tier 2 — SP_Staking_Emails) |
| 5 | GCID | int | YES | Global Customer ID. Unique customer identifier across all platforms. (Tier 2 — SP_Staking_Emails) |
| 6 | Language | varchar(100) | YES | Customer's preferred language for email localization. (Tier 2 — SP_Staking_Emails) |
| 7 | TronUnits | decimal(38,0) | YES | Average daily TRX units staked during the month. (Tier 2 — SP_Staking_Emails) |
| 8 | TronMPercentage | decimal(38,4) | YES | TRX monthly yield percentage. (Tier 2 — SP_Staking_Emails) |
| 9 | TronCPercentage | decimal(38,2) | YES | TRX club tier percentage multiplier. (Tier 2 — SP_Staking_Emails) |
| 10 | TronReward | decimal(38,4) | YES | TRX reward in crypto units. (Tier 2 — SP_Staking_Emails) |
| 11 | CardanoUnits | decimal(38,0) | YES | Average daily ADA units staked. (Tier 2 — SP_Staking_Emails) |
| 12 | CardanoMPercentage | decimal(38,4) | YES | ADA monthly yield percentage. (Tier 2 — SP_Staking_Emails) |
| 13 | CardanoCPercentage | decimal(38,2) | YES | ADA club tier percentage. (Tier 2 — SP_Staking_Emails) |
| 14 | CardanoReward | decimal(38,4) | YES | ADA reward in crypto units. (Tier 2 — SP_Staking_Emails) |
| 15 | ClubTier | varchar(100) | YES | Customer's club tier at time of staking (Bronze, Silver, Gold, Platinum, Diamond, Platinum+). Determines CPercentage. (Tier 2 — SP_Staking_Emails) |
| 16 | Mailing_Group | varchar(100) | YES | Email campaign segment. E.g., "AirDropClubs". (Tier 2 — SP_Staking_Emails) |
| 17 | UpdateDate | datetime | YES | ETL load timestamp. (Tier 2 — SP_Staking_Emails) |
| 18 | SolanaUnits | decimal(38,0) | YES | Average daily SOL units staked. (Tier 2 — SP_Staking_Emails) |
| 19 | SolanaMPercentage | decimal(38,4) | YES | SOL monthly yield percentage. (Tier 2 — SP_Staking_Emails) |
| 20 | SolanaCPercentage | decimal(38,2) | YES | SOL club tier percentage. (Tier 2 — SP_Staking_Emails) |
| 21 | SolanaReward | decimal(38,4) | YES | SOL reward in crypto units. (Tier 2 — SP_Staking_Emails) |
| 22 | EthereumUnits | decimal(38,0) | YES | Average daily ETH units staked. (Tier 2 — SP_Staking_Emails) |
| 23 | EthereumMPercentage | decimal(38,4) | YES | ETH monthly yield percentage. (Tier 2 — SP_Staking_Emails) |
| 24 | EthereumCPercentage | decimal(38,2) | YES | ETH club tier percentage. (Tier 2 — SP_Staking_Emails) |
| 25 | EthereumReward | decimal(38,4) | YES | ETH reward in crypto units. (Tier 2 — SP_Staking_Emails) |
| 26 | NearProtocolUnits | decimal(38,0) | YES | Average daily NEAR units staked. (Tier 2 — SP_Staking_Emails) |
| 27 | NearProtocolMPercentage | decimal(38,4) | YES | NEAR monthly yield percentage. (Tier 2 — SP_Staking_Emails) |
| 28 | NearProtocolCPercentage | decimal(38,2) | YES | NEAR club tier percentage. (Tier 2 — SP_Staking_Emails) |
| 29 | NearProtocolReward | decimal(38,4) | YES | NEAR reward in crypto units. (Tier 2 — SP_Staking_Emails) |
| 30 | PolygonUnits | decimal(38,0) | YES | Average daily POL units staked. (Tier 2 — SP_Staking_Emails) |
| 31 | PolygonMPercentage | decimal(38,4) | YES | POL monthly yield percentage. (Tier 2 — SP_Staking_Emails) |
| 32 | PolygonCPercentage | decimal(38,2) | YES | POL club tier percentage. (Tier 2 — SP_Staking_Emails) |
| 33 | PolygonReward | decimal(38,4) | YES | POL reward in crypto units. (Tier 2 — SP_Staking_Emails) |

---

## 5. Lineage

### 5.1 ETL Pipeline

```
Dealing_Staking_DailyPool → SP_Staking_Emails → Dealing_Staking_Emails
                              SP_Staking_Emails_US → (same table, US customers)
```

---

*Generated: 2026-03-21 | Quality: 6.8/10 (★★★☆☆) | Phases: 6/14*
*Tiers: 0 T1, 33 T2, 0 T3, 0 T4, 0 T5 | Elements: 9/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10*
*Object: Dealing_dbo.Dealing_Staking_Emails | Type: Table | Production Source: Derived*
