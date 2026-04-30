# Trade.InstrumentToFeeConfig_Backup

> Despite "_Backup" suffix, this is the active temporal base table for instrument fee configuration; system-versioned with History.InstrumentToFeeConfig.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (PK_InstrumentToFeeConfigTemporal) |
| **Partition** | N/A (system versioning) |
| **Indexes** | PK_InstrumentToFeeConfigTemporal (clustered) |

---

## 1. Business Meaning

Trade.InstrumentToFeeConfig_Backup has a "_Backup" suffix but is the active base table for instrument fee configuration. It holds 11,600 rows with system versioning enabled, pointing to History.InstrumentToFeeConfig for temporal history. The PK name PK_InstrumentToFeeConfigTemporal confirms it is the temporal implementation.

The view Trade.InstrumentToFeeConfig projects from InstrumentToFeeConfigV2 for backward compatibility, but this physical table remains the temporal definition in SSDT. It maps instruments to overnight and weekend fee rates across eight combinations: NonLeveraged/Leveraged * Buy/Sell * OverNight/EndOfWeek, plus NonLeveragedBuyCFDOverNightFee.

Sample data shows InstrumentID=1 with fee rates like NonLeveragedBuyOverNightFee=0.00011842, updated by "adamco" with BeginTime 2025-10-27. Despite the naming, this table is in active use and should not be treated as a discardable backup.

---

## 2. Business Logic

- System versioning: Row changes are recorded in History.InstrumentToFeeConfig. Queries can use FOR SYSTEM_TIME to access historical fee rates.
- Fee structure: Each instrument has separate rates for leveraged vs non-leveraged, buy vs sell, overnight vs end-of-week, plus CFD overnight.
- Occurred and UpdatedByUser track when and who changed the row; BeginTime/EndTime are system-generated for temporal queries.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count (live) | 11,600 |
| History table | History.InstrumentToFeeConfig |
| Sample | InstrumentID=1, NonLeveragedBuyOverNightFee=0.00011842, UpdatedByUser=adamco, BeginTime 2025-10-27 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | High | PK; FK to Trade.Instrument |
| 2 | NonLeveragedSellEndOfWeekFee | decimal(16,8) | NOT NULL | - | High | Non-leveraged sell end-of-week fee rate |
| 3 | NonLeveragedBuyEndOfWeekFee | decimal(16,8) | NOT NULL | - | High | Non-leveraged buy end-of-week fee rate |
| 4 | NonLeveragedBuyOverNightFee | decimal(16,8) | NOT NULL | - | High | Non-leveraged buy overnight fee rate |
| 5 | NonLeveragedSellOverNightFee | decimal(16,8) | NOT NULL | - | High | Non-leveraged sell overnight fee rate |
| 6 | LeveragedSellEndOfWeekFee | decimal(16,8) | NOT NULL | - | High | Leveraged sell end-of-week fee rate |
| 7 | LeveragedBuyEndOfWeekFee | decimal(16,8) | NOT NULL | - | High | Leveraged buy end-of-week fee rate |
| 8 | LeveragedBuyOverNightFee | decimal(16,8) | NOT NULL | - | High | Leveraged buy overnight fee rate |
| 9 | LeveragedSellOverNightFee | decimal(16,8) | NOT NULL | - | High | Leveraged sell overnight fee rate |
| 10 | Occurred | datetime | NOT NULL | - | High | When the row was last updated |
| 11 | UpdatedByUser | varchar(50) | NULL | - | High | User who made the change |
| 12 | BeginTime | datetime2(7) | NOT NULL | GENERATED | High | System-versioning row start |
| 13 | EndTime | datetime2(7) | NOT NULL | GENERATED | High | System-versioning row end |
| 14 | NonLeveragedBuyCFDOverNightFee | decimal(16,8) | NOT NULL | 0 | High | CFD overnight fee for non-leveraged buy |

---

## 5. Relationships

### 5.1 References To
- Trade.Instrument (InstrumentID) - instrument receiving fee configuration

### 5.2 Referenced By
- History.InstrumentToFeeConfig (temporal history)
- View Trade.InstrumentToFeeConfig (or InstrumentToFeeConfigV2) likely references this or related table

---

## 6. Dependencies

### 6.1 Objects This Depends On
- Trade.Instrument

### 6.2 Objects That Depend On This
- History.InstrumentToFeeConfig (system versioning)
- Fee calculation logic across dividend, position, and margin processes

---

## 7. Technical Details

### 7.1 Indexes
- PK_InstrumentToFeeConfigTemporal (clustered) on InstrumentID

### 7.2 Constraints
- PK_InstrumentToFeeConfigTemporal PRIMARY KEY CLUSTERED (InstrumentID)
- PERIOD FOR SYSTEM_TIME (BeginTime, EndTime)
- SYSTEM_VERSIONING = ON (HISTORY_TABLE = History.InstrumentToFeeConfig)
- NonLeveragedBuyCFDOverNightFee DEFAULT 0

---

*Generated: 2026-03-14 | Quality: 8.5/10*
*Object: Trade.InstrumentToFeeConfig_Backup | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentToFeeConfig_Backup.sql*
