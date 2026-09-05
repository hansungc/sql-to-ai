-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 4  플랫폼별 팬 분포 현황 - GROUP BY
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
--   ✕ 실행하지 마세요       일부러 주석 처리한 SQL입니다. 사유는 같은 줄에 적어 두었습니다
-- ============================================

-- ============================================================
-- 예제 1 · [4.1] GROUP BY의 기본 문법
-- ============================================================

-- ▶ 실행해 보세요 — 대괄호는 자리를 표시한 것이라 그대로 실행하면 문법 에러가 납니다
SELECT
  그룹화할_칼럼,
  집계 함수(칼럼) AS `별칭`
FROM 테이블명
WHERE 조건
GROUP BY 그룹화할_칼럼
ORDER BY 정렬 기준;

-- ============================================================
-- 예제 2 · [4.1] 플랫폼별 스트리밍 집계
-- ============================================================

SELECT
  platform,
  COUNT(*) AS `session_count`
FROM streaming
GROUP BY platform
ORDER BY `session_count` DESC
LIMIT 3;

-- ============================================================
-- 예제 3 · [4.1] Universe만 분석하기
-- ============================================================

SELECT
  platform,
  COUNT(*) AS `universe_sessions`
FROM streaming
WHERE track_id=93 -- Universe 트랙 ID
  AND stream_date='2026-07-22'
GROUP BY platform
ORDER BY `universe_sessions` DESC
LIMIT 3;

-- ============================================================
-- 예제 4 · [4.1] 날짜별 스트리밍 추이
-- ============================================================

SELECT
  stream_date,
  COUNT(*) AS `세션 수`
FROM streaming
WHERE stream_date BETWEEN '2026-07-01' AND '2026-07-10'
GROUP BY stream_date
ORDER BY stream_date
LIMIT 3;

-- ============================================================
-- 예제 5 · [4.1] 시간대별 재생 패턴
-- ============================================================

SELECT
  HOUR(stream_datetime) AS `시간대`,
  COUNT(*) AS `세션 수`
FROM streaming
WHERE stream_date BETWEEN '2026-07-01' AND '2026-07-31'
GROUP BY HOUR(stream_datetime)
ORDER BY `세션 수` DESC
LIMIT 3;

-- ============================================================
-- 예제 6 · [4.1] 시간대별 재생 패턴 (데이터베이스별 함수)
-- ============================================================

-- ✕ 실행하지 마세요 — 다른 DBMS에서 같은 일을 하는 함수를 비교한 메모입니다. MySQL에서는 실행하지 않습니다
-- -- MySQL, Snowflake: HOUR(stream_datetime)
-- -- PostgreSQL, BigQuery: EXTRACT(HOUR FROM stream_datetime)

-- ============================================================
-- 예제 7 · [4.1] 유형별 아티스트 분포
-- ============================================================

SELECT
  artist_type,
  COUNT(*) AS `artist_count`
FROM artists
GROUP BY artist_type;

-- ============================================================
-- 예제 8 · [4.1] 전체 재생 세션 수(중복 포함)
-- ============================================================

SELECT COUNT(*) FROM streaming WHERE platform='Melon';

-- ============================================================
-- 예제 9 · [4.1] 실제로 들은 팬 수(중복 제거)
-- ============================================================

SELECT COUNT(DISTINCT fan_id) FROM streaming WHERE platform='Melon';

-- ============================================================
-- 예제 10 · [4.2] 플랫폼별 세션 수
-- ============================================================

SELECT
  platform,
  COUNT(*) AS `session_count`
FROM streaming
GROUP BY platform
LIMIT 3;

-- ============================================================
-- 예제 11 · [4.2] SUM으로 합계 구하기
-- ============================================================

SELECT
  platform,
  COUNT(*) AS `session_count`,
  SUM(play_count) AS `total_plays`
FROM streaming
WHERE stream_date='2026-07-22'
GROUP BY platform
ORDER BY `total_plays` DESC
LIMIT 3;

-- ============================================================
-- 예제 12 · [4.2] AVG로 평균 구하기
-- ============================================================

SELECT
  platform,
  COUNT(*) AS `session_count`,
  SUM(play_count) AS `total_plays`,
  ROUND(AVG(play_count), 1) AS `avg_plays`
FROM streaming
WHERE stream_date='2026-07-22'
GROUP BY platform
ORDER BY `avg_plays` DESC
LIMIT 3;

-- ============================================================
-- 예제 13 · [4.2] MAX, MIN으로 최댓값, 최솟값 찾기
-- ============================================================

SELECT
  platform,
  COUNT(*) AS `세션 수`,
  MAX(play_count) AS `최대 재생`,
  MIN(play_count) AS `최소 재생`,
  ROUND(AVG(play_count), 1) AS `평균 재생`
FROM streaming
WHERE stream_date='2026-07-22'
GROUP BY platform
ORDER BY `최대 재생` DESC
LIMIT 3;

-- ============================================================
-- 예제 14 · [4.2] 한 칼럼으로 그룹화하기
-- ============================================================

SELECT
  track_id,
  COUNT(*) AS `play_sessions`,
  SUM(play_count) AS `total_plays`,
  ROUND(AVG(play_count), 1) AS `avg_plays`
FROM streaming
WHERE stream_date='2026-07-22'
GROUP BY track_id
ORDER BY `total_plays` DESC
LIMIT 3;

-- ============================================================
-- 예제 15 · [4.2] 여러 칼럼으로 그룹화하기
-- ============================================================

SELECT
  platform,
  track_id,
  COUNT(*) AS `sessions`,
  SUM(play_count) AS `total_plays`
FROM streaming
WHERE track_id=93
  AND stream_date='2026-07-22'
GROUP BY platform, track_id
ORDER BY `total_plays` DESC
LIMIT 3;

-- ============================================================
-- 예제 16 · [4.2] 일별 핵심 지표 대시보드
-- ============================================================

SELECT
  stream_date AS `날짜`,
  COUNT(*) AS `세션 수`,
  SUM(play_count) AS `총 재생`,
  ROUND(AVG(play_count), 1) AS `평균 재생`,
  MAX(play_count) AS `최대 재생`
FROM streaming
WHERE stream_date BETWEEN '2026-07-22' AND '2026-07-24'
GROUP BY stream_date
ORDER BY stream_date;

-- ============================================================
-- 예제 17 · [4.2] 팬별 집계로 헤비 유저 파악하기
-- ============================================================

SELECT
  fan_id,
  COUNT(*) AS `sessions`,
  SUM(play_count) AS `total_plays`,
  ROUND(AVG(play_count), 1) AS `avg_plays`
FROM streaming
WHERE stream_date='2026-07-22'
GROUP BY fan_id
ORDER BY `total_plays` DESC
LIMIT 3;

-- ============================================================
-- 예제 18 · [4.3] 플랫폼별 Universe 성과
-- ============================================================

SELECT
  platform,
  COUNT(*) AS `sessions`,
  SUM(play_count) AS `total_plays`,
  ROUND(AVG(play_count), 1) AS `avg_plays`
FROM streaming
WHERE track_id=93
  AND stream_date='2026-07-22'
GROUP BY platform
ORDER BY `total_plays` DESC;

-- ============================================================
-- 예제 19 · [4.3] 시간대별 패턴 분석
-- ============================================================

SELECT
  HOUR(stream_datetime) AS `시간대`,
  COUNT(*) AS `세션 수`,
  SUM(play_count) AS `총 재생`
FROM streaming
WHERE track_id=93
  AND stream_date='2026-07-22'
GROUP BY HOUR(stream_datetime)
ORDER BY `시간대`;

-- ============================================================
-- 예제 20 · [4.3] 시간대별 패턴 분석 (데이터베이스별 함수)
-- ============================================================

-- ✕ 실행하지 마세요 — 다른 DBMS에서 같은 일을 하는 함수를 비교한 메모입니다. MySQL에서는 실행하지 않습니다
-- -- MySQL: HOUR(칼럼)
-- -- PostgreSQL, BigQuery: EXTRACT(HOUR FROM 칼럼)

-- ============================================================
-- 예제 21 · [4.3] 점유율 계산하기
-- ============================================================

SELECT
  platform,
  SUM(play_count) AS `plays`,
  ROUND(SUM(play_count) * 100.0/212, 1) AS `share_pct`
FROM streaming
WHERE track_id=93
  AND stream_date='2026-07-22'
GROUP BY platform
ORDER BY `plays` DESC
LIMIT 3;

-- ============================================================
-- 예제 22 · [4.3] 글로벌 팬 분포 분석
-- ============================================================

SELECT
  country AS `국가`,
  COUNT(*) AS `팬 수`,
  ROUND(COUNT(*) * 100.0/111, 1) AS `비율`
FROM fans
GROUP BY country
ORDER BY `팬 수` DESC
LIMIT 5;

-- ============================================================
-- 예제 23 · [4.3] Universe 전체 성과 한 줄 요약
-- ============================================================

SELECT
  'Universe 발매일 성과' AS `항목`,
  COUNT(*) AS `총세션`,
  SUM(play_count) AS `총 재생`,
  ROUND(AVG(play_count), 1) AS `평균 재생`
FROM streaming
WHERE track_id=93
  AND stream_date='2026-07-22';

-- ============================================================
-- 예제 24 · [4.3] 플랫폼별 종합 대시보드
-- ============================================================

SELECT
  platform,
  COUNT(*) AS `세션 수`,
  SUM(play_count) AS `총 재생`,
  ROUND(AVG(play_count), 1) AS `평균 재생`,
  ROUND(SUM(play_count) * 100.0/212, 1) AS `점유율`
FROM streaming
WHERE track_id=93
  AND stream_date='2026-07-22'
GROUP BY platform
ORDER BY `총 재생` DESC;
