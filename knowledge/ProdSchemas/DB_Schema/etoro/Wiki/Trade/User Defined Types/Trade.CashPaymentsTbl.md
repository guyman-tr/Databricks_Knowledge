# Trade.CashPaymentsTbl

> A table-valued parameter type for passing cash payment details for manual dividend or airdrop payments via terminal ID. Contains customer and instrument identifiers plus amount or units.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | None (multi-column input set) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.CashPaymentsTbl is a table-valued parameter (TVP) type used to pass cash payment details for manual dividend or airdrop credits. When dividends or airdrops are paid manually (rather than via automated feeds), operators use this type to specify which customers receive what amounts for which instruments.

The type supports flexible identification: customer by CID or ApexID (external ID), instrument by InstrumentID or CUSIP. Amounts can be specified as money or as units. The consuming procedure Trade.PayCashTerminalIdByManualData uses these rows to credit customer accounts.

Without this type, each payment would require separate parameters or row-by-row calls. Batching payments into a TVP enables efficient bulk processing of manual payouts.

---

## 2. Business Logic

### 2.1 Customer and Instrument Identification

**What**: Each row identifies a recipient and an asset via flexible lookup fields.

**Columns/Parameters Involved**: `CID`, `ApexID`, `InstrumentID`, `CUSIP`

**Rules**:
- Customer is identified by CID or ApexID (external system ID); at least one should be populated per row.
- Instrument is identified by InstrumentID or CUSIP; at least one should be populated.
- Amount or Units must be provided; Amount is NOT NULL, Units is optional.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID - internal eToro account identifier. Use when customer is known by CID. Can be NULL if ApexID is used instead. |
| 2 | ApexID | varchar(100) | YES | - | CODE-BACKED | External customer identifier from Apex or similar system. Use when customer is identified by external ID. Can be NULL if CID is used. |
| 3 | InstrumentID | int | YES | - | CODE-BACKED | Internal instrument identifier. Use when instrument is known by Trade.InstrumentID. Can be NULL if CUSIP is used. |
| 4 | CUSIP | varchar(255) | YES | - | CODE-BACKED | CUSIP identifier for the instrument. Use for securities when CUSIP is the primary reference. Can be NULL if InstrumentID is used. |
| 5 | Amount | money | NO | - | CODE-BACKED | Payment amount in currency. Required. Used when crediting a fixed monetary amount for the dividend or airdrop. |
| 6 | Units | decimal(16,6) | YES | - | CODE-BACKED | Payment in units (shares/quantity). Optional. Used when crediting a quantity rather than a cash amount. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no declared outgoing references. CID semantically references Customer.CustomerTbl; InstrumentID references instrument catalog; ApexID and CUSIP reference external systems.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PayCashTerminalIdByManualData | Parameter (TVP) | TVP | Receives cash payment rows for manual dividend/airdrop processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PayCashTerminalIdByManualData | Stored Procedure | READONLY TVP parameter for manual cash payment processing |

---

## 7. Technical Details

### 7.1 Indexes

None. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Pass cash payments by CID and InstrumentID

```sql
DECLARE @Payments Trade.CashPaymentsTbl;
INSERT INTO @Payments (CID, InstrumentID, Amount, Units)
VALUES (12345, 100, 150.00, NULL), (12346, 100, 200.00, NULL);
EXEC Trade.PayCashTerminalIdByManualData @Payments = @Payments;
```

### 8.2 Pass payments by ApexID and CUSIP

```sql
DECLARE @Payments Trade.CashPaymentsTbl;
INSERT INTO @Payments (ApexID, CUSIP, Amount)
VALUES ('APX-001', '037833100', 75.50);
EXEC Trade.PayCashTerminalIdByManualData @Payments = @Payments;
```

### 8.3 Mix CID/InstrumentID and units-based payment

```sql
DECLARE @Payments Trade.CashPaymentsTbl;
INSERT INTO @Payments (CID, InstrumentID, Amount, Units)
VALUES (10001, 200, 0, 10.5);
EXEC Trade.PayCashTerminalIdByManualData @Payments = @Payments;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CashPaymentsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.CashPaymentsTbl.sql*
