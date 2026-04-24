#!/usr/bin/env python3
"""
Telegram Bot Proxy for PPT Agent
OpenClaw agent 와 텔레그램 간의 파일 업로드/다운로드 브릿지

이 스크립트는:
1. 텔레그램에서 파일 업로드 받기
2. OpenClaw workspace 로 파일 저장
3. PPTAgent 에게 처리 요청 (필요시)
4. 결과를 다시 텔레그램으로 전송
"""

import os
import sys
from pathlib import Path
from telebot import TeleBot, types
from datetime import datetime

# 구성
TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
TELEGRAM_CHAT_ID = os.getenv('TELEGRAM_CHAT_ID', '7582725936')  # 성남 임 계정
WORKSPACE_DIR = Path('/home/opensn/.openclaw/workspace')
TEMPLATES_DIR = WORKSPACE_DIR / 'templates'
TEMP_DIR = WORKSPACE_DIR / 'temp_telegram_files'

# 디렉토리 생성
TEMPLATES_DIR.mkdir(parents=True, exist_ok=True)
TEMP_DIR.mkdir(parents=True, exist_ok=True)

# 텔레그램 봇 초기화
bot = TeleBot(TELEGRAM_BOT_TOKEN)

def save_uploaded_file(message, file_id):
    """업로드된 파일을 저장"""
    try:
        file_info = bot.get_file(file_id)
        downloaded_path = TEMP_DIR / f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{file_info.file_name}"
        
        bot.download_file(file_info.file_path, downloaded_path)
        print(f"✅ 파일 다운로드 완료: {downloaded_path}")
        return str(downloaded_path)
    except Exception as e:
        print(f"❌ 파일 다운로드 실패: {e}")
        return None

@bot.message_handler(content_types=['document', 'photo', 'text'])
def handle_incoming_message(message):
    """ incoming 메시지 처리 (파일 업로드 등) """
    chat_id = message.chat.id
    
     if content_types == ['document']:
        file_id = message.document.file_id
        file_path = save_uploaded_file(message, file_id)
        
        if file_path:
            # OpenClaw 에게 파일 처리 요청 (후에 구현)
            # bot.send_message(chat_id, f"📄 파일 '{message.document.file_name}'을(를) 받았습니다.\nOpenClaw 에서 처리 중...")
            pass
            
    elif content_types == ['photo']:
        file_id = message.photo[-1].file_id
        file_path = save_uploaded_file(message, file_id)
        
        if file_path:
             # 이미지 분석 후 PPT 생성 요청 (후에 구현)
            pass
            
    elif content_types == ['text']:
         # 일반 텍스트 메시지 (PPT 생성 요청 등)
        bot.send_message(chat_id, f"💬 메시지 받음: {message.text[:100]}...")

def start_bot():
    """봇 시작 - 파일 업로드 핸들러 활성화"""
    print(f"🤖 PPT Agent 봇 시작!")
    print(f"📱 텔레그램 채팅 ID: {TELEGRAM_CHAT_ID}")
    print(f"📂 워크스페이스: {WORKSPACE_DIR}")
    
     # 기본 명령어 핸들러
    @bot.message_handler(commands=['start', 'help'])
    def send_welcome(message):
        bot.reply_to(message, 
            "안녕하세요! 👋\n\n"
            "PPT 에이전트입니다. 다음을 지원해요:\n\n"
            "• 📄 파일 업로드 (문서, 이미지)\n"
            "• 🎯 PPT 생성 요청\n"
            "• 📊 데이터 분석 및 리포트\n\n"
            "도움말: 파일을 보내주시면 자동으로 처리해드립니다!"
        )
    
     # 폴링 시작
    print("⏳ 텔레그램 폴링 중... (Ctrl+C 로 종료)")
    bot.infinity_polling()

if __name__ == '__main__':
    start_bot()
