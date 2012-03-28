SET foreign_key_checks=0;

DROP TABLE IF EXISTS `roles`;

CREATE TABLE `roles` (
  `id` MEDIUMINT(8) NOT NULL auto_increment,
  `role` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE `roles_role` (`role`)
) Type=InnoDB;

DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `id` MEDIUMINT(8) NOT NULL auto_increment,
  `active` enum('0','1') NOT NULL DEFAULT '0',
  `username` VARCHAR(64) NOT NULL DEFAULT '',
  `password` VARCHAR(64) NOT NULL DEFAULT '',
  `email_address` VARCHAR(64) NOT NULL DEFAULT '',
  `first_name` VARCHAR(64) NOT NULL DEFAULT '',
  `last_name` VARCHAR(64) NOT NULL DEFAULT '',
  `home_phone` VARCHAR(64) NOT NULL DEFAULT '',
  `location` VARCHAR(64) NOT NULL DEFAULT '',
  `project` VARCHAR(64) NOT NULL DEFAULT '',
  `work_phone` VARCHAR(64) NOT NULL DEFAULT '',
  `pwlast` MEDIUMINT(8),
  `pwnext` MEDIUMINT(8),
  `pwafter` MEDIUMINT(8),
  `pwwarn` MEDIUMINT(8),
  `pwexpires` MEDIUMINT(8),
  `pwdisable` MEDIUMINT(8),
  PRIMARY KEY (`id`),
  UNIQUE `users_username` (`username`)
) Type=InnoDB;

DROP TABLE IF EXISTS `user_roles`;

CREATE TABLE `user_roles` (
  `user_id` MEDIUMINT(8) NOT NULL,
  `role_id` MEDIUMINT(8) NOT NULL,
  INDEX `user_roles_idx_role_id` (`role_id`),
  INDEX `user_roles_idx_user_id` (`user_id`),
  PRIMARY KEY (`user_id`, `role_id`),
  CONSTRAINT `user_roles_fk_role_id` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_roles_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) Type=InnoDB;

SET foreign_key_checks=1;

