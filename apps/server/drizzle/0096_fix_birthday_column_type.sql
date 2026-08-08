-- Bug fix: 0076 created `users.birthday` as a native `date` column, but
-- src/routes/profile.ts has always stored it AES-encrypted (same as the
-- address fields, via encryptPII) — an encrypted value ("gcm1:...") can never
-- fit in a `date` column, so every attempt to save a birthday has been
-- failing with "invalid input syntax for type date" (the address fields are
-- unaffected, they were correctly typed `text` from the start).
--
-- Run this in the Supabase SQL editor. Safe to run more than once.

ALTER TABLE users ALTER COLUMN birthday TYPE text USING birthday::text;
ALTER TABLE users ALTER COLUMN birthday SET DEFAULT '';
UPDATE users SET birthday = '' WHERE birthday IS NULL;
ALTER TABLE users ALTER COLUMN birthday SET NOT NULL;
