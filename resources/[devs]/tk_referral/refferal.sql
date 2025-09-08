CREATE TABLE IF NOT EXISTS `referrals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `referrer_license` varchar(80) NOT NULL,
  `referrer_cid` varchar(50) DEFAULT NULL,
  `referrer_code` varchar(16) DEFAULT NULL,
  `referred_license` varchar(80) NOT NULL,
  `referred_cid` varchar(50) DEFAULT NULL,
  `referred_steam` varchar(80) DEFAULT NULL,
  `referred_discord` varchar(80) DEFAULT NULL,
  `ip_at_redeem` varchar(64) DEFAULT NULL,
  `redeemed_at` datetime NOT NULL,
  `seconds_active` int(11) NOT NULL DEFAULT 0,
  `requirement_seconds` int(11) NOT NULL DEFAULT 3600,
  `completed` tinyint(1) NOT NULL DEFAULT 0,
  `reward_given` tinyint(1) NOT NULL DEFAULT 0,
  `grace_until` datetime DEFAULT NULL,
  `is_debug` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_referred_license` (`referred_license`),
  KEY `idx_referrer` (`referrer_license`),
  KEY `idx_referred` (`referred_license`),
  KEY `idx_completed` (`completed`),
  KEY `idx_ip_date` (`ip_at_redeem`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `referral_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(80) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `code` varchar(16) NOT NULL,
  `alias` varchar(120) DEFAULT NULL,
  `is_debug` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `license` (`license`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `referral_rewards_ledger` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(80) NOT NULL,
  `payload_json` longtext DEFAULT NULL,
  `reason` varchar(100) DEFAULT NULL,
  `status` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL,
  `delivered_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_license_status` (`license`,`status`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `ref_daily_activity` (
  `license` varchar(80) NOT NULL,
  `day_date` date NOT NULL,
  `seconds_active` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`license`,`day_date`),
  KEY `idx_license` (`license`),
  KEY `idx_day` (`day_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `ref_hour_activity` (
  `license` varchar(80) NOT NULL,
  `hour_start` datetime NOT NULL,
  `seconds_active` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`license`,`hour_start`),
  KEY `idx_license` (`license`),
  KEY `idx_hour` (`hour_start`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
