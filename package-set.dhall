let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.21-20220215/package-set.dhall sha256:b46f30e811fe5085741be01e126629c2a55d4c3d6ebf49408fb3b4a98e37589b
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions =
    [
      { name = "stableRBT"
      , version = "v0.6.0"
      , repo = "https://github.com/canscale/StableRBTree"
      , dependencies = ["base"] : List Text
      }
    ] : List Package

let overrides =
    [] : List Package

in  upstream # additions # overrides
