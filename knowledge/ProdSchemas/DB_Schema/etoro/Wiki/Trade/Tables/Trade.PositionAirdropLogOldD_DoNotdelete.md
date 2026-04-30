# Trade.PositionAirdropLogOldD_DoNotdelete

> Archived copy of the position airdrop log table, marked for permanent retention. Stores historical records of crypto token airdrop attempts to position holders, including DTC settlement IDs and success/failure status.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | AirdropID (int IDENTITY, PK) |
| **Partition** | No |
| **Indexes** | 5 (PK + IX_ApexID, IX_CID, IX_Cusip, IX_RequestOccurred) |

---

## 1. Business Meaning

**WHAT**: Trade.PositionAirdropLogOldD_DoNotdelete is an archived copy of the live PositionAirdropLog table, explicitly marked for retention via the "_OldD_DoNotdelete" suffix. Airdrops are crypto token distributions to position holders-when a blockchain project distributes tokens (e.g., forks, staking rewards) to holders of a related instrument. Each row logs one airdrop attempt: customer, instrument, hedge server, amounts (dollar and unit), CUSIP/ApexID for DTC settlement, result (success/failure), failure reason, and timestamps.

**WHY**: The "DoNotdelete" in the name indicates this data was archived from the live table but must be kept for regulatory compliance, audit, or legal hold. Deleting this table could violate retention requirements. The live table (PositionAirdropLog) continues to receive new airdrop records; this archive holds historical data that was migrated out of the live table.

**HOW**: Data was likely bulk-copied from PositionAirdropLog during an archival job. The table is empty (0 rows) in the live database, suggesting either the archival is complete and the archive resides elsewhere, or the archive copy has not been populated in this environment. Indexes on CID, Cusip, ApexID, and RequestOccurred support lookups by customer, DTC identifiers, and time.

---

## 2. Business Logic

### 2.1 Airdrop Attempt Lifecycle

**What**: Each row represents one airdrop attempt from request to execution result.

**Columns/Parameters Involved**: RequestOccurred, ExecutionOccurred, Result, FailReason, PositionID

**Rules**:
- RequestOccurred: When the airdrop request was received (default getutcdate()).
- ExecutionOccurred: When the airdrop was executed (NULL until processed).
- Result: 1 = success, 0 = failure (bit).
- FailReason: Human-readable failure reason when Result=0 (varchar(8000)).
- PositionID: The position that received (or was to receive) the airdrop. References Trade.PositionTbl.PositionID.

### 2.2 DTC Settlement Integration

**What**: CUSIP and ApexID support Depository Trust Company (DTC) settlement for US securities and real-asset crypto positions.

**Columns/Parameters Involved**: Cusip, ApexID, TerminalID

**Rules**:
- Cusip: CUSIP identifier for the instrument (US securities standard).
- ApexID: Apex Clearing identifier for brokerage integration.
- TerminalID: May identify the settlement terminal or system.

---

## 3. Data Overview

| AirdropID | CID | InstrumentID | Amount | HedgeServerID | Result | Meaning |
|-----------|-----|--------------|--------|---------------|--------|---------|
| (empty) | - | - | - | - | - | Table has 0 rows in live DB. Archive structure only. |

**Selection criteria**: Table is empty. Structure matches the live PositionAirdropLog; sample data would include CID, InstrumentID, Amount, AmountInUnits, Cusip, ApexID, Result (1/0), FailReason, RequestOccurred, ExecutionOccurred.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AirdropID | int | NO | IDENTITY(1,1) | CODE-BACKED | PK. Surrogate key. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. Implicit FK to Customer.Customer. Indexed. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. Instrument for which airdrop was distributed. |
| 4 | Amount | money | YES | - | CODE-BACKED | Dollar amount of airdrop. |
| 5 | HedgeServerID | int | NO | - | CODE-BACKED | FK to Trade.HedgeServer. Hedge routing for the position. |
| 6 | RequestOccurred | datetime | YES | getutcdate() | CODE-BACKED | When airdrop request arrived. Indexed. |
| 7 | UserName | varchar(100) | YES | - | CODE-BACKED | Operator or system user initiating the airdrop. |
| 8 | ExecutionOccurred | datetime | YES | - | CODE-BACKED | When airdrop was executed. NULL until processed. |
| 9 | PositionID | bigint | YES | - | CODE-BACKED | FK to Trade.PositionTbl. Position that received the airdrop. |
| 10 | Result | bit | YES | - | CODE-BACKED | 1 = success, 0 = failure. |
| 11 | FailReason | varchar(8000) | YES | - | CODE-BACKED | Failure reason when Result=0. |
| 12 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Airdrop amount in units/shares. |
| 13 | Cusip | varchar(100) | YES | - | CODE-BACKED | CUSIP identifier for DTC settlement. Indexed. |
| 14 | ApexID | varchar(100) | YES | - | CODE-BACKED | Apex Clearing ID for brokerage. Indexed. |
| 15 | Rate | money | YES | - | CODE-BACKED | Rate/price used for the airdrop. |
| 16 | TerminalID | varchar(100) | YES | - | CODE-BACKED | Settlement terminal or system identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Customer receiving the airdrop |
| InstrumentID | Trade.Instrument | Implicit | Instrument for the airdrop |
| HedgeServerID | Trade.HedgeServer | Implicit | Hedge server routing |
| PositionID | Trade.PositionTbl | Implicit | Position that received the airdrop |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Archive) | - | - | Archived table; no active writers. Read for audit/compliance. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionAirdropLogOldD_DoNotdelete (table)
├── Trade.Instrument (implicit via InstrumentID)
├── Trade.HedgeServer (implicit via HedgeServerID)
├── Trade.PositionTbl (implicit via PositionID)
└── Customer.Customer (implicit via CID)
```

### 6.1 Objects This Depends On

No explicit FKs. Implicit: Trade.Instrument, Trade.HedgeServer, Trade.PositionTbl, Customer.Customer.

### 6.2 Objects That Depend On This

Archive table. No active procedures depend on it; used for audit/compliance queries only.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PositionAirdropLog | CLUSTERED PK | AirdropID | - | - | Active (FILLFACTOR 80) |
| IX_ApexID | NC | ApexID | - | - | Active |
| IX_CID | NC | CID | - | - | Active |
| IX_Cusip | NC | Cusip | - | - | Active |
| IX_RequestOccurred | NC | RequestOccurred | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PositionAirdropLog | PRIMARY KEY | AirdropID |
| DF (RequestOccurred) | DEFAULT | getutcdate() |

---

## 8. Sample Queries

### 8.1 Airdrops by customer (audit)
```sql
SELECT pa.AirdropID, pa.CID, pa.InstrumentID, pa.Amount, pa.AmountInUnits,
       pa.Result, pa.FailReason, pa.RequestOccurred, pa.ExecutionOccurred
FROM   Trade.PositionAirdropLogOldD_DoNotdelete pa WITH (NOLOCK)
WHERE  pa.CID = @CID
ORDER BY pa.RequestOccurred DESC;
```

### 8.2 Failed airdrops by CUSIP
```sql
SELECT pa.AirdropID, pa.Cusip, pa.CID, pa.FailReason, pa.RequestOccurred
FROM   Trade.PositionAirdropLogOldD_DoNotdelete pa WITH (NOLOCK)
WHERE  pa.Result = 0
       AND pa.Cusip = @Cusip;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.0/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED*
*Object: Trade.PositionAirdropLogOldD_DoNotdelete | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.PositionAirdropLogOldD_DoNotdelete.sql*
