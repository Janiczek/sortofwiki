module ProgramTest.Fixtures exposing
    ( demoAboutPublished
    , demoGuidesPublished
    , demoHomePublished
    , demoMarkdownPlaygroundPublished
    )


demoHomePublished : String
demoHomePublished =
    """Welcome to the Demo Wiki. See [Guides](/w/Demo/p/Guides) and [MarkdownPlayground](/w/Demo/p/MarkdownPlayground)."""


demoGuidesPublished : String
demoGuidesPublished =
    """## How to use this wiki

Read the **manual**.

The home page links here, so it shows under *Backlinks* below. That list is inbound links only—this page does not link back to home.
"""


demoAboutPublished : String
demoAboutPublished =
    """This page links only to [[Home]]. The home page does not link here; *Backlinks* on home still lists this page because other pages pointing **to** the current page are what backlinks mean.
"""


demoMarkdownPlaygroundPublished : String
demoMarkdownPlaygroundPublished =
    """# Markdown Playground

This page demonstrates seeded Markdown support.

## Inline formatting

This paragraph includes **bold**, *italic*, `inline code`, and ~~strikethrough~~.

## Links

- External link: [Lamdera](https://lamdera.com)
- In-wiki link by slug: [[Guides]]
- In-wiki link with label: [[About|About this wiki]]
- Missing page (red link in UI): [[Story49MissingPage]]
- Raw URL autolink: <https://example.com>

## Lists

- Unordered item one
- Unordered item two
  - Nested unordered item

1. Ordered item one
2. Ordered item two

## Blockquote

> This is a blockquote.
>
> It spans multiple lines.

## Code block

```elm
viewGreeting : String -> String
viewGreeting name =
    "Hello, " ++ name
```

## Horizontal rule

---

## Escaping and entities

Use \\*asterisks\\* literally and show an ampersand entity: &amp;.
"""
