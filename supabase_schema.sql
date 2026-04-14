-- ============================================================
-- Chatify — Complete Supabase Schema
-- Run this in your Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- ─── 1. TABLES CREATION (STRICT ORDER) ──────────────────────

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT,
  email TEXT,
  image_url TEXT,
  phone TEXT,
  about TEXT DEFAULT 'Hey there! I am using Chatify',
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversations Table
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Conversation Participants Table
CREATE TABLE IF NOT EXISTS conversation_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  UNIQUE(conversation_id, user_id)
);

-- Messages Table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  text TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- If messages table already existed but without these columns, add them
ALTER TABLE messages ADD COLUMN IF NOT EXISTS conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE;

-- ─── 2. INDEXES ───────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at);

-- ─── 3. ENABLE RLS ────────────────────────────────────────

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- ─── 4. RLS POLICIES (ALL TABLES MUST EXIST) ──────────────

-- Users Policies
DROP POLICY IF EXISTS "Users can insert their own data" ON users;
CREATE POLICY "Users can insert their own data" ON users FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can read all users" ON users;
CREATE POLICY "Users can read all users" ON users FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can update their own data" ON users;
CREATE POLICY "Users can update their own data" ON users FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Conversations Policies
DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
CREATE POLICY "Users can view their conversations" ON conversations FOR SELECT USING (
  id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
CREATE POLICY "Users can create conversations" ON conversations FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update their conversations" ON conversations;
CREATE POLICY "Users can update their conversations" ON conversations FOR UPDATE USING (
  id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
);

-- Participants Policies
DROP POLICY IF EXISTS "Users can view their participations" ON conversation_participants;
CREATE POLICY "Users can view their participations" ON conversation_participants FOR SELECT USING (
  user_id = auth.uid() OR conversation_id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can create participations" ON conversation_participants;
CREATE POLICY "Users can create participations" ON conversation_participants FOR INSERT WITH CHECK (true);

-- Messages Policies
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
CREATE POLICY "Users can view messages in their conversations" ON messages FOR SELECT USING (
  conversation_id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can send messages in their conversations" ON messages;
CREATE POLICY "Users can send messages in their conversations" ON messages FOR INSERT WITH CHECK (
  conversation_id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users can update messages" ON messages;
CREATE POLICY "Users can update messages" ON messages FOR UPDATE USING (
  conversation_id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
);


-- ─── 5. HELPER FUNCTION ──────────────────────────────────

CREATE OR REPLACE FUNCTION find_conversation(user_one UUID, user_two UUID)
RETURNS UUID AS $$
  SELECT cp1.conversation_id
  FROM conversation_participants cp1
  JOIN conversation_participants cp2
    ON cp1.conversation_id = cp2.conversation_id
  WHERE cp1.user_id = user_one
    AND cp2.user_id = user_two
  LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER;


-- Enable Realtime for all tables at once
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE conversations, conversation_participants, messages;
COMMIT;

-- ─── 7. AUTOMATED PROFILE CREATION ────────────────────────

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, username, email, image_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', 'User'),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to run the function on every signup
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

