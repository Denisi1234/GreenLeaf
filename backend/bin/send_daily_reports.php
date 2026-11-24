<?php

declare(strict_types=1);

require_once __DIR__ . '/../src/Database.php';
require_once __DIR__ . '/../src/ApiError.php';
require_once __DIR__ . '/../src/SmsService.php';

$config = require __DIR__ . '/../config.php';
$db = new Database($config['db']);
$sms = new SmsService($config['sms'] ?? []);

$db->execute(
    'CREATE TABLE IF NOT EXISTS daily_report_logs (
        store_id VARCHAR(64) NOT NULL,
        report_date VARCHAR(16) NOT NULL,
        sent_at VARCHAR(32) NOT NULL,
        PRIMARY KEY (store_id, report_date)
    )'
);

$tz = new DateTimeZone('Africa/Dar_es_Salaam');
$now = new DateTimeImmutable('now', $tz);
$todayDate = $now->format('Y-m-d');
$currentHm = $now->format('H:i');

// Week boundaries (Monday 00:00:00 to now, and previous Monday-Sunday)
$weekday = (int) $now->format('N'); // 1 = Monday, 7 = Sunday
$thisWeekStart = $now->setTime(0, 0, 0)->modify('-' . ($weekday - 1) . ' days');
$lastWeekStart = $thisWeekStart->modify('-7 days');

$stores = $db->rows('SELECT id, name FROM stores');
$sentCount = 0;

foreach ($stores as $store) {
    $storeId = (string) $store['id'];

    // Skip if already sent today
    if ($db->rows('SELECT 1 FROM daily_report_logs WHERE store_id = ? AND report_date = ?', [$storeId, $todayDate]) !== []) {
        continue;
    }

    // Load profile & settings
    $profileRows = $db->rows("SELECT payload FROM records WHERE store_id = ? AND resource = 'profile' LIMIT 1", [$storeId]);
    $profile = $profileRows !== [] ? (json_decode((string) $profileRows[0]['payload'], true) ?: []) : [];

    $settingsRows = $db->rows("SELECT payload FROM records WHERE store_id = ? AND resource = 'receipt-settings' LIMIT 1", [$storeId]);
    $settings = $settingsRows !== [] ? (json_decode((string) $settingsRows[0]['payload'], true) ?: []) : [];

    $enabled = $settings['daily_report_enabled'] ?? $profile['daily_report_enabled'] ?? true;
    if (!$enabled) {
        continue;
    }

    $targetTime = trim((string) ($settings['daily_report_time'] ?? $profile['daily_report_time'] ?? '21:00'));
    if (!preg_match('/^\d{2}:\d{2}$/', $targetTime)) {
        $targetTime = '21:00';
    }
    if ($currentHm < $targetTime) {
        continue;
    }

    $rawPhone = (string) ($settings['daily_report_phone'] ?? $profile['contact_number'] ?? $profile['email_address'] ?? '');
    if (trim($rawPhone) === '') {
        continue;
    }

    try {
        $phone = ApiValidator::formatTanzanianPhone($rawPhone);
    } catch (Throwable) {
        continue;
    }

    $ownerName = trim((string) ($profile['owner_name'] ?? $store['name'] ?? 'Mkuu'));
    if ($ownerName === '') {
        $ownerName = 'Mkuu';
    }

    // Aggregate orders
    $orderRows = $db->rows("SELECT payload FROM records WHERE store_id = ? AND resource = 'orders'", [$storeId]);
    $todaySales = 0.0;
    $thisWeekSales = 0.0;
    $lastWeekSales = 0.0;
    $todayCount = 0;

    foreach ($orderRows as $row) {
        $order = json_decode((string) $row['payload'], true);
        if (!is_array($order)) {
            continue;
        }
        if (strtolower((string) ($order['status'] ?? '')) === 'voided') {
            continue;
        }
        $dateStr = (string) ($order['date_time'] ?? '');
        if ($dateStr === '') {
            continue;
        }
        try {
            $orderDt = (new DateTimeImmutable($dateStr))->setTimezone($tz);
        } catch (Throwable) {
            continue;
        }

        $total = (float) ($order['total'] ?? 0);
        if ($orderDt->format('Y-m-d') === $todayDate) {
            $todaySales += $total;
            $todayCount++;
        }
        if ($orderDt >= $thisWeekStart) {
            $thisWeekSales += $total;
        } elseif ($orderDt >= $lastWeekStart && $orderDt < $thisWeekStart) {
            $lastWeekSales += $total;
        }
    }

    $todayFmt = number_format((int) round($todaySales));
    $thisWeekFmt = number_format((int) round($thisWeekSales));
    $lastWeekFmt = number_format((int) round($lastWeekSales));
    $trend = $thisWeekSales >= $lastWeekSales ? 'yameongezeka' : 'yamepungua';

    $message = "Habari ya jioni {$ownerName}, mauzo yako ya leo ({$todayCount} oda) ni TSH {$todayFmt}. "
        . "Mauzo ya wiki hii ni TSH {$thisWeekFmt}, {$trend} kutoka TSH {$lastWeekFmt} wiki iliyopita. "
        . "Asante kwa kutumia TrackMauzo.";

    if ($sms->send($phone, $message)) {
        $db->execute(
            'INSERT INTO daily_report_logs (store_id, report_date, sent_at) VALUES (?, ?, ?)',
            [$storeId, $todayDate, gmdate('c')]
        );
        $sentCount++;
    }
}

echo "Daily reports processed. Sent: {$sentCount}\n";
