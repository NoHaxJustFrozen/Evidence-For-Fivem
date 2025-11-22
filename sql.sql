DROP TABLE IF EXISTS `evidence_archive`;

CREATE TABLE `evidence_archive` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `officer_name` varchar(100) DEFAULT 'Bilinmiyor',
  `evidence_type` varchar(50) DEFAULT NULL,
  `report_data` longtext DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;