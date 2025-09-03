ServerCfg = {}

-- Multi-speaker per player
ServerCfg.OneActivePerPlayer = false

-- Kontrol
ServerCfg.AllowPublicControl = false
ServerCfg.ControlRadius      = 6.0
ServerCfg.AllowedDomains = { 'youtube.com', 'youtu.be', 'soundcloud.com' }

-- DB tables
ServerCfg.DB = {
  TableBoxes = 'tk_boombox_boxes',
  TableSongs = 'tk_boombox_songs',
}

-- YouTube
ServerCfg.YouTube = {
  APIKey     = 'AIzaSyAh3_JAiC3NqgywqHZ2r9TAVYqQvzWc49Q',
  MaxResults = 5
}

-- Relog grace (menit)
ServerCfg.RelogGraceMinutes = 30

-- Wipe saat resource start/stop
ServerCfg.WipeOnResourceStart = true
ServerCfg.WipeOnResourceStop  = true

-- Item → model
ServerCfg.Items = {
  ['boombox']           = 'prop_boombox_01',
  ['speaker_small']     = 'h4_prop_battle_club_speaker_small',
  ['speaker_l_01a']     = 'sf_prop_sf_speaker_l_01a',
  ['speaker_array']     = 'h4_prop_battle_club_speaker_array',
  ['speaker_dj']        = 'h4_prop_battle_club_speaker_dj',
  ['speaker_stand_01a'] = 'sf_prop_sf_speaker_stand_01a',
}
