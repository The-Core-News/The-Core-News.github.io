#!/usr/bin/env python3
"""
Telegram PPT Auto-Upload Script
OpenClaw agent가 생성한 PPT 파일을 텔레그램에 자동 업로드

사용법:
  python send_telegram_ppt.py <ppt_file_path> [chat_id]
  
환경 변수:
  TELEGRAM_BOT_TOKEN: 텔레그램 봇 토큰
  TELEGRAM_CHAT_ID: (선택) 기본 채팅 ID, 명령줄 인자로도 전달 가능
"""

import sys
import os
from pathlib import Path
from telebot import TeleBot
from telebot.types import File

# 환경 변수에서 텔레그램 봇 토큰 가져오기
TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
if not TELEGRAM_BOT_TOKEN:
    print("❌ 오류: TELEGRAM_BOT_TOKEN 환경 변수가 설정되어 있지 않습니다!")
    print("  텔레그램 봇을 생성하고 토큰을 설정해주세요.")
    sys.exit(1)

bot = TeleBot(TELEGRAM_BOT_TOKEN)

def upload_ppt_to_telegram(ppt_file_path: str, chat_id: str = None) -> bool:
    """
    PPT 파일을 텔레그램에 업로드
    
    Args:
        ppt_file_path: PPT 파일 경로
        chat_id: 텔레그램 채팅 ID (선택)
    
    Returns:
        True if success, False otherwise
    """
    if not os.path.exists(ppt_file_path):
        print(f"❌ 오류: 파일 '{ppt_file_path}'를 찾을 수 없습니다!")
        return False
    
    try:
        # Chat ID 설정
        target_chat_id = chat_id or os.getenv('TELEGRAM_CHAT_ID')
        
        if not target_chat_id:
            print("⚠️ 경고: 텔레그램 채팅 ID가 설정되지 않았습니다.")
            print("  chat_id 파라미터를 전달해주세요.")
            return False
        
        # 파일 업로드
        print(f"📁 파일을 '{ppt_file_path}'에서 텔레그램 채팅 '{target_chat_id}'로 업로드 중...")
        
        with open(ppt_file_path, 'rb') as file:
            bot.send_document(target_chat_id, file)
            
        print(f"✅ 성공! 파일 '{ppt_file_path}'이(가) 텔레그램에 업로드되었습니다!")
        return True
        
    except Exception as e:
        print(f"❌ 오류: 파일 업로드 실패 - {str(e)}")
        return False

def main():
    if len(sys.argv) < 2:
        print("사용법:")
        print("  python send_telegram_ppt.py <ppt_file_path> [chat_id]")
        print("")
        print("예시:")
        print("  python send_telegram_ppt.py /path/to/file.pptx")
        print("  python send_telegram_ppt.py /path/to/file.pptx 7582725936")
        sys.exit(1)
    
    ppt_file = sys.argv[1]
    chat_id = sys.argv[2] if len(sys.argv) > 2 else None
    
    success = upload_ppt_to_telegram(ppt_file, chat_id)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
