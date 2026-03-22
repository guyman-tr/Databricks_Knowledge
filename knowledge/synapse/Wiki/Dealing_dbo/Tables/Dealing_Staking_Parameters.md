# Dealing_dbo.Dealing_Staking_Parameters

> Staking program configuration per cryptocurrency — intro periods, liquidity buffers, and start dates for daily pool, welcome emails, and reward distribution.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (reference/config) |
| **Production Source** | Manual configuration |
| **Refresh** | Manual (updated when new cryptos are added to staking) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on InstrumentID |

---

## 1. Business Meaning

This reference table configures the staking program for each supported cryptocurrency. It defines operational parameters:
- **IntroDays**: Days a customer must hold before staking yields begin (7 for most, 9 for ADA, 60 for ETH)
- **LiquidityBuffer**: Fraction of staked assets reserved for liquidity (0.60-1.00)
- **Start dates**: When each phase (daily pool calculation, welcome email, reward distribution) begins for each crypto

Contains 13 instruments including USD and EUR pairs (ETH, ETHEUR, ADA, ADAEUR, TRX, SOL, SOLEUR, POL, DOT, NEAR, ATOM, AVAX, SUI).

Referenced by all Staking SPs (`SP_Staking`, `SP_Staking_US`, `SP_Staking_DailyPool`, `SP_Staking_DailyPool_US`, `SP_Staking_Emails`, `SP_Staking_WelcomeEmail`).

---

## 2. Business Logic

### 2.1 IntroDays Significance

**What**: Waiting period before staking yields start.

**Rules**:
- ETH/ETHEUR: 60 days (Ethereum's proof-of-stake requires bonding period)
- ADA/ADAEUR: 9 days (Cardano epoch boundary)
- All others: 7 days (standard)

### 2.2 LiquidityBuffer

**What**: Percentage of total staked pool reserved for withdrawal liquidity.

**Rules**:
- 1.0 (100%) = Full pool reserved (ETH/ETHEUR — high-value, long lock)
- 0.85-0.90 = Standard buffer
- 0.60 = Minimal buffer (DOT)

---

## 3. Query Advisory

### 3.1 Gotchas

- **Only 13 rows**: Small reference table.
- **EUR pairs are separate**: ETH and ETHEUR are separate entries with same IntroDays but different start dates.
- **100xxx InstrumentIDs**: Staking instruments use the 100xxx range, not the standard InstrumentID range.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | YES | Crypto instrument identifier (100xxx range). E.g., 100001=ETH, 100017=ADA, 100026=TRX, 100063=SOL. (Tier 3 — live data) |
| 2 | Currency | varchar(50) | YES | Crypto symbol. E.g., ETH, ADA, TRX, SOL, DOT, NEAR, ATOM, AVAX, SUI, POL, ETHEUR, SOLEUR, ADAEUR. (Tier 3 — live data) |
| 3 | IntroDays | int | YES | Days before staking yields begin for new positions. 7 (standard), 9 (ADA), 60 (ETH). (Tier 3 — live data) |
| 4 | LiquidityBuffer | decimal(12,4) | YES | Fraction of staked pool reserved for liquidity. 0.60-1.00. Higher = more reserved, lower yield for stakers. (Tier 3 — live data) |
| 5 | DailyPool_StartDate | date | YES | Date when daily pool calculation begins for this crypto. (Tier 3 — live data) |
| 6 | WelcomeEmail_StartDate | date | YES | Date when welcome staking emails start being sent for this crypto. (Tier 3 — live data) |
| 7 | Distribution_StartDate | date | YES | Date when reward distribution begins. Always >= DailyPool_StartDate (pool must accumulate before distribution). (Tier 3 — live data) |
| 8 | UpdateDate | datetime | YES | Last configuration update timestamp. (Tier 3 — live data) |

---

## 5. Relationships

### 5.1 Referenced By

| Source Object | Description |
|--------------|-------------|
| SP_Staking | Main staking calculation SP |
| SP_Staking_US | US-specific staking calculation |
| SP_Staking_DailyPool | Daily pool aggregation |
| SP_Staking_DailyPool_US | US daily pool aggregation |
| SP_Staking_Emails | Monthly email data generation |
| SP_Staking_WelcomeEmail | Welcome email trigger |

---

*Generated: 2026-03-21 | Quality: 6.5/10 (★★★☆☆) | Phases: 5/14*
*Tiers: 0 T1, 0 T2, 8 T3, 0 T4, 0 T5 | Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10*
*Object: Dealing_dbo.Dealing_Staking_Parameters | Type: Table (reference)*
