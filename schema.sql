-- ==============================================================================
-- 📋 다함께 케어 (Dahamkke Care) - Supabase 데이터베이스 스키마
-- ==============================================================================
-- Supabase 대시보드의 [SQL Editor]에 복사하여 [RUN]을 실행하시면 테이블이 자동 생성됩니다.

-- 1. 어르신 기본 정보 테이블 (elders)
CREATE TABLE IF NOT EXISTS public.elders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    age INT NOT NULL,
    gender VARCHAR(10) DEFAULT '여성',
    care_level VARCHAR(50) DEFAULT '장기요양 치매 3등급',
    center_name VARCHAR(100) DEFAULT '화성남부노인복지관 주간보호',
    manager_info VARCHAR(100) DEFAULT '이지은 사회복지사 (031-356-8000)',
    guardian_phone VARCHAR(50) DEFAULT '010-3849-5921',
    profile_img TEXT DEFAULT 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
    safety_tag VARCHAR(100) DEFAULT '배회 위험군 (위치추적기 착용)',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. 건강/투약/기분/식사 데일리 기록 테이블 (health_records)
CREATE TABLE IF NOT EXISTS public.health_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    elder_id UUID REFERENCES public.elders(id) ON DELETE CASCADE,
    record_date DATE DEFAULT CURRENT_DATE NOT NULL,
    meds JSONB DEFAULT '{"morning": true, "morningTime": "08:30", "lunch": true, "lunchTime": "12:45", "dinner": false, "dinnerTime": "", "night": false, "nightTime": ""}'::jsonb,
    mood VARCHAR(50) DEFAULT 'good', -- 'great', 'good', 'anxious', 'wandering', 'agitated'
    mood_note TEXT DEFAULT '',
    meals JSONB DEFAULT '{"breakfast": "완식", "lunch": "완식", "dinner": "진행전"}'::jsonb,
    sleep VARCHAR(50) DEFAULT '7.5시간 (기상 1회)',
    vitals JSONB DEFAULT '{"bp": "128 / 82", "sugar": "112 mg/dL", "temp": "36.5 ℃"}'::jsonb,
    center_attended BOOLEAN DEFAULT true,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_elder_record_date UNIQUE (elder_id, record_date)
);

-- 3. 관찰일지 테이블 (observation_diaries)
CREATE TABLE IF NOT EXISTS public.observation_diaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    elder_id UUID REFERENCES public.elders(id) ON DELETE CASCADE,
    role_type VARCHAR(20) NOT NULL, -- 'center' (복지관) or 'family' (가족)
    author VARCHAR(50) NOT NULL,
    author_role VARCHAR(50) NOT NULL,
    tag VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    photos TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. 관찰일지 댓글 테이블 (diary_comments)
CREATE TABLE IF NOT EXISTS public.diary_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    diary_id UUID REFERENCES public.observation_diaries(id) ON DELETE CASCADE,
    author VARCHAR(50) NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. 가족 구성원 및 복지관 담당자 (family_members)
CREATE TABLE IF NOT EXISTS public.family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    elder_id UUID REFERENCES public.elders(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    relation VARCHAR(50) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    is_key BOOLEAN DEFAULT false,
    is_staff BOOLEAN DEFAULT false,
    status VARCHAR(50) DEFAULT '활동중',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- RLS (Row Level Security) 설정 및 공개 접근 정책
-- ==============================================================================
ALTER TABLE public.elders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.observation_diaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diary_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;

-- 공용 익명 접근 정책 (Anon Key로 읽기/쓰기 허용)
CREATE POLICY "Public Read Elders" ON public.elders FOR SELECT USING (true);
CREATE POLICY "Public Upsert Elders" ON public.elders FOR ALL USING (true);

CREATE POLICY "Public Read Health" ON public.health_records FOR SELECT USING (true);
CREATE POLICY "Public Upsert Health" ON public.health_records FOR ALL USING (true);

CREATE POLICY "Public Read Diaries" ON public.observation_diaries FOR SELECT USING (true);
CREATE POLICY "Public Insert Diaries" ON public.observation_diaries FOR ALL USING (true);

CREATE POLICY "Public Read Comments" ON public.diary_comments FOR SELECT USING (true);
CREATE POLICY "Public Insert Comments" ON public.diary_comments FOR ALL USING (true);

CREATE POLICY "Public Read Family" ON public.family_members FOR SELECT USING (true);
CREATE POLICY "Public Upsert Family" ON public.family_members FOR ALL USING (true);

-- 실시간 Realtime 동기화 활성화
ALTER PUBLICATION supabase_realtime ADD TABLE public.health_records;
ALTER PUBLICATION supabase_realtime ADD TABLE public.observation_diaries;
ALTER PUBLICATION supabase_realtime ADD TABLE public.diary_comments;

-- ==============================================================================
-- 초기 샘플 데이터 삽입
-- ==============================================================================
INSERT INTO public.elders (id, name, age, gender, care_level, center_name, guardian_phone)
VALUES ('a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', '김순자', 82, '여성', '장기요양 치매 3등급', '화성남부노인복지관 주간보호', '010-3849-5921')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.health_records (elder_id, record_date, mood, mood_note)
VALUES (
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    CURRENT_DATE,
    'good',
    '아침에 화성남부 복지관 셔틀 타실 때 기분 좋게 옛 노래를 흥얼거리심'
)
ON CONFLICT (elder_id, record_date) DO NOTHING;

INSERT INTO public.observation_diaries (id, elder_id, role_type, author, author_role, tag, content, photos)
VALUES 
(
    'b2c3d4e5-f6a7-5b6c-9d0e-1f2a3b4c5d6e',
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'center',
    '이지은 사회복지사',
    '화성남부 주간보호',
    '인지재활 프로그램',
    '순자 어르신께서 오늘 가을 단풍 미술치료 활동에 정말 열정적으로 참여하셨습니다. 옛날 고향 화성 남양 장터 추억을 이야기하시며 다른 어르신들과도 도란도란 웃으셨어요. 점심 식사도 한 그릇 싹 비우셨습니다! 🍁',
    ARRAY['https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=600&auto=format&fit=crop&q=80', 'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=600&auto=format&fit=crop&q=80']
),
(
    'c3d4e5f6-a7b8-6c7d-0e1f-2a3b4c5d6e7f',
    'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
    'family',
    '딸 김영희 (주보호자)',
    '가족 보호자',
    '가정 일상 & 투약',
    '어젯밤에는 한 번도 안 깨시고 푹 주무셨어요. 아침 혈압약과 치매 처방약(도네페질) 챙겨 드렸습니다. 복지관 셔틀버스 기사님 오셔서 반갑게 인사하며 탑승하셨습니다!',
    ARRAY['https://images.unsplash.com/photo-1581579438747-1dc8d17bbce4?w=600&auto=format&fit=crop&q=80']
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.diary_comments (diary_id, author, text)
VALUES 
('b2c3d4e5-f6a7-5b6c-9d0e-1f2a3b4c5d6e', '딸 김영희', '선생님 항상 세심하게 챙겨주셔서 감사합니다! 💕'),
('b2c3d4e5-f6a7-5b6c-9d0e-1f2a3b4c5d6e', '아들 김철수', '어머니 웃으시는 모습 보니 든든합니다.')
ON CONFLICT (id) DO NOTHING;
