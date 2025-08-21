local Translations = {
    ui = {
        last_location = "Lokasi Terakhir",
        confirm = "Confirm",
        select = "Select",
        spawn_header = "Spawn Selector",
        where_would_you_like_to_start = "Where would you like to start?",
        defaultDescription = 'a nice place to start',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
