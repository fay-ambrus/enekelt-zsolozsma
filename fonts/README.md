# Betűtípusok

`OSFONTDIR` erre a könyvtárra mutat, így a `fontspec` mindent megtalál itt
minden további beállítás nélkül.

## Verziókövetett

- `GuidoHU.ttf` — a gregorián kottaírás betűtípusa, © Bali János, szabadon
  terjeszthető. A `gregosheet.sty` `\newfontfamily\MusicFont{GuidoHU.ttf}`
  néven hivatkozik rá.
- `GuidoHU.sfd` — a FontForge forrásállomány.
- `guidohu_.ttf` — korábbi változat.
- `guidohu_kod_embed.pdf` — kódtábla.

## Nem verziókövetett

A `styles.tex` a **Cambria** betűtípust kéri, amely a Microsoft tulajdona, és
nem terjeszthető tovább: a `.gitignore` ezért kizárja. Egyszer be kell másolni:

    cp ~/Library/Fonts/Cambria* fonts/

Enélkül a könyvek nem fordulnak le. A PDF-ekbe viszont beágyazható — a
betűtípus `fsType` értéke `0x0008` („Editable embedding allowed”) —, ezért az
`out/` könyvtár verziókövetett PDF-jei rendben vannak.

Szabadon terjeszthető alternatíva a **Caladea** (OFL-1.1 / Apache-2.0), amely
metrikailag megegyezik a Cambriával, és a devcontainerben telepítve van.
