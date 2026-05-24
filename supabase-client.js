// ============================================
// VENTUREVAULT — SUPABASE CLIENT
// Include this in every HTML page
// ============================================

const SUPABASE_URL = 'https://azmjhgvkweaibdbntzze.supabase.co'
const SUPABASE_ANON_KEY = 'sb_publishable_RW2tSWtiL6aVq_rlEhnD3w__WhSv5Ve'

// Load Supabase from CDN — add this script tag to every HTML page:
// <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
// <script src="supabase-client.js"></script>

const { createClient } = supabase
const db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// ── AUTH HELPERS ──

async function signUp(email, password, firstName, lastName) {
  const { data, error } = await db.auth.signUp({
    email, password,
    options: { data: { first_name: firstName, last_name: lastName } }
  })
  if (error) throw error
  return data
}

async function signIn(email, password) {
  const { data, error } = await db.auth.signInWithPassword({ email, password })
  if (error) throw error
  return data
}

async function signOut() {
  const { error } = await db.auth.signOut()
  if (error) throw error
}

async function getUser() {
  const { data: { user } } = await db.auth.getUser()
  return user
}

async function getProfile(userId) {
  const { data, error } = await db.from('profiles').select('*').eq('id', userId).single()
  if (error) throw error
  return data
}

// ── LISTINGS ──

async function getListings({ sector, region, minPrice, maxPrice, status = 'live', limit = 20, offset = 0 } = {}) {
  let query = db.from('listings').select(`
    *, 
    profiles!seller_id(first_name, last_name, id_verified),
    digital_listings(*),
    listing_documents(id, doc_type, is_hidden)
  `).eq('status', status).order('created_at', { ascending: false }).range(offset, offset + limit - 1)

  if (sector) query = query.eq('sector', sector)
  if (region) query = query.eq('region', region)
  if (minPrice) query = query.gte('asking_price', minPrice)
  if (maxPrice) query = query.lte('asking_price', maxPrice)

  const { data, error } = await query
  if (error) throw error
  return data
}

async function getListing(id) {
  const { data, error } = await db.from('listings').select(`
    *,
    profiles!seller_id(first_name, last_name, id_verified, phone, created_at),
    digital_listings(*),
    listing_documents(id, name, doc_type, is_hidden, file_type)
  `).eq('id', id).single()
  if (error) throw error
  return data
}

async function createListing(listingData) {
  const user = await getUser()
  if (!user) throw new Error('Must be logged in to create a listing')
  const { data, error } = await db.from('listings').insert({
    ...listingData,
    seller_id: user.id,
    status: 'pending'
  }).select().single()
  if (error) throw error
  return data
}

async function updateListing(id, updates) {
  const { data, error } = await db.from('listings').update(updates).eq('id', id).select().single()
  if (error) throw error
  return data
}

// ── ENQUIRIES ──

async function sendEnquiry(listingId, sellerId, message) {
  const user = await getUser()
  if (!user) throw new Error('Must be logged in to enquire')

  // Get buyer passport
  const { data: passport } = await db.from('buyer_passports').select('*').eq('user_id', user.id).single()

  const { data, error } = await db.from('enquiries').insert({
    listing_id: listingId,
    buyer_id: user.id,
    seller_id: sellerId,
    initial_message: message,
    buyer_budget: passport?.max_budget,
    buyer_finance: passport?.finance_status,
    buyer_passport_ref: passport?.passport_ref,
    status: 'new'
  }).select().single()
  if (error) throw error
  return data
}

async function getMyEnquiries(role = 'buyer') {
  const user = await getUser()
  if (!user) throw new Error('Not logged in')
  const field = role === 'buyer' ? 'buyer_id' : 'seller_id'
  const { data, error } = await db.from('enquiries').select(`
    *,
    listings(title, city, asking_price, photos),
    profiles!buyer_id(first_name, last_name),
    messages(id)
  `).eq(field, user.id).order('created_at', { ascending: false })
  if (error) throw error
  return data
}

// ── MESSAGES ──

async function sendMessage(enquiryId, body) {
  const user = await getUser()
  const { data, error } = await db.from('messages').insert({
    enquiry_id: enquiryId,
    sender_id: user.id,
    body
  }).select().single()
  if (error) throw error

  // Update enquiry updated_at
  await db.from('enquiries').update({ updated_at: new Date() }).eq('id', enquiryId)

  return data
}

async function getMessages(enquiryId) {
  const { data, error } = await db.from('messages').select(`
    *, profiles!sender_id(first_name, last_name)
  `).eq('enquiry_id', enquiryId).order('created_at', { ascending: true })
  if (error) throw error
  return data
}

// Mark messages as read
async function markMessagesRead(enquiryId) {
  const user = await getUser()
  await db.from('messages')
    .update({ is_read: true })
    .eq('enquiry_id', enquiryId)
    .neq('sender_id', user.id)
}

// ── BUYER PASSPORT ──

async function saveBuyerPassport(passportData) {
  const user = await getUser()
  if (!user) throw new Error('Must be logged in')
  const ref = 'VV-' + new Date().getFullYear() + '-' + Math.floor(1000 + Math.random() * 9000)
  const { data, error } = await db.from('buyer_passports').upsert({
    user_id: user.id,
    passport_ref: ref,
    ...passportData,
    updated_at: new Date()
  }, { onConflict: 'user_id' }).select().single()
  if (error) throw error
  return data
}

async function getMyPassport() {
  const user = await getUser()
  if (!user) return null
  const { data } = await db.from('buyer_passports').select('*').eq('user_id', user.id).single()
  return data
}

// ── SAVED LISTINGS ──

async function toggleSaved(listingId) {
  const user = await getUser()
  if (!user) throw new Error('Must be logged in')
  const { data: existing } = await db.from('saved_listings')
    .select('id').eq('user_id', user.id).eq('listing_id', listingId).single()

  if (existing) {
    await db.from('saved_listings').delete().eq('id', existing.id)
    return false
  } else {
    await db.from('saved_listings').insert({ user_id: user.id, listing_id: listingId })
    return true
  }
}

async function getSavedListings() {
  const user = await getUser()
  if (!user) return []
  const { data, error } = await db.from('saved_listings').select(`
    *, listings(id, title, city, asking_price, weekly_turnover, photos, sector, trust_score, status)
  `).eq('user_id', user.id)
  if (error) throw error
  return data
}

// ── PROFILE MATCH ──

function calculateMatch(listing, passport) {
  if (!passport) return 0
  let score = 0
  let factors = []

  // Budget match
  const price = listing.asking_price
  const budgetMap = {
    'Under £50,000': 50000, 'Under £100,000': 100000,
    'Under £250,000': 250000, 'Under £500,000': 500000, '£1,000,000+': 9999999
  }
  const maxBudget = budgetMap[passport.max_budget] || 0
  if (price <= maxBudget) { score += 30; factors.push({ yes: true, text: '✓ Within budget' }) }
  else { factors.push({ yes: false, text: '✗ Over budget' }) }

  // Sector match
  if (passport.preferred_sectors?.some(s => listing.sector?.includes(s.split(' ')[1] || s))) {
    score += 25; factors.push({ yes: true, text: '✓ Preferred sector' })
  } else { factors.push({ yes: false, text: '✗ Not preferred sector' }) }

  // Location match
  if (passport.preferred_location === 'Any UK Region' ||
      listing.region?.toLowerCase().includes(passport.preferred_location?.toLowerCase())) {
    score += 20; factors.push({ yes: true, text: '✓ Location match' })
  } else { factors.push({ yes: false, text: '✗ Different region' }) }

  // Verified seller
  if (listing.profiles?.id_verified) { score += 15; factors.push({ yes: true, text: '✓ Seller verified' }) }
  else { factors.push({ yes: false, text: '✗ Seller not yet verified' }) }

  // Documents available
  if (listing.listing_documents?.length > 0) { score += 10; factors.push({ yes: true, text: '✓ Documents available' }) }

  return { score: Math.min(score, 100), factors }
}

// ── FILE UPLOADS ──

async function uploadPhoto(file, listingId) {
  const user = await getUser()
  if (!user) throw new Error('Must be logged in')
  const ext = file.name.split('.').pop()
  const path = `${listingId}/${Date.now()}.${ext}`
  const { data, error } = await db.storage.from('listing-photos').upload(path, file)
  if (error) throw error
  const { data: url } = db.storage.from('listing-photos').getPublicUrl(path)
  return url.publicUrl
}

async function uploadDocument(file, listingId, docType) {
  const user = await getUser()
  const ext = file.name.split('.').pop()
  const path = `${listingId}/${docType}-${Date.now()}.${ext}`
  const { data, error } = await db.storage.from('listing-documents').upload(path, file)
  if (error) throw error
  // Documents are private — return path not public URL
  return path
}

// ── REAL-TIME SUBSCRIPTIONS ──

function subscribeToMessages(enquiryId, callback) {
  return db.channel(`messages:${enquiryId}`)
    .on('postgres_changes', {
      event: 'INSERT', schema: 'public', table: 'messages',
      filter: `enquiry_id=eq.${enquiryId}`
    }, callback)
    .subscribe()
}

function subscribeToEnquiries(sellerId, callback) {
  return db.channel(`enquiries:${sellerId}`)
    .on('postgres_changes', {
      event: 'INSERT', schema: 'public', table: 'enquiries',
      filter: `seller_id=eq.${sellerId}`
    }, callback)
    .subscribe()
}

// ── PLATFORM STATS ──

async function getPlatformStats() {
  const { data } = await db.from('platform_stats').select('*')
  if (!data) return {}
  return data.reduce((acc, row) => ({ ...acc, [row.stat_key]: row.stat_value }), {})
}

// ── NOTIFICATIONS ──

async function getNotifications() {
  const user = await getUser()
  if (!user) return []
  const { data } = await db.from('notifications').select('*')
    .eq('user_id', user.id).order('created_at', { ascending: false }).limit(20)
  return data || []
}

async function markNotificationRead(id) {
  await db.from('notifications').update({ is_read: true }).eq('id', id)
}

console.log('✅ VentureVault Supabase client loaded')
