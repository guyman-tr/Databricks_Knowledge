# Trade.InstrumentToFeeConfigOld

> Pre-temporal archive of instrument fee configuration; data frozen July 2021 when replaced by temporal version.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (PK_TradeInstrumentToFeeConfig) |
| **Partition** | N/A |
| **Indexes** | PK_TradeInstrumentToFeeConfig (clustered) |

---

## 1. Business Meaning

Trade.InstrumentToFeeConfigOld is the pre-temporal version of instrument fee configuration. It has nine columns (eight fee rates plus Occurred) and no system versioning, UpdatedByUser, or NonLeveragedBuyCFDOverNightFee. The PK constraint name PK_TradeInstrumentToFeeConfig matches the original table name before it was renamed to "Old" and replaced by the temporal version.

Data is frozen at July 2021 based on Occurred dates. Sample: InstrumentID=9017 with zero fees, Occurred 2021-07-18. The table was renamed to "Old" when the temporal table (Trade.InstrumentToFeeConfig_Backup or InstrumentToFeeConfigV2) became the active source. It serves as a historical archive of fee rates before the temporal migration and as a reference for auditing or rollback.

The live database contains 4,113 rows. No procedures write to it; it is read-only from a logical standpoint.

---

## 2. Business Logic

None. Archive table. Fee calculation logic now uses the temporal table. Historical queries may reference this for pre-July-2021 fee rates if not yet fully migrated to temporal history.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count (live) | 4,113 |
| Data frozen | July 2021 (based on Occurred) |
| Sample | InstrumentID=9017, zero fees, Occurred 2021-07-18 |
| Purpose | Pre-temporal fee config archive |

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
| 10 | Occurred | datetime | NOT NULL | getutcdate() | High | When the row was last updated |

---

## 5. Relationships

### 5.1 References To
- Trade.Instrument (InstrumentID) - instrument whose fee config was captured

### 5.2 Referenced By
Possibly historical reports or migration scripts; no active production procedures expected to reference it. Verify in codebase before removal.

---

## 6. Dependencies

### 6.1 Objects This Depends On
- Trade.Instrument

### 6.2 Objects That Depend On This
Unknown; likely none for active processing. May be referenced by ad-hoc queries or legacy reports.

---

## 7. Technical Details

### 7.1 Indexes
- PK_TradeInstrumentToFeeConfig (clustered) on InstrumentID

### 7.2 Constraints
- PK_TradeInstrumentToFeeConfig PRIMARY KEY CLUSTERED (InstrumentID)
- Occurred DEFAULT getutcdate()

---

*Generated: 2026-03-14 | Quality: 8.0/10*
*Object: Trade.InstrumentToFeeConfigOld | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentToFeeConfigOld.sql*
