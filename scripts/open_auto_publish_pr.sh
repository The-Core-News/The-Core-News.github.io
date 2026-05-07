#!/usr/bin/env bash
set -euo pipefail

BASE_BRANCH="main"
LABEL="auto-publish"

usage() {
  echo "Usage: $0 <run_dir> [commit_message]"
  echo "Example: $0 runs/20260507-140000-new-topic \"Auto publish: new topic\""
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

RUN_DIR="$1"
COMMIT_MESSAGE="${2:-Auto publish verified content}"

if [ ! -d "$RUN_DIR" ]; then
  echo "RUN_DIR_NOT_FOUND: $RUN_DIR"
  exit 1
fi

if [ ! -f "$RUN_DIR/06_publish_decision.json" ]; then
  echo "PUBLISH_DECISION_NOT_FOUND: $RUN_DIR/06_publish_decision.json"
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"
if [ "$CURRENT_BRANCH" != "$BASE_BRANCH" ]; then
  echo "MUST_RUN_FROM_MAIN: current=$CURRENT_BRANCH"
  exit 1
fi

if [ -n "$(git status --short)" ]; then
  echo "WORKTREE_NOT_CLEAN"
  git status --short
  exit 1
fi

RUN_ID="$(basename "$RUN_DIR")"
AUTO_BRANCH="auto-content/$RUN_ID"

echo "[1/8] main 최신화"
git fetch origin "$BASE_BRANCH"
git pull origin "$BASE_BRANCH"

echo "[2/8] publish decision gate 실행"
python3 scripts/validate_publish_decision.py --run-dir "$RUN_DIR"

echo "[3/8] content gate 실행"
python3 scripts/validate_content.py

echo "[4/8] 자동 게시 브랜치 생성"
git checkout -b "$AUTO_BRANCH"

echo "[5/8] 자동 게시 PR에 금지된 파일 변경이 있는지 확인"
CHANGED="$(git diff --name-only "origin/$BASE_BRANCH"...HEAD || true)"
if echo "$CHANGED" | grep -E '^(\.github/workflows/|scripts/)'; then
  echo "AUTO_PUBLISH_MUST_NOT_CHANGE_PIPELINE_FILES"
  echo "$CHANGED"
  exit 1
fi

echo "[6/8] 변경 파일 commit"
git add .
if git diff --cached --quiet; then
  echo "NO_CHANGES_TO_COMMIT"
  exit 1
fi
git commit -m "$COMMIT_MESSAGE"

echo "[7/8] 브랜치 push"
git push -u origin "$AUTO_BRANCH"

echo "[8/8] PR 생성 및 라벨 부착"
PR_URL="$(gh pr create \
  --base "$BASE_BRANCH" \
  --head "$AUTO_BRANCH" \
  --title "$COMMIT_MESSAGE" \
  --body "검증 산출물 경로: $RUN_DIR

자동 게시 후보입니다.
GitHub Actions의 content gate와 publish decision gate를 통과해야 자동 병합됩니다.")"

gh pr edit "$PR_URL" --add-label "$LABEL"

echo "AUTO_PUBLISH_PR_CREATED"
echo "$PR_URL"
