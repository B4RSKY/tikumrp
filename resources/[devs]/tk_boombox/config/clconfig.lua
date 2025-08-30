ClientCfg = {}

ClientCfg.Model           = `prop_boombox_01`
ClientCfg.DefaultDistance = 25
ClientCfg.MaxDistance     = 80
ClientCfg.DefaultVolume   = 0.5
ClientCfg.MaxVolume       = 1.0

ClientCfg.UI = {
  ShowLocalVolume = true,
}

ClientCfg.Carry = {
  Enabled       = true,
  Bone          = 57005,
  Offset        = vec3(0.27, 0.00, 0.00),
  Rot           = vec3(0.0, 263.0, 58.0),
  AnimDict      = 'move_weapon@jerrycan@generic',
  AnimName      = 'idle',
  KeepPlaying   = true,
  DisableSprint = true,
  DisableJump   = true
}

ClientCfg.CarryPositionUpdateMs = 350