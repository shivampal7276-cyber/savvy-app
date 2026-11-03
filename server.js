const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { randomUUID, createHmac, timingSafeEqual } = require('node:crypto');

// Load private local development settings from the project-root .env file.
// Existing process environment variables take precedence.
function loadLocalEnv() {
  const envFile = path.join(__dirname, '..', '.env');
  if (!fs.existsSync(envFile)) return;

  for (const line of fs.readFileSync(envFile, 'utf8').split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const separator = trimmed.indexOf('=');
    if (separator < 1) continue;

    const key = trimmed.slice(0, separator).trim();
    let value = trimmed.slice(separator + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    if (process.env[key] == null) process.env[key] = value;
  }
}

loadLocalEnv();

const host = process.env.HOST || '0.0.0.0';
const port = Number(process.env.PORT || 3000);
const portalFile = path.join(__dirname, '..', 'admin_portal', 'index.html');
const logoFile = path.join(__dirname, '..', 'assets', 'images', 'logo.png');
const transactions = [];
const paymentOrders = new Map();
const users = new Map();
const usersFile = path.join(__dirname, 'data', 'users.json');
const analyticsFile = path.join(__dirname, 'data', 'daily-analytics.json');

function loadDailyAnalytics() {
  try {
    const saved = JSON.parse(fs.readFileSync(analyticsFile, 'utf8'));
    return saved && typeof saved === 'object' && !Array.isArray(saved) ? saved : {};
  } catch (error) {
    if (error.code !== 'ENOENT') console.error('Could not load saved analytics:', error.message);
    return {};
  }
}

const dailyAnalytics = loadDailyAnalytics();

function dayKey(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

function parseDayKey(key) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(key);
  return match ? new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3])) : null;
}

function recordAnalyticsEvent(transaction) {
  const date = new Date(transaction.createdAt);
  if (Number.isNaN(date.getTime()) || !['deposit', 'withdrawal'].includes(transaction.type)) return;
  const key = dayKey(date);
  const entry = dailyAnalytics[key] || {
    depositTotal: 0,
    withdrawalTotal: 0,
    depositCount: 0,
    withdrawalCount: 0,
  };
  const amount = Number(transaction.amount) || 0;
  if (transaction.type === 'deposit') {
    entry.depositTotal += amount;
    entry.depositCount += 1;
  } else {
    entry.withdrawalTotal += amount;
    entry.withdrawalCount += 1;
  }
  dailyAnalytics[key] = entry;

  try {
    fs.mkdirSync(path.dirname(analyticsFile), { recursive: true });
    const temporaryFile = `${analyticsFile}.tmp`;
    fs.writeFileSync(temporaryFile, JSON.stringify(dailyAnalytics, null, 2));
    fs.renameSync(temporaryFile, analyticsFile);
  } catch (error) {
    console.error('Could not persist aggregate analytics:', error.message);
  }
}

function getRazorpayCredentials() {
  const keyId = process.env.RAZORPAY_KEY_ID || '';
  const keySecret = process.env.RAZORPAY_KEY_SECRET || '';
  if (!keyId.startsWith('rzp_test_') || !keySecret) {
    throw new Error('Razorpay test credentials are not configured on the server.');
  }
  return { keyId, keySecret };
}

async function razorpayRequest(endpoint, method, body) {
  const { keyId, keySecret } = getRazorpayCredentials();
  const authorization = Buffer.from(`${keyId}:${keySecret}`).toString('base64');
  const response = await fetch(`https://api.razorpay.com/v1${endpoint}`, {
    method,
    headers: {
      Authorization: `Basic ${authorization}`,
      'Content-Type': 'application/json',
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const result = await response.json();
  if (!response.ok) {
    throw new Error(result.error?.description || 'Razorpay request failed.');
  }
  return result;
}

function verifyPaymentSignature(orderId, paymentId, signature) {
  const { keySecret } = getRazorpayCredentials();
  const expected = createHmac('sha256', keySecret)
    .update(`${orderId}|${paymentId}`)
    .digest();
  let supplied;
  try {
    supplied = Buffer.from(signature, 'hex');
  } catch {
    return false;
  }
  return supplied.length === expected.length && timingSafeEqual(supplied, expected);
}

function sendJson(response, statusCode, data) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Cache-Control': 'no-store',
  });
  response.end(JSON.stringify(data));
}

function readJson(request) {
  return new Promise((resolve, reject) => {
    let body = '';
    request.on('data', (chunk) => {
      body += chunk;
      if (body.length > 16_384) {
        reject(new Error('Request body is too large.'));
        request.destroy();
      }
    });
    request.on('end', () => {
      try {
        resolve(JSON.parse(body || '{}'));
      } catch {
        reject(new Error('Request body must be valid JSON.'));
      }
    });
    request.on('error', reject);
  });
}

function loadUsers() {
  try {
    const savedUsers = JSON.parse(fs.readFileSync(usersFile, 'utf8'));
    if (Array.isArray(savedUsers)) {
      for (const user of savedUsers) {
        if (user && typeof user.identity === 'string') {
          users.set(user.identity.toLowerCase(), user);
        }
      }
    }
  } catch (error) {
    if (error.code !== 'ENOENT') {
      console.error('Could not read local user records:', error.message);
    }
  }
}

function saveUsers() {
  fs.mkdirSync(path.dirname(usersFile), { recursive: true });
  const temporaryFile = `${usersFile}.tmp`;
  fs.writeFileSync(temporaryFile, JSON.stringify([...users.values()], null, 2));
  fs.renameSync(temporaryFile, usersFile);
}

loadUsers();
function getSummary() {
  const deposits = transactions.filter((item) => item.type === 'deposit');
  const withdrawals = transactions.filter((item) => item.type === 'withdrawal');
  const sum = (items) => items.reduce((total, item) => total + item.amount, 0);
  return {
    depositCount: deposits.length,
    withdrawalCount: withdrawals.length,
    depositTotal: sum(deposits),
    withdrawalTotal: sum(withdrawals),
    netMovement: sum(deposits) - sum(withdrawals),
    transactionCount: transactions.length,
  };
}

function getAnalytics(now = new Date()) {
  const entries = Object.entries(dailyAnalytics)
    .map(([key, totals]) => ({ date: parseDayKey(key), totals }))
    .filter((entry) => entry.date && entry.totals && typeof entry.totals === 'object');
  const sum = (items, field) => items.reduce((total, item) => total + (Number(item.totals[field]) || 0), 0);
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const previousMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const thisMonth = entries.filter(({ date }) => date >= monthStart && date <= now);
  const lastMonth = entries.filter(({ date }) => date >= previousMonthStart && date < monthStart);
  const thisMonthDeposits = sum(thisMonth, 'depositTotal');
  const lastMonthDeposits = sum(lastMonth, 'depositTotal');

  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const currentWeekStart = new Date(today);
  currentWeekStart.setDate(today.getDate() - ((today.getDay() + 6) % 7));
  const weeklyDeposits = Array.from({ length: 4 }, (_, index) => {
    const start = new Date(currentWeekStart);
    start.setDate(currentWeekStart.getDate() - (3 - index) * 7);
    const end = new Date(start);
    end.setDate(start.getDate() + 7);
    return {
      label: start.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }),
      amount: sum(entries.filter(({ date }) => date >= start && date < end), 'depositTotal'),
    };
  });

  const depositTotal = sum(entries, 'depositTotal');
  const withdrawalTotal = sum(entries, 'withdrawalTotal');
  const depositCount = sum(entries, 'depositCount');
  const withdrawalCount = sum(entries, 'withdrawalCount');
  return {
    scope: 'all-app-activity',
    transactionCount: depositCount + withdrawalCount,
    depositCount,
    withdrawalCount,
    depositTotal,
    withdrawalTotal,
    netMovement: depositTotal - withdrawalTotal,
    thisMonthDeposits,
    lastMonthDeposits,
    weeklyDeposits,
    updatedAt: now.toISOString(),
  };
}

const server = http.createServer(async (request, response) => {
  const url = new URL(request.url, `http://${request.headers.host || 'localhost'}`);
  const pathname = url.pathname;

  if (request.method === 'OPTIONS') {
    response.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    return response.end();
  }

  if (request.method === 'GET' && (pathname === '/' || pathname === '/admin')) {
    fs.readFile(portalFile, (error, html) => {
      if (error) return sendJson(response, 500, { error: 'Admin portal file could not be loaded.' });
      response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
      response.end(html);
    });
    return;
  }

  if (request.method === 'GET' && pathname === '/assets/logo.png') {
    fs.readFile(logoFile, (error, image) => {
      if (error) return sendJson(response, 404, { error: 'Logo image was not found.' });
      response.writeHead(200, { 'Content-Type': 'image/png', 'Cache-Control': 'public, max-age=3600' });
      response.end(image);
    });
    return;
  }

  if (request.method === 'GET' && pathname === '/api/health') {
    return sendJson(response, 200, { status: 'ok', service: 'savyyk-api' });
  }

  if (request.method === 'GET' && pathname === '/api/admin/users') {
    const search = (url.searchParams.get('search') || '').toLowerCase();
    let result = [...users.values()].sort((a, b) => b.lastLoginAt.localeCompare(a.lastLoginAt));
    if (search) {
      result = result.filter((user) =>
        `${user.displayName} ${user.identity}`.toLowerCase().includes(search),
      );
    }
    return sendJson(response, 200, { users: result });
  }

  // Guest users see a zero state in the app; signed-in users load these aggregate totals.
  if (request.method === 'GET' && pathname === '/api/analytics') {
    return sendJson(response, 200, getAnalytics());
  }

  if (request.method === 'GET' && pathname === '/api/admin/summary') {
    return sendJson(response, 200, getSummary());
  }

  if (request.method === 'GET' && pathname === '/api/admin/transactions') {
    const type = url.searchParams.get('type');
    const search = (url.searchParams.get('search') || '').toLowerCase();
    let result = [...transactions].reverse();
    if (type === 'deposit' || type === 'withdrawal') result = result.filter((item) => item.type === type);
    if (search) {
      result = result.filter((item) =>
        `${item.userName} ${item.userId} ${item.reference}`.toLowerCase().includes(search),
      );
    }
    return sendJson(response, 200, { transactions: result });
  }

  if (request.method === 'POST' && pathname === '/api/auth/activity') {
    try {
      const body = await readJson(request);
      const identity = String(body.identity || '').trim();
      const displayName = String(body.displayName || '').trim();
      const event = String(body.event || '');
      if (!identity || identity.length > 254 || !displayName || displayName.length > 100 ||
          !['sign_up', 'sign_in'].includes(event)) {
        return sendJson(response, 400, { error: 'A valid identity, display name, and sign-in event are required.' });
      }

      const key = identity.toLowerCase();
      const previous = users.get(key);
      const now = new Date().toISOString();
      const user = {
        identity,
        displayName,
        createdAt: previous?.createdAt || now,
        lastLoginAt: now,
        signInCount: (previous?.signInCount || 0) + (event === 'sign_in' ? 1 : 0),
      };
      users.set(key, user);
      saveUsers();
      return sendJson(response, previous ? 200 : 201, { user });
    } catch (error) {
      return sendJson(response, 500, { error: error.message || 'Could not save sign-in activity.' });
    }
  }
  if (request.method === 'POST' && pathname === '/api/payments/create-order') {
    try {
      const body = await readJson(request);
      const amount = Number(body.amount);
      const userId = String(body.userId || '').trim();
      const userName = String(body.userName || '').trim();
      const goalTitle = String(body.goalTitle || '').trim();
      if (!Number.isFinite(amount) || amount < 1 || amount > 100_000) {
        return sendJson(response, 400, { error: 'Amount must be between ₹1 and ₹100,000.' });
      }
      if (!userId || userId.length > 160 || userName.length > 100 || !goalTitle || goalTitle.length > 100) {
        return sendJson(response, 400, { error: 'A valid signed-in user and goal are required.' });
      }

      const amountPaise = Math.round(amount * 100);
      const order = await razorpayRequest('/orders', 'POST', {
        amount: amountPaise,
        currency: 'INR',
        receipt: `sv_${randomUUID().replaceAll('-', '').slice(0, 30)}`,
      });
      const { keyId } = getRazorpayCredentials();
      paymentOrders.set(order.id, {
        amountPaise,
        userId,
        userName: userName || 'Savyyk user',
        goalTitle,
        createdAt: Date.now(),
        transaction: null,
      });
      return sendJson(response, 201, {
        keyId,
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
      });
    } catch (error) {
      return sendJson(response, 502, { error: error.message || 'Could not create a Razorpay order.' });
    }
  }

  if (request.method === 'POST' && pathname === '/api/payments/verify') {
    try {
      const body = await readJson(request);
      const orderId = String(body.orderId || '').trim();
      const paymentId = String(body.paymentId || '').trim();
      const signature = String(body.signature || '').trim();
      const order = paymentOrders.get(orderId);
      if (!order || Date.now() - order.createdAt > 30 * 60 * 1000) {
        paymentOrders.delete(orderId);
        return sendJson(response, 404, { error: 'Payment order was not found or has expired.' });
      }
      if (order.transaction) return sendJson(response, 200, { transaction: order.transaction });
      if (!paymentId || !/^[a-f0-9]{64}$/i.test(signature) || !verifyPaymentSignature(orderId, paymentId, signature)) {
        return sendJson(response, 400, { error: 'Razorpay payment signature could not be verified.' });
      }

      let payment = await razorpayRequest(`/payments/${encodeURIComponent(paymentId)}`, 'GET');
      if (payment.order_id !== orderId || payment.amount !== order.amountPaise || payment.currency !== 'INR') {
        return sendJson(response, 400, { error: 'Payment details do not match the order.' });
      }
      if (payment.status === 'authorized') {
        payment = await razorpayRequest(`/payments/${encodeURIComponent(paymentId)}/capture`, 'POST', {
          amount: order.amountPaise,
          currency: 'INR',
        });
      }
      if (payment.status !== 'captured') {
        return sendJson(response, 409, { error: 'Razorpay has not captured this payment, so the goal balance was not updated.' });
      }

      const transaction = {
        id: randomUUID(),
        type: 'deposit',
        amount: order.amountPaise / 100,
        userId: order.userId,
        userName: order.userName,
        goalTitle: order.goalTitle,
        reference: paymentId,
        orderId,
        createdAt: new Date().toISOString(),
      };
      transactions.push(transaction);
      recordAnalyticsEvent(transaction);
      order.transaction = transaction;
      return sendJson(response, 200, { transaction });
    } catch (error) {
      return sendJson(response, 502, { error: error.message || 'Could not verify the Razorpay payment.' });
    }
  }

  if (request.method === 'POST' && pathname === '/api/transactions') {
    try {
      const body = await readJson(request);
      const type = body.type;
      const amount = Number(body.amount);
      const userId = String(body.userId || '').trim();
      const userName = String(body.userName || '').trim();

      if (type === 'deposit') {
        return sendJson(response, 403, { error: 'Deposits must be completed and verified through Razorpay checkout.' });
      }
      if (type !== 'withdrawal') {
        return sendJson(response, 400, { error: 'type must be withdrawal.' });
      }
      if (!Number.isFinite(amount) || amount <= 0 || amount > 10_000_000) {
        return sendJson(response, 400, { error: 'amount must be a positive number below ₹10,000,000.' });
      }
      if (!userId || userId.length > 160 || userName.length > 100) {
        return sendJson(response, 400, { error: 'A valid userId is required.' });
      }

      const transaction = {
        id: randomUUID(),
        type,
        amount: Math.round(amount * 100) / 100,
        userId,
        userName: userName || 'Savyyk user',
        reference: `SV-${Date.now().toString(36).toUpperCase()}`,
        createdAt: new Date().toISOString(),
      };
      transactions.push(transaction);
      recordAnalyticsEvent(transaction);
      return sendJson(response, 201, { transaction });
    } catch (error) {
      return sendJson(response, 400, { error: error.message || 'Invalid transaction.' });
    }
  }

  return sendJson(response, 404, { error: 'Route not found.' });
});

server.listen(port, host, () => {
  console.log(`Savyyk API and admin portal listening on http://${host}:${port}`);
});
