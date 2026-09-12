# RikiPath Flutter Environment Configuration

The Flutter app uses compile-time environment values through
`String.fromEnvironment`. This system already existed in the starter, so this
phase extends it instead of adding `flutter_dotenv` and bundling a local `.env`
file as an application asset.

## Create a local environment file

From the repository root, copy the public template:

```powershell
Copy-Item .env.example .env
```

Then run Flutter with that file:

```powershell
flutter run --dart-define-from-file=.env
```

Local `.env` and `.env.*` files are ignored by Git. `.env.example` remains
committed as the public template. Never put JWT signing keys, database
credentials, AWS credentials, payment secrets, private keys, or any other
secret in these files. Dart define values are compiled into the mobile binary
and are not a secret-storage mechanism.

## Required variables

| Variable | Allowed value or purpose |
|---|---|
| `APP_ENV` | Exactly `development`, `staging`, or `production` |
| `API_BASE_URL` | Absolute API deployment origin, with no `/api`, Swagger path, query, or fragment |
| `SWAGGER_URL` | Absolute Swagger UI reference URL; it is not used as the Dio base URL |
| `ENABLE_API_LOGGING` | Exactly `true` or `false`; honored only in development and production requires `false` |

All four variables are required. Invalid or missing configuration fails during
application startup instead of silently falling back to another server.

## Verified development API origin

The current public development values are:

```dotenv
APP_ENV=development
API_BASE_URL=http://140.245.43.97
SWAGGER_URL=http://140.245.43.97/swagger/index.html
ENABLE_API_LOGGING=true
```

`API_BASE_URL` is the deployment origin, not the Swagger HTML URL. The live
OpenAPI document is served from the same origin at
`/swagger/v1/swagger.json`, and its verified application routes include their
own `/api/...` prefix, such as `/api/Auth/login`. The OpenAPI document does not
publish a `servers` value, so the origin is derived from the reachable Swagger
deployment documented in `API_CONTRACT.md`.

In development, API logging records Dio method, path, and status metadata only.
It does not print query parameters, request/response headers, bodies, tokens, or
backend error payloads. Logging is not enabled for staging or production.

## Development, staging, and production

You may keep separate ignored files and select one at build or run time:

```powershell
flutter run --dart-define-from-file=.env.development
flutter run --dart-define-from-file=.env.staging
flutter build apk --release --dart-define-from-file=.env.production
```

Set `APP_ENV` inside each file to match its target. Staging and production
deployment origins are not published by the current API contract and must be
provided by the backend/deployment owner; do not guess them or reuse the
Swagger URL. Production configuration rejects non-HTTPS `API_BASE_URL` values
and rejects enabled API logging.

## HTTP development limitation

The verified development API currently uses plain HTTP. Android and iOS may
block cleartext traffic depending on platform version and application network
policy. Standard Android and iOS hosts now exist, but C10.5 does not add a
global or production transport exception.

Prefer an HTTPS development endpoint. If HTTP remains necessary, add a narrowly
scoped development/debug-only exception for `140.245.43.97` in an explicitly
approved networking phase. Do not enable global cleartext traffic or weaken
App Transport Security in production/release configuration.
