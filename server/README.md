# localbill-server

Lightweight sync server for the LocalBill Flutter app.

## Running

```bash
cd server
dart pub get
dart run bin/server.dart
# or specify a port:
dart run bin/server.dart 8080
```

Environment variables:
- `PORT`     — HTTP port (default: 8080)
- `DATA_DIR` — Directory for JSON data files (default: `data/`)

## API

| Method | Path                    | Description                            |
|--------|-------------------------|----------------------------------------|
| GET    | /health                 | Health check                           |
| POST   | /sync                   | Bidirectional sync (bulk upsert)       |
| GET    | /transactions           | List all transactions                  |
| POST   | /transactions           | Upsert one transaction                 |
| DELETE | /transactions/:id       | Delete a transaction                   |
| GET    | /queue                  | List queued URLs                       |
| POST   | /queue                  | Add URL(s) to queue                    |
| DELETE | /queue                  | Remove processed URL(s) from queue     |

### POST /sync

```json
// Request
{ "transactions": [ ...Transaction objects... ] }

// Response
{ "new_transactions": [ ...Transaction objects the client didn't have... ] }
```

Conflict resolution: **last-write-wins by `id`**. The client always wins.

### POST /queue

```json
// Single URL
{ "item": "https://suf.purs.gov.rs/v/?vl=..." }

// Multiple URLs
{ "items": ["https://...", "https://..."] }
```

### DELETE /queue

```json
{ "items": ["https://..."] }
```
