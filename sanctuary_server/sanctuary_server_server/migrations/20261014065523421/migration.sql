BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "reflection_posts" (
    "id" bigserial PRIMARY KEY,
    "authorName" text NOT NULL,
    "spaceKey" text NOT NULL,
    "intentTag" text NOT NULL,
    "specialInterestTag" text,
    "content" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "prayingCount" bigint NOT NULL,
    "standingWithCount" bigint NOT NULL,
    "peaceCount" bigint NOT NULL,
    "encouragedCount" bigint NOT NULL
);

-- Indexes
CREATE INDEX "space_created_idx" ON "reflection_posts" USING btree ("spaceKey", "createdAt");


--
-- MIGRATION VERSION FOR sanctuary_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('sanctuary_server', '20261014065523421', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261014065523421', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
