# [RecursionError] 재귀 깊이 제한 오류, 해결하는 3 가지 방법

2026 년 현재 Python 개발자들이 가장 자주 마주치는 에러 중 하나가 RecursionError: maximum recursion depth exceeded 입니다. 잘못된 재귀 구조나 기초(base case) 부재로 인해 발생하는 이 문제는 스택 오버플로우를 방지하기 위한 Python 의 보호 장치입니다. 본 가이드에서는 실제 상황에서 바로 적용할 수 있는 3 가지 해결책을 제시합니다.

## RecursionError 가 발생하는 이유

Python 은 함수가 자기 자신을 호출할 때 호출되는 최대 횟수를 제한합니다. 기본 설정값은 보통 1000 회 정도입니다. 재귀 함수가 이 한도를 넘기면 Python 이 RecursionError 를 발생시켜 스택 오버플로우를 방지합니다. 가장 흔한 원인은 다음과 같습니다:

- **Base case(재귀 종료 조건) 누락**: 재귀 호출이 언제 멈춰야 하는지 명시하지 않음
- **잘못된 재귀 논리**: 감소하거나 진척되는 값을 전달하지 못함
- **너무 큰 입력값**: 정상적인 경우에도 재귀 깊이가 과도하게 커짐

## 해결 방법 1: Base Case 추가 (기본 원칙)

재귀 함수의 가장 중요한 요소는 종료 조건입니다. 코드 예제를 통해 확인해보겠습니다:

```python
# ❌ 잘못된 예: base case 없음
def factorial(n):
    return n * factorial(n - 1)  # 무한 재귀!

factorial(5)  # RecursionError 발생
```

```python
# ✅ 올바른 예: base case 명시
def factorial(n):
    if n <= 1:  # 종료 조건 추가
        return 1
    return n * factorial(n - 1)

print(factorial(5))  # 정상 출력: 120
```

**해결 포인트**: 재귀 함수가 반드시 `if n <= 1: return ...` 형태로 종료 조건을 명시해야 합니다.

## 해결 방법 2: Recursion Limit 증가 (임시 조치)

긴급한 상황에서 재귀 깊이를 일시적으로 늘리는 방법이 있습니다:

```python
import sys

# 기본 1000 회에서 5000 회로 증가
sys.setrecursionlimit(5000)

def recursive_function(n):
    if n <= 0:
        return 0
    return 1 + recursive_function(n - 1)

print(recursive_function(4000))  # 정상 동작
```

**주의**: 재귀 한도를 높이는 것은 근본 해결책이 아니며, 메모리 부족으로 프로그램이 죽을 수 있습니다. 반드시 필요할 때만 사용하세요.

## 해결 방법 3: 반복문으로 변환 (권장)

재귀 함수는 거의 대부분 반복문 (for/while) 으로改写할 수 있으며, 이것이 가장 안전하고 성능이 좋습니다:

```python
# ❌ 재귀 버전 (기피)
def fibonacci_recursive(n):
    if n <= 1:
        return n
    return fibonacci_recursive(n - 1) + fibonacci_recursive(n - 2)

# ✅ 반복문 버전 (추천)
def fibonacci_iterative(n):
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b

print(fibonacci_iterative(50))  # 빠르고 안정적
```

**장점**: 
- 재귀 한도 제한 없음
- 메모리 효율성 극대화
- 성능 최적화 용이

## 추가 팁: Tail Recursion 최적화

일부 파이썬 구현체는 tail recursion 을 최적화합니다. 가능하면 재귀 호출을 함수의 마지막 문장으로 배치하세요:

```python
# ✅ Tail Recursive (최적화 가능한 형태)
def factorial_tail(n, accumulator=1):
    if n <= 1:
        return accumulator
    return factorial_tail(n - 1, n * accumulator)
```

---

## 결론

RecursionError 는 재귀 함수의 기본 구조를 다시 검토해야 하는 신호입니다. 먼저 `base case` 가 있는지 확인하고, 가능하다면 반복문으로 전환하는 것이 가장 안전합니다. 임시 조치로 `sys.setrecursionlimit()` 을 사용할 때도 반드시 메모리 사용량을 고려하세요.

**관련 자료**:
- [Python 공식 문서 - RecursionError](https://docs.python.org/3/library/exceptions.html#RecursionError)
- [StackOverflow: How to fix RecursionError in Python](https://stackoverflow.com/questions/tagged/recursionerror)

2026 년 파이썬 개발자를 위한 이 가이드가 재귀 함수 작성에 도움이 되길 바랍니다.
