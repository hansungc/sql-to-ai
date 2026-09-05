-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- 부록 J  JSON 심화 - 배열 펼치기, 키 통합, 패턴 매칭
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
-- 예제 1 · [배열 데이터 확인하기] JSON_EXTRACT로 배열 데이터 확인하기
-- ============================================================

SELECT
  platform AS `플랫폼`,
  JSON_EXTRACT(reaction_data, '$.keywords') AS `키워드 배열`
FROM sns_reactions
WHERE artist_id=1
LIMIT 3;

-- ============================================================
-- 예제 2 · [JSON_TABLE로 배열 펼치기] JSON_TABLE로 배열을 행으로 펼치기
-- ============================================================

SELECT
  sr.platform AS `플랫폼`,
  jt.keyword AS `키워드`
FROM sns_reactions sr,
  JSON_TABLE(
     JSON_EXTRACT(sr.reaction_data, '$.keywords'),
     '$[*]' COLUMNS(keyword VARCHAR(50) PATH '$')
  ) AS `jt`
WHERE sr.reaction_id=1;

-- ============================================================
-- 예제 3 · [키워드별 빈도 집계] 키워드별 빈도 집계하기
-- ============================================================

SELECT
  jt.keyword AS `키워드`,
  COUNT(*) AS `등장 횟수`
FROM sns_reactions sr,
  JSON_TABLE(
     JSON_EXTRACT(sr.reaction_data, '$.keywords'),
     '$[*]' COLUMNS(keyword VARCHAR(50) PATH '$')
  ) AS `jt`
WHERE sr.artist_id=1
GROUP BY jt.keyword
ORDER BY `등장 횟수` DESC
LIMIT 5;

-- ============================================================
-- 예제 4 · [플랫폼마다 다른 키 통합] COALESCE로 플랫폼마다 다른 키 통합하기
-- ============================================================

SELECT
  platform AS `플랫폼`,
  CAST(JSON_EXTRACT(reaction_data, '$.likes') AS UNSIGNED) AS `좋아요`,
  COALESCE(
     CAST(JSON_EXTRACT(reaction_data, '$.retweets') AS UNSIGNED),
     CAST(JSON_EXTRACT(reaction_data, '$.shares') AS UNSIGNED),
     0
  ) AS `공유 수`
FROM sns_reactions
WHERE artist_id=1
LIMIT 4;

-- ============================================================
-- 예제 5 · [JSON 값에서 패턴 찾기] LIKE로 JSON 값에서 패턴 찾기
-- ============================================================

SELECT
  platform AS `플랫폼`,
  DATE(posted_datetime) AS `게시일`,
  JSON_EXTRACT(reaction_data, '$.keywords') AS `키워드`
FROM sns_reactions
WHERE JSON_EXTRACT(reaction_data, '$.keywords') LIKE '%dance%'
LIMIT 3;

-- ============================================================
-- 예제 6 · [여러 패턴 동시에 찾기] 여러 패턴을 한 번에 찾기
-- ============================================================

SELECT
  platform AS `플랫폼`,
  DATE(posted_datetime) AS `게시일`,
  JSON_EXTRACT(reaction_data, '$.keywords') AS `키워드`
FROM sns_reactions
WHERE JSON_EXTRACT(reaction_data, '$.keywords') LIKE '%comeback%'
 OR JSON_EXTRACT(reaction_data, '$.keywords') LIKE '%viral%'
LIMIT 3;
