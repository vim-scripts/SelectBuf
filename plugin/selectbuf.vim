" selectbuf.vim -- lets you select a buffer visually.
" Author: Hari Krishna <hari_vim@yahoo.com>
" Last Change: 26-Oct-2001 @ 12:04
" Requires: Vim-6.0 or higher, lightWeightArray.vim(1.0.1),
"           bufNwinUtils.vim(1.0.1)
" Version: 2.1.6
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
" If the directory buffers should be hidden from the list.
" The default is to NOT to hide directory buffers.
"
if exists("g:selBufAlwaysShowDirectories")
  let s:showDirectories = g:selBufAlwaysShowDirectories
else
  let s:showDirectories = 1
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
" characters that must be escaped for a regular expression
let s:escregexp = '/*^$.~\'
let s:savePositionInSort = 1

let s:sortByNumber=0
let s:sortByName=1
let s:sortByType=2
let s:sortByIndicators=3
let s:sortByMaxVal=3

let s:sortdirlabel  = ""
let s:sorttype = 0
let s:sortdirection = 1

function! s:SelBufGetSortTypeLabel(sorttype)
  if a:sorttype == 0
    return "number"
  elseif a:sorttype == 1
    return "name"
  elseif a:sorttype == 2
    return "type"
  elseif a:sorttype == 3
    return "indicators"
  else
    return ""
  endif
endfunction

function! s:SelBufGetSortTypeCmd(sorttype)
  if a:sorttype == 0
    return "s:SelBufCmpByNumber"
  elseif a:sorttype == 1
    return "s:SelBufCmpByName"
  elseif a:sorttype == 2
    return "s:SelBufCmpByType"
  elseif a:sorttype == 3
    return "s:SelBufCmpByIndicators"
  else
    return ""
  endif
endfunction


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

" Deleting autocommands first is a good idea especially if we want to reload
"   the script without restarting vim.
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


function! s:SelBufUpdateHeader()
  0
  silent! 1,/^"=/delete

  let helpMsg=""
  if s:showHelp
    let helpMsg = helpMsg
      \ . "\" <Enter> or Left-double-click : open current buffer\n"
      \ . "\" <C-W><Enter> : open buffer in a new window\n"
      \ . "\" d : delete/undelete current buffer\tD : wipeout current buffer\n"
      \ . "\" i : toggle additional details\t\tp : toggle line wrapping\n"
      \ . "\" c : toggle directory buffers\t\tu : toggle hidden buffers\n"
      \ . "\" R : refresh browser\t\t\tq or <F3> : close browser\n"
      \ . "\" s/S : select sort field for/backward\tr : reverse sort\n"
      \ . "\" Next, Previous & Current buffers are marked 'a', 'b' & 'c' "
        \ . "respectively\n"
      \ . "\" Press ? to hide help\n"
  else
    let helpMsg = helpMsg
      \ . "\" Press ? to show help\n"
  endif
  let helpMsg = helpMsg . "\"=" . " Sorting=" . s:sortdirlabel .
              \ s:SelBufGetSortTypeLabel(s:sorttype) .
              \ ",showDetails=" . s:showDetails .
              \ ",showHidden=" . s:showHidden . ",showDirs=" .
              \ s:showDirectories . ",wrapLines=" . s:wrapLines .
              \ "\n"
    "\.w:sorttype.b:suffixeslast.b:filtering."\n"
  0
  put! =helpMsg

  " Delete any empty lines.
  %g/^$/d

  " This works from here as this method is the last one called anytime (because
  "   of sort).
  " Set the window size to one more than just required.
  normal! 1G
  if NumberOfWindows() != 1
    exec "resize" . (line("$") + 1)
    "silent! exec "normal! \<C-W>_"
  endif

  " Mark the end of the header.
  0
  /^"=
  normal! mt
endfunction


function! s:SelBufUpdateBuffer()
  call s:SelBufSetupBuf()
  let savedReport = &report
  let &report = 10000
  setlocal modifiable
  " Delete the contents (if any) first.
  0,$delete

  " This will anyway be called from the sort, but it doesn't hurt.
  call s:SelBufUpdateHeader()

  $
  let s:headerSize = line("$")

  " Loop over all the buffers.
  let i = 1
  let myBufNr = FindBufferForName(g:selBufWindowName)
  while i <= bufnr("$")
    let newLine = ""
    let showBuffer = 0

    " If user wants to hide hidden buffers.
    if s:showHidden && bufexists(i)
      let showBuffer = 1
    elseif ! s:showHidden && buflisted(i)
      let showBuffer = 1
    endif

    " If user wants to hide directory buffers.
    if ! s:showDirectories && isdirectory(bufname(i))
      let showBuffer = 0
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
  " This is not needed because of the buftype setting.
  "set nomodified
  setlocal nomodifiable

  " Move to the start
  if line("'t") != 0 && line("'t") < line("$")
    " FIXME: For some reason, this doesn't always work.
    normal! 't
  else
    0
  endif

  " Finally sort the listing based on the current settings.
  let _savePositionInSort = s:savePositionInSort
  let s:savePositionInSort = 0
  call s:SortSelect(0)
  let s:savePositionInSort = _savePositionInSort
endfunction


function! s:SelBufSelectCurrentBuffer(openInNewWindow)
  let s:selectedBufferNumber = s:SelBufGetBufferNumber()
  if s:selectedBufferNumber == -1
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
  let s:selectedBufferNumber = s:SelBufGetBufferNumber()
  if s:selectedBufferNumber == -1
    +
    return
  endif
  let deleteLine = 0
  if a:wipeout
    exec "bwipeout" s:selectedBufferNumber
    echo "Buffer " . s:selectedBufferNumber . " wiped out."
    let deleteLine = 1
  elseif buflisted(s:selectedBufferNumber)
    exec "bdelete" s:selectedBufferNumber
    echo "Buffer " . s:selectedBufferNumber . " deleted."
    if ! s:showHidden
      let deleteLine = 1
    endif
  else
    " Undelete buffer.
    call setbufvar(s:selectedBufferNumber, "&buflisted", "1")
    echo "Buffer " . s:selectedBufferNumber . " undeleted."
  endif
  if deleteLine
    setlocal modifiable
    delete
    setlocal nomodifiable
    " This is not needed because of the buftype setting.
    "set nomodified
  endif
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
  " We don't need to set this as the buftype setting below takes care of it.
  "set noswapfile
  set nobuflisted
  setlocal buftype=nofile
  " Just in case, this will make sure we are always hidden.
  setlocal bufhidden=delete
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
  syn match Statement "^\"= .*$"
  nnoremap <buffer> <silent> <CR> :call <SID>SelBufSelectCurrentBuffer(0)<CR>
  nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>SelBufSelectCurrentBuffer(0)<CR>
  nnoremap <buffer> <silent> <C-W><CR> :call <SID>SelBufSelectCurrentBuffer(1)<CR>
  nnoremap <buffer> <silent> d :call <SID>SelBufDeleteCurrentBuffer(0)<CR>
  nnoremap <buffer> <silent> D :call <SID>SelBufDeleteCurrentBuffer(1)<CR>
  nnoremap <buffer> <silent> i :call <SID>SelBufToggleDetails()<CR>
  nnoremap <buffer> <silent> u :call <SID>SelBufToggleHidden()<CR>
  nnoremap <buffer> <silent> c :call <SID>SelBufToggleDirectories()<CR>
  nnoremap <buffer> <silent> p :call <SID>SelBufToggleWrap()<CR>
  nnoremap <buffer> <silent> R :call <SID>SelBufUpdateBuffer()<CR>
  nnoremap <buffer> <silent> s :call <SID>SortSelect(1)<cr>
  nnoremap <buffer> <silent> S :call <SID>SortSelect(-1)<cr>
  nnoremap <buffer> <silent> r :call <SID>SortReverse()<cr>
  nnoremap <buffer> <silent> ? :call <SID>SelBufToggleHelpHeader()<CR>
  nnoremap <buffer> <silent> q :call <SID>SelBufQuit()<CR>
  " This is not needed because of the buftype setting.
  "cabbr <buffer> <silent> w :
  "cabbr <buffer> <silent> wq q
  " Toggle the same key to mean "Close".
  nnoremap <buffer> <silent> <Plug>SelectBuf :call <SID>SelBufQuit()<CR>

  " Define some local command too for ease of debugging.
  command! -nargs=0 -buffer SB :call <SID>SelBufSelectCurrentBuffer(0)
  command! -nargs=0 -buffer SBS :call <SID>SelBufSelectCurrentBuffer(1)
  command! -nargs=0 -buffer D :call <SID>SelBufDeleteCurrentBuffer(0)
  command! -nargs=0 -buffer DD :call <SID>SelBufDeleteCurrentBuffer(1)
  command! -nargs=0 -buffer SS :call <SID>SortSelect(1)
  command! -nargs=0 -buffer SSR :call <SID>SortSelect(-1)
  command! -nargs=0 -buffer SR :call <SID>SortReverse()
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


function! s:SelBufToggleDirectories()
  let s:showDirectories = ! s:showDirectories
  call s:SelBufUpdateBuffer()
endfunction


function! s:SelBufToggleWrap()
  let &l:wrap = ! &l:wrap
  let s:wrapLines = &l:wrap
  " To update the help header, at least.
  call s:SelBufUpdateBuffer()
endfunction


function! s:SelBufDone()
  call s:SelBufHACKSearchString()

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


function! s:SelBufGetBufferNumber()
  normal! 0yw
  let bufNumber = substitute(@", '\s\+', '', 'g')
  if line(".") <= s:headerSize || match(bufNumber, '\d\+') == -1
    return -1
  endif
  " Convert it to number type.
  return bufNumber + 0
endfunction

"""
""" Support for sorting...from explorer.vim (2.5)
""" Minimize the changes necessary, to make future merges easier.
"""

""
"" Compare methods added.
""

function! s:SelBufCmpByName(line1, line2, direction)
  let name1 = substitute(a:line1, '^.*\t', '', '')
  let name2 = substitute(a:line2, '^.*\t', '', '')
  if name1 < name2
    return -a:direction
  elseif name1 > name2
    return a:direction
  else
    return 0
  endif
endfunction

function! s:SelBufCmpByNumber(line1, line2, direction)
  let num1 = substitute(a:line1, '\t.*$', '', '') + 0
  let num2 = substitute(a:line2, '\t.*$', '', '') + 0
  if num1 < num2
    return -a:direction
  elseif num1 > num2
    return a:direction
  else
    return 0
  endif
endfunction

function! s:SelBufCmpByType(line1, line2, direction)
  " Establish the extensions.
  let type1 = substitute(a:line1, '^.*\.\([^.]*\)', '\1', '')
  let type2 = substitute(a:line2, '^.*\.\([^.]*\)', '\1', '')

  " If line1 doesn't have an extension
  if type1 == a:line1
    if type2 == a:line2
      return 0
    else
      return a:direction
    endif
  endif

  " If line2 doesn't have an extension
  if type2 == a:line2
    if type1 == a:line1
      return 0
    else
      return -a:direction
    endif
  endif

  if type1 < type2
    return -a:direction
  elseif type1 > type2
    return a:direction
  else
    return 0
  endif
endfunction

function! s:SelBufCmpByIndicators(line1, line2, direction)
  let ind1 = substitute(a:line1, '^\d\+\t\+\([^\t]\+\)\t\+.*$', '\1', '')
  let ind2 = substitute(a:line2, '^\d\+\t\+\([^\t]\+\)\t\+.*$', '\1', '')
  if ind1 < ind2
    return -a:direction
  elseif ind1 > ind2
    return a:direction
  else
    return 0
  endif
endfunction


"
" Interface to sort.
"

"---
" Reverse the current sort order
"
function! s:SortReverse()
  if exists("s:sortdirection") && s:sortdirection == -1
    let s:sortdirection = 1
    let s:sortdirlabel  = ""
  else
    let s:sortdirection = -1
    let s:sortdirlabel  = "rev-"
  endif
  call s:SortListing("")
endfunction

"---
" Toggle through the different sort orders
"
function! s:SortSelect(inc)
  " Select the next sort option
  if exists("s:sorttype")
    let s:sorttype=s:sorttype + a:inc

    " Wrap the sort type.
    if s:sorttype > s:sortByMaxVal
      let s:sorttype = 0
    elseif s:sorttype < 0
      let s:sorttype = s:sortByMaxVal
    endif
  endif
  call s:SortListing("")
endfunction

"---
" Sort the file listing
"
function! s:SortListing(msg)
    " Save the line we start on so we can go back there when done
    " sorting
    if s:savePositionInSort
      let startline = getline(".")
      let col=col(".")
      let lin=line(".")
    endif

    " Allow modification
    setlocal modifiable

    " Send a message about what we're doing
    " Don't really need this - it can cause hit return prompts
"   echo a:msg . "Sorting by" . w:sortdirlabel . w:sorttype

    " Create a regular expression out of the suffixes option in case
    " we need it.
    "call s:SetSuffixesLast()

    " Remove section separators
    "call s:RemoveSeparators()

    " Do the sort
    0
    silent! /^"=/+1,$call s:Sort(s:SelBufGetSortTypeCmd(s:sorttype),
      \ s:sortdirection)

    " Replace the header with updated information
    call s:SelBufUpdateHeader()

    " Restore section separators
    "call s:AddSeparators()

    " Return to the position we started on
    if s:savePositionInSort
      0
      if search('\m^'.escape(startline,s:escregexp),'W') <= 0
        execute lin
      endif
      execute "normal!" col . "|"
    endif

    " Disallow modification
    " This is not needed because of the buftype setting.
    "setlocal nomodified
    setlocal nomodifiable

endfunction

""
"" Sort infrastructure.
""


"---
" Sort lines.  SortR() is called recursively.
"
function! s:SortR(start, end, cmp, direction)

  " Bottom of the recursion if start reaches end
  if a:start >= a:end
    return
  endif
  "
  let partition = a:start - 1
  let middle = partition
  let partStr = getline((a:start + a:end) / 2)
  let i = a:start
  while (i <= a:end)
    let str = getline(i)
    exec "let result = " . a:cmp . "(str, partStr, " . a:direction . ")"
    if result <= 0
      " Need to put it before the partition.  Swap lines i and partition.
      let partition = partition + 1
      if result == 0
        let middle = partition
      endif
      if i != partition
        let str2 = getline(partition)
        call setline(i, str2)
        call setline(partition, str)
      endif
    endif
    let i = i + 1
  endwhile

  " Now we have a pointer to the "middle" element, as far as partitioning
  " goes, which could be anywhere before the partition.  Make sure it is at
  " the end of the partition.
  if middle != partition
    let str = getline(middle)
    let str2 = getline(partition)
    call setline(middle, str2)
    call setline(partition, str)
  endif
  call s:SortR(a:start, partition - 1, a:cmp,a:direction)
  call s:SortR(partition + 1, a:end, a:cmp,a:direction)
endfunction

"---
" To Sort a range of lines, pass the range to Sort() along with the name of a
" function that will compare two lines.
"
function! s:Sort(cmp,direction) range
  call s:SortR(a:firstline, a:lastline, a:cmp, a:direction)
endfunction
