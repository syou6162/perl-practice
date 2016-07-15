CREATE TABLE user (
    `user_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARBINARY(32) NOT NULL,
    `created` TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id),
    UNIQUE KEY (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE entry (
    `entry_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `diary_id` BIGINT UNSIGNED NOT NULL,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `title` VARCHAR(512) NOT NULL,
    `content` VARCHAR(512) NOT NULL,
    `path` VARCHAR(128) NOT NULL,
    `created` TIMESTAMP NOT NULL,
    PRIMARY KEY (entry_id),
    UNIQUE KEY (diary_id, user_id, path),
    KEY (user_id, path)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tag` (
    `tag_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` varchar(32) DEFAULT NULL,
    `created` TIMESTAMP NOT NULL,
    PRIMARY KEY (`tag_id`),
    UNIQUE KEY (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `entry_tag_map` (
    `entry_id` BIGINT UNSIGNED NOT NULL,
    `tag_id` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`entry_id`, `tag_id`),
    FOREIGN KEY (entry_id) REFERENCES entry(entry_id),
    FOREIGN KEY (tag_id) REFERENCES tag(tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE diary (
    `diary_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `title` VARCHAR(256) NOT NULL,
    `created` TIMESTAMP NOT NULL,
    PRIMARY KEY (diary_id),
    UNIQUE KEY (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sessions (
    `id` CHAR(72) PRIMARY KEY,
    `session_data` TEXT
);

CREATE TABLE liked_pin (
    `user_id` BIGINT UNSIGNED NOT NULL,
    `entry_id` BIGINT UNSIGNED NOT NULL,
    `liked` BOOLEAN NOT NULL,
    `created` TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id, entry_id),
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
