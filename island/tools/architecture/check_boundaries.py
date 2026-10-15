#!/usr/bin/env python3
"""IslandBar architecture dependency guard (standard library only).

Existing legacy boundary violations are tracked in legacy-dependencies.json.
The guard fails only when *new* prohibited edges appear, permitting gradual
migration under IslandBar Architecture V1 without breaking the existing tree.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
BASELINE = HERE / "legacy-dependencies.json"
MODULE_PATTERN = re.compile(
    r'\.name\s*=\s*"([^"]+)"\s*,\s*\.module\s*=\s*sourceModule\s*\([^,]+,[^,]+,[^,]+,\s*"([^"]+)"',
    re.MULTILINE,
)
IMPORT_PATTERN = re.compile(r'@import\(\s*"([^"]+)"\s*\)')
STANDARD_IMPORTS = {"std", "builtin", "root", "compiler_rt", "unwind", "options"}
LEGACY_FEATURE_OWNERS = {
    "Notification": "notification",
    "Weather": "weather",
}


def category(path: Path) -> tuple[str, str]:
    parts = path.parts
    if len(parts) < 3 or parts[0] != "src":
        return "other", ""
    group = parts[1]
    if group == "features":
        owner = parts[2] if len(parts) > 3 else LEGACY_FEATURE_OWNERS.get(path.stem, path.stem)
        return group, owner
    if group == "platform":
        return group, ""
    return group, ""


def forbidden(source: Path, target: Path) -> bool:
    source_type, source_owner = category(source)
    target_type, target_owner = category(target)
    if source_type == "core":
        return target_type != "core" and target_type != "other"
    is_windows_impl = target_type == "platform" and len(target.parts) >= 3 and target.parts[2] == "windows"
    if source_type == "ui":
        return target_type in {"features", "app", "shell"} or is_windows_impl
    if source_type == "features":
        core_submodule = len(source.parts) >= 5 and source.parts[3] == "core"
        other_feature_ui = (target_type == "features" and len(target.parts) >= 5
                            and target.parts[3] == "ui")
        return (target_type in {"app", "shell"} or is_windows_impl
                or target_type == "features" and source_owner != target_owner
                or core_submodule and (target_type == "ui" or other_feature_ui))
    if source_type == "platform":
        if len(source.parts) >= 3 and source.parts[2] == "contracts":
            return is_windows_impl or target_type in {"features", "ui", "app", "shell"}
        return target_type in {"features", "ui", "app", "shell"}
    if source_type == "shell":
        # Shell's feature public contracts will need a separate rule once those exist.
        return target_type == "app" or is_windows_impl
    return False


def scan(root: Path) -> tuple[list[str], list[str]]:
    build = (root / "build.zig").read_text(encoding="utf-8")
    module_map = {name: Path(path) for name, path in MODULE_PATTERN.findall(build)}
    # A few modules (e.g. Setup) are injected at the composition root.
    explicit_injections = set(re.findall(r'\.addImport\(\s*"([^"]+)"', build))
    if not module_map or "Renderer" not in module_map or "MediaService" not in module_map:
        raise ValueError("Cannot read the expected named source modules from build.zig")
    violations: set[str] = set()
    unresolved: set[str] = set()
    for f in sorted((root / "src").rglob("*.zig")):
        source = f.relative_to(root)
        for imported in IMPORT_PATTERN.findall(f.read_text(encoding="utf-8")):
            if imported in STANDARD_IMPORTS or imported in explicit_injections:
                continue
            target = module_map.get(imported)
            if target is None and (imported.startswith(".") or imported.endswith(".zig") or "/" in imported):
                possible = (f.parent / imported).resolve()
                if possible.is_file() and possible.is_relative_to(root.resolve()):
                    target = possible.relative_to(root.resolve())
            if target is None:
                # Setup/Payload and Zig package names may be separate build roots.
                unresolved.add(f"{source.as_posix()} -> {imported}")
                continue
            if target == source:
                continue
            if forbidden(source, target):
                violations.add(f"{source.as_posix()} -> {target.as_posix()}")
    return sorted(violations), sorted(unresolved)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT, help="IslandBar repo root")
    parser.add_argument("--record-baseline", action="store_true", help="explicitly replace the tracked debt allowlist")
    parser.add_argument("--report", action="store_true", help="show all currently prohibited dependencies")
    args = parser.parse_args()
    try:
        violations, unresolved = scan(args.root.resolve())
    except (OSError, ValueError) as exc:
        print(f"[ERROR] dependency scan could not run: {exc}", file=sys.stderr)
        return 2
    if args.record_baseline:
        path = (args.root.resolve() / "tools/architecture/legacy-dependencies.json")
        path.write_text(json.dumps({"schema_version": 1, "legacy_edges": violations}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"Recorded {len(violations)} legacy violations in {path}")
        return 0
    try:
        baseline = json.loads((args.root.resolve() / "tools/architecture/legacy-dependencies.json").read_text(encoding="utf-8"))
        allowed = set(baseline["legacy_edges"])
        if baseline.get("schema_version") != 1 or not all(isinstance(x, str) for x in allowed):
            raise ValueError("invalid baseline schema")
    except (OSError, KeyError, ValueError, TypeError) as exc:
        print(f"[ERROR] invalid dependency baseline: {exc}", file=sys.stderr)
        return 2
    fresh = sorted(set(violations) - allowed)
    removed = sorted(allowed - set(violations))
    print(f"IslandBar architecture: {len(violations)} active legacy forbidden edges, "
          f"{len(fresh)} new, {len(removed)} removed, {len(unresolved)} unresolved import names")
    if args.report:
        for edge in violations:
            print(("NEW " if edge in fresh else "OLD ") + edge)
        for edge in unresolved:
            print("UNRESOLVED " + edge)
    if fresh:
        for edge in fresh:
            print("[FAIL] new prohibited import: " + edge, file=sys.stderr)
        print("Do not add this edge to the baseline without an explicit reviewed exception.", file=sys.stderr)
        return 1
    print("[PASS] No new prohibited dependencies detected.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
