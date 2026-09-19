# Workflow and keymaps

Reference for day-to-day use. `<leader>` is Space.

**The rule of thumb:** built-in keys are preferred; a custom key exists only when
there is no built-in or the action is frequent. Custom keys are grouped by area,
and every one of them has a description, so **`<leader>sk` searches all keymaps**
(type "hunk", "definition", "Run:" …).

---

## The four feedback loops

| Loop | When | Scope | Where the result shows |
|---|---|---|---|
| LSP diagnostics | as you type | the file | inline; list with `<leader>sd` |
| nvim-lint | on save (Go), also on `BufEnter`/`InsertLeave` (others) | the file | same list |
| `:make` | when you ask | the whole project | quickfix: `:copen`, `]q` / `[q` |
| `:Run` / `<leader>r` | when you ask | one file | a terminal split you read yourself |

`<leader>r` answers "what does this program print?"; `:make` answers "what is
broken, and where?".

### `:make` per language (set by `after/ftplugin/<ft>.lua`)

| Filetype | `:make` runs | Catches |
|---|---|---|
| go | `go build` | compile errors in the module |
| python | `ruff check` | ruff findings in the project |
| c | `gcc -Wall -Wextra -o %:r %` | compile errors and warnings |
| sh | `bash -n %` | syntax errors in the file |

### Quickfix list (one list, many sources)

| Key / command | Does |
|---|---|
| `:make` / `:make!` | run the build; `!` stays put instead of jumping |
| `:copen` / `:cclose` | open / close the list |
| `]q` `[q` | next / previous entry (built-in) |
| `]Q` `[Q` | last / first entry |
| `:colder` / `:cnewer` | previous / next list (the last 10 are kept) |
| `:cdo {cmd} \| update` | run a command on every entry, e.g. `:cdo s/old/new/g \| update` |
| `<C-q>` inside any telescope picker | send all results to quickfix (`<M-q>`: only selected) |
| `<leader>hq` / `<leader>hQ` | git hunks of this buffer / all buffers |

---

## Search the project — `<leader>s` and friends

| Key | Does |
|---|---|
| `<C-p>` | project files (git files in a repo) |
| `<M-p>` | files in this file's directory, ignored ones included |
| `<C-f>` | live grep across the project |
| `<C-b>` | open buffers (`<C-d>` in the picker deletes one) |
| `<C-/>` | fuzzy search inside this buffer |
| `<leader>sf` | all files, ignored ones included |
| `<leader>sw` | grep the word under the cursor |
| `<leader>ss` | grep a regex you type |
| `<leader>sh` | help tags |
| `<leader>sk` | **all keymaps** |
| `<leader>sd` | diagnostics (whole project, not just this file) |
| `<leader>sy` | symbols in the project |
| `<leader>sr` | resume the last picker |
| `<leader>ft` | set this buffer's filetype |

The project root is the git root, else the nearest `go.mod`/`pyproject.toml`/…,
else the file's folder. In oil, the folder you are browsing.

## LSP — `gr` + a letter acts on what is under the cursor

| Key | Does |
|---|---|
| `grd` | definition |
| `grr` | references |
| `gri` | implementations |
| `grt` | type definition |
| `grs` (or `gO`) | symbols in this file |
| `grn` | rename |
| `gra` | code action |
| `grx` | run the codelens on this line (Go only; nothing shows until run) |
| `K` | hover documentation |
| `<C-s>` (insert) | signature help |

All the jump keys open a telescope picker, and jump straight there when there is
only one result. Definition, type definition and implementation differ like this:
definition = "where is this written", type definition = "what type is this
thing", implementation = "who actually implements this interface/protocol".

Also built in: `<C-]>` definition (tags via LSP), `<C-t>` jump back, `<C-w>]`
definition in a split, `<C-o>` / `<Tab>` older / newer jump position.

### Diagnostics

| Key | Does |
|---|---|
| `]d` `[d` | next / previous diagnostic |
| `]D` `[D` | last / first |
| `<C-w>d` | show the full message in a float |
| `<leader>sd` | list them all (project-wide) |
| `<leader>li` | lint this file now, without saving |

## Git

| Key | Does |
|---|---|
| `<leader>gs` | fugitive status (stage, commit, everything) |
| `<leader>gb` | open this file on GitHub |
| `:GV` | commit browser |
| `:AiCommit` | in a commit buffer: generate the message |

### Hunks — `<leader>h`, in files inside a repo

| Key | Does |
|---|---|
| `]h` `[h` | next / previous hunk |
| `]H` `[H` | last / first hunk |
| `<leader>hp` | preview the hunk in a float |
| `<leader>hi` | preview it inline |
| `<leader>hb` | blame this line (full) |
| `<leader>hd` | diff this file against the index |
| `<leader>hq` `<leader>hQ` | hunks → quickfix (this buffer / all) |
| `<leader>hs` `<leader>hr` | stage / reset the hunk (visual: the selected lines) |
| `<leader>hS` `<leader>hR` | stage / reset the whole buffer |
| `<leader>hB` | toggle blame text on the current line |
| `<leader>hw` | toggle word-level diff highlighting |
| `ih` / `ah` | hunk textobject (`vih`, `dah`) |
| `]c` `[c` | inside a diff: next / previous change (classes elsewhere) |

## Run, test

| Key | Does |
|---|---|
| `<leader>r` | run this file (`:Run`; Go, Python, C, JS/TS, Lua; `.http`: the request) |
| `<leader>tt` | Go: test the package |
| `<leader>tm` | Go: test with a main file |

## Debug (nvim-dap + nvim-dap-ui; debugpy for Python, Delve for Go)

| Key | Does |
|---|---|
| `F5` | start / continue (asks which configuration on first start, e.g. "file" or "Debug") |
| `F10` / `F11` / `F12` | step over / into / out |
| `<leader>db` | toggle breakpoint (red dot) |
| `<leader>dB` | conditional breakpoint (asks for the condition) |
| `<leader>dc` | run to the cursor |
| `<leader>dl` | re-run the last session |
| `<leader>dq` | quit (terminate) the session |
| `<leader>du` | toggle the debug UI (it opens and closes with the session by itself) |
| `<leader>de` | evaluate the expression under the cursor, or the selection |
| `<leader>dt` | Python / Go: debug the test under the cursor |
| `<leader>dT` | Python: the same, stepping into library code too |

The program runs with the project's Python (`$VIRTUAL_ENV`, else `.venv`/`venv`
in the project); debugpy itself lives in Mason. Go needs a module (`go.mod`).

**Stepping into library code.** Python's debugger skips code that isn't yours
by default ("just my code"). To follow a call into a library, start with `F5` and
pick a configuration ending in **(library code too)**, e.g. "file (library code
too)", or use `<leader>dT` for a test. Go has no such switch: Delve already steps
into the standard library and dependencies.

## Move around the code

| Key | Does |
|---|---|
| `]f` `[f` | next / previous function |
| `]c` `[c` | next / previous class |
| `]p` `[p` | next / previous parameter |
| `]b` `[b` | next / previous block |
| `]r` `[r` | next / previous HTTP request (`###` line) |
| `;` `,` | repeat the last of those jumps, same / opposite direction |
| `f` `F` `t` `T` | find / till a character (built-in behaviour; `;` `,` repeat them) |
| `<C-Space>` | select the syntax node under the cursor; again grows, `<C-BS>` shrinks |
| `n` `N`, `<C-d>` `<C-u>` | search results and half-page scroll, kept centred |

### Textobjects (after `v`, `d`, `c`, `y`)

`am`/`im` method · `af`/`if` function call · `ac`/`ic` class · `aa`/`ia` argument
· `ai`/`ii` if · `al`/`il` loop · `ab`/`ib` block · `a=`/`i=` assignment (`l=`
left side, `r=` right side) · `ad` comment · `ar`/`ir` HTTP request · `ih`/`ah`
git hunk.

`<leader>a` / `<leader>A` swap the argument under the cursor with the next / previous one.

## Editing, windows, files

| Key | Does |
|---|---|
| `-` | open the parent directory (oil) |
| `<C-\>` | toggle the floating terminal (`<Esc>` leaves terminal mode) |
| `<leader>u` | undo tree |
| `<leader>D` | database UI |
| `<leader>ev` | edit this config in a new tab |
| `<leader>cd` | change this window's directory to the file's folder |
| `J` | join lines, cursor stays |
| visual `J` / `K` | move the selection down / up |
| visual `<leader>p` | paste over the selection, keep the register |
| visual `<leader>s` | sort the selection |
| visual `<C-y>` | yank to the system clipboard |
| `<C-x><C-m>` / `<C-x><C-w>` (insert) | whole-line completion from the buffer / project |
| `z=` | spelling suggestions |
| `gc` | comment (built-in; `gcc` a line, `gc` a motion or selection) |

**Built-ins used instead of custom keys:** `<C-w>s` / `<C-w>v` split, `<C-w>c`
close, `:tabnew` / `:tabclose`, `gt` / `gT` (and `2gt`) switch tabs, `gi` resume
insert where you last stopped, `gd` / `gD` Vim's own local/global declaration
search, `.` repeat the last change, `gx` open the link under the cursor.

---

## Adding a language

`after/ftplugin/<ft>.lua` (runner via `require("config.runner").setup(...)`,
`:compiler`, formatoptions) · server in `lua/plugins/lsp/init.lua` plus
`after/lsp/<server>.lua` · parser in `lua/plugins/treeshitter.lua` · save
behaviour in `lua/plugins/lsp/autocmds.lua` · linter in `lua/plugins/lint.lua` ·
a case in `tests/specs/languages.lua`, then `tests/run.sh`.
