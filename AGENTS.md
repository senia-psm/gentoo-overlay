# AGENTS.md — senia Gentoo overlay

Personal Gentoo overlay (name: `senia`, masters: `gentoo`, thin-manifests).
Contains out-of-tree ebuilds not yet in the official Gentoo tree.

## Repository structure

```
<category>/<package>/
    <package>-<version>.ebuild
    Manifest
    files/            ← patches and small companion files (≤20 KiB each)
metadata/layout.conf
profiles/repo_name
```

## Commands

- Validate ebuild syntax: `ebuild <path>.ebuild clean`
- Generate/update Manifest: `ebuild <path>.ebuild manifest`
- Run pkgcheck: `pkgcheck scan <category>/<package>`
- Check staged commits: `pkgcheck scan --commits`
- Verify bash syntax of an eclass: `bash -n <file>.eclass`

## Definition of Done

A task is complete when ALL of the following hold:

1. `pkgcheck scan <category>/<package>` exits 0 with no warnings or errors
2. `Manifest` is present and up to date (all `DIST` entries match actual tarballs)
3. Ebuild uses the latest EAPI (currently **EAPI=8**)
4. All external calls in phase functions have `|| die` or use helpers that die automatically (`emake`, `eapply`, install helpers)
5. Indentation uses **tabs** (not spaces); no trailing whitespace

## When Adding or Updating an Ebuild

### File format rules
- Filename: `<name>-<version>.ebuild` — lowercase, hyphens/underscores/digits/plusses only
- Two-line header exactly:
  ```
  # Copyright 1999-2026 Gentoo Authors
  # Distributed under the terms of the GNU General Public License v2
  ```
- Indent with **tabs**, one tab per level; lines ≤80 chars where practical
- UTF-8 encoding

### Required variables
- `EAPI=8` — always use the latest EAPI
- `DESCRIPTION` — ≤80 chars, describes the package purpose
- `HOMEPAGE` — raw URL(s), never use `${PN}` in the domain
- `SRC_URI` — use `${PV}` / `${P}` to avoid hardcoding versions; use `-> ${P}.tar.gz` renaming for generic upstream filenames
- `LICENSE` — must match a file in the Gentoo `licenses/` directory exactly
- `SLOT="0"` — mandatory even when unused; never use `SLOT=""`
- `KEYWORDS` — only for tested architectures; new ebuilds use `~arch` only (e.g. `~amd64 ~arm ~arm64 ~x86`)
- `IUSE` — omit if empty; do not list arch flags; cumulative with inherited eclasses (don't re-list eclass flags)

### Variables to avoid
- Never redefine `P`, `PV`, `PN`, `PF` — use `MY_P`, `MY_PV`, `MY_PN` instead
- Omit `S="${WORKDIR}/${P}"` — it is the default and is redundant
- Never use `${PN}` in `HOMEPAGE` or in URL domains in `SRC_URI`
- Never use `${HOMEPAGE}` in `SRC_URI`

### Dependency variables (EAPI 8)
- `BDEPEND` — build tools running on CBUILD (e.g. `virtual/pkgconfig`, `app-arch/unzip`)
- `DEPEND` — libraries/headers needed to build, linked against CHOST
- `RDEPEND` — runtime dependencies (include all dynamically linked libraries)
- `PDEPEND` — post-merge dependencies (use only to break circular deps)
- Always include `virtual/pkgconfig` in `BDEPEND` when calling `pkg-config`
- List one dependency per line; always include the category (e.g. `dev-libs/openssl`, not `openssl`)
- Do not depend on meta-packages (e.g. `gnome-base/gnome`); depend on specific libraries

### Calling pkg-config
Never call `pkg-config` directly. Use `tc-getPKG_CONFIG` from `toolchain-funcs` eclass:
```bash
inherit toolchain-funcs
# in phase function:
$(tc-getPKG_CONFIG) --cflags foo
```
Add `virtual/pkgconfig` to `BDEPEND`.

### Error handling
- All external commands need `|| die "message"` unless the helper dies automatically
- `emake`, `eapply`, `dobin`, `dosbin`, `insinto`, `doins`, `dodoc`, etc. die automatically
- `die` works in subshells from EAPI 7+ (EAPI 8 is fine)
- For pipes, use `assert` after the pipeline or restructure to avoid subshells

### Phase functions
- `src_prepare`: always call `default` (applies patches from `files/`)
- `src_compile`: use `emake`; never call bare `make`
- `src_install`:
  - `dosbin` → `/usr/sbin/`
  - `dobin` → `/usr/bin/`
  - `insinto /path && doins file` → arbitrary destinations
  - `dodoc` for documentation files; no need to install `COPYING` (license is in `licenses/`)
  - Default `src_install` (EAPI 6+) runs `emake DESTDIR="${D}" install` and `einstalldocs`; only define it when needed

### Common mistakes to avoid
- Do not use `static` USE flag for static libraries — use `static-libs`
- Do not use `ROOT` in `src_*` phases — only in `pkg_*` phases
- Do not reference full compressed doc paths in messages (file may be compressed)
- Strip `-Werror` from build systems (causes random failures on version bumps)
- Remove unused USE flags and eclass inherits
- Build log must be verbose — pass `V=1` or `--disable-silent-rules` as appropriate

### Manifest
- `thin-manifests = true` is set — only `DIST` entries are needed (no `EBUILD`/`AUX` lines)
- Regenerate with: `ebuild <path>.ebuild manifest`
- Contains `BLAKE2B` and `SHA512` hashes

### Files directory
- Patches and small files go in `<category>/<package>/files/`
- Max size: 20 KiB per file
- Name patches with version: `<package>-<version>-<description>.patch`
- Do not compress patches

## When Writing Eclasses

- Document with `@ECLASS:`, `@MAINTAINER:`, `@BLURB:` comment blocks
- Guard with inherit guard: `if [[ -z ${_FOO_ECLASS} ]]; then _FOO_ECLASS=1 ... fi`
- Place `EXPORT_FUNCTIONS` outside and after the inherit guard, at the very end
- Prefix exported phase functions: `foo_src_compile()` exported via `EXPORT_FUNCTIONS src_compile`
- Do not set `KEYWORDS` in an eclass

## When Blocked

- If `pkgcheck` reports errors you cannot resolve: stop and report the full output
- If Manifest generation fails (no network access): compute hashes manually with `sha512sum` and `b2sum`, write `DIST` lines by hand
- Never: force-push, skip pkgcheck, commit a broken Manifest

## References

- Ebuild writing guide: https://devmanual.gentoo.org/ebuild-writing/index.html
- Ebuild maintenance guide: https://devmanual.gentoo.org/ebuild-maintenance/index.html
- Eclass writing guide: https://devmanual.gentoo.org/eclass-writing/index.html
- Dependencies: https://devmanual.gentoo.org/general-concepts/dependencies/index.html
- Variables: https://devmanual.gentoo.org/ebuild-writing/variables/index.html
- Common mistakes: https://devmanual.gentoo.org/ebuild-writing/common-mistakes/index.html
- eselect/repository: https://wiki.gentoo.org/wiki/Eselect/Repository
