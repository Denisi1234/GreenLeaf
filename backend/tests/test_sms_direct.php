<?php
$ch = curl_init("https://messaging-service.co.tz/api/sms/v1/text/single");
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode([
        'from' => 'POS',
        'to' => '255767000000',
        'text' => 'TrackMauzo Test SMS'
    ]),
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 12,
    CURLOPT_SSL_VERIFYPEER => false,
    CURLOPT_HTTPHEADER => [
        'Authorization: Basic ' . base64_encode('dm328432.14a:Mahenge2004#'),
        'Content-Type: application/json',
        'Accept: application/json',
    ],
]);
$response = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);
echo "HTTP Status: $code\nResponse: $response\nError: $error\n";
