#!/usr/bin/env python3
from pathlib import Path
import argparse
import json
import sys

REQUIRED_FILES = [
    "01_sources.json",
    "02_verified_facts.json",
    "03_draft.md",
    "04_claims.json",
    "05_verification_report.json",
    "06_publish_decision.json",
    "summary.md",
]

BLOCKING_VERDICTS = {"contradicted"}
BLOCKING_UNSUPPORTED_SEVERITIES = {"high", "critical"}

def load_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8", errors="replace"))
    except Exception as e:
        raise SystemExit(f"JSON_PARSE_FAILED: {path}: {e}")

def as_claim_list(data):
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        for key in ("claims", "items", "results"):
            if isinstance(data.get(key), list):
                return data[key]
    return []

def latest_run_dir():
    runs = Path("runs")
    if not runs.exists():
        return None

    search_roots = []

    auto_publish = runs / "auto-publish"
    if auto_publish.exists():
        search_roots.append(auto_publish)

    # 기존 호환성: runs/<run_id>/ 구조도 허용하되 content-audit는 제외한다.
    search_roots.append(runs)

    candidates = []

    for root in search_roots:
        for p in root.iterdir():
            if not p.is_dir():
                continue
            if p.name == "content-audit":
                continue
            if p == auto_publish:
                continue
            if (p / "06_publish_decision.json").exists():
                candidates.append(p)

    if not candidates:
        return None

    return sorted(candidates, key=lambda p: p.stat().st_mtime, reverse=True)[0]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-dir", help="runs/<run_id> 경로. 생략하면 최신 run을 사용합니다.")
    args = parser.parse_args()

    run_dir = Path(args.run_dir) if args.run_dir else latest_run_dir()

    errors = []

    if run_dir is None:
        errors.append("검증할 runs/<run_id> 디렉터리를 찾지 못했습니다.")
        print("PUBLISH_DECISION_GATE_FAILED")
        for e in errors:
            print(f"- {e}")
        sys.exit(1)

    if not run_dir.exists() or not run_dir.is_dir():
        errors.append(f"run 디렉터리가 없습니다: {run_dir}")

    for name in REQUIRED_FILES:
        if not (run_dir / name).exists():
            errors.append(f"필수 파일 누락: {run_dir / name}")

    if errors:
        print("PUBLISH_DECISION_GATE_FAILED")
        for e in errors:
            print(f"- {e}")
        sys.exit(1)

    decision = load_json(run_dir / "06_publish_decision.json")
    claims_data = load_json(run_dir / "04_claims.json")
    claims = as_claim_list(claims_data)

    status = str(decision.get("status", "")).lower().strip()
    if status != "approved":
        errors.append(f"06_publish_decision.json status가 approved가 아님: {status!r}")

    safe_to_merge = decision.get("safe_to_merge_main")
    if safe_to_merge is not True:
        errors.append("06_publish_decision.json safe_to_merge_main 값이 true가 아님")

    contradicted = []
    unsupported_blocking = []

    for idx, claim in enumerate(claims, 1):
        if not isinstance(claim, dict):
            continue

        verdict = str(
            claim.get("verdict")
            or claim.get("status")
            or claim.get("result")
            or ""
        ).lower().strip()

        severity = str(
            claim.get("severity")
            or claim.get("risk")
            or claim.get("level")
            or ""
        ).lower().strip()

        text = str(claim.get("claim") or claim.get("text") or f"claim#{idx}")

        if verdict in BLOCKING_VERDICTS:
            contradicted.append(text)

        if verdict == "unsupported" and severity in BLOCKING_UNSUPPORTED_SEVERITIES:
            unsupported_blocking.append(text)

    if contradicted:
        errors.append(f"contradicted claim 존재: {len(contradicted)}개")
        for c in contradicted[:10]:
            errors.append(f"  contradicted: {c}")

    if unsupported_blocking:
        errors.append(f"high/critical unsupported claim 존재: {len(unsupported_blocking)}개")
        for c in unsupported_blocking[:10]:
            errors.append(f"  unsupported: {c}")

    if errors:
        print("PUBLISH_DECISION_GATE_FAILED")
        print(f"run_dir={run_dir}")
        for e in errors:
            print(f"- {e}")
        sys.exit(1)

    print("PUBLISH_DECISION_GATE_PASSED")
    print(f"run_dir={run_dir}")
    print(f"claims_checked={len(claims)}")

if __name__ == "__main__":
    main()
