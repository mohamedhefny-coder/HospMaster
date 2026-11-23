// Copies pediatric surgery waiting-list rows (and their images) between two
// Supabase projects. Safe to re-run: rows are upserted by id, files are upserted.
//
// Usage (PowerShell):
//   $env:SRC_URL='https://<src>.supabase.co'; $env:SRC_KEY='sb_publishable_...'
//   $env:DST_URL='https://<dst>.supabase.co'; $env:DST_KEY='sb_secret_...'
//   node scripts/migrate_pediatric.mjs
//
// Add `$env:MODE='sync'` to only add missing patients/images instead of
// overwriting rows that already exist in the destination.
//
// Once 20261118_service_access.sql is applied, the destination tables and
// bucket only accept signed-in users with the service, so DST_KEY must be the
// project's secret (service role) key from Settings > API Keys. Keep it local;
// never commit it or put it in the app.

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

// MODE=sync is non-destructive: it only adds source rows missing in the
// destination (matched by id or by name) and merges in missing images of rows
// that share the same id. Other fields of existing rows are never changed.
const SYNC = process.env.MODE === 'sync';

const normName = (s) => (s ?? '').replace(/\s+/g, ' ').trim().toLowerCase();

async function readAll(url, key, select) {
  const out = [];
  for (let from = 0; ; from += 1000) {
    const page = await (
      await ok(
        await fetch(`${url}/rest/v1/${TABLE}?select=${select}&order=created_at.asc`, {
          headers: headers(key, { Range: `${from}-${from + 999}` }),
        }),
        'read rows',
      )
    ).json();
    out.push(...page);
    if (page.length < 1000) return out;
  }
}

// `called` is unused by the app and absent in the destination table
const sourceRows = (await readAll(SRC_URL, SRC_KEY, '*')).map(({ called, ...row }) => row);
console.log(`Source rows: ${sourceRows.length}`);

let rows = sourceRows;
const imagePatches = [];
const syncImagePaths = new Set();
if (SYNC) {
  const dstRows = await readAll(DST_URL, DST_KEY, 'id,name,images');
  const dstById = new Map(dstRows.map((r) => [r.id, r]));
  const dstNames = new Set(dstRows.map((r) => normName(r.name)));
  rows = [];
  let skippedByName = 0;
  for (const src of sourceRows) {
    const dst = dstById.get(src.id);
    if (!dst) {
      if (dstNames.has(normName(src.name))) {
        skippedByName++;
      } else {
        rows.push(src);
        (src.images ?? []).forEach((img) => img.path && syncImagePaths.add(img.path));
      }
      continue;
    }
    const have = new Set((dst.images ?? []).map((img) => img.path));
    const added = (src.images ?? []).filter((img) => img.path && !have.has(img.path));
    if (added.length) {
      imagePatches.push({ id: src.id, images: [...(dst.images ?? []), ...added] });
      added.forEach((img) => syncImagePaths.add(img.path));
    }
  }
  console.log(
    `Sync: ${rows.length} new rows, ${imagePatches.length} rows get extra images, ` +
      `${skippedByName} skipped (same name already exists with a different id).`,
  );
}

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

for (const patch of imagePatches) {
  await ok(
    await fetch(`${DST_URL}/rest/v1/${TABLE}?id=eq.${patch.id}`, {
      method: 'PATCH',
      headers: headers(DST_KEY, { 'Content-Type': 'application/json', Prefer: 'return=minimal' }),
      body: JSON.stringify({ images: patch.images }),
    }),
    `update images of ${patch.id}`,
  );
}

const paths = SYNC
  ? [...syncImagePaths]
  : [...new Set(rows.flatMap((r) => (r.images ?? []).map((img) => img.path).filter(Boolean)))];
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
