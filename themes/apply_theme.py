#!/usr/bin/env python3
"""Apply a theme to the SQL editor colors in MySQL Workbench's code_editor.xml.
Usage: apply_theme.py <code_editor.xml> <theme.json>
Always starts from <code_editor.xml>.orig (created on first run).
Writes the same colors to both the light and dark variants, plus the editor background."""
import json, re, shutil, sys, os

# Applied in order, so later keys override earlier ones (majorKeyword after keyword).
FORE = [
    ("default", [0, 32]), ("comment", [1, 2, 65, 66]), ("variable", [3, 67]),
    ("sysvar", [4, 5, 68, 69]), ("number", [6, 70]), ("string", [11, 12, 13, 75, 76, 77]),
    ("keyword", [7, 8, 71, 72]), ("majorKeyword", [7, 71]),
    ("function", [9, 10, 15, 73, 74, 79]), ("operator", [14, 78]),
    ("identifier", [16, 80]), ("quotedIdentifier", [17, 81]),
    ("delimiter", [18, 19, 20, 82, 83, 84]),
]
MAIN_IDS = list(range(0, 21)) + [32]
HIDDEN_IDS = [21, 22] + list(range(65, 87))

def set_attr(tag, name, value):
    pat = r'(?<![\w-])%s="[^"]*"' % re.escape(name)
    if re.search(pat, tag):
        return re.sub(pat, '%s="%s"' % (name, value), tag, count=1)
    return re.sub(r'\s*/>$', ' %s="%s" />' % (name, value), tag, count=1)

def main(xml_path, theme_path):
    theme = json.load(open(theme_path, encoding="utf-8"))
    orig = xml_path + ".orig"
    if not os.path.exists(orig):
        shutil.copy2(xml_path, orig)
    text = open(orig, encoding="utf-8-sig").read()

    m = re.search(r'<language name="SCLEX_MYSQL">.*?</language>', text, re.S)
    if not m:
        sys.exit("SCLEX_MYSQL section not found - file format differs from expected.")
    block = m.group(0)

    # id -> {attribute: value}
    wanted = {}
    def want(i, **kw):
        wanted.setdefault(i, {}).update(kw)

    for key, ids in FORE:
        c = theme.get(key)
        if c:
            for i in ids:
                want(i, **{"fore-color-light": c, "fore-color-dark": c})
    bg = theme.get("background")
    if bg:
        for i in MAIN_IDS:
            want(i, **{"back-color-light": bg, "back-color-dark": bg})
    hb = theme.get("hiddenBackground") or bg
    if hb:
        for i in HIDDEN_IDS:
            want(i, **{"back-color-light": hb, "back-color-dark": hb})
    if theme.get("lineNumber"):
        c = theme["lineNumber"]
        want(33, **{"fore-color-light": c, "fore-color-dark": c})
        if bg:
            want(33, **{"back-color-light": bg, "back-color-dark": bg})

    seen = set()
    def repl(sm):
        tag, sid = sm.group(0), int(sm.group(1))
        seen.add(sid)
        for k, v in wanted.get(sid, {}).items():
            tag = set_attr(tag, k, v)
        return tag
    new_block = re.sub(r'<style id="(\d+)"[^>]*/>', repl, block)

    # Create styles missing from the stock file (e.g. 32 = editor background, 33 = line numbers).
    extra = ""
    for sid in sorted(set(wanted) - seen):
        attrs = " ".join('%s="%s"' % kv for kv in sorted(wanted[sid].items()))
        extra += '\t\t<style id="%d" %s />\n' % (sid, attrs)
    new_block = new_block.replace("</language>", extra + "\t</language>", 1)

    text = text.replace(block, new_block, 1)
    with open(xml_path, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    print("Applied theme '%s' to %s" % (theme.get("name", theme_path), xml_path))

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
