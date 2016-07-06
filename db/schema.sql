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

CREATE TABLE diary (
    `diary_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `title` VARCHAR(256) NOT NULL,
    `created` TIMESTAMP NOT NULL,
    PRIMARY KEY (diary_id),
    UNIQUE KEY (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
