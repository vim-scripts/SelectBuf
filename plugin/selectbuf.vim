"
" selectbuf.vim -- lets you select a buffer visually.
" Author: Hari Krishna <haridsv@ureach.com>
" Last Change: 04-Oct-2001 @ 16:45
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
"  See the FIXME below.

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
if !exists("selBufWindowName")
  let selBufWindowName = '---\ Select\ Buffer\ ---'
endif

"
" A non-zero value for the variable selBufOpenInNewWindow means that the
"   selected buffer should be opened in a separate window. The value zero will
"   open the selected buffer in the current window.
"
if !exists("selBufOpenInNewWindow")
  let selBufOpenInNewWindow = 0
endif

"
" A non-zero value for the variable selBufRemoveBrowserBuffer means that after
"   the selection is made, the buffer that belongs to the browser should be
"   deleted. But this is not advisable as vim doesn't reuse the buffer numbers
"   that are no longer used. The default value is 0, i.e., reuse a single
"   buffer. This will avoid creating a lot of buffers and quickly reach large
"   buffer numbers for the new buffers created.
if !exists("selBufRemoveBrowserBuffer")
  let selBufRemoveBrowserBuffer = 0
endif

"
" A non-zero value for the variable selBufHighlightOnlyFilename will highlight
"   only the filename instead of the whole path. The default value is 0.
if !exists("selBufHighlightOnlyFilename")
  let selBufHighlightOnlyFilename = 0
endif

"
" END configuration.
"
if !hasmapto('<Plug>SelectBuf')
  nmap <unique> <silent> <F3> <Plug>SelectBuf
endif

" The main plug-in mapping.
nmap <script> <silent> <Plug>SelectBuf :call <SID>SelBufListBufs()<CR>

function! s:SelBufListBufs()
  " First check if there is a browser already running.
  let browserWinNo = FindWindowForBuffer(g:selBufWindowName)
  if browserWinNo != -1
    exec "normal " . browserWinNo . "\<C-W>w"
    return
  endif
  call SaveWindowSettings()
  let savedReport = &report
  let &report = 10000
  let curBuf = bufnr("%")
  " A quick hack to restore the search string.
  if histnr("search") != -1
    let g:selBufSavedSearchString = histget("search", -1)
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
  set noswapfile
  $put=\"Buffer\t\t\tFile\"
  1d
  let i = 1
  let myBufNr = bufnr("%")
  while i <= bufnr("$")
    if buflisted(i) && (i != myBufNr)
      $put=i . \"\t\t\t\" . bufname(i)
    endif
    let i = i + 1
  endwhile
  1
  exec "/^" . curBuf
  call histdel("search", -1)
  if line(".") < line("$")
    +mark a " Mark the next line.
  endif
  1
  set nomodified
  exec "normal \<C-W>_"
  let &report = savedReport
  call s:SelBufSetupBuf()
endfunction

function! s:SelBufSetupBuf()
  set nobuflisted
  set nomodifiable
  syn keyword Title Buffer File
  if g:selBufHighlightOnlyFilename == 0
    syn match Directory +\([a-z][A-Z]:\)\=\([/\\]*\p\+\)+
  else
    syn match Directory +\([^/\\]\+$\)+
  endif
  syn match Constant +^[0-9]\++
  noremap <buffer> <silent> <CR> :call <SID>SelBufSelectCurrentBuffer(0)<CR>
  noremap <buffer> <silent> <2-LeftMouse> :call <SID>SelBufSelectCurrentBuffer(0)<CR>:<BS>
  noremap <buffer> <silent> <C-W><CR> :call <SID>SelBufSelectCurrentBuffer(1)<CR>:<BS>
  noremap <buffer> <silent> dd :call <SID>SelBufDeleteCurrentBuffer()<CR>:<BS>
  cabbr <buffer> <silent> w :
  cabbr <buffer> <silent> wq q
  " FIXME: How can I know what was the original activation key, so that I can
  "  toggle it to mean "Close"? Use F3 for now.
  nmap <buffer> <silent> <F3> :call <SID>SelBufQuit()<CR>
  call s:SelBufSetupBufAutoClean()
endfunction

" Arrange an autocommand such that the buffer is automatically deleted when the
"  window is quit. Delete the autocommand itself when done.
function! s:SelBufSetupBufAutoClean()
  exec "au BufUnload " . g:selBufWindowName . " :call <SID>SelBufExecBufClean ()"
  exec "au BufHidden " . g:selBufWindowName . " :call <SID>SelBufExecBufClean ()"
endfunction

" Cleanup the settings fo this buffer. Delete the autocommand itself after that.
function! s:SelBufExecBufClean()
  let bufNo = FindBufferForName(g:selBufWindowName)
  if bufNo == -1
    " Should not happen
    echohl Error | echo "SelBuf Internal ERROR" | echohl None
    return
  endif
  exec "au! * " . g:selBufWindowName
  " For use next time.
  set modifiable
  " In case hidden is set, the buffer is not unloaded, so delete the contents.
  0,$d
  set nomodified
endfunction

function! s:SelBufSelectCurrentBuffer(openInNewWindow)
  let myBufNr = bufnr("%")
  normal 0yw
  let s:selectedBufferNumber = @"
  if @" =~ "Buffer"
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
  exec "buffer" s:selectedBufferNumber
  unlet s:selectedBufferNumber
  if g:selBufRemoveBrowserBuffer
    exec "bd " . myBufNr
  endif
  call RestoreWindowSettings()
endfunction

function! s:SelBufDeleteCurrentBuffer()
  let saveReport = &report
  let &report = 10000
  normal 0yw
  if @" =~ "Buffer"
    +
    return
  endif
  exec "bdelete" @"
  set modifiable
  delete
  set nomodifiable
  set nomodified
  let &report = saveReport
endfunction

function! s:SelBufQuit()
  if NumberOfWindows() > 1
    quit | call RestoreWindowSettings()
    exec "normal :\<BS>"
  else
    echo "Can't quit the last window"
  endif
endfunction
