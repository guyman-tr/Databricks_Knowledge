"""Cross-check 12 manually-analyzed SPs against scanner output."""
import csv
from pathlib import Path

ROOT = Path(__file__).parent
rows = list(csv.DictReader((ROOT / "subaccount-option1-triage.csv").open(encoding="utf-8")))

expected = {
    "SP_DDR_Customer_Daily_Status":      "A",
    "SP_eMoney_Panel_FirstDates":        "A",
    "SP_eMoney_ClientBalance":           "A",
    "SP_eMoney_Daily_Shortfall_CID_Level": "B",
    "SP_DealingDashboard_Clients":       "C",
    "SP_Capital_Adequacy_IFR_KPMG":      "C",
    "SP_VarCommission":                  "C",
    "SP_DepositWithdrawFee":             "D",
    "SP_EXW_FactBalance":                "D",
    "SP_EXW_FinanceReportsBalancesNew":  "D",
    "SP_EXW_FirstTimeWalletsAndUsers":   "E",
    "SP_NOP_LPandClients":               "F",
}

print(f"{'object':<48s} {'got':<3s} {'want':<4s} {'conf':<7s} pri    insight")
print("-" * 130)

for obj_name, want in expected.items():
    matches = [r for r in rows if r["object_name"] == obj_name]
    if not matches:
        print(f"{obj_name:<48s}  MISSING")
        continue
    for r in matches:
        got = r["archetype"]
        mark = "OK  " if got == want else "MISS"
        print(f'{r["schema"]+"."+r["object_name"]:<48s} {got:<3s} {want:<4s} {r["confidence"]:<7s} {r["priority"]:<5s} [{mark}] {r["key_insight"][:70]}')
        print(f'   keys=[{r["dest_customer_keys"]}] money=[{r["dest_money_cols"][:90]}] flags=[{r["dest_pop_flag_cols"][:60]}] count=[{r["dest_count_cols"][:40]}] txn=[{r["dest_txn_cols"][:40]}]')
