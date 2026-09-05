-- ============================================
-- 『SQL부터 AI까지 데이터 분석 With 클로드 코드』 실습 파일
-- Day 8  "팬사인회, 투자 대비 정말 남는 장사일까?" - WITH(CTE)
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
-- 예제 1 · [8.1] 3단계 중첩 서브쿼리 예제
-- ============================================================

SELECT p.product_name, `revenue`
FROM(
  SELECT product_id, SUM(total_amount) AS `revenue`
  FROM(
    SELECT product_id, total_amount
    FROM orders
    WHERE order_date BETWEEN '2026-07-22' AND '2026-07-31'
  ) AS `july_data`
  GROUP BY product_id
) AS `product_totals`
JOIN products p ON product_totals.product_id=p.product_id
WHERE `revenue` >=100000
ORDER BY `revenue` DESC;

-- ============================================================
-- 예제 2 · [8.1] 기본 CTE: 7월 주문 데이터
-- ============================================================

WITH july_orders AS(
  SELECT order_id, fan_id, product_id, total_amount
  FROM orders
  WHERE order_date BETWEEN '2026-07-22' AND '2026-07-31'
)
SELECT * FROM july_orders
ORDER BY total_amount DESC
LIMIT 3;

-- ============================================================
-- 예제 3 · [8.1] CTE 안에서 집계: 상품별 매출
-- ============================================================

WITH product_revenue AS(
  SELECT
    product_id,
    SUM(total_amount) AS `revenue`,
    COUNT(*) AS `order_count`
  FROM orders
  WHERE order_date BETWEEN '2026-07-22' AND '2026-07-31'
  GROUP BY product_id
)
SELECT * FROM product_revenue
ORDER BY `revenue` DESC
LIMIT 3;

-- ============================================================
-- 예제 4 · [8.1] CTE 결과에 테이블 조인하기
-- ============================================================

WITH product_revenue AS(
  SELECT product_id, SUM(total_amount) AS `revenue`, COUNT(*) AS `order_count`
  FROM orders
  WHERE order_date BETWEEN '2026-07-22' AND '2026-07-31'
  GROUP BY product_id
)
SELECT
  p.product_name AS `상품명`,
  pr.revenue AS `매출`,
  pr.order_count AS `주문 건수`
FROM product_revenue pr
JOIN products p ON pr.product_id=p.product_id
ORDER BY pr.revenue DESC
LIMIT 3;

-- ============================================================
-- 예제 5 · [8.1] 여러 CTE 연결하기: 도입부 서브쿼리 변환
-- ============================================================

WITH july_orders AS(
  SELECT product_id, total_amount
  FROM orders
  WHERE order_date BETWEEN '2026-07-22' AND '2026-07-31'
),
product_revenue AS(
  SELECT product_id, SUM(total_amount) AS `revenue`
  FROM july_orders
  GROUP BY product_id
)
SELECT p.product_name, pr.revenue
FROM product_revenue pr
JOIN products p ON pr.product_id=p.product_id
WHERE pr.revenue >=100000
ORDER BY pr.revenue DESC;

-- ============================================================
-- 예제 6 · [8.2] CTE 체이닝 구조 템플릿
-- ============================================================

-- ▶ 실행해 보세요 — 대괄호는 자리를 표시한 것이라 그대로 실행하면 문법 에러가 납니다
WITH 1단계_필터링 AS(
  SELECT ...
  FROM 원본 테이블
  WHERE 조건
),
2단계_집계 AS(
  SELECT ...
  FROM 1단계_필터링
  GROUP BY ...
)
SELECT ...
FROM 2단계_집계;

-- ============================================================
-- 예제 7 · [8.2] 2단계 CTE: 필터링 후 집계
-- ============================================================

WITH weekly_streams AS(
  SELECT track_id, play_count
  FROM streaming
  WHERE stream_date BETWEEN '2026-07-22' AND '2026-07-28'
),
track_totals AS(
  SELECT track_id,
    COUNT(*) AS `stream_count`,
    SUM(play_count) AS `total_plays`
  FROM weekly_streams
  GROUP BY track_id
)
SELECT t.track_name, tt.stream_count, tt.total_plays
FROM track_totals tt
JOIN tracks t ON tt.track_id=t.track_id
ORDER BY tt.total_plays DESC
LIMIT 3;

-- ============================================================
-- 예제 8 · [8.2] 3단계 CTE: 일별, 플랫폼별, 비중 계산
-- ============================================================

WITH daily_streams AS(
  SELECT stream_date, platform,
    COUNT(*) AS `stream_count`,
    SUM(play_count) AS `total_plays`
  FROM streaming
  WHERE stream_date BETWEEN '2026-07-22' AND '2026-07-28'
  GROUP BY stream_date, platform
),
platform_totals AS(
  SELECT platform,
    SUM(`stream_count`) AS `platform_streams`,
    SUM(`total_plays`) AS `platform_plays`
  FROM daily_streams
  GROUP BY platform
),
overall_total AS(
  SELECT SUM(`total_plays`) AS `grand_total`
  FROM daily_streams
)
SELECT
  pt.platform AS `플랫폼`,
  pt.platform_streams AS `스트리밍 건수`,
  pt.platform_plays AS `총 재생`,
  ROUND(pt.platform_plays * 100.0/ot.grand_total, 1) AS `비중`
FROM platform_totals pt
CROSS JOIN overall_total ot
ORDER BY pt.platform_plays DESC
LIMIT 3;

-- ============================================================
-- 예제 9 · [8.2] 같은 CTE를 여러 곳에서 사용
-- ============================================================

WITH vip_fans AS(
  SELECT fan_id, country
  FROM fans
  WHERE membership_level='VIP'
)
SELECT
  (SELECT COUNT(*) FROM vip_fans) AS `전체 VIP`,
  (SELECT COUNT(*) FROM vip_fans WHERE country='대한민국') AS `한국 VIP`,
  (SELECT COUNT(*) FROM vip_fans WHERE country !='대한민국') AS `해외 VIP`;

-- ============================================================
-- 예제 10 · [8.2] CTE끼리 JOIN하기: 아티스트 유형별 분석
-- ============================================================

WITH type_artists AS(
  SELECT artist_type,
    COUNT(*) AS `artist_count`
  FROM artists
  GROUP BY artist_type
),
type_albums AS(
  SELECT ar.artist_type,
    COUNT(al.album_id) AS `album_count`,
    ROUND(AVG(al.price), 0) AS `avg_price`
  FROM artists ar
  LEFT JOIN albums al ON ar.artist_id=al.artist_id
  GROUP BY ar.artist_type
)
SELECT
  ta.artist_type AS `유형`,
  ta.artist_count AS `아티스트 수`,
  tb.album_count AS `앨범 수`,
  tb.avg_price AS `평균 가격`,
  ROUND(tb.album_count * 1.0/ta.artist_count, 1) AS `인당 앨범`
FROM type_artists ta
JOIN type_albums tb ON ta.artist_type=tb.artist_type;

-- ============================================================
-- 예제 11 · [8.3] 팬사인회 이벤트 기본 정보 조회
-- ============================================================

SELECT event_id, artist_id, event_date, total_participants, total_cost
FROM fansign_events
LIMIT 3;

-- ============================================================
-- 예제 12 · [8.3] 업계 평균 ROI 확인
-- ============================================================

SELECT metric_name, benchmark_value
FROM industry_benchmarks
WHERE metric_name='avg_fansign_roi';

-- ============================================================
-- 예제 13 · [8.3] 이벤트별 ROI 계산
-- ============================================================

WITH event_roi AS(
  SELECT
    event_id,
    artist_id,
    total_cost,
    total_revenue,
    total_revenue-total_cost AS `net_profit`,
    ROUND((total_revenue-total_cost) * 100.0/total_cost, 1) AS `roi`
  FROM fansign_events
)
SELECT event_id AS `이벤트`, total_cost AS `비용`, total_revenue AS `수익`,
  net_profit AS `순수익`, roi AS `ROI(%)`
FROM event_roi
ORDER BY `roi` DESC
LIMIT 3;

-- ============================================================
-- 예제 14 · [8.3] 우리 ROI와 업계 평균 비교
-- ============================================================

WITH our_avg AS(
  SELECT
    ROUND(AVG((total_revenue-total_cost) * 100.0/total_cost), 1) AS `our_roi`
  FROM fansign_events
),
industry AS(
  SELECT benchmark_value AS `industry_roi`
  FROM industry_benchmarks
  WHERE metric_name='avg_fansign_roi'
)
SELECT
  o.our_roi AS `우리 ROI`,
  i.industry_roi AS `업계 평균`,
  ROUND(o.our_roi-i.industry_roi, 1) AS `차이`
FROM our_avg o
CROSS JOIN industry i;

-- ============================================================
-- 예제 15 · [8.3] 아티스트별 ROI 분석
-- ============================================================

WITH event_roi AS(
  SELECT
    event_id,
    artist_id,
    total_cost,
    total_revenue,
    total_revenue-total_cost AS `net_profit`,
    ROUND((total_revenue-total_cost) * 100.0/total_cost, 1) AS `roi`
  FROM fansign_events
),
artist_summary AS(
  SELECT
    er.artist_id,
    a.artist_name,
    COUNT(*) AS `event_count`,
    SUM(er.total_cost) AS `total_invested`,
    SUM(er.net_profit) AS `total_profit`,
    ROUND(AVG(er.roi), 1) AS `avg_roi`
  FROM event_roi er
  JOIN artists a ON er.artist_id=a.artist_id
  GROUP BY er.artist_id, a.artist_name
)
SELECT artist_name AS `아티스트`, `event_count` AS `횟수`,
  total_invested AS `총 투자`, total_profit AS `총 순수익`,
  avg_roi AS `평균 ROI(%)`
FROM artist_summary
ORDER BY `avg_roi` DESC;

-- ============================================================
-- 예제 16 · [다중 CTE 기본 문법 템플릿]
-- ============================================================

-- ▶ 실행해 보세요 — 대괄호는 자리를 표시한 것이라 그대로 실행하면 문법 에러가 납니다
WITH 첫 번째 CTE AS(
   SELECT ...
),
두 번째 CTE AS(
   SELECT ...
   FROM 첫 번째 CTE
)
SELECT ...
FROM 두 번째 CTE;
