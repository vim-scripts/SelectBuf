"
" selectbuf.vim -- lets you select a buffer visually.
" Author: Hari Krishna <hari_vim@yahoo.com>
" Last Change: 15-Oct-2001 @ 19:27
" Requires: Vim-6.0 or higher, lightWeightArray.vim(1.0.1),
"           bufNwinUtils.vim(1.0.1)
" Version: 2.1.2
"
"  Source this file and press <F3> to get the list of buffers.
"  Move the cursor on to the buffer that you need to select and press <CR> or
"   double click with the left-mouse button.
"  If you want to close the window without making a selection, press <F3> again.
"  You can also press ^W<CR> to open the file in a new window.
"  You can use dd to delete the buffer.
"  For convenience when the browser is opened, the line corresponding to the
"   next buffer is marked with 'a so that you can quickly go to the next buffer.
"
"  You can define your own mapping to activat the browser using the following:
"   nmap <your key sequence here> <Plug>SelectBuf
"  The default is to use <F3>.
"
" To configure the behavior, take a look at the following. You can define the
"  configuration properties in your .vimrc to change the defaults.
" TODO:
"  See FIXME's below.

if exists("loaded_selectbuf")
  finish
endif
let loaded_selectbuf=1

"
" BEGIN configuration.
"

"
" The name of the browser. The default is "---Select Buffer---", but you can
"   change the name at your will.
if !exists("g:selBufWindowName")
  let g:selBufWindowName = '---\ Select\ Buffer\ ---'
endif

"
" A non-zero value for the variable selBufOpenInNewWindow means that the
"   selected buffer should be opened in a separate window. The value zero will
"   open the selected buffer in the current window.
"
if !exists("g:selBufOpenInNewWindow")
  let g:selBufOpenInNewWindow = 0
endif

"
" A non-zero value for the variable selBufRemoveBrowserBuffer means that after
"   the selection is made, the buffer that belongs to the browser should be
"   deleted. But this is not advisable as vim doesn't reuse the buffer numbers
"   that are no longer used. The default value is 0, i.e., reuse a single
"   buffer. This will avoid creating a lot of buffers and quickly reach large
"   buffer numbers for the new buffers created.
if !exists("g:selBufRemoveBrowserBuffer")
  let g:selBufRemoveBrowserBuffer = 0
endif

"
" A non-zero value for the variable selBufHighlightOnlyFilename will highlight
"   only the filename instead of the whole path. The default value is 0.
if !exists("g:selBufHighlightOnlyFilename")
  let g:selBufHighlightOnlyFilename = 0
endif

"
" If help should be shown always.
" The default is to NOT to show help.
"
if exists("g:selBufAlwaysShowHelp")
  let s:showHelp = g:selBufAlwaysShowHelp
else
  let s:showHelp = 0
endif

"
" Should hide the hidden buffers or not.
" The default is to NOT to show hidden buffers.
"
if exists("g:selBufAlwaysShowHidden")
  let s:showHidden = g:selBufAlwaysShowHidden
else
  let s:showHidden = 0
endif

"
" If additional details about the buffers should be shown.
" The default is to NOT to show details.
"
if exists("g:selBufAlwaysShowDetails")
  let s:showDetails = g:selBufAlwaysShowDetails
else
  let s:showDetails = 0
endif

"
" If the lines should be wrapped.
" The default is to NOT to wrap.
"
if exists("g:selBufAlwaysWrapLines")
  let s:wrapLines = g:selBufAlwaysWrapLines
else
  let s:wrapLines = 0
endif

"
" END configuration.
"

"
" Initialize some variables.
"
" To store the buffer from which the browser is invoked.
let s:originalBuffer = 1
" Store the header size.
let s:headerSize = 0


"
" Define a default mapping if the user hasn't defined a map.
"
if !hasmapto('<Plug>SelectBuf')
  nmap <unique> <silent> <F3> <Plug>SelectBuf
endif

"
" Define a command too (easy for debugging).
"
if !exists("SelBuf")
  command! -nargs=0 SelectBuf :call <SID>SelBufListBufs()
endif

" The main plug-in mapping.
nmap <script> <silent> <Plug>SelectBuf :call <SID>SelBufListBufs()<CR>

aug SelectBuf
  au!
  exec "au BufWinEnter " . g:selBufWindowName .
    \ " :call <SID>SelBufUpdateBuffer()"
  exec "au BufWinLeave " . g:selBufWindowName .
    \ " :call <SID>SelBufDone()"
aug END


function! s:SelBufListBufs()
  " First check if there is a browser already running.
  let browserWinNo = FindWindowForBuffer(
          \ substitute(g:selBufWindowName, '\\ ', ' ', "g"), 1)
  if browserWinNo != -1
    " How can I move to this window directly ?
    while 1
        if winnr() == browserWinNo
            break
        endif
        exec "normal! " . "\<C-W>w"
    endwhile
    return
  endif
  call SaveWindowSettings()
  let s:originalBuffer = bufnr("%")
  " For use with the display.
  let s:originalAltBuffer = bufnr("#")
  " A quick hack to restore the search string.
  if histnr("search") != -1
    let s:selBufSavedSearchString = histget("search", -1)
  endif
  split

  " Find if there is a buffer already created.
  let bufNo = FindBufferForName(g:selBufWindowName)
  if bufNo != -1
    " Switch to the existing buffer.
    exec "buffer " . bufNo
  else
    " Create a new buffer.
    exec ":e " . g:selBufWindowName
  endif
  " The remaining is done by the auto-command.
endfunction


function! s:SelBufUpdateBuffer()
  call s:SelBufSetupBuf()
  let savedReport = &report
  let &report = 10000
  set modifiable
  " Delete the contents (if any) first.
  0,$d

  let helpMsg=""
  if s:showHelp
    let helpMsg = helpMsg
      \ . "\" <Enter> or Left-double-click : open current buffer\n"
      \ . "\" <C-W><Enter> : open buffer in a new window\n"
      \ . "\" d : delete current buffer\t\tD : wipeout current buffer\n"
      \ . "\" i : toggle additional details\t\tp : toggle line wrapping\n"
      \ . "\" r : refresh browser\t\t\tu : toggle hidden buffers\n"
      \ . "\" q or <F3> : close browser\n"
      \ . "\" Next, Previous & Current buffers are marked 'a', 'b' & 'c' "
        \ . "respectively\n"
      \ . "\" Press ? to hide help\n"
  else
    let helpMsg = helpMsg
      \ . "\" Press ? to show help\n"
  endif
  let helpMsg = helpMsg . "Buffer\t\tFile"
  put! =helpMsg
  $
  $d " Excess empty line.
  $
  normal! mt

  let s:headerSize = line("$")

  " Loop over all the buffers.
  let i = 1
  let myBufNr = FindBufferForName(g:selBufWindowName)
  while i <= bufnr("$")
    let newLine = ""
    let showBuffer = 0
    if s:showHidden && bufexists(i)
      let showBuffer = 1
    elseif ! s:showHidden && buflisted(i)
      let showBuffer = 1
    endif

    if showBuffer
      let newLine = newLine . i . "\t"
      " If user wants to see more details.
      if s:showDetails
        if !buflisted(i)
          let newLine = newLine . "u"
        else
          let newLine = newLine . " "
        endif

        " Bluff a little bit here about the current and alternate buffers.
        "  Not accurate though.
        if s:originalBuffer == i
          let newLine = newLine . "%"
        elseif s:originalAltBuffer == i
          let newLine = newLine . "#"
        else
          let newLine = newLine . " "
        endif

        if bufloaded(i)
          if bufwinnr(i) != -1
            " Active buffer.
            let newLine = newLine . "a"
          else
            let newLine = newLine . "h"
          endif
        else
          let newLine = newLine . " "
        endif
        
        " Special case for "my" buffer as I am finally going to be
        "  non-modifiable, anyway.
        if getbufvar(i, "&modifiable") == 0 || myBufNr == i
          let newLine = newLine . "-"
        elseif getbufvar(i, "&readonly") == 1
          let newLine = newLine . "="
        else
          let newLine = newLine . " "
        endif

        " Special case for "my" buffer as I am finally going to be
        "  non-modified, anyway.
        if getbufvar(i, "&modified") == 1 && myBufNr != i
          let newLine = newLine . "+"
        else
          let newLine = newLine . " "
        endif
      endif
      let newLine = newLine . "\t" . bufname(i)
      call append(line("$"), newLine)
    endif
    let i = i + 1
  endwhile
  normal! 1G
  let v:errmsg=""
  silent! exec "/^" . s:originalBuffer
  " If found.
  if v:errmsg == ""
    mark c
    call histdel("search", -1)
    if line(".") < line("$")
      +mark a " Mark the next line.
    endif
    " Avoids error messages.
    silent! exec "-2"
    if line(".") > s:headerSize
      +mark b " Mark the previous line.
    endif
  endif
  let &report = savedReport
  set nomodified
  set nomodifiable
  " Just set the window size to one more than just required.
  normal! 1G
  if NumberOfWindows() != 1
    exec "resize" . (line("$") + 1)
    "silent! exec "normal! \<C-W>_"
  endif
  " Move to the start
  if line("'t") != 0
    " FIXME: For some reason, this doesn't always work.
    normal! 't
  endif
endfunction


function! s:SelBufSelectCurrentBuffer(openInNewWindow)
  normal! 0yw
  let s:selectedBufferNumber = @"
  " if @" =~ "Buffer"
  if line(".") <= s:headerSize
    +
    return
  endif
  if (! a:openInNewWindow) && ! (g:selBufOpenInNewWindow)
    " In any case, if there is only one window, then don't quit.
    let moreThanOneWindowExsists = (NumberOfWindows() > 1)
    if moreThanOneWindowExsists
      quit
    endif
  endif
  let v:errmsg = ""
  silent! exec "buffer" s:selectedBufferNumber
  if v:errmsg != ""
    split
    exec "buffer" s:selectedBufferNumber
    echohl Error |
       \ echo "Couldn't open buffer " . s:selectedBufferNumber .
       \   " in window " . winnr() ", creating a new window." |
       \ echo "Error Message: " . v:errmsg |
       \ echohl None
  endif
  unlet s:selectedBufferNumber
  call RestoreWindowSettings()
endfunction


function! s:SelBufDeleteCurrentBuffer(wipeout)
  let saveReport = &report
  let &report = 10000
  normal! 0yw
  if line(".") <= s:headerSize
    +
    return
  endif
  if a:wipeout
    exec "bwipeout" @"
  else
    exec "bdelete" @"
  endif
  set modifiable
  delete
  set nomodifiable
  set nomodified
  let &report = saveReport
endfunction


function! s:SelBufQuit()
  if NumberOfWindows() > 1
    quit | call RestoreWindowSettings()
    exec "normal! :\<BS>"
  else
    echo "Can't quit the last window"
  endif
endfunction


function! s:SelBufSetupBuf()
  set noswapfile
  set nobuflisted
  if s:wrapLines
    setlocal wrap
  else
    setlocal nowrap
  endif
  syn keyword Title Buffer File
  if g:selBufHighlightOnlyFilename == 0
    syn match Directory +\([a-z][A-Z]:\)\=\([/\\]*\p\+\)+
  else
    syn match Directory +\([^/\\]\+$\)+
  endif
  syn match Constant +^[0-9]\++
  syn match Special +^"[^:]* [:]+
  syn match Special +\t[^:]* [:]+
  syn match Comment +^"[^:]*$+
  noremap <buffer> <silent> <CR> :call <SID>SelBufSelectCurrentBuffer(0)<CR>
  noremap <buffer> <silent> <2-LeftMouse> :call <SID>SelBufSelectCurrentBuffer(0)<CR>
  noremap <buffer> <silent> <C-W><CR> :call <SID>SelBufSelectCurrentBuffer(1)<CR>
  noremap <buffer> <silent> d :call <SID>SelBufDeleteCurrentBuffer(0)<CR>
  noremap <buffer> <silent> D :call <SID>SelBufDeleteCurrentBuffer(1)<CR>
  noremap <buffer> <silent> i :call <SID>SelBufToggleDetails()<CR>
  noremap <buffer> <silent> u :call <SID>SelBufToggleHidden()<CR>
  noremap <buffer> <silent> p :call <SID>SelBufToggleWrap()<CR>
  noremap <buffer> <silent> r :call <SID>SelBufUpdateBuffer()<CR>
  noremap <buffer> <silent> ? :call <SID>SelBufToggleHelpHeader()<CR>
  cabbr <buffer> <silent> w :
  cabbr <buffer> <silent> wq q
  " FIXME: How can I know what was the original activation key, so that I can
  "  toggle it to mean "Close"? Use F3 for now.
  noremap <buffer> <silent> <F3> :call <SID>SelBufQuit()<CR>
  noremap <buffer> <silent> q :call <SID>SelBufQuit()<CR>

  " Define some local command too for convenience and for easy debugging.
  command! -nargs=0 -buffer S :call <SID>SelBufSelectCurrentBuffer(0)
  command! -nargs=0 -buffer SS :call <SID>SelBufSelectCurrentBuffer(1)
  command! -nargs=0 -buffer D :call <SID>SelBufDeleteCurrentBuffer()
endfunction


function! s:SelBufToggleHelpHeader()
  let s:showHelp = ! s:showHelp
  call s:SelBufUpdateBuffer()
endfunction


function! s:SelBufToggleDetails()
  let s:showDetails = ! s:showDetails
  call s:SelBufUpdateBuffer()
endfunction


function! s:SelBufToggleHidden()
  let s:showHidden = ! s:showHidden
  call s:SelBufUpdateBuffer()
endfunction


function! s:SelBufToggleWrap()
  let &l:wrap = ! &l:wrap
  let s:wrapLines = &l:wrap
endfunction


function! s:SelBufDone()
  call s:SelBufHACKSearchString()
  call s:SelBufHACKNoModifiableProblem()

  " If user wants this buffer be removed...
  if g:selBufRemoveBrowserBuffer
    let myBufNr = FindBufferForName(g:selBufWindowName)
    silent! exec "bwipeout " . myBufNr
  endif
endfunction


" HACK.
function! s:SelBufHACKSearchString()
  " A quick hack to restore the search string.
  if exists ("s:selBufSavedSearchString")
    if histget ("search", -1) != s:selBufSavedSearchString
      let @/ = s:selBufSavedSearchString
      call histadd ("search", s:selBufSavedSearchString)
      unlet s:selBufSavedSearchString
    endif
  endif
endfunction


function! s:SelBufHACKNoModifiableProblem()
  " FIXME: Why do I have to do this ??? Otherwise, the selected buffer or those
  "  that are created by using "file" command become nomodifiable.
  set modifiable
endfunction
