# Savyyk local API

This development server receives deposit and withdrawal activity from the Flutter app and serves the admin website. It uses Node.js built-ins only and keeps records in memory; restarting the process clears the records.

## Start

From this directory, run:

```powershell
node server.js
```

Open the portal at `http://localhost:3000/`.

## Flutter connection

Android Emulator uses `http://10.0.2.2:3000` by default. For a physical Android device, start the server on the same trusted Wi-Fi network and run Flutter with the computer's LAN address:

```powershell
flutter run --dart-define=SAVYYK_API_URL=http://YOUR-COMPUTER-LAN-IP:3000
```

The API records the user identifier, display name, transaction type, amount, timestamp, and reference. Deposits are accepted only through the verified Razorpay test flow; withdrawals remain demo records. The app does not make a real bank transfer.

## Razorpay test payments

The add-money flow creates each Razorpay order on this server and records a deposit only after the server verifies the checkout signature and confirms the payment is captured. The Razorpay key secret must stay in server environment variables; never put it in Flutter code or commit it.

The key secret previously pasted into chat should be regenerated in Razorpay before testing. Set the new test credentials in the same PowerShell window used to start the server:

```powershell
$env:RAZORPAY_KEY_ID = 'rzp_test_your_rotated_test_key_id'
$env:RAZORPAY_KEY_SECRET = 'your_rotated_test_key_secret'
node server.js
```

The server rejects live-mode key IDs. Test mode simulates checkout and does not move real funds. The current records and balances are still in memory and are only for development; this setup is not a production wallet or bank transfer system.

The Android and iOS app uses Razorpay's official `razorpay_flutter` plugin. The Chrome app uses Razorpay's hosted Checkout.js script. Both platforms create orders and verify payments through the same server endpoints. Ensure the Flutter web page is served over HTTP(S) and the Razorpay checkout script can load.

## Development-only limitations

- There is no database, so data is lost when the server restarts.
- There is no admin sign-in or API authentication yet. Keep the server on a trusted development network; do not expose it to the public internet.
- The Android manifest currently allows cleartext HTTP for local development. Replace this with HTTPS before production use.
