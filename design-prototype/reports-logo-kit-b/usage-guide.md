# Reports · Report Pop

## Idea

Three message dots sit inside a lively speech bubble. The bubble makes the app’s reporting purpose clear; the uneven dots and rounded hand-drawn wordmark keep it warm and playful without a mascot.

## Color

| Color | Hex | Use |
|---|---|---|
| Reports orange | `#FF9600` | Dot accents and app icon tile |
| Ink | `#3C3C3C` | Bubble, wordmark, and small text |
| Dark orange | `#CC7A00` | Larger secondary accents |
| White | `#FFFFFF` | Knockouts and light backgrounds |

Ink on orange is **5.05:1**. Orange on white is **2.18:1**, so keep orange off small text and use ink for the wordmark. The custom letter paths need no installed font.

## Choose a version

- **Horizontal color lockup:** headers, splash screens, and app store artwork.
- **Stacked color lockup:** square layouts, posters, and profile panels.
- **Color symbol:** light backgrounds and spaces where the wordmark is too small.
- **Small-size symbol:** favicons and other tiny placements; its enlarged dots survive reduction better.
- **White lockup or symbol:** dark backgrounds.
- **Black or orange mono:** one-color reproduction; the dots are open cutouts.
- **App icon:** charcoal bubble on the orange rounded-square tile.

## Clear space and size

Keep at least one dot diameter of clear space around the mark. Use the horizontal lockup at **210 px wide or larger**, and the standalone symbol at **28 px or larger**. For a **16 px favicon**, use the small-size cut supplied in the web export. For print, keep the horizontal logo at **38 mm wide or larger** and the symbol at **8 mm or larger**.

## Do

- Use the full-color mark on white or a quiet light background.
- Use the reversed white version on charcoal or another dark background.
- Put the app icon on its orange tile; do not add a second background tile.
- Preserve the dot cutouts in mono versions and keep the mark’s proportions.

## Avoid

- Don’t recolor the wordmark orange or place it small on orange.
- Don’t stretch, rotate, outline, shadow, or add a character to the logo.
- Don’t use the full-size symbol at favicon size.

## Files

- `masters/` contains the editable color and mono SVG masters.
- `exports/color/` contains transparent PNGs of the color masters.
- `exports/symbol/`, `exports/horizontal/`, `exports/stacked/`, and `exports/wordmark/` contain black, white, orange, square, and raster variants for their respective logo forms.
- `exports/web/` contains favicon, Apple touch, PWA, and manifest files. Add the provided `head-snippet.html` to a web page’s `<head>`.
- `presentation.html` and `presentation-slides/` show the identity in context.

SVG artwork contains vector paths only. The wordmark uses custom rounded vector strokes, so it is not live text and needs no external font. Expand those strokes before specialty cutting or engraving.
