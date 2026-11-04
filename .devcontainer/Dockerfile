FROM texlive/texlive:latest

# LilyPond is required by lyluatex, which nagyhet-2026, nagyhet-vetites,
# temetes, temetesi-mise, urnapja and urnapja-vetites all use. Git is needed
# for the gregosheet submodule, and pymupdf/pypdf back reprint.py and
# scramble.py. Caladea is metric compatible with Cambria and is here as a
# stand-in for anyone who cannot supply Cambria itself; see the note in
# devcontainer.json about .devcontainer/fonts.
RUN apt-get update && apt-get install -y --no-install-recommends \
      lilypond \
      fontconfig \
      git \
      ca-certificates \
      python3 \
      python3-pymupdf \
      python3-pypdf \
      fonts-crosextra-caladea \
 && rm -rf /var/lib/apt/lists/* \
 && fc-cache -f

# Match the devcontainer default user so bind mounted files stay writable.
ARG USERNAME=vscode
RUN useradd -m -s /bin/bash ${USERNAME} || true

WORKDIR /workspace
