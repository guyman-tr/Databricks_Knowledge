import sys
src = open(sys.argv[1], encoding="utf-8").read()
out = []
i = 0
in_single = False
in_block = False
in_line = False
while i < len(src):
    ch = src[i]
    nxt = src[i + 1] if i + 1 < len(src) else ""
    if in_line:
        if ch == "\n":
            in_line = False
            out.append(ch)
        i += 1
        continue
    if in_block:
        if ch == "*" and nxt == "/":
            in_block = False
            i += 2
        else:
            i += 1
        continue
    if in_single:
        if ch == "'":
            if nxt == "'":
                i += 2
                continue
            in_single = False
        i += 1
        continue
    if ch == "-" and nxt == "-":
        in_line = True
        i += 2
        continue
    if ch == "/" and nxt == "*":
        in_block = True
        i += 2
        continue
    if ch == "'":
        in_single = True
        i += 1
        continue
    out.append(ch)
    i += 1
clean = "".join(out)
opens = clean.count("(")
closes = clean.count(")")
print(f"Open: {opens}, Close: {closes}, Delta: {opens - closes}")
# Now walk to find first unclosed or extra-close.
depth = 0
line = 1
col = 0
for j, c in enumerate(clean):
    if c == "\n":
        line += 1
        col = 0
        continue
    col += 1
    if c == "(":
        depth += 1
    elif c == ")":
        depth -= 1
        if depth < 0:
            print(f"Extra `)` at line {line}, col {col}, depth={depth}")
            break
print(f"Final depth: {depth}")
