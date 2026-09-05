-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- 부록 E  UNION/UNION ALL - 데이터 결합의 기술
--
-- 이 파일은 교재의 '실습 재료'입니다. 쿼리를 왜 그렇게 쓰는지, 결과를 어떻게 읽고
-- 무엇을 판단하는지는 교재 본문에 있습니다. 예제 제목의 절 번호가 교재의 절 번호와
-- 같으니, 막히는 곳이 있으면 해당 절을 펼쳐 보세요.
--
-- 실행 전제: harmony_db에 harmony_v1.sql(HARMONY 데이터셋) 적재
--
-- 읽는 법
--   -- ======  구분선     이 줄부터 새 예제입니다
--   주석 없는 SQL           그대로 실행하면 됩니다
--   ▶ 실행해 보세요       실행해도 됩니다. 무엇을 보게 될지 같은 줄에 적어 두었습니다
-- ============================================

-- ============================================================
-- 예제 1 · [E.1] UNION 기본 문법
-- ============================================================

-- ▶ 실행해 보세요 — 대괄호는 자리를 표시한 것이라 그대로 실행하면 문법 에러가 납니다
SELECT 칼럼 FROM 테이블 WHERE 조건1
UNION
SELECT 칼럼 FROM 테이블 WHERE 조건2;

-- ============================================================
-- 예제 2 · [E.2] K-POP과 발라드 아티스트 합치기
-- ============================================================

SELECT artist_name, genre
FROM artists
WHERE genre='K-POP'
UNION
SELECT artist_name, genre
FROM artists
WHERE genre='Ballad'
LIMIT 3;

-- ============================================================
-- 예제 3 · [E.3] UNION - 중복 제거 (첫 쿼리)
-- ============================================================

SELECT genre FROM artists WHERE artist_id=1
UNION
SELECT genre FROM artists WHERE artist_id=2;

-- ============================================================
-- 예제 4 · [E.4] UNION ALL - 중복 포함
-- ============================================================

SELECT genre FROM artists WHERE artist_id=1
UNION ALL
SELECT genre FROM artists WHERE artist_id=2;

-- ============================================================
-- 예제 5 · [E.5] 칼럼 개수 맞추기 - 에러 예제
-- ============================================================

-- ▶ 실행해 보세요 — 위아래 SELECT의 칼럼 수가 달라 "different number of columns" 에러가 납니다
-- Error: top has 2 columns, bottom has 1
SELECT artist_name, genre FROM artists
UNION
SELECT track_name FROM tracks;

-- ============================================================
-- 예제 6 · [E.6] 칼럼 개수 맞추기 - 정상 작동
-- ============================================================

-- Both queries return 1 column
SELECT artist_name FROM artists
UNION
SELECT track_name FROM tracks;

-- ============================================================
-- 예제 7 · [E.7] ORDER BY는 맨 마지막에
-- ============================================================

SELECT artist_name, debut_date
FROM artists
WHERE artist_type='GROUP'
UNION
SELECT artist_name, debut_date
FROM artists
WHERE artist_type='SOLO'
ORDER BY debut_date DESC
LIMIT 3;

-- ============================================================
-- 예제 8 · [부록 E] GROUP BY 결과에 전체 합계 행 추가
-- ============================================================

SELECT platform, SUM(play_count)
FROM streaming
WHERE stream_date >='2026-07-01'
GROUP BY platform

UNION ALL

SELECT '전체 합계', SUM(play_count)
FROM streaming
WHERE stream_date >='2026-07-01';

-- ============================================================
-- 예제 9 · [E.8] UNION 대신 IN으로 대체 가능
-- ============================================================

SELECT artist_name, genre
FROM artists
WHERE genre IN('K-POP', 'Ballad');

-- ============================================================
-- 예제 10 · [E.9] 서로 다른 테이블의 데이터를 합칠 때
-- ============================================================

-- ▶ 실행해 보세요 — 설명용 가상 테이블이라 "doesn't exist" 에러가 납니다
SELECT order_id, order_date, total_amount
FROM orders_2025
WHERE total_amount >=100000
UNION ALL
SELECT order_id, order_date, total_amount
FROM orders_2026
WHERE total_amount >=100000;

-- ============================================================
-- 예제 11 · [E.10] 집계 결과에 총계 행을 추가할 때
-- ============================================================

SELECT platform, SUM(play_count) AS `total_plays`
FROM streaming
WHERE stream_date >= '2026-07-01'
GROUP BY platform
UNION ALL
SELECT 'total', SUM(play_count)
FROM streaming
WHERE stream_date >= '2026-07-01';
