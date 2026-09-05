-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 15  "같은 질문인데 AI 답변이 매번 달라요." - 쿼리 검증
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
--   ✕ 실행하지 마세요       일부러 주석 처리한 SQL입니다. 사유는 같은 줄에 적어 두었습니다
--   ▶ 실행해 보세요       실행해도 됩니다. 무엇을 보게 될지 같은 줄에 적어 두었습니다
-- ============================================

-- ============================================================
-- 예제 1 · [15.1] 스키마 정보 - 스트리밍 데이터베이스
-- ============================================================

-- ▶ 실행해 보세요 — 이미 있는 테이블이라 "already exists" 에러가 납니다. 스키마를 참고용으로 다시 보여 준 것입니다
CREATE TABLE streaming(
   stream_id INT PRIMARY KEY,
   track_id INT,
   stream_date DATE,
   play_count INT,
   FOREIGN KEY(track_id) REFERENCES tracks(track_id)
);

-- CREATE TABLE tracks(
--    track_id INT PRIMARY KEY,
--    track_name VARCHAR(200),
--    album_id INT,
--    FOREIGN KEY(album_id) REFERENCES albums(album_id)
-- );

-- CREATE TABLE albums(
--    album_id INT PRIMARY KEY,
--    album_name VARCHAR(200),
--    artist_id INT,
--    FOREIGN KEY(artist_id) REFERENCES artists(artist_id)
-- );

-- CREATE TABLE artists(
--    artist_id INT PRIMARY KEY,
--    artist_name VARCHAR(100)
-- );

-- ============================================================
-- 예제 2 · [15.1] AI 응답 예시 1 - 전체 JOIN 방식
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE streaming(
   stream_id INT PRIMARY KEY,
   track_id INT,
   stream_date DATE,
   play_count INT,
   FOREIGN KEY(track_id) REFERENCES tracks(track_id)
);

CREATE TABLE tracks(
   track_id INT PRIMARY KEY,
   track_name VARCHAR(200),
   album_id INT,
   FOREIGN KEY(album_id) REFERENCES albums(album_id)
);

CREATE TABLE albums(
   album_id INT PRIMARY KEY,
   album_name VARCHAR(200),
   artist_id INT,
   FOREIGN KEY(artist_id) REFERENCES artists(artist_id)
);

CREATE TABLE artists(
   artist_id INT PRIMARY KEY,
   artist_name VARCHAR(100)
);

[연결 관계]
streaming.track_id→tracks.track_id
tracks.album_id→albums.album_id
albums.artist_id→artists.artist_id

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.:
2026년 7월 15일 이후 아티스트별 총 스트리밍 재생 수를 구해서,
상위 5개 아티스트의 아티스트명과 총 재생 수를 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT
  a.artist_name,
  SUM(s.play_count) AS `total_plays`
FROM streaming s
INNER JOIN tracks t ON s.track_id=t.track_id
INNER JOIN albums al ON t.album_id=al.album_id
INNER JOIN artists a ON al.artist_id=a.artist_id
WHERE s.stream_date >= '2026-07-15'
GROUP BY a.artist_id, a.artist_name
ORDER BY `total_plays` DESC
LIMIT 5;

-- ============================================================
-- 예제 3 · [15.1] AI 응답 예시 2 - 서브쿼리 방식
-- ============================================================

SELECT a.artist_name, agg.total_plays
FROM artists a
INNER JOIN(
   SELECT al.artist_id, SUM(s.play_count) AS `total_plays`
   FROM streaming s
   INNER JOIN tracks t ON s.track_id=t.track_id
   INNER JOIN albums al ON t.album_id=al.album_id
   WHERE s.stream_date >= '2026-07-15'
   GROUP BY al.artist_id
) agg ON a.artist_id=agg.artist_id
ORDER BY agg.total_plays DESC
LIMIT 5;

-- ============================================================
-- 예제 4 · [15.1] AI 응답 예시 3 - CTE 방식
-- ============================================================

WITH artist_streams AS(
  SELECT al.artist_id, SUM(s.play_count) AS `total_plays`
  FROM streaming s
  INNER JOIN tracks t ON s.track_id=t.track_id
  INNER JOIN albums al ON t.album_id=al.album_id
  WHERE s.stream_date >= '2026-07-15'
  GROUP BY al.artist_id
)
SELECT a.artist_name, ast.total_plays
FROM artist_streams ast
INNER JOIN artists a ON ast.artist_id=a.artist_id
ORDER BY ast.total_plays DESC
LIMIT 5;

-- ============================================================
-- 예제 5 · [15.1] AI 응답 예시 4 - 불일치 예시(날짜가 다름)
-- ============================================================

-- ▶ 실행해 보세요 — 에러는 안 나지만 앞의 세 응답과 수치가 다릅니다.
--   요청은 '7월 15일 이후'인데 이 응답만 '7월 1일 이후'로 작성됐습니다.
--   같은 질문에도 AI가 조건을 다르게 해석할 수 있다는 것을 보여 줍니다.
SELECT a.artist_name, SUM(s.play_count) AS `total_plays`
FROM streaming s
INNER JOIN tracks t ON s.track_id=t.track_id
INNER JOIN albums al ON t.album_id=al.album_id
INNER JOIN artists a ON al.artist_id=a.artist_id
WHERE s.stream_date >= '2026-07-01'
GROUP BY a.artist_id, a.artist_name
ORDER BY `total_plays` DESC
LIMIT 5;

-- ============================================================
-- 예제 6 · [15.2] 스키마 정보 - 팬과 주문 데이터
-- ============================================================

-- ▶ 실행해 보세요 — 이미 있는 테이블이라 "already exists" 에러가 납니다. 스키마를 참고용으로 다시 보여 준 것입니다
CREATE TABLE fans(fan_id INT, membership_level VARCHAR(20));
CREATE TABLE orders(order_id INT, fan_id INT, order_date DATE, total_amount INT);

-- ============================================================
-- 예제 7 · [15.2] ChatGPT/Claude 응답 - INNER JOIN 방식
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE fans(fan_id INT, membership_level VARCHAR(20));
CREATE TABLE orders(order_id INT, fan_id INT, order_date DATE, total_amount INT);

[연결 관계]
orders.fan_id→fans.fan_id

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 7월 VIP 팬의 평균 구매 금액 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT AVG(`fan_total`) AS `avg_purchase`
FROM(
   SELECT o.fan_id, SUM(o.total_amount) AS `fan_total`
   FROM orders o
   INNER JOIN fans f ON o.fan_id=f.fan_id
   WHERE f.membership_level='VIP'
    AND o.order_date >= '2026-07-01'
    AND o.order_date < '2026-08-01'
   GROUP BY o.fan_id
) fan_totals;

-- ============================================================
-- 예제 8 · [15.2] Gemini 응답 - LEFT JOIN+COALESCE 방식
-- ============================================================

SELECT AVG(`total_purchase`) AS `avg_purchase`
FROM(
   SELECT f.fan_id, COALESCE(SUM(o.total_amount), 0) AS `total_purchase`
   FROM fans f
   LEFT JOIN orders o ON f.fan_id=o.fan_id
     AND o.order_date >= '2026-07-01' AND o.order_date < '2026-08-01'
   WHERE f.membership_level='VIP'
   GROUP BY f.fan_id
) fan_totals;

-- ============================================================
-- 예제 9 · [15.2] 불일치 원인 분석 - 주문한 VIP 팬 수
-- ============================================================

SELECT
COUNT(DISTINCT o.fan_id) AS `ordered_vip_count`
FROM orders o
JOIN fans f ON o.fan_id=f.fan_id
WHERE f.membership_level='VIP'
 AND o.order_date >= '2026-07-01'
 AND o.order_date < '2026-08-01';

-- ============================================================
-- 예제 10 · [15.2] 불일치 원인 분석 - 전체 VIP 팬 수
-- ============================================================

SELECT COUNT(*) AS `total_vip_count`
FROM fans
WHERE membership_level='VIP';

-- ============================================================
-- 예제 11 · [15.3] 스키마 정보 - VIP 팬 분석
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE fans(fan_id INT, membership_level VARCHAR(20));
CREATE TABLE orders(order_id INT, fan_id INT, order_date DATE, total_amount INT);

[연결 관계]
orders.fan_id→fans.fan_id

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.:
2026년 7월에 실제로 주문한 VIP 팬들의 평균 구매 금액 조회. 주문이 없는 VIP 팬은 제외
*/

-- ▼ AI가 만든 SQL  ✕ 실행하지 마세요 — 데이터셋에 이미 있는 스키마를 참고용으로 다시 보여 준 것입니다
-- CREATE TABLE fans(
--    fan_id INT PRIMARY KEY,
--    fan_name VARCHAR(100),
--    membership_level VARCHAR(50)
-- );

-- CREATE TABLE orders(
--    order_id INT PRIMARY KEY,
--    fan_id INT,
--    order_date DATE,
--    total_amount INT,
--    FOREIGN KEY(fan_id) REFERENCES fans(fan_id)
-- );

-- ============================================================
-- 예제 12 · [15.3] AI 응답 1 - JOIN 방식
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
CREATE TABLE fans(
   fan_id INT PRIMARY KEY,
   fan_name VARCHAR(100),
   membership_level VARCHAR(50)
);

CREATE TABLE orders(
   order_id INT PRIMARY KEY,
   fan_id INT,
   order_date DATE,
   total_amount INT,
   FOREIGN KEY(fan_id) REFERENCES fans(fan_id)
);

[연결 관계]
orders.fan_id→fans.fan_id

[요청]
위 테이블을 사용해서 SQL을 작성해 줘.: 2026년 7월에 VIP 등급 팬들이 구매한 총 금액 조회
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT SUM(o.total_amount) AS `vip_total`
FROM orders o
INNER JOIN fans f ON o.fan_id=f.fan_id
WHERE f.membership_level='VIP'
 AND o.order_date >= '2026-07-01'
 AND o.order_date < '2026-08-01';

-- ============================================================
-- 예제 13 · [15.3] AI 응답 2 - 서브쿼리 방식
-- ============================================================

SELECT SUM(total_amount) AS `vip_total`
FROM orders
WHERE fan_id IN(
  SELECT fan_id
  FROM fans
  WHERE membership_level='VIP'
)
AND order_date >= '2026-07-01'
AND order_date < '2026-08-01';

-- ============================================================
-- 예제 14 · [15.3] AI 응답 3 - CTE+HAVING 실수
-- ============================================================

-- ▶ 실행해 보세요 — HAVING이 집계되지 않은 칼럼을 참조해 "Unknown column ... in 'having clause'" 에러가 납니다
WITH vip_fans AS(
  SELECT fan_id FROM fans WHERE membership_level='VIP'
)
SELECT SUM(o.total_amount) AS `vip_total`
FROM orders o
INNER JOIN vip_fans v ON o.fan_id=v.fan_id
WHERE o.order_date >= '2026-07-01'
HAVING o.order_date < '2026-08-01';

-- ============================================================
-- 예제 15 · [15.3] 날짜 범위 확인
-- ============================================================

SELECT
  MIN(order_date) AS `시작일`,
  MAX(order_date) AS `종료일`,
  COUNT(*) AS `주문 건수`
FROM orders o
INNER JOIN fans f ON o.fan_id=f.fan_id
WHERE f.membership_level='VIP'
 AND o.order_date >= '2026-07-01'
 AND o.order_date < '2026-08-01';

-- ============================================================
-- 예제 16 · [15.3] 대푯값 수동 검증 - 상세 내역
-- ============================================================

SELECT f.fan_name, o.order_date, o.total_amount
FROM orders o
INNER JOIN fans f ON o.fan_id=f.fan_id
WHERE f.membership_level='VIP'
 AND o.order_date >= '2026-07-01'
 AND o.order_date < '2026-08-01'
ORDER BY o.order_date, o.total_amount DESC;

-- ============================================================
-- 예제 17 · [커피 브레이크] 데이터 탐색 - streaming 테이블 구조
-- ============================================================

SELECT * FROM streaming LIMIT 5;

-- ============================================================
-- 예제 18 · [커피 브레이크] 데이터 탐색 - Universe track_id 확인
-- ============================================================

SELECT track_id, track_name FROM tracks WHERE track_name='Universe';
