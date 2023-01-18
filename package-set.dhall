let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.7.3-20221102/package-set.dhall sha256:9c989bdc496cf03b7d2b976d5bf547cfc6125f8d9bb2ed784815191bd518a7b9
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions =
    [
        { name = "stableRBT"
        , version = "v0.6.0"
        , repo = "https://github.com/canscale/StableRBTree"
        , dependencies = ["base"] : List Text
        },
        { name = "map"
        , repo = "https://github.com/ZhenyaUsenko/motoko-hash-map"
        , version = "v7.0.0"
        , dependencies = [ "base"]
        }
    ] : List Package

let overrides =
    [] : List Package

in  upstream # additions # overrides
