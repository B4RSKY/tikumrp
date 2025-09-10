-- Referral code owners
CREATE TABLE IF NOT EXISTS referral_codes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  license VARCHAR(80) NOT NULL UNIQUE,
  citizenid VARCHAR(50) NOT NULL,
  code VARCHAR(16) NOT NULL UNIQUE,
  alias VARCHAR(120),
  is_debug TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Referrals (multi-redeem diperbolehkan)
CREATE TABLE IF NOT EXISTS referrals (
  id INT AUTO_INCREMENT PRIMARY KEY,
  referrer_license VARCHAR(80) NOT NULL,
  referrer_cid VARCHAR(50),
  referrer_code VARCHAR(16),
  referred_license VARCHAR(80) NOT NULL,
  referred_cid VARCHAR(50),
  referred_steam VARCHAR(80),
  referred_discord VARCHAR(80),
  ip_at_redeem VARCHAR(64),
  redeemed_at DATETIME NOT NULL,
  seconds_active INT NOT NULL DEFAULT 0,
  requirement_seconds INT NOT NULL DEFAULT 3600,
  completed TINYINT(1) NOT NULL DEFAULT 0,
  reward_given TINYINT(1) NOT NULL DEFAULT 0, -- "claims dibuat" penanda
  grace_until DATETIME NULL,
  is_debug TINYINT(1) NOT NULL DEFAULT 0,
  KEY idx_referrer (referrer_license),
  KEY idx_referred (referred_license),
  KEY idx_completed (completed),
  KEY idx_ip_date (ip_at_redeem),
  KEY idx_redeemed_at (redeemed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Hapus unique lama (abaikan error jika tidak ada)
ALTER TABLE referrals DROP INDEX uniq_referred_license;

-- Claims
CREATE TABLE IF NOT EXISTS referral_claims (
  id INT AUTO_INCREMENT PRIMARY KEY,
  license VARCHAR(80) NOT NULL,
  payload_json LONGTEXT,
  reason VARCHAR(100),
  status TINYINT NOT NULL DEFAULT 0, -- -1=locked, 0=unlocked, 1=claimed, 2=processing
  created_at DATETIME NOT NULL,
  claimed_at DATETIME NULL,
  KEY idx_license_status (license, status),
  KEY idx_reason (reason)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Activity (gating HIDE/DECAY)
CREATE TABLE IF NOT EXISTS ref_daily_activity (
  license VARCHAR(80) NOT NULL,
  day_date DATE NOT NULL,
  seconds_active INT NOT NULL DEFAULT 0,
  PRIMARY KEY (license, day_date),
  KEY idx_license (license),
  KEY idx_day (day_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ref_hour_activity (
  license VARCHAR(80) NOT NULL,
  hour_start DATETIME NOT NULL,
  seconds_active INT NOT NULL DEFAULT 0,
  PRIMARY KEY (license, hour_start),
  KEY idx_license (license),
  KEY idx_hour (hour_start)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;