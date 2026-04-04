module ProgramTest.Query exposing
    ( expectAll
    , expectBacklinks
    , expectDataAttributeOccurrenceCount
    , expectDescendantMatchesEvery
    , expectDoesNotHaveAriaLabel
    , expectDoesNotHaveDataContext
    , expectDoesNotHaveReadonly
    , expectEmpty
    , expectHasClass
    , expectHasDataAttributes
    , expectHasHref
    , expectHasInputValue
    , expectHasNotId
    , expectHasNotText
    , expectHasReadonly
    , expectHasSubmissionId
    , expectHasText
    , expectHasTexts
    , expectHasWikiSlug
    , expectHostAdminCreateWikiSlugInputUsesHtmlConstraints
    , expectLink
    , expectNoBacklinks
    , expectPageShowsWikiSlug
    , expectTagOccurrenceCount
    , expectTextOccurrenceCount
    , expectWikiCard
    , expectWikiHomePageShowsSlug
    , expectWikiLoginPageShowsSlug
    , headingIs
    , subheadingIs
    , withinAriaLabel
    , withinAuditEventIndex
    , withinDataAttribute
    , withinDataAttributes
    , withinHostAdminWikiRow
    , withinHref
    , withinId
    , withinIdAndDataAttributes
    , withinIds
    , withinLayoutHeader
    , withinLinkHref
    , withinPageMarkdownHeading
    , withinTag
    , withinTagAndHref
    , withinWikiCatalogRow
    )

import Expect exposing (Expectation)
import Html.Attributes
import Test.Html.Query
import Test.Html.Selector
import Submission
import Wiki


dataAttr : String -> String -> Test.Html.Selector.Selector
dataAttr name value =
    Test.Html.Selector.attribute (Html.Attributes.attribute name value)


withinId : String -> (Test.Html.Query.Single msg -> expectation) -> Test.Html.Query.Single msg -> expectation
withinId elementId f root =
    root
        |> singleWithinId elementId
        |> f


singleWithinId : String -> Test.Html.Query.Single msg -> Test.Html.Query.Single msg
singleWithinId elementId single =
    Test.Html.Query.find [ Test.Html.Selector.id elementId ] single


withinIdAndDataAttributes : String -> List ( String, String ) -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinIdAndDataAttributes elementId dataPairs f single =
    Test.Html.Query.find
        (Test.Html.Selector.id elementId
            :: List.map (\( name, value ) -> dataAttr name value) dataPairs
        )
        single
        |> f


withinIds : List String -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinIds elementIds f root =
    List.foldl singleWithinId root elementIds
        |> f


withinAriaLabel : String -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinAriaLabel label f single =
    Test.Html.Query.find
        [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" label) ]
        single
        |> f


withinLayoutHeader : (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinLayoutHeader f root =
    Test.Html.Query.find [ dataAttr "data-context" "layout-header" ] root
        |> f


withinHostAdminWikiRow : String -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinHostAdminWikiRow wikiSlug f single =
    Test.Html.Query.find
        [ dataAttr "data-context" "host-admin-wiki-row"
        , dataAttr "data-wiki-slug" wikiSlug
        ]
        single
        |> f


withinWikiCatalogRow : String -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinWikiCatalogRow wikiSlug f single =
    Test.Html.Query.find [ dataAttr "data-wiki-slug" wikiSlug ] single
        |> f


withinDataAttribute : String -> String -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinDataAttribute name value f single =
    Test.Html.Query.find [ dataAttr name value ] single
        |> f


withinDataAttributes : List ( String, String ) -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinDataAttributes pairs f single =
    Test.Html.Query.find (List.map (\( name, value ) -> dataAttr name value) pairs) single
        |> f


withinHref : String -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinHref href f single =
    Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.href href) ] single
        |> f


withinTagAndHref : String -> String -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinTagAndHref tagName href f single =
    Test.Html.Query.find
        [ Test.Html.Selector.tag tagName
        , Test.Html.Selector.attribute (Html.Attributes.href href)
        ]
        single
        |> f


withinLinkHref : String -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinLinkHref href f single =
    Test.Html.Query.find
        [ Test.Html.Selector.all
            [ Test.Html.Selector.tag "a"
            , Test.Html.Selector.attribute (Html.Attributes.href href)
            ]
        ]
        single
        |> f


singleWithinTag : String -> Test.Html.Query.Single msg -> Test.Html.Query.Single msg
singleWithinTag tagName single =
    Test.Html.Query.find [ Test.Html.Selector.tag tagName ] single


withinTag : String -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinTag tagName f root =
    root
        |> singleWithinTag tagName
        |> f


withinPageMarkdownHeading : String -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinPageMarkdownHeading headingTag f single =
    single
        |> singleWithinId "page-markdown"
        |> singleWithinTag headingTag
        |> f


withinAuditEventIndex : String -> (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
withinAuditEventIndex index f single =
    Test.Html.Query.find [ dataAttr "data-audit-event" index ] single
        |> f


expectHasText : String -> Test.Html.Query.Single msg -> Expectation
expectHasText fragment single =
    Test.Html.Query.has [ Test.Html.Selector.text fragment ] single


expectHasNotText : String -> Test.Html.Query.Single msg -> Expectation
expectHasNotText fragment single =
    Test.Html.Query.hasNot [ Test.Html.Selector.text fragment ] single


expectHasNotId : String -> Test.Html.Query.Single msg -> Expectation
expectHasNotId elementId single =
    Test.Html.Query.hasNot [ Test.Html.Selector.id elementId ] single


expectHasTexts : List String -> Test.Html.Query.Single msg -> Expectation
expectHasTexts fragments single =
    Test.Html.Query.has (List.map Test.Html.Selector.text fragments) single


expectHasWikiSlug : String -> Test.Html.Query.Single msg -> Expectation
expectHasWikiSlug wikiSlug single =
    Test.Html.Query.has [ dataAttr "data-wiki-slug" wikiSlug ] single


expectHasSubmissionId : String -> Test.Html.Query.Single msg -> Expectation
expectHasSubmissionId submissionId single =
    Test.Html.Query.has [ dataAttr "data-submission-id" submissionId ] single


expectHasDataAttributes : List ( String, String ) -> Test.Html.Query.Single msg -> Expectation
expectHasDataAttributes pairs single =
    Test.Html.Query.has (List.map (\( name, value ) -> dataAttr name value) pairs) single


expectHasInputValue : String -> Test.Html.Query.Single msg -> Expectation
expectHasInputValue value single =
    Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.value value) ] single


{-| Create-wiki slug field: native constraint validation (`pattern`, `maxlength`, `required`, `title`).
-}
expectHostAdminCreateWikiSlugInputUsesHtmlConstraints : Test.Html.Query.Single msg -> Expectation
expectHostAdminCreateWikiSlugInputUsesHtmlConstraints root =
    withinId "host-admin-create-wiki-slug"
        (expectDescendantMatchesEvery
            [ Test.Html.Selector.attribute (Html.Attributes.pattern Submission.pageSlugHtmlPattern)
            , Test.Html.Selector.attribute (Html.Attributes.maxlength Submission.pageSlugHtmlMaxLength)
            , Test.Html.Selector.attribute (Html.Attributes.required True)
            , Test.Html.Selector.attribute (Html.Attributes.title Submission.pageSlugConstraintTitle)
            ]
        )
        root


expectHasReadonly : Test.Html.Query.Single msg -> Expectation
expectHasReadonly single =
    Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.readonly True) ] single


expectDoesNotHaveReadonly : Test.Html.Query.Single msg -> Expectation
expectDoesNotHaveReadonly single =
    Test.Html.Query.hasNot [ Test.Html.Selector.attribute (Html.Attributes.readonly True) ] single


expectDoesNotHaveDataContext : String -> Test.Html.Query.Single msg -> Expectation
expectDoesNotHaveDataContext context single =
    Test.Html.Query.hasNot [ dataAttr "data-context" context ] single


expectDoesNotHaveAriaLabel : String -> Test.Html.Query.Single msg -> Expectation
expectDoesNotHaveAriaLabel label single =
    Test.Html.Query.hasNot
        [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" label) ]
        single


expectHasHref : String -> Test.Html.Query.Single msg -> Expectation
expectHasHref href single =
    Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.href href) ] single


expectHasClass : String -> Test.Html.Query.Single msg -> Expectation
expectHasClass className single =
    Test.Html.Query.has [ Test.Html.Selector.class className ] single


expectEmpty : Test.Html.Query.Single msg -> Expectation
expectEmpty single =
    Test.Html.Query.has [] single


expectDescendantMatchesEvery : List Test.Html.Selector.Selector -> Test.Html.Query.Single msg -> Expectation
expectDescendantMatchesEvery selectors single =
    Test.Html.Query.has selectors single


expectLink : { href : String, label : String } -> Test.Html.Query.Single msg -> Expectation
expectLink { href, label } single =
    Test.Html.Query.has
        [ Test.Html.Selector.tag "a"
        , Test.Html.Selector.attribute (Html.Attributes.href href)
        , Test.Html.Selector.text label
        ]
        single


expectPageShowsWikiSlug : String -> String -> Test.Html.Query.Single msg -> Expectation
expectPageShowsWikiSlug pageElementId wikiSlug root =
    withinId pageElementId (expectHasWikiSlug wikiSlug) root


expectWikiCard : { slug : String, title : String } -> Test.Html.Query.Single msg -> Expectation
expectWikiCard { slug, title } root =
    withinWikiCatalogRow slug (expectHasText title) root


expectWikiHomePageShowsSlug : String -> Test.Html.Query.Single msg -> Expectation
expectWikiHomePageShowsSlug =
    expectPageShowsWikiSlug "wiki-home-page"


expectWikiLoginPageShowsSlug : String -> Test.Html.Query.Single msg -> Expectation
expectWikiLoginPageShowsSlug =
    expectPageShowsWikiSlug "wiki-login-page"


{-| Published page backlinks section: heading plus one entry per slug (`data-backlink-page-slug`, href).
-}
expectBacklinks : String -> List String -> Test.Html.Query.Single msg -> Expectation
expectBacklinks wikiSlug backlinkPageSlugs root =
    expectAll
        (withinId "page-backlinks" (expectHasText "Backlinks")
            :: List.map
                (\slug ->
                    withinId "page-backlinks-list"
                        (withinHref (Wiki.publishedPageUrlPath wikiSlug slug)
                            (expectHasDataAttributes [ ( "data-backlink-page-slug", slug ) ])
                        )
                )
                backlinkPageSlugs
        )
        root


expectNoBacklinks : Test.Html.Query.Single msg -> Expectation
expectNoBacklinks root =
    withinId "page-backlinks-empty" (expectHasText "No backlinks.") root


expectAll : List (Test.Html.Query.Single msg -> Expectation) -> Test.Html.Query.Single msg -> Expectation
expectAll checks single =
    Expect.all checks single


headingIs : String -> Test.Html.Query.Single msg -> Expectation
headingIs fragment root =
    withinLayoutHeader (expectHasText fragment) root


subheadingIs : String -> Test.Html.Query.Single msg -> Expectation
subheadingIs fragment root =
    withinLayoutHeader (expectHasText fragment) root


expectTextOccurrenceCount : String -> (Int -> Expectation) -> Test.Html.Query.Single msg -> Expectation
expectTextOccurrenceCount fragment expectInt single =
    single
        |> Test.Html.Query.findAll [ Test.Html.Selector.text fragment ]
        |> Test.Html.Query.count expectInt


expectTagOccurrenceCount : String -> (Int -> Expectation) -> Test.Html.Query.Single msg -> Expectation
expectTagOccurrenceCount tagName expectInt single =
    single
        |> Test.Html.Query.findAll [ Test.Html.Selector.tag tagName ]
        |> Test.Html.Query.count expectInt


expectDataAttributeOccurrenceCount : String -> String -> (Int -> Expectation) -> Test.Html.Query.Single msg -> Expectation
expectDataAttributeOccurrenceCount name value expectInt single =
    single
        |> Test.Html.Query.findAll [ dataAttr name value ]
        |> Test.Html.Query.count expectInt
