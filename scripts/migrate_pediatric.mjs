// Copies pediatric surgery waiting-list rows (and their images) between two
// Supabase projects. Safe to re-run: rows are upserted by id, files are upserted.
//
// Usage (PowerShell):
//   $env:SRC_URL='https://<src>.supabase.co'; $env:SRC_KEY='sb_publishable_...'
//   $env:DST_URL='https://<dst>.supabase.co'; $env:DST_KEY='sb_publishable_...'
//   node scripts/migrate_pediatric.mjs

const { SRC_URL, SRC_KEY, DST_URL, DST_KEY } = process.env;
if (!SRC_URL || !SRC_KEY || !DST_URL || !DST_KEY) {
  console.error('Set SRC_URL, SRC_KEY, DST_URL and DST_KEY.');
  process.exit(1);
}

const TABLE = 'pediatric_surgery_waiting_patients';
const BUCKET = 'pediatric_surgery_patient_images';

const headers = (key, extra = {}) => ({
  apikey: key,
  Authorization: `Bearer ${key}`,
  ...extra,
});

async function ok(res, what) {
  if (!res.ok) throw new Error(`${what} failed: ${res.status} ${await res.text()}`);
  return res;
}

const rows = (
  await (
    await ok(await fetch(`${SRC_URL}/rest/v1/${TABLE}?select=*&order=created_at.asc`, { headers: headers(SRC_KEY) }), 'read source rows')
  ).json()
).map(({ called, ...row }) => row); // `called` is unused by the app and absent in the destination table
console.log(`Source rows: ${rows.length}`);

for (let i = 0; i < rows.length; i += 100) {
  const batch = rows.slice(i, i + 100);
  await ok(
    await fetch(`${DST_URL}/rest/v1/${TABLE}?on_conflict=id`, {
      method: 'POST',
      headers: headers(DST_KEY, {
        'Content-Type': 'application/json',
        Prefer: 'resolution=merge-duplicates,return=minimal',
      }),
      body: JSON.stringify(batch),
    }),
    `insert rows ${i}-${i + batch.length}`,
  );
  console.log(`Inserted ${i + batch.length}/${rows.length}`);
}

const paths = [...new Set(rows.flatMap((r) => (r.images ?? []).map((img) => img.path).filter(Boolean)))];
console.log(`Images to copy: ${paths.length}`);
let copied = 0;
const failed = [];
for (const path of paths) {
  try {
    const encoded = path.split('/').map(encodeURIComponent).join('/');
    const sign = await (
      await ok(
        await fetch(`${SRC_URL}/storage/v1/object/sign/${BUCKET}/${encoded}`, {
          method: 'POST',
          headers: headers(SRC_KEY, { 'Content-Type': 'application/json' }),
          body: JSON.stringify({ expiresIn: 300 }),
        }),
        'sign',
      )
    ).json();
    const file = await ok(await fetch(`${SRC_URL}/storage/v1${sign.signedURL}`), 'download');
    const type = file.headers.get('content-type') ?? 'application/octet-stream';
    await ok(
      await fetch(`${DST_URL}/storage/v1/object/${BUCKET}/${encoded}`, {
        method: 'POST',
        headers: headers(DST_KEY, { 'Content-Type': type, 'x-upsert': 'true' }),
        body: Buffer.from(await file.arrayBuffer()),
      }),
      'upload',
    );
    copied++;
  } catch (e) {
    failed.push(`${path}: ${e.message}`);
  }
}
console.log(`Images copied: ${copied}/${paths.length}`);
if (failed.length) console.log('Failed images:\n' + failed.join('\n'));

const count = await fetch(`${DST_URL}/rest/v1/${TABLE}?select=id`, {
  headers: headers(DST_KEY, { Prefer: 'count=exact', Range: '0-0' }),
});
console.log(`Destination rows now: ${count.headers.get('content-range')}`);
