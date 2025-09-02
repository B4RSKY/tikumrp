ClientCfg = {}

ClientCfg.DefaultModel = 'prop_boombox_01'
ClientCfg.Models = {
  'prop_boombox_01',
  'h4_prop_battle_club_speaker_small',
  'sf_prop_sf_speaker_l_01a',
  'h4_prop_battle_club_speaker_array',
  'h4_prop_battle_club_speaker_dj',
  'sf_prop_sf_speaker_stand_01a',
}

-- Audio defaults
ClientCfg.DefaultDistance = 25
ClientCfg.MaxDistance     = 80
ClientCfg.DefaultVolume   = 0.5
ClientCfg.MaxVolume       = 1.0

ClientCfg.UI = { ShowLocalVolume = true }

ClientCfg.Keybinds = { Place = 'G', Store = 'K' }

ClientCfg.Carry = {
  Enabled       = true,
  Bone          = 57005,
  Offset        = vec3(0.32, 0.00, -0.05),
  Rot           = vec3(0.10, 270.0, 60.0),
  AnimDict      = 'anim@heists@box_carry@',
  AnimName      = 'idle',
  KeepPlaying   = true,
  DisableSprint = true,
  DisableJump   = true
}

ClientCfg.CarryPositionUpdateMs = 350