" selectbuf.vim -- lets you select a buffer visually.
" Author: Hari Krishna <hari_vim@yahoo.com>
" Last Change: 01-Feb-2002 @ 19:26
" Created:     20-Jul-1999
" Requires: Vim-6.0, multvals.vim(2.0.5), genutils.vim(1.0.6)
" Version: 2.2.2
" Download latest version from:
"           http://vim.sourceforge.net/scripts/script.php?script_id=107
"
"  Source this file or drop it in plugin directory and press <F3> to get the
"    list of buffers.
"  Move the cursor on to the buffer that you need to select and press <CR> or
"    double click with the left-mouse button.
"  If you want to close the window without making a selection, press <F3> again.
"  You can also press ^W<CR> to open the file in a new window.
"  You can use d to delete the buffer.
"  For convenience when the browser is opened, the line corresponding to the
"    next buffer is marked with 'a so that you can quickly go to the next
"    buffer.
"
"  You can define your own mapping to activat the browser using the following:
"    nmap <your key sequence here> <Plug>SelectBuf
"  The default is to use <F3>.
"
" To change the default behavior, copy the following configuration properties
"   into your .vimrc and change the values. These are one time use global
"   variables, and so will be unset after the script is loaded, to avoid
"   cluttering the global name space.
"
"     nmap <silent> <unique> ,sb <Plug>SelectBuf
"     let g:selBufWindowName = '---\ Select\ Buffer\ ---'
"     let g:selBufOpenInNewWindow = 0
"     let g:selBufRemoveBrowserBuffer = 0
"     let g:selBufHighlightOnlyFilename = 0
"     let g:selBufRestoreWindowSizes = 1
"     let g:selBufDefaultSortOrder = "number" " number, name, path, type, indicators, mru.
"     let g:selBufAlwaysShowHelp = 0
"     let g:selBufAlwaysShowHidden = 0
"     let g:selBufAlwaysShowDetails = 0
"     let g:selBufAlwaysShowDirectories = 1
"     let g:selBufAlwaysWrapLines = 0
"     let g:selBufAlwaysShowPaths = 1
"     let g:selBufBrowserMode = "keep" " split, switch, keep
"     let g:selBufUseVerticalSplit = 1 " Uses the vertically split windows.
"     let g:selBufSplitType = "topleft" " See :h vertical for possible options.
"     let g:selBufDisableMRUlisting = 1 " Disable generating an MRU listing of the file usage.
"
" You can also change the default key mappings for all the operations, e.g.,
"
"     nmap <script> <silent> <Plug>SelBufHelpKey <C-H> " Default: ?
"
" Here is the complete list of all the key map and their default key:
"     <Plug>SelBufSelectKey		Default: <CR>
"     <Plug>SelBufMSelectKey		Default: <2-LeftMouse>
"     <Plug>SelBufWSelectKey		Default: <C-W><CR>
"     <Plug>SelBufDeleteKey		Default: d
"     <Plug>SelBufWipeOutKey		Default: D
"     <Plug>SelBufDeleteKey		Default: d
"     <Plug>SelBufWipeOutKey		Default: D
"     <Plug>SelBufTDetailsKey		Default: i
"     <Plug>SelBufTHiddenKey		Default: u
"     <Plug>SelBufTDirsKey		Default: c
"     <Plug>SelBufTLineWrapKey		Default: p
"     <Plug>SelBufTHidePathsKey		Default: P
"     <Plug>SelBufRefreshKey		Default: R
"     <Plug>SelBufSortSelectFKey	Default: s
"     <Plug>SelBufSortSelectBKey	Default: S
"     <Plug>SelBufSortRevKey		Default: r
"     <Plug>SelBufQuitKey		Default: q
"     <Plug>SelBufHelpKey		Default: ?
"

if exists("loaded_selectbuf")
  finish
endif
let loaded_selectbuf=1

" Call this any time to reconfigure the environment. This re-performs the same
"   initializations that the script does during the vim startup.
command! -nargs=0 SBInitialize :call <SID>Initialize()

"
" BEGIN configuration.
"

function! Initialize()

"
" The name of the browser. The default is "---Select_Buffer---", but you can
"   change the name at your will.
"
if exists("g:selBufWindowName")
  let s:windowName = g:selBufWindowName
  unlet g:selBufWindowName
else
  let s:windowName = '---Select_Buffer---'
endif

"
" A non-zero value for the variable selBufOpenInNewWindow means that the
"   selected buffer should be opened in a separate window. The value zero will
"   open the selected buffer in the current window.
"
if exists("g:selBufOpenInNewWindow")
  let s:openInNewWindow = g:selBufOpenInNewWindow
  unlet g:selBufOpenInNewWindow
else
  let s:openInNewWindow = 0
endif

"
" A non-zero value for the variable selBufRemoveBrowserBuffer means that after
"   the selection is made, the buffer that belongs to the browser should be
"   deleted. But this is not advisable as vim doesn't reuse the buffer numbers
"   that are no longer used. The default value is 0, i.e., reuse a single
"   buffer. This will avoid creating a lot of buffers and quickly reach large
"   buffer numbers for the new buffers created.
if exists("g:selBufRemoveBrowserBuffer")
  let s:removeBrowserBuffer = g:selBufRemoveBrowserBuffer
  unlet g:selBufRemoveBrowserBuffer
else
  let s:removeBrowserBuffer = 0
endif

"
" A non-zero value for the variable selBufHighlightOnlyFilename will highlight
"   only the filename instead of the whole path. The default value is 0.
if exists("g:selBufHighlightOnlyFilename")
  let s:highlightOnlyFilename = g:selBufHighlightOnlyFilename
  unlet g:selBufHighlightOnlyFilename
else
  let s:highlightOnlyFilename = 0
endif

"
" A non-zero value for the variable selBufRestoreWindowSizes will save the
"   window sizes when the browser is opened and restore them while closing it.
"   The default value is 1.
if exists("g:selBufRestoreWindowSizes")
  let s:restoreWindowSizes = g:selBufRestoreWindowSizes
  unlet g:selBufRestoreWindowSizes
else
  let s:restoreWindowSizes = 1
endif

"
" The default sort order. Browser will start with this sort order.
"   The default value is "number".
if exists("g:selBufDefaultSortOrder")
  " INFO: We allow both name and number as sorttype value, but the
  "   SortListing expects only number values. The actual trick is done by the
  "   SortSelect, which converts the name type to number type before invoking
  "   SortListing.
  let s:sorttype = g:selBufDefaultSortOrder
  unlet g:selBufDefaultSortOrder
else
  let s:sorttype = "number"
endif

"
" If help should be shown always.
" The default is to NOT to show help.
"
if exists("g:selBufAlwaysShowHelp")
  let s:showHelp = g:selBufAlwaysShowHelp
  unlet g:selBufAlwaysShowHelp
else
  let s:showHelp = 0
endif

"
" Should hide the hidden buffers or not.
" The default is to NOT to show hidden buffers.
"
if exists("g:selBufAlwaysShowHidden")
  let s:showHidden = g:selBufAlwaysShowHidden
  unlet g:selBufAlwaysShowHidden
else
  let s:showHidden = 0
endif

"
" If additional details about the buffers should be shown.
" The default is to NOT to show details.
"
if exists("g:selBufAlwaysShowDetails")
  let s:showDetails = g:selBufAlwaysShowDetails
  unlet g:selBufAlwaysShowDetails
else
  let s:showDetails = 0
endif

"
" If the directory buffers should be hidden from the list.
" The default is to NOT to hide directory buffers.
"
if exists("g:selBufAlwaysShowDirectories")
  let s:showDirectories = g:selBufAlwaysShowDirectories
  unlet g:selBufAlwaysShowDirectories
else
  let s:showDirectories = 1
endif

"
" If the lines should be wrapped.
" The default is to NOT to wrap.
"
if exists("g:selBufAlwaysWrapLines")
  let s:wrapLines = g:selBufAlwaysWrapLines
  unlet g:selBufAlwaysWrapLines
else
  let s:wrapLines = 0
endif

"
" If the paths should be shown.
" The default is to NOT to hide.
"
if exists("g:selBufAlwaysShowPaths")
  let s:showPaths = g:selBufAlwaysShowPaths
  unlet g:selBufAlwaysShowPaths
else
  let s:showPaths = 1
endif

"
" Defines the mode of operation for the browser.
" The default is 0 for "split". Other possible values are:
"   1 - switch
"   2 - keep
" The "split" mode always opens the browser after creating a new window, and
"   closes it after selecting a browser.
" The "switch" mode doesn't do the above and tries to reuse the current window.
" The "keep" keeps the browser always open. It opens the selected browser in
"   the most recently used window.
if exists("g:selBufBrowserMode")
  let s:browserMode = g:selBufBrowserMode
  unlet g:selBufBrowserMode
else
  let s:browserMode = "split"
endif


"
" If a the window should be split vertically.
" The defaul is NOT to split verticall.
"
if exists("g:selBufUseVerticalSplit")
  let s:useVerticalSplit = g:selBufUseVerticalSplit
  unlet g:selBufUseVerticalSplit
else
  let s:useVerticalSplit = 0
endif

"
" Specify the split type.
"
if exists("g:selBufSplitType")
  let s:splitType = g:selBufSplitType
  unlet g:selBufSplitType
endif

"
" Disable generating an MRU listing of the file usage. If you never use this
"   feature, you may as well disable this feature as it reduces the
"   autocommands and may contribute to improved performance.
" The deafult is NOT to disable this feature.
"
if exists("g:selBufDisableMRUlisting")
  let s:disableMRU = g:selBufDisableMRUlisting
  unlet g:selBufDisableMRUlisting
else
  let s:disableMRU = 0
endif



"
" END configuration.
"

"
" Initialize some variables.
"
" To store the buffer from which the browser is invoked.
let s:originalBuffer = 1
" characters that must be escaped for a regular expression
let s:savePositionInSort = 1
let s:MRUlist = ""

let s:sortByNumber=0
let s:sortByName=1
let s:sortByPath=2
let s:sortByType=3
let s:sortByIndicators=4
let s:sortByMRU=5
let s:sortByMaxVal=5

let s:sortdirlabel  = ""
" Default Sort type is initialized above from an user setting.
"let s:sorttype = 0
let s:sortdirection = 1

" This is the list maintaining the MRU order of buffers.
let s:MRUlist = ''

function! s:SelBufMyScriptId()
  map <SID>xx <SID>xx
  let s:sid = maparg("<SID>xx")
  unmap <SID>xx
  return substitute(s:sid, "xx$", "", "")
endfunction
let s:myScriptId = s:SelBufMyScriptId()


"
" Define a default mapping if the user hasn't defined a map.
"
if !hasmapto('<Plug>SelectBuf')
  nmap <unique> <silent> <F3> <Plug>SelectBuf
endif

"
" Define a command too (easy for debugging).
"
if !exists(":SelectBuf")
  command! -nargs=0 SelectBuf :call <SID>SelBufListBufs()
endif

" commands to manipulate the MRU list.
if !exists(":SBBufToHead")
  command! -nargs=1 SBBufToHead :call <SID>SelBufPushToFrontInMRU(<f-args>)
endif

if !exists(":SBBufToTail")
  command! -nargs=1 SBBufToTail :call <SID>SelBufPushToBackInMRU(<f-args>)
endif

" The main plug-in mapping.
noremap <script> <silent> <Plug>SelectBuf :call <SID>SelBufListBufs()<CR>

" Deleting autocommands first is a good idea especially if we want to reload
"   the script without restarting vim.
aug SelectBuf
  au!
  exec "au BufWinEnter " . s:windowName . " :call <SID>SelBufUpdateBuffer()"
  exec "au BufWinLeave " . s:windowName . " :call <SID>SelBufDone()"
  "exec "au WinLeave " . s:windowName . " :call <SID>SelBufRestoreWindows()"
  if ! s:disableMRU
    au BufWinEnter * :call <SID>SelBufPushToFrontInMRU(bufnr('%'))
    au BufWipeout * :call <SID>SelBufDelFromMRU(bufnr(expand("<afile>")))
  endif
aug END

endfunction " -- Initialize

" Do the actual initialization.
call Initialize()


"
" Functions start from here.
"

function! s:SelBufListBufs()

  " For use with the display.
  let s:originalBuffer = bufnr("%")
  let s:originalAltBuffer = bufnr("#")
  " A quick hack to restore the search string.
  if histnr("search") != -1
    let s:selBufSavedSearchString = histget("search", -1)
  endif

  " First check if there is a browser already running.
  let browserWinNo = FindWindowForBuffer(
          \ substitute(s:windowName, '\\ ', ' ', "g"), 1)
  if browserWinNo != -1
    call MoveCursorToWindow(browserWinNo)
  else
    " If user wants us to save window sizes and restore them later.
    "   But don't save unless "split" mode, as otherwise we are not creating a
    "   new window.
    if s:restoreWindowSizes && s:SelBufGetModeTypeByName(s:browserMode) == 0
      call SaveWindowSettings()
    endif

    " Don't split window for "switch" mode.
    if s:SelBufGetModeTypeByName(s:browserMode) != 1
      let splitCommand = ""
      " If user specified a split type, use that.
      if exists("s:splitType")
        let splitCommand = splitCommand .  s:splitType
      endif
      if s:useVerticalSplit
        let splitCommand = splitCommand . " vert "
      endif
      let splitCommand = splitCommand . " split"
      exec splitCommand
    endif
  endif

  if browserWinNo == -1
    " Find if there is a buffer already created.
    let bufNo = FindBufferForName(s:windowName)
    if bufNo != -1
      " Switch to the existing buffer.
      exec "buffer " . bufNo
    else
      " Create a new buffer.
      exec ":e " . s:windowName
    endif
    " The actual work should have been done by now by the BufWinEnter
    "   autocommand.
  else
    " Since we have the browser already open, we have to update the window
    "   explicitly.
    call s:SelBufUpdateBuffer()
  endif

  if line("'t") != 0
    normal! 't
  endif
endfunction " SelBufListBufs


function! s:SelBufUpdateHeader()
  " Remember the position.
  normal! mz
  0
  silent! 1,/^"=/delete

  call s:SelBufAddHeader()
  0
  silent! /^"=
  normal! mt

  " For vertical split, we shouldn't adjust the number of lines.
  if ! s:useVerticalSplit
    call s:SelBufAdjustWindowSize()
  endif

  " Return to the original position.
  if line("'z") != 0
    normal! `z
  endif
endfunction " SelBufUpdateHeader


function! s:SelBufAddHeader()
  let helpMsg=""
  let helpKey = maparg("<Plug>SelBufHelpKey")
  if helpKey == ""
    let helpKey = "?"
  endif
  if s:showHelp
    let helpMsg = helpMsg
      \ . "\" <Enter> or Left-double-click : open current buffer\n"
      \ . "\" <C-W><Enter> : open buffer in a new window\n"
      \ . "\" d : delete/undelete current buffer\tD : wipeout current buffer\n"
      \ . "\" i : toggle additional details\t\tp : toggle line wrapping\n"
      \ . "\" c : toggle directory buffers\t\tu : toggle hidden buffers\n"
      \ . "\" P : toggle show paths\t\t\t\n"
      \ . "\" R : refresh browser\t\t\tq : close browser\n"
      \ . "\" s/S : select sort field for/backward\tr : reverse sort\n"
      \ . "\" Next, Previous & Current buffers are marked 'a', 'b' & 'c' "
        \ . "respectively\n"
      \ . "\" Press " . helpKey . " to hide help\n"
  else
    let helpMsg = helpMsg
      \ . "\" Press " . helpKey . " to show help\n"
  endif
  let helpMsg = helpMsg . "\"=" . " Sorting=" . s:sortdirlabel .
              \ s:SelBufGetSortNameByType(s:sorttype) .
              \ ",showDetails=" . s:showDetails .
              \ ",showHidden=" . s:showHidden . ",showDirs=" .
              \ s:showDirectories . ",wrapLines=" . s:wrapLines .
              \ ",showPaths=" . s:showPaths .
              \ "\n"
  0
  put! =helpMsg
endfunction " SelBufAddHeader


function! s:SelBufUpdateBuffer()
  call s:SelBufSetupBuf()
  let savedReport = &report
  let &report = 10000
  setlocal modifiable
  " Delete the contents (if any) first.
  0,$delete

  call s:SelBufAddHeader()
  $d _
  normal! mt

  $
  let headerSize = line("$")

  " Loop over all the buffers.
  let i = 1
  let myBufNr = FindBufferForName(s:windowName)
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
      "let newLine = s:SelBufGetBufLine(i)
      "call append(line("$"), newLine)
      " Hopefully this is easier on sorting.
      call append(line("$"), i)
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
    if line(".") > headerSize
      +mark b " Mark the previous line.
    endif
  endif
  let &report = savedReport
  " This is not needed because of the buftype setting.
  "set nomodified
  setlocal nomodifiable

  " Finally sort the listing based on the current settings.
  let _savePositionInSort = s:savePositionInSort
  let s:savePositionInSort = 0
  call s:SortSelect(0)
  " Finally add the additional info.
  call s:SelBufAddInfo()
  let s:savePositionInSort = _savePositionInSort

  " For vertical split, we shouldn't adjust the number of lines.
  "if ! s:useVerticalSplit
    " Now that our Save/RestoreWindowSettings() is working correctly, it should
    "   be fine.
    call s:SelBufAdjustWindowSize()
  "endif
endfunction " SelBufUpdateBuffer


function! s:SelBufAddInfo()
  setlocal modifiable
  0
  /^"=
  while search('^\d\+$', "W") != 0
    let bufNum = s:SelBufGetCurrentBufferNumber()
    "echomsg "bufNum = " . bufNum . " bufLine = " . s:SelBufGetBufLine(bufNum)
    call setline(".", s:SelBufGetBufLine(bufNum))
  endwhile
  setlocal nomodifiable
endfunction " SelBufAddInfo


function! s:SelBufGetBufLine(bufNum)
  let newLine = ""
  let newLine = newLine . a:bufNum . "\t"
  " If user wants to see more details.
  if s:showDetails
    if !buflisted(a:bufNum)
      let newLine = newLine . "u"
    else
      let newLine = newLine . " "
    endif

    " Bluff a little bit here about the current and alternate buffers.
    "  Not accurate though.
    if s:originalBuffer == a:bufNum
      let newLine = newLine . "%"
    elseif s:originalAltBuffer == a:bufNum
      let newLine = newLine . "#"
    else
      let newLine = newLine . " "
    endif

    if bufloaded(a:bufNum)
      if bufwinnr(a:bufNum) != -1
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
    if getbufvar(a:bufNum, "&modifiable") == 0 || myBufNr == a:bufNum
      let newLine = newLine . "-"
    elseif getbufvar(a:bufNum, "&readonly") == 1
      let newLine = newLine . "="
    else
      let newLine = newLine . " "
    endif

    " Special case for "my" buffer as I am finally going to be
    "  non-modified, anyway.
    if getbufvar(a:bufNum, "&modified") == 1 && myBufNr != a:bufNum
      let newLine = newLine . "+"
    else
      let newLine = newLine . " "
    endif
    let newLine = newLine . "\t"
  endif
  if s:showPaths
    let newLine = newLine . bufname(a:bufNum)
  else
    let newLine = newLine . fnamemodify(bufname(a:bufNum), ":t")
  endif
  return newLine
endfunction " SelBufGetBufLine


function! s:SelBufAdjustWindowSize()
  " Set the window size to one more than just required.
  normal! 1G
  if NumberOfWindows() != 1
    exec "resize" . (line("$") + 1)
    "silent! exec "normal! \<C-W>_"
  endif
endfunction


function! s:SelBufSelectCurrentBuffer(openInNewWindow)
  if search("^\"=", "W") != 0
    +
    return
  endif

  let selectedBufferNumber = s:SelBufGetCurrentBufferNumber()
  if selectedBufferNumber == -1
    +
    return
  endif

  " Quit window only for "split" mode.
  let didQuit = 0
  if s:SelBufGetModeTypeByName(s:browserMode) == 0
    if ! (a:openInNewWindow || s:openInNewWindow)
      " In any case, if there is only one window, then don't quit.
      if (NumberOfWindows() > 1)
        silent! quit
        let didQuit = 1
      endif
    endif
    let v:errmsg = ""
  elseif s:SelBufGetModeTypeByName(s:browserMode) == 2
    " Switch to the most recently used window.
    wincmd p
  endif
  " If we are not quitting the window, then there is no point trying to restore
  "   the window settings.
  if ! didQuit
    call RemoveNotifyWindowClose(s:windowName)
    call ResetWindowSettings()
  endif

  silent! exec "buffer" selectedBufferNumber

  if v:errmsg != ""
    split
    exec "buffer" selectedBufferNumber
    redraw | echohl Error |
       \ echo "Couldn't open buffer " . selectedBufferNumber .
       \   " in window " . winnr() ", creating a new window." |
       \ echo "Error Message: " . v:errmsg |
       \ echohl None
  endif
endfunction " SelBufSelectCurrentBuffer


function! s:SelBufDeleteCurrentBuffer(wipeout) range
  let saveReport = &report
  let &report = 10000
  call SaveHardPositionWithContext(s:myScriptId)

  if a:firstline == 0 || a:lastline == 0
    let a:firstline = line(".")
    let a:lastline = line(".")
  endif

  let line = a:firstline
  let nDeleted = 0
  let nUndeleted = 0
  let nWipedout = 0
  let deletedMsg = ""
  let undeletedMsg = ""
  let wipedoutMsg = ""
  while line <= a:lastline
    silent execute line

    let selectedBufferNumber = s:SelBufGetCurrentBufferNumber()
    if selectedBufferNumber == -1
      +
      return
    endif
    let deleteLine = 0
    let refreshBuffer = 0
    if a:wipeout
      exec "bwipeout" selectedBufferNumber
      let deleteLine = 1
      let nWipedout = nWipedout + 1
      let wipedoutMsg = wipedoutMsg . " " . selectedBufferNumber
    elseif buflisted(selectedBufferNumber)
      exec "bdelete" selectedBufferNumber
      if ! s:showHidden
        let deleteLine = 1
      else
        let deleteLine = 0
        let refreshBuffer = 1
      endif
      let nDeleted = nDeleted + 1
      let deletedMsg = deletedMsg . " " . selectedBufferNumber
    else
      " Undelete buffer.
      call setbufvar(selectedBufferNumber, "&buflisted", "1")
      let deleteLine = 0
      let refreshBuffer = 1
      let nUndeleted = nUndeleted + 1
      let undeletedMsg = undeletedMsg . " " . selectedBufferNumber
    endif
    if deleteLine
      setlocal modifiable
      delete
      setlocal nomodifiable
      " This is not needed because of the buftype setting.
      "set nomodified
    endif

    silent +
    let line = line + 1
  endwhile

  function! s:SelBufGetDeleteMsg(nBufs, msg)
    let msg = a:nBufs . ((a:nBufs > 1) ? " buffers: " : " buffer: ") .
            \ a:msg
    return msg
  endfunction

  let msg = ""
  if nWipedout > 0
    let msg = msg . s:SelBufGetDeleteMsg(nWipedout, wipedoutMsg)
    let msg = msg . " wiped out.\n"
  endif
  if nDeleted > 0
    let msg = msg . s:SelBufGetDeleteMsg(nDeleted, deletedMsg)
    let msg = msg . " deleted (unlisted).\n"
  endif
  if nUndeleted > 0
    let msg = msg . s:SelBufGetDeleteMsg(nUndeleted, undeletedMsg)
    let msg = msg . " undeleted (listed).\n"
  endif

  " If the additional details are being shown, then we may have to update the
  "   buffer.
  if s:showDetails && refreshBuffer
    call s:SelBufUpdateBuffer()
  endif

  call RestoreHardPositionWithContext(s:myScriptId)
  let &report = saveReport

  redraw | echo msg
  "call input(msg)
endfunction " SelBufDeleteCurrentBuffer


function! s:SelBufQuit()
  if s:SelBufGetModeTypeByName(s:browserMode) == 1
    e#
    return
  endif

  if NumberOfWindows() > 1
    silent! quit
  else
    redraw | echo "Can't quit the last window"
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

  "
  " Start syntax rules.
  "

  " The mappings in the help header.
  syn match SelBufMapping "\s\(\i\|[ /<>-]\)\+ : " contained
  syn match SelBufHelpLine "^\" .*$" contains=SelBufMapping

  " The starting line. Summary of current settings.
  syn keyword SelBufKeyWords Sorting showDetails showHidden showDirs wrapLines showPaths bufNameOnly contained
  syn region SelBufKeyValues start=+=+ end=+,+ end=+$+ skip=+ + contained
  syn match SelBufKeyValuePair +\i\+=\i\++ contained contains=SelBufKeyWords,SelBufKeyValues
  syn match SelBufSummary "^\"= .*$" contains=SelBufKeyValuePair

  syn match SelBufBufNumber "^\d\+" contained
  if s:highlightOnlyFilename
    syn match SelBufBufName "\([^/\\ \t]\+\)$" contained
  else
    syn match SelBufBufName "\([a-zA-Z]:\)\=\([/\\]\{-}\p\{-1,}\)$" contained
  endif
  syn match SelBufBufIndicators "\(\t\| \)[^\t]*\t" contained
  syn match SelBufBufLine "^[^"].*$" contains=SelBufBufNumber,SelBufBufIndicators,SelBufBufName


  hi def link SelBufHelpLine      Comment
  hi def link SelBufMapping       Special

  hi def link SelBufSummary       Statement
  hi def link SelBufKeyWords      Keyword
  hi def link SelBufKeyValues     Constant

  hi def link SelBufBufNumber     Constant
  hi def link SelBufBufIndicators Comment
  hi def link SelBufBufName       Directory

  "
  " End Syntax rules.
  "

  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufSelectKey", "<CR>", ":call <SID>SelBufSelectCurrentBuffer(0)<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufMSelectKey", "<2-LeftMouse>", ":call <SID>SelBufSelectCurrentBuffer(0)<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufWSelectKey", "<C-W><CR>", ":call <SID>SelBufSelectCurrentBuffer(1)<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufDeleteKey", "d", ":call <SID>SelBufDeleteCurrentBuffer(0)<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufWipeOutKey", "D", ":call <SID>SelBufDeleteCurrentBuffer(1)<CR>")
  call s:SelBufDefineMapFromKey("vnore", "<Plug>SelBufDeleteKey", "d", ":call <SID>SelBufDeleteCurrentBuffer(0)<CR>")
  call s:SelBufDefineMapFromKey("vnore", "<Plug>SelBufWipeOutKey", "D", ":call <SID>SelBufDeleteCurrentBuffer(1)<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufTDetailsKey", "i", ":call <SID>SelBufToggleDetails()<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufTHiddenKey", "u", ":call <SID>SelBufToggleHidden()<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufTDirsKey", "c", ":call <SID>SelBufToggleDirectories()<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufTLineWrapKey", "p", ":call <SID>SelBufToggleWrap()<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufTHidePathsKey", "P", ":call <SID>SelBufToggleHidePaths()<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufRefreshKey", "R", ":call <SID>SelBufUpdateBuffer()<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufSortSelectFKey", "s", ":call <SID>SortSelect(1)<cr>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufSortSelectBKey", "S", ":call <SID>SortSelect(-1)<cr>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufSortRevKey", "r", ":call <SID>SortReverse()<cr>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufQuitKey", "q", ":call <SID>SelBufQuit()<CR>")
  call s:SelBufDefineMapFromKey("nnore", "<Plug>SelBufHelpKey", "?", ":call <SID>SelBufToggleHelpHeader()<CR>")

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
  command! -nargs=0 -buffer SQ :call <SID>SelBufQuit()

  " Arrange a notification of the window close on this window.
  call AddNotifyWindowClose(s:windowName, s:myScriptId . "SelBufRestoreWindows")
endfunction " SelBufSetupBuf


function! s:SelBufDefineMapFromKey(mapType, mapKeyName, defaultKey, cmdStr)
  let key = maparg(a:mapKeyName)
  " If user hasn't specified a key, use the default key passed in.
  if key == ""
    let key = a:defaultKey
  endif
  exec a:mapType . "map <buffer> <silent>" key a:cmdStr
endfunction


function! s:SelBufToggleHelpHeader()
  let s:showHelp = ! s:showHelp
  " Don't save/restore position in this case, because otherwise the user may
  "   not be able to view the help if he has listing that is more than one page
  "   (after all what is he viewing the help for ?)
  setlocal modifiable
  call s:SelBufUpdateHeader()
  setlocal nomodifiable
endfunction


function! s:SelBufToggleDetails()
  let s:showDetails = ! s:showDetails
  call SaveHardPositionWithContext(s:myScriptId)
  call s:SelBufUpdateBuffer()
  call RestoreHardPositionWithContext(s:myScriptId)
endfunction


function! s:SelBufToggleHidden()
  let s:showHidden = ! s:showHidden
  call SaveHardPositionWithContext(s:myScriptId)
  call s:SelBufUpdateBuffer()
  call RestoreHardPositionWithContext(s:myScriptId)
endfunction


function! s:SelBufToggleDirectories()
  let s:showDirectories = ! s:showDirectories
  call SaveHardPositionWithContext(s:myScriptId)
  call s:SelBufUpdateBuffer()
  call RestoreHardPositionWithContext(s:myScriptId)
endfunction


function! s:SelBufToggleWrap()
  let &l:wrap = ! &l:wrap
  let s:wrapLines = &l:wrap
  call SaveHardPositionWithContext(s:myScriptId)
  setlocal modifiable
  call s:SelBufUpdateHeader()
  setlocal nomodifiable
  call RestoreHardPositionWithContext(s:myScriptId)
endfunction


function! s:SelBufToggleHidePaths()
  let s:showPaths = ! s:showPaths
  call SaveHardPositionWithContext(s:myScriptId)
  call s:SelBufUpdateBuffer()
  call RestoreHardPositionWithContext(s:myScriptId)
endfunction


" FIXME: Should I do this even for "keep" mode?
function! s:SelBufDone()
  call s:SelBufHACKSearchString()

  " If user wants this buffer be removed...
  if s:removeBrowserBuffer
    let myBufNr = FindBufferForName(s:windowName)
    silent! exec "bwipeout " . myBufNr
  endif
endfunction


function! s:SelBufRestoreWindows(dummyTitle)
  " If user wants us to restore window sizes during the exit.
  if s:restoreWindowSizes && s:SelBufGetModeTypeByName(s:browserMode) != 2
  "redraw | echomsg "nWindows: " . NumberOfWindows()
  call RestoreWindowSettings()
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


function! s:SelBufGetCurrentBufferNumber()
  return s:SelBufGetBufferNumber(getline("."))
endfunction

function! s:SelBufGetBufferNumber(line)
  let bufNumber = matchstr(a:line, '^\d\+')
  if bufNumber == ""
    return -1
  endif
  " Convert it to number type.
  return bufNumber + 0
endfunction


"
" Utility methods.
"

function! s:SelBufGetModeNameByType(modeType)
  if a:modeType == 0
    return "split"
  elseif a:modeType == 1
    return "switch"
  elseif a:modeType == 2
    return "keep"
  elseif match(a:modeType, '\a') != -1
    return a:modeType
  else
    return ""
  endif
endfunction

function! s:SelBufGetModeTypeByName(modeName)
  if match(a:modeName, '\d') != -1
    return (a:modeName + 0)
  elseif a:modeName == "split"
    return 0
  elseif a:modeName == "switch"
    return 1
  elseif a:modeName == "keep"
    return 2
  else
    return -1
  endif
endfunction


function! s:SelBufPushToFrontInMRU(bufNum)
  " Avoid browser buffer to come in the front.
  if a:bufNum == FindBufferForName(s:windowName)
      return
  end

  let s:MRUlist = MvPushToFront(s:MRUlist, ',', a:bufNum)
  let g:MRUlist = s:MRUlist " For debugging.
endfunction


function! s:SelBufPushToBackInMRU(bufNum)
  let s:MRUlist = MvPullToBack(s:MRUlist, ',', a:bufNum)
  let g:MRUlist = s:MRUlist " For debugging.
endfunction


function! s:SelBufDelFromMRU(bufNum)
  let s:MRUlist = MvRemoveElement(s:MRUlist, ',', a:bufNum)
  let g:MRUlist = s:MRUlist " For debugging.
endfunction


"""
""" Support for sorting...from explorer.vim (2.5)
""" Minimize the changes necessary, to make future merges easier.
"""

""
"" Utility methods.
""
function! s:SelBufGetSortNameByType(sorttype)
  if a:sorttype == 0
    return "number"
  elseif a:sorttype == 1
    return "name"
  elseif a:sorttype == 2
    return "path"
  elseif a:sorttype == 3
    return "type"
  elseif a:sorttype == 4
    return "indicators"
  elseif a:sorttype == 5
    return "mru"
  elseif match(a:sorttype, '\a') != -1
    return a:sorttype
  else
    return ""
  endif
endfunction

function! s:SelBufGetSortTypeByName(sortname)
  if match(a:sortname, '\d') != -1
    return (a:sortname + 0)
  elseif a:sortname == "number"
    return 0
  elseif a:sortname == "name"
    return 1
  elseif a:sortname == "path"
    return 2
  elseif a:sortname == "type"
    return 3
  elseif a:sortname == "indicators"
    return 4
  elseif a:sortname == "mru"
    return 5
  else
    return -1
  endif
endfunction

function! s:SelBufGetSortCmpFnByType(sorttype)
  if a:sorttype == 0
    return "s:SelBufCmpByNumber"
  elseif a:sorttype == 1
    return "s:SelBufCmpByName"
  elseif a:sorttype == 2
    return "s:SelBufCmpByPath"
  elseif a:sorttype == 3
    return "s:SelBufCmpByType"
  elseif a:sorttype == 4
    return "s:SelBufCmpByIndicators"
  elseif a:sorttype == 5
    return "s:SelBufCmpByMRU"
  else
    return ""
  endif
endfunction


""
"" Compare methods added.
""

function! s:SelBufCmpByName(line1, line2, direction)
  let name1 = substitute(a:line1, '^.*\t.\{-}\([^/\\]*$\)', '\1', '')
  let name2 = substitute(a:line2, '^.*\t.\{-}\([^/\\]*$\)', '\1', '')

  if name1 < name2
    return -a:direction
  elseif name1 > name2
    return a:direction
  else
    return 0
  endif
endfunction

function! s:SelBufCmpByPath(line1, line2, direction)
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
  let num1 = s:SelBufGetBufferNumber(a:line1)
  let num2 = s:SelBufGetBufferNumber(a:line2)

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
  "let type1 = matchstr(a:line1, '\.[^.]\+$')
  "let type1 = strpart(type1, 1)
  "let type2 = matchstr(a:line2, '\.[^.]\+$')
  "let type2 = strpart(type2, 1)
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


function! s:SelBufCmpByMRU(line1, line2, direction)
  let num1 = s:SelBufGetBufferNumber(a:line1)
  let num2 = s:SelBufGetBufferNumber(a:line2)

  return MvCmpByPosition(s:MRUlist, ',', num1, num2, a:direction)
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
  let s:sorttype = s:SelBufGetSortTypeByName(s:sorttype)
  let s:sorttype = s:sorttype + a:inc

  " Wrap the sort type.
  if s:sorttype > s:sortByMaxVal
    let s:sorttype = 0
  elseif s:sorttype < 0
    let s:sorttype = s:sortByMaxVal
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
      call SaveHardPositionWithContext(s:myScriptId)
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
    silent! /^"=/+1,$call s:Sort(s:SelBufGetSortCmpFnByType(
      \ s:SelBufGetSortTypeByName(s:sorttype)), s:sortdirection)

    " Replace the header with updated information
    call s:SelBufUpdateHeader()

    " Restore section separators
    "call s:AddSeparators()

    " Return to the position we started on
    if s:savePositionInSort
      call RestoreHardPositionWithContext(s:myScriptId)
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
