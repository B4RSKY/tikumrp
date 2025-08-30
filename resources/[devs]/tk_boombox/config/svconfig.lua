ServerCfg = {}
ServerCfg.ItemName = 'boombox'

ServerCfg.AllowPublicControl = false
ServerCfg.OneActivePerPlayer = true
ServerCfg.ControlRadius      = 6.0

-- Validasi link (opsional)
ServerCfg.AllowedDomains = { 'youtube.com'}

-- DB tables
ServerCfg.DB = {
  TableBoxes = 'tk_boombox_boxes',
  TableSongs = 'tk_boombox_songs',
}

-- YouTube API
ServerCfg.YouTube = {
  APIKey     = 'AIzaSyAh3_JAiC3NqgywqHZ2r9TAVYqQvzWc49Q',
  MaxResults = 5
}

-- Relog grace (menit)
ServerCfg.RelogGraceMinutes = 30

-- Wipe behavior saat resource start/stop
ServerCfg.WipeOnResourceStart = true
ServerCfg.WipeOnResourceStop  = true
