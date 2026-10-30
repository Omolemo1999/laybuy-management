# LaybyPay

South African lay-by platform with two role-specific experiences: an installable customer PWA and a retailer web workspace. Customers register, verify email, review lay-by agreements, track balances, pay online through Paystack, request cancellation and open disputes. Retailers manage products, stock, customers, agreements, payments, collection and activity.

The experiences share one Express API and PostgreSQL database. Customer and retailer routes are role-checked server-side, and retailer data is scoped to the authenticated tenant.

## Stack
Node.js 22, Express, PostgreSQL 16, Paystack-hosted checkout, responsive vanilla JavaScript UI, PWA manifest/service worker and Docker Compose.

## Run locally with Docker
1. Copy `.env.example` to `.env`.
2. Set strong SESSION_SECRET and POSTGRES_PASSWORD values, Paystack test secret and SMTP credentials.
3. Run `docker compose up --build -d`.
4. Open http://localhost:4000. Register and verify a retailer account and a customer account using separate email addresses.
5. Add products in the retailer workspace, create a lay-by for the verified customer, then sign in as that customer to review, accept and pay.

## PWA
Deploy on HTTPS. Android users can install through Chrome. iPhone users open the site in Safari, tap Share, then Add to Home Screen. The service worker caches only static app-shell files; it does not cache API, authentication, payment or personal data. This is a PWA, not a native app binary.

## Payment security
Paystack secrets stay server-side. Configure the webhook at `https://YOUR_DOMAIN/api/payments/webhook`. The backend checks the raw webhook HMAC-SHA512 signature, independently verifies transactions with Paystack, checks ZAR amount/reference/customer email, processes events idempotently and updates the payment ledger transactionally. Use test keys before production.

## Important limitations
Cancellation requests are recorded but refunds are not automatically processed. Customers currently manage retailer-created lay-bys; there is no public store/product discovery marketplace. No native app binary, MFA, staff invitation UI, platform-admin console, subscription billing or WhatsApp/SMS provider is included. Production email, Paystack credentials, HTTPS, legal review and independent security testing are required before launch.

See the setup, lifecycle, security and South African CPA/POPIA notes in this README and `.env.example`. Official references: https://www.gov.za/documents/consumer-protection-act ; https://www.gov.za/documents/protection-personal-information-act ; https://paystack.com/docs/payments/webhooks/ .