# Billing.MonthlyQuoteAdd

> Idempotent initialization procedure that calculates and inserts monthly deposit volume snapshots for WireCard (18), WorldPay (23), and Adyen (31) protocols into Billing.MonthlyQuota - legacy protocols no longer active in 2026.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CurrentYear INT, @CurrentMonth INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.MonthlyQuoteAdd initializes the Billing.MonthlyQuota tracking rows for a given year/month combination. It is idempotent: it only inserts a row if one does not already exist for the target (ProtocolID, Year, Month). The amount inserted is calculated from actual approved deposits (PaymentStatusID=2) for that period.

This procedure was created on 19/06/2018 by Ran Ovadia (FogBugz ticket FG:51351, parent of FG:51380) as part of the credit card routing volume tracking infrastructure. It initializes quota rows for three protocols:
- ProtocolID=18 (WireCard) - DepotID=18 in Billing.Deposit
- ProtocolID=23 (WorldPay) - DepotIDs 35-44 in Billing.Deposit
- ProtocolID=31 (Adyen) - DepotIDs 63-68 in Billing.Deposit

**IMPORTANT**: These three protocols are legacy. WireCard ceased operations in June 2020. The active credit card protocols in Billing.MonthlyQuota as of 2026 are ProtocolID=23 (WorldPay), 43 (Checkout), and 46 (IxopayNuvei). The procedure still correctly initializes WorldPay (23) but does nothing meaningful for WireCard (18) and Adyen (31) which have no recent deposit activity. The active updates for Checkout (43) and IxopayNuvei (46) are handled by Billing.UpdateMonthlyProcessingQuota, not this initialization procedure.

---

## 2. Business Logic

### 2.1 Idempotent Quota Initialization

**What**: For each of three protocols, inserts a MonthlyQuota row only if one doesn't already exist for the given year/month.

**Columns/Parameters Involved**: `@CurrentYear`, `@CurrentMonth`

**Rules**:
- Three IF-EXISTS guards, one per protocol. Each follows the same pattern:
  1. Check: `IF ((SELECT COUNT(*) FROM Billing.MonthlyQuota WHERE ProtocolID = {N} AND Year = @CurrentYear AND Month = @CurrentMonth) = 0)`
  2. Calculate: `SUM(Amount * ExchangeRate) FROM Billing.Deposit WITH(NOLOCK) WHERE PaymentStatusID = 2 AND DepotID IN (...) AND YEAR(PaymentDate) = @CurrentYear AND MONTH(PaymentDate) = @CurrentMonth`
  3. Insert: `INSERT INTO Billing.MonthlyQuota (ProtocolID, Year, Month, Amount, TimeStamp) VALUES ({N}, @CurrentYear, @CurrentMonth, @CalculatedAmount, GetUTCDate())`
- COALESCE(..., 0): if no approved deposits exist for the period, inserts Amount=0 (not NULL).
- Amount calculation: Billing.Deposit.Amount (in USD dollars) * ExchangeRate = USD-normalized value. The ExchangeRate converts deposits made in non-USD currencies to USD.
- PaymentStatusID=2 = Approved deposits only (not pending, declined, or refunded).
- The procedure is idempotent: calling it multiple times for the same year/month is safe - only the first call inserts; subsequent calls find the row and skip.
- No TRY/CATCH. No RETURN value.

### 2.2 Protocol-to-DepotID Mapping

**What**: Maps the three legacy protocols to their DepotIDs in Billing.Deposit.

**Columns/Parameters Involved**: `DepotID` in Billing.Deposit

**Rules**:
- ProtocolID=18 (WireCard): DepotID = 18 only.
- ProtocolID=23 (WorldPay): DepotID IN (35, 36, 37, 38, 39, 40, 41, 42, 43, 44) - 10 terminals covering different WorldPay configurations (currencies, regions).
- ProtocolID=31 (Adyen): DepotID IN (63, 64, 65, 66, 67, 68) - 6 terminals covering Adyen configurations.
- WireCard (18) was discontinued in 2020. Its DepotID=18 may still receive historical queries but no live deposits.
- Adyen (ProtocolID=31) appears deprecated in favor of IxopayNuvei (46). The DepotIDs 63-68 are Adyen-era terminals.

**Diagram**:
```
Billing.MonthlyQuoteAdd(@CurrentYear=2026, @CurrentMonth=3)
    |
    +-- ProtocolID=18 (WireCard):
    |       IF no row exists for (18, 2026, 3)
    |           Calculate: SUM(Amount*ExchangeRate) FROM Billing.Deposit WHERE StatusID=2 AND DepotID=18 AND Year=2026 AND Month=3
    |           Insert: MonthlyQuota(18, 2026, 3, @WireCardProcessedQuote, GETUTCDATE())
    |           -> WireCard inactive since 2020: inserts Amount=0
    |
    +-- ProtocolID=23 (WorldPay):
    |       IF no row exists for (23, 2026, 3)
    |           Calculate: SUM(Amount*ExchangeRate) ... DepotID IN (35..44) AND Year=2026 AND Month=3
    |           Insert: MonthlyQuota(23, 2026, 3, @WordPayProcessedQuote, GETUTCDATE())
    |           -> Inserts ~$13.8M (actual March 2026 WorldPay volume to date)
    |
    +-- ProtocolID=31 (Adyen):
            IF no row exists for (31, 2026, 3)
                Calculate: SUM(Amount*ExchangeRate) ... DepotID IN (63..68) AND Year=2026 AND Month=3
                Insert: MonthlyQuota(31, 2026, 3, @AdyenCardProcessedQuote, GETUTCDATE())
                -> Adyen deprecated: likely inserts Amount=0 or near-zero
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CurrentYear | INT | NO | - | CODE-BACKED | Calendar year to initialize quota rows for (e.g., 2026). Combined with @CurrentMonth to define the target period. Typically called with the current year/month at the start of each month. |
| 2 | @CurrentMonth | INT | NO | - | CODE-BACKED | Calendar month number (1-12) to initialize quota rows for. Combined with @CurrentYear to define the target period. The procedure only inserts rows for months that have no existing quota entries. |
| RETURN | (void) | - | - | CODE-BACKED | No explicit RETURN. Void on success. Inserts 0-3 rows depending on which protocols already have quota rows for the target period. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT (EXISTS check) | Billing.MonthlyQuota | READ | Checks if quota rows already exist for the target period+protocol. |
| INSERT | Billing.MonthlyQuota | WRITE | Creates initialization rows with calculated deposit volumes. |
| SELECT (SUM) | Billing.Deposit | READ | Calculates the actual approved deposit volume for the target period per protocol. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing scheduler / monthly job | @CurrentYear, @CurrentMonth | EXEC | Called at the start of each month to initialize quota tracking rows for the new period. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.MonthlyQuoteAdd (procedure)
├── Billing.MonthlyQuota (table) - EXISTS check + INSERT target
└── Billing.Deposit (table) - SUM(Amount*ExchangeRate) source
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.MonthlyQuota | Table | READ (exists check) + INSERT (quota initialization). |
| Billing.Deposit | Table | READ - SUM(Amount*ExchangeRate) of approved deposits for the period. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing scheduler / monthly job | Application | EXEC - initializes monthly quota rows at period start. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Initialize quota rows for March 2026
```sql
EXEC Billing.MonthlyQuoteAdd
    @CurrentYear  = 2026,
    @CurrentMonth = 3;
-- Inserts rows for ProtocolID 18, 23, 31 if they don't exist
-- WireCard (18) and Adyen (31) will insert Amount=0 (inactive protocols)
```

### 8.2 Check which quota rows exist before calling
```sql
SELECT ProtocolID, Year, Month, Amount, TimeStamp
FROM Billing.MonthlyQuota WITH (NOLOCK)
WHERE Year = 2026 AND Month = 3
  AND ProtocolID IN (18, 23, 31)
ORDER BY ProtocolID;
-- If any rows returned, procedure will skip those protocols
```

### 8.3 Verify the initialized amounts match Billing.Deposit
```sql
-- WorldPay (DepotIDs 35-44) approved deposits for March 2026
SELECT SUM(Amount * ExchangeRate) AS WorldPayApprovedUSD
FROM Billing.Deposit WITH (NOLOCK)
WHERE PaymentStatusID = 2
  AND DepotID IN (35, 36, 37, 38, 39, 40, 41, 42, 43, 44)
  AND YEAR(PaymentDate) = 2026
  AND MONTH(PaymentDate) = 3;
-- Should match the Amount in Billing.MonthlyQuota for ProtocolID=23, 2026, March
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.MonthlyQuoteAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.MonthlyQuoteAdd.sql*
