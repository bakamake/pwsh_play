$token = "8099010241:AAHWaGMuckS25r2nD4z9zQmU_6bMCmZXSKg"
$updates = Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/getUpdates"
#收消息，取最新一条消息的chat id


$chatId = $updates.result[0].message.chat.id
$body = @{
    chat_id = $chatId
    text = "Hello from PowerShell!"
} | ConvertTo-Json

#发消息
Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/sendMessage" `
    -Method POST `
    -Body $body `
    -ContentType "application/json"