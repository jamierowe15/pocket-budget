#!/usr/bin/env python3
"""Coverage gate for the lab packages. Fails (exit 1) if coverage is under the minimum.

Reads either format:
  llvm   JSON from `swift test --enable-code-coverage`
         (path printed by `swift test --show-codecov-path`)
  xccov  JSON from `xcrun xccov view --report --json Result.xcresult`

Examples:
  python3 scripts/check_coverage.py llvm Packages/Auth/.build/debug/codecov/Auth.json --name Auth --min 70
  python3 scripts/check_coverage.py xccov coverage.json --targets AppTarget --min 0
"""
import argparse
import json
import sys


def llvm_coverage(path, package):
    """Line coverage for files under Packages/<package>/Sources/ only."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    needle = f"/Packages/{package}/Sources/"
    covered = total = 0
    for entry in data["data"][0]["files"]:
        name = entry["filename"].replace("\\", "/")
        if needle not in name or "/.build/" in name:
            continue
        lines = entry["summary"]["lines"]
        covered += lines["covered"]
        total += lines["count"]
    return (100.0 * covered / total if total else 0.0), total


def xccov_coverage(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    result = {}
    for target in data.get("targets", []):
        name = target["name"]
        for suffix in (".app", ".framework", ".appex", ".xctest"):
            name = name.removesuffix(suffix)
        result[name] = 100.0 * target.get("lineCoverage", 0.0)
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="format", required=True)

    llvm = sub.add_parser("llvm", help="swift test --enable-code-coverage JSON")
    llvm.add_argument("path")
    llvm.add_argument("--name", required=True, help="package name, e.g. Networking")
    llvm.add_argument("--min", type=float, default=70.0)
    llvm.add_argument("--markdown", help="append a Markdown table row to this file")

    xccov = sub.add_parser("xccov", help="xcrun xccov --json report")
    xccov.add_argument("path")
    xccov.add_argument("--targets", nargs="+", required=True)
    xccov.add_argument("--min", type=float, default=70.0)
    xccov.add_argument("--markdown", help="append a Markdown table row to this file")

    args = parser.parse_args(argv)
    failures = []

    if args.format == "llvm":
        percent, lines = llvm_coverage(args.path, args.name)
        rows = [(args.name, percent, lines)]
    else:
        report = xccov_coverage(args.path)
        rows = []
        for target in args.targets:
            if target not in report:
                print(f"warning: target {target!r} not in report (have: {', '.join(sorted(report))})")
                failures.append(target)
                continue
            rows.append((target, report[target], None))

    for name, percent, lines in rows:
        ok = percent >= args.min
        status = "PASS" if ok else "FAIL"
        detail = f" over {lines} lines" if lines is not None else ""
        print(f"{status}  {name:<14} {percent:5.1f}%{detail}  (minimum {args.min:.0f}%)")
        if args.markdown:
            gate = f"{status} (min {args.min:.0f}%)" if args.min > 0 else "report only"
            with open(args.markdown, "a", encoding="utf-8") as out:
                out.write(f"| {name} | {percent:.1f}% | {lines if lines is not None else '-'} | {gate} |\n")
        if not ok:
            failures.append(name)

    if failures:
        print(f"Coverage gate failed for: {', '.join(failures)}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
