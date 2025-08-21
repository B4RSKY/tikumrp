---@class BillingServerConfig
---@field LogsEnabled boolean
---@field Webhooks table<string, string>
SVConfig = SVConfig or {}

SVConfig.LogsEnabled = true

SVConfig.Webhooks = {
	createBill = 'https://discord.com/api/webhooks/1408013458095472721/8edHXSkxpDy1T0hNdjUJijX2fK-GKLM0qss0HpGjL_9HuAVeYcQJR6Pi8UpNNBl0P8H1',
	payBill = 'https://discord.com/api/webhooks/1408013458095472721/8edHXSkxpDy1T0hNdjUJijX2fK-GKLM0qss0HpGjL_9HuAVeYcQJR6Pi8UpNNBl0P8H1',
	refundBill = 'https://discord.com/api/webhooks/1408013458095472721/8edHXSkxpDy1T0hNdjUJijX2fK-GKLM0qss0HpGjL_9HuAVeYcQJR6Pi8UpNNBl0P8H1',
	setGradePerm = 'https://discord.com/api/webhooks/1408013458095472721/8edHXSkxpDy1T0hNdjUJijX2fK-GKLM0qss0HpGjL_9HuAVeYcQJR6Pi8UpNNBl0P8H1'
}


