DROP TABLE IF EXISTS "links" CASCADE;
CREATE TABLE "links" (
  "id" serial NOT NULL,
  "nid" integer DEFAULT 0 NOT NULL,
  "name" character varying(255) DEFAULT '' NOT NULL,
  "text" character varying(255) DEFAULT '' NOT NULL,
  "url" character varying(255) DEFAULT '' NOT NULL,
  "info" character varying(255) DEFAULT '' NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "links_name" UNIQUE ("name")
);

DROP TABLE IF EXISTS "names" CASCADE;
CREATE TABLE "names" (
  "id" serial NOT NULL,
  "text" character varying(255) DEFAULT '' NOT NULL,
  PRIMARY KEY ("id")
);

DROP TABLE IF EXISTS "nodes" CASCADE;
CREATE TABLE "nodes" (
  "id" serial NOT NULL,
  "gid" integer DEFAULT 0 NOT NULL,
  "nid" integer DEFAULT 0 NOT NULL,
  "lid" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "nodes_idx_gid" on "nodes" ("gid");
CREATE INDEX "nodes_idx_lid" on "nodes" ("lid");
CREATE INDEX "nodes_idx_nid" on "nodes" ("nid");

ALTER TABLE "nodes" ADD FOREIGN KEY ("gid")
  REFERENCES "names" ("id") DEFERRABLE;

ALTER TABLE "nodes" ADD FOREIGN KEY ("lid")
  REFERENCES "links" ("id") ON DELETE CASCADE DEFERRABLE;

ALTER TABLE "nodes" ADD FOREIGN KEY ("nid")
  REFERENCES "names" ("id") ON DELETE CASCADE DEFERRABLE;

