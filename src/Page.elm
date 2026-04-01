module Page exposing (FrontendDetails, Page, Slug, frontendDetails)


type alias Page =
    { slug : Slug
    , content : String
    }


type alias Slug =
    String


type alias FrontendDetails =
    { markdownSource : String
    }


frontendDetails : Page -> FrontendDetails
frontendDetails p =
    { markdownSource = p.content }
