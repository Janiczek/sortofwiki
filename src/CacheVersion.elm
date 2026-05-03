module CacheVersion exposing (Versions, same, zero)


type alias Versions =
    { contentVersion : Int
    , auditVersion : Int
    , viewsVersion : Int
    }


zero : Versions
zero =
    { contentVersion = 0
    , auditVersion = 0
    , viewsVersion = 0
    }


same : Versions -> Versions -> Bool
same left right =
    left.contentVersion
        == right.contentVersion
        && left.auditVersion
        == right.auditVersion
        && left.viewsVersion
        == right.viewsVersion
