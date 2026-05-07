#!/usr/bin/env python3
from pathlib import Path
import re
import sys
import subprocess

ROOT = Path(".").resolve()

EXCLUDE_ARTICLES = {
    "index.md",
    "about.md",
    "privacy.md",
    "README.md",
    "AGENT_RULES.md",
}

FORBIDDEN_REPO_FILES = [
    "AGENT_RULES.md",
    "openclaw_tasks.safe.yaml",
]

RISK_PATTERNS = [
    (re.compile(r"2,400|12억|쇼핑몰|금융기관"), "확인되지 않은 피해 규모/피해 사례 가능성"),
    (re.compile(r"대규모 공격|실제 공격|공격 사례|현재 공격|공격 포착"), "실제 악용 주장 가능성"),
    (re.compile(r"즉시 패치|필수|공포|원클릭|치명적|완벽"), "과장 표현 가능성"),
    (re.compile(r"\bPoC\b|공격 코드|\bexploit\b|\battacker\b", re.IGNORECASE), "공격 세부 내용 또는 악용 코드 가능성"),
    (re.compile(r"wget\s+https?://|tar\s+-xzf|systemctl\s+restart|cat\s+/etc/shadow|ssh\s+"), "운영 환경에 위험할 수 있는 직접 실행 명령"),
    (re.compile(r"세계 최초|업계 최초|시장 성장\s*[0-9]|[0-9]+%"), "검증 필요한 수치/최초 주장 가능성"),
]

SECRET_PATTERNS = [
    (re.compile(r"ghp_[A-Za-z0-9_]{20,}"), "GitHub token pattern"),
    (re.compile(r"-----BEGIN OPENSSH PRIVATE KEY-----"), "SSH private key"),
    (re.compile(r"-----BEGIN RSA PRIVATE KEY-----"), "RSA private key"),
    (re.compile(r"AKIA[0-9A-Z]{16}"), "AWS access key pattern"),
]

def fail(errors):
    print("CONTENT_GATE_FAILED")
    for e in errors:
        print(f"- {e}")
    sys.exit(1)

def read_text(path):
    return path.read_text(encoding="utf-8", errors="replace")

def root_md_files():
    return sorted(p for p in ROOT.glob("*.md") if p.is_file())

def article_files():
    return [p for p in root_md_files() if p.name not in EXCLUDE_ARTICLES]

errors = []

def is_git_tracked(path_name):
    result = subprocess.run(
        ["git", "ls-files", "--error-unmatch", path_name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return result.returncode == 0

# 1. 내부 운영 파일 공개 커밋 방지
# 로컬에만 있고 git에 추적되지 않는 파일은 CI에 올라가지 않으므로 실패 처리하지 않는다.
for name in FORBIDDEN_REPO_FILES:
    if is_git_tracked(name):
        errors.append(f"내부 운영 파일이 git 추적 대상임: {name}")

# 2. index.md 존재 확인
index = ROOT / "index.md"
if not index.exists():
    errors.append("index.md가 없음")
    fail(errors)

index_text = read_text(index)

# 3. index.md 로컬 링크 검사
link_pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
index_links = []

for link in link_pattern.findall(index_text):
    if link.startswith(("http://", "https://", "mailto:", "#")):
        continue

    clean = link.split("#", 1)[0]
    if not clean:
        continue

    index_links.append(clean)

    target = ROOT / clean
    if clean.endswith(".md") and not target.exists():
        errors.append(f"index.md 깨진 링크: {clean}")

# 4. root 게시글이 index.md에 포함됐는지 검사
index_link_set = set(index_links)

for p in article_files():
    if p.name not in index_link_set:
        errors.append(f"index.md에 게시글 링크 누락: {p.name}")

# 5. 기사 파일 위험 표현 검사
for p in article_files():
    text = read_text(p)
    for lineno, line in enumerate(text.splitlines(), 1):
        for pattern, reason in RISK_PATTERNS:
            if pattern.search(line):
                errors.append(f"{p.name}:{lineno}: {reason}: {line.strip()}")

# 6. 전체 repo root md에서 토큰/키 패턴 검사
for p in root_md_files():
    text = read_text(p)
    for lineno, line in enumerate(text.splitlines(), 1):
        for pattern, reason in SECRET_PATTERNS:
            if pattern.search(line):
                errors.append(f"{p.name}:{lineno}: 비밀정보 의심: {reason}")

# 7. 마크다운 링크 제목 안 대괄호 중첩 방지
for p in root_md_files():
    for lineno, line in enumerate(read_text(p).splitlines(), 1):
        if re.search(r"\[\[[^\]]+\].*\]\([^)]+\)", line):
            errors.append(f"{p.name}:{lineno}: 링크 제목 안 대괄호 중첩 가능성: {line.strip()}")

if errors:
    fail(errors)

print("CONTENT_GATE_PASSED")
print(f"articles_checked={len(article_files())}")
print(f"index_links_checked={len(index_links)}")
