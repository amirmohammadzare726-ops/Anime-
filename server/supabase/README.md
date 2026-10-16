# ETERNUM backend

## Active service

The initial game API is deployed as a Supabase Edge Function named `eternum-api` in project `ccnovtgefjoemxoangix`.

Base URL:
`https://ccnovtgefjoemxoangix.supabase.co/functions/v1/eternum-api`

## Routes

- `GET /health` — service health response
- `GET /api/health` — alias for health
- `GET /api/world` — world metadata and starting locations
- `POST /api/power/generate` — generates a temporary power preview (not persisted)
- `GET /api/rooms` — currently reports that persistent multiplayer rooms are pending

## Current limits (do not treat as finished features)

- The API deployment is listed as ACTIVE, but an independent live HTTP smoke test has not yet been confirmed.
- Power generation is a preview only. It does not save the generated power to a player's profile.
- Multiplayer rooms, live combat, quests, and server-authoritative progression are not implemented here yet.
- The browser client still authenticates and saves basic profile/location data directly through Supabase. This API is not yet wired into the browser UI.
- The current browser signup uses a synthetic email alias for username-based authentication, so Supabase email-confirmation settings may affect signup.

## Source

The deployed function source is version-controlled at:
`server/supabase/functions/eternum-api/index.ts`

Keep the public browser key in the client only. Never commit a Supabase service-role key or other server secret.
