#import "@local/orange-book:0.7.1": book, part, chapter, appendices

#show: book.with(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(by-author)$
  author: "$for(by-author)$$it.name.literal$$sep$, $endfor$",
$endif$
$if(date)$
  date: "$date$",
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
  main-color: brand-color.at("primary", default: blue),
  logo: {
    let logo-info = brand-logo.at("medium", default: none)
    if logo-info != none { image(logo-info.path, alt: logo-info.at("alt", default: none)) }
  },
$if(toc-depth)$
  outline-depth: $toc-depth$,
$endif$
$if(lof)$
  list-of-figure-title: "$if(crossref.lof-title)$$crossref.lof-title$$else$$crossref-lof-title$$endif$",
$endif$
$if(lot)$
  list-of-table-title: "$if(crossref.lot-title)$$crossref.lot-title$$else$$crossref-lot-title$$endif$",
$endif$
)

$if(margin-geometry)$
// Configure marginalia page geometry for book context
// Geometry computed by Quarto's meta.lua filter (typstGeometryFromPaperWidth)
// IMPORTANT: This must come AFTER book.with() to override the book format's margin settings
#import "@preview/marginalia:0.3.1" as marginalia

#show: marginalia.setup.with(
  inner: (
    far: $margin-geometry.inner.far$,
    width: $margin-geometry.inner.width$,
    sep: $margin-geometry.inner.separation$,
  ),
  outer: (
    far: $margin-geometry.outer.far$,
    width: $margin-geometry.outer.width$,
    sep: $margin-geometry.outer.separation$,
  ),
  top: $if(margin.top)$$margin.top$$else$1.25in$endif$,
  bottom: $if(margin.bottom)$$margin.bottom$$else$1.25in$endif$,
  // CRITICAL: Enable book mode for recto/verso awareness
  book: true,
  clearance: $margin-geometry.clearance$,
)

// Override heading styling for levels 2-4 to use marginalia for number placement.
// Orange-book uses place(dx: -width - gap) which doesn't participate in marginalia's
// collision avoidance. By using marginalia.note() with shift: false, heading numbers
// become "immovable objects" that margin notes will dodge around.
//
// NOTE: This does NOT fix orange-book's appendices() function which sets a heading
// numbering function that returns place() content. This causes #ref() to section
// headings in appendices to render incorrectly (number displaced to margin).
// That needs to be fixed upstream in orange-book.
#show heading: it => {
  if it.level == 1 { it } else {
    let size = if it.level == 2 { 1.5em } else if it.level == 3 { 1.1em } else { 1em }
    let color = if it.level < 4 { brand-color.at("primary", default: blue) } else { black }
    let space = if it.level == 2 { 1em } else if it.level == 3 { 0.9em } else { 0.7em }

    set text(size: size)
    block[
      #if it.numbering != none {
        // Format number ourselves - orange-book's appendices() sets a numbering function
        // that returns place() content, which we can't use inside marginalia.note()
        context {
          let nums = counter(heading).get()
          let is-appendix = state("appendix-state", none).get() != none
          let num-str = if is-appendix { numbering("A.1", ..nums) } else { numbering("1.1", ..nums) }
          marginalia.note(
            side: "left",  // Always left of heading (inner on recto, outer on verso)
            counter: none,
            anchor-numbering: none,
            shift: false,  // Fixed position - margin notes will avoid this
            alignment: "baseline",
            text-style: (size: size, fill: color, weight: "regular"),
            block-style: (width: 100%),
          )[#align(right)[#num-str]]
        }
      }
      #it.body
    ]
    v(space, weak: true)
  }
}
$endif$
