-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 13  "결과가 이상한데 에러가 없어요." - 논리 오류 검증
--
-- 이 파일은 교재의 '실습 재료'입니다. 쿼리를 왜 그렇게 쓰는지, 결과를 어떻게 읽고
-- 무엇을 판단하는지는 교재 본문에 있습니다. 예제 제목의 절 번호가 교재의 절 번호와
-- 같으니, 막히는 곳이 있으면 해당 절을 펼쳐 보세요.
--
-- 실행 전제: harmony_db에 harmony_v1.sql(HARMONY 데이터셋) 적재
--
-- 읽는 법
--   -- ======  구분선     이 줄부터 새 예제입니다
--   ▼ 프롬프트            /* 와 */ 사이가 AI에 입력할 내용입니다. 그대로 복사해 쓰세요
--   ▼ AI가 만든 SQL       그 프롬프트로 AI가 만들어 준 쿼리입니다
--   주석 없는 SQL           그대로 실행하면 됩니다
--   ▶ 실행해 보세요       실행해도 됩니다. 무엇을 보게 될지 같은 줄에 적어 두었습니다
--   -- ※                   실습 안내 주석입니다. 입력하지도, 실행하지도 않습니다
-- ============================================

-- ============================================================
-- 예제 1 · [13.1] 값 불일치 - 한국 VIP 팬 조회 (에러 예제)
-- ============================================================

-- ▶ 실행해 보세요 — 에러는 안 나지만 결과가 0명입니다.
--   country 칼럼의 실제 값이 '한국'이 아니라서 조건에 걸리는 행이 없습니다.
--   실제 값은 다음 예제의 DISTINCT로 확인합니다.
SELECT COUNT(*) AS `korean_vip_fans`
FROM fans
WHERE membership_level='VIP'
  AND country='한국';

-- ============================================================
-- 예제 2 · [13.1] 값 불일치 - DISTINCT로 country 확인
-- ============================================================

SELECT DISTINCT country
FROM fans
ORDER BY country;

-- ============================================================
-- 예제 3 · [13.1] 값 불일치 - 수정된 조회
-- ============================================================

SELECT COUNT(*) AS `korean_vip_fans`
FROM fans
WHERE membership_level='VIP'
  AND country='대한민국';

-- ============================================================
-- 예제 4 · [13.1] 값 불일치 - membership_level 확인
-- ============================================================

SELECT DISTINCT membership_level
FROM fans;

-- ============================================================
-- 예제 5 · [13.1] 값 불일치 - country 형식 확인
-- ============================================================

SELECT DISTINCT country
FROM fans;

-- ============================================================
-- 예제 6 · [13.1] NULL 비교 - 잘못된 방법 (에러 예제)
-- ============================================================

-- ▶ 실행해 보세요 — 에러는 안 나지만 결과가 0입니다.
--   SQL에서 NULL은 '=' 로 비교할 수 없습니다. email=NULL은 참도 거짓도 아닙니다.
--   IS NULL을 써야 합니다. 다음 예제와 비교해 보세요.
SELECT COUNT(*)
FROM fans
WHERE email=NULL;

-- ============================================================
-- 예제 7 · [13.1] NULL 비교 - IS NULL 사용
-- ============================================================

SELECT COUNT(*)
FROM fans
WHERE email IS NULL;

-- ============================================================
-- 예제 8 · [13.1] NULL 집계 누락 - COUNT(*) vs COUNT(칼럼명)
-- ============================================================

SELECT COUNT(*) AS `전체 팬 수`,
       COUNT(email) AS `이메일있는팬 수`
FROM fans;

-- ============================================================
-- 예제 9 · [13.1] 날짜 범위 - MIN/MAX로 검증
-- ============================================================

SELECT MIN(order_date),
       MAX(order_date)
FROM orders
WHERE order_date >='2026-07-01'
  AND order_date <'2026-08-01';

-- ============================================================
-- 예제 10 · [13.1] 경곗값 오류 - >를 사용한 오류 예제
-- ============================================================

-- ▶ 실행해 보세요 — 에러는 안 나지만 362건이 나옵니다.
--   '5회 이상'을 찾으려면 >=5여야 하는데 >5라서 정확히 5회인 행이 빠졌습니다.
--   다음 예제(>=5)의 370건과 8건 차이가 납니다.
SELECT COUNT(*) AS `stream_count`
FROM streaming
WHERE play_count >5;

-- ============================================================
-- 예제 11 · [13.1] 경곗값 오류 - >=를 사용한 수정
-- ============================================================

SELECT COUNT(*) AS `stream_count`
FROM streaming
WHERE play_count >=5;

-- ============================================================
-- 예제 12 · [13.1] 검증 3단계 - 건수로 빠르게 확인
-- ============================================================

SELECT COUNT(*) AS `total_fans` FROM fans;

SELECT COUNT(*) AS `vip_fans` FROM fans WHERE membership_level='VIP';

-- ============================================================
-- 예제 13 · [13.1] 검증 3단계 - 대푯값으로 검증 (MIN/MAX)
-- ============================================================

SELECT MIN(order_date), MAX(order_date)
FROM orders
WHERE order_date >='2026-07-01'
  AND order_date <'2026-08-01';

-- ============================================================
-- 예제 14 · [13.1] 검증 3단계 - 역검증으로 합계 맞추기
-- ============================================================

SELECT membership_level, COUNT(*)
FROM fans
GROUP BY membership_level;

SELECT COUNT(*) AS `total` FROM fans;

-- ============================================================
-- 예제 15 · [13.2] JOIN 조건 오류 - LEFT JOIN 초기 쿼리 (에러 예제)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: fans(fan_id, fan_name, membership_level)
테이블: orders(order_id, fan_id, product_id, order_date, total_amount)
테이블: products(product_id, product_name)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.
7월에 주문한 VIP 팬의 이름, 상품명, 주문 금액을 보여 줘.
주문이 없는 VIP 팬도 포함해서 보고 싶어.
*/

-- ▶ 실행해 보세요 — 에러는 안 나지만 주문한 팬만 나옵니다.
--   LEFT JOIN을 썼는데도 WHERE에 o.order_date 조건을 두면, 주문이 없어 NULL인 행이
--   조건에서 걸러집니다. 결과적으로 INNER JOIN과 같아집니다.
--   조건을 ON으로 옮긴 수정본이 아래에 이어집니다.
SELECT
  f.fan_name,
  p.product_name,
  o.total_amount
FROM fans f
LEFT JOIN orders o ON f.fan_id=o.fan_id
LEFT JOIN products p ON o.product_id=p.product_id
WHERE f.membership_level='VIP'
  AND o.order_date >='2026-07-01'
  AND o.order_date <'2026-08-01'
ORDER BY o.total_amount DESC;

-- ============================================================
-- 예제 16 · [13.2] JOIN 조건 오류 - VIP 팬 수 확인
-- ============================================================

SELECT COUNT(*)
FROM fans
WHERE membership_level='VIP';

-- ============================================================
-- 예제 17 · [13.2] JOIN 조건 오류 - 수정된 쿼리 (WHERE를 ON으로 이동)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[문제]
"주문이 없는 VIP 팬도 포함"해달라고 했는데, 결과에 주문한 VIP 팬만 나와.
LEFT JOIN을 썼는데 왜 주문 없는 VIP 팬이 안 나오는지 모르겠어.

[현재 결과]
- VIP 팬 총 44명
- 결과에는 주문한 팬만 표시(주문 없는 팬은 안 보임)

[기대 결과]
- 주문한 VIP 팬: 상품명, 금액 표시
- 주문 없는 VIP 팬: NULL로 표시

[현재 SQL]
SELECT f.fan_name, p.product_name, o.total_amount
FROM fans f
LEFT JOIN orders o ON f.fan_id=o.fan_id
LEFT JOIN products p ON o.product_id=p.product_id
WHERE f.membership_level='VIP'
 AND o.order_date >='2026-07-01'
 AND o.order_date <'2026-08-01';
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT
  f.fan_name,
  p.product_name,
  o.total_amount
FROM fans f
LEFT JOIN orders o ON f.fan_id=o.fan_id
  AND o.order_date >='2026-07-01'
  AND o.order_date <'2026-08-01'
LEFT JOIN products p ON o.product_id=p.product_id
WHERE f.membership_level='VIP'
ORDER BY o.total_amount DESC;

-- ============================================================
-- 예제 18 · [13.2] 서브쿼리 조건 오류 - NOT EXISTS 초기 쿼리 (에러 예제)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: fans(fan_id, fan_name)
테이블: streaming(stream_id, fan_id, stream_date)
테이블: orders(order_id, fan_id, order_date)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.:
7월 22일 이후 스트리밍 기록이 있지만, 7월에 주문 기록이 없는 팬을 찾아 줘.
*/

-- ▶ 실행해 보세요 — 에러는 안 나지만 2명만 나옵니다.
--   NOT EXISTS가 '7월 주문'이 아니라 '전체 기간 주문'을 확인하고 있습니다.
--   과거에 주문했지만 7월에는 안 한 팬이 빠집니다. 날짜 조건을 넣은 수정본이 아래에 있습니다.
SELECT DISTINCT f.fan_id, f.fan_name
FROM fans f
JOIN streaming s ON f.fan_id=s.fan_id
WHERE s.stream_date >='2026-07-22'
  AND NOT EXISTS(
    SELECT 1 FROM orders o
    WHERE o.fan_id=f.fan_id
  )
ORDER BY f.fan_name;

-- ============================================================
-- 예제 19 · [13.2] 서브쿼리 조건 오류 - 7월 22일 이후 스트리밍 팬 수 확인
-- ============================================================

SELECT COUNT(DISTINCT fan_id)
FROM streaming
WHERE stream_date >='2026-07-22';

-- ============================================================
-- 예제 20 · [13.2] 서브쿼리 조건 오류 - 수정된 쿼리 (날짜 조건 추가)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[문제]
"7월에 주문 기록이 없는 팬"을 찾으려고 했는데,
NOT EXISTS가 전체 기간 주문을 체크하고 있어.
과거에 주문했지만 7월에는 안 한 팬이 빠지고 있어.

[현재 결과]
- 7/22 이후 스트리밍한 팬: 60명
- 결과: 2명(전체 기간 주문 없는 팬만 나옴)

[기대 결과]
- 7/22 이후 스트리밍 O+7월 주문 X인 팬
- 과거 주문 이력은 상관없이, 7월에만 주문 안 한 팬 포함

[현재 SQL]
NOT EXISTS(
  SELECT 1 FROM orders o
  WHERE o.fan_id=f.fan_id
)
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT DISTINCT f.fan_id, f.fan_name
FROM fans f
JOIN streaming s ON f.fan_id=s.fan_id
WHERE s.stream_date >='2026-07-22'
  AND NOT EXISTS(
    SELECT 1 FROM orders o
    WHERE o.fan_id=f.fan_id
      AND o.order_date >='2026-07-01'
      AND o.order_date <'2026-08-01'
  )
ORDER BY f.fan_name;

-- ============================================================
-- 예제 21 · [13.2] 이상값 원인 파악 - 7월 상품별 매출 분석
-- ============================================================

-- ※ 상품명이 지면은 '응원봉 Ver. 2'(공백 있음), 데이터셋의 실제 값은 'Ver.2'입니다.
--    지면 표기와 데이터 값의 차이라 정상입니다.

SELECT p.product_name, SUM(o.total_amount) AS `revenue`
FROM orders o
JOIN products p ON o.product_id=p.product_id
WHERE o.order_date >='2026-07-01'
  AND o.order_date <'2026-08-01'
GROUP BY p.product_id, p.product_name
ORDER BY `revenue` DESC
LIMIT 3;

-- ============================================================
-- 예제 22 · [13.2] 이상값 원인 파악 - 상품별 주문 상세 내역
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[현재 결과]
Celestial 포토카드 올멤버 매출이 1,632,000원으로 1위야.
7월 22일 Universe 발매 효과인지 확인하고 싶어.

[추가 분석 요청]
이 상품의 7월 주문 상세 내역을 보여 줘.
주문일, 수량, 금액을 날짜순으로.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT o.order_date, o.quantity, o.total_amount
FROM orders o
JOIN products p ON o.product_id=p.product_id
WHERE p.product_name='Celestial 포토카드 올멤버'
  AND o.order_date >='2026-07-01'
  AND o.order_date <'2026-08-01'
ORDER BY o.order_date;

-- ============================================================
-- 예제 23 · [13.3] 프롬프트 체이닝 1회차 - Universe 일별 스트리밍
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: streaming(stream_id, track_id, stream_date, play_count)
테이블: tracks(track_id, track_name, album_id)
테이블: albums(album_id, album_name, artist_id)

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.:
Universe 트랙의 일별 스트리밍 추이를 보여 줘.
발매일: 2026-07-22
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT
  s.stream_date,
  SUM(s.play_count) AS `daily_streams`
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
WHERE t.track_name='Universe'
GROUP BY s.stream_date
ORDER BY s.stream_date;

-- ============================================================
-- 예제 24 · [13.3] 프롬프트 체이닝 1회차 - Universe 데이터 범위 확인
-- ============================================================

SELECT MIN(stream_date),
       MAX(stream_date)
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
WHERE t.track_name='Universe';

-- ============================================================
-- 예제 25 · [13.3] 프롬프트 체이닝 2회차 - Universe vs Sky High 비교
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[이전 분석 결과]
Universe 트랙의 7/22~7/25 일별 스트리밍:
- 7/22: 212회, 7/23: 233회, 7/24: 256회, 7/25: 232회

[추가 분석]
Celestial의 기존 앨범 'Sky High' 수록곡들의 스트리밍도 함께 보고 싶어.
Universe 발매(7/22) 전후로 기존 곡 스트리밍이 어떻게 변했는지 비교하고 싶어.

[스키마 추가 정보]
- Celestial의 artist_id: 10
- 'Sky High' 앨범의 album_id: 19
- 'Universe' 앨범의 album_id: 20
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT
  s.stream_date,
  a.album_name,
  SUM(s.play_count) AS `daily_streams`
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
JOIN albums a ON t.album_id=a.album_id
WHERE a.album_id IN(19, 20)
  AND s.stream_date BETWEEN '2026-07-15' AND '2026-07-25'
GROUP BY s.stream_date, a.album_name
ORDER BY s.stream_date, a.album_name;

-- ============================================================
-- 예제 26 · [13.3] 프롬프트 체이닝 3회차 - 아티스트별 스트리밍 비교
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[이전 분석 결과]
Sky High(기존 앨범) 스트리밍: 발매 전후 변화 없음(7/17: 24회, 7/25: 24회)
Universe(신규 앨범) 스트리밍: 7/22: 288회, 7/23: 309회, 7/24: 271회, 7/25: 232회

[분석 방향 변경]
Universe 발매 효과를 측정하려면 비교군이 필요해.
같은 기간(7/22-7/25) Celestial vs. 다른 아티스트 스트리밍을 비교하고 싶어.

[요청]
SQL을 작성해 줘.
7월 22일-25일 아티스트별 총 스트리밍 수를 비교해 줘.
상위 5개 아티스트만.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT
  ar.artist_name,
  SUM(s.play_count) AS `total_streams`
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
JOIN albums a ON t.album_id=a.album_id
JOIN artists ar ON a.artist_id=ar.artist_id
WHERE s.stream_date BETWEEN '2026-07-22' AND '2026-07-25'
GROUP BY ar.artist_id, ar.artist_name
ORDER BY `total_streams` DESC
LIMIT 5;

-- ============================================================
-- 예제 27 · [13.3] 프롬프트 체이닝 3회차 추가 - 발매 전후 비교 (CASE WHEN)
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[요청]
SQL을 작성해 줘.:
같은 아티스트들에 대해 발매 전(7/15~7/21)과 발매 후(7/22~7/25) 스트리밍을 한 쿼리에서 나란히 비교할 수 있게
해 줘. 상위 3개 아티스트만.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT
  ar.artist_name,
  SUM(CASE WHEN s.stream_date BETWEEN '2026-07-15' AND '2026-07-21'
    THEN s.play_count ELSE 0 END) AS `before_release`,
  SUM(CASE WHEN s.stream_date BETWEEN '2026-07-22' AND '2026-07-25'
    THEN s.play_count ELSE 0 END) AS `after_release`
FROM streaming s
JOIN tracks t ON s.track_id=t.track_id
JOIN albums a ON t.album_id=a.album_id
JOIN artists ar ON a.artist_id=ar.artist_id
WHERE s.stream_date BETWEEN '2026-07-15' AND '2026-07-25'
GROUP BY ar.artist_id, ar.artist_name
ORDER BY `after_release` DESC
LIMIT 3;
