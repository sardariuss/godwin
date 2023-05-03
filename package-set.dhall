let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.7.3-20221102/package-set.dhall sha256:9c989bdc496cf03b7d2b976d5bf547cfc6125f8d9bb2ed784815191bd518a7b9
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions =
    [
        { name = "stableRBT"
        , version = "v0.6.0"
        , repo = "https://github.com/canscale/StableRBTree"
        , dependencies = ["base"]
        },
        { name = "map"
        , repo = "https://github.com/ZhenyaUsenko/motoko-hash-map"
        , version = "v8.1.0"
        , dependencies = ["base"]
        },
        {
        name = "StableTrieMap",
        version = "main",
        repo = "https://github.com/NatLabs/StableTrieMap",
        dependencies = ["base"] : List Text
        },
        {
        name = "StableBuffer",
        version = "v0.2.0",
        repo = "https://github.com/canscale/StableBuffer",
        dependencies = ["base"] : List Text
        },
        {
        name = "array",
        version = "v0.2.0",
        repo = "https://github.com/aviate-labs/array.mo",
        dependencies = ["base"] : List Text
        },
        {
        name = "itertools",
        version = "main",
        repo = "https://github.com/NatLabs/Itertools.mo",
        dependencies = ["base"] : List Text
        },
        { name = "icrc1"
        , version = "main"
        , repo = "https://github.com/NatLabs/icrc1/"
        , dependencies = ["base"]
        },
        { name = "testing"
        , version = "v0.1.0"
        , repo = "https://github.com/internet-computer/testing"
        , dependencies = [] : List Text
        }
    ] : List Package

let overrides =
    [] : List Package

in  upstream # additions # overrides
