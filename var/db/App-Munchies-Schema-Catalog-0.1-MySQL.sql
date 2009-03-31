SET foreign_key_checks=0;

DROP TABLE IF EXISTS links;
CREATE TABLE links (
  id MEDIUMINT(8) NOT NULL auto_increment,
  nid MEDIUMINT(8) NOT NULL DEFAULT '0',
  name VARCHAR(255) NOT NULL DEFAULT '',
  text VARCHAR(255) NOT NULL DEFAULT '',
  url VARCHAR(255) NOT NULL DEFAULT '',
  info VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (id),
  UNIQUE INDEX (name)
) Type=InnoDB;

DROP TABLE IF EXISTS names;
CREATE TABLE names (
  id MEDIUMINT(8) NOT NULL auto_increment,
  text VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (id)
) Type=InnoDB;

DROP TABLE IF EXISTS nodes;
CREATE TABLE nodes (
  id MEDIUMINT(8) NOT NULL auto_increment,
  gid MEDIUMINT(8) NOT NULL DEFAULT '0',
  nid MEDIUMINT(8) NOT NULL DEFAULT '0',
  lid MEDIUMINT(8) NOT NULL DEFAULT '0',
  INDEX (nid),
  INDEX (gid),
  INDEX (lid),
  PRIMARY KEY (id),
  FOREIGN KEY fk_nid (nid) REFERENCES names (id) ON DELETE CASCADE,
  FOREIGN KEY fk_gid (gid) REFERENCES names (id),
  FOREIGN KEY fk_lid (lid) REFERENCES links (id)
) Type=InnoDB;

