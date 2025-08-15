local function EditHarga(category, itemData)
    local input = lib.inputDialog('Edit Harga', {{ type = 'number', label = 'Harga Baru', default = itemData.price, required = true }})
    if input then
        local success = lib.callback.await('tk-disnaker:menu:editharga', false, { key = category, item = itemData.item, newPrice = input[1] })
        lib.notify({ title = success and 'DISNAKER' or 'DISNAKER', description = success and 'Berhasil mengubah harga item' or 'Gagal mengubah harga item', type = success and 'success' or 'error' })
    end
end

local function EditStock(category, itemData)
    local input = lib.inputDialog('Edit Stock', {{ type = 'number', label = 'Stock Baru', default = itemData.stock, required = true }})
    if input then
        local success = lib.callback.await('tk-disnaker:menu:editStock', false, { key = category, item = itemData.item, newStock = input[1] })
        lib.notify({ title = success and 'DISNAKER' or 'DISNAKER', description = success and 'Berhasil mengubah stock item' or 'Gagal mengubah stock item', type = success and 'success' or 'error' })
    end
end

local function menuAdmin()
    local data = lib.callback.await('tk-disnaker:main:getData', false)
    local options = {}
    local allItems = exports.ox_inventory:Items()
    
    table.insert(options, {
        title = 'Tambah Kategori',
        description = 'Tambah kategori baru',
        icon = 'fa-solid fa-plus',
        onSelect = function()
            local input = lib.inputDialog('Tambah Kategori', {
                { type = 'input', label = 'Nama Kategori', description = 'Masukkan nama kategori baru', required = true }
            })
            if input then
                lib.callback.await('tk-disnaker:menu:addCategory', false, input[1])
            end
        end
    })

    for category, items in pairs(data) do
        table.insert(options, {
            title = category,
            description = 'Kelola kategori ' .. category,
            onSelect = function()
                local categoryOptions = {
                    {
                        title = 'Tambah Item',
                        description = 'Tambah item baru ke kategori ' .. category,
                        icon = 'fa-solid fa-plus',
                        onSelect = function()
                            local itemOptions = {}
                            
                            for k, v in pairs(allItems) do
                                table.insert(itemOptions, {
                                    value = k,
                                    label = v.label
                                })
                            end
                            
                            table.sort(itemOptions, function(a, b)
                                return a.label:lower() < b.label:lower()
                            end)
                            
                            local input = lib.inputDialog('Tambah Item', {
                                {
                                    type = 'select',
                                    label = 'Pilih Item',
                                    options = itemOptions,
                                    required = true,
                                    search = true
                                },
                                {
                                    type = 'number',
                                    label = 'Harga',
                                    description = 'Masukkan harga item',
                                    required = true,
                                    icon = 'hashtag'
                                },
                                {
                                    type = 'number',
                                    label = 'Stock',
                                    description = 'Masukkan jumlah stock',
                                    required = true,
                                    icon = 'hashtag'
                                }
                            })
                            
                            if input then
                                local selectedItem = input[1]
                                local selectedItemLabel = allItems[selectedItem].label
                                if lib.alertDialog({
                                    header = 'Konfirmasi',
                                    content = 'Menambahkan ' .. selectedItemLabel .. ' ke kategori ' .. category .. '?',
                                    centered = true,
                                    cancel = true
                                }) then
                                    lib.callback.await('tk-disnaker:menu:addItems', false, {
                                        key = category,
                                        newItem = selectedItem,
                                        newPrice = input[2],
                                        stock = input[3]
                                    })
                                end
                            end
                        end
                    },
                    {
                        title = 'Hapus Kategori',
                        description = 'Hapus kategori ' .. category,
                        icon = 'fa-solid fa-minus',
                        onSelect = function()
                            if lib.alertDialog({
                                header = 'Hapus Kategori',
                                content = 'Apakah anda yakin ingin menghapus kategori ' .. category .. '?',
                                centered = true,
                                cancel = true
                            }) then
                                lib.callback.await('tk-disnaker:menu:deleteCategory', false, { key = category })
                            end
                        end
                    }
                }

                for _, itemData in ipairs(items) do
                    local itemInfo = allItems[itemData.item]
                    local itemLabel = itemInfo and itemInfo.label or itemData.item
                    
                    table.insert(categoryOptions, {
                        title = itemLabel,
                        description = 'Harga: TK$' .. lib.math.groupdigits(itemData.price, '.') .. ' | Stock: ' .. itemData.stock,
                        onSelect = function()
                            lib.registerContext({
                                id = 'item_options',
                                title = itemLabel,
                                menu = 'category_menu',
                                options = {
                                    {
                                        title = 'Edit Harga',
                                        icon = 'fa-solid fa-pencil',
                                        description = 'Harga saat ini: TK$' .. lib.math.groupdigits(itemData.price, '.'),
                                        onSelect = function()
                                            EditHarga(category, itemData)
                                        end
                                    },
                                    {
                                        title = 'Edit Stock',
                                        description = 'Stock saat ini: ' .. itemData.stock,
                                        icon = 'fa-solid fa-file-pen',
                                        onSelect = function()
                                            EditStock(category, itemData)
                                        end
                                    },
                                    {
                                        title = 'Hapus Item',
                                        description = 'Hapus ' .. itemLabel,
                                        icon = 'fa-solid fa-minus',
                                        onSelect = function()
                                            if lib.alertDialog({
                                                header = 'Hapus Item',
                                                content = 'Apakah anda yakin ingin menghapus ' .. itemLabel .. '?',
                                                centered = true,
                                                cancel = true
                                            }) then
                                                lib.callback.await('tk-disnaker:menu:delItems', false, {
                                                    key = category,
                                                    item = itemData.item
                                                })
                                            end
                                        end
                                    }
                                }
                            })
                            lib.showContext('item_options')
                        end
                    })
                end
                
                lib.registerContext({
                    id = 'category_menu',
                    title = 'Kategori: ' .. category,
                    menu = 'admin_menu',
                    options = categoryOptions
                })
                lib.showContext('category_menu')
            end
        })
    end
    
    lib.registerContext({
        id = 'admin_menu',
        title = 'Menu Admin Disnaker',
        options = options
    })
    
    lib.showContext('admin_menu')
end

---@param key string
---@param value any
local function MenPenjualan(key, value)
    local option = {}
    local allItems = exports.ox_inventory:Items()
    
    for k, v in pairs(value) do
        local itemData = allItems[v.item]
        local itemLabel = itemData and itemData.label or v.item
        local playerItemCount = exports.ox_inventory:GetItemCount(v.item)
        
        option[#option + 1] = {
            title = itemLabel,
            icon = "nui://ox_inventory/web/images/" .. v.item .. ".png",
            description = 'Stock: ' .. tostring(v.stock) .. ' \n ' .. 'Harga: TK$' .. lib.math.groupdigits(v.price, '.'),
            onSelect = function()
                local input = lib.inputDialog('Penjualan ' .. itemLabel, {
                    { 
                        type = 'number', 
                        label = 'Input', 
                        description = 'Jumlah Yang Ingin Anda Jual (Max: ' .. playerItemCount .. ')', 
                        icon = 'hashtag',
                        min = 1,
                        max = playerItemCount
                    },
                })
                if input and input[1] and input[1] > 0 and input[1] <= playerItemCount then
                    lib.callback.await('tk-disnaker:jual:jualItems', false,
                        { key = key, item = v.item, price = v.price, stock = v.stock, input = input[1] })
                end
            end,
        }
    end

    lib.registerContext({
        id = 'sale_menu',
        title = 'Penjualan ' .. key,
        menu = 'menu_penjualan',
        options = option
    })

    lib.showContext('sale_menu')
end

local function dataJual()
    local data = lib.callback.await('tk-disnaker:main:getData', false)
    local option = {}
    for k, v in pairs(data) do
        option[#option + 1] = {
            title = k,
            onSelect = function()
                MenPenjualan(k, v)
            end
        }
    end

    lib.registerContext({
        id = 'menu_penjualan',
        title = 'Menu Penjualan',
        options = option
    })

    lib.showContext('menu_penjualan')
end

local function MenPembelian(key, value)
    local option = {}
    local allItems = exports.ox_inventory:Items()
    
    for _, v in pairs(value) do
        local itemData = allItems[v.item]
        local itemLabel = itemData and itemData.label or v.item
        
        option[#option + 1] = {
            title = itemLabel,
            icon = "nui://ox_inventory/web/images/" .. v.item .. ".png",
            description = 'Stock: ' .. tostring(v.stock) .. ' \n ' 
                .. 'Harga: TK$' .. lib.math.groupdigits(v.price, '.'),
            onSelect = function()
                local input = lib.inputDialog('Pembelian ' .. itemLabel, {
                    { 
                        type = 'number', 
                        label = 'Jumlah', 
                        description = 'Masukkan jumlah yang ingin Anda beli (Max: ' .. v.stock .. ')', 
                        icon = 'hashtag',
                        min = 1,
                        max = v.stock
                    },
                })
                if input and input[1] and input[1] > 0 and input[1] <= v.stock then
                    lib.callback.await('tk-disnaker:beli:buyItems', false,
                        { key = key, item = v.item, price = v.price, input = input[1] })
                end
            end,
        }
    end

    lib.registerContext({
        id = 'buy_menu',
        title = 'Pembelian ' .. key,
        menu = 'menu_beli',
        options = option
    })
    
    lib.showContext('buy_menu')
end

local function dataBeli()
    local data = lib.callback.await('tk-disnaker:main:getData', false)
    local option = {}
    for k, v in pairs(data) do
        option[#option + 1] = {
            title = k,
            onSelect = function()
                MenPembelian(k, v)
            end
        }
    end

    lib.registerContext({
        id = 'menu_beli',
        title = 'Menu Pembelian',
        options = option
    })
    
    lib.showContext('menu_beli')
end

CreateThread(function()
    local coords = Config.PedLocation
    local model = Config.PedModel
    while not HasModelLoaded(model) do
        RequestModel(model)
        Wait(10)
    end
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1, coords.w, false, true)
    SetModelAsNoLongerNeeded(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    exports.ox_target:addLocalEntity(ped, {
        {
            icon = 'fa-solid fa-money-bill',
            label = 'Jual Disnaker',
            onSelect = function()
                dataJual()
            end,
        },
        {
            icon = 'fa-solid fa-cart-shopping',
            label = 'Beli Disnaker',
            onSelect = function()
                dataBeli()
            end,
        },
        {
            icon = 'fa-solid fa-pencil',
            label = 'Edit Disnaker',
            canInteract = function()
                local admin = lib.callback.await('tk-disnaker:checkAdmin', false)
                if admin then
                    return true
                end
                return false
            end,
            onSelect = function()
                menuAdmin()
            end,
        },
    })
end)