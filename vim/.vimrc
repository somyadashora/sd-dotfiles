
" ============================================================================
" .vimrc — plugin-free vim, tuned for large logs and run dirs
"
" The companion to this repo's Neovim config, NOT a copy of it. nvim is the
" editor; this is the thing you reach for when you have to open a 2 GB
" simulation log on a machine you don't control. Deliberately:
"   * ZERO plugins, zero managers, zero network — one self-contained file.
"     Nothing to install, nothing to update, nothing to break on a locked-down
"     box. Startup stays in the tens of milliseconds.
"   * vim 8.0+ as the floor, with has() guards so nothing errors on older vim.
"   * Muscle memory shared with the nvim config where it's free to do so:
"     <Space> leader, jk to escape, <leader>s* splits, <leader>T* tabs, ]q/[q
"     quickfix, <C-hjkl> window moves.
"
" Install: symlinked to ~/.vimrc by this repo's install.sh.
"
" ----------------------------------------------------------------------------
" VIM CHEATSHEET                                    (`vim-cs`, or :VimCS in vim)
"
"   LOGS
"   ]e  [e        next / prev error       (counter: "Error 3 of 12")
"   ]w  [w        next / prev warning
"   <leader>le    quickfix ALL errors + warnings in this file
"   <leader>lf    follow/tail toggle — reload on change, stick to the end
"   <leader>lh    toggle log highlighting
"   <leader>lb    force big-file mode on this buffer (syntax/undo off)
"   <leader>lt    show timestamp deltas between this line and the last
"
"   RUN DIRS
"   <leader>e     file explorer (netrw tree)
"   <leader>fg    grep the tree (rg if present, else grep) then ]q / [q
"   <leader>fw    grep the word under the cursor
"   <leader>ff    :find (path includes **)
"   gf   gF       open file under cursor / at its line:col
"   <leader>gf    smart open: file:12, file(12), "file", line 12
"
"   MOVEMENT & EDIT
"   jk            leave insert mode          <leader>nh   clear search hl
"   <C-h/j/k/l>   move between windows       <leader>w    write
"   <leader>sv/sh split vert / horiz         <leader>q    quit
"   <leader>se/sx equalise / close split     <leader>y    yank to OSC-52
"   <leader>To/Tx/Tn/Tp   tab open/close/next/prev
"   ]q  [q  ]Q  [Q        quickfix next/prev/last/first
"   <leader>ub    toggle background dark/light
"   <leader>un    toggle relative numbers    <leader>uw   toggle wrap
" ----------------------------------------------------------------------------
" ============================================================================

if !has('eval')
  " vim-tiny / plain vi: nothing below would parse. Bail out quietly so the
  " editor still starts instead of spraying errors on every launch.
  finish
endif

set nocompatible
let s:vimrc = expand('<sfile>:p')

" ============================================================================
" Performance — the reason this file exists
" ============================================================================

" Long log lines are the #1 way to make vim crawl: syntax highlighting is
" O(line length) per redraw. Stop highlighting past a sane column.
set synmaxcol=300

set lazyredraw            " don't redraw mid-macro/mid-register-replay
set ttyfast               " assume a fast terminal (batch-sends redraws)
set updatetime=300
set timeout timeoutlen=500 ttimeoutlen=10   " no Esc lag in the terminal
set history=1000
set maxmempattern=20000   " huge single-line logs blow the default regex budget

" Folding by syntax means parsing the whole buffer; manual folding costs
" nothing until you ask for it.
set foldmethod=manual
set nofoldenable

" Cap what gets carried between sessions — a fat viminfo is startup latency.
if has('viminfo')
  set viminfo='100,<50,s10,h
endif

" ============================================================================
" General options  (mirrors nvim/lua/somya/core/options.lua where it makes sense)
" ============================================================================

set number relativenumber
set numberwidth=3
set cursorline
set scrolloff=5 sidescrolloff=20
set nowrap                " logs are column data; wrapping destroys alignment
set signcolumn=no

set tabstop=2 shiftwidth=2 expandtab autoindent
set backspace=indent,eol,start
set nrformats-=octal      " 007 increments to 008, not 010

set ignorecase smartcase incsearch hlsearch
set wildmenu wildmode=longest:full,full
set wildignorecase
set splitright splitbelow
set hidden                " switch away from a modified buffer without ceremony
set confirm
set report=0              " always say how many lines changed
set shortmess+=I          " no intro screen
set laststatus=2
set ruler
set display=truncate
set encoding=utf-8
set fileformats=unix,dos
set fileencodings=utf-8,latin1   " a log with one stray byte must still open

" Mouse stays OFF on purpose. With mouse=a, drag-selecting text in the
" terminal starts a vim visual selection instead of a terminal selection —
" which breaks the most common way to copy a few log lines over ssh.
set mouse=

" Where scratch state lives. Kept out of the run dir so a `rm -rf` of a
" simulation directory never takes your undo history with it.
if !isdirectory($HOME . '/.vim/swap')   | call mkdir($HOME . '/.vim/swap', 'p', 0700)   | endif
if !isdirectory($HOME . '/.vim/backup') | call mkdir($HOME . '/.vim/backup', 'p', 0700) | endif
set directory=~/.vim/swap//
set backupdir=~/.vim/backup//
if has('persistent_undo')
  if !isdirectory($HOME . '/.vim/undo') | call mkdir($HOME . '/.vim/undo', 'p', 0700) | endif
  set undodir=~/.vim/undo//
  set undofile
  set undolevels=1000
endif

filetype plugin indent on
syntax enable

" ============================================================================
" Colours
" ============================================================================

set background=dark

" True colour when the terminal can take it. Inside tmux/screen vim needs to be
" told the escape sequences explicitly or it silently sends nothing.
if has('termguicolors') && $COLORTERM =~# '\v^(truecolor|24bit)$'
  if &term =~# '\v^(tmux|screen)'
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  endif
  set termguicolors
endif

silent! colorscheme habamax   " ships with vim 8.2+; harmless failure on older
if !exists('g:colors_name')
  silent! colorscheme desert
endif

" The repo accent set — the same saturated Monokai colours the nvim config
" forces onto every scheme for diagnostics and git signs, so an error looks
" like an error in both editors.
let s:red    = '#ff6188' | let s:c_red    = 204
let s:amber  = '#ffd866' | let s:c_amber  = 221
let s:cyan   = '#78dce8' | let s:c_cyan   = 117
let s:green  = '#a9dc76' | let s:c_green  = 150
let s:mauve  = '#cba6f7' | let s:c_mauve  = 183
let s:muted  = '#6c7086' | let s:c_muted  = 243

function! s:Hl(group, fg, cterm, attr) abort
  execute 'highlight' a:group
        \ 'guifg=' . a:fg 'ctermfg=' . a:cterm
        \ 'gui=' . a:attr 'cterm=' . a:attr
endfunction

function! s:LogColors() abort
  call s:Hl('SdLogError', s:red,   s:c_red,   'bold')
  call s:Hl('SdLogWarn',  s:amber, s:c_amber, 'NONE')
  call s:Hl('SdLogInfo',  s:cyan,  s:c_cyan,  'NONE')
  call s:Hl('SdLogPass',  s:green, s:c_green, 'bold')
  call s:Hl('SdLogPath',  s:mauve, s:c_mauve, 'underline')
  call s:Hl('SdLogTime',  s:muted, s:c_muted, 'NONE')
endfunction
call s:LogColors()
autocmd ColorScheme * call s:LogColors()

" ============================================================================
" Statusline — one line, no plugin, cheap to redraw
" ============================================================================

function! SdMode() abort
  let l:m = mode()
  return l:m ==# 'n' ? 'NORMAL' : l:m ==# 'i' ? 'INSERT'
        \ : l:m ==# 'R' ? 'REPLACE' : l:m =~# '\v^(v|V|)' ? 'VISUAL'
        \ : l:m ==# 'c' ? 'COMMAND' : l:m ==# 't' ? 'TERM' : toupper(l:m)
endfunction

" Flags for the modes this config can put a buffer into, so you can always see
" why syntax is off or why the view keeps jumping to the end.
function! SdFlags() abort
  let l:f = ''
  if get(b:, 'sd_bigfile', 0)      | let l:f .= ' [BIG]'    | endif
  if exists('b:sd_follow_timer')   | let l:f .= ' [FOLLOW]' | endif
  return l:f
endfunction

set statusline=
set statusline+=\ %{SdMode()}\ 
set statusline+=\ %f%m%r%h%w
set statusline+=%{SdFlags()}
set statusline+=%=
set statusline+=\ %{&filetype==#''?'--':&filetype}
set statusline+=\ \ ln\ %l/%L\ (%p%%)\ col\ %v\ 

" ============================================================================
" Keymaps
" ============================================================================

let mapleader = ' '
nnoremap <Space> <Nop>

inoremap jk <Esc>

nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader>nh :nohlsearch<CR>

" Windows / splits / tabs — same mnemonics as the nvim config
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <leader>sv <C-w>v
nnoremap <leader>sh <C-w>s
nnoremap <leader>se <C-w>=
nnoremap <leader>sx :close<CR>
nnoremap <leader>To :tabnew<CR>
nnoremap <leader>Tx :tabclose<CR>
nnoremap <leader>Tn :tabnext<CR>
nnoremap <leader>Tp :tabprevious<CR>

" Quickfix
nnoremap ]q :cnext<CR>
nnoremap [q :cprevious<CR>
nnoremap ]Q :clast<CR>
nnoremap [Q :cfirst<CR>
nnoremap <leader>qo :copen<CR>
nnoremap <leader>qc :cclose<CR>

" Keep the cursor put while joining, and centre the view on search results —
" on a 100k-line log a match at the screen edge tells you nothing.
nnoremap J mzJ`z
nnoremap n nzzzv
nnoremap N Nzzzv

" Move visual selections (nvim config's x-mode J/K)
xnoremap J :move '>+1<CR>gv=gv
xnoremap K :move '<-2<CR>gv=gv

" UI toggles, under the same <leader>u prefix the nvim config uses
nnoremap <leader>uw :setlocal wrap!<CR>:setlocal wrap?<CR>
nnoremap <leader>un :setlocal relativenumber!<CR>
nnoremap <leader>ub :let &background = (&background ==# 'dark' ? 'light' : 'dark')<CR>

" ============================================================================
" Big-file mode
" ============================================================================
"
" Everything that makes vim pleasant on a source file — syntax, undo, swap,
" relative numbers, cursorline — is O(file size) and turns a multi-GB log into
" a hang. Detect size BEFORE the read and strip all of it. Override the
" threshold in ~/.vimrc.local, or force it per buffer with <leader>lb.

let g:sd_bigfile_mb = get(g:, 'sd_bigfile_mb', 10)

function! s:BigFileOn(announce) abort
  let b:sd_bigfile = 1
  setlocal noswapfile noundofile nobackup nowritebackup
  setlocal undolevels=-1
  setlocal bufhidden=unload
  setlocal norelativenumber nocursorline nolist
  setlocal foldmethod=manual nofoldenable
  setlocal syntax=off
  setlocal textwidth=0
  if a:announce
    echohl WarningMsg
    echomsg printf('Big file (%s) — syntax/undo/swap off. :set syntax=on to override.',
          \ s:HumanSize(getfsize(expand('%'))))
    echohl None
  endif
endfunction

function! s:HumanSize(bytes) abort
  if a:bytes < 0 | return '?' | endif
  if a:bytes >= 1073741824 | return printf('%.1f GB', a:bytes / 1073741824.0) | endif
  if a:bytes >= 1048576    | return printf('%.0f MB', a:bytes / 1048576.0)    | endif
  return printf('%.0f KB', a:bytes / 1024.0)
endfunction

augroup SdBigFile
  autocmd!
  " BufReadPre: the size is known but nothing has been parsed yet, so the
  " expensive options never get a chance to apply.
  autocmd BufReadPre * if getfsize(expand('<afile>')) > g:sd_bigfile_mb * 1048576
        \ | let b:sd_bigfile_pending = 1 | endif
  autocmd BufReadPost * if get(b:, 'sd_bigfile_pending', 0)
        \ | unlet b:sd_bigfile_pending | call s:BigFileOn(1) | endif
augroup END

nnoremap <leader>lb :call <SID>BigFileOn(0)<CR>:echo 'Big-file mode: on'<CR>

" ============================================================================
" Log highlighting
" ============================================================================
"
" Uses matchadd(), NOT a syntax file, for two reasons: it keeps working when
" big-file mode has turned syntax off, and it only costs anything for lines
" actually on screen. Priorities are negative so 'hlsearch' (priority 0) still
" paints over them — searching is what you came here to do.
"
" Patterns cover the tool output that actually shows up in a run dir: UVM,
" VCS (Error-[TAG]), Xcelium (*E,TAG), Questa (** Error:), and plain words.

" Two representations of the same idea, on purpose.
"
" The COMBINED regexes below are for matchadd() only. matchadd evaluates its
" pattern against the lines currently on screen, so a rich alternation costs
" nothing there and buys precision in the colouring.
"
" The PATTERN LISTS further down are for searching and counting, which touch
" every line in the buffer. Measured on this vim against a 400k-line, 34 MB
" log: one combined alternation costs ~74us per line, while the same set as
" separate alternation-free patterns costs ~1.7us per line — vim can only use
" its fast literal search path when a pattern has no top-level alternation.
" That is 3.7s versus 0.05s for a single ]e. Hence the split; keep it.

let s:log_error = '\v\c(<(error|fatal|fail(ed|ure)?|abort(ed)?|timeout)>|\*\*\s*error|\*E[,:]|<UVM_(ERROR|FATAL)>|<(Error|Fatal)-\[|segmentation fault|core dumped)'
let s:log_warn  = '\v\c(<warn(ing)?>|\*\*\s*warning|\*W[,:]|<UVM_WARNING>|<Warning-\[)'
let s:log_info  = '\v\c(<(info|note|notice)>|\*\*\s*note|\*N[,:]|<UVM_INFO>)'
let s:log_pass  = '\v\c(<(pass(ed)?|success(ful)?|clean)>|TEST PASSED|<0 errors>)'
let s:log_time  = '\v(\d+(\.\d+)?\s*(fs|ps|ns|us|ms)>|\d{2}:\d{2}:\d{2})'
let s:log_path  = '\v<[[:alnum:]_./+-]+\.(sv|svh|v|vh|vhd|c|cpp|h|hpp|py|pl|tcl|f|do|log|rpt)(:\d+)?'

" Search/count patterns. Each one is alternation-free. \<error\> deliberately
" does NOT match UVM_ERROR (an underscore is a word character), so the UVM
" markers are listed separately rather than loosening the boundary — that is
" also what keeps a "0 errors" summary line from being reported as an error.
" Add site-specific markers by setting these in ~/.vimrc.local.
let g:sd_log_error_pats = get(g:, 'sd_log_error_pats',
      \ ['\c\<error\>', '\cUVM_[EF]', '\c\<fatal\>', '\c\*E[,:]', '\c\<fail'])
let g:sd_log_warn_pats = get(g:, 'sd_log_warn_pats',
      \ ['\c\<warn', '\cUVM_WARNING', '\c\*W[,:]'])

function! s:LogHlOn() abort
  if get(w:, 'sd_log_hl', 0) | return | endif
  let w:sd_log_hl = 1
  let w:sd_log_ids = []
  for [l:grp, l:pat, l:pri] in [
        \ ['SdLogError', s:log_error, -1], ['SdLogWarn', s:log_warn, -2],
        \ ['SdLogPass',  s:log_pass,  -3], ['SdLogInfo', s:log_info, -4],
        \ ['SdLogPath',  s:log_path,  -5], ['SdLogTime', s:log_time, -6]]
    call add(w:sd_log_ids, matchadd(l:grp, l:pat, l:pri))
  endfor
endfunction

function! s:LogHlOff() abort
  for l:id in get(w:, 'sd_log_ids', [])
    silent! call matchdelete(l:id)
  endfor
  let w:sd_log_ids = []
  let w:sd_log_hl = 0
endfunction

function! s:LogHlToggle() abort
  if get(w:, 'sd_log_hl', 0)
    call s:LogHlOff() | echo 'Log highlighting: off'
  else
    call s:LogHlOn()  | echo 'Log highlighting: on'
  endif
endfunction

nnoremap <leader>lh :call <SID>LogHlToggle()<CR>

augroup SdLog
  autocmd!
  autocmd BufRead,BufNewFile *.log,*.rpt,*.out,*.err,*.summary,*.trans,*transcript*
        \ setfiletype log
  " matchadd() is window-local, so re-apply whenever the buffer lands in a
  " window (split, tab move, :bnext), not just once at read time.
  autocmd FileType,BufWinEnter * if &filetype ==# 'log' | call s:LogHlOn() | endif
augroup END

" 'BufRead' and 'BufReadPost' are the same event, so big-file mode above and
" the log filetype detection here fire in augroup-definition order: big-file
" turns syntax off, then setfiletype fires FileType, and vim's own syntaxset
" autocmd turns it straight back on. This runs last and has the final word.
augroup SdBigFileSyntax
  autocmd!
  autocmd FileType * if get(b:, 'sd_bigfile', 0) | setlocal syntax=off | endif
augroup END

" ============================================================================
" Error / warning navigation  ("Error 3 of 12")
" ============================================================================
"
" The echoed counter is this repo's navmsg idea ported to vim: say WHAT you
" landed on and WHERE you are in the list. Counting matches means scanning the
" buffer, which is exactly what you can't afford on a giant log — so above
" g:sd_log_count_max lines the label is printed without an index rather than
" made up. Same rule as the nvim side: a miss stays silent, never wrong.

let g:sd_log_count_max = get(g:, 'sd_log_count_max', 20000)
let g:sd_log_window = get(g:, 'sd_log_window', 5000)

function! s:CountMatches(pats, upto) abort
  " a:upto of 0 means "whole buffer". One filter() pass over the line list with
  " an OR of the simple patterns; still O(lines), which is why the caller only
  " asks below g:sd_log_count_max.
  let l:last = a:upto > 0 ? a:upto : line('$')
  let l:expr = join(map(copy(a:pats), '"v:val =~# " . string(v:val)'), ' || ')
  return len(filter(getline(1, l:last), l:expr))
endfunction

" Scan every pattern once, keeping the closest hit. Each search is bounded by
" the best candidate so far — anything further away cannot win, so patterns
" after the first only scan a shrinking window.
function! s:ScanPats(pats, back, limit) abort
  " Try whichever pattern won last time in this buffer FIRST. A pattern that
  " matches nothing has to scan to the end of the buffer before it can say so,
  " and the bound above only helps patterns that come after a hit — so putting
  " a known-good marker first is what keeps the second and subsequent jumps
  " cheap. One log's markers are overwhelmingly all of the same kind, which is
  " exactly when this pays.
  let l:pats = copy(a:pats)
  let l:pref = get(b:, 'sd_log_pref', '')
  let l:at = index(l:pats, l:pref)
  if l:at > 0
    call insert(l:pats, remove(l:pats, l:at))
  endif

  let l:best = 0
  let l:best_pat = ''
  for l:p in l:pats
    let l:stop = l:best > 0 ? l:best : a:limit
    let l:hit = search(l:p, a:back ? 'bnW' : 'nW', l:stop)
    if l:hit > 0 && (l:best == 0 || (a:back ? l:hit > l:best : l:hit < l:best))
      let l:best = l:hit
      let l:best_pat = l:p
    endif
  endfor
  if !empty(l:best_pat)
    let b:sd_log_pref = l:best_pat
  endif
  return l:best
endfunction

" Nearest line matching ANY of a:pats, without moving the cursor.
"
" Two phases, because the expensive case is a pattern that matches NOWHERE: it
" scans to the end of the buffer before admitting defeat, once per pattern.
" Phase one looks only at a nearby window, which is where the answer almost
" always is and costs ~50ms on a 34 MB log; phase two falls back to the whole
" buffer only when that window really is empty.
function! s:NearestMatch(pats, back) abort
  let l:near = a:back ? max([1, line('.') - g:sd_log_window])
        \ : min([line('$'), line('.') + g:sd_log_window])
  let l:hit = s:ScanPats(a:pats, a:back, l:near)
  return l:hit > 0 ? l:hit : s:ScanPats(a:pats, a:back, 0)
endfunction

function! s:LogNav(pats, label, group, back) abort
  let l:target = 0
  for l:i in range(v:count1)
    " Move to the far edge of the current line first, so the scan is strictly
    " line-to-line. Without this, landing at column 1 on a line whose marker
    " sits further right makes the next ]e re-find the SAME line forever.
    call cursor(line('.'), a:back ? 1 : col('$'))
    let l:hit = s:NearestMatch(a:pats, a:back)
    if !l:hit | break | endif
    call cursor(l:hit, 1)
    let l:target = l:hit
  endfor
  if !l:target
    echohl WarningMsg
    echo 'No ' . tolower(a:label) . ' ' . (a:back ? 'above' : 'below')
    echohl None
    return
  endif
  normal! zz
  " Counting means scanning the buffer, which is exactly what you cannot afford
  " on a giant log — so past the threshold print the label with no index rather
  " than inventing one. Same rule as the nvim config's navmsg: a number we
  " cannot compute is omitted, never guessed.
  if line('$') > g:sd_log_count_max
    execute 'echohl ' . a:group
    echo a:label
    echohl None
    return
  endif
  let l:total = s:CountMatches(a:pats, 0)
  let l:index = s:CountMatches(a:pats, line('.'))
  execute 'echohl ' . a:group
  echo printf('%s %d of %d', a:label, l:index, l:total)
  echohl None
endfunction

nnoremap <silent> ]e :<C-u>call <SID>LogNav(g:sd_log_error_pats, 'Error', 'SdLogError', 0)<CR>
nnoremap <silent> [e :<C-u>call <SID>LogNav(g:sd_log_error_pats, 'Error', 'SdLogError', 1)<CR>
nnoremap <silent> ]w :<C-u>call <SID>LogNav(g:sd_log_warn_pats, 'Warning', 'SdLogWarn', 0)<CR>
nnoremap <silent> [w :<C-u>call <SID>LogNav(g:sd_log_warn_pats, 'Warning', 'SdLogWarn', 1)<CR>

" Collect every error and warning in the buffer into the quickfix list.
function! s:LogQf() abort
  " getline(1,'$') materialises the whole buffer as a List — fine for a normal
  " log, ruinous for a multi-GB one. Past the threshold, hand the job to the
  " external grepper, which streams instead.
  if line('$') > g:sd_log_count_max
    if &grepprg =~# '^rg'
      echo 'Large file — grepping externally...'
      execute 'silent grep! -e ' . shellescape('(?i)(error|fatal|warn|UVM_(ERROR|FATAL|WARNING))')
            \ . ' -- ' . shellescape(expand('%:p'))
      copen
      return
    endif
    echohl WarningMsg
    echo 'File too large to scan in-process; raise g:sd_log_count_max or install rg'
    echohl None
    return
  endif
  " Build one OR expression per severity so quickfix agrees exactly with what
  " ]e / ]w visit — a list that disagrees with the jumps is worse than none.
  let l:e_expr = join(map(copy(g:sd_log_error_pats), '"l:line =~# " . string(v:val)'), ' || ')
  let l:w_expr = join(map(copy(g:sd_log_warn_pats),  '"l:line =~# " . string(v:val)'), ' || ')
  let l:items = []
  let l:lnum = 0
  for l:line in getline(1, '$')
    let l:lnum += 1
    if eval(l:e_expr)
      call add(l:items, {'bufnr': bufnr('%'), 'lnum': l:lnum, 'type': 'E', 'text': l:line})
    elseif eval(l:w_expr)
      call add(l:items, {'bufnr': bufnr('%'), 'lnum': l:lnum, 'type': 'W', 'text': l:line})
    endif
  endfor
  if empty(l:items)
    echo 'No errors or warnings found' | return
  endif
  call setqflist(l:items, 'r')
  copen
  echo printf('%d errors/warnings', len(l:items))
endfunction

nnoremap <leader>le :call <SID>LogQf()<CR>

" Timestamp delta: how long between this log line and the previous stamped one.
" The question you actually ask when a test hangs.
function! s:TimeDelta() abort
  let l:pat = '\v\d+(\.\d+)?\s*(fs|ps|ns|us|ms)'
  let l:here = matchstr(getline('.'), l:pat)
  if empty(l:here) | echo 'No timestamp on this line' | return | endif
  let l:prev_line = search(l:pat, 'bnW')
  if !l:prev_line | echo 'Timestamp: ' . l:here . ' (no earlier stamp)' | return | endif
  let l:prev = matchstr(getline(l:prev_line), l:pat)
  echo printf('%s  <-  %s   (line %d, %+d lines back)',
        \ l:here, l:prev, l:prev_line, l:prev_line - line('.'))
endfunction

nnoremap <leader>lt :call <SID>TimeDelta()<CR>

" ============================================================================
" Follow / tail mode
" ============================================================================
"
" Watch a running simulation without leaving vim: reload on change and keep the
" view pinned to the end. Uses a timer (vim 8.0+) rather than a blocking loop,
" so the editor stays usable while it follows.

function! s:FollowTick(bufnr, timer) abort
  if !bufexists(a:bufnr)
    call timer_stop(a:timer)
    return
  endif
  let l:wins = win_findbuf(a:bufnr)
  if empty(l:wins) | return | endif   " not on screen: nothing to do, keep timer
  silent! checktime
  if exists('*win_execute')
    for l:w in l:wins
      call win_execute(l:w, 'normal! G')
    endfor
  elseif bufnr('%') == a:bufnr
    normal! G
  endif
endfunction

function! s:FollowToggle() abort
  if !has('timers')
    echohl WarningMsg | echo 'Follow needs vim 8.0+ (timers)' | echohl None
    return
  endif
  if exists('b:sd_follow_timer')
    call timer_stop(b:sd_follow_timer)
    unlet b:sd_follow_timer
    echo 'Follow: off'
  else
    setlocal autoread
    let b:sd_follow_timer = timer_start(1000,
          \ function('s:FollowTick', [bufnr('%')]), {'repeat': -1})
    normal! G
    echo 'Follow: on — tailing ' . expand('%:t')
  endif
endfunction

nnoremap <leader>lf :call <SID>FollowToggle()<CR>

" ============================================================================
" Run-dir navigation
" ============================================================================

let g:netrw_liststyle = 3     " tree view, same as the nvim config
let g:netrw_banner = 0
let g:netrw_winsize = 25
nnoremap <leader>e :Lexplore<CR>

" :find searches down the tree. ** can be slow in a run dir with a million
" files — that's a per-invocation cost, not a startup one.
set path=.,,**
set wildignore+=*.o,*.so,*.a,*.pyc,*.vcd,*.fsdb,*.shm,*.vpd,*.wlf

if executable('rg')
  set grepprg=rg\ --vimgrep\ --smart-case\ --no-heading
  set grepformat=%f:%l:%c:%m
elseif executable('grep')
  set grepprg=grep\ -rn\ --exclude-dir=.git\ $*\ .
endif

nnoremap <leader>fg :silent grep! ""<Left>
nnoremap <leader>fw :silent grep! "<C-r><C-w>"<CR>:copen<CR>
nnoremap <leader>ff :find 

" Smart open of a file reference under the cursor. Log lines quote files in
" every shape but the one gf expects, so parse the common ones: path:12,
" path:12:34, path(12), and "path", line 12.
function! s:SmartGf() abort
  let l:line = getline('.')
  let l:file = expand('<cfile>')
  let l:lnum = 0

  let l:m = matchlist(l:line, '\v([[:alnum:]_./+-]+):(\d+)(:(\d+))?')
  if !empty(l:m)
    let l:file = l:m[1] | let l:lnum = str2nr(l:m[2])
  else
    let l:m = matchlist(l:line, '\v([[:alnum:]_./+-]+)\((\d+)\)')
    if !empty(l:m)
      let l:file = l:m[1] | let l:lnum = str2nr(l:m[2])
    else
      let l:m = matchlist(l:line, '\v"([^"]+)",\s*line\s*(\d+)')
      if !empty(l:m)
        let l:file = l:m[1] | let l:lnum = str2nr(l:m[2])
      endif
    endif
  endif

  if empty(l:file) | echo 'No file reference on this line' | return | endif
  let l:found = findfile(l:file)
  if empty(l:found)
    if filereadable(l:file)
      let l:found = l:file
    else
      echohl WarningMsg | echo 'Not found: ' . l:file | echohl None | return
    endif
  endif
  execute 'edit' fnameescape(l:found)
  " NB: ':execute' treats a following '|' as part of its expression, so these
  " must be separate lines — "if x | execute x | normal! zz | endif" silently
  " does the wrong thing.
  if l:lnum > 0
    execute l:lnum
    normal! zz
  endif
endfunction

nnoremap <leader>gf :call <SID>SmartGf()<CR>

" ============================================================================
" Clipboard — OSC 52
" ============================================================================
"
" Most of these machines run a vim built without +clipboard, over ssh, with no
" X forwarding. OSC 52 hands the text to the TERMINAL emulator instead, which
" puts it on the local clipboard — the one place a plain vim can reach it from.
" (This is the vim answer to the nvim config's nvim-clip fallback.)

function! s:Osc52(text) abort
  if !executable('base64')
    echohl WarningMsg | echo 'OSC 52 needs base64 on PATH' | echohl None
    return
  endif
  let l:b64 = substitute(system('base64 | tr -d "\n"', a:text), '\n', '', 'g')
  let l:seq = "\<Esc>]52;c;" . l:b64 . "\<Esc>\\"
  " tmux swallows unknown OSC sequences unless they're wrapped for passthrough.
  if !empty($TMUX)
    let l:seq = "\<Esc>Ptmux;" . substitute(l:seq, "\<Esc>", "\<Esc>\<Esc>", 'g') . "\<Esc>\\"
  endif
  " filewritable() can say yes and the write still fail (no controlling
  " terminal, e.g. vim driven from a script), so guard the write itself.
  try
    call writefile([l:seq], '/dev/tty', 'b')
    echo printf('Copied %d bytes to the system clipboard (OSC 52)', len(a:text))
  catch
    echohl WarningMsg
    echo 'OSC 52: no terminal to write to (' . v:exception . ')'
    echohl None
  endtry
endfunction

nnoremap <leader>y :call <SID>Osc52(getline('.'))<CR>
xnoremap <leader>y y:call <SID>Osc52(@")<CR>

" ============================================================================
" Misc autocommands
" ============================================================================

" Highlight the just-yanked range for 150ms, then remove the match. Window-local
" and self-cleaning, so nothing accumulates.
function! s:YankFlash() abort
  let l:id = matchadd('IncSearch',
        \ '\%>' . (line("'[") - 1) . 'l\%<' . (line("']") + 1) . 'l', -1)
  call timer_start(150, function('s:YankUnflash', [l:id]))
endfunction

function! s:YankUnflash(id, timer) abort
  silent! call matchdelete(a:id)
endfunction

" Reopen a file where you left it — except for commit messages, where the top
" of the buffer is always the right place. A function, not an inline autocmd:
" ':execute' swallows a following '|', so the one-liner form silently breaks.
function! s:RestoreCursor() abort
  if &filetype =~# 'commit' | return | endif
  let l:pos = line("'\"")
  if l:pos >= 1 && l:pos <= line('$')
    execute 'normal! g`"'
  endif
endfunction

augroup SdMisc
  autocmd!
  autocmd QuickFixCmdPost grep,grepadd,vimgrep cwindow
  " Reopen a file where you left it — except for commit messages, where the
  " top of the buffer is always the right place.
  autocmd BufReadPost * call s:RestoreCursor()

  " Flash what you yanked, the way the nvim config's TextYankPost autocmd does.
  " The match MUST be torn down on a timer — matchadd() without a matching
  " matchdelete() leaks one match per yank and every redraw pays for all of them.
  if exists('##TextYankPost') && has('timers')
    autocmd TextYankPost * call s:YankFlash()
  endif

  " Don't drag the number/fold chrome into terminal buffers.
  if has('terminal')
    autocmd TerminalOpen * setlocal nonumber norelativenumber signcolumn=no
  endif
augroup END

" ============================================================================
" Commands
" ============================================================================

" Print the cheatsheet block at the top of this file. Same trick as the repo's
" tmux-cs / fzf-cs / rg-cs aliases, but from inside vim.
function! s:Cheatsheet() abort
  if !filereadable(s:vimrc)
    echohl WarningMsg | echo 'Cannot read ' . s:vimrc | echohl None | return
  endif
  let l:lines = []
  let l:started = 0
  for l:line in readfile(s:vimrc)
    if !l:started
      if l:line =~# 'VIM CHEATSHEET' | let l:started = 1 | endif
      continue
    endif
    " The block ends at the next full-width rule.
    if l:line =~# '^" -\{20,}$' | break | endif
    call add(l:lines, substitute(l:line, '^"\s\?', '', ''))
  endfor

  " A scratch split, not a pile of :echo — thirty lines of echo runs straight
  " into vim's more-prompt, and this way it scrolls and closes with q.
  new
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  setlocal nonumber norelativenumber nowrap
  call setline(1, l:lines)
  setlocal nomodifiable
  execute 'resize' min([len(l:lines) + 1, 25])
  normal! gg
  nnoremap <buffer> <silent> q :close<CR>
  " Colour it with the same groups the logs use, so the help looks like the tool.
  call matchadd('SdLogPass', '^\s*[A-Z][A-Z &/]\+$')
  call matchadd('SdLogPath', '\v^\s+\S+')
  call matchadd('SdLogTime', '\v\(.{-}\)')
  echo 'q to close'
endfunction

command! VimCS call s:Cheatsheet()
command! BigFile call s:BigFileOn(0)
command! Follow call s:FollowToggle()

" ============================================================================
" Machine-local overrides
" ============================================================================
"
" Anything specific to one box — a different big-file threshold, a site colour
" scheme, paths that only exist there — goes in ~/.vimrc.local, which is never
" part of this repo. Same philosophy as the per-machine telekasten vault and
" bookmarks DB in the nvim config.

if filereadable(expand('~/.vimrc.local'))
  source ~/.vimrc.local
endif
