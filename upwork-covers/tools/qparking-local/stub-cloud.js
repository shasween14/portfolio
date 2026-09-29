/**
 * Stand-ins for the two things a gate PC talks to that are not on this machine:
 *
 *   1. the qparking SaaS  — GET /api/v1/local-server/*   (the cloud mirrors)
 *   2. a Touch'n'Go W4G payment device — POST /w4g/PayRequest, then it calls
 *      the box back on /w4g/PayResult
 *
 * Both speak the real contracts (see app/src/main/services/cloud-sync.ts and
 * payment-tng.ts); the box is not modified or stubbed in any way. Every row
 * served here is invented — no client site, customer or plate appears.
 */
const http = require('http');

// ─── demo dataset ────────────────────────────────────────────────────────────

const SITE = {
  id: 'site-3f9c2a',
  company_id: 'co-118',
  name: 'Lagoon Central Parking',
  address: 'Jalan Seri Muara, 50480 Kuala Lumpur',
  total_spaces: 420,
  occupied_spaces: 137,
  status: 'active',
  contact_person: 'Faridah Osman',
  telephone: '+60 3-2118 4400',
  country: 'Malaysia',
  email: 'ops@lagooncentral.example',
  parking_site_type: 'Commercial',
};

const COMPANY_SETTINGS = {
  id: 'cs-118',
  company_id: 'co-118',
  season_pass_grace_days: 30,
  sync_capture_images: 1,
  sync_interval_minutes: 60,
};

const RATE_POLICIES = [
  {
    id: 'pol-std',
    policy_name: 'Standard Hourly',
    description: 'Public rate. 15 minutes free, RM2.00 first hour, RM1.50 after, capped at RM15.00 a day.',
    is_site_default: 1,
    grace_minutes: 15,
    currency: 'MYR',
    daily_cap_cents: 1500,
    grace_exceeded_behavior: 'charge_from_entry',
    // Priority decides which rule owns a given moment, and the box mirrors the
    // highest-priority ACTIVE rule into the headline columns of the overview —
    // so the daytime block rule is the one that ranks top, and the flat rules
    // cover only the hours it does not.
    rules: [
      {
        rule_id: 'r-std-weekday', name: 'Weekdays 06:00–22:00', priority: 30,
        days_of_week: [1, 2, 3, 4, 5], time_from: '06:00:00', time_to: '22:00:00',
        rule_type: 'block_hourly',
        first_block_amount_cents: 200, first_block_minutes: 60,
        subsequent_block_amount_cents: 150, subsequent_block_minutes: 60,
        daily_cap_cents: 1500, is_active: 1,
      },
      {
        rule_id: 'r-std-night', name: 'Overnight 22:00–06:00', priority: 20,
        time_from: '22:00:00', time_to: '06:00:00',
        rule_type: 'flat_rate', flat_amount_cents: 800, is_overnight: 1, is_active: 1,
      },
      {
        rule_id: 'r-std-weekend', name: 'Weekends', priority: 10,
        days_of_week: [0, 6], time_from: '00:00:00', time_to: '23:59:59',
        rule_type: 'flat_rate', flat_amount_cents: 500, daily_cap_cents: 500, is_active: 1,
      },
    ],
  },
  {
    id: 'pol-event',
    policy_name: 'Event Day',
    description: 'Concert and expo days. RM10.00 covers the first three hours, RM5.00 an hour after that.',
    is_site_default: 0,
    grace_minutes: 0,
    currency: 'MYR',
    daily_cap_cents: 2000,
    rules: [
      {
        rule_id: 'r-event-block', name: 'Event block rate', priority: 10,
        time_from: '00:00:00', time_to: '23:59:59',
        rule_type: 'block_hourly',
        first_block_amount_cents: 1000, first_block_minutes: 180,
        subsequent_block_amount_cents: 500, subsequent_block_minutes: 60,
        daily_cap_cents: 2000, is_active: 1,
      },
    ],
  },
  {
    id: 'pol-moto',
    policy_name: 'Motorcycle',
    description: 'Two-wheelers. RM1.00 the first hour, RM0.50 after, capped at RM3.00.',
    is_site_default: 0,
    grace_minutes: 30,
    currency: 'MYR',
    daily_cap_cents: 300,
    rules: [
      {
        rule_id: 'r-moto-block', name: 'Two-wheeler rate', priority: 10,
        time_from: '00:00:00', time_to: '23:59:59',
        rule_type: 'block_hourly',
        first_block_amount_cents: 100, first_block_minutes: 60,
        subsequent_block_amount_cents: 50, subsequent_block_minutes: 60,
        daily_cap_cents: 300, is_active: 1,
      },
    ],
  },
];

const SEASON_PASSES = [
  {
    id: 'pass-2041', plates: ['WXY4821', 'WQE3390'], role: 'resident', status: 'active',
    start_date: '2026-01-01', end_date: '2026-12-31', concurrent_limit: 1,
    plan: 'Resident Monthly — 1 bay',
  },
  {
    id: 'pass-2042', plates: ['JPQ1188'], role: 'staff', status: 'active',
    start_date: '2026-03-01', end_date: '2027-02-28', concurrent_limit: 1,
    plan: 'Staff Annual',
  },
  {
    id: 'pass-2043', plates: ['BMT7342', 'BNS5521', 'VAB9087'], role: 'season', status: 'active',
    start_date: '2026-07-01', end_date: '2026-12-31', concurrent_limit: 2,
    plan: 'Corporate Pool — 2 bays',
  },
  {
    id: 'pass-2044', plates: ['PKM6610'], role: 'visitor', status: 'active',
    start_date: '2026-09-01', end_date: '2026-09-30', concurrent_limit: 1,
    plan: 'Visitor Weekly',
  },
];

const BLOCKED = [
  { plate_number: 'WPL2233', vehicle_id: 'veh-909', reason: 'Repeated non-payment' },
  { plate_number: 'KEV7781', vehicle_id: 'veh-912', reason: 'Tailgating incident — 2026-08-30' },
];

const CUSTOMERS = [
  { id: 'cus-401', full_name: 'Faridah Osman', email: 'faridah.osman@example.com', phone: '+60 12-330 8841', holder_type: 'resident', season_pass_status: 'active', is_enabled: 1, vehicles_count: 2, active_passes_count: 1, last_sign_in: '2026-09-16T09:12:00Z', created_at: '2025-11-02T02:15:00Z' },
  { id: 'cus-402', full_name: 'Daniel Teoh', email: 'daniel.teoh@example.com', phone: '+60 16-882 1170', holder_type: 'staff', season_pass_status: 'active', is_enabled: 1, vehicles_count: 1, active_passes_count: 1, last_sign_in: '2026-09-15T23:40:00Z', created_at: '2026-02-19T06:30:00Z' },
  { id: 'cus-403', full_name: 'Meera Rajan', email: 'meera.rajan@example.com', phone: '+60 11-2244 9083', holder_type: 'season', season_pass_status: 'active', is_enabled: 1, vehicles_count: 3, active_passes_count: 1, last_sign_in: '2026-09-14T01:05:00Z', created_at: '2026-06-28T08:00:00Z' },
  { id: 'cus-404', full_name: 'Azrul Hakim', email: 'azrul.hakim@example.com', phone: '+60 13-707 6612', holder_type: 'visitor', season_pass_status: 'active', is_enabled: 1, vehicles_count: 1, active_passes_count: 1, last_sign_in: '2026-09-09T04:22:00Z', created_at: '2026-09-01T03:44:00Z' },
  { id: 'cus-405', full_name: 'Grace Lim', email: 'grace.lim@example.com', phone: '+60 12-909 4417', holder_type: 'resident', season_pass_status: 'lapsed', is_enabled: 1, vehicles_count: 1, active_passes_count: 0, last_sign_in: '2026-07-30T10:18:00Z', created_at: '2025-08-12T05:00:00Z' },
  { id: 'cus-406', full_name: 'Hafiz Rahman', email: 'hafiz.rahman@example.com', phone: '+60 19-551 2208', holder_type: 'season', season_pass_status: 'active', is_enabled: 1, vehicles_count: 1, active_passes_count: 1, last_sign_in: '2026-09-16T12:55:00Z', created_at: '2026-04-05T07:20:00Z' },
  { id: 'cus-407', full_name: 'Siti Nurhaliza Yusof', email: 'siti.yusof@example.com', phone: '+60 17-441 3396', holder_type: 'staff', season_pass_status: 'active', is_enabled: 0, vehicles_count: 1, active_passes_count: 0, last_sign_in: '2026-05-21T02:10:00Z', created_at: '2026-01-14T09:05:00Z' },
];

const VEHICLES = [
  { id: 'veh-801', plate_number: 'WXY4821', vehicle_type: 'Sedan', color: 'Silver', model: 'Honda City', owner_name: 'Faridah Osman', owner_kind: 'resident', is_blacklisted: 0, created_at: '2025-11-02T02:20:00Z' },
  { id: 'veh-802', plate_number: 'WQE3390', vehicle_type: 'SUV', color: 'Black', model: 'Perodua Aruz', owner_name: 'Faridah Osman', owner_kind: 'resident', is_blacklisted: 0, created_at: '2026-01-08T04:00:00Z' },
  { id: 'veh-803', plate_number: 'JPQ1188', vehicle_type: 'Hatchback', color: 'White', model: 'Perodua Myvi', owner_name: 'Daniel Teoh', owner_kind: 'staff', is_blacklisted: 0, created_at: '2026-02-19T06:35:00Z' },
  { id: 'veh-804', plate_number: 'BMT7342', vehicle_type: 'Sedan', color: 'Grey', model: 'Toyota Vios', owner_name: 'Meera Rajan', owner_kind: 'season', is_blacklisted: 0, created_at: '2026-06-28T08:10:00Z' },
  { id: 'veh-805', plate_number: 'BNS5521', vehicle_type: 'MPV', color: 'Blue', model: 'Toyota Innova', owner_name: 'Meera Rajan', owner_kind: 'season', is_blacklisted: 0, created_at: '2026-06-28T08:12:00Z' },
  { id: 'veh-806', plate_number: 'VAB9087', vehicle_type: 'Van', color: 'White', model: 'Nissan NV200', owner_name: 'Meera Rajan', owner_kind: 'season', is_blacklisted: 0, created_at: '2026-07-01T01:00:00Z' },
  { id: 'veh-807', plate_number: 'PKM6610', vehicle_type: 'Sedan', color: 'Red', model: 'Proton Saga', owner_name: 'Azrul Hakim', owner_kind: 'visitor', is_blacklisted: 0, created_at: '2026-09-01T03:50:00Z' },
  { id: 'veh-808', plate_number: 'CBA4412', vehicle_type: 'Motorcycle', color: 'Black', model: 'Yamaha NMAX', owner_name: 'Hafiz Rahman', owner_kind: 'season', is_blacklisted: 0, created_at: '2026-04-05T07:25:00Z' },
  { id: 'veh-909', plate_number: 'WPL2233', vehicle_type: 'Sedan', color: 'Green', model: 'Proton Persona', owner_name: 'Grace Lim', owner_kind: 'resident', is_blacklisted: 1, blacklist_reason: 'Repeated non-payment', created_at: '2025-08-12T05:10:00Z' },
  { id: 'veh-912', plate_number: 'KEV7781', vehicle_type: 'SUV', color: 'Maroon', model: 'Mazda CX-5', owner_name: null, owner_kind: null, is_blacklisted: 1, blacklist_reason: 'Tailgating incident — 2026-08-30', created_at: '2026-08-30T11:02:00Z' },
];

const PARKING_SPACES = (() => {
  const rows = [];
  const plan = [
    { building: 'Tower A', level: 'B1', zone: 'Zone 1', bay_type: 'season', count: 8, from: 1 },
    { building: 'Tower A', level: 'B1', zone: 'Zone 2', bay_type: 'visitor', count: 8, from: 9 },
    { building: 'Tower A', level: 'B2', zone: 'Zone 3', bay_type: 'resident', count: 8, from: 17 },
    { building: 'Tower B', level: 'B1', zone: 'Zone 4', bay_type: 'staff', count: 6, from: 25 },
  ];
  const holders = {
    'A-B1-01': 'Meera Rajan', 'A-B1-02': 'Meera Rajan', 'A-B1-03': 'Hafiz Rahman',
    'A-B2-17': 'Faridah Osman', 'A-B2-18': 'Faridah Osman', 'B-B1-25': 'Daniel Teoh',
  };
  for (const block of plan) {
    for (let i = 0; i < block.count; i++) {
      const n = block.from + i;
      const code = `${block.building === 'Tower A' ? 'A' : 'B'}-${block.level}-${String(n).padStart(2, '0')}`;
      const customer = holders[code] ?? null;
      rows.push({
        id: `space-${n}`,
        building: block.building, level: block.level, zone: block.zone,
        space_number: String(n).padStart(3, '0'), space_code: code,
        status: customer ? 'occupied' : (n % 5 === 0 ? 'reserved' : 'available'),
        customer_name: customer,
        bay_type: block.bay_type,
        pass_id: customer ? 'pass-2043' : null,
        start_date: customer ? '2026-07-01' : null,
        end_date: customer ? '2026-12-31' : null,
        notes: null,
      });
    }
  }
  return rows;
})();

/** Cloud-origin audit rows — what an operator did in the web portal. Local rows
 *  the box pushes up are added to this list as they arrive, exactly as the real
 *  endpoint would, so the pull brings back the combined trail. */
const CLOUD_ACTIVITY = [
  { id: 'cl-9001', event_key: 'season_pass.issued', action: 'Season pass issued', category: 'season_pass', severity: 'low', outcome: 'success', resource_type: 'SeasonPass', resource_id: 'pass-2044', description: 'Visitor Weekly issued to PKM6610', source: 'cloud', actor_name: 'Nadia (HQ)', site_id: SITE.id, occurred_at: iso(-3 * 3600), created_at: iso(-3 * 3600) },
  { id: 'cl-9002', event_key: 'rate_policy.updated', action: 'Rate policy updated', category: 'pricing', severity: 'medium', outcome: 'success', resource_type: 'RatePolicy', resource_id: 'pol-std', description: 'Standard Hourly daily cap changed to RM15.00', source: 'cloud', actor_name: 'Nadia (HQ)', site_id: SITE.id, occurred_at: iso(-9 * 3600), created_at: iso(-9 * 3600) },
  { id: 'cl-9003', event_key: 'vehicle.blacklisted', action: 'Vehicle blacklisted', category: 'enforcement', severity: 'high', outcome: 'success', resource_type: 'Vehicle', resource_id: 'veh-912', description: 'KEV7781 added to the deny list — tailgating', source: 'cloud', actor_name: 'Operations', site_id: SITE.id, occurred_at: iso(-26 * 3600), created_at: iso(-26 * 3600) },
  { id: 'cl-9004', event_key: 'bay.assigned', action: 'Bay assigned', category: 'bays', severity: 'low', outcome: 'success', resource_type: 'ParkingSpace', resource_id: 'space-3', description: 'A-B1-03 assigned to Hafiz Rahman', source: 'cloud', actor_name: 'Nadia (HQ)', site_id: SITE.id, occurred_at: iso(-30 * 3600), created_at: iso(-30 * 3600) },
];

function iso(offsetSeconds) {
  return new Date(Date.now() + offsetSeconds * 1000).toISOString();
}

// Rows the box has pushed up, kept so the pull returns the combined trail.
const pushedActivity = [];

// ─── the fake qparking SaaS ──────────────────────────────────────────────────

const list = (data) => ({ data, meta: { total: data.length } });

function cloudRoutes(route, method, body) {
  if (method === 'POST' && route === '/activity-logs/sync') {
    let rows = [];
    try {
      rows = JSON.parse(JSON.parse(body || '{}').data || '[]');
    } catch { rows = []; }
    const stored = rows.map((r) => ({
      id: r.id,
      event_key: r.eventKey ?? null,
      action: r.action,
      category: r.category ?? null,
      severity: r.severity ?? 'low',
      outcome: r.outcome ?? null,
      resource_type: r.resourceType ?? null,
      resource_id: r.resourceId ?? null,
      correlation_id: r.correlationId ?? null,
      description: r.description ?? null,
      changes: r.changes ?? null,
      source: 'local',
      actor_name: r.actorName ?? null,
      site_id: r.siteId ?? SITE.id,
      occurred_at: r.occurredAt ?? null,
      created_at: r.createdAt ?? null,
    }));
    for (const row of stored) {
      const at = pushedActivity.findIndex((p) => p.id === row.id);
      if (at >= 0) pushedActivity[at] = row; else pushedActivity.push(row);
    }
    return [200, { data: stored }];
  }

  if (method === 'POST') {
    // The outbound half: the queue drains sessions and transactions up, the
    // heartbeat reports device health, and the equipment Push buttons send
    // lanes/terminals/LCDs. All the box checks is a 2xx, so one ack covers them.
    //   /parking-records/upsert  /transactions/upsert  /device-health
    //   /local-lanes/upsert  /local-terminals/upsert  /local-lcds/upsert
    return [200, { data: { ok: true } }];
  }

  switch (route) {
    case '/site': return [200, { data: SITE }];
    case '/company/settings': return [200, { data: COMPANY_SETTINGS }];
    case '/rate-policies': return [200, list(RATE_POLICIES)];
    case '/season-passes/v2': return [200, list(SEASON_PASSES)];
    case '/vehicles/blacklisted': return [200, list(BLOCKED)];
    case '/customers': return [200, list(CUSTOMERS)];
    case '/vehicles': return [200, list(VEHICLES)];
    case '/parking-spaces': return [200, list(PARKING_SPACES)];
    case '/parking-records/open': return [200, list([])];
    case '/activity-logs':
      return [200, list([...pushedActivity, ...CLOUD_ACTIVITY]
        .sort((a, b) => String(b.occurred_at ?? '').localeCompare(String(a.occurred_at ?? ''))))];
    default: return [404, { message: 'no such endpoint' }];
  }
}

function startCloud(port) {
  const server = http.createServer((req, res) => {
    const url = new URL(req.url, 'http://127.0.0.1');
    const route = url.pathname.replace('/api/v1/local-server', '');
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', () => {
      const [status, payload] = cloudRoutes(route, req.method, body);
      res.writeHead(status, { 'content-type': 'application/json' });
      res.end(JSON.stringify(payload));
    });
  });
  return new Promise((resolve) => server.listen(port, '127.0.0.1', () => resolve(server)));
}

// ─── the fake W4G payment device ─────────────────────────────────────────────

/**
 * Answers PayRequest with State:0 (accepted), then calls the box back on
 * /w4g/PayResult the way the real device does after the driver taps.
 */
function startDevice(port, callbackPort) {
  let stan = 480_000;
  const server = http.createServer((req, res) => {
    let body = '';
    req.on('data', (c) => { body += c; });
    req.on('end', () => {
      const path = (req.url || '').split('?')[0].replace(/\/+$/, '');
      if (!/^\/w4g\/payrequest$/i.test(path)) {
        res.writeHead(404, { 'content-type': 'application/json' });
        res.end(JSON.stringify({ State: 1 }));
        return;
      }
      let payload = {};
      try { payload = JSON.parse(body || '{}'); } catch { /* keep empty */ }
      const orderId = String(payload.OrderId ?? '');
      res.writeHead(200, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ State: 0, OrderId: orderId }));

      // The driver taps ~1.2s later and the device reports the result.
      setTimeout(() => {
        const result = {
          State: 0,
          OrderId: orderId,
          PayType: 1,
          CardNo: `6214${String(1000 + (stan % 9000))}****${String(stan).slice(-4)}`,
          Balance: 4_2300 + (stan % 1500),
          PayTime: Math.floor(Date.now() / 1000),
          STAN: String(++stan),
          APPR_CODE: `A${String(stan).slice(-6)}`,
        };
        const data = JSON.stringify(result);
        const cb = http.request(
          { host: '127.0.0.1', port: callbackPort, path: '/w4g/PayResult', method: 'POST',
            headers: { 'content-type': 'application/json', 'content-length': Buffer.byteLength(data) } },
          (r) => r.resume(),
        );
        cb.on('error', () => { /* the box logs the miss itself */ });
        cb.end(data);
      }, 1200);
    });
  });
  return new Promise((resolve) => server.listen(port, '127.0.0.1', () => resolve(server)));
}

module.exports = { startCloud, startDevice, SITE, RATE_POLICIES, SEASON_PASSES, BLOCKED, VEHICLES };

if (require.main === module) {
  const cloudPort = Number(process.argv[2] || 7788);
  const devicePort = Number(process.argv[3] || 7901);
  const callbackPort = Number(process.argv[4] || 7902);
  Promise.all([startCloud(cloudPort), startDevice(devicePort, callbackPort)]).then(() => {
    console.log(`stub cloud on :${cloudPort}, stub W4G device on :${devicePort} → callback :${callbackPort}`);
  });
}
