# VentureVault — Complete Setup Guide
## From zero to fully live in under 2 hours

---

## STEP 1 — Run the Database Schema (5 minutes)

1. Go to https://supabase.com and open your VentureVault project
2. Click **SQL Editor** in the left sidebar
3. Click **New Query**
4. Open the file `supabase-setup.sql` and copy ALL of its contents
5. Paste into the SQL editor and click **Run**
6. You should see "Success. No rows returned"

This creates every table, all security rules, and all automatic functions.

---

## STEP 2 — Create Storage Buckets (3 minutes)

In Supabase, go to **Storage** → **New Bucket** and create these two:

| Bucket Name | Public? |
|---|---|
| `listing-photos` | ✅ Yes (public) |
| `listing-documents` | ❌ No (private) |

---

## STEP 3 — Add the Client File to Your Pages (2 minutes)

Add these two lines inside the `<head>` of every HTML page:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="supabase-client.js"></script>
```

Then put `supabase-client.js` in the same folder as your HTML files.

---

## STEP 4 — Deploy to Vercel (10 minutes)

1. Go to https://github.com and create a free account if you don't have one
2. Create a **New Repository** called `venturevault`
3. Upload all your HTML files and `supabase-client.js` to the repository
4. Go to https://vercel.com and sign in with GitHub
5. Click **Add New Project** → select your `venturevault` repo
6. Click **Deploy** — Vercel builds and deploys in about 60 seconds
7. Your site is now live at `venturevault.vercel.app`

---

## STEP 5 — Add Your Domain (10 minutes)

1. Buy `venturevault.co.uk` from Namecheap (~£12/year)
2. In Vercel → your project → **Domains** → Add `venturevault.co.uk`
3. Vercel gives you DNS records to add in Namecheap
4. In Namecheap → **Advanced DNS** → add the records Vercel shows you
5. Wait 10–30 minutes for DNS to propagate
6. Your site is now live at `venturevault.co.uk` with SSL automatically

---

## STEP 6 — Connect Stripe Identity (ID Verification)

1. Go to https://stripe.com → create account
2. Go to **Identity** → **Settings** → get your publishable key
3. Add to `supabase-client.js`:
   ```js
   const STRIPE_KEY = 'pk_live_your_key_here'
   ```
4. When a user completes verification, Stripe sends a webhook
5. In Supabase → **Edge Functions** → I'll write the webhook handler for you

---

## STEP 7 — Connect Twilio SMS (Instant Notifications)

1. Go to https://twilio.com → create account
2. Get a UK phone number (~£1/month)
3. Copy your Account SID and Auth Token
4. In Supabase → **Edge Functions** → add these as secrets
5. I'll write the SMS trigger function — fires automatically on new enquiry

---

## STEP 8 — Connect Resend Email

1. Go to https://resend.com → free account
2. Verify your sending domain (venturevault.co.uk)
3. Copy your API key
4. Add to Supabase secrets
5. I'll write the email templates — one for each event type

---

## WHAT WORKS IMMEDIATELY AFTER STEP 1–3

After running the SQL and adding the client file:

✅ User registration and login  
✅ Seller listing submission — saves to database  
✅ Buyer passport creation — saves to database  
✅ Enquiry sending — saves to database  
✅ Messaging between buyer and seller  
✅ Saved listings  
✅ Real-time messages (instant, no refresh needed)  
✅ Profile match calculation  
✅ Admin can see all data in Supabase dashboard  

---

## DATABASE TABLES CREATED

| Table | Purpose |
|---|---|
| `profiles` | All user accounts |
| `buyer_passports` | Buyer passport data |
| `listings` | All business listings |
| `digital_listings` | Extra data for YouTube/Instagram/Shopify etc |
| `listing_documents` | Uploaded documents (accounts, lease etc) |
| `document_access_requests` | Buyer requests to see hidden documents |
| `enquiries` | All buyer enquiries |
| `messages` | Messages within each enquiry thread |
| `saved_listings` | Buyers' saved/favourited listings |
| `sold_prices` | Comparable sales database |
| `valuations` | AI valuation history |
| `notifications` | In-app notification log |
| `platform_stats` | Live numbers for urgency bar |

---

## NEED HELP?

If anything goes wrong at any step, just tell me exactly what error message you see and I'll fix it immediately.

