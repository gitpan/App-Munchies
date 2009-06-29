SET foreign_key_checks=0;

DROP TABLE IF EXISTS user_roles;
CREATE TABLE user_roles (
  user_id integer(11) NOT NULL DEFAULT '0',
  role_id integer(11) NOT NULL DEFAULT '0',
  INDEX (user_id),
  INDEX (role_id),
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY fk_user_id (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY fk_role_id (role_id) REFERENCES roles (id) ON DELETE CASCADE ON UPDATE CASCADE
) Type=InnoDB;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id integer(11) NOT NULL auto_increment,
  active TINYINT(1) NOT NULL DEFAULT '0',
  username varchar(32) NOT NULL,
  password varchar(64),
  email_address varchar(255),
  first_name varchar(32),
  last_name varchar(32),
  home_phone varchar(32),
  location varchar(255),
  project varchar(255),
  work_phone varchar(32),
  pwlast integer(11) unsigned NOT NULL DEFAULT '13267',
  pwnext integer(11) unsigned NOT NULL DEFAULT '0',
  pwafter integer(11) unsigned NOT NULL DEFAULT '99999',
  pwwarn integer(11) unsigned NOT NULL DEFAULT '7',
  pwexpires integer(11) unsigned NOT NULL DEFAULT '0',
  pwdisable integer(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (id),
  UNIQUE INDEX (username(32))
) Type=InnoDB;

DROP TABLE IF EXISTS roles;
CREATE TABLE roles (
  id integer(11) NOT NULL auto_increment,
  role varchar(32) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE INDEX (role(32))
) Type=InnoDB;

