# 텔레그램 PPT 자동화 설정 가이드

## 📋 현재 상황

- **OpenClaw Workspace**: `/home/opensn/.openclaw/workspace`
- **PPT 템플릿**: `templates/company_template.pptx`
- **텔레그램 계정**: 성남 임 (ID: 7582725936)
- **사용 스크립트**: 
  - `scripts/send_telegram_ppt.py` - PPT 파일 업로드용
  - `scripts/telegram_bot_proxy.py` - 텔레그램 봇 브릿지용

## 🚀 설치 및 설정 방법

### 1. Python 의존성 설치

```bash
cd /home/opensn/.openclaw/workspace
pip install python-telegram-bot pyyaml
```

### 2. 환경 변수 설정

`.env` 파일 생성 (프로젝트 루트에 저장):

```env
# 텔레그램 봇 토큰
TELEGRAM_BOT_TOKEN=your_bot_token_here

# 기본 채팅 ID (선택)
TELEGRAM_CHAT_ID=7582725936
```

### 3. 텔레그램 봇 생성 방법

1. **BotFather 에게 가세요**: https://telegram.me/BotFather
2. `/newbot` 명령어 실행
3. 봇 이름과.username 설정
4. 받은 `TOKEN` 을 `.env` 파일에 저장

### 4. 스크립트 실행 테스트

```bash
# PPT 업로드 테스트
python scripts/send_telegram_ppt.py /home/opensn/.openclaw/workspace/templates/company_template.pptx

# 텔레그램 봇 시작 (백그라운드에서 실행)
nohup python scripts/telegram_bot_proxy.py > telegram_bot.log 2>&1 &
```

## 💡 사용 방법

### 기본 명령어 (텔레그램에서)

- `/start` - 인사말 및 메뉴 표시
- `/help` - 도움말
- 파일 업로드 - PPT 파일을 보내면 자동으로 처리

### 고급 사용

```python
# OpenClaw 에서 직접 PPT 생성 후 전송
import sys
sys.path.append('/home/opensn/.openclaw/workspace/scripts')
from send_telegram_ppt import upload_ppt_to_telegram

upload_ppt_to_telegram(
    '/home/opensn/.openclaw/workspace/output.pptx',
    chat_id='7582725936'
)
```

## 🔧 문제 해결

### 문제가 발생하면:

1. `TELEGRAM_BOT_TOKEN` 이 올바른지 확인
2. 채널 ID 가 유효한지 확인 (`get_me` 명령어로 봇 정보 확인)
3. `python scripts/send_telegram_ppt.py --help` 실행
4. 로그 파일 확인: `cat telegram_bot.log`

### 파일이 업로드 안 되나요?

- Telethon 라이브러리 대신 python-telegram-bot 사용 권장
- 파일 크기 제한 확인 (보통 50MB)
- 네트워크 연결 상태 확인

---

**도움이 필요하시면 언제든 말씀해주세요!** 😊🚀
