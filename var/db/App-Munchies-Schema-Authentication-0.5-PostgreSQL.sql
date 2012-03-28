DROP TABLE IF EXISTS "roles" CASCADE;
CREATE TABLE "roles" (
  "id" serial NOT NULL,
  "role" character varying(255) DEFAULT '' NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "roles_role" UNIQUE ("role")
);

DROP TABLE IF EXISTS "users" CASCADE;
CREATE TABLE "users" (
  "id" serial NOT NULL,
  "active" boolean DEFAULT '0' NOT NULL,
  "username" character varying(64) DEFAULT '' NOT NULL,
  "password" character varying(64) DEFAULT '' NOT NULL,
  "email_address" character varying(64) DEFAULT '' NOT NULL,
  "first_name" character varying(64) DEFAULT '' NOT NULL,
  "last_name" character varying(64) DEFAULT '' NOT NULL,
  "home_phone" character varying(64) DEFAULT '' NOT NULL,
  "location" character varying(64) DEFAULT '' NOT NULL,
  "project" character varying(64) DEFAULT '' NOT NULL,
  "work_phone" character varying(64) DEFAULT '' NOT NULL,
  "pwlast" integer,
  "pwnext" integer,
  "pwafter" integer,
  "pwwarn" integer,
  "pwexpires" integer,
  "pwdisable" integer,
  PRIMARY KEY ("id"),
  CONSTRAINT "users_username" UNIQUE ("username")
);

DROP TABLE IF EXISTS "user_roles" CASCADE;
CREATE TABLE "user_roles" (
  "user_id" integer NOT NULL,
  "role_id" integer NOT NULL,
  PRIMARY KEY ("user_id", "role_id")
);
CREATE INDEX "user_roles_idx_role_id" on "user_roles" ("role_id");
CREATE INDEX "user_roles_idx_user_id" on "user_roles" ("user_id");

ALTER TABLE "user_roles" ADD FOREIGN KEY ("role_id")
  REFERENCES "roles" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "user_roles" ADD FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

