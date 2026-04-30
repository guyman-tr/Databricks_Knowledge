# History.GetFaultedPIBonusFlow

> Diagnostic query that detects "faulted" Popular Investor (PI) bonus flows: cases where a PI's cashout-linked compensation credit (CompensationReasonID=41) was credited and reversed on the same day, yet the associated withdrawal was still processed on a later date.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; self-contained diagnostic; filters active PI tiers (GuruStatusID 2-6) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a **financial anomaly detector** for Popular Investor (Guru) cashout-linked bonus payments. It identifies cases where a PI's monthly payment (a "Guru cash with CO" compensation) was credited and reversed on the same day, but the withdrawal associated with that reversed credit was still fully processed on a subsequent day.

This represents a financial discrepancy: the PI's account received a compensation credit, had it reversed the same day (suggesting an error or dispute), but the underlying cashout was still executed - meaning the PI may have received real money for a bonus that was administratively voided.

**CompensationReasonID=41 = "Guru cash with CO"**: PI payment processed as a linked cashout (CO = Cashout). This is the standard mechanism for monthly PI compensation: eToro credits the PI, then the PI withdraws it. CompensationReasonID=50 ("Guru cash no CO") is the variant without a linked cashout.

Used by finance/backoffice teams to identify and investigate PI payment anomalies before or after month-end PI payment processing.

---

## 2. Business Logic

### 2.1 Active PI Filter (GuruStatusID 2-6)

**What**: Builds a `#GuruCIDs` temp table containing only active Popular Investor CIDs.

**Rules**:
- `BackOffice.Customer.GuruStatusID IN (2, 3, 4, 5, 6)` = Cadet, Rising Star, Champion, Elite, Elite Pro
- Excludes hardcoded internal/system accounts: `NOT IN (4535598, 1604918, 149, 4487561, 2295739, 5431588, 5431591, 5431592, 5431594, 4657433, 4657429)`
- CLUSTERED INDEX on CID for efficient join performance

### 2.2 Three-Way ActiveCredit Join - Fault Detection Pattern

**What**: Identifies the three-event "faulted flow" pattern within `History.ActiveCredit`.

**Event t1 - PI bonus credit**:
- `CreditTypeID = 6` (Compensation)
- `CompensationReasonID = 41` (Guru cash with CO - PI payment linked to cashout)
- `CID IN #GuruCIDs`
- The incoming bonus credit for the PI payment

**Event t2 - Same-day reversal** (INNER JOIN):
- Same `CID` as t1
- `Occurred >= t1.Occurred AND CONVERT(date, t2.Occurred) = CONVERT(date, t1.Occurred)` - same calendar day, at or after t1
- `t2.Payment = -t1.Payment` - exact negative amount (full reversal)
- This is the reversal of the bonus credit on the same day

**Event t3 - Subsequent withdrawal processing** (INNER JOIN):
- Same `CID` as t1
- `t3.WithdrawID = t2.WithdrawID` - same withdrawal as the reversed entry
- `t3.Occurred > t2.Occurred` - occurs after the reversal
- `CONVERT(date, t3.Occurred) <> CONVERT(date, t2.Occurred)` - different calendar date from the reversal
- `t3.Payment = 0` - no payment change (processing record only)
- `t3.WithdrawProcessingID IS NOT NULL` - a real withdrawal processing ID exists (withdrawal was executed)

**Fault condition**: All three events present simultaneously = bonus was credited and reversed same-day, but the associated cashout was still processed.

### 2.3 Result Enrichment

**What**: Joins to `Customer.Customer` for display name and external ID.

**Rules**: LEFT JOIN (non-matching CIDs still appear, with NULL cust fields).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No parameters - self-contained diagnostic procedure.

**Result set columns:**

| Column | Source | Description |
|--------|--------|-------------|
| CID | History.ActiveCredit (t1) | Popular Investor customer ID with the faulted flow |
| UserName | Customer.Customer.UserName | PI's eToro username |
| ID | Customer.Customer.ID | PI's external/login ID |
| MoneyAmount | History.ActiveCredit.Payment (t1) | Amount of the PI compensation credit (positive) |
| MoneyInDate | History.ActiveCredit.Occurred (t1) | Date the compensation was credited (and reversed) |
| WithdrawID | History.ActiveCredit.WithdrawID (t3) | The withdrawal ID that was processed |
| WithdrawProcessingID | History.ActiveCredit.WithdrawProcessingID (t3) | The withdrawal processing record ID |
| MoneyOutDate | History.ActiveCredit.Occurred (t3) | Date the withdrawal was processed |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.ActiveCredit (t1) | Read | Primary scan: Compensation/PI bonus credits (CreditTypeID=6, CompensationReasonID=41). |
| INNER JOIN | History.ActiveCredit (t2) | Read | Self-join: finds same-day reversal of t1.Payment. |
| INNER JOIN | History.ActiveCredit (t3) | Read | Self-join: finds subsequent withdrawal processing linked to the reversed entry. |
| FROM | BackOffice.Customer | Read | GuruStatusID filter to restrict to active PI tiers (2-6). |
| LEFT JOIN | Customer.Customer | Lookup | UserName and ID enrichment for result display. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Finance / BackOffice team | EXEC | Direct call | Ad-hoc diagnostic for investigating PI payment anomalies and potential double-payment or reversal errors. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetFaultedPIBonusFlow (procedure)
├── History.ActiveCredit (table) [x3 - t1 scan + t2 same-day reversal + t3 withdrawal processing]
├── BackOffice.Customer (table) [GuruStatusID filter]
└── Customer.Customer (table) [LEFT JOIN for UserName/ID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table | Three-way self-join: t1=PI bonus credit, t2=same-day reversal, t3=subsequent withdrawal processing. |
| BackOffice.Customer | Table | Filters to active PI tier accounts (GuruStatusID IN 2-6) excluding hardcoded system accounts. |
| Customer.Customer | Table | LEFT JOIN for UserName and ID (display fields). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Finance / PI payment operations | External | Investigates cases where PI bonus was reversed but withdrawal still processed. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CompensationReasonID=41 | PI bonus type | Only "Guru cash with CO" (cashout-linked PI payments) are checked. CompensationReasonID=50 (Guru cash no CO) is out of scope. |
| Same-day reversal detection | Date match | Both Occurred >= t1.Occurred AND CONVERT(date,t2.Occurred)=CONVERT(date,t1.Occurred) ensures the reversal is same-calendar-day at or after the credit. |
| Different-day withdrawal | Date mismatch | t3 must be on a DIFFERENT calendar day from t2, ensuring only next-day-or-later processing is flagged. |
| Hardcoded CID exclusions | Known exceptions | 11 specific CIDs excluded from GuruCIDs - likely internal test or system accounts that should not appear in anomaly reports. |

---

## 8. Sample Queries

### 8.1 Run the faulted PI bonus detector

```sql
EXEC History.GetFaultedPIBonusFlow;
```

### 8.2 Check PI payment credits for a specific CID

```sql
SELECT CreditID, CreditTypeID, CompensationReasonID, Payment, TotalCashChange,
       WithdrawID, WithdrawProcessingID, Occurred
FROM History.ActiveCredit WITH (NOLOCK)
WHERE CID = 12345
  AND CreditTypeID = 6
  AND CompensationReasonID IN (41, 50)
ORDER BY Occurred DESC;
```

### 8.3 Verify GuruStatus values

```sql
SELECT GuruStatusID, RTRIM(Name) AS Name
FROM Dictionary.GuruStatus
ORDER BY GuruStatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetFaultedPIBonusFlow | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetFaultedPIBonusFlow.sql*
