-- ============================================
-- VENTUREVAULT — COMPLETE DATABASE SCHEMA
-- Run this in Supabase SQL Editor
-- ============================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ── USERS (extends Supabase auth.users) ──
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text unique not null,
  first_name text,
  last_name text,
  phone text,
  region text,
  role text default 'buyer' check (role in ('buyer','seller','admin')),
  id_verified boolean default false,
  id_verified_at timestamptz,
  avatar_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ── BUYER PASSPORTS ──
create table if not exists public.buyer_passports (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  max_budget text,
  preferred_sectors text[],
  preferred_location text,
  purchase_timeline text,
  experience text,
  finance_status text,
  available_deposit text,
  background text,
  tenure_preference text,
  id_verified boolean default false,
  finance_verified boolean default false,
  passport_ref text unique,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ── LISTINGS ──
create table if not exists public.listings (
  id uuid default uuid_generate_v4() primary key,
  seller_id uuid references public.profiles(id) on delete cascade not null,
  -- Basic
  title text not null,
  sector text not null,
  business_type text,
  city text,
  region text,
  description text,
  short_description text,
  -- Financials
  asking_price numeric,
  weekly_turnover numeric,
  annual_profit numeric,
  annual_rent numeric,
  -- Details
  years_trading text,
  num_employees text,
  premises_size text,
  opening_days text,
  tenure_type text,
  lease_remaining text,
  -- Scores
  trust_score integer default 0,
  health_score integer default 0,
  -- Status
  status text default 'draft' check (status in ('draft','pending','live','under_offer','sold','archived')),
  featured boolean default false,
  -- Media
  photos text[],
  video_url text,
  -- Timestamps
  published_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ── DIGITAL LISTINGS (extends listings) ──
create table if not exists public.digital_listings (
  id uuid default uuid_generate_v4() primary key,
  listing_id uuid references public.listings(id) on delete cascade not null,
  platform text not null, -- youtube, instagram, tiktok, shopify, amazon_fba, saas, newsletter, website
  platform_url text,
  -- Metrics
  followers integer,
  subscribers integer,
  monthly_revenue numeric,
  monthly_profit numeric,
  monthly_views integer,
  engagement_rate numeric,
  email_subscribers integer,
  -- Verification
  stats_verified boolean default false,
  stats_verified_at timestamptz,
  -- Demographics
  audience_uk_pct numeric,
  audience_female_pct numeric,
  top_age_group text,
  -- History
  account_age_months integer,
  created_at timestamptz default now()
);

-- ── DOCUMENTS ──
create table if not exists public.listing_documents (
  id uuid default uuid_generate_v4() primary key,
  listing_id uuid references public.listings(id) on delete cascade not null,
  name text not null,
  file_url text not null,
  file_type text,
  file_size integer,
  is_hidden boolean default true,
  doc_type text, -- accounts, lease, hygiene, licence, other
  uploaded_at timestamptz default now()
);

-- ── DOCUMENT ACCESS REQUESTS ──
create table if not exists public.document_access_requests (
  id uuid default uuid_generate_v4() primary key,
  listing_id uuid references public.listings(id) on delete cascade not null,
  buyer_id uuid references public.profiles(id) on delete cascade not null,
  seller_id uuid references public.profiles(id) not null,
  status text default 'pending' check (status in ('pending','approved','declined')),
  message text,
  responded_at timestamptz,
  created_at timestamptz default now()
);

-- ── ENQUIRIES ──
create table if not exists public.enquiries (
  id uuid default uuid_generate_v4() primary key,
  listing_id uuid references public.listings(id) on delete cascade not null,
  buyer_id uuid references public.profiles(id) on delete cascade not null,
  seller_id uuid references public.profiles(id) not null,
  -- Buyer passport snapshot at time of enquiry
  buyer_budget text,
  buyer_finance text,
  buyer_passport_ref text,
  -- Message
  initial_message text,
  status text default 'new' check (status in ('new','read','replied','progressing','completed','cancelled')),
  seller_notified_sms boolean default false,
  seller_notified_email boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ── MESSAGES (threaded per enquiry) ──
create table if not exists public.messages (
  id uuid default uuid_generate_v4() primary key,
  enquiry_id uuid references public.enquiries(id) on delete cascade not null,
  sender_id uuid references public.profiles(id) not null,
  body text not null,
  is_read boolean default false,
  created_at timestamptz default now()
);

-- ── SAVED LISTINGS ──
create table if not exists public.saved_listings (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  listing_id uuid references public.listings(id) on delete cascade not null,
  created_at timestamptz default now(),
  unique(user_id, listing_id)
);

-- ── SOLD PRICES (comparable sales database) ──
create table if not exists public.sold_prices (
  id uuid default uuid_generate_v4() primary key,
  listing_id uuid references public.listings(id),
  sector text not null,
  city text,
  region text,
  sold_price numeric not null,
  weekly_turnover numeric,
  premises_size text,
  tenure_type text,
  sold_at timestamptz default now(),
  days_to_sell integer,
  is_digital boolean default false,
  platform text
);

-- ── VALUATIONS ──
create table if not exists public.valuations (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id),
  sector text,
  location text,
  weekly_turnover numeric,
  annual_profit numeric,
  years_trading text,
  tenure_type text,
  lease_remaining text,
  valuation_low numeric,
  valuation_high numeric,
  valuation_mid numeric,
  ai_reasoning text,
  created_at timestamptz default now()
);

-- ── NOTIFICATIONS LOG ──
create table if not exists public.notifications (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  type text not null, -- enquiry, message, match, verification, sale
  title text not null,
  body text,
  is_read boolean default false,
  metadata jsonb,
  created_at timestamptz default now()
);

-- ── PLATFORM STATS (for urgency bar / admin) ──
create table if not exists public.platform_stats (
  id uuid default uuid_generate_v4() primary key,
  stat_key text unique not null,
  stat_value text not null,
  updated_at timestamptz default now()
);

-- Seed platform stats
insert into public.platform_stats (stat_key, stat_value) values
  ('active_listings', '1247'),
  ('monthly_buyers', '94000'),
  ('sales_this_month', '7'),
  ('avg_days_to_sell', '18'),
  ('digital_listings', '312'),
  ('avg_first_enquiry_hours', '4')
on conflict (stat_key) do nothing;

-- ════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ════════════════════════════════

alter table public.profiles enable row level security;
alter table public.buyer_passports enable row level security;
alter table public.listings enable row level security;
alter table public.digital_listings enable row level security;
alter table public.listing_documents enable row level security;
alter table public.document_access_requests enable row level security;
alter table public.enquiries enable row level security;
alter table public.messages enable row level security;
alter table public.saved_listings enable row level security;
alter table public.sold_prices enable row level security;
alter table public.valuations enable row level security;
alter table public.notifications enable row level security;
alter table public.platform_stats enable row level security;

-- PROFILES: users can read all, edit own
create policy "Profiles are viewable by everyone" on public.profiles for select using (true);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

-- BUYER PASSPORTS: owner can CRUD, others can read basic info
create policy "Passport owner full access" on public.buyer_passports for all using (auth.uid() = user_id);
create policy "Others can view passports" on public.buyer_passports for select using (true);

-- LISTINGS: anyone can read live listings, sellers manage own
create policy "Live listings viewable by all" on public.listings for select using (status = 'live' or auth.uid() = seller_id);
create policy "Sellers manage own listings" on public.listings for all using (auth.uid() = seller_id);
create policy "Anyone can create listing" on public.listings for insert with check (auth.uid() = seller_id);

-- DIGITAL LISTINGS: public read
create policy "Digital listings public read" on public.digital_listings for select using (true);
create policy "Sellers manage digital listings" on public.digital_listings for all using (
  exists(select 1 from public.listings where id = listing_id and seller_id = auth.uid())
);

-- DOCUMENTS: hidden by default, sellers manage own
create policy "Sellers manage own documents" on public.listing_documents for all using (
  exists(select 1 from public.listings where id = listing_id and seller_id = auth.uid())
);
create policy "Non-hidden docs viewable" on public.listing_documents for select using (is_hidden = false);

-- ENQUIRIES: buyer and seller can see their own
create policy "Enquiry parties can view" on public.enquiries for select using (auth.uid() = buyer_id or auth.uid() = seller_id);
create policy "Buyers can create enquiries" on public.enquiries for insert with check (auth.uid() = buyer_id);
create policy "Parties can update enquiries" on public.enquiries for update using (auth.uid() = buyer_id or auth.uid() = seller_id);

-- MESSAGES: enquiry participants only
create policy "Message participants can view" on public.messages for select using (
  exists(select 1 from public.enquiries where id = enquiry_id and (buyer_id = auth.uid() or seller_id = auth.uid()))
);
create policy "Message participants can send" on public.messages for insert with check (
  exists(select 1 from public.enquiries where id = enquiry_id and (buyer_id = auth.uid() or seller_id = auth.uid()))
);

-- SAVED LISTINGS: own only
create policy "Users manage own saved" on public.saved_listings for all using (auth.uid() = user_id);

-- SOLD PRICES, PLATFORM STATS: public read
create policy "Sold prices public read" on public.sold_prices for select using (true);
create policy "Platform stats public read" on public.platform_stats for select using (true);

-- VALUATIONS: own only
create policy "Users manage own valuations" on public.valuations for all using (auth.uid() = user_id);

-- NOTIFICATIONS: own only
create policy "Users see own notifications" on public.notifications for all using (auth.uid() = user_id);

-- ════════════════════════════
-- FUNCTIONS & TRIGGERS
-- ════════════════════════════

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, first_name, last_name)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Auto-update trust score when listing changes
create or replace function public.calculate_trust_score(listing_uuid uuid)
returns integer language plpgsql as $$
declare
  score integer := 0;
  rec record;
begin
  select * into rec from public.listings where id = listing_uuid;
  if rec.description is not null and length(rec.description) > 100 then score := score + 20; end if;
  if rec.asking_price is not null then score := score + 15; end if;
  if rec.weekly_turnover is not null then score := score + 15; end if;
  if rec.annual_profit is not null then score := score + 10; end if;
  if array_length(rec.photos, 1) > 0 then score := score + 15; end if;
  if rec.video_url is not null then score := score + 10; end if;
  if exists(select 1 from public.listing_documents where listing_id = listing_uuid and doc_type = 'accounts') then score := score + 15; end if;
  -- Check seller ID verified
  if exists(select 1 from public.profiles where id = rec.seller_id and id_verified = true) then score := score + 20; end if;
  -- Cap at 100
  if score > 100 then score := 100; end if;
  return score;
end;
$$;

-- Update updated_at automatically
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger listings_updated_at before update on public.listings for each row execute procedure public.set_updated_at();
create trigger profiles_updated_at before update on public.profiles for each row execute procedure public.set_updated_at();
create trigger enquiries_updated_at before update on public.enquiries for each row execute procedure public.set_updated_at();

-- ════════════════
-- INDEXES
-- ════════════════
create index if not exists idx_listings_status on public.listings(status);
create index if not exists idx_listings_sector on public.listings(sector);
create index if not exists idx_listings_region on public.listings(region);
create index if not exists idx_listings_seller on public.listings(seller_id);
create index if not exists idx_enquiries_buyer on public.enquiries(buyer_id);
create index if not exists idx_enquiries_seller on public.enquiries(seller_id);
create index if not exists idx_messages_enquiry on public.messages(enquiry_id);
create index if not exists idx_notifications_user on public.notifications(user_id);

