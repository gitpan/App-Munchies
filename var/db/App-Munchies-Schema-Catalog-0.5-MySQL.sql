SET foreign_key_checks=0;

DROP TABLE IF EXISTS `links`;

CREATE TABLE `links` (
  `id` MEDIUMINT(8) NOT NULL auto_increment,
  `nid` MEDIUMINT(8) NOT NULL DEFAULT 0,
  `name` VARCHAR(255) NOT NULL DEFAULT '',
  `text` VARCHAR(255) NOT NULL DEFAULT '',
  `url` VARCHAR(255) NOT NULL DEFAULT '',
  `info` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE `links_name` (`name`)
) Type=InnoDB;

DROP TABLE IF EXISTS `names`;

CREATE TABLE `names` (
  `id` MEDIUMINT(8) NOT NULL auto_increment,
  `text` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) Type=InnoDB;

DROP TABLE IF EXISTS `nodes`;

CREATE TABLE `nodes` (
  `id` MEDIUMINT(8) NOT NULL auto_increment,
  `gid` MEDIUMINT(8) NOT NULL DEFAULT 0,
  `nid` MEDIUMINT(8) NOT NULL DEFAULT 0,
  `lid` MEDIUMINT(8) NOT NULL DEFAULT 0,
  INDEX `nodes_idx_gid` (`gid`),
  INDEX `nodes_idx_lid` (`lid`),
  INDEX `nodes_idx_nid` (`nid`),
  PRIMARY KEY (`id`),
  CONSTRAINT `nodes_fk_gid` FOREIGN KEY (`gid`) REFERENCES `names` (`id`),
  CONSTRAINT `nodes_fk_lid` FOREIGN KEY (`lid`) REFERENCES `links` (`id`) ON DELETE CASCADE,
  CONSTRAINT `nodes_fk_nid` FOREIGN KEY (`nid`) REFERENCES `names` (`id`) ON DELETE CASCADE
) Type=InnoDB;

SET foreign_key_checks=1;

