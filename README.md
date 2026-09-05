# 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일

교재와 함께 쓰는 실습 재료입니다. 쿼리와 프롬프트는 모두 들어 있지만, 왜 그렇게 쓰는지와
결과를 어떻게 읽는지는 교재 본문에 있습니다.

예제 제목의 절 번호(`[11.1]`, `[19.2]`)가 **교재의 절 번호와 같습니다.** 막히면 그 절을 펼쳐 보세요.
모든 SQL은 MySQL 8.4 LTS + HARMONY 데이터셋에서 실행 검증했습니다.

## 폴더 구성

위에서부터 차례로 내려가면 됩니다. **`0주차/`부터 시작하세요.**

```
실습파일/
├── 0주차/        harmony_v1.sql     HARMONY 데이터셋 (17개 테이블) — 여기부터
│                 day00              오리엔테이션
├── 1주차/        day01 ~ day05      SELECT · WHERE · ORDER BY · GROUP BY · HAVING
├── 2주차/        day06 ~ day10      JOIN · 서브쿼리 · CTE · 윈도우 함수 · JSON
├── 3주차/        day11 ~ day15      AI로 SQL 만들기 · 오류 검증 · 스키마 링킹
├── 4주차/        day16 ~ day20      문제 정의 · 쿼리 개선 · 탐색 분석 · 리포트
├── 5주차/        day21 ~ day25      클로드 코드로 만드는 데이터 분석 에이전트
│   ├── harmony-analysis/            Day 21~25 동안 직접 채워 갈 시작 프로젝트
│   ├── 환경셋업/                     도커 · 계정 생성 SQL · 환경 점검 도구
│   └── day21~25/                    프롬프트 → 코드 → SQL 순서의 Day별 문서
├── 부록/         appendix_A ~ N     집계 · 날짜 · 인덱스 · NULL · VIEW · RAG 기초
└── docs/                            정오표 · 자주 묻는 질문
```

막히거나 결과가 책과 다를 때는 [자주 묻는 질문](docs/자주-묻는-질문.md)을 먼저 보세요.
지면 오류는 [정오표](docs/정오표.md)에 모읍니다.

## 시작하기

### 0~4주차와 부록 — db-fiddle이면 충분합니다

설치할 것이 없습니다. https://www.db-fiddle.com 에서:

1. 왼쪽 위 `Database` 목록에서 **MySQL → `8`** 을 고릅니다
2. `0주차/harmony_v1.sql` 전체를 왼쪽 **Schema SQL** 칸에 붙여 넣습니다
3. 실습할 예제를 오른쪽 **Query SQL** 칸에 붙여 넣고 **Run**

> db-fiddle 목록에는 `9`, `8`, `5.7`처럼 **메이저 번호만** 나옵니다. `8.4`라는 항목은
> 없으니 `8`을 고르시면 됩니다. `9`를 골라도 0~4주차와 부록은 그대로 동작합니다.
> 실제로 어떤 버전이 붙었는지는 `SELECT VERSION();`으로 확인할 수 있습니다.

왼쪽 칸은 한 번만 채우면 됩니다.

내 PC의 MySQL을 쓴다면 데이터베이스를 먼저 만들어야 합니다.

```bash
mysql -u [사용자] -p -e "CREATE DATABASE harmony_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u [사용자] -p --default-character-set=utf8mb4 harmony_db < 0주차/harmony_v1.sql
```

### 5주차 — 로컬 MySQL이 필요합니다

클로드 코드가 MCP로 실제 데이터베이스에 접속하므로 db-fiddle로는 진행할 수 없습니다.
도커로 한 번에 준비됩니다(데이터셋과 `query_history`가 자동 적재).

```bash
cd 5주차/환경셋업 && docker compose up -d
```

이미 MySQL이 있다면 위 명령으로 데이터셋을 적재한 뒤 `query_history` 테이블만 추가하면 됩니다.

```bash
mysql -u [사용자] -p harmony_db < 5주차/환경셋업/query_history_setup.sql
```

자세한 안내는 `5주차/README.md`와 `5주차/환경셋업/도커로_MySQL_준비하기.md`를 참고하세요.

> **실습 전용 DB에서 진행하세요.** 5주차는 클로드 코드가 데이터베이스에 직접 붙어
> 쿼리를 실행하는 구성을 만듭니다. 운영 중인 회사·서비스 DB에는 연결하지 마세요.

> **MySQL 버전**: 5주차 자료는 8.4.10 기준입니다. 다른 버전에서 `MD5()`가 없다는
> 오류가 나면 `5주차/day25/day25.md`의 SHA-256 대안을 사용하세요.

## 파일 읽는 법

예제 하나가 구분선으로 나뉘고, 프롬프트가 있는 예제는 프롬프트와 그 결과 SQL이 한 묶음입니다.

```sql
-- ============================================================
-- 예제 3 · [11.1] Zero-Shot: 스키마 정보 함께 전달
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: albums(album_id, album_name, release_date)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 2026년 7월에 발매된 앨범의 이름과 발매일 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT album_name, release_date
FROM albums
WHERE release_date >= '2026-07-01'
  AND release_date < '2026-08-01';
```

| 표기 | 뜻 |
|---|---|
| `/* ... */` 블록 | AI에 입력할 프롬프트. **접두 기호가 없어 드래그해 그대로 복사**하면 됩니다 |
| 주석 없이 바로 나오는 SQL | 그대로 실행하면 됩니다 |
| `▶ 실행해 보세요 — 사유` | **그대로 실행해도 됩니다.** 무엇을 보게 될지 같은 줄에 적혀 있습니다 |
| `✕ 실행하지 마세요 — 사유` | 주석 처리해 둔 코드. 왜 실행하지 않는지 같은 줄에 적혀 있습니다 |

`▶`가 붙은 예제는 **일부러 에러를 내 보는 것**이 많습니다. 잘못된 문법, 다른 DBMS의 문법,
없는 테이블 이름처럼 교재가 "이렇게 쓰면 안 된다"를 보여주는 자리입니다. 에러 메시지를
직접 읽어 보는 것도 실습이니 마음 놓고 실행하세요 — **데이터는 바뀌지 않습니다.**
파일 하나를 통째로 실행한 뒤 데이터가 그대로인 것을 확인해 두었습니다.

`✕`는 열한 곳뿐입니다. **데이터가 실제로 바뀌는 것 두 개**(0주차 예제 4·8)와,
DBMS별 함수를 나란히 적어 둔 메모·터미널 명령·실행 결과 예시처럼 **애초에 실행할 SQL이
아닌 것 아홉 개**입니다.

`5주차/`는 각 Day 폴더의 `dayNN.md` 한 파일에서 교재 순서대로 프롬프트·코드·SQL을
복사해 실습할 수 있습니다. 개념과 결과 해석은 교재에 두고, 예제파일에는 실행 순서와
환경별 오류 해결만 보충했습니다.

## 질문과 오류 제보

**막혔을 때는 [Discussions], 잘못된 것을 찾았을 때는 [Issues]** — 이 한 줄만 기억하시면 됩니다.

| 남기실 내용 | 어디에 |
|---|---|
| 실습하다 막혔다 · 에러가 왜 나는지 모르겠다 · 사용법이 궁금하다 | [Discussions → **Q&A**][q-a] |
| 이런 예제가 있으면 좋겠다 · 이렇게 바꾸면 어떨까 | [Discussions → **Ideas**][ideas] |
| 실습을 응용해 만든 것을 공유하고 싶다 | [Discussions → **Show and tell**][show] |
| **예제 파일**이 실행되지 않는다 · 결과가 책과 다르다 | [Issues → **예제 파일 오류 제보**][bug] |
| **교재 지면**에 오탈자·잘못된 설명이 있다 | [Issues → **교재 본문 오류·오탈자 제보**][errata] |
| 정오표 · 예제 파일 업데이트 소식 | [Discussions → **Announcements**][notice] (읽기 전용) |

가르는 기준은 간단합니다. **답변을 원하시면 Discussions, 고쳐야 할 것을 알려 주시는 거면 Issues**입니다.
Issues는 고쳐서 닫는 목록이라, 질문을 여기에 남기시면 오히려 답변이 늦어집니다.

어느 쪽이든 ① 막힌 위치(예: `3주차 Day 12` 또는 `356쪽`) ② 실행 환경(db-fiddle / 도커 /
직접 설치, MySQL 버전) ③ 실행한 쿼리와 오류 메시지를 함께 적어 주시면 빠르게 확인할 수 있습니다.

읽기만 할 때는 계정이 필요 없고, 글을 쓰려면 GitHub 계정이 필요합니다
([가입](https://github.com/signup), 1~2분).

## 예제 파일 이용에 대하여

이 저장소의 예제를 여러분의 프로그램과 문서에 쓰실 때 따로 허락을 구하실 필요는 없습니다.
예제 여러 개를 가져다 업무용 쿼리를 만드는 것, 질문에 답하며 코드를 인용하는 것,
사내 교육 자료에 일부를 옮기는 것 모두 자유롭게 하셔도 됩니다.

다만 예제 모음 자체를 재배포하거나, 상당 부분을 제품 문서나 유료 강의에 그대로 싣는
경우에는 미리 알려 주세요. 출처를 밝혀 주시면 고맙지만 의무는 아닙니다. 밝히실 때는
이 정도면 충분합니다 — 『SQL부터 AI까지 데이터 분석 With 클로드 코드』(조한성 지음, 정보문화사).

교재 본문과 그림, 편집 디자인은 위 안내의 대상이 아닙니다. 저작권은 저자와 정보문화사에 있습니다.

> HARMONY 데이터셋은 실습을 위해 만든 가상의 데이터입니다. 이름, 이메일, 전화번호까지
> 모두 허구이며 실재하는 인물·단체·기업과는 아무 관계가 없습니다.

[q-a]: https://github.com/hansungc/sql-to-ai/discussions/categories/q-a
[ideas]: https://github.com/hansungc/sql-to-ai/discussions/categories/ideas
[show]: https://github.com/hansungc/sql-to-ai/discussions/categories/show-and-tell
[notice]: https://github.com/hansungc/sql-to-ai/discussions/categories/announcements
[bug]: https://github.com/hansungc/sql-to-ai/issues/new?template=1-example-bug.yml
[errata]: https://github.com/hansungc/sql-to-ai/issues/new?template=2-book-errata.yml
