" sel12-Feb-2002 @ 17:55
" Author: Hari Krishna <hari_vim@yahoo.com>
" Last Change: 12-Feb-2002 @ 17:55
" Created:     20-Jul-1999
" Requires: Vim-6.0, multvals.vim(2.0.5), genutils.vim(1.0.6)
" Version: 2.2.4
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
let s:savedSearchString = ""

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

function! s:MyScriptId()
  map <SID>xx <SID>xx
  let s:sid = maparg("<SID>xx")
  unmap <SID>xx
  return substitute(s:sid, "xx$", "", "")
endfunction
let s:myScriptId = s:MyScriptId()


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
  command! -nargs=0 SelectBuf :call <SID>ListBufs()
endif

" commands to manipulate the MRU list.
if !exists(":SBBufToHead")
  command! -nargs=1 SBBufToHead :call <SID>PushToFrontInMRU(<f-args>)
endif

if !exists(":SBBufToTail")
  command! -nargs=1 SBBufToTail :call <SID>PushToBackInMRU(<f-args>)
endif

" The main plug-in mapping.
noremap <script> <silent> <Plug>SelectBuf :call <SID>ListBufs()<CR>

" Deleting autocommands first is a good idea especially if we want to reload
"   the script without restarting vim.
aug SelectBuf
  au!
  exec "au BufWinEnter " . s:windowName . " :call <SID>UpdateBuffer()"
  exec "au BufWinLeave " . s:windowName . " :call <SID>Done()"
  "exec "au WinLeave " . s:windowName . " :call <SID>RestoreWindows()"
  if ! s:disableMRU
    au BufWinEnter * :call <SID>PushToFrontInMRU(bufnr('%'))
    au BufWipeout * :call <SID>DelFromMRU(bufnr(expand("<afile>")))
  endif
aug END

endfunction " -- Initialize

" Do the actual initialization.
call Initialize()


"
" Functions start from here.
"

function! s:ListBufs()

  " For use with the display.
  let s:originalBuffer = bufnr("%")
  let s:originalAltBuffer = bufnr("#")
  " This will not add it to the history.
  let prevSearchString = s:savedSearchString
  " Save the current search string to be able to restore it later.
  if histnr("search") != -1
    let s:savedSearchString = histget("search", -1)
  endif
  let savedUnnamedRegister = @"

  " First check if there is a browser already running.
  let browserWinNo = FindWindowForBuffer(
          \ substitute(s:windowName, '\\ ', ' ', "g"), 1)
  if browserWinNo != -1
    call MoveCursorToWindow(browserWinNo)
  else
    " If user wants us to save window sizes and restore them later.
    "   But don't save unless "split" mode, as otherwise we are not creating a
    "   new window.
    if s:restoreWindowSizes && s:GetModeTypeByName(s:browserMode) == 0
      call SaveWindowSettings()
    endif

    " Don't split window for "switch" mode.
    if s:GetModeTypeByName(s:browserMode) != 1
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
    call s:UpdateBuffer()
  endif

  if line("'t") != 0
    't
  endif
  if prevSearchString != ""
    let @/ = prevSearchString
    call histadd ("search", @/)
  else
    let @/ = s:savedSearchString
  endif
  let @" = savedUnnamedRegister
endfunction " ListBufs


function! s:UpdateHeader()
  let _report=&report
  let &report=99999

  " Remember the position.
  mark z
  let @/ = '^"='
  0
  silent! 1,//delete

  call s:AddHeader()
  0
  call search('^"=', "W")
  mark t

  " For vertical split, we shouldn't adjust the number of lines.
  if ! s:useVerticalSplit
    call s:AdjustWindowSize()
  endif

  " Return to the original position.
  if line("'z") != 0
    normal! `z
  endif

  let &report=_report
endfunction " UpdateHeader


function! s:AddHeader()
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
              \ s:GetSortNameByType(s:sorttype) .
              \ ",showDetails=" . s:showDetails .
              \ ",showHidden=" . s:showHidden . ",showDirs=" .
              \ s:showDirectories . ",wrapLines=" . s:wrapLines .
              \ ",showPaths=" . s:showPaths .
              \ "\n"
  0
  put! =helpMsg
endfunction " AddHeader


function! s:UpdateBuffer()
  call s:SetupBuf()
  let _report=&report
  let &report = 10000
  setlocal modifiable
  " Delete the contents (if any) first.
  silent! 0,$delete

  call s:AddHeader()
  $d _
  mark t

  $
  let headerSize = line("$")

  " Loop over all the buffers.
  let i = 1
  let nBuffers = 0
  let nBuffersShown = 0
  let newLine = ""
  let showBuffer = 0
  while i <= bufnr("$")
    if bufexists(i)
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
        if exists("g:noOptimize") && g:noOptimize
        let newLine = s:GetBufLine(i)
        call append(line("$"), newLine)
        else
        " Hopefully this is easier on sorting.
        call append(line("$"), i)
        endif
        let nBuffersShown = nBuffersShown + 1
      endif
      let nBuffers = nBuffers + 1
    endif
    let i = i + 1
  endwhile
  0
  " If found.
  if search('^' . s:originalBuffer, "W")
    mark c
    if line(".") < line("$")
      +mark a " Mark the next line.
    endif
    -mark b " Mark the previous line.
  endif
  let &report=_report
  " This is not needed because of the buftype setting.
  "set nomodified
  setlocal nomodifiable

  " Finally sort the listing based on the current settings.
  let _savePositionInSort = s:savePositionInSort
  let s:savePositionInSort = 0
  call s:SortSelect(0)
  " Finally add the additional info.
  if ! exists("g:noOptimize") || ! g:noOptimize
  call s:AddInfo()
  endif
  let s:savePositionInSort = _savePositionInSort

  " For vertical split, we shouldn't adjust the number of lines.
  "if ! s:useVerticalSplit
    " Now that our Save/RestoreWindowSettings() is working correctly, it should
    "   be fine.
    call s:AdjustWindowSize()
  "endif
  redraw | echo "Total buffers: " . nBuffers . " Showing: " . nBuffersShown
endfunction " UpdateBuffer


function! s:AddInfo()
  setlocal modifiable
  0
  call search('^"=', "W")
  while search('^\d\+$', "W") != 0
    let bufNum = s:GetCurrentBufferNumber()
    "echomsg "bufNum = " . bufNum . " bufLine = " . s:GetBufLine(bufNum)
    call setline(".", s:GetBufLine(bufNum))
  endwhile
  setlocal nomodifiable
endfunction " AddInfo


function! s:GetBufLine(bufNum)
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

    let myBufNr = FindBufferForName(s:windowName)
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
endfunction " GetBufLine


function! s:AdjustWindowSize()
  " Set the window size to one more than just required.
  0
  if NumberOfWindows() != 1
    exec "resize" . (line("$") + 1)
    "silent! exec "normal! \<C-W>_"
  endif
endfunction


function! s:SelectCurrentBuffer(openInNewWindow)
  if search("^\"=", "W") != 0
    +
    return
  endif

  let selectedBufferNumber = s:GetCurrentBufferNumber()
  if selectedBufferNumber == -1
    +
    return
  endif

  " Quit window only for "split" mode.
  let didQuit = 0
  if s:GetModeTypeByName(s:browserMode) == 0
    if ! (a:openInNewWindow || s:openInNewWindow)
      " In any case, if there is only one window, then don't quit.
      if (NumberOfWindows() > 1)
        silent! quit
        let didQuit = 1
      endif
    endif
    let v:errmsg = ""
  elseif s:GetModeTypeByName(s:browserMode) == 2
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
endfunction " SelectCurrentBuffer


function! s:DeleteCurrentBuffer(wipeout) range
  let _report=&report
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

    let selectedBufferNumber = s:GetCurrentBufferNumber()
    if selectedBufferNumber != -1
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
        silent! delete
        setlocal nomodifiable
        " This is not needed because of the buftype setting.
        "set nomodified
      endif
    endif
    silent +
    let line = line + 1
  endwhile

  let msg = ""
  if nWipedout > 0
    let msg = msg . s:GetDeleteMsg(nWipedout, wipedoutMsg)
    let msg = msg . " wiped out.\n"
  endif
  if nDeleted > 0
    let msg = msg . s:GetDeleteMsg(nDeleted, deletedMsg)
    let msg = msg . " deleted (unlisted).\n"
  endif
  if nUndeleted > 0
    let msg = msg . s:GetDeleteMsg(nUndeleted, undeletedMsg)
    let msg = msg . " undeleted (listed).\n"
  endif

  " If the additional details are being shown, then we may have to update the
  "   buffer.
  if s:showDetails && refreshBuffer
    call s:UpdateBuffer()
  endif

  call RestoreHardPositionWithContext(s:myScriptId)
  let &report=_report

  redraw | echo msg
  "call input(msg)
endfunction " DeleteCurrentBuffer


function! s:GetDeleteMsg(nBufs, msg)
  let msg = a:nBufs . ((a:nBufs > 1) ? " buffers: " : " buffer: ") .
          \ a:msg
  return msg
endfunction


function! s:Quit()
  if s:GetModeTypeByName(s:browserMode) == 1
    e#
    return
  endif

  if NumberOfWindows() > 1
    silent! quit
  else
    redraw | echo "Can't quit the last window"
  endif
endfunction


function! s:SetupBuf()
  " We don't need to set this as the buftype setting below takes care of it.
  setlocal noswapfile
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

  call s:DefineMapFromKey("nnore", "<Plug>SelBufSelectKey", "<CR>", ":call <SID>SelectCurrentBuffer(0)<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufMSelectKey", "<2-LeftMouse>", ":call <SID>SelectCurrentBuffer(0)<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufWSelectKey", "<C-W><CR>", ":call <SID>SelectCurrentBuffer(1)<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufDeleteKey", "d", ":call <SID>DeleteCurrentBuffer(0)<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufWipeOutKey", "D", ":call <SID>DeleteCurrentBuffer(1)<CR>")
  call s:DefineMapFromKey("vnore", "<Plug>SelBufDeleteKey", "d", ":call <SID>DeleteCurrentBuffer(0)<CR>")
  call s:DefineMapFromKey("vnore", "<Plug>SelBufWipeOutKey", "D", ":call <SID>DeleteCurrentBuffer(1)<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufTDetailsKey", "i", ":call <SID>ToggleDetails()<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufTHiddenKey", "u", ":call <SID>ToggleHidden()<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufTDirsKey", "c", ":call <SID>ToggleDirectories()<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufTLineWrapKey", "p", ":call <SID>ToggleWrap()<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufTHidePathsKey", "P", ":call <SID>ToggleHidePaths()<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufRefreshKey", "R", ":call <SID>UpdateBuffer()<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufSortSelectFKey", "s", ":call <SID>SortSelect(1)<cr>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufSortSelectBKey", "S", ":call <SID>SortSelect(-1)<cr>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufSortRevKey", "r", ":call <SID>SortReverse()<cr>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufQuitKey", "q", ":call <SID>Quit()<CR>")
  call s:DefineMapFromKey("nnore", "<Plug>SelBufHelpKey", "?", ":call <SID>ToggleHelpHeader()<CR>")

  " This is not needed because of the buftype setting.
  "cabbr <buffer> <silent> w :
  "cabbr <buffer> <silent> wq q
  " Toggle the same key to mean "Close".
  nnoremap <buffer> <silent> <Plug>SelectBuf :call <SID>Quit()<CR>

  " Define some local command too for ease of debugging.
  command! -nargs=0 -buffer SB :call <SID>SelectCurrentBuffer(0)
  command! -nargs=0 -buffer SBS :call <SID>SelectCurrentBuffer(1)
  command! -nargs=0 -buffer D :call <SID>DeleteCurrentBuffer(0)
  command! -nargs=0 -buffer DD :call <SID>DeleteCurrentBuffer(1)
  command! -nargs=0 -buffer SS :call <SID>SortSelect(1)
  command! -nargs=0 -buffer SSR :call <SID>SortSelect(-1)
  command! -nargs=0 -buffer SR :call <SID>SortReverse()
  command! -nargs=0 -buffer SQ :call <SID>Quit()

  " Arrange a notification of the window close on this window.
  call AddNotifyWindowClose(s:windowName, s:myScriptId . "RestoreWindows")
endfunction " SetupBuf


function! s:DefineMapFromKey(mapType, mapKeyName, defaultKey, cmdStr)
  let key = maparg(a:mapKeyName)
  " If user hasn't specified a key, use the default key passed in.
  if key == ""
    let key = a:defaultKey
  endif
  exec a:mapType . "map <buffer> <silent>" key a:cmdStr
endfunction


function! s:ToggleHelpHeader()
  let s:showHelp = ! s:showHelp
  " Don't save/restore position in this case, because otherwise the user may
  "   not be able to view the help if he has listing that is more than one page
  "   (after all what is he viewing the help for ?)
  setlocal modifiable
  call s:UpdateHeader()
  setlocal nomodifiable
endfunction


function! s:ToggleDetails()
  let s:showDetails = ! s:showDetails
  call SaveHardPositionWithContext(s:myScriptId)
  call s:UpdateBuffer()
  call RestoreHardPositionWithContext(s:myScriptId)
endfunction


function! s:ToggleHidden()
  let s:showHidden = ! s:showHidden
  call SaveHardPositionWithContext(s:myScriptId)
  call s:UpdateBuffer()
  call RestoreHardPositionWithContext(s:myScriptId)
endfunction


function! s:ToggleDirectories()
  let s:showDirectories = ! s:showDirectories
  call SaveHardPositionWithContext(s:myScriptId)
  call s:UpdateBuffer()
  call RestoreHardPositionWithContext(s:myScriptId)
endfunction


function! s:ToggleWrap()
  let &l:wrap = ! &l:wrap
  let s:wrapLines = &l:wrap
  call SaveHardPositionWithContext(s:myScriptId)
  setlocal modifiable
  call s:UpdateHeader()
  setlocal nomodifiable
  call RestoreHardPositionWithContext(s:myScriptId)
endfunction


function! s:ToggleHidePaths()
  let s:showPaths = ! s:showPaths
  call SaveHardPositionWithContext(s:myScriptId)
  call s:UpdateBuffer()
  call RestoreHardPositionWithContext(s:myScriptId)
endfunction


" FIXME: Should I do this even for "keep" mode?
function! s:Done()
  call s:RestoreSearchString()

  " If user wants this buffer be removed...
  if s:removeBrowserBuffer
    let myBufNr = FindBufferForName(s:windowName)
    silent! exec "bwipeout " . myBufNr
  endif
endfunction


function! s:RestoreWindows(dummyTitle)
  " If user wants us to restore window sizes during the exit.
  if s:restoreWindowSizes && s:GetModeTypeByName(s:browserMode) != 2
  call RestoreWindowSettings()
  endif
endfunction


function! s:RestoreSearchString()
  let @/ = s:savedSearchString
  let s:savedSearchString = histget("search", -1)
  " Fortunately, this will make sure there is only one copy in the history.
  call histadd ("search", @/)
endfunction


function! s:GetCurrentBufferNumber()
  return s:GetBufferNumber(getline("."))
endfunction

function! s:GetBufferNumber(line)
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

function! s:GetModeNameByType(modeType)
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

function! s:GetModeTypeByName(modeName)
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


function! s:PushToFrontInMRU(bufNum)
  " Avoid browser buffer to come in the front.
  if a:bufNum == FindBufferForName(s:windowName)
      return
  end

  let s:MRUlist = MvPushToFront(s:MRUlist, ',', a:bufNum)
  let g:MRUlist = s:MRUlist " For debugging.
endfunction


function! s:PushToBackInMRU(bufNum)
  let s:MRUlist = MvPullToBack(s:MRUlist, ',', a:bufNum)
  let g:MRUlist = s:MRUlist " For debugging.
endfunction


function! s:DelFromMRU(bufNum)
  let s:MRUlist = MvRemoveElement(s:MRUlist, ',', a:bufNum)
  let g:MRUlist = s:MRUlist " For debugging.
endfunction


"""
""" Support for sorting... based on the explorer.vim implementation (2.5)
""" Changed the sort algorithm to speed sorting up.
"""

""
"" Utility methods.
""
function! s:GetSortNameByType(sorttype)
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

function! s:GetSortTypeByName(sortname)
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

function! s:GetSortCmpFnByType(sorttype)
  if a:sorttype == 0
    return "s:CmpByNumber"
  elseif a:sorttype == 1
    return "s:CmpByName"
  elseif a:sorttype == 2
    return "s:CmpByPath"
  elseif a:sorttype == 3
    return "s:CmpByType"
  elseif a:sorttype == 4
    return "s:CmpByIndicators"
  elseif a:sorttype == 5
    return "s:CmpByMRU"
  else
    return ""
  endif
endfunction


""
"" Compare methods added.
""

function! s:CmpByName(line1, line2, direction)
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

function! s:CmpByPath(line1, line2, direction)
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

function! s:CmpByNumber(line1, line2, direction)
  let num1 = s:GetBufferNumber(a:line1)
  let num2 = s:GetBufferNumber(a:line2)

  if num1 < num2
    return -a:direction
  elseif num1 > num2
    return a:direction
  else
    return 0
  endif
endfunction

function! s:CmpByType(line1, line2, direction)
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

function! s:CmpByIndicators(line1, line2, direction)
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


function! s:CmpByMRU(line1, line2, direction)
  let num1 = s:GetBufferNumber(a:line1)
  let num2 = s:GetBufferNumber(a:line2)

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
  let s:sorttype = s:GetSortTypeByName(s:sorttype)
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
    let @/ = '^"='
    silent! //+1,$call s:Sort(s:GetSortCmpFnByType(
      \ s:GetSortTypeByName(s:sorttype)), s:sortdirection)

    " Replace the header with updated information
    call s:UpdateHeader()

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
  if a:end > a:start
    let low = a:start
    let high = a:end

    " Arbitrarily establish partition element at the midpoint of the data.
    let midStr = getline((a:start + a:end) / 2)

    " Loop through the data until indices cross.
    while low <= high

      " Find the first element that is greater than or equal to the partition
      "   element starting from the left Index.
      while low < a:end
        let str = getline(low)
        exec "let result = " . a:cmp . "(str, midStr, " . a:direction . ")"
        if result < 0
          let low = low + 1
        else
          break
        endif
      endwhile

      " Find an element that is smaller than or equal to the partition element
      "   starting from the right Index.
      while high > a:start
        let str = getline(high)
        exec "let result = " . a:cmp . "(str, midStr, " . a:direction . ")"
        if result > 0
          let high = high - 1
        else
          break
        endif
      endwhile

      " If the indexes have not crossed, swap.
      if low <= high
        " Swap lines low and high.
        let str2 = getline(high)
        call setline(high, getline(low))
        call setline(low, str2)
        let low = low + 1
        let high = high - 1
      endif
    endwhile

    " If the right index has not reached the left side of data must now sort
    "   the left partition.
    if a:start < high
      call s:SortR(a:start, high, a:cmp, a:direction)
    endif

    " If the left index has not reached the right side of data must now sort
    "   the right partition.
    if low < a:end
      call s:SortR(low, a:end, a:cmp, a:direction)
    endif
  endif
endfunction

"---
" To Sort a range of lines, pass the range to Sort() along with the name of a
" function that will compare two lines.
"
function! s:Sort(cmp,direction) range
  call s:SortR(a:firstline, a:lastline, a:cmp, a:direction)

endfunction
