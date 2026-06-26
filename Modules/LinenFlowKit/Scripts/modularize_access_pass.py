#!/usr/bin/env python3
"""
First-pass module access transformer for the LinenFlowKit split.

For every Swift file in the three library targets this script:
  1. Inserts the cross-module imports the target needs
     (Engine -> Core; UI -> Core + Engine).
  2. Promotes top-level type declarations and their members from the
     default `internal` access level to `public`, so they can be
     referenced across module boundaries.

It is deliberately CONSERVATIVE: it never promotes declarations inside
function bodies / closures (local `let`/`var`) or protocol requirements
(which cannot carry an access modifier), and it skips anything that
already has an explicit access modifier.

This is a mechanical FIRST PASS. A Mac/Xcode build is still required to
finish access control — notably adding `public init(...)` to structs and
classes constructed across modules (Swift does not synthesize public
inits). See Docs/MODULARIZATION_FINISHING.md.

Run:  python3 modularize_access_pass.py /path/to/Modules/LinenFlowKit
"""

import os
import re
import sys

ACCESS_MODIFIERS = {"public", "private", "fileprivate", "internal", "open", "package"}

# Keywords that, as the leading non-attribute token (possibly after other
# modifiers), mark a declaration we want to promote to `public`.
DECL_KEYWORDS = {
    "struct", "class", "enum", "actor", "protocol", "extension",
    "func", "var", "let", "subscript", "typealias", "init",
}
# Modifiers that may precede the real declaration keyword.
LEADING_MODIFIERS = {
    "static", "final", "override", "mutating", "nonmutating", "lazy",
    "weak", "unowned", "dynamic", "convenience", "required", "indirect",
    "distributed", "nonisolated", "isolated", "borrowing", "consuming",
}
# Type-introducing keywords (open a *type* scope, not a code scope).
TYPE_KEYWORDS = {"struct", "class", "enum", "actor", "extension"}

IMPORTS_BY_TARGET = {
    "LinenFlowCore": [],
    "LinenFlowEngine": ["LinenFlowCore"],
    "LinenFlowUI": ["LinenFlowCore", "LinenFlowEngine"],
}

ATTR_RE = re.compile(r"^@[A-Za-z_][A-Za-z0-9_]*(\([^)]*\))?\s*")


def strip_for_braces(line, in_block_comment):
    """Return (sanitized_line, in_block_comment) with comments/strings blanked
    so brace counting ignores them."""
    out = []
    i = 0
    n = len(line)
    while i < n:
        if in_block_comment:
            end = line.find("*/", i)
            if end == -1:
                return "".join(out), True
            i = end + 2
            in_block_comment = False
            continue
        two = line[i:i + 2]
        if two == "//":
            break
        if two == "/*":
            in_block_comment = True
            i += 2
            continue
        ch = line[i]
        if ch == '"':
            # skip string literal (handles simple escapes; good enough)
            i += 1
            while i < n:
                if line[i] == "\\":
                    i += 2
                    continue
                if line[i] == '"':
                    i += 1
                    break
                i += 1
            continue
        out.append(ch)
        i += 1
    return "".join(out), in_block_comment


def leading_tokens(stripped):
    """Yield the declaration's leading tokens after whitespace + attributes,
    returning (insert_col_in_original, tokens) or (None, []) if not a decl."""
    return None  # replaced below


def find_decl_insertion(raw_line):
    """If raw_line is a promotable declaration, return the column at which to
    insert 'public ' (after leading whitespace + attributes), else None."""
    m = re.match(r"^(\s*)", raw_line)
    indent = m.group(1)
    rest = raw_line[len(indent):]
    # consume leading attributes (@Foo, @Foo(...))
    while True:
        am = ATTR_RE.match(rest)
        if not am:
            break
        rest = rest[am.end():]
    insert_col = len(raw_line) - len(rest)
    # tokenize the first few words
    words = re.findall(r"[A-Za-z_][A-Za-z0-9_().,<>]*|[{}]", rest)
    if not words:
        return None
    first = re.match(r"[A-Za-z_]+", words[0])
    first = first.group(0) if first else ""
    if first in ACCESS_MODIFIERS or words[0].startswith(("private(", "public(", "internal(", "fileprivate(")):
        return None  # already has access control
    # walk leading modifiers to find a real decl keyword
    for w in words:
        kw = re.match(r"[A-Za-z_]+", w)
        kw = kw.group(0) if kw else ""
        if kw in LEADING_MODIFIERS:
            continue
        if kw == "class" :
            # could be `class func`/`class var` (modifier) or `class Foo` (type)
            return insert_col  # either way inserting public before is valid
        if kw in DECL_KEYWORDS:
            if kw == "deinit":
                return None
            return insert_col
        return None
    return None


def classify_scope_open(raw_line):
    """Given a line that nets +1 brace, classify the scope it opens."""
    m = re.match(r"^\s*", raw_line)
    rest = raw_line[m.end():]
    while True:
        am = ATTR_RE.match(rest)
        if not am:
            break
        rest = rest[am.end():]
    words = re.findall(r"[A-Za-z_]+", rest)
    # skip access + leading modifiers to find the introducer
    for w in words:
        if w in ACCESS_MODIFIERS or w in LEADING_MODIFIERS:
            continue
        if w == "protocol":
            return "protocol"
        if w in TYPE_KEYWORDS:
            # distinguish `class func` (already filtered: class then func)
            return "type"
        return "code"
    return "code"


def promote_file(path):
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    scope_stack = []  # entries: 'type' | 'protocol' | 'code'
    in_block_comment = False
    changed = 0
    out_lines = []

    for raw in lines:
        line = raw.rstrip("\n")
        sanitized, in_block_comment_after = strip_for_braces(line, in_block_comment)

        # Decide promotion using the scope context BEFORE this line's braces.
        promotable_context = all(s == "type" for s in scope_stack)  # empty => True
        new_line = line
        if promotable_context and not in_block_comment:
            col = find_decl_insertion(line)
            if col is not None:
                new_line = line[:col] + "public " + line[col:]
                changed += 1

        # Update brace scope stack from the (sanitized) line.
        opens = sanitized.count("{")
        closes = sanitized.count("}")
        net = opens - closes
        if net > 0:
            kind = classify_scope_open(line)
            for _ in range(net):
                scope_stack.append(kind)
        elif net < 0:
            for _ in range(-net):
                if scope_stack:
                    scope_stack.pop()

        in_block_comment = in_block_comment_after
        out_lines.append(new_line + "\n")

    if changed:
        with open(path, "w", encoding="utf-8") as f:
            f.writelines(out_lines)
    return changed


def add_imports(path, modules):
    if not modules:
        return 0
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    existing = set()
    last_import_idx = -1
    for i, ln in enumerate(lines[:60]):
        m = re.match(r"^\s*import\s+([A-Za-z_][A-Za-z0-9_]*)", ln)
        if m:
            existing.add(m.group(1))
            last_import_idx = i
    to_add = [m for m in modules if m not in existing]
    if not to_add:
        return 0
    insert_at = last_import_idx + 1 if last_import_idx >= 0 else 0
    new_import_lines = [f"import {m}\n" for m in to_add]
    lines[insert_at:insert_at] = new_import_lines
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(lines)
    return len(to_add)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    src = os.path.join(root, "Sources")
    total_promoted = 0
    total_imports = 0
    for target, imports in IMPORTS_BY_TARGET.items():
        tdir = os.path.join(src, target)
        if not os.path.isdir(tdir):
            continue
        for dirpath, _, filenames in os.walk(tdir):
            for fn in filenames:
                if not fn.endswith(".swift"):
                    continue
                p = os.path.join(dirpath, fn)
                total_imports += add_imports(p, imports)
                total_promoted += promote_file(p)
    print(f"Promoted declarations: {total_promoted}")
    print(f"Imports added:         {total_imports}")


if __name__ == "__main__":
    main()
