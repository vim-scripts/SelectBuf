" selectbuf.vim
" Author: Hari Krishna <hari_vim at yahoo dot com>
" Last Change: 01-May-2003 @ 17:41PM
" Created: Before 20-Jul-1999 (http://groups.yahoo.com/group/vim/message/6409)
" Requires: Vim-6.0, multvals.vim(3.1), genutils.vim(1.6)
" Version: 3.1.7
" Licence: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License.
"          See http://www.gnu.org/copyleft/gpl.txt 
" Download From:
"     http://www.vim.org/script.php?script_id=107
" Usage: 
"   For detailed help, see ":help selectbuf" or doc/selectbuf.txt. 
"
"   Source this file or drop it in plugin directory and press <F3> to get the
"     list of buffers.
"   Move the cursor on to the buffer that you need to select and press <CR> or
"     double click with the left-mouse button.
"   If you want to close the window without making a selection, press <F3>
"     again.
"   You can also press ^W<CR> or O to open the file in a new or previous window.
"   You can use d to delete or D to wipeout the buffer. Use d again to
"     undelete a previously deleted buffer (you need to first view the deleted
"     buffers using u command).
"
" TODO:
"   - When entering any of the plugin window's WinManager does something that
"     makes Vim ignore fast mouse-double-clicks. This is a WinManager issue,
"     as I verified this problem with other plugins also and SelectBuf in
"     stand-alone "keep" mode works fine.

if exists("loaded_selectbuf")
  finish
endif
let loaded_selectbuf=1

" Make sure line-continuations won't cause any problem. This will be restored
"   at the end
let s:save_cpo = &cpo
set cpo&vim
                      
" Call this any time to reconfigure the environment. This re-performs the same
"   initializations that the script does during the vim startup, without
"   loosing what is already configured.
command! -nargs=0 SBInitialize :call <SID>Initialize()

" Initializations {{{
function! s:Initialize() " {{{

"
"" START: configuration 
"

if !exists("s:disableSummary") " The first-time only, initialize with defaults.
  let s:disableSummary = 1
  let s:highlightOnlyFilename = 0
  let s:restoreWindowSizes = 1
  let s:sorttype = "mru"
  let s:sortdirection = 1
  let s:ignoreNonFileBufs = 1
  let s:showHelp = 0
  let s:showHidden = 0
  let s:showDetails = 0
  let s:showPaths = 0
  let s:hideBufNums = 0
  let s:browserMode = "split"
  let s:useVerticalSplit = 0
  let s:splitType = ""
  let s:disableMRUlisting = 0
  let s:enableDynUpdate = 1
  let s:delayedDynUpdate = 0
  let s:doFileOnClose = 1
endif

function! s:CondDefSetting(globalName, settingName, ...)
  let assgnmnt = (a:0 != 0) ? a:1 : a:globalName
  if exists(a:globalName)
    exec "let" a:settingName "=" assgnmnt
    exec "unlet" a:globalName
  endif
endfunction

call s:CondDefSetting('g:selBufDisableSummary', 's:disableSummary')
call s:CondDefSetting("g:selBufHighlightOnlyFilename",
      \ 's:highlightOnlyFilename')
call s:CondDefSetting("g:selBufRestoreWindowSizes", 's:restoreWindowSizes')
call s:CondDefSetting("g:selBufDefaultSortOrder", 's:sorttype')
call s:CondDefSetting("g:selBufDefaultSortDirection", 's:sortdirection')
call s:CondDefSetting("g:selBufIgnoreNonFileBufs", 's:ignoreNonFileBufs')
call s:CondDefSetting("g:selBufAlwaysShowHelp", 's:showHelp')
call s:CondDefSetting("g:selBufAlwaysShowHidden", 's:showHidden')
call s:CondDefSetting("g:selBufAlwaysShowDetails", 's:showDetails')
call s:CondDefSetting("g:selBufAlwaysShowPaths", 's:showPaths')
call s:CondDefSetting("g:selBufAlwaysHideBufNums",
      \ 's:hideBufNums | let s:userDefinedHideBufNums = 1')
call s:CondDefSetting("g:selBufBrowserMode", 's:browserMode')
call s:CondDefSetting("g:selBufUseVerticalSplit", 's:useVerticalSplit')
call s:CondDefSetting("g:selBufSplitType", 's:splitType')
call s:CondDefSetting("g:selBufDisableMRUlisting", 's:disableMRUlisting')
call s:CondDefSetting("g:selBufEnableDynUpdate", 's:enableDynUpdate')
call s:CondDefSetting("g:selBufDelayedDynUpdate", 's:delayedDynUpdate')
call s:CondDefSetting("g:selBufDoFileOnClose", 's:doFileOnClose')

"
" END configuration.
"

let s:windowName = '[Select Buf]'

" For WinManager integration.
let g:SelectBuf_title = s:windowName

"
" Define a default mapping if the user hasn't defined a map.
"
if !hasmapto('<Plug>SelectBuf') &&
      \ (! exists("no_plugin_maps") || ! no_plugin_maps) &&
      \ (! exists("no_selectbuf_maps") || ! no_selectbuf_maps)
  nmap <unique> <silent> <F3> <Plug>SelectBuf
endif


" This default mappings are just for the reverse lookup (maparg()) to work
" always.
function! s:DefDefMap(mapType, mapKeyName, defaultKey)
  if maparg('<Plug>SelBuf' . a:mapKeyName) == ''
    exec a:mapType . "noremap <script> <silent> <Plug>SelBuf" . a:mapKeyName
	  \ a:defaultKey
  endif
endfunction
call s:DefDefMap('n', 'SelectKey', "<CR>")
call s:DefDefMap('n', 'MSelectKey', "<2-LeftMouse>")
call s:DefDefMap('n', 'WSelectKey', "<C-W><CR>")
call s:DefDefMap('n', 'OpenKey', "O")
call s:DefDefMap('n', 'DeleteKey', "d")
call s:DefDefMap('n', 'WipeOutKey', "D")
call s:DefDefMap('v', 'DeleteKey', "d")
call s:DefDefMap('v', 'WipeOutKey', "D")
call s:DefDefMap('n', 'TDetailsKey', "i")
call s:DefDefMap('n', 'THiddenKey', "u")
call s:DefDefMap('n', 'TBufNumsKey', "p")
call s:DefDefMap('n', 'THidePathsKey', "P")
call s:DefDefMap('n', 'RefreshKey', "R")
call s:DefDefMap('n', 'SortSelectFKey', "s")
call s:DefDefMap('n', 'SortSelectBKey', "S")
call s:DefDefMap('n', 'SortRevKey', "r")
call s:DefDefMap('n', 'QuitKey', "q")
call s:DefDefMap('n', 'THelpKey', "?")
call s:DefDefMap('n', 'ShowSummaryKey', "<C-G>")
delfunction s:DefDefMap


"
" Define a command too (easy for debugging).
"
command! -nargs=0 SelectBuf :call <SID>ListBufs()
" commands to manipulate the MRU list.
command! -nargs=1 SBBufToHead :call <SID>PushToFrontInMRU(
      \ (<f-args> !~ '^\d\+$') ? bufnr(<f-args>) : <f-args>, 1)
command! -nargs=1 SBBufToTail :call <SID>PushToBackInMRU(
      \ (<f-args> !~ '^\d\+$') ? bufnr(<f-args>) : <f-args>, 1)
" Command to change settings interactively.
command! -nargs=0 SBSettings :call <SID>SBSettings()

" The main plug-in mapping.
noremap <script> <silent> <Plug>SelectBuf :call <SID>ListBufs()<CR>

" Deleting autocommands first is a good idea especially if we want to reload
"   the script without restarting vim.
aug SelectBuf
  au!
  au BufWinEnter * :call <SID>BufWinEnter()
  au BufWinLeave * :call <SID>BufWinLeave()
  au BufWipeout * :call <SID>BufWipeout()
  au BufDelete * :call <SID>BufDelete()
  au BufAdd * :call <SID>BufAdd()
  au BufNew * :call <SID>BufNew()
aug END

endfunction " -- Initialize }}}

" Do the actual initialization.
call s:Initialize()

" One-time initialization of some script variables {{{
" These are typically those that save the state are some constants which are
"   not impacted directly by user.
" This is the current buffer when the browser is invoked ('%').
let s:originalCurBuffer = 1
" This is the alternate buffer when the browser is invoked ('#').
let s:originalAltBuffer = 1
" The size of the current header. Used for mapping file names to buffer
"   numbers when buffer numbers are hidden.
let s:headerSize = 0
let s:myBufNum = -1
let s:savedSearchString = ""
" The operating mode for the current session. This is reset after the browser
"   is closed. Ideally, we assume that the browser is open in only one window.
let s:opMode = ""

let s:sortByNumber=0
let s:sortByName=1
let s:sortByPath=2
let s:sortByType=3
let s:sortByIndicators=4
let s:sortByMRU=5
let s:sortByMaxVal=5

let s:sortdirlabel  = ""

let s:pendingUpdAxns = ""
let s:auSuspended = 1 " Disable until we are ready.
let s:bufList = ""
let s:indList = ""

let s:settings = 'AlwaysHideBufNums,AlwaysShowDetails,AlwaysShowHelp,' .
      \ 'AlwaysShowHidden,AlwaysShowPaths,BrowserMode,DefaultSortDirection,' .
      \ 'DefaultSortOrder,DelayedDynUpdate,DisableMRUlisting,DisableSummary,' .
      \ 'EnableDynUpdate,HighlightOnlyFilename,IgnoreNonFileBufs,' .
      \ 'RestoreWindowSizes,SplitType,UseVerticalSplit,DoFileOnClose'
" Map of global variable name to the local variable that are different than
"   their global counterparts.
let s:settingsMap{'DefaultSortOrder'} = 'sorttype'
let s:settingsMap{'DefaultSortDirection'} = 'sortdirection'
let s:settingsMap{'AlwaysShowHelp'} = 'showHelp'
let s:settingsMap{'AlwaysShowHidden'} = 'showHidden'
let s:settingsMap{'AlwaysShowDetails'} = 'showDetails'
let s:settingsMap{'AlwaysShowPaths'} = 'showPaths'
let s:settingsMap{'AlwaysHideBufNums'} = 'hideBufNums'

" This is the list maintaining the MRU order of buffers.
let s:MRUlist = ''

"let g:SB_MESSAGES = ''

function! s:MyScriptId()
  map <SID>xx <SID>xx
  let s:sid = maparg("<SID>xx")
  unmap <SID>xx
  return substitute(s:sid, "xx$", "", "")
endfunction
let s:myScriptId = s:MyScriptId()
delfunction s:MyScriptId

let s:optMRUfullUpdate = 1
" One-time initialization of some script variables }}}
" Initializations }}}


"
" Functions start from here.
"

" ListBufs: Main User entry function. {{{

function! s:ListBufs()
  " First check if the browser window is already visible.
  let browserWinNo = bufwinnr(s:myBufNum)

  " We need to update these before we switch to the browser window.
  if browserWinNo != winnr()
    let s:originalCurBuffer = bufnr("%")
    let s:originalAltBuffer = bufnr("#")
  endif

  call s:SuspendAutoUpdates('ListBufs')

  call s:GoToBrowserWindow(browserWinNo)
  call s:UpdateBuffers(0) " It will do a full refresh if required.
  if s:opMode == 'WinManager'
    call WinManagerForceReSize('SelectBuf')
  else
    call s:AdjustWindowSize()
  endif
  call s:ResumeAutoUpdates()

  if s:opMode == 'user' && s:browserMode != 'keep'
    if s:savedSearchString != ''
      let @/ = s:savedSearchString
    endif
    let s:savedSearchString = histget('search')
    call histadd("search", @/) " Ignores the call if it is empty.

    " Arrange a notification of the window close on this window.
    call AddNotifyWindowClose(s:windowName, s:myScriptId . "RestoreWindows")
  endif
endfunction " ListBufs


function! s:AutoListBufs()
  if s:AUSuspended()
    return
  endif
  " If opMode is empty, it means the browser window entered through backdoor
  " (by e#<browserBufNumber> e.g.)
  if s:opMode == ""
    let s:opMode = 'auto'
  endif
  let s:quiteWinEnter = 0
  call s:ListBufs()
endfunction

" ListBufs }}}


" Buffer Update {{{
" Header {{{
function! s:UpdateHeader()
  setlocal modifiable

  " Remember the position.
  call SaveSoftPosition("UpdateHeader")
  if search('^"= ', 'w')
    silent! 1,.delete _
  endif

  call s:AddHeader()
  call search('^"= ', "w")
  let s:headerSize = line(".")

  if s:opMode == 'WinManager'
    call WinManagerForceReSize('SelectBuf')
  else
    call s:AdjustWindowSize()
  endif

  " Return to the original position.
  call RestoreSoftPosition("UpdateHeader")

  setlocal nomodifiable
endfunction " UpdateHeader

function s:MapArg(key)
  return maparg('<Plug>SelBuf' . a:key)
endfunction

function! s:AddHeader()
  let helpMsg=""
  let helpKey = maparg("<Plug>SelBufTHelpKey")
  if s:showHelp
    let helpMsg = helpMsg
      \ . "\" " . s:MapArg("SelectKey") . " or " . s:MapArg("MSelectKey") .
      \	    " : open current buffer\n"
      \ . "\" " . s:MapArg("WSelectKey") . "/" . s:MapArg("OpenKey") .
      \	    " : open buffer in a new/previous window\n"
      \ . "\" " . s:MapArg("DeleteKey") . " : delete/undelete current buffer\t"
      \	    . s:MapArg("WipeOutKey") . " : wipeout current buffer\n"
      \ . "\" " . s:MapArg("TDetailsKey") . " : toggle additional details\t\t" .
      \	    s:MapArg("TBufNumsKey") . " : toggle show buffer numbers\n"
      \ . "\" " . s:MapArg("THidePathsKey") . " : toggle show paths\t\t\t" .
      \	    s:MapArg("THiddenKey") . " : toggle hidden buffers\n"
      \ . "\" " . s:MapArg("RefreshKey") . " : refresh browser\t\t\t" .
      \	    s:MapArg("QuitKey") . " : close browser\n"
      \ . "\" " . s:MapArg("SortSelectFKey") . "/" . s:MapArg("SortSelectBKey")
      \	    . " : select sort field for/backward\t" . s:MapArg("SortRevKey") .
      \	    " : reverse sort\n"
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
              \ ",showHidden=" . s:showHidden . ",showPaths=" . s:showPaths .
	      \ ",hideBufNums=" . s:hideBufNums .
              \ "\n"
  0
  " Silence a vim internal error about undo buffer. There seems to be no other
  "   side effects.
  silent! put! =helpMsg
endfunction " AddHeader
" Header }}}

" UpdateBuffers {{{
function! s:UpdateBuffers(fullUpdate)
  call s:SetupBuf()

  " If this is the first time we are updating the buffer, we need to do
  " everything from scratch.
  if getline(1) == "" || a:fullUpdate || ! s:enableDynUpdate
    call s:FullUpdate()
  else
    call s:IncrementalUpdate()
  endif
endfunction " UpdateBuffers

function! s:AutoUpdateBuffers(fullUpdate)
  if s:AUSuspended()
    return
  endif

  call s:UpdateBuffers(a:fullUpdate)
endfunction
" }}}

function! s:ShouldShowBuffer(bufNr) " {{{
  let showBuffer = 1
  if bufexists(a:bufNr)
    " If user wants to hide hidden buffers.
    if s:ignoreNonFileBufs && getbufvar(a:bufNr, '&buftype') != ''
      let showBuffer = 0
    elseif ! s:showHidden && ! buflisted(a:bufNr)
      let showBuffer = 0
    endif
  else
    let showBuffer = 0
  endif
  return showBuffer
endfunction " }}}

function! s:FullUpdate() " {{{
  setlocal modifiable

  " Go as far as possible in the undo history to conserve Vim resources.
  let i = 0
  while line('$') != 1 && i < &undolevels
    silent! undo
    let i = i + 1
  endwhile
  " Delete the contents if there are still any.
  silent! 0,$delete _

  call s:AddHeader()
  silent! $delete _ " Delete one empty extra line at the end.
  let s:headerSize = line("$")

  $
  " Loop over all the buffers.
  let nBuffers = 0
  let nBuffersShown = 0
  let newLine = ""
  let showBuffer = 0
  let s:bufList = ""
  let lastBufNr = bufnr('$')
  if s:optMRUfullUpdate && s:GetSortNameByType(s:sorttype) == 'mru'
    let i = s:NextBufInMRU()
  else
    let i = 1
  endif
  while i <= lastBufNr
    let newLine = ""
    if s:ShouldShowBuffer(i)
      let s:bufList = s:bufList . i . "\n"
      let newLine = s:GetBufLine(i)
      silent! call append(line("$"), newLine)
      let nBuffersShown = nBuffersShown + 1
    endif
    let nBuffers = nBuffers + 1
    if s:optMRUfullUpdate && s:GetSortNameByType(s:sorttype) == 'mru'
      let i = s:NextBufInMRU()
    else
      let i = i + 1
    endif
  endwhile

  if line("$") != s:headerSize
    " Finally sort the listing based on the current settings.
    if (!s:optMRUfullUpdate || s:GetSortNameByType(s:sorttype) != 'mru') &&
	  \ s:GetSortNameByType(s:sorttype) != 'number'
      call s:SortBuffers(0)
    endif

    if s:hideBufNums
      call s:RemoveBufNumbers()
    endif
  endif

  call s:MarkBuffers()

  " Since we did a full refresh, we shouldn't need them.
  let s:pendingUpdAxns = ""

  if search('^"= ', "w")
    +
  endif

  if ! s:disableSummary
    redraw | echohl SelBufSummary |
	  \ echo "Total buffers: " . nBuffers . " Showing: " . nBuffersShown |
	  \ echohl None
  endif
  setlocal nomodifiable
endfunction " FullUpdate " }}}

" Incremental update support {{{
function! s:IncrementalUpdate()
  " If there are no pending updates, then we don't have to do anything.
  if s:pendingUpdAxns == ""
    return
  endif

  call SaveSoftPosition("IncrementalUpdate")

  if search('^"= ', 'w') != 0
    let s:headerSize = line('.')
  endif

  if s:hideBufNums
    call s:AddBufNumbers()
  endif

  setlocal modifiable

  call MvIterCreate(s:pendingUpdAxns, ',', 'SelectBufUpdateAxns')
  while MvIterHasNext('SelectBufUpdateAxns')
    let nextAxn = MvIterNext('SelectBufUpdateAxns')
    let bufNo = nextAxn + 0
    let action = nextAxn[strlen(nextAxn) - 1] " Last char.

    " For delete, skip when we are showing hidden buffers but not details.
    if action == 'd' && s:showHidden && ! s:showDetails
      continue
      " For create, skip when the buffer is hidden and we don't show hidden
      " buffers.
    elseif action == 'c' && ! s:showHidden && ! buflisted(bufNo)
      continue
    endif

    if search('^' . bufNo . '\>', 'w') > 0
      if action == 'u' || (action == 'd' && s:showHidden)
	call setline('.', s:GetBufLine(bufNo))
	continue
      else
	silent! .delete _
      endif
    endif
    if action == 'c' || action == 'm'
      let bufLine = s:GetBufLine(bufNo)
      let lineNoToInsert = BinSearchForInsert(s:headerSize + 1, line("$"),
	    \ bufLine, s:GetSortCmpFnByType(s:GetSortTypeByName(s:sorttype)),
	    \ s:sortdirection)
      silent! call append(lineNoToInsert, bufLine)
    endif
  endwhile
  call MvIterDestroy('SelectBufUpdateAxns')
  let s:pendingUpdAxns = ""

  call s:MarkBuffers()

  setlocal nomodifiable

  if s:hideBufNums
    call s:RemoveBufNumbers()
  endif

  call RestoreSoftPosition("IncrementalUpdate")
  normal zb
endfunction " IncrementalUpdate

" action:
"   c - buffer added (add line).
"   d - buffer deleted (remove only if !showHidden and update otherwise).
"   w - buffer wipedout (remove in any case).
"   u - needs an update.
"   m - needs to be moved (remove and add back).
function! s:DynUpdate(action, bufNum, ovrrdDelayDynUpdate)
  let bufNo = a:bufNum
  if bufNo == -1 || bufNo == s:myBufNum || s:AUSuspended()
    return
  endif
  if s:ignoreNonFileBufs && getbufvar(bufNo, '&buftype') != ''
    return
  endif

  let ignore = 0
  if (a:action == 'u' || a:action == 'm') &&
	\ MvContainsPattern(s:pendingUpdAxns, ',', bufNo . 'c')
    let ignore = 1
  elseif a:action == 'w'
    while 1
      let pendingUpdAxns = s:pendingUpdAxns
      let s:pendingUpdAxns = MvRemovePattern(s:pendingUpdAxns, ',',
	    \ bufNo . '\a')
      if pendingUpdAxns == s:pendingUpdAxns
	break
      endif
    endwhile
  elseif MvContainsPattern(s:pendingUpdAxns, ',', bufNo . a:action)
    let ignore = 1
  endif
  if ! ignore
    let s:pendingUpdAxns = s:pendingUpdAxns . bufNo . a:action. ',' 
  endif

  " Update the previous alternative buffer.
  let s:originalCurBuffer = bufnr("%")
  let saveAltBuf = s:originalAltBuffer
  let s:originalAltBuffer = bufnr("#")
  if s:showDetails && saveAltBuf != s:originalAltBuffer
    let s:pendingUpdAxns = s:pendingUpdAxns . saveAltBuf . 'u,'
  endif

  let browserWinNo = bufwinnr(s:myBufNum)
  if ! s:delayedDynUpdate && browserWinNo != -1 && ! s:AUSuspended() &&
	\ s:pendingUpdAxns != '' && !a:ovrrdDelayDynUpdate
    if s:opMode != 'WinManager' || !WinManagerAUSuspended()
      " CAUTION: Using bufnr('%') is not reliable in the case of ":split new".
      "	  By the time the BufAdd even is fired, the window is already created,
      "	  but the bufnr() still gives the old buffer number. Using winnr()
      "	  alone seems to work well.
      "let prevFile = bufnr('%')
      let prevWin = winnr() " Backup.
      call s:ListBufs()
      "let win = bufwinnr(prevFile)
      "if win == -1
	let win = prevWin
      "endif
      call s:GoToWindow(win)
    endif
  endif
endfunction
" Incremental update support }}}

" Event handlers {{{
function! s:BufWinEnter()
  call s:PushToFrontInMRU(expand("<abuf>") + 0, 0)
  " FIXME: In case of :e#, the alternate buffer must have got updated because
  "   of a BufWinLeave event, but it looks like this buffer still appears as
  "   the current and active buffer at that time, so details will show
  "   incorrect information. As a workaround, update this buffer again.
  call s:DynUpdate('u', bufnr('#') + 0, 0)
endfunction

function! s:BufWinLeave()
  call s:DynUpdate('u', expand("<abuf>") + 0, 1)
endfunction

function! s:BufWipeout()
  call s:DelFromMRU(expand("<abuf>") + 0)
  if s:enableDynUpdate
    call s:DynUpdate('w', expand("<abuf>") + 0, 0)
  endif
endfunction

function! s:BufDelete()
  if s:enableDynUpdate
    call s:DynUpdate('d', expand("<abuf>") + 0, 0)
  endif
endfunction

function! s:BufNew()
  if ! s:disableMRUlisting
    call s:AddToMRU(expand("<abuf>") + 0)
  endif
endfunction

function! s:BufAdd()
  if s:enableDynUpdate
    call s:DynUpdate('c', expand("<abuf>") + 0, 0)
  endif
endfunction
" Event handlers }}}
" Buffer Update }}}


" Buffer line operations {{{

" Add/Remove buffer/indicators numbers {{{
function! s:RemoveBufNumbers()
  let s:bufList = s:RemoveColumn(1)
endfunction " RemoveBufNumbers


function! s:AddBufNumbers()
  call s:AddColumn(1, s:bufList)
endfunction " AddBufNumbers

"function! s:RemoveIndicators()
"  let s:indList = s:RemoveColumn(2)
"endfunction " RemoveIndicators
"
"
"function! s:AddIndicators()
"  call s:AddColumn(2, s:indList)
"endfunction " AddIndicators

function! s:RemoveColumn(colNum)
  if line("$") == s:headerSize
    return
  endif
  0
  call search('^"= ', "w")
  +
  let _unnamed = @"
  let _z = @z
  setlocal modifiable
  " Position correctly.
  exec "normal! 0"
  let colNum = a:colNum
  if s:hideBufNums && colNum > 1
    let colNum = colNum - 1
  endif
  if colNum != 1
    "let oldvcol = virtcol('.')
    " TODO: Doesn't work for last column, but not required right now.
    silent! exec "normal! " . (colNum - 1) . "f\<Tab>l"
  endif
  silent! exec "normal! \<C-V>Gf\<Tab>\"zd"
  setlocal nomodifiable
  let block = @z
  let @z = _z
  let @" = _unnamed
  return block
endfunction " RemoveColumn

function! s:AddColumn(colNum, block)
  if line("$") == s:headerSize || a:block == ""
    return
  endif
  let _unnamed = @"
  let _z = @z
  setlocal modifiable
  silent! $put =a:block
  silent! exec "normal! \<C-V>G$\"zyu"
  0
  call search('^"= ', "w")
  +
  exec "normal! 0"
  let colNum = a:colNum
  if s:hideBufNums && colNum > 1
    let colNum = colNum - 1
  endif
  if colNum == 1
    exec "normal! P"
  else
    silent! exec "normal! " . (colNum - 1) . "f\<Tab>p"
  endif
  setlocal nomodifiable
  let @z = _z
  let @" = _unnamed
endfunction " AddColumn
" Add/Remove buffer/indicators numbers }}}


" GetBufLine {{{
function! s:GetBufLine(bufNum, ...)
  if a:bufNum == -1
    return ""
  endif
  let newLine = ""
  let newLine = newLine . a:bufNum . "\t"
  " If user wants to see more details.
  if s:showDetails || a:0
    if !buflisted(a:bufNum)
      let newLine = newLine . "u"
    else
      let newLine = newLine . " "
    endif

    " Alternate buffer is more reliable than current when switching windows
    " (BufWinLeave comes first and the # buffer is already changed by then,
    " not the % buffer).
    if s:originalAltBuffer == a:bufNum
      let newLine = newLine . "#"
    elseif s:originalCurBuffer == a:bufNum
      let newLine = newLine . "%"
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
    if getbufvar(a:bufNum, "&modifiable") == 0 || s:myBufNum == a:bufNum
      let newLine = newLine . "-"
    elseif getbufvar(a:bufNum, "&readonly") == 1
      let newLine = newLine . "="
    else
      let newLine = newLine . " "
    endif

    " Special case for "my" buffer as I am finally going to be
    "  non-modified, anyway.
    if getbufvar(a:bufNum, "&modified") == 1 && a:bufNum != s:myBufNum
      let newLine = newLine . "+"
    else
      let newLine = newLine . " "
    endif
    let newLine = newLine . "\t"
  endif
  if s:showPaths || a:0
    let bufName = bufname(a:bufNum)
  else
    " TODO: expand('#'.a:bufNum.':t') also works here, have to check which is
    " better.
    let bufName = fnamemodify(bufname(a:bufNum), ":t")
  endif
  if bufName == ""
    let bufName = "[No File]"
  endif
  let newLine = newLine . bufName
  return newLine
endfunction
" GetBufLine }}}


function! s:SelectCurrentBuffer(openMode) " {{{
  if search("^\"= ", "W") != 0
    +
    return
  endif

  let selBufNum = s:GetCurrentBufferNumber()
  if selBufNum == -1
    +
    return
  endif

  " If running under WinManager, let it open the file.
  if s:opMode == 'WinManager'
    call WinManagerFileEdit(selBufNum, a:openMode)
    return
  endif

  let didQuit = 0
  if a:openMode == 2
    " Behaves temporarily like "keep"
    wincmd p
  elseif a:openMode == 1
    " We will just skip calling Quit() here, because we will change to the
    " selected buffer anyway soon.
    let s:opMode = 'auto'
  else
    let didQuit = s:Quit(1)
  endif

  " If we are not quitting the window, then there is no point trying to restore
  "   the window settings.
  if ! didQuit && s:browserMode == "split"
    call RemoveNotifyWindowClose(s:windowName)
    call ResetWindowSettings2(s:myScriptId)
  endif

  let v:errmsg = ""
  silent! exec "buffer" selBufNum

  " E325 is the error message that you see when the file is curerntly open in
  "   another vim instance.
  if v:errmsg != "" && v:errmsg !~ '^E325: ATTENTION'
    split
    exec "buffer" selBufNum
    redraw | echohl Error |
       \ echo "Couldn't open buffer " . selBufNum .
       \   " in window " . winnr() ", creating a new window." |
       \ echo "Error Message: " . v:errmsg |
       \ echohl None
  endif
endfunction " SelectCurrentBuffer }}}


" Buffer Deletions {{{
function! s:DeleteBuffers(wipeout) range
  if s:opMode == 'WinManager'
    call WinManagerSuspendAUs()
  endif

  if s:hideBufNums
    call s:AddBufNumbers()
  endif

  call SaveHardPosition('DeleteBuffers')

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
  call s:SuspendAutoUpdates('DeleteBuffers')
  setlocal modifiable
  silent! execute line
  while line <= a:lastline
    let selectedBufNum = s:GetCurrentBufferNumber()
    if selectedBufNum != -1
      if a:wipeout
        exec "bwipeout" selectedBufNum
        let nWipedout = nWipedout + 1
        let wipedoutMsg = wipedoutMsg . " " . selectedBufNum
	silent! delete _
      elseif buflisted(selectedBufNum)
        exec "bdelete" selectedBufNum
        if ! s:showHidden
	  silent! delete _
        else
	  call setline('.', s:GetBufLine(selectedBufNum))
	  silent! +
        endif
        let nDeleted = nDeleted + 1
        let deletedMsg = deletedMsg . " " . selectedBufNum
      else
        " Undelete buffer.
        call setbufvar(selectedBufNum, "&buflisted", "1")
        call setline('.', s:GetBufLine(selectedBufNum))
	silent! +
        let nUndeleted = nUndeleted + 1
        let undeletedMsg = undeletedMsg . " " . selectedBufNum
      endif
    endif
    let line = line + 1
  endwhile
  call s:ResumeAutoUpdates()
  setlocal nomodifiable

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

  if s:hideBufNums
    call s:RemoveBufNumbers()
  endif

  call RestoreHardPosition('DeleteBuffers')

  redraw | echo msg
  "call input(msg)

  if s:opMode == 'WinManager'
    call WinManagerResumeAUs()
  endif
endfunction " DeleteBuffers


function! s:GetDeleteMsg(nBufs, msg)
  let msg = a:nBufs . ((a:nBufs > 1) ? " buffers: " : " buffer: ") .
          \ a:msg
  return msg
endfunction
" Buffer Deletions }}}

" Buffer line operations }}}


" Buffer Setup/Cleanup {{{

function! s:SetupBuf() " {{{
  call SetupScratchBuffer()
  setlocal noreadonly " Or it shows [RO] after the buffer name, not nice.
  setlocal nowrap
  setlocal nonumber
  setlocal foldcolumn=0
  setlocal tabstop=8
  if s:enableDynUpdate
    setlocal bufhidden=hide
  else
    setlocal bufhidden=delete
  endif

  " Add autocommands for automatically updating the buffer when the browser
  " buffer is made visible by other means.
  aug SelectBufAutoUpdate
  au!
  exec "au BufWinEnter " . escape(s:windowName, '\[*^$. ') .
        \ " :call <SID>AutoListBufs()"
  exec "au BufWinLeave " . escape(s:windowName, '\[*^$. ') .
        \ " :call <SID>Done()"
  exec "au WinEnter " . escape(s:windowName, '\[*^$. ') .
        \ " :call <SID>AutoUpdateBuffers(0)"
  aug END

  " Start syntax rules. {{{
  "" 

  " Do only if they are not already done, may save some time.
  "if hlID("SelBufMapping") == 0

  " The mappings in the help header.
  syn match SelBufMapping "\s\(\i\|[ /<>-]\)\+ : " contained
  syn match SelBufHelpLine "^\" .*$" contains=SelBufMapping

  " The starting line. Summary of current settings.
  syn keyword SelBufKeyWords Sorting showDetails showHidden showDirs showPaths bufNameOnly hideBufNums contained
  syn region SelBufKeyValues start=+=+ end=+,+ end=+$+ skip=+ + contained
  syn match SelBufKeyValuePair +\i\+=\i\++ contained contains=SelBufKeyWords,SelBufKeyValues
  syn match SelBufSummary "^\"= .*$" contains=SelBufKeyValuePair

  syn match SelBufBufLine "^[^"].*$" contains=SelBufBufNumber,SelBufBufIndicators,SelBufBufName
  syn match SelBufBufNumber "^\d\+" contained
  syn match SelBufBufIndicators "\t[^\t]*\t" contained
  if s:highlightOnlyFilename
    syn match SelBufBufName "\([^/\\\t]\{-1,}\)$" contained
  else
    syn match SelBufBufName "\(\p\| \)*$" contained
  endif


  hi def link SelBufHelpLine      Comment
  hi def link SelBufMapping       Special

  hi def link SelBufSummary       Statement
  hi def link SelBufKeyWords      Keyword
  hi def link SelBufKeyValues     Constant

  hi def link SelBufBufNumber     Constant
  hi def link SelBufBufIndicators Label
  hi def link SelBufBufName       Directory

  hi def link SelBufSummary       Special

  "endif

  "
  " End Syntax rules. }}}

  " Maps {{{
  call s:DefMap("n", "SelectKey", "<CR>", ":SBSelect<CR>")
  call s:DefMap("n", "MSelectKey", "<2-LeftMouse>", ":SBSelect<CR>")
  call s:DefMap("n", "WSelectKey", "<C-W><CR>", ":SBWSelect<CR>")
  call s:DefMap("n", "OpenKey", "O", ":SBOpen<CR>")
  call s:DefMap("n", "DeleteKey", "d", ":SBDelete<CR>")
  call s:DefMap("n", "WipeOutKey", "D", ":SBWipeout<CR>")
  call s:DefMap("v", "DeleteKey", "d", ":SBDelete<CR>")
  call s:DefMap("v", "WipeOutKey", "D", ":SBWipeout<CR>")
  call s:DefMap("n", "TDetailsKey", "i", ":SBTDetails<CR>")
  call s:DefMap("n", "THiddenKey", "u", ":SBTHidden<CR>")
  call s:DefMap("n", "TBufNumsKey", "p", ":SBTBufNums<CR>")
  call s:DefMap("n", "THidePathsKey", "P", ":SBTPaths<CR>")
  call s:DefMap("n", "RefreshKey", "R", ":SBRefresh<CR>")
  call s:DefMap("n", "SortSelectFKey", "s", ":SBFSort<cr>")
  call s:DefMap("n", "SortSelectBKey", "S", ":SBBSort<cr>")
  call s:DefMap("n", "SortRevKey", "r", ":SBRSort<cr>")
  call s:DefMap("n", "QuitKey", "q", ":SBQuit<CR>")
  call s:DefMap("n", "THelpKey", "?", ":SBTHelp<CR>")
  call s:DefMap("n", "ShowSummaryKey", "<C-G>", ":SBSummary<CR>")

  if ! s:disableSummary
    nnoremap <silent> <buffer> j j:call <SID>EchoCurrentBufferName()<CR>
    nnoremap <silent> <buffer> k k:call <SID>EchoCurrentBufferName()<CR>
    nnoremap <silent> <buffer> <Up> <Up>:call <SID>EchoCurrentBufferName()<CR>
    nnoremap <silent> <buffer> <Down>
	  \ <Down>:call <SID>EchoCurrentBufferName()<CR>
    nnoremap <silent> <buffer> <LeftMouse>
	  \ <LeftMouse>:call <SID>EchoCurrentBufferName()<CR>
  else
    let _errmsg = v:errmsg
    silent! nunmap <buffer> j
    silent! nunmap <buffer> k
    silent! nunmap <buffer> <Up>
    silent! nunmap <buffer> <Down>
    silent! nunmap <buffer> <LeftMouse>
    let v:errmsg = _errmsg
  endif
  " Maps }}}

  " Commands {{{ 
  " Toggle the same key to mean "Close".
  nnoremap <buffer> <silent> <Plug>SelectBuf :call <SID>Quit(0)<CR>

  " Define some local command too for the ease of debugging.
  command! -nargs=0 -buffer SBSelect :call <SID>SelectCurrentBuffer(0)
  command! -nargs=0 -buffer SBOpen :call <SID>SelectCurrentBuffer(2)
  command! -nargs=0 -buffer SBWSelect :call <SID>SelectCurrentBuffer(1)
  command! -nargs=0 -buffer -range SBDelete :<line1>,<line2>call <SID>DeleteBuffers(0)
  command! -nargs=0 -buffer -range SBWipeout :<line1>,<line2>call <SID>DeleteBuffers(1)
  command! -nargs=0 -buffer SBFSort :call <SID>SortSelect(1)
  command! -nargs=0 -buffer SBBSort :call <SID>SortSelect(-1)
  command! -nargs=0 -buffer SBRSort :call <SID>SortReverse()
  command! -nargs=0 -buffer SBQuit :call <SID>Quit(0)
  command! -nargs=0 -buffer SBTHelp :call <SID>ToggleHelpHeader()
  command! -nargs=0 -buffer SBTBufNums :call <SID>ToggleHideBufNums()
  command! -nargs=0 -buffer SBTHidden :call <SID>ToggleHidden()
  command! -nargs=0 -buffer SBTDetails :call <SID>ToggleDetails()
  command! -nargs=0 -buffer SBTPaths :call <SID>ToggleHidePaths()
  command! -nargs=0 -buffer SBRefresh :call <SID>UpdateBuffers(1)
  command! -nargs=0 -buffer SBSummary :echohl SelBufSummary |
	\ echo <SID>GetBufLine(<SID>GetCurrentBufferNumber(), 1) |
	\ echohl NONE
  " Commands }}} 
endfunction " SetupBuf }}}


" Routing browser quit through this function gives a chance to decide how to
"   do the exit.
" Returns 1 when the browser window is really quit. 
function! s:Quit(scriptOrigin) " {{{
  " When the browser should be left open, switch to the previously used window
  "   instead of quitting the window.
  " The user can still use :q commnad to force a quit.
  if s:opMode == 'WinManager' || s:browserMode == 'keep'
    " Switch to the most recently used window.
    if s:opMode == 'WinManager'
      let prevWin = bufwinnr(WinManagerGetLastEditedFile())
      if prevWin != -1
	if s:quiteWinEnter " When previously entered using activation key.
	  call s:GoToWindow(prevWin)
	else
	  exec prevWin . 'wincmd w'
	endif
      endif
    else
      wincmd p
    endif
    return 0
  endif

  let didQuit = 0
  " If opMode is empty or 'auto', the browser might have entered through some
  "   back-door mechanism. We don't want to exit the window in this case.
  if s:browserMode == "switch" || s:opMode == 'auto' || s:opMode == ''
    " Switch browser even when the dynamic update is on, as it will allow us
    "	preserve the contents of the browser as we want.
    if ! a:scriptOrigin || s:enableDynUpdate
      e#
    endif

  " In any case, if there is only one window, then don't quit.
  elseif NumberOfWindows() > 1
    let v:errmsg = ""
    if s:enableDynUpdate
      hide
    else
      silent! quit
    endif
    if v:errmsg == ""
      let didQuit = 1
    endif

  " Give warning only when the user wanted to quit.
  elseif ! a:scriptOrigin
    redraw | echohl WarningMsg | echo "Can't quit the last window" |
	  \ echohl NONE
  endif

  if didQuit && s:doFileOnClose
    file
  endif

  return didQuit
endfunction " Quit }}}


" This is the function that gets always called no matter how we do the exit
"   from the browser, giving us a chance to do last minute cleanup.
function! s:Done() " {{{
  if s:AUSuspended()
    return
  endif

  " Clear up such that it gets set correctly the next time.
  let s:opMode = ''

  " Never cleanup when started by WinManager or in keep mode.
  if s:opMode == 'WinManager' || s:browserMode == 'keep'
    return
  endif

  call s:RestoreSearchString()
endfunction " Done }}}


function! s:RestoreWindows(dummyTitle) " {{{
  " If user wants us to restore window sizes during the exit.
  if s:restoreWindowSizes && s:browserMode != "keep"
    call RestoreWindowSettings2(s:myScriptId)
  endif
endfunction " }}}


function! s:RestoreSearchString() " {{{
  if s:savedSearchString != ''
    let @/ = s:savedSearchString " This doesn't modify the history.
    let s:savedSearchString = histget("search")
    " Fortunately, this will make sure there is only one copy in the history.
    call histadd("search", @/)
  endif
endfunction " }}}


function! s:DefMap(mapType, mapKeyName, defaultKey, cmdStr) " {{{
  let key = maparg('<Plug>SelBuf' . a:mapKeyName)
  " If user hasn't specified a key, use the default key passed in.
  if key == ""
    let key = a:defaultKey
  endif
  exec a:mapType . "noremap <buffer> <silent> " . key a:cmdStr
endfunction " DefMap " }}}

" Buffer Setup/Cleanup }}}


" Utility methods. {{{
"

function! s:AdjustWindowSize() " {{{
  call SaveSoftPosition('AdjustWindowSize')
  " Set the window size to one more than just required.
  0
  " For vertical split, we shouldn't adjust the number of lines.
  if NumberOfWindows() != 1 && ! s:useVerticalSplit
    let size = (line("$") + 1)
    if size > (&lines / 2)
      let size = &lines/2
    endif
    exec "resize" . size
  endif
  call RestoreSoftPosition('AdjustWindowSize')
endfunction " }}}


" Suspend/Resume AUs{{{
function! s:SuspendAutoUpdates(dbgTag)
  " To make it reentrant.
  if !exists("s:_lazyredraw")
    let s:auSuspended = 1
    let s:dbgSuspTag = a:dbgTag
    if s:opMode == 'WinManager'
      call WinManagerSuspendAUs()
    endif
    let s:_lazyredraw = &lazyredraw
    set lazyredraw
    let s:_report = &report
    set report=99999
  endif
endfunction

function! s:ResumeAutoUpdates()
  " To make it reentrant.
  if exists("s:_lazyredraw")
    let &report = s:_report
    let &lazyredraw = s:_lazyredraw
    unlet s:_lazyredraw
    if s:opMode == 'WinManager'
      call WinManagerResumeAUs()
    endif
    let s:auSuspended = 0
    let s:dbgSuspTag = ''
  endif
endfunction

function! s:AUSuspended()
  return s:auSuspended
endfunction
" }}}


function! s:GetCurrentBufferNumber() " {{{
  if s:hideBufNums
    let bufIndex = line(".") - s:headerSize - 1
    let bufNo = MvElementAt(s:bufList, "\t\n", bufIndex)
    if bufNo == ""
      return -1
    else
      return bufNo + 0
    endif
  else
    return s:GetBufferNumber(getline("."))
  endif
endfunction " }}}


function! s:GetBufferNumber(line) " {{{
  let bufNumber = matchstr(a:line, '^\d\+')
  if bufNumber == ""
    return -1
  endif
  return bufNumber + 0 " Convert it to number type.
endfunction " }}}


function! s:EchoCurrentBufferName() " {{{
  let bufNumber = s:GetCurrentBufferNumber()
  if bufNumber != -1
    let bufName = expand('#'.bufNumber.':p')
    if bufName == ''
      let bufName = '[No File]'
    endif
    echohl SelBufSummary | echo "Buffer: " . bufName | echohl NONE
  endif
endfunction " }}}


" GoToBrowserWindow {{{
" Place holder function for any future manipulation of window while taking
" focus into the browser window.
function! s:GoToBrowserWindow(browserWinNo)
  if winnr() != a:browserWinNo
    if a:browserWinNo != -1
      call s:GoToWindow(a:browserWinNo)
      let s:quiteWinEnter = 1
    else
      let s:opMode = 'user'

      " If user wants us to save window sizes and restore them later.
      " But don't save unless "split" mode, as otherwise we are not creating a
      "   new window.
      if s:restoreWindowSizes && s:browserMode == "split"
	call SaveWindowSettings2(s:myScriptId, 1)
      endif

      " Don't split window for "switch" mode.
      let splitCommand = ""
      if s:browserMode != "switch"
	" If user specified a split type, use that.
	let splitCommand = splitCommand .  s:splitType
	if s:useVerticalSplit
	  let splitCommand = splitCommand . " vert "
	endif
	let splitCommand = splitCommand . " split"
      endif
      exec splitCommand
      if s:useVerticalSplit
	25wincmd |
      endif
      " Find if there is a buffer already created.
      if s:myBufNum != -1
	" Switch to the existing buffer.
	exec "buffer " . s:myBufNum
      else
	" Create a new buffer.
	" Temporarily modify isfname to avoid treating the name as a pattern.
	let _isf = &isfname
	set isfname-=\
	set isfname-=[
	exec ":e \\" . escape(s:windowName, ' ')
	let &isfname = _isf
	let s:myBufNum = bufnr('%')
      endif
    endif
  endif
endfunction

function! s:GoToWindow(winNr)
  if winnr() != a:winNr
    let _eventignore = &eventignore
    set eventignore+=WinEnter,WinLeave
    exec a:winNr . 'wincmd w'
    let &eventignore = _eventignore
  endif
endfunction
" }}}

function! s:SBSettings() " {{{
  let selectedSetting = MvPromptForElement2(s:settings, ',', -1,
	\ "Select the setting: ", -1, 0, 3)
  if selectedSetting != ""
    let oldVal = ''
    let localVar = substitute(selectedSetting, '^\(\u\)', '\L\1', '')
    if exists("s:" . localVar)
      exec "let oldVal = s:" . localVar . " . '' "
    else
      silent! exec "let oldVal = s:settingsMap{selectedSetting}"
      if oldVal != ''
	exec "let oldVal = s:" . oldVal . " . '' "
      else
	echoerr "Internal error detected, couldn't locate value for " .
	      \ selectedSetting
      endif
    endif
    let newVal = input("Current value for " . selectedSetting . " is: " .
	  \ oldVal . "\nEnter new value: ", oldVal)
    if newVal != oldVal
      exec "let g:selBuf" . selectedSetting . " = '" . newVal . "'"
      call s:Initialize()
    endif
  endif
endfunction " }}}

function! s:MarkBuffers() " {{{
  " Find current, next and previous buffers.
  if search('^' . s:originalCurBuffer . '\>', "w") " If found.
    mark c
  endif
  call s:FindAndMarkNextBuffer('a', 1)
  call s:FindAndMarkNextBuffer('b', -1)
endfunction " }}}

function! s:FindAndMarkNextBuffer(marker, inc) " {{{
  let nextBuffer = s:originalCurBuffer + a:inc
  let lastBufNr = bufnr('$')
  while ! bufexists(nextBuffer) && nextBuffer < lastBufNr && nextBuffer > 0
    let nextBuffer = nextBuffer + a:inc
  endwhile
  if search('^' . nextBuffer . '\>', "w") " If found.
    exec "mark " . a:marker
  endif
endfunction " }}}


"" START: Toggle methods {{{

function! s:ToggleHelpHeader()
  let s:showHelp = ! s:showHelp
  " Don't save/restore position in this case, because otherwise the user may
  "   not be able to view the help if he has listing that is more than one page
  "   (after all what is he viewing the help for ?)
  call s:UpdateHeader()
  if s:showHelp
    0 " If you turn on help, you intent to see it right?
  endif
endfunction


function! s:ToggleDetails()
  "if ! s:showDetails && s:indList == ""
    let s:showDetails = ! s:showDetails
    call s:UpdateBuffers(1)
  "else
  "  if s:showDetails
  "    call s:RemoveIndicators()
  "  else
  "    call s:AddIndicators()
  "  endif
  "  let s:showDetails = ! s:showDetails
  "  call s:UpdateHeader()
  "endif
endfunction


function! s:ToggleHidden()
  let s:showHidden = ! s:showHidden
  call s:UpdateBuffers(1)
endfunction


function! s:ToggleHideBufNums()
  call SaveHardPosition('ToggleHideBufNums')
  if ! s:hideBufNums
    call s:RemoveBufNumbers()
  else
    call s:AddBufNumbers()
  endif
  let s:hideBufNums = ! s:hideBufNums
  call s:UpdateHeader()
  call RestoreHardPosition('ToggleHideBufNums')
endfunction


function! s:ToggleHidePaths()
  let s:showPaths = ! s:showPaths
  call s:UpdateBuffers(1)
endfunction

"" END: Toggle methods }}}


" MRU support {{{
function! s:PushToFrontInMRU(bufNum, updImm)
  " Avoid browser buffer to come in the front.
  if a:bufNum == -1 || a:bufNum == s:myBufNum || s:disableMRUlisting
      return
  endif
  if s:ignoreNonFileBufs && getbufvar(a:bufNum, '&buftype') != ''
    return
  endif

  let s:MRUlist = MvPushToFront(s:MRUlist, ',', a:bufNum)
  let g:MRUlist = s:MRUlist
  if s:GetSortNameByType(s:sorttype) == 'mru'
    call s:DynUpdate('m', a:bufNum + 0, !a:updImm)
  else
    call s:DynUpdate('u', a:bufNum + 0, !a:updImm)
  endif
endfunction

function! s:PushToBackInMRU(bufNum, updImm)
  if a:bufNum == -1 || a:bufNum == s:myBufNum || s:disableMRUlisting
    return
  endif
  if s:ignoreNonFileBufs && getbufvar(a:bufNum, '&buftype') != ''
    return
  endif

  let s:MRUlist = MvPullToBack(s:MRUlist, ',', a:bufNum)
  let g:MRUlist = s:MRUlist
  if s:GetSortNameByType(s:sorttype) == 'mru'
    call s:DynUpdate('m', a:bufNum + 0, !a:updImm)
  else
    call s:DynUpdate('u', a:bufNum + 0, !a:updImm)
  endif
endfunction

function! s:AddToMRU(bufNum)
  if a:bufNum == -1 || a:bufNum == s:myBufNum
    return
  endif
  let s:MRUlist = s:MRUlist . a:bufNum . ','
  let g:MRUlist = s:MRUlist
endfunction

function! s:DelFromMRU(bufNum)
  if a:bufNum == -1 || s:disableMRUlisting
    return
  endif
  let s:MRUlist = MvRemoveElement(s:MRUlist, ',', a:bufNum)
  let g:MRUlist = s:MRUlist
endfunction

function! s:NextBufInMRU()
  if !exists("s:NextBufInMRUInitialized")
    let s:NextBufInMRUInitialized = 1
    call MvIterCreate(s:MRUlist, ',', 'FullUpdate')
  endif

  let lastBufNr = bufnr('$')
  let i = lastBufNr + 1
  while MvIterHasNext('FullUpdate') && i > lastBufNr
    let i = MvIterNext('FullUpdate') + 0
  endwhile

  if ! MvIterHasNext('FullUpdate') && i > lastBufNr
    call MvIterDestroy('FullUpdate')
    unlet s:NextBufInMRUInitialized
  endif
  return i
endfunction
" MRU support }}}

" Initialize with the bufers that might have been already loaded. This is
"   required to show the buffers that are loaded by specifying them as
"   command-line arguments (Reported by David Fishburn).
if ! s:disableMRUlisting
  let i = 1
  let lastBufNr = bufnr('$')
  while i <= lastBufNr
    if s:ShouldShowBuffer(i)
      let s:MRUlist = s:MRUlist . i . ','
    endif
    let i = i + 1
  endwhile
endif
"
" Utility methods. }}}


""" START: Support for sorting... based on explorer.vim {{{
"""

"" START: Sort Utility methods. {{{
""
function! s:GetSortNameByType(sorttype)
  if match(a:sorttype, '\a') != -1
    return a:sorttype
  elseif a:sorttype == 0
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
    return s:myScriptId . "CmpByNumber"
  elseif a:sorttype == 1
    return s:myScriptId . "CmpByName"
  elseif a:sorttype == 2
    return s:myScriptId . "CmpByPath"
  elseif a:sorttype == 3
    return s:myScriptId . "CmpByType"
  elseif a:sorttype == 4
    return s:myScriptId . "CmpByIndicators"
  elseif a:sorttype == 5
    return s:myScriptId . "CmpByMRU"
  else
    return ""
  endif
endfunction

""
"" END: Sort Utility methods. }}}

"" START: Compare methods. {{{
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
  if s:disableMRUlisting
    return 0
  endif

  let num1 = s:GetBufferNumber(a:line1)
  let num2 = s:GetBufferNumber(a:line2)

  return MvCmpByPosition(s:MRUlist, ',', num1, num2, a:direction)
endfunction

" END: Compare methods. }}}

" START: Interface to sort. {{{
"

" Reverse the current sort order
function! s:SortReverse()
  if exists("s:sortdirection") && s:sortdirection == -1
    let s:sortdirection = 1
    let s:sortdirlabel  = ""
  else
    let s:sortdirection = -1
    let s:sortdirlabel  = "rev-"
  endif
  call s:SortBuffers(s:hideBufNums)
  let s:indList = ""
endfunction

" Toggle through the different sort orders
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

  call s:SortBuffers(s:hideBufNums)
  let s:indList = ""
endfunction

" Sort the file listing
function! s:SortBuffers(bufNumsHidden)
    " Save the line we start on so we can go back there when done
    " sorting
    call SaveSoftPosition('SortBuffers')

    if a:bufNumsHidden
      call s:AddBufNumbers()
    endif

    " Allow modification
    setlocal modifiable
    " Do the sort
    if search('^"= ', 'w')
      silent! .+1,$call QSort(s:GetSortCmpFnByType(
	    \ s:GetSortTypeByName(s:sorttype)), s:sortdirection)
    endif
    " Disallow modification
    setlocal nomodifiable

    " Update buffer-list again with the sorted list.
    if a:bufNumsHidden
      call s:RemoveBufNumbers()
    endif

    " Replace the header with updated information
    call s:UpdateHeader()

    " Return to the position we started on
    call RestoreSoftPosition('SortBuffers')
endfunction

" END: Interface to Sort. }}}

"""
""" START: Support for sorting... based on explorer.vim }}}


""" START: WinManager hooks. {{{

function! SelectBuf_Start()
  if s:myBufNum == -1
    if exists("s:userDefinedHideBufNums")
      unlet s:userDefinedHideBufNums
    else
      let s:hideBufNums = 1
    endif
    let s:myBufNum = bufnr('%')
  endif
  call SelectBuf_Refresh()
endfunction


" Called by WinManager for BufEnter event.
" Return invalid only when there are pending updates.
function! SelectBuf_IsValid()
  return s:delayedDynUpdate || (s:pendingUpdAxns == "")
endfunction


function! SelectBuf_Refresh()
  let s:opMode = 'WinManager'
  call s:ListBufs()
endfunction


function! SelectBuf_ReSize()
  call s:AdjustWindowSize()
endfunction

""" END: WinManager hooks. }}}

" Restore cpo.
let &cpo = s:save_cpo
unlet s:save_cpo

" vim6:fdm=marker sw=2
