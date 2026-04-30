# Trade.PositionAirdropTbl

> A table-valued parameter type for bulk airdrop operations - passing customer, instrument, amount, and hedge metadata to add airdrop credits to positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID, InstrumentID, HedgeServerID, TerminalID (no PK) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.PositionAirdropTbl is a TVP type for passing batches of airdrop records to Trade.PositionAirdropAdd. An airdrop is a credit or allocation applied to a customer's position - e.g., token airdrops for crypto, stock dividends, or promotional credits. Each row contains the customer, instrument, amount in dollars and units, hedge server context, rate, and terminal ID.

This type exists to support bulk airdrop processing. Back-office or automated jobs collect airdrop data (from exchanges, custodians, or internal systems), populate this TVP, and pass it to PositionAirdropAdd. The procedure processes each row to credit positions and update balances.

The application or ETL layer builds the TVP and passes it as a READONLY parameter to Trade.PositionAirdropAdd.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. CID+InstrumentID+HedgeServerID+TerminalID form a logical key for airdrop application.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - account receiving the airdrop. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument (asset) for the airdrop. |
| 3 | Cusip | varchar(100) | YES | - | CODE-BACKED | CUSIP identifier for US securities airdrops. |
| 4 | ApexID | varchar(100) | YES | - | CODE-BACKED | Apex custodian identifier. |
| 5 | Amount | money | YES | - | CODE-BACKED | Airdrop amount in dollars. |
| 6 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Airdrop amount in units (shares/tokens). |
| 7 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server where the position is held. |
| 8 | Rate | dbo.dtPrice | YES | - | CODE-BACKED | Price/rate for the airdrop (uses dtPrice scalar type). |
| 9 | TerminalID | varchar(100) | NO | - | CODE-BACKED | Terminal or system identifier for the airdrop source. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CID, InstrumentID, HedgeServerID semantically reference Customer, Instrument, and hedge entities.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionAirdropAdd | @positionAirdropTbl | Parameter (TVP) | Adds airdrop credits to positions for each row |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

Depends on dbo.dtPrice (scalar type alias for decimal pricing).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionAirdropAdd | Stored Procedure | READONLY parameter for bulk airdrop processing |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for airdrop

```sql
DECLARE @Airdrops Trade.PositionAirdropTbl;
INSERT INTO @Airdrops (CID, InstrumentID, Amount, AmountInUnits, HedgeServerID, Rate, TerminalID)
VALUES (12345, 100, 50.00, 0.5, 1, 100.00, 'CRYPTO-AIRDROP-001');

EXEC Trade.PositionAirdropAdd @positionAirdropTbl = @Airdrops, @userName = 'BackOffice';
```

### 8.2 Bulk airdrop from exchange data

```sql
DECLARE @Airdrops Trade.PositionAirdropTbl;
INSERT INTO @Airdrops (CID, InstrumentID, Cusip, ApexID, Amount, AmountInUnits, HedgeServerID, Rate, TerminalID)
SELECT  CID, InstrumentID, Cusip, ApexID, Amount, AmountInUnits, HedgeServerID, Rate, @TerminalID
FROM    #StagingAirdrops;

EXEC Trade.PositionAirdropAdd @positionAirdropTbl = @Airdrops, @userName = @UserName;
```

### 8.3 Inspect structure

```sql
SELECT c.name, t.name AS type_name
FROM   sys.table_types tt
       JOIN sys.columns c ON c.object_id = tt.type_table_object_id
       JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE  tt.name = 'PositionAirdropTbl';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PositionAirdropTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.PositionAirdropTbl.sql*
