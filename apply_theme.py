#!/usr/bin/env python3
"""Patch the dark colors of the SQL editor in MySQL Workbench's code_editor.xml.
Usage: apply_theme.py <code_editor.xml> <theme.json>
Always starts from <code_editor.xml>.orig (created on first run)."""
import json, re, shutil, sys, os

MAP = {
    "default": [0], "comment": [1, 2, 65, 66], "variable": [3, 67],
    "sysvar": [4, 5, 68, 69], "number": [6, 70], "string": [12, 13, 76, 77],
    "keyword": [7, 8, 71, 72], "function": [15, 10, 79, 74], "operator": [14, 78],
    "identifier": [16, 80], "quotedIdentifier": [17, 81], "delimiter": [18, 82],
}
HIDDEN_BG_IDS = [21, 65, 66, 67, 68, 69, 70, 71, 72, 74, 76, 77, 78, 79, 80, 81, 82]

def set_attr(tag, name, value):
    if re.search(r'(?<![\w-])%s="[^"]*"' % re.escape(name), tag):
        return re.sub(r'(?<![\w-])%s="[^"]*"' % re.escape(name), '%s="%s"' % (name, value), tag, count=1)
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

    fore = {i: theme[k] for k, ids in MAP.items() if k in theme for i in ids}
    bg = theme.get("hiddenBackground")

    def repl(sm):
        tag, sid = sm.group(0), int(sm.group(1))
        if sid in fore:
            tag = set_attr(tag, "fore-color-dark", fore[sid])
        if bg and sid in HIDDEN_BG_IDS and "back-color-dark" in tag:
            tag = set_attr(tag, "back-color-dark", bg)
        return tag

    new_block = re.sub(r'<style id="(\d+)"[^>]*/>', repl, block)
    text = text.replace(block, new_block, 1)
    with open(xml_path, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    print("Applied theme '%s' to %s" % (theme.get("name", theme_path), xml_path))

if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
