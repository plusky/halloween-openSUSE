# Prompts

One file per generated asset, numbered in the order they were made
(`NN-short-name.md`). Each records everything needed to reproduce or
continue the asset (art made by hand gets a file too, saying who made it and
with what):

- model and settings (size, aspect ratio, seed, image weight)
- the full prompt and negative prompt
- reference images used (paths in `art/source/` or earlier prompt numbers)
- which result was kept, and any post-processing done by hand

Under its title, each record lists the masters it made and whose copyright
they are; a list of master paths that runs long goes on indented lines:

```markdown
# 12 Contributed icons: code editor and chat

- Masters: `art/source/vectors/app-code.svg`, `art/source/vectors/app-chat.svg`
- Copyright: 2026 Pablo Herranz Ramírez <pablo.herranz@suse.com>
```

`make check` holds every file in `art/source/` to it: some record must list
it, and REUSE must give it the copyright that record states. A master remade
later is listed by both records. Art that isn't the maintainer's gets its
author's copyright in `REUSE.toml`, in an annotation after the one for all
artwork, so that it wins.

Prompt rules for this project:

- Never write "openSUSE", "Geeko" or "logo": the chameleon is an original
  character, inspired by the Geeko, never a copy of the trademark.
- Always add "no text, no lettering, no watermark, no signature".
- Characters to be cut out go on a solid magenta background (never green,
  because the chameleon is green).
