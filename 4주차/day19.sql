-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 19  "이 숫자, 뭘 더 알려 줄 수 있지?" - Exploratory Analysis
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
-- ============================================

-- ============================================================
-- 예제 1 · [19.1] 업계 벤치마크 테이블 살펴보기
-- ============================================================

SELECT *
FROM industry_benchmarks
WHERE category='K-POP';

-- ============================================================
-- 예제 2 · [19.1] 컨텍스트 전달용 프롬프트 템플릿
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[이전 결과]
분석 대상과 핵심 수치

[분석 목표]
알고 싶은 것을 질문 형태로

[분석 조건]
비교할 대상, 확인할 항목, 필터 조건 등을 자연어로 작성

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.

[결과 형식]
출력할 칼럼과 정렬 기준
*/

-- ============================================================
-- 예제 3 · [19.1] 분석 결과를 컨텍스트로 정리 요청
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
지금까지 분석한 결과를 아래 형식으로 정리해 줘.
다음 분석에서 컨텍스트로 사용할 거야.
형식:
- 분석 대상:
- 기간:
- 핵심 수치: (항목별로)
- 발견된 패턴:
*/

-- ============================================================
-- 예제 4 · [19.2] 아티스트별 7월 스트리밍 현황
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: streaming(stream_id, fan_id, track_id, stream_date, play_count)
테이블: tracks(track_id, album_id)
테이블: albums(album_id, artist_id)
테이블: artists(artist_id, artist_name)

[연결 관계]
streaming.track_id→tracks→albums→artists(각각 ID로 연결)

[요청]
아티스트별 2026년 7월 총 스트리밍 횟수를 조회해 줘.
play_count 합계 기준 내림차순 정렬

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT a.artist_name       AS `아티스트`
   , SUM(s.play_count)     AS `총 스트리밍`
FROM streaming s
INNER JOIN tracks t ON s.track_id=t.track_id
INNER JOIN albums al ON t.album_id=al.album_id
INNER JOIN artists a ON al.artist_id=a.artist_id
WHERE s.stream_date >= '2026-07-01'
 AND s.stream_date < '2026-08-01'
GROUP BY a.artist_id, a.artist_name
ORDER BY `총 스트리밍` DESC;

-- ============================================================
-- 예제 5 · [19.2] 아티스트별 스트리밍 vs. 업계 평균 비교
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[이전 결과]
아티스트별 7월 스트리밍:
- Celestial: 892,500
- StarLight: 756,000
- Phoenix: 623,000
- Luna Eclipse: 412,000
- Nova Stars: 385,000

[분석 목표]
각 아티스트가 업계 평균 대비 몇 %인지 알고 싶어.

[분석 조건]
industry_benchmarks 테이블의 K-POP 월 평균 스트리밍과 비교해 줘.
metric_name='avg_monthly_streams', category='K-POP' 조건이야.

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.

[결과 형식]
아티스트명, 스트리밍 수치, 업계 평균, 달성률(%)
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
WITH artist_streams AS(
    SELECT a.artist_id
       , a.artist_name
       , SUM(s.play_count) AS `total_streams`
    FROM streaming s
    INNER JOIN tracks t ON s.track_id=t.track_id
    INNER JOIN albums al ON t.album_id=al.album_id
    INNER JOIN artists a ON al.artist_id=a.artist_id
    WHERE s.stream_date >= '2026-07-01'
     AND s.stream_date < '2026-08-01'
    GROUP BY a.artist_id, a.artist_name
 )
 , benchmark AS(
    SELECT benchmark_value
    FROM industry_benchmarks
    WHERE metric_name='avg_monthly_streams'
     AND category='K-POP'
 )
 SELECT artist_name                AS `아티스트`
    , total_streams                AS `스트리밍`
    , b.benchmark_value            AS `업계 평균`
    , ROUND(`total_streams` * 100.0
         /b.benchmark_value, 1) AS `달성률`
 FROM artist_streams
 CROSS JOIN benchmark b
 ORDER BY `달성률` DESC;

-- ============================================================
-- 예제 6 · [19.2] 7월 22일 이후 신규 앨범 확인
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[이전 결과]
Celestial: 105.0%(업계 평균 초과)
Phoenix: 73.3%(업계 평균 미달)

[분석 목표]
두 아티스트의 차이 원인을 분석해 줘.

[분석 조건]
7월 22일 이후 발매된 앨범이 있는지 확인해 줘(신곡 효과).

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.

[결과 형식]
아티스트별로 비교할 수 있게 정리해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT a.artist_name           AS `아티스트`
   , COUNT(al.album_id)        AS `앨범 수`
FROM albums al
INNER JOIN artists a ON al.artist_id=a.artist_id
WHERE al.release_date >= '2026-07-22'
 AND al.release_date < '2026-08-01'
 AND a.artist_name IN('Celestial', 'Phoenix')
GROUP BY a.artist_id, a.artist_name;

-- ============================================================
-- 예제 7 · [19.2] 7월 활성 트랙 수 비교
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[이전 결과]
Celestial: 7월 신규 앨범 1개 발매
Phoenix: 7월 신규 앨범 없음

[분석 목표]
활성 트랙 수도 차이가 나는지 확인해 줘.

[분석 조건]
Celestial과 Phoenix의 7월 스트리밍된 고유 트랙 수를 비교해 줘.

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT a.artist_name             AS `아티스트`
    , COUNT(DISTINCT s.track_id) AS `활성 트랙 수`
 FROM streaming s
 INNER JOIN tracks t ON s.track_id=t.track_id
 INNER JOIN albums al ON t.album_id=al.album_id
 INNER JOIN artists a ON al.artist_id=a.artist_id
 WHERE s.stream_date >= '2026-07-01'
  AND s.stream_date < '2026-08-01'
  AND a.artist_name IN('Celestial', 'Phoenix')
 GROUP BY a.artist_id, a.artist_name;

-- ============================================================
-- 예제 8 · [19.2] 6월 vs. 7월 스트리밍 증감률 비교
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[이전 결과]
Phoenix: 업계 평균 73.3%, 신곡 없음, 활성 트랙 2곡

[분석 목표]
Phoenix가 정체 상태인지 검증해 줘.

[분석 조건]
Phoenix의 6월 vs. 7월 스트리밍 변화를 확인해 줘.
다른 아티스트들과 증감률도 비교해 줘.

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.

[결과 형식]
아티스트별 6월, 7월 수치와 증감률(%)을 정렬해서 보여 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
WITH monthly_streams AS(
   SELECT a.artist_name
     , CASE
         WHEN s.stream_date >= '2026-06-01'
         AND s.stream_date < '2026-07-01' THEN '6월'
         WHEN s.stream_date >= '2026-07-01'
         AND s.stream_date < '2026-08-01' THEN '7월'
       END AS `월`
     , SUM(s.play_count)        AS `스트리밍`
   FROM streaming s
   INNER JOIN tracks t ON s.track_id=t.track_id
   INNER JOIN albums al ON t.album_id=al.album_id
   INNER JOIN artists a ON al.artist_id=a.artist_id
   WHERE s.stream_date >= '2026-06-01'
    AND s.stream_date < '2026-08-01'
   GROUP BY a.artist_id, a.artist_name, `월`
)
SELECT m6.artist_name         AS `아티스트`
  , m6.스트리밍                   AS `6월`
  , m7.스트리밍                   AS `7월`
  , ROUND((m7.스트리밍-m6.스트리밍) * 100.0/m6.`스트리밍`, 1) AS `증감률`
 FROM monthly_streams m6
 INNER JOIN monthly_streams m7
   ON m6.artist_name=m7.artist_name
 WHERE m6.`월`='6월'
  AND m7.`월`='7월'
 ORDER BY `증감률` DESC;

-- ============================================================
-- 예제 9 · [19.3] 분석 결과 종합 정리 요청
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[분석 목표]
지금까지 분석한 결과를 정리해 줘.

[결과 형식]
주제별로 묶어서(스트리밍, 팬 활동, 콘서트, 굿즈, 업계 비교) 각 항목은 핵심 수치와 의미를 한 줄로 정리해 줘.
*/

-- ============================================================
-- 예제 10 · [19.3] 경영진 보고용 핵심 발견 정리 요청
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[이전 결과]
Celestial: 신곡 효과로 업계 평균 105%, 신규 팬 유입 증가
Phoenix: 업계 평균 73%, 성장률 1.3% 최하위
Phoenix 굿즈 구매자: 43%가 해외 팬

[분석 목표]
경영진 보고용으로 핵심 발견을 정리해 줘.

[결과 형식]
각 발견은 "현황→의미→제안" 형식으로 정리해 줘.
*/

-- ============================================================
-- 예제 11 · [19.3] 스스로 해보기 - 프롬프트 작성 가이드
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[이전 결과]
(직전 단계의 핵심 수치)

[분석 목표]
(알고 싶은 것을 질문으로)

[분석 조건]
(비교 대상이나 확인할 항목)

[지침 참조]
지침 파일에 등록된 스키마 정보와 팀 코딩 컨벤션을 적용해 줘.
*/
