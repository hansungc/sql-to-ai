-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 10  'SNS 반응 데이터에서 인사이트 찾기' - JSON 데이터
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
-- ============================================

-- ============================================================
-- 예제 1 · [10.1] JSON에서 원하는 값 꺼내기 - 원본 데이터 확인
-- ============================================================

SELECT
  platform AS `플랫폼`,
  posted_datetime AS `게시 시간`,
  reaction_data AS `JSON 데이터`
FROM sns_reactions
WHERE artist_id=1
LIMIT 3;

-- ============================================================
-- 예제 2 · [10.1] JSON에서 값 꺼내기 - 기본 추출
-- ============================================================

SELECT
  platform AS `플랫폼`,
  JSON_EXTRACT(reaction_data, '$.likes') AS `좋아요`
FROM sns_reactions
WHERE artist_id=1
LIMIT 3;

-- ============================================================
-- 예제 3 · [10.1] 여러 값 동시에 꺼내기
-- ============================================================

SELECT
  platform AS `플랫폼`,
  JSON_EXTRACT(reaction_data, '$.likes') AS `좋아요`,
  JSON_EXTRACT(reaction_data, '$.comments') AS `댓글 수`,
  JSON_EXTRACT(reaction_data, '$.sentiment') AS `감정`
FROM sns_reactions
WHERE artist_id=1
LIMIT 3;

-- ============================================================
-- 예제 4 · [10.1] 좋아요 많은 순으로 정렬하기
-- ============================================================

SELECT
  platform AS `플랫폼`,
  JSON_EXTRACT(reaction_data, '$.likes') AS `좋아요`
FROM sns_reactions
WHERE artist_id=1
ORDER BY JSON_EXTRACT(reaction_data, '$.likes') DESC
LIMIT 3;

-- ============================================================
-- 예제 5 · [10.1] 플랫폼별 합계 계산하기 - CAST 없이
-- ============================================================

SELECT
  platform AS `플랫폼`,
  SUM(JSON_EXTRACT(reaction_data, '$.likes')) AS `좋아요 합계`
FROM sns_reactions
WHERE artist_id=1
GROUP BY platform
ORDER BY `좋아요 합계` DESC;

-- ============================================================
-- 예제 6 · [10.1] 플랫폼별 합계 계산하기 - CAST 적용
-- ============================================================

SELECT
  platform AS `플랫폼`,
  SUM(CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED)) AS `좋아요 합계`
FROM sns_reactions
WHERE artist_id=1
GROUP BY platform
ORDER BY `좋아요 합계` DESC;

-- ============================================================
-- 예제 7 · [10.2] 플랫폼별 좋아요 집계
-- ============================================================

SELECT
  platform AS `플랫폼`,
  COUNT(*) AS `게시물 수`,
  SUM(CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED)) AS `총 좋아요`,
  ROUND(AVG(CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED)), 0) AS `평균 좋아요`
FROM sns_reactions
WHERE artist_id=1
GROUP BY platform
ORDER BY `총 좋아요` DESC;

-- ============================================================
-- 예제 8 · [10.2] 플랫폼별 댓글 수도 함께 보기
-- ============================================================

SELECT
  platform AS `플랫폼`,
  SUM(CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED)) AS `총 좋아요`,
  SUM(CAST(JSON_EXTRACT(reaction_data, '$.comments') AS UNSIGNED)) AS `총 댓글`
FROM sns_reactions
WHERE artist_id=1
GROUP BY platform
ORDER BY `총 좋아요` DESC;

-- ============================================================
-- 예제 9 · [10.2] 좋아요 10만 개 이상 게시물 찾기
-- ============================================================

SELECT
  platform AS `플랫폼`,
  DATE(posted_datetime) AS `게시일`,
  CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED) AS `좋아요`,
  JSON_EXTRACT(reaction_data, '$.sentiment') AS `감정`
FROM sns_reactions
WHERE artist_id=1
  AND CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED) >= 100000
ORDER BY `좋아요` DESC
LIMIT 5;

-- ============================================================
-- 예제 10 · [10.2] 따옴표 제거하기 - JSON_UNQUOTE 적용
-- ============================================================

SELECT
  platform AS `플랫폼`,
  DATE(posted_datetime) AS `게시일`,
  CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED) AS `좋아요`,
  JSON_UNQUOTE(JSON_EXTRACT(reaction_data, '$.sentiment')) AS `감정`
FROM sns_reactions
WHERE artist_id=1
  AND CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED) >= 100000
ORDER BY `좋아요` DESC
LIMIT 5;

-- ============================================================
-- 예제 11 · [10.2] 함수 두 개를 겹쳐 쓰는 방식
-- ============================================================

SELECT JSON_UNQUOTE(JSON_EXTRACT(reaction_data, '$.sentiment')) AS `감성`
FROM sns_reactions
WHERE artist_id=1
LIMIT 3;

-- ============================================================
-- 예제 12 · [10.2] ->> 연산자로 같은 결과를 간결하게
-- ============================================================

SELECT reaction_data ->> '$.sentiment' AS `감성`
FROM sns_reactions
WHERE artist_id=1
LIMIT 3;

-- ============================================================
-- 예제 13 · [10.2] 문자열 값으로 필터링하기
-- ============================================================

SELECT
  platform AS `플랫폼`,
  DATE(posted_datetime) AS `게시일`,
  CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED) AS `좋아요`
FROM sns_reactions
WHERE artist_id=1
  AND reaction_data ->> '$.sentiment' = 'mixed'
ORDER BY `게시일`;

-- ============================================================
-- 예제 14 · [10.2] 긍정 반응이면서 댓글이 많은 게시물
-- ============================================================

SELECT
  platform AS `플랫폼`,
  CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED) AS `좋아요`,
  CAST(JSON_EXTRACT(reaction_data, '$.comments') AS UNSIGNED) AS `댓글 수`
FROM sns_reactions
WHERE artist_id=1
  AND reaction_data ->> '$.sentiment' = 'positive'
  AND CAST(JSON_EXTRACT(reaction_data, '$.comments') AS UNSIGNED) >= 5000
ORDER BY `댓글 수` DESC
LIMIT 3;

-- ============================================================
-- 예제 15 · [10.3] 플랫폼별 종합 지표
-- ============================================================

SELECT
  platform AS `플랫폼`,
  COUNT(*) AS `게시물 수`,
  SUM(CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED)) AS `총 좋아요`,
  SUM(CAST(JSON_EXTRACT(reaction_data, '$.comments') AS UNSIGNED)) AS `총 댓글`,
  ROUND(SUM(CAST(JSON_EXTRACT(reaction_data, '$.comments') AS UNSIGNED)) * 100.0 /
    SUM(CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED)), 2) AS `댓글 비율`
FROM sns_reactions
WHERE artist_id=1
GROUP BY platform
ORDER BY `총 좋아요` DESC;

-- ============================================================
-- 예제 16 · [10.3] 전체 감정 분포
-- ============================================================

SELECT
  reaction_data ->> '$.sentiment' AS `감정`,
  COUNT(*) AS `건수`,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM sns_reactions WHERE artist_id=1), 1) AS `비율`
FROM sns_reactions
WHERE artist_id=1
GROUP BY reaction_data ->> '$.sentiment'
ORDER BY `건수` DESC;

-- ============================================================
-- 예제 17 · [10.3] 플랫폼별 감정 분포
-- ============================================================

SELECT
  platform AS `플랫폼`,
  reaction_data ->> '$.sentiment' AS `감정`,
  COUNT(*) AS `건수`
FROM sns_reactions
WHERE artist_id=1
GROUP BY platform, reaction_data ->> '$.sentiment'
ORDER BY platform, `건수` DESC;

-- ============================================================
-- 예제 18 · [10.3] mixed 감정 게시물 상세 확인
-- ============================================================

SELECT
  platform AS `플랫폼`,
  DATE(posted_datetime) AS `게시일`,
  CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED) AS `좋아요`,
  CAST(JSON_EXTRACT(reaction_data, '$.comments') AS UNSIGNED) AS `댓글 수`,
  reaction_data ->> '$.sentiment' AS `감정`
FROM sns_reactions
WHERE artist_id=1
  AND reaction_data ->> '$.sentiment' = 'mixed'
ORDER BY `게시일`;

-- ============================================================
-- 예제 19 · [10.3] 댓글 비율이 높은 게시물
-- ============================================================

SELECT
  platform AS `플랫폼`,
  DATE(posted_datetime) AS `게시일`,
  CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED) AS `좋아요`,
  CAST(JSON_EXTRACT(reaction_data, '$.comments') AS UNSIGNED) AS `댓글 수`,
  ROUND(CAST(JSON_EXTRACT(reaction_data, '$.comments') AS UNSIGNED) * 100.0 /
    CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED), 1) AS `댓글 비율`,
  reaction_data ->> '$.sentiment' AS `감정`
FROM sns_reactions
WHERE artist_id=1
ORDER BY `댓글 비율` DESC
LIMIT 3;
