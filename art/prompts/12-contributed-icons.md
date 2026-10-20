# 12 Contributed icons: code editor and chat

Two app icon masters contributed by Pablo Herranz Ramírez in pull request #22,
which describes them as hand-drawn in the theme's flat palette style. They are
SVG on the set's 2048-unit canvas. The build holds their colours to the palette
like every other master (`normalise()` in `tools/vectors.py`). Their copyright
is the contributor's (`REUSE.toml`), under the artwork's CC-BY-SA-4.0.

| Master | Subject | Used for |
|---|---|---|
| `app-code` | "two-tone plum block with pumpkin `{ }` braces and a little ghost" | VSCodium and Visual Studio Code (`vscodium`, `codium`, `com.vscodium.codium`, `code`, `vscode`) |
| `app-chat` | "two overlapping speech bubbles (vampire + witch hat)" | Slack, Polari and NeoChat (`com.slack.Slack`, `slack`, `org.gnome.Polari`, `polari`, `org.kde.neochat`, `internet-chat`) |

Thunderbird (`thunderbird`, `thunderbird-esr`, `org.mozilla.Thunderbird`) takes
the existing mail icon (`app-mail`), and Spotify (`spotify`, `spotify-client`,
`com.spotify.Client`) the existing music icon (`app-music`).

Design review: both read from 16 px on the dark panel, a light background and
the ember selection. At 16 px the code icon's dark body merges with the dark
panel and the braces carry it; the chat icon's fangs show as a white band.
Neither reproduces Slack's or Visual Studio Code's marks. On Plasma, the
short name `code` would otherwise take over Breeze's `code-*` icons; the build
links those to Breeze's own (`tools/kde_lookup.py`).
