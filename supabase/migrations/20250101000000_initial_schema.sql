-- Initial Schema for SRT App
-- Description: ユーザーの所有品・欲しいものを管理するアプリのスキーマ

-- ユーザープロファイル（Supabase Authと連携）
CREATE TABLE IF NOT EXISTS users_profile (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- カテゴリー
CREATE TABLE IF NOT EXISTS stuff_categories (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users_profile(id) ON DELETE CASCADE,
  rank INTEGER,
  name TEXT NOT NULL,
  icon TEXT NOT NULL, -- 絵文字（例: "📱", "👔", "🎮"）
  property_limited_number INTEGER NOT NULL DEFAULT 0, -- 所有品登録上限数
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 所有品
CREATE TABLE IF NOT EXISTS stuff_properties (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users_profile(id) ON DELETE CASCADE,
  category_id BIGINT NOT NULL REFERENCES stuff_categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  thumbnail TEXT, -- Supabase StorageのURL
  score INTEGER CHECK (score >= 0 AND score <= 100),
  price DECIMAL(10, 2),
  address TEXT, -- 保管場所
  purchase_date DATE,
  purchase_place TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 所有品メモ
CREATE TABLE IF NOT EXISTS stuff_property_memos (
  id BIGSERIAL PRIMARY KEY,
  property_id BIGINT NOT NULL REFERENCES stuff_properties(id) ON DELETE CASCADE,
  five_w TEXT[] DEFAULT '{}', -- 5W1H配列
  image TEXT, -- Supabase StorageのURL
  memo TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 欲しいもの
CREATE TABLE IF NOT EXISTS stuff_wants (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users_profile(id) ON DELETE CASCADE,
  category_id BIGINT NOT NULL REFERENCES stuff_categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  thumbnail TEXT, -- Supabase StorageのURL
  score INTEGER CHECK (score >= 0 AND score <= 100),
  price DECIMAL(10, 2),
  brand TEXT,
  url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 欲しいもの購入条件
CREATE TABLE IF NOT EXISTS stuff_want_conditions (
  id BIGSERIAL PRIMARY KEY,
  want_id BIGINT NOT NULL REFERENCES stuff_wants(id) ON DELETE CASCADE,
  asset_threshold DECIMAL(10, 2) NOT NULL, -- 必要資産額
  period TEXT, -- 期間条件（例: "2024-06", "within_3_months"）
  max_property_count INTEGER, -- 所有品数上限
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックス
CREATE INDEX IF NOT EXISTS idx_stuff_categories_user_id ON stuff_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_stuff_properties_user_id ON stuff_properties(user_id);
CREATE INDEX IF NOT EXISTS idx_stuff_properties_category_id ON stuff_properties(category_id);
CREATE INDEX IF NOT EXISTS idx_stuff_property_memos_property_id ON stuff_property_memos(property_id);
CREATE INDEX IF NOT EXISTS idx_stuff_wants_user_id ON stuff_wants(user_id);
CREATE INDEX IF NOT EXISTS idx_stuff_wants_category_id ON stuff_wants(category_id);
CREATE INDEX IF NOT EXISTS idx_stuff_want_conditions_want_id ON stuff_want_conditions(want_id);

-- RLS（Row Level Security）を有効化
ALTER TABLE stuff_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE stuff_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE stuff_property_memos ENABLE ROW LEVEL SECURITY;
ALTER TABLE stuff_wants ENABLE ROW LEVEL SECURITY;
ALTER TABLE stuff_want_conditions ENABLE ROW LEVEL SECURITY;

-- RLSポリシー：自分のデータのみアクセス可能

-- カテゴリー
DROP POLICY IF EXISTS "Users can manage their own categories" ON stuff_categories;
CREATE POLICY "Users can manage their own categories"
  ON stuff_categories FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 所有品
DROP POLICY IF EXISTS "Users can manage their own properties" ON stuff_properties;
CREATE POLICY "Users can manage their own properties"
  ON stuff_properties FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 所有品メモ
DROP POLICY IF EXISTS "Users can manage their own property memos" ON stuff_property_memos;
CREATE POLICY "Users can manage their own property memos"
  ON stuff_property_memos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM stuff_properties
      WHERE stuff_properties.id = stuff_property_memos.property_id
      AND stuff_properties.user_id = auth.uid()
    )
  );

-- 欲しいもの
DROP POLICY IF EXISTS "Users can manage their own wants" ON stuff_wants;
CREATE POLICY "Users can manage their own wants"
  ON stuff_wants FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 欲しいもの購入条件
DROP POLICY IF EXISTS "Users can manage their own want conditions" ON stuff_want_conditions;
CREATE POLICY "Users can manage their own want conditions"
  ON stuff_want_conditions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM stuff_wants
      WHERE stuff_wants.id = stuff_want_conditions.want_id
      AND stuff_wants.user_id = auth.uid()
    )
  );

-- updated_at自動更新トリガー関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- updated_atトリガー設定
DROP TRIGGER IF EXISTS update_stuff_categories_updated_at ON stuff_categories;
CREATE TRIGGER update_stuff_categories_updated_at
  BEFORE UPDATE ON stuff_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_stuff_properties_updated_at ON stuff_properties;
CREATE TRIGGER update_stuff_properties_updated_at
  BEFORE UPDATE ON stuff_properties
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_stuff_property_memos_updated_at ON stuff_property_memos;
CREATE TRIGGER update_stuff_property_memos_updated_at
  BEFORE UPDATE ON stuff_property_memos
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_stuff_wants_updated_at ON stuff_wants;
CREATE TRIGGER update_stuff_wants_updated_at
  BEFORE UPDATE ON stuff_wants
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_stuff_want_conditions_updated_at ON stuff_want_conditions;
CREATE TRIGGER update_stuff_want_conditions_updated_at
  BEFORE UPDATE ON stuff_want_conditions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
