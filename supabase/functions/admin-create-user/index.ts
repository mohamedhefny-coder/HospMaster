// Creates a confirmed user account on behalf of an admin and approves the
// chosen services. Needs the service-role key, so it must run server-side.
//
// Deploy:  supabase functions deploy admin-create-user
// (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase.)
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const allowedServices = [
  'general_surgery',
  'oncology_surgery',
  'pediatric_surgery',
  'obgyn_clinic',
  'pediatrics_clinic',
];

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
  const { data: caller } = await admin.auth.getUser(token);
  if (!caller.user || caller.user.app_metadata?.role !== 'admin') {
    return json({ error: 'Only admins can create accounts.' }, 403);
  }

  let payload: { email?: string; password?: string; services?: string[] };
  try {
    payload = await req.json();
  } catch (_) {
    return json({ error: 'Invalid request body.' }, 400);
  }

  const email = (payload.email ?? '').trim().toLowerCase();
  const password = payload.password ?? '';
  const services = [...new Set(payload.services ?? [])];
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return json({ error: 'Enter a valid email.' }, 400);
  }
  if (password.length < 6) {
    return json({ error: 'Password must be at least 6 characters.' }, 400);
  }
  if (services.length === 0 || services.some((s) => !allowedServices.includes(s))) {
    return json({ error: 'Pick at least one valid service.' }, 400);
  }

  const created = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (created.error || !created.data.user) {
    return json({ error: created.error?.message ?? 'Could not create the user.' }, 400);
  }
  const userId = created.data.user.id;

  // The email may already have rows (pre-approved or requested earlier).
  const { data: existing, error: selectError } = await admin
    .from('service_access')
    .select('id, service')
    .eq('email', email);
  if (selectError) return json({ error: selectError.message }, 500);

  const decision = {
    status: 'approved',
    decided_at: new Date().toISOString(),
    decided_by: caller.user.id,
  };
  const known = new Map((existing ?? []).map((row) => [row.service, row.id]));
  for (const service of services) {
    const id = known.get(service);
    const result = id
      ? await admin.from('service_access').update({ ...decision, user_id: userId }).eq('id', id)
      : await admin
          .from('service_access')
          .insert({ ...decision, user_id: userId, email, service });
    if (result.error) return json({ error: result.error.message }, 500);
  }

  return json({ user_id: userId, email });
});
