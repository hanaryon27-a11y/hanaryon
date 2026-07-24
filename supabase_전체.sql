-- =============================================================
-- 지력사무소 후원보상 안내 — Supabase 전체 셋업 SQL (한 번에 붙여넣기용)
-- 사용법: Supabase → SQL Editor → 아래 전체 복붙 → Run.
-- ✅ 여러 번 다시 실행해도 안전 (IF NOT EXISTS / ON CONFLICT / DROP POLICY IF EXISTS)
-- ✅ 모든 표는 anon(공개) 키로 읽기+쓰기 허용 — 관리자 페이지가 anon 키로 동작하므로 필수
-- ✅ 이미지는 전부 "링크(URL)" 방식이라 Storage(버킷) 설정이 필요 없습니다.
-- =============================================================


-- ── 사이트 문구 · 팔레트 (id=1 한 칸에 JSON으로 저장) ──
CREATE TABLE IF NOT EXISTS profile (
  id         BIGINT PRIMARY KEY,
  data       JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE profile ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profile_all" ON profile;
CREATE POLICY "profile_all" ON profile FOR ALL USING (true) WITH CHECK (true);


-- ── 컬렉션 (의상 outfit / 헤어 hair) ──
CREATE TABLE IF NOT EXISTS collection_items (
  id         BIGSERIAL PRIMARY KEY,
  category   TEXT NOT NULL DEFAULT 'outfit',   -- outfit / hair
  label      TEXT NOT NULL,
  image_url  TEXT DEFAULT '',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_collection_category ON collection_items(category);
ALTER TABLE collection_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "collection_all" ON collection_items;
CREATE POLICY "collection_all" ON collection_items FOR ALL USING (true) WITH CHECK (true);


-- ── 누적공약 ──
CREATE TABLE IF NOT EXISTS pledges (
  id           BIGSERIAL PRIMARY KEY,
  amount_label TEXT NOT NULL,      -- 화면에 보이는 문구 (예: 5만개)
  value        BIGINT DEFAULT 0,   -- 진행바 계산용 숫자 (예: 50000)
  reward       TEXT NOT NULL,
  sort_order   INT DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE pledges ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pledges_all" ON pledges;
CREATE POLICY "pledges_all" ON pledges FOR ALL USING (true) WITH CHECK (true);


-- ── 개인보상 ──
CREATE TABLE IF NOT EXISTS personal_rewards (
  id           BIGSERIAL PRIMARY KEY,
  amount_label TEXT NOT NULL,
  reward       TEXT NOT NULL,
  sort_order   INT DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE personal_rewards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "personal_all" ON personal_rewards;
CREATE POLICY "personal_all" ON personal_rewards FOR ALL USING (true) WITH CHECK (true);


-- ── 누적보상: 구간 ──
CREATE TABLE IF NOT EXISTS cumulative_tiers (
  id           BIGSERIAL PRIMARY KEY,
  amount_label TEXT NOT NULL,      -- 예: 5000개 이상
  sort_order   INT DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE cumulative_tiers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "cumulative_tiers_all" ON cumulative_tiers;
CREATE POLICY "cumulative_tiers_all" ON cumulative_tiers FOR ALL USING (true) WITH CHECK (true);


-- ── 누적보상: 구간 안의 상품 ──
CREATE TABLE IF NOT EXISTS cumulative_items (
  id         BIGSERIAL PRIMARY KEY,
  tier_id    BIGINT NOT NULL,
  label      TEXT NOT NULL,
  image_url  TEXT DEFAULT '',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_cumulative_items_tier ON cumulative_items(tier_id);
ALTER TABLE cumulative_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "cumulative_items_all" ON cumulative_items;
CREATE POLICY "cumulative_items_all" ON cumulative_items FOR ALL USING (true) WITH CHECK (true);


-- ── TOP5 보상 ──
CREATE TABLE IF NOT EXISTS top_rewards (
  id         BIGSERIAL PRIMARY KEY,
  label      TEXT NOT NULL,
  image_url  TEXT DEFAULT '',     -- 비우면 번호(01·02…)로 표시됨
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE top_rewards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "top_rewards_all" ON top_rewards;
CREATE POLICY "top_rewards_all" ON top_rewards FOR ALL USING (true) WITH CHECK (true);


-- ── 룰렛 확률 ──
CREATE TABLE IF NOT EXISTS roulette_odds (
  id         BIGSERIAL PRIMARY KEY,
  label      TEXT NOT NULL,
  chance     TEXT DEFAULT '',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE roulette_odds ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "roulette_all" ON roulette_odds;
CREATE POLICY "roulette_all" ON roulette_odds FOR ALL USING (true) WITH CHECK (true);


-- ── 보상기록 ──
CREATE TABLE IF NOT EXISTS reward_records (
  id         BIGSERIAL PRIMARY KEY,
  nickname   TEXT NOT NULL,
  soop_id    TEXT DEFAULT '',       -- SOOP 아이디 → 프로필 사진 자동 연동
  reward     TEXT NOT NULL,
  status     TEXT DEFAULT '대기',   -- 대기 / 진행중 / 완료
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
-- (예전 버전에서 만든 표에도 아이디 칸 추가)
ALTER TABLE reward_records ADD COLUMN IF NOT EXISTS soop_id TEXT DEFAULT '';
ALTER TABLE reward_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "reward_records_all" ON reward_records;
CREATE POLICY "reward_records_all" ON reward_records FOR ALL USING (true) WITH CHECK (true);


-- ── 문의함 ──
CREATE TABLE IF NOT EXISTS inquiries (
  id         BIGSERIAL PRIMARY KEY,
  nickname   TEXT,
  message    TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "inquiries_all" ON inquiries;
CREATE POLICY "inquiries_all" ON inquiries FOR ALL USING (true) WITH CHECK (true);


-- =============================================================
-- 기본 데이터 심기 (처음 1회만 들어감 — 이미 값이 있으면 건너뜀)
-- =============================================================

INSERT INTO profile (id, data) VALUES (1, '{}'::jsonb) ON CONFLICT (id) DO NOTHING;

-- 사이트 문구 기본값 (이미 저장된 키는 그대로 두고, 없는 키만 채움)
UPDATE profile SET data = '{
  "site-title":"한아련 삼국지 API 공약",
  "site-icon":"https://profile.img.sooplive.co.kr/LOGO/rk/rkdmsdl782/rkdmsdl782.jpg",
  "loader-image":"https://profile.img.sooplive.co.kr/LOGO/rk/rkdmsdl782/rkdmsdl782.jpg",
  "trans-prefix":"한아련&",
  "brand-stamp":"吳",
  "brand-sub":"JIRYEOK",
  "side-note":"江東 · WU VIRTUAL ARCHIVE\nJIRYEOK OFFICE",
  "nav-main-ko":"메인","nav-main-en":"MAIN",
  "nav-pledge-ko":"누적공약","nav-pledge-en":"PROMISE",
  "nav-personal-ko":"개인보상","nav-personal-en":"PERSONAL",
  "nav-cumulative-ko":"누적보상","nav-cumulative-en":"TOTAL",
  "nav-top5-ko":"TOP5 보상","nav-top5-en":"TOP 5",
  "nav-records-ko":"보상기록","nav-records-en":"RECORDS",
  "outfit-kicker":"江東 · WU ARCHIVE / COLLECTION 01","outfit-title":"의상",
  "hair-kicker":"江東 · WU ARCHIVE / COLLECTION 02","hair-title":"헤어",
  "roulette-kicker":"江東 · WU ARCHIVE / EVENT GUIDE","roulette-title":"룰렛 확률",
  "roulette-badge":"","roulette-note":"","roulette-percol":"5",
  "roulette-mascot":"/bee-mascot.png",
  "pledge-kicker":"CUMULATIVE PROMISE","pledge-title":"누적공약","pledge-note":"누적으로 다 합니다",
  "pledge-current":"0",
  "personal-kicker":"PERSONAL REWARD","personal-title":"개인보상","personal-note":"해당 개수로 쏴주시거나 따로 알려주세요",
  "cumul-kicker":"CUMULATIVE REWARD","cumul-title":"누적보상","cumul-note":"룰렛 + 개인보상 모두 포함 · 1000개당 카드팩",
  "top-kicker":"SPECIAL REWARD","top-title":"TOP5 보상","top-note":"1개 골라주세요",
  "rec-kicker":"REWARD RECORDS","rec-title":"보상기록","rec-note":"전달된 보상과 진행 상태를 정리하는 공간",
  "rec-empty-title":"아직 등록된 보상 기록이 없어요.",
  "rec-empty-desc":"전달이 시작되면 이곳에서 한눈에 확인할 수 있어요.",
  "ask-kicker":"CONTACT · 문의","ask-title":"사무소에 남기기",
  "ask-desc":"보상 관련 문의나 하고 싶은 말을 남겨주세요. 확인 후 방송에서 안내드려요.",
  "site-desc":"삼국지 API 공약에 관한 모든 것을 한눈에 확인하세요.",
  "ask-btn":"✉ 문의하기",
  "ask-nick-label":"닉네임","ask-nick-ph":"닉네임 (선택)",
  "ask-msg-label":"내용","ask-msg-ph":"내용을 적어주세요",
  "ask-close":"닫기","ask-send":"보내기",
  "ask-need":"내용을 적어주세요.",
  "ask-done":"문의가 전달됐어요. 고마워요!",
  "ask-fail":"전송에 실패했어요. 잠시 뒤 다시 시도해 주세요.",
  "look-prefix":"LOOK",
  "empty-collection":"아직 등록된 항목이 없어요.",
  "empty-roulette":"확률표가 아직 비어 있어요.",
  "pledge-cur-label":"현재 누적","pledge-unit":"개",
  "pledge-done-label":"달성 보상",
  "pledge-next-prefix":"다음","pledge-next-suffix":"개 남음",
  "pledge-all-done":"모든 누적공약 달성!",
  "pledge-st-done":"달성","pledge-st-next":"다음","pledge-st-wait":"대기",
  "empty-pledge":"등록된 공약이 없어요.",
  "empty-personal":"등록된 개인보상이 없어요.",
  "empty-tier":"이 구간에 등록된 보상이 없어요.",
  "empty-cumul":"등록된 누적보상 구간이 없어요.",
  "empty-top":"등록된 TOP5 보상이 없어요.",
  "pledge-fs-label":"14","pledge-fs-text":"12",
  "personal-fs-label":"20","personal-fs-text":"13",
  "rec-th-nick":"닉네임","rec-th-reward":"보상","rec-th-status":"상태",
  "rec-more":"외","rec-count-unit":"건","rec-sum-label":"완료",
  "rec-tap-hint":"이름을 누르면 받은 보상 전체를 볼 수 있어요.","rec-close":"닫기",
  "rec-glyph":"錄",
  "theme-wu-red":"#7a1f1b","theme-accent":"#ad342b","theme-gold":"#b38636",
  "theme-signal":"#58d9d7","theme-ink":"#211b15","theme-paper":"#f7f0df"
}'::jsonb || data
WHERE id = 1;


-- (이미 예전 버전 SQL을 돌렸던 경우) 제목·설명을 새 문구로 — 예전 기본값일 때만 바꿈
UPDATE profile
   SET data = jsonb_set(data, '{site-title}', '"한아련 삼국지 API 공약"'::jsonb)
 WHERE id = 1 AND data->>'site-title' = '한아련&지력사무소';

UPDATE profile
   SET data = jsonb_set(data, '{site-desc}', '"삼국지 API 공약에 관한 모든 것을 한눈에 확인하세요."'::jsonb)
 WHERE id = 1 AND data->>'site-desc' = '의상과 헤어 컬렉션, 누적 공약과 후원 보상을 한눈에 확인하세요.';


-- (이미 예전 버전 SQL을 돌렸던 경우) 룰렛 각주에 남아 있는 샘플 문구만 비움 — 직접 쓴 글은 건드리지 않음
UPDATE profile
   SET data = jsonb_set(data, '{roulette-note}', '""'::jsonb)
 WHERE id = 1
   AND data->>'roulette-note' = '확률은 교체하기 쉬운 임시 값이에요.';


-- (이미 예전 버전 SQL을 돌렸던 경우) 룰렛 SAMPLE 배지만 비움 — 직접 쓴 글은 건드리지 않음
UPDATE profile
   SET data = jsonb_set(data, '{roulette-badge}', '""'::jsonb)
 WHERE id = 1
   AND data->>'roulette-badge' = 'SAMPLE';


-- 컬렉션 (의상 · 헤어)
INSERT INTO collection_items (category, label, image_url, sort_order)
SELECT * FROM (VALUES
  ('outfit','화이트 드레스','/characters/look-01.webp',1),
  ('outfit','빈티지 룩','/characters/look-02.webp',2),
  ('outfit','스타리 나이트','/characters/look-03.webp',3),
  ('outfit','클래식 코르셋','/characters/look-04.webp',4),
  ('hair','웨이브 롱','/characters/look-05.webp',1),
  ('hair','트윈테일','/characters/look-06.webp',2),
  ('hair','레이어드 롱','/characters/look-07.webp',3),
  ('hair','보브 컷','/characters/look-08.webp',4)
) AS v(category,label,image_url,sort_order)
WHERE NOT EXISTS (SELECT 1 FROM collection_items);


-- 누적공약
INSERT INTO pledges (amount_label, value, reward, sort_order)
SELECT * FROM (VALUES
  ('5만개',50000,'모션캡쳐 방송',1),
  ('7만개',70000,'지창걸스 커버곡 업로드',2),
  ('10만개',100000,'움직이는 OGQ (이모티콘) 아련티콘 + 호빵티콘',3),
  ('12만개',120000,'지력 72시간 (병라목련)',4),
  ('15만개',150000,'오리지널 아바타',5),
  ('20만개',200000,'전기충격촉각슈트 치킨먹기 (w. 라무)',6),
  ('25만개',250000,'스카이다이빙',7),
  ('30만개',300000,'VRC 풀트 메이드카페',8),
  ('44만개',440000,'사란니 빼기 (1개)',9),
  ('50만개',500000,'지력카페 일일 알바생',10),
  ('71만개',710000,'장가계 하늘사다리 브이로그',11),
  ('150만개',1500000,'지력사무소 콘서트',12)
) AS v(amount_label,value,reward,sort_order)
WHERE NOT EXISTS (SELECT 1 FROM pledges);


-- 개인보상
INSERT INTO personal_rewards (amount_label, reward, sort_order)
SELECT * FROM (VALUES
  ('500개','복붙방셀 + 역팬 10개',1),
  ('1440개','단컷방셀 2장 + 역팬 20개',2),
  ('2340개','단컷방셀 2장 + 움짤방셀 + 역팬 40개',3),
  ('4040개','단컷방셀 풀세트 (모든 의상) + 역팬 140개',4),
  ('5240개','단컷방셀 2장 + 움짤방셀 1장 + 네컷방셀 + 역팬 234개',5),
  ('7777개','방셀 풀세트 (단컷 풀세트 + 움짤방셀 + 네컷방셀) + 역팬 500개',6),
  ('12440개','방셀 풀세트 (단컷 풀세트 + 움짤방셀 + 네컷방셀) + 배너 풀세트 + 역팬 1440개',7),
  ('1,000,000개','약혼하기 (본인이 원하면 파혼 가능)',8)
) AS v(amount_label,reward,sort_order)
WHERE NOT EXISTS (SELECT 1 FROM personal_rewards);


-- 누적보상 구간 + 상품
INSERT INTO cumulative_tiers (amount_label, sort_order)
SELECT * FROM (VALUES
  ('2000개 이상',1),('3000개 이상',2),('5000개 이상',3),('20000개 이상',4)
) AS v(amount_label,sort_order)
WHERE NOT EXISTS (SELECT 1 FROM cumulative_tiers);

INSERT INTO cumulative_items (tier_id, label, image_url, sort_order)
SELECT t.id, v.label, v.image_url, v.sort_order
FROM (VALUES
  ('2000개 이상','지력 탁상시계','/rewards/clock.webp',1),
  ('3000개 이상','자체제작 후드집업','/rewards/hoodie.webp',1),
  ('3000개 이상','지력 티셔츠','/rewards/tshirt.webp',2),
  ('3000개 이상','지력 탁상시계','/rewards/clock.webp',3),
  ('5000개 이상','자체제작 후드집업','/rewards/hoodie.webp',1),
  ('5000개 이상','지력 티셔츠','/rewards/tshirt.webp',2),
  ('5000개 이상','직접 조향한 디퓨저','/rewards/diffuser.webp',3),
  ('5000개 이상','지력 탁상시계','/rewards/clock.webp',4),
  ('5000개 이상','지력카페 입장권','/rewards/cafe-ticket.webp',5),
  ('20000개 이상','자체제작 후드집업','/rewards/hoodie.webp',1),
  ('20000개 이상','지력 티셔츠','/rewards/tshirt.webp',2),
  ('20000개 이상','직접 조향한 디퓨저','/rewards/diffuser.webp',3),
  ('20000개 이상','커스텀 마우스','/rewards/mouse.webp',4),
  ('20000개 이상','지력 탁상시계','/rewards/clock.webp',5),
  ('20000개 이상','지력카페 입장권','/rewards/cafe-ticket.webp',6)
) AS v(tier_label,label,image_url,sort_order)
JOIN cumulative_tiers t ON t.amount_label = v.tier_label
WHERE NOT EXISTS (SELECT 1 FROM cumulative_items);


-- (이미 SQL을 돌린 경우) 3000개 이상 구간에 '지력 티셔츠' 추가 — 이미 있으면 건너뜀
INSERT INTO cumulative_items (tier_id, label, image_url, sort_order)
SELECT t.id, '지력 티셔츠', '/rewards/tshirt.webp',
       COALESCE((SELECT MAX(i.sort_order) FROM cumulative_items i WHERE i.tier_id = t.id), 0) + 1
  FROM cumulative_tiers t
 WHERE t.amount_label IN ('3000개 이상', '5000개 이상', '20000개 이상')
   AND NOT EXISTS (
        SELECT 1 FROM cumulative_items i
         WHERE i.tier_id = t.id AND i.label = '지력 티셔츠');


-- TOP5 보상
INSERT INTO top_rewards (label, image_url, sort_order)
SELECT * FROM (VALUES
  ('수제 목도리 (11월 내)','/rewards/scarf.webp',1),
  ('종겜 켠왕권 (지피티룰 제한)','',2),
  ('노래방셀 2곡 (스튜디오 녹음 + 방송국)','',3),
  ('100시간 노방종','',4),
  ('수제 가죽지갑','/rewards/wallet.webp',5)
) AS v(label,image_url,sort_order)
WHERE NOT EXISTS (SELECT 1 FROM top_rewards);


-- 룰렛 확률
INSERT INTO roulette_odds (label, chance, sort_order)
SELECT * FROM (VALUES
  ('카드팩','40%',1),
  ('역팬 10개','25%',2),
  ('복붙 방셀','18%',3),
  ('단컷 방셀','12%',4),
  ('한 번 더','5%',5)
) AS v(label,chance,sort_order)
WHERE NOT EXISTS (SELECT 1 FROM roulette_odds);


-- 끝! 이미지는 전부 "링크" 방식이라 Storage 설정이 필요 없습니다.
