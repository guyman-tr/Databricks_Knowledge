"""Hunt for tail-fusion corruption artifacts in the deployed codepoint
remediation SQL (and the patched wiki .alter.sql files). A typical artifact
looks like '=Diamondsk limits' where the substitution truncated mid-word
('VIP. Determines available features and ri' -> 'Diamond' but the trailing
'sk limits' from 'risk limits' fused onto 'Diamond')."""
from __future__ import annotations

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"
DEPLOYED = REPO / "knowledge" / "_codepoint_claims_remediation.alter.sql"

TRUTHS = (
    "Diamond", "Internal", "Bronze", "Silver", "Gold", "Platinum",
    "ETF", "Card", "Stocks", "Visa", "Indices", "Commodities", "Currencies",
    "Refund", "Fee", "Pending", "Approved", "Normal", "Active", "Closed",
    "OnlinePayment", "Contactless", "CashWithdrawal", "Transfer", "Payment",
    "Settled", "Confirmed", "Verified", "Error", "Failed", "Reverse Deposit",
    "Cashout Fee", "Local Card", "Master Card", "ASIC", "FCA", "CySEC",
    "Level 0", "Level 1", "Level 2", "Level 3", "Retail Pending",
    "ManualPositionOpen", "PositionOpenTypeUnknown", "Crypto Currencies",
    "Adjustment", "Bonus Abuser", "Staking", "Airdrop",
)

PAT = re.compile(r"=([A-Z][A-Za-z]+)(\s+)([a-z])")


def scan(file: Path, label: str) -> list[tuple[int, str, str, str]]:
    out = []
    text = file.read_text(encoding="utf-8")
    for i, line in enumerate(text.splitlines(), 1):
        for m in PAT.finditer(line):
            w = m.group(1)
            for t in TRUTHS:
                if w.startswith(t) and w != t:
                    tail = w[len(t):]
                    if 1 <= len(tail) <= 5:
                        out.append((i, t, tail, line))
                        break
    return out


def main() -> None:
    print("Scanning deployed remediation SQL...")
    for i, t, tail, line in scan(DEPLOYED, "deployed"):
        print(f"  L{i}: truth='{t}' + tail='{tail}'")
        # show context window around the fused word
        idx = line.find("=" + t + tail)
        if idx >= 0:
            window = line[max(0, idx-30):idx+len(t+tail)+50]
            print(f"      ...{window}...")
    print()
    print("Scanning patched wiki .alter.sql files...")
    total = 0
    for p in WIKI.rglob("*.alter.sql"):
        hits = scan(p, str(p.relative_to(REPO)))
        if hits:
            total += len(hits)
            print(f"\n  {p.relative_to(REPO)}")
            for i, t, tail, line in hits:
                idx = line.find("=" + t + tail)
                window = line[max(0, idx-20):idx+len(t+tail)+50] if idx >= 0 else line[:200]
                print(f"    L{i}: '{t}' + '{tail}'    ...{window}...")
    print(f"\nTotal wiki hits: {total}")


if __name__ == "__main__":
    main()
