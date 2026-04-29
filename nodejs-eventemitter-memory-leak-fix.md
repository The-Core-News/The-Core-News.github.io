# Node.js EventEmitter 메모리 누수 완벽 해결 가이드

## 발생 원인 분석

Node.js 애플리케이션에서 EventEmitter 를 사용하는 과정에서 발생하는 메모리 누수는 실제 서비스 환경에서 치명적인 성능 저하를 유발한다. 특히 장시간 운영되는 백엔드 서버나 실시간 데이터 처리 시스템에서는 누적된 이벤트 리스너 수가 증가하여 Out Of Memory (OOM) 에러가 발생하거나, 응답 속도가 심각한 수준으로 떨어지는 경우가 빈번하다.

메모리 누수의 주요 원인은 다음과 같다:
1. `on()` 또는 `once()` 메서드로 이벤트 리스너를 등록할 때, 제거가 이루어지지 않음
2. 클로저(closure) 내부에서 대용량 객체가 참조되어 Garbage Collection 이 작동하지 않음
3. 여러 Instance 가 생성된 후 cleanup 이 제대로 수행되지 않음

## 해결 방법 1 단계: 리스너 제거 코드 명시적 구현

가장 기본적인 해결책은 이벤트 소멸 시 `removeListener()` 또는 `off()` 메서드를 반드시 호출하는 것이다. 다음 예시 코드를 참고하라:

```javascript
const EventEmitter = require('node:events');

class DataProcessor extends EventEmitter {
  process(data) {
    this.emit('data-received', data);
  }

  cleanup() {
    // 명시적 리스너 제거
    this.removeAllListeners('data-received');
    console.log('EventEmitter 정리 완료');
  }
}

const processor = new DataProcessor();
processor.on('data-received', (data) => console.log(data));
processor.process({ id: 123 });
processor.cleanup(); // 반드시 호출해야 한다.
```

이 코드는 `data-received` 이벤트에 대한 리스너를 명시적으로 제거하여, 메모리 누수를 근본적으로 방지한다.

## 해결 방법 2 단계: MaxListenersExceededWarning 감지 및 자동 대응

Node.js 는 기본적으로 이벤트 리스너 최대 개수 (10 개) 를 제한하며, 이를 초과하면 경고 메세지를 출력한다. 이를 활용하여 메모리 누수를 조기에 발견할 수 있다:

```javascript
const EventEmitter = require('node:events');

// 경보 활성화
process.on('warning', (warning) => {
  if (warning.name === 'MaxListenersExceededWarning') {
    console.error(`경고: ${warning.message}`);
    // 자동 로그 기록 또는 관리자 알림 구현 가능
  }
});

const emitter = new EventEmitter();
emitter.setMaxListeners(20); // 초기 최대 리스너 수 조정 권장
```

MaxListenersExceededWarning 를 감지하고, 경고 메세지를 모니터링 시스템 (예: DataDog, NewRelic) 으로 전달하거나, 자동으로 리셋 로직을 실행하도록 구현하라.

## 해결 방법 3 단계: WeakMap 을 활용한 참조 관리 고급 기법

클로저 내부에서 대용량 객체가 참조되는 경우, WeakMap 을 활용하여 약한 참조를 유지하고 Garbage Collection 이 작동하도록 유도할 수 있다:

```javascript
const EventEmitter = require('node:events');

class AdvancedEmitter extends EventEmitter {
  constructor() {
    super();
    this._listenersData = new WeakMap();
  }

  addAdvancedListener(event, callback, metadata) {
    const wrappedCallback = (data) => {
      console.log(`[Event: ${event}] Metadata`, metadata);
      callback(data);
      // WeakMap 이므로 참조 시 자동 해제 가능
      this._listenersData.set(callback, null);
    };
    this.on(event, wrappedCallback);
  }

  cleanup() {
    this.removeAllListeners();
    this._listenersData.clear();
  }
}
```

WeakMap 을 사용하면 객체 참조를 약하게 유지할 수 있어, 외부에서 더 이상 참조하지 않아도 Garbage Collection 이 자동으로 메모리를 회수한다. 이는 대규모 실시간 처리 시스템에 매우 효과적인 패턴이다.

## 결론 및 추가 팁

Node.js EventEmitter 메모리 누수는 작은 실수로 인해 발생할 수 있지만, 위 방법들을 체계적으로 적용하면 충분히 예방 가능하다. 특히 다음과 같은 추가 팁을 고려하라:

- `setMaxListeners(0)` 으로 경고 자체를 비활성화할 수도 있으나, 이는 근본 해결책이 아니므로 권장하지 않는다.
- 단위 테스트 (Jest 등) 에서 `afterEach` 콜백 내에 리스너 제거 로직을 필수로 포함하라.
- 프로덕션 환경에서 주기적인 `--inspect-brk` 를 실행하여 Heap Snapshot 을 분석하면 누수 지점을 정확히 찾을 수 있다.

공식 문서: [Node.js EventEmitter Reference](https://nodejs.org/api/events.html)

---

*The Core News 분석팀 - 기술 전문 에디터*