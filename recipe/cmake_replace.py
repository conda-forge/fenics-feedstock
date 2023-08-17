"""
Script to strip path prefixes from CMake string arrays

- Only checks strings (within "")
- Splits on ';'
- exclude any entries that begin with a list of prefixes
"""
import difflib
import os
import re
import sys

to_strip = (
    "/Applications",
    "/usr/lib",
    "/usr/lib64",
    os.environ["BUILD_PREFIX"],
)

# only
str_pat = re.compile(r'"([^"]*)"')


def strip_prefixes(match):
    original = match.group(0)
    text = match.group(1)
    if not text:
        return original
    chunks = text.split(";")
    new_chunks = []
    changed = False
    for chunk in chunks:
        if chunk.startswith(to_strip):
            print(f"Removing {chunk}")
            changed = True
        else:
            new_chunks.append(chunk)

    if not changed:
        return original

    return f'"{";".join(new_chunks)}"'


def replace_one(path):
    with open(path) as f:
        old_text = f.read()
        new_text, n_subs = str_pat.subn(strip_prefixes, old_text)
    name = os.path.basename(path)
    if n_subs:
        print(
            "\n".join(
                difflib.unified_diff(
                    old_text.splitlines(),
                    new_text.splitlines(),
                    name,
                    name,
                )
            )
        )
        with open(path + ".fixed", "w") as f:
            f.write(new_text)


for f in sys.argv[1:]:
    replace_one(f)
