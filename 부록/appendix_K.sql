-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- 부록 K  AI와 함께 생각하기 - CoT 프롬프팅
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
-- 예제 1 · [Zero-Shot CoT] 스키마 정보
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
테이블: daily_charts(chart_id, track_id, chart_date, chart_rank, daily_streams)
테이블: tracks(track_id, track_name, album_id)
테이블: albums(album_id, album_name, artist_id)
테이블: artists(artist_id, artist_name)
*/

-- ============================================================
-- 예제 2 · [Zero-Shot CoT] 프롬프트 요청
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
2026년 7월 한 달 동안 차트 1위를 가장 많이 차지한 아티스트를 구해 줘.
*/

-- ============================================================
-- 예제 3 · [Zero-Shot CoT] AI 응답 - 최종 SQL
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[단계별 접근]
1. 필요한 테이블과 JOIN 경로를 먼저 설명해 줘.
2. 필터 조건(WHERE)을 정리해 줘.
3. 집계 및 정렬 방법을 설명해 줘.
4. 최종 SQL을 작성해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT
   a.artist_name,
   COUNT(*) AS `top1_count`
FROM daily_charts dc
JOIN tracks t ON dc.track_id =t.track_id
JOIN albums al ON t.album_id =al.album_id
JOIN artists a ON al.artist_id=a.artist_id
WHERE dc.chart_rank=1
 AND dc.chart_date BETWEEN '2026-07-01' AND '2026-07-31'
GROUP BY a.artist_id, a.artist_name
ORDER BY `top1_count` DESC
LIMIT 1;

-- ============================================================
-- 예제 4 · [Few-Shot CoT] 패턴 예시 SQL
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
테이블: streaming(stream_id, track_id, stream_date, play_count)

[패턴 예시]
요청: 2025년 월별 총 스트리밍 수를 구해 줘.

단계별 접근:
1. 필요한 테이블과 JOIN 경로: streaming 테이블 단독 사용, JOIN 불필요
2. 필터 조건(WHERE): YEAR(stream_date)=2025로 연도 필터링
3. 집계 및 정렬: MONTH()로 월 추출 후 GROUP BY, play_count를 SUM, 월 오름차순 정렬
   (WHERE에서 연도를 먼저 필터링했으므로 월 정렬만으로 충분합니다.)

SQL:
(아래 [Few-Shot CoT] 패턴 예시 SQL을 그대로 붙여 넣습니다)

[요청]
위 단계별 출력 구조를 그대로 따라서 아래 요청의 SQL을 작성해 줘.
요청: 2026년 월별 총 스트리밍 수를 구해 줘.
*/

-- ▼ AI가 만든 SQL  ▶ 실행해서 결과를 비교하세요
SELECT YEAR(stream_date) AS `stream_year`,
     MONTH(stream_date) AS `stream_month`,
     SUM(play_count) AS `total_streams`
FROM streaming
WHERE YEAR(stream_date)=2025
GROUP BY YEAR(stream_date), MONTH(stream_date)
ORDER BY MONTH(stream_date);

-- ============================================================
-- 예제 5 · [실무 프롬프트 템플릿] 복잡한 SQL 분석 요청
-- ============================================================

-- ▼ 프롬프트 (/* */ 안을 그대로 복사해 AI에 입력)
/*
[스키마 정보]
(테이블 구조 입력)

[요청]
(분석 요청 입력)

[단계별 접근]
1. 필요한 테이블과 JOIN 경로를 먼저 파악해 줘.
2. 필터 조건(WHERE)을 정리해 줘.
3. 집계나 정렬이 필요하면 방법을 설명해 줘.
4. 위 분석을 바탕으로 최종 SQL을 작성해 줘.
*/
