" selectbuf.vim
" Author: Hari Krishna (hari_vim at yahoo dot com)
" Last Change: 14-Mar-2005 @ 16:57
" Created: Before 20-Jul-1999
"          (Ref: http://groups.yahoo.com/group/vim/message/6409
"                mailto:vim-thread.1235@vim.org)
" Requires: Vim-6.3, multvals.vim(3.5), genutils.vim(1.16)
" Depends On: multiselect.vim(1.0)
" Version: 3.5.0
" Licence: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License.
"          See http://www.gnu.org/copyleft/gpl.txt 
" Download From:
"     http://www.vim.org/script.php?script_id=107
" Usage: 
"   For detailed help, see ":help selectbuf" or read doc/selectbuf.txt. 
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
"   - Open browser from one window. Try to open again from another window and
"     select a buffer. The buffer is shown in the first window.
"   - It is useful to have space for additional indicators. Useful to show
"     perforce status.
"   - s:curBufNameLen is getting reset to 9 else where (hard to reproduce).
"     - Fixed one issue, need to observe if it still happens.
"   - Is sort by path working correctly?
"   - When entering any of the plugin window's WinManager does something that
"     makes Vim ignore quick mouse-double-clicks. This is a WinManager issue,
"     as I verified this problem with other plugins also and SelectBuf in
"     stand-alone "keep" mode works fine.

if exists('loaded_selectbuf')
  finish
endif
if v:version < 603
  echomsg 'SelectBuf: You need at least Vim 6.3'
  finish
endif

" Dependency checks.
if !exists('loaded_multvals')
  runtime plugin/multvals.vim
endif
if !exists('loaded_multvals') || loaded_multvals < 305
  echomsg 'SelectBuf: You need a newer version of multvals.vim plugin'
  finish
endif
if !exists('loaded_genutils')
  runtime plugin/genutils.vim
endif
if !exists('loaded_genutils') || loaded_genutils < 116
  echomsg 'SelectBuf: You need a newer version of genutils.vim plugin'
  finish
endif
let loaded_selectbuf=305

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

" [-2s]
"" START: configuration 
"

if !exists('s:disableSummary') " The first-time only, initialize with defaults.
  let s:disableSummary = 1
  let s:restoreWindowSizes = 1
  let s:sorttype = 'mru'
  let s:sortdirection = 1
  let s:ignoreNonFileBufs = 1
  let s:showHelp = 0
  let s:showHidden = 0
  let s:showDetails = 0
  let s:showPaths = 2
  let s:hideBufNums = 0
  let s:browserMode = 'split'
  let s:useVerticalSplit = 0
  let s:splitType = ''
  let s:disableMRUlisting = 0
  let s:enableDynUpdate = 1
  let s:delayedDynUpdate = 0
  let s:doFileOnClose = 1
  let s:ignoreCaseInSort = 0
  let s:displayMaxPath = -1
  if OnMS()
    "let s:launcher = '!start rundll32 url.dll,FileProtocolHandler'
    let s:launcher = '!start rundll32 SHELL32.DLL,ShellExec_RunDLL'
  else
    let s:launcher = ''
  endif
endif

function! s:CondDefSetting(globalName, settingName, ...)
  let assgnmnt = (a:0 != 0) ? a:1 : a:globalName
  if exists(a:globalName)
    exec "let" a:settingName "=" assgnmnt
    exec "unlet" a:globalName
  endif
endfunction

call s:CondDefSetting('g:selBufDisableSummary', 's:disableSummary')
call s:CondDefSetting('g:selBufRestoreWindowSizes', 's:restoreWindowSizes')
call s:CondDefSetting('g:selBufDefaultSortOrder', 's:sorttype')
call s:CondDefSetting('g:selBufDefaultSortDirection', 's:sortdirection')
call s:CondDefSetting('g:selBufIgnoreNonFileBufs', 's:ignoreNonFileBufs')
call s:CondDefSetting('g:selBufAlwaysShowHelp', 's:showHelp')
call s:CondDefSetting('g:selBufAlwaysShowHidden', 's:showHidden')
call s:CondDefSetting('g:selBufAlwaysShowDetails', 's:showDetails')
call s:CondDefSetting('g:selBufAlwaysShowPaths', 's:showPaths')
call s:CondDefSetting('g:selBufAlwaysHideBufNums', 's:hideBufNums',
      \ 'g:selBufAlwaysHideBufNums | let s:userDefinedHideBufNums = 1')
call s:CondDefSetting('g:selBufBrowserMode', 's:browserMode')
call s:CondDefSetting('g:selBufUseVerticalSplit', 's:useVerticalSplit')
call s:CondDefSetting('g:selBufSplitType', 's:splitType')
call s:CondDefSetting('g:selBufDisableMRUlisting', 's:disableMRUlisting')
call s:CondDefSetting('g:selBufEnableDynUpdate', 's:enableDynUpdate')
call s:CondDefSetting('g:selBufDelayedDynUpdate', 's:delayedDynUpdate')
call s:CondDefSetting('g:selBufDoFileOnClose', 's:doFileOnClose')
call s:CondDefSetting('g:selBufIgnoreCaseInSort', 's:ignoreCaseInSort')
call s:CondDefSetting('g:selBufDisplayMaxPath', 's:displayMaxPath')
call s:CondDefSetting('g:selBufLauncher', 's:launcher')

"
" END configuration.
"

let s:windowName = '[Select Buf]'

" For WinManager integration.
let g:SelectBuf_title = s:windowName

"
" Define a default mapping if the user hasn't defined a map.
"
if (! exists("no_plugin_maps") || ! no_plugin_maps) &&
      \ (! exists("no_selectbuf_maps") || ! no_selectbuf_maps)
  if !hasmapto('<Plug>SelectBuf', 'n')
    nmap <unique> <silent> <F3> <Plug>SelectBuf
  endif
  if !hasmapto('<Plug>SelectBuf', 'i')
    imap <unique> <silent> <F3> <ESC><Plug>SelectBuf
  endif
  if !hasmapto('<Plug>SelBufLaunchCmd', 'n')
    nmap <unique> <Leader>sbl <Plug>SelBufLaunchCmd
  endif
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
call s:DefDefMap('n', 'LaunchKey', "A")
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
command! -complete=file -nargs=* SBLaunch :call <SID>LaunchBuffer(<f-args>)

" The main plug-in mapping.
noremap <script> <silent> <Plug>SelectBuf :call <SID>ListBufs()<CR>
nnoremap <script> <Plug>SelBufLaunchCmd :SBLaunch<Space>

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

" One-time initialization of some script variables {{{
" These are typically those that save the state are those which are not
"   impacted directly by user.
if !exists('s:myBufNum') 
  " This is the current buffer when the browser is invoked ('%').
  let s:originalCurBuffer = 1
  " This is the alternate buffer when the browser is invoked ('#').
  let s:originalAltBuffer = 1
  " The size of the current header. Used for mapping file names to buffer
  "   numbers when buffer numbers are hidden.
  let s:headerSize = 0
  let s:myBufNum = -1
  let s:savedSearchString = ""
  let s:curBufNameLen = 9 " Buffer name length used currently, start with min.
  " The operating mode for the current session. This is reset after the browser
  "   is closed. Ideally, we assume that the browser is open in only one window.
  let s:opMode = ""

  let s:pendingUpdAxns = ""
  let s:auSuspended = 1 " Disable until we are ready.
  let s:bufList = ""
  let s:indList = ""
  let s:quiteWinEnter = 0
  let s:originatingWinNr = 1

  " This is the list maintaining the MRU order of buffers.
  let s:MRUlist = ''
endif

let s:sortByNumber=0
let s:sortByName=1
let s:sortByPath=2
let s:sortByType=3
let s:sortByIndicators=4
let s:sortByMRU=5
let s:sortByMaxVal=5

let s:sortdirlabel  = ""

let s:settings = 'AlwaysHideBufNums,AlwaysShowDetails,AlwaysShowHelp,' .
      \ 'AlwaysShowHidden,AlwaysShowPaths,BrowserMode,DefaultSortDirection,' .
      \ 'DefaultSortOrder,DelayedDynUpdate,DisableMRUlisting,DisableSummary,' .
      \ 'EnableDynUpdate,IgnoreCaseInSort,IgnoreNonFileBufs,' .
      \ 'RestoreWindowSizes,SplitType,UseVerticalSplit,DoFileOnClose,' .
      \ 'DisplayMaxPath,Launcher'
" Map of global variable name to the local variable that are different than
"   their global counterparts.
let s:settingsMap{'DefaultSortOrder'} = 'sorttype'
let s:settingsMap{'DefaultSortDirection'} = 'sortdirection'
let s:settingsMap{'AlwaysShowHelp'} = 'showHelp'
let s:settingsMap{'AlwaysShowHidden'} = 'showHidden'
let s:settingsMap{'AlwaysShowDetails'} = 'showDetails'
let s:settingsMap{'AlwaysShowPaths'} = 'showPaths'
let s:settingsMap{'AlwaysHideBufNums'} = 'hideBufNums'

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
  try
    call s:GoToBrowserWindow(browserWinNo)
    call s:UpdateBuffers(0) " It will do a full refresh if required.
    if s:opMode ==# 'WinManager'
      call WinManagerForceReSize('SelectBuf')
    else
      call s:AdjustWindowSize()
    endif
  finally
    call s:ResumeAutoUpdates()
  endtry

  " When browser window is opened for the first time, if it was invoked by the
  " user (instead of accidentally switching to the browser buffer), and the
  " browser mode is not to keep the window open.
  if s:opMode ==# 'user' && s:browserMode !=# 'keep' && browserWinNo == -1
    call s:RestoreSearchString()

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
  let _modifiable = &l:modifiable
  setlocal modifiable
  " Remember the position.
  call SaveSoftPosition("UpdateHeader")
  try
    if search('^"= ', 'w')
      silent! keepjumps 1,.delete _
    endif

    call s:AddHeader()
    call search('^"= ', "w")
    let s:headerSize = line('.')

    if s:opMode ==# 'WinManager'
      call WinManagerForceReSize('SelectBuf')
    else
      call s:AdjustWindowSize()
    endif
  finally
    " Return to the original position.
    call RestoreSoftPosition("UpdateHeader")
    call ResetSoftPosition("UpdateHeader")
    let &l:modifiable = _modifiable
  endtry
endfunction " UpdateHeader

function! s:MapArg(key)
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

function! s:ShouldShowBuffer(bufNum) " {{{
  let showBuffer = 1
  if bufexists(a:bufNum)
    " If user wants to hide hidden buffers.
    if s:IgnoreBuf(a:bufNum)
      let showBuffer = 0
    elseif ! s:showHidden && ! buflisted(a:bufNum)
      let showBuffer = 0
    endif
  else
    let showBuffer = 0
  endif
  return showBuffer
endfunction " }}}

function! s:FullUpdate() " {{{
  setlocal modifiable

  call OptClearBuffer()

  call s:AddHeader()
  silent! keepjumps $delete _ " Delete one empty extra line at the end.
  let s:headerSize = line("$")
  let _curBufNameLen = s:curBufNameLen
  let s:curBufNameLen = s:CalcMaxBufNameLen(-1, !s:showHidden)
  if _curBufNameLen != s:curBufNameLen
    call s:SetupSyntax()
  endif

  $
  " Loop over all the buffers.
  let nBuffers = 0
  let nBuffersShown = 0
  let newLine = ""
  let showBuffer = 0
  let s:bufList = ""
  let lastBufNr = bufnr('$')
  call s:InitializeMRU()
  if s:optMRUfullUpdate && s:GetSortNameByType(s:sorttype) ==# 'mru'
    let i = s:NextBufInMRU()
  else
    let i = 1
  endif
  while i <= lastBufNr
    let newLine = ""
    if s:ShouldShowBuffer(i)
      let s:bufList = s:bufList . i . "\n"
      let newLine = s:GetBufLine(i)
      silent! keepjumps call append(line("$"), newLine)
      let nBuffersShown = nBuffersShown + 1
    endif
    let nBuffers = nBuffers + 1
    if s:optMRUfullUpdate && s:GetSortNameByType(s:sorttype) ==# 'mru'
      let i = s:NextBufInMRU()
    else
      let i = i + 1
    endif
  endwhile

  if line("$") != s:headerSize
    " Finally sort the listing based on the current settings.
    if (!s:optMRUfullUpdate || s:GetSortNameByType(s:sorttype) !=# 'mru') &&
	  \ s:GetSortNameByType(s:sorttype) !=# 'number'
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
"let g:selbufDebug='' 
function! s:IncrementalUpdate() " {{{
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

    if (action ==# 'I' || action ==# 'i' || action ==# 'l') && s:showPaths == 2
      let newMax = (action ==# 'i' && bufNo != -1) ? strlen(s:FileName(bufNo)) :
            \ s:CalcMaxBufNameLen(bufNo, !s:showHidden)
      "let g:selbufDebug = g:selbufDebug.'action:'.action.' file:'.s:FileName(bufNo).' s:curBufNameLen:'.s:curBufNameLen.' newMax:'.newMax."\n"
      if s:showPaths == 2 && s:curBufNameLen != newMax
        call search('^"= ', "w")
        let _search = @/
        try
          " If the max. buffer name length has increased or decreased since
          " the last time, we need to fix the existing buffer lines first.
          if (action ==# 'i' || action ==# 'l') && s:curBufNameLen < newMax
            " Insert enough extra spacer for all the existing buffers.
            let addSpacer = GetSpacer(newMax - s:curBufNameLen)
            let colToIns = (s:showDetails ? 11 : 5) + s:curBufNameLen +
                  \ 1 " Col index starts with 1.
            let @/ = '\%'.colToIns.'c'
            silent! keepjumps exec '+,$s//'.addSpacer.'/'
          elseif (action ==# 'I' || action ==# 'l') && s:curBufNameLen > newMax
            "exec BPBreak(1)
            let remSpacer = ' \{'.(s:curBufNameLen - newMax).'}'
            let colToDel = (s:showDetails ? 11 : 5) + newMax
                  \ + 1 " Col index starts with 1.
            let @/ = '\%'.colToDel.'c'.remSpacer
            silent! keepjumps exec '+,$s///'
          else
            let newMax = 0
          endif
        finally
          let @/=_search
          if newMax != 0
            let s:curBufNameLen = newMax
            call s:SetupSyntax()
          endif
        endtry
      endif
      continue

    " For delete, skip when we are showing hidden buffers but not details.
    elseif action ==# 'd' && s:showHidden && ! s:showDetails
      continue

    " For 'm' or 'u', skip when the buffer is hidden and we don't show [-2s]
    "   hidden buffers (we would like to add 'c' also here but a buffer can
    "   never be unlisted by the time it is created).
    elseif action =~ '[um]' && ! s:showHidden && ! buflisted(bufNo)
      continue
    endif

    if search('^' . bufNo . '\>', 'w') > 0
      if action ==# 'u' || (action ==# 'd' && s:showHidden)
	silent! keepjumps call setline('.', s:GetBufLine(bufNo))
	continue
      else
	silent! keepjumps .delete _
      endif
    endif
    if action ==# 'c' || action ==# 'm'
      let bufLine = s:GetBufLine(bufNo)
      let lineNoToInsert = BinSearchForInsert(s:headerSize + 1, line("$"),
	    \ bufLine, s:GetSortCmpFnByType(s:GetSortTypeByName(s:sorttype)),
	    \ s:sortdirection)
      silent! keepjumps call append(lineNoToInsert, bufLine)
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
  call ResetSoftPosition("IncrementalUpdate")
  normal! zb
endfunction " IncrementalUpdate }}}

" Actions:
"   'c' - buffer added (add line).
"   'd' - buffer deleted (remove only if !showHidden and update otherwise).
"   'w' - buffer wipedout (remove in any case).
"   'u' - needs an update.
"   'm' - needs to be moved (remove and add back).
"   'i' - Increase in max length due to loading bufNo.
"   'I' - Decrease in max length due to wiping out bufNo (which is to be ignored
"         while calculating new max).
"   'l' - Recalculate max length, no significance for bufNo.
function! s:DynUpdate(action, bufNum, ovrrdDelayDynUpdate) " {{{
  let bufNo = a:bufNum
  if bufNo == -1 || bufNo == s:myBufNum || s:AUSuspended()
    return
  endif
  " This means that only 'd', 'w' and most of the 'c' events get through. If
  "   the buffer is ignored by its name, the 'c' events will not get through,
  "   so their corresponding 'd' or 'w' event is redundant, but there is no
  "   way to avoid it.
  if s:IgnoreBuf(a:bufNum) && (a:action !=# 'd' && a:action !=# 'w')
    return
  endif

  let ignore = 0
  if (a:action ==# 'u' || a:action ==# 'm') &&
	\ MvContainsElement(s:pendingUpdAxns, ',', bufNo . 'c')
    let ignore = 1
  elseif a:action ==# 'w'
    let s:pendingUpdAxns = MvRemovePatternAll(s:pendingUpdAxns, ',',
          \ bufNo . '\a')
  elseif a:action ==# 'i'
    " Special case which requires us to add spacer first.
    let s:pendingUpdAxns = bufNo . a:action. ',' . s:pendingUpdAxns
    let ignore = 1
  elseif a:action ==# 'I'
    let s:pendingUpdAxns = MvRemovePatternAll(s:pendingUpdAxns, ',', '\d\+I')
  elseif MvContainsElement(s:pendingUpdAxns, ',', bufNo . a:action)
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
    if s:opMode !=# 'WinManager' || !WinManagerAUSuspended()
      " CAUTION: Using bufnr('%') is not reliable in the case of ":split new".
      "	  By the time the BufAdd event is fired, the window is already created,
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
endfunction " }}}
" Incremental update support }}}

" Event handlers {{{
function! s:BufWinEnter()
  " Optimization: Pass 1 for updImm only when the next call is not going to be
  "   effective.
  call s:PushToFrontInMRU(expand("<abuf>") + 0,
        \ (! s:IgnoreBuf(bufnr('#') + 0) && !s:showDetails) ? 1 : 0)
  " FIXME: In case of :e#, the alternate buffer must have got updated because
  "   of a BufWinLeave event, but it looks like this buffer still appears as
  "   the current and active buffer at that time, so details will show
  "   incorrect information. As a workaround, update this buffer again.
  if s:enableDynUpdate && s:showDetails
    call s:DynUpdate('u', bufnr('#') + 0, 0)
  endif
endfunction

function! s:BufWinLeave()
  if s:enableDynUpdate
    call s:DynUpdate('u', expand("<abuf>") + 0, 1)
  endif
endfunction

function! s:BufWipeout()
  call s:BufDeleteImpl(expand("<abuf>")+0, 0, 'w')
endfunction

function! s:BufDelete()
  "if s:enableDynUpdate
  "  call s:DynUpdate('d', expand("<abuf>") + 0, 0)
  "endif
  call s:BufDeleteImpl(expand("<abuf>")+0, 0, 'd')
endfunction

function! s:BufDeleteImpl(bufNr, delayedUpdate, event)
  if a:event ==# 'w'
    call s:DelFromMRU(a:bufNr)
  endif
  if s:enableDynUpdate
    let len = (s:showPaths == 2) ? strlen(s:FileName(a:bufNr)) : -1
    " Optimization: Pass 0 for ovrrdDelayDynUpdate only when the next call is
    "   not going to happen.
    call s:DynUpdate(a:event, a:bufNr,
          \ (len == s:curBufNameLen && s:showPaths == 2) ? 1 : a:delayedUpdate)
    " Send event only if the buffer is not going to be shown anymore.
    if len == s:curBufNameLen && s:showPaths == 2 &&
          \ (a:event ==# 'w' || !s:showHidden)
      " Let s:curBufNameLen be recalculated.
      call s:DynUpdate('I', a:bufNr, a:delayedUpdate)
    endif
  endif
endfunction

function! s:BufNew()
  if ! s:disableMRUlisting
    call s:AddToMRU(expand("<abuf>") + 0)
  endif
endfunction

function! s:BufAdd()
  let bufNr = expand("<abuf>") + 0
  if s:enableDynUpdate
    " Ignore non-file buffers.
    if !s:IgnoreBuf(bufNr)
      call s:BufAddImpl(bufNr, 0)
    endif
  endif
endfunction

" Actual event generator.
function! s:BufAddImpl(bufNr, delayedUpdate)
  let len = (s:showPaths == 2) ? strlen(s:FileName(a:bufNr)) : -1
  if len > s:curBufNameLen
    call s:DynUpdate('i', a:bufNr, 1)
  endif
  call s:DynUpdate('c', a:bufNr, a:delayedUpdate)
endfunction
" Event handlers }}}
" Buffer Update }}}


" Buffer line operations {{{

" Add/Remove buffer/indicators numbers {{{
function! s:RemoveBufNumbers()
  let s:bufList = s:RemoveColumn(1, 5, 1)
endfunction " RemoveBufNumbers


function! s:AddBufNumbers()
  call s:AddColumn(0, s:bufList)
endfunction " AddBufNumbers

"function! s:RemoveIndicators()
"  let s:indList = s:RemoveColumn(2)
"endfunction " RemoveIndicators
"
"
"function! s:AddIndicators()
"  call s:AddColumn(2, s:indList)
"endfunction " AddIndicators

" Pass -1 for colWidth to include till the end of line.
function! s:RemoveColumn(colPos, colWidth, collect)
  if line("$") == s:headerSize
    return
  endif
  call search('^"= ', "w")
  +
  if a:collect
    let _unnamed = @"
    let _z = @z
  endif
  let block = ''
  let _sol = &startofline
  let _modifiable = &l:modifiable
  try
    setlocal modifiable
    set nostartofline
    exec "normal! ".a:colPos."|" | " Position correctly.
    silent! keepjumps exec "normal! \<C-V>G".
          \ ((a:colWidth > 0) ? (a:colWidth-1).'l' : '$').
          \ '"'.(a:collect?'z':'_').'d'
  finally
    let &l:modifiable = _modifiable
    let  &startofline = _sol
    if a:collect
      let block = @z
      let @z = _z
      let @" = _unnamed
    endif
  endtry
  return block
endfunction " RemoveColumn

function! s:AddColumn(colPos, block)
  if line("$") == s:headerSize || a:block == ""
    return
  endif
  let _z = @z
  let _modifiable = &l:modifiable
  try
    setlocal modifiable
    call setreg('z', a:block, "\<C-V>")
    call search('^"= ', "w")
    +
    exec "normal!" (a:colPos ? a:colPos : 1)."|" | " Position correctly.
    if a:colPos == 0
      normal! "zP
    else
      normal! "zp
    endif
  finally
    let &l:modifiable = _modifiable
    let @z = _z
  endtry
endfunction " AddColumn
" Add/Remove buffer/indicators numbers }}}

" GetBufLine {{{
function! s:GetBufLine(bufNum)
  if a:bufNum == -1
    return ""
  endif
  let newLine = ""
  let newLine = newLine . strpart(a:bufNum."    ", 0, 5)
  " If user wants to see more details.
  if s:showDetails
    let newLine = newLine . s:GetBufIndicators(a:bufNum)
  endif
  let newLine = newLine . s:GetBufName(a:bufNum)
  return newLine
endfunction

" Width: 6
function! s:GetBufIndicators(bufNum)
  let bufInd = ''
  if !buflisted(a:bufNum)
    let bufInd = bufInd . "u"
  else
    let bufInd = bufInd . " "
  endif

  " Alternate buffer is more reliable than current when switching windows
  " (BufWinLeave comes first and the # buffer is already changed by then,
  " not the % buffer).
  if s:originalAltBuffer == a:bufNum
    let bufInd = bufInd . "#"
  elseif s:originalCurBuffer == a:bufNum
    let bufInd = bufInd . "%"
  else
    let bufInd = bufInd . " "
  endif

  if bufloaded(a:bufNum)
    if bufwinnr(a:bufNum) != -1
      " Active buffer.
      let bufInd = bufInd . "a"
    else
      let bufInd = bufInd . "h"
    endif
  else
    let bufInd = bufInd . " "
  endif

  " Special case for "my" buffer as I am finally going to be
  "  non-modifiable, anyway.
  if getbufvar(a:bufNum, "&modifiable") == 0 || s:myBufNum == a:bufNum
    let bufInd = bufInd . "-"
  elseif getbufvar(a:bufNum, "&readonly") == 1
    let bufInd = bufInd . "="
  else
    let bufInd = bufInd . " "
  endif

  " Special case for "my" buffer as I am finally going to be
  "  non-modified, anyway.
  if getbufvar(a:bufNum, "&modified") == 1 && a:bufNum != s:myBufNum
    let bufInd = bufInd . "+"
  else
    let bufInd = bufInd . " "
  endif
  let bufInd = bufInd . " "

  return bufInd
endfunction

function! s:GetBufName(bufNum)
  if s:showPaths
    if s:showPaths == 2
      let bufName = s:FileName(a:bufNum)
      let path = expand('#'.a:bufNum.':p:h')
      let bufName = bufName . GetSpacer(s:curBufNameLen - strlen(bufName) + 1) .
            \ s:TrimPath(path)
    else
      let bufName = s:TrimPath(s:BufName(a:bufNum))
    endif
  else
    let bufName = s:FileName(a:bufNum)
  endif
  return bufName
endfunction

function! s:TrimPath(path)
  let path = a:path
  if s:displayMaxPath > 0 && strlen(path) > s:displayMaxPath
    let path = '...'.strpart(path, strlen(path) - s:displayMaxPath + 3)
  endif
  return path
endfunction
" GetBufLine }}}

function! s:SelectCurrentBuffer(openMode) " {{{
  if search('^"= ', "W") != 0
    +
    return
  endif

  let selBufNum = SBCurBufNumber()
  if selBufNum == -1
    +
    return
  endif

  " If running under WinManager, let it open the file.
  if s:opMode ==# 'WinManager'
    call WinManagerFileEdit(selBufNum, a:openMode)
    return
  endif

  let didQuit = 0
  if a:openMode == 2
    " Behaves temporarily like "keep"
    let prevWin = winnr()
    exec s:originatingWinNr 'wincmd w'
    if prevWin == winnr() " No previous window.
      split
    endif
  elseif a:openMode == 1
    " We will just skip calling Quit() here, because we will change to the
    " selected buffer anyway soon.
    let s:opMode = 'auto'
  else
    let didQuit = s:Quit(1)
  endif

  " If we are not quitting the window, then there is no point trying to restore
  "   the window settings.
  if ! didQuit && s:browserMode ==# "split"
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
let s:deleteMsg = ''
function! s:DeleteSelBuffers(wipeout) range
  if s:opMode ==# 'WinManager'
    " Otherwise, WinManager would try to refresh us multiple times, once for
    "   each buffer deleted.
    call WinManagerSuspendAUs()
  endif

  call SaveHardPosition('DeleteSelBuffers')

  if s:hideBufNums
    call s:AddBufNumbers()
  endif
  let _delayedDynUpdate = s:delayedDynUpdate
  " Temporarily delay dynamic update until we call UpdateBuffers()
  let s:delayedDynUpdate = 1
  try
    if s:MultiSelectionExists()
      exec 'MSExecCmd call '.s:myScriptId.'DeleteBuffers("'.a:wipeout.'")'
      MSClear
    else
      exec a:firstline.','.a:lastline.'call s:DeleteBuffers(a:wipeout)'
    endif
  finally
    if s:hideBufNums
      call s:RemoveBufNumbers()
    endif
    let s:delayedDynUpdate = _delayedDynUpdate
    if s:deleteMsg != ''
      call s:UpdateBuffers(0)
    endif
    redraw | echo s:deleteMsg
    "call input(s:deleteMsg)
    let s:deleteMsg = ''
  endtry

  call RestoreHardPosition('DeleteSelBuffers')
  call ResetHardPosition('DeleteSelBuffers')

  if s:opMode ==# 'WinManager'
    call WinManagerResumeAUs()
  endif
endfunction

function! s:DeleteBuffers(wipeout) range
  let nDeleted = 0
  let nUndeleted = 0
  let nWipedout = 0
  let deletedMsg = ""
  let undeletedMsg = ""
  let wipedoutMsg = ""
  let line = a:firstline
  silent! execute line
  while line <= a:lastline
    let selectedBufNum = SBCurBufNumber()
    if selectedBufNum != -1
      if a:wipeout
        exec "bwipeout" selectedBufNum
        let nWipedout = nWipedout + 1
        let wipedoutMsg = wipedoutMsg . " " . selectedBufNum
      elseif buflisted(selectedBufNum)
        exec "bdelete" selectedBufNum
        let nDeleted = nDeleted + 1
        let deletedMsg = deletedMsg . " " . selectedBufNum
      else
        " Undelete buffer.
        call setbufvar(selectedBufNum, "&buflisted", "1")
        let nUndeleted = nUndeleted + 1
        let undeletedMsg = undeletedMsg . " " . selectedBufNum
      endif
    endif
    silent! +
    let line = line + 1
  endwhile

  if nWipedout > 0
    let s:deleteMsg = s:deleteMsg . s:GetDeleteMsg(nWipedout, wipedoutMsg)
    let s:deleteMsg = s:deleteMsg . " wiped out.\n"
  endif
  if nDeleted > 0
    let s:deleteMsg = s:deleteMsg . s:GetDeleteMsg(nDeleted, deletedMsg)
    let s:deleteMsg = s:deleteMsg . " deleted (unlisted).\n"
  endif
  if nUndeleted > 0
    let s:deleteMsg = s:deleteMsg . s:GetDeleteMsg(nUndeleted, undeletedMsg)
    let s:deleteMsg = s:deleteMsg . " undeleted (listed).\n"
  endif
endfunction " DeleteBuffers

function! s:GetDeleteMsg(nBufs, msg)
  let msg = a:nBufs . ((a:nBufs > 1) ? " buffers: " : " buffer: ") .
          \ a:msg
  return msg
endfunction
" Buffer Deletions }}}

function! s:ExecFileCmdOnSelection(cmd) range " {{{
  let ind = match(a:cmd, '%\@<!\%(%%\)*\zs%[sn]')
  if ind != -1
    let cmdPre = strpart(a:cmd, 0, ind)
    let cmdPost = strpart(a:cmd, ind+2)
  else
    let cmdPre = a:cmd.' '
    let cmdPost = ''
  endif
  let cmdPre = substitute(cmdPre, '%%', '%', 'g')
  let cmdPost = substitute(cmdPost, '%%', '%', 'g')

  if s:hideBufNums
    call s:AddBufNumbers()
  endif
  try
    if ind != -1 && a:cmd[ind+1] == 'n'
      let bufList = SBSelectedBufNums(a:firstline, a:lastline)
    else
      let bufList = SBSelectedBuffers(a:firstline, a:lastline)
    endif
  finally
    if s:hideBufNums
      call s:RemoveBufNumbers()
    endif
  endtry

  if bufList != ''
    let cmd = escape(cmdPre.bufList.cmdPost, '%')
    redraw | echo cmd
    exec cmd
    if s:MultiSelectionExists()
      MSClear
    endif
  endif
endfunction " }}}

" Buffer line operations }}}


" Buffer Setup/Cleanup {{{

function! s:SetupBuf() " {{{
  call SetupScratchBuffer()
  setlocal nowrap
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
  exec "au BufWinEnter " . GetBufNameForAu(fnamemodify(s:windowName, ':p')) .
        \ " :call <SID>AutoListBufs()"
  exec "au BufWinLeave " . GetBufNameForAu(fnamemodify(s:windowName, ':p')) .
        \ " :call <SID>Done()"
  exec "au WinEnter " . GetBufNameForAu(fnamemodify(s:windowName, ':p')) .
        \ " :call <SID>AutoUpdateBuffers(0)"
  aug END

  call s:SetupSyntax()

  " Maps {{{
  if (! exists("no_plugin_maps") || ! no_plugin_maps) &&
        \ (! exists("no_selectbuf_maps") || ! no_selectbuf_maps)
    let noMaps = 0
  else
    let noMaps = 1
  endif

  if !noMaps
    call s:DefMap("n", "SelectKey", "<CR>", ":SBSelect<CR>")
    call s:DefMap("n", "MSelectKey", "<2-LeftMouse>", ":SBSelect<CR>")
    call s:DefMap("n", "WSelectKey", "<C-W><CR>", ":SBWSelect<CR>")
    call s:DefMap("n", "OpenKey", "O", ":SBOpen<CR>")
    call s:DefMap("n", "DeleteKey", "d", ":SBDelete<CR>")
    call s:DefMap("n", "WipeOutKey", "D", ":SBWipeout<CR>")
    call s:DefMap("v", "DeleteKey", "d", ":SBDelete<CR>")
    call s:DefMap("v", "WipeOutKey", "D", ":SBWipeout<CR>")
    call s:DefMap("n", "RefreshKey", "R", ":SBRefresh<CR>")
    call s:DefMap("n", "SortSelectFKey", "s", ":SBFSort<cr>")
    call s:DefMap("n", "SortSelectBKey", "S", ":SBBSort<cr>")
    call s:DefMap("n", "SortRevKey", "r", ":SBRSort<cr>")
    call s:DefMap("n", "QuitKey", "q", ":SBQuit<CR>")
    call s:DefMap("n", "ShowSummaryKey", "<C-G>", ":SBSummary<CR>")
    call s:DefMap("n", "LaunchKey", "A", ":SBLaunch<CR>")
    call s:DefMap("n", "TDetailsKey", "i", ":SBTDetails<CR>")
    call s:DefMap("n", "THiddenKey", "u", ":SBTHidden<CR>")
    call s:DefMap("n", "TBufNumsKey", "p", ":SBTBufNums<CR>")
    call s:DefMap("n", "THidePathsKey", "P", ":SBTPaths<CR>")
    call s:DefMap("n", "THelpKey", "?", ":SBTHelp<CR>")

    cnoremap <buffer> <C-R><C-F> <C-R>=expand('#'.SBCurBufNumber().':p')<CR>

    nnoremap <buffer> 0 gg0:silent! call search('^"= ')<CR>

    " From Thomas Link (t dot link02a at gmx at net)
    " When user types numbers in the browser window start a search for the
    " buffer by its number.
    let chars = "123456789"
    let i = 0
    let max = strlen(chars)
    while i < max
      exec 'noremap <buffer>' chars[i] ':call <SID>InputBufNumber()<CR>'.
            \ chars[i]
      let i = i + 1
    endwhile

    if s:MSExists()
      nnoremap <buffer> <silent> <Space> :.MSInvert<CR>
      vnoremap <buffer> <silent> <Space> :MSInvert<CR>
    endif
  endif

  if !s:disableSummary && !noMaps
    nnoremap <silent> <buffer> j j:call <SID>EchoBufSummary(0)<CR>
    nnoremap <silent> <buffer> k k:call <SID>EchoBufSummary(0)<CR>
    nnoremap <silent> <buffer> <Up> <Up>:call <SID>EchoBufSummary(0)<CR>
    nnoremap <silent> <buffer> <Down>
	  \ <Down>:call <SID>EchoBufSummary(0)<CR>
    nnoremap <silent> <buffer> <LeftMouse>
	  \ <LeftMouse>:call <SID>EchoBufSummary(0)<CR>
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

  command! -nargs=1 -buffer -complete=command -range SBExec
        \ :<line1>,<line2>call <SID>ExecFileCmdOnSelection(<q-args>)

  " Define some local command too for the ease of debugging.
  command! -nargs=0 -buffer SBS :SBSettings
  command! -nargs=0 -buffer SBSelect :call <SID>SelectCurrentBuffer(0)
  command! -nargs=0 -buffer SBOpen :call <SID>SelectCurrentBuffer(2)
  command! -nargs=0 -buffer SBWSelect :call <SID>SelectCurrentBuffer(1)
  command! -nargs=0 -buffer SBQuit :call <SID>Quit(0)
  command! -nargs=0 -buffer -range SBDelete
        \ :<line1>,<line2>call <SID>DeleteSelBuffers(0)
  command! -nargs=0 -buffer -range SBWipeout
        \ :<line1>,<line2>call <SID>DeleteSelBuffers(1)
  command! -nargs=0 -buffer SBRefresh :call <SID>UpdateBuffers(1)
  command! -nargs=0 -buffer SBSummary :call s:EchoBufSummary(1)
  command! -nargs=0 -buffer SBFSort :call <SID>SortSelect(1)
  command! -nargs=0 -buffer SBBSort :call <SID>SortSelect(-1)
  command! -nargs=0 -buffer SBRSort :call <SID>SortReverse()
  command! -nargs=0 -buffer SBTBufNums :call <SID>ToggleHideBufNums()
  command! -nargs=0 -buffer SBTDetails :call <SID>ToggleDetails()
  command! -nargs=0 -buffer SBTHelp :call <SID>ToggleHelpHeader()
  command! -nargs=0 -buffer SBTHidden :call <SID>ToggleHidden()
  command! -nargs=0 -buffer SBTPaths :call <SID>ToggleHidePaths()
  " Commands }}} 
endfunction " SetupBuf }}}

function! s:SetupSyntax() " {{{
  syn clear " Why do we have to do this explicitly?
  set ft=selectbuf

  " The mappings in the help header.
  syn match SelBufMapping "\s\(\i\|[ /<>-]\)\+ : " contained
  syn match SelBufHelpLine "^\" .*$" contains=SelBufMapping

  " The starting line. Summary of current settings.
  syn keyword SelBufKeyWords Sorting showDetails showHidden showDirs showPaths bufNameOnly hideBufNums contained
  syn region SelBufKeyValues start=+=+ end=+,+ end=+$+ skip=+ + contained
  syn match SelBufKeyValuePair +\i\+=\i\++ contained contains=SelBufKeyWords,SelBufKeyValues
  syn match SelBufSummary "^\"= .*$" contains=SelBufKeyValuePair

  syn match SelBufBufLine "^[^"].*$" contains=SelBufBufNumber,SelBufBufIndicators,SelBufBufName,@SelBufLineAdd
  syn match SelBufBufNumber "^\d\+" contained
  if s:hideBufNums
    if s:showDetails
      syn match SelBufBufIndicators "\%(^\)\@<=....." contained contains=@SelBufIndAdd
      syn match SelBufBufName "\%(^.....\)\@<=\(\p\| \)*" contains=SelBufPath,@SelBufBufAdd contained
    else
      syn match SelBufBufName "^\(\p\| \)*" contains=SelBufPath,@SelBufBufAdd contained
    endif
  else
    if s:showDetails
      " CAUTION: Five dots because that is the width of the buf number column.
      syn match SelBufBufIndicators "\%(^.....\)\@<=....." contained contains=@SelBufIndAdd
      syn match SelBufBufName "\%(^..........\)\@<=\(\p\| \)*" contains=SelBufPath,@SelBufBufAdd contained
    else
      syn match SelBufBufName "\%(^.....\)\@<=\(\p\| \)*" contains=SelBufPath,@SelBufBufAdd contained
    endif
  endif
  if s:showPaths == 2
    let pathStartCol = s:curBufNameLen + 2 + (!s:hideBufNums) * 5 +
          \ (s:showDetails>0) * 5
    exec 'syn match SelBufPath "\%'.pathStartCol.'c\(\p\| \)*$" contained contains=@SelBufPathAdd'
  endif


  hi def link SelBufHelpLine      Comment
  hi def link SelBufMapping       Special

  hi def link SelBufSummary       Statement
  hi def link SelBufKeyWords      Keyword
  hi def link SelBufKeyValues     Constant

  hi def link SelBufBufNumber     Constant
  hi def link SelBufBufIndicators Label
  hi def link SelBufBufName       Directory
  hi def link SelBufPath          Identifier

  hi def link SelBufSummary       Special
endfunction " }}}

" Routing browser quit through this function gives a chance to decide how to
"   do the exit.
" Returns 1 when the browser window could be successfully closed.
function! s:Quit(scriptOrigin) " {{{
  " When the browser should be left open, switch to the previously used window
  "   instead of quitting the window.
  " The user can still use :q commnad to force a quit.
  if s:opMode ==# 'WinManager' || s:browserMode ==# 'keep'
    " Switch to the most recently used window.
    if s:opMode ==# 'WinManager'
      let prevWin = bufwinnr(WinManagerGetLastEditedFile())
      if prevWin != -1
	if s:quiteWinEnter " When previously entered using activation key.
	  call s:GoToWindow(prevWin)
	else
	  exec prevWin . 'wincmd w'
	endif
      endif
    else
      exec s:originatingWinNr 'wincmd w'
    endif
    return 0
  endif

  let didQuit = 0
  " If opMode is empty or 'auto', the browser might have entered through some
  "   back-door mechanism. We don't want to exit the window in this case.
  if s:browserMode ==# "switch" || s:opMode ==# 'auto' || s:opMode == ''
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
  if s:opMode ==# 'WinManager' || s:browserMode ==# 'keep'
    return
  endif

  call s:RestoreSearchString()
endfunction " Done }}}

function! s:RestoreWindows(dummyTitle) " {{{
  " If user wants us to restore window sizes during the exit.
  if s:restoreWindowSizes && s:browserMode !=# "keep"
    call RestoreWindowSettings2(s:myScriptId)
  endif
endfunction " }}}

function! s:RestoreSearchString() " {{{
  if s:savedSearchString != ''
    let @/ = s:savedSearchString " This doesn't modify the history.
    let s:savedSearchString = histget("search")
    " Fortunately, this will make sure there is only one copy in the history,
    " and ignores the call if it is empty.
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
  if ! IsOnlyVerticalWindow() && ! s:useVerticalSplit
    let size = (line("$") + 1)
    if size > (&lines / 2)
      let size = &lines/2
    endif
    exec "resize" . size
  endif
  call RestoreSoftPosition('AdjustWindowSize')
  call ResetSoftPosition('AdjustWindowSize')
endfunction " }}}

" Suspend/Resume AUs{{{
function! s:SuspendAutoUpdates(dbgTag)
  " To make it reentrant.
  if !exists("s:_lazyredraw")
    let s:auSuspended = 1
    let s:dbgSuspTag = a:dbgTag
    if s:opMode ==# 'WinManager'
      call WinManagerSuspendAUs()
    endif
    let s:_lazyredraw = &lazyredraw
    set lazyredraw
    let s:_report = &report
    set report=99999
    let s:_undolevels = &undolevels
    set undolevels=-1
  endif
endfunction

function! s:ResumeAutoUpdates()
  " To make it reentrant.
  if exists("s:_lazyredraw")
    let &report = s:_report
    let &lazyredraw = s:_lazyredraw
    unlet s:_lazyredraw
    if s:opMode ==# 'WinManager'
      call WinManagerResumeAUs()
    endif
    let s:auSuspended = 0
    let s:dbgSuspTag = ''
    let &undolevels = s:_undolevels
  endif
endfunction

function! s:AUSuspended()
  return s:auSuspended
endfunction
" }}}

function! s:GetBufferNumber(line) " {{{
  let bufNumber = matchstr(a:line, '^\d\+')
  if bufNumber == ''
    return -1
  endif
  return bufNumber + 0 " Convert it to number type.
endfunction " }}}

function! s:EchoBufSummary(detailed) " {{{
  if !a:detailed && s:showPaths == 1 " There is nothing special to display here.
    return
  endif
  let bufNumber = SBCurBufNumber()
  if bufNumber != -1
    let _showPaths = s:showPaths | let s:showPaths = 1
    let _showDetails = s:showDetails | let s:showDetails = (a:detailed?1:0)
    let _hideBufNums = s:hideBufNums | let s:hideBufNums = (a:detailed?0:1)
    let _displayMaxPath = s:displayMaxPath | let s:displayMaxPath = -1
    let bufLine = ''
    try
      let bufLine = s:GetBufLine(bufNumber)
      let bufLine = a:detailed ? bufLine :
	    \ substitute(bufLine, '^\d\+\s\+', '', '')
    finally
      let s:showPaths = _showPaths
      let s:showDetails = _showDetails
      let s:hideBufNums = _hideBufNums
      let s:displayMaxPath = _displayMaxPath
    endtry
    echohl SelBufSummary | echo (a:detailed ? '' : "Buffer: ") . bufLine .
	  \ (a:detailed ? (' (Total: '.(line('$') - s:headerSize).')') : '') |
	  \ echohl NONE
  endif
endfunction " }}}

function! s:LaunchBuffer(...) " {{{
  if s:launcher == ''
    return
  endif
  let args = ''
  let commandNeedsEscaping = 1
  if OnMS() && s:launcher =~# '^\s*!\s*start\>'
    let commandNeedsEscaping = 0
  endif
  if a:0 == 0
    let args = '#'.(bufnr('%') == s:myBufNum ? SBCurBufNumber() : bufnr('%')).
          \    ':p'
  else
    let i = 1
    while i <= a:0
      let arg = a:{i}
      if filereadable(a:{i}) || a:{i} == '.'
        let arg = fnamemodify(arg, ':p')
      endif
      if OnMS() && &shellslash && filereadable(arg)
        let arg = substitute(arg, '/', '\\', 'g')
      endif
      let arg = Escape(arg, ' ')
      let args = args . arg . ((i == a:0) ? '' : ' ')
      let i = i + 1
    endwhile
  endif
  if commandNeedsEscaping
    let args = EscapeCommand('', args, '')
  else
    " Escape the existing double-quotes (by quadrapling them).
    let args = substitute(args, '"', '""""', 'g')
    " Use double quotes to protect spaces and double-quotes.
    let args = substitute(args, '\(\%([^ ]\|\\\@<=\%(\\\\\)* \)\+\)',
          \ '"\1"', 'g')
          "\ '\="\"".escape(submatch(1), "\\")."\""', 'g')
    let args = UnEscape(args, ' ')
  endif
  if args != -1 && args.'' != ''
    exec 'silent! '.s:launcher args
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
      if s:restoreWindowSizes && s:browserMode ==# "split"
	call SaveWindowSettings2(s:myScriptId, 1)
      endif

      " Don't split window for "switch" mode.
      let splitCommand = ""
      if s:browserMode !=# "switch"
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
	try
	  set isfname-=\
	  set isfname-=[
	  if exists('+shellslash')
	    exec ":e \\\\" . escape(s:windowName, ' ')
	  else
	    exec ":e \\" . escape(s:windowName, ' ')
	  endif
	finally
	  let &isfname = _isf
	endtry
	let s:myBufNum = bufnr('%')
      endif
    endif
  endif
endfunction

function! s:GoToWindow(winNr)
  if winnr() != a:winNr
    let _eventignore = &eventignore
    try
      "set eventignore+=WinEnter,WinLeave
      set eventignore=all
      let s:originatingWinNr = winnr()
      exec a:winNr . 'wincmd w'
    finally
      let &eventignore = _eventignore
    endtry
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
      if exists("s:settingsMap" . selectedSetting)
	exec "let oldVal = s:" . s:settingsMap{selectedSetting} . " . '' "
      else
	echoerr "Internal error detected, couldn't locate value for " .
	      \ selectedSetting
      endif
    endif
    let newVal = input("Current value for " . selectedSetting . " is: " .
	  \ oldVal . "\nEnter new value: ", oldVal)
    if newVal !=# oldVal
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
  "let s:showDetails = ! s:showDetails
  "call s:UpdateBuffers(1)
  call SaveSoftPosition('ToggleDetails')
  if s:showDetails
    call s:RemoveColumn((!s:hideBufNums) * 5 + 1, 6, 0)
  else
    if s:hideBufNums
      call s:AddBufNumbers()
    endif
    if search('^"= ', "w")
      let _search = @/
      setlocal modifiable
      try
        let @/ = '\%6c'
        silent! keepjumps +,$s//\=s:GetBufIndicators(SBCurBufNumber())/e
      finally
        let @/ = _search
        setlocal nomodifiable
      endtry
    endif
    if s:hideBufNums
      call s:RemoveBufNumbers()
    endif
  endif
  let s:showDetails = ! s:showDetails
  call s:UpdateHeader()
  call s:SetupSyntax()
  call RestoreSoftPosition('ToggleDetails')
  call ResetSoftPosition('ToggleDetails')
endfunction


function! s:ToggleHidden()
  if s:enableDynUpdate
    let i = 1
    let lastBufNr = bufnr('$')
    while i <= lastBufNr
      if bufexists(i) && ! buflisted(i) && ! s:IgnoreBuf(i)
        if s:showHidden
          call s:BufDeleteImpl(i, 1, 'd')
        else
          call s:BufAddImpl(i, 1)
        endif
      endif
      let i = i + 1
    endwhile
    let s:showHidden = ! s:showHidden
    call s:UpdateHeader()
    call s:ListBufs()
  else
    let s:showHidden = ! s:showHidden
    call s:UpdateBuffers(1)
  endif
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
  call ResetHardPosition('ToggleHideBufNums')
  call s:SetupSyntax()
endfunction


function! s:ToggleHidePaths()
  call SaveSoftPosition('ToggleHidePaths')
  call s:RemoveColumn((!s:hideBufNums) * 5 + (s:showDetails) * 6 +
        \ (s:showDetails || !s:hideBufNums) +
        \ (s:showPaths == 2) * (s:curBufNameLen + 1), -1, 0)
  let s:showPaths = (s:showPaths == 2) ? 0 : s:showPaths + 1
  if s:showPaths > 0
    setlocal modifiable
    if s:hideBufNums
      call s:AddBufNumbers()
    endif
    call search('^"= ', "w")
    let _search = @/
    try
      let @/ = '$'
      keepjumps +,$s//\=escape(s:GetBufName(SBCurBufNumber()), '\')/e
    finally
      let @/ = _search
      if s:hideBufNums
        call s:RemoveBufNumbers()
      endif
      setlocal nomodifiable
    endtry
  endif
  call s:UpdateHeader()
  call RestoreSoftPosition('ToggleHidePaths')
  call ResetSoftPosition('ToggleHidePaths')
  call s:SetupSyntax()
endfunction

"" END: Toggle methods }}}

" MRU support {{{
function! s:PushToFrontInMRU(bufNum, updImm)
  " Avoid browser buffer to come in the front.
  if a:bufNum == -1 || a:bufNum == s:myBufNum || s:disableMRUlisting
      return
  endif
  if s:IgnoreBuf(a:bufNum)
    return
  endif

  let s:MRUlist = MvPushToFront(s:MRUlist, ',', a:bufNum)
  let g:MRUlist = s:MRUlist
  if s:GetSortNameByType(s:sorttype) ==# 'mru'
    call s:DynUpdate('m', a:bufNum + 0, !a:updImm)
  else
    call s:DynUpdate('u', a:bufNum + 0, !a:updImm)
  endif
endfunction

function! s:PushToBackInMRU(bufNum, updImm)
  if a:bufNum == -1 || a:bufNum == s:myBufNum || s:disableMRUlisting
    return
  endif
  if s:IgnoreBuf(a:bufNum)
    return
  endif

  let s:MRUlist = MvPullToBack(s:MRUlist, ',', a:bufNum)
  let g:MRUlist = s:MRUlist
  if s:GetSortNameByType(s:sorttype) ==# 'mru'
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

function! s:IgnoreBuf(bufNum) " {{{
  if s:ignoreNonFileBufs && (getbufvar(a:bufNum, '&buftype') != '' ||
        \ (bufname(a:bufNum)[0] ==# '[' && bufname(a:bufNum) =~# ']$'))
    return 1
  endif
  return 0
endfunction " }}}

function! s:BufName(bufNum) " {{{
  let bufName = bufname(a:bufNum)
  if bufName == ""
    let bufName = "[No File]"
  endif
  return bufName
endfunction " }}}

function! s:FileName(bufNum) " {{{
  let fileName = expand('#'.a:bufNum.':p:t')
  if fileName == ""
    let fileName = "[No File]"
  endif
  return fileName
endfunction " }}}

function! s:CalcMaxBufNameLen(skipBuf, skipHidden) " {{{
  let i = 1
  let maxBufNameLen = -1
  let lastBufNr = bufnr('$')
  while i <= lastBufNr
    try
      let fileName = s:FileName(i)
      if bufexists(i) && !s:IgnoreBuf(i) && maxBufNameLen < strlen(fileName) &&
            \ i != a:skipBuf
        if !buflisted(i) && a:skipHidden
          continue
        endif
        let maxBufNameLen = strlen(fileName)
      endif
    finally
      let i = i + 1
    endtry
  endwhile
  if maxBufNameLen < 9
    let maxBufNameLen = 9 " Min length of '[No File]'
  endif
  return maxBufNameLen
endfunction " }}}

function! s:MultiSelectionExists() " {{{
  if s:MSExists() && MSSelectionExists()
    return 1
  else
    return 0
  endif
endfunction " }}}

function! s:MSExists() " {{{
  if exists('g:loaded_multiselect') && g:loaded_multiselect >= 100
    return 1
  else
    return 0
  endif
endfunction " }}}

function! s:InitializeMRU() " {{{
  " Initialize with the bufers that might have been already loaded. This is
  "   required to show the buffers that are loaded by specifying them as
  "   command-line arguments (Reported by David Fishburn).
  if s:MRUlist == ''
    let createMode = 1
  else
    let createMode = 0 " Update mode.
  endif
  if ! s:disableMRUlisting
    let i = 1
    let lastBufNr = bufnr('$')
    while i <= lastBufNr
      if bufexists(i)
        if createMode
          let s:MRUlist = s:MRUlist . i . ','
        else
          if !MvContainsElement(s:MRUlist, ',', i)
            let s:MRUlist = s:MRUlist . i . ','
          endif
        endif
      endif
      let i = i + 1
    endwhile
  endif
endfunction " }}}

function! s:InputBufNumber() " {{{
  " Generate a line with spaces to clear the previous message.
  let i = 1
  let clearLine = "\r"
  while i < &columns
    let clearLine = clearLine . ' '
    let i = i + 1
  endwhile

  let bufNr = ''
  let abort = 0
  call s:Prompt(bufNr)
  let breakLoop = 0
  while !breakLoop
    try
      let char = getchar()
    catch /^Vim:Interrupt$/
      let char = "\<Esc>"
    endtry
    "exec BPBreakIf(cnt == 1, 2)
    if char == '^\d\+$' || type(char) == 0
      let char = nr2char(char)
    endif " It is the ascii code.
    if char == "\<BS>"
      let bufNr = strpart(bufNr, 0, strlen(bufNr) - 1)
    elseif char == "\<Esc>"
      let breakLoop = 1
      let abort = 1
    elseif char == "\<CR>"
      let breakLoop = 1
    else
      let bufNr = bufNr . char
    endif
    echon clearLine
    call s:Prompt(bufNr)
  endwhile
  if !abort && bufNr != ''
    call search('^'.bufNr.'\>', 'w')
  endif
endfunction

function! s:Prompt(bufNr)
  echon "\rEnter Buffer Number: " . a:bufNr
endfunction " }}}
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
  elseif a:sortname ==# "number"
    return 0
  elseif a:sortname ==# "name"
    return 1
  elseif a:sortname ==# "path"
    return 2
  elseif a:sortname ==# "type"
    return 3
  elseif a:sortname ==# "indicators"
    return 4
  elseif a:sortname ==# "mru"
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
  let name1 = expand('#'.s:GetBufferNumber(a:line1).':t')
  let name2 = expand('#'.s:GetBufferNumber(a:line2).':t')

  if (s:ignoreCaseInSort && name1 <? name2) || (!s:ignoreCaseInSort && name1 <# name2)
    return -a:direction
  elseif (s:ignoreCaseInSort && name1 >? name2) || (!s:ignoreCaseInSort && name1 ># name2)
    return a:direction
  else
    return 0
  endif
endfunction

function! s:CmpByPath(line1, line2, direction)
  if s:showPaths
    if s:showPaths == 2
      let name1 = strpart(a:line1, (s:showDetails?11:5)+s:curBufNameLen) .
	    \ strpart(a:line1, (s:showDetails?11:5), s:curBufNameLen)
      let name2 = strpart(a:line2, (s:showDetails?11:5)+s:curBufNameLen) .
	    \ strpart(a:line2, (s:showDetails?11:5), s:curBufNameLen)
    else
      let name1 = strpart(a:line1, (s:showDetails?11:5))
      let name2 = strpart(a:line2, (s:showDetails?11:5))
    endif

    if (s:ignoreCaseInSort && name1 <? name2) ||
          \ (!s:ignoreCaseInSort && name1 <# name2)
      return -a:direction
    elseif (s:ignoreCaseInSort && name1 >? name2) ||
          \ (!s:ignoreCaseInSort && name1 ># name2)
      return a:direction
    endif
  endif
  return 0
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
  let type1 = expand('#'.s:GetBufferNumber(a:line1).':e')
  let type2 = expand('#'.s:GetBufferNumber(a:line2).':e')

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
  if s:showDetails
    let ind1 = matchstr(a:line1, '^.....\zs.....')
    let ind2 = matchstr(a:line2, '^.....\zs.....')

    if ind1 < ind2
      return -a:direction
    elseif ind1 > ind2
      return a:direction
    endif
  endif
  return 0
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

  try
    " Allow modification
    setlocal modifiable
    " Do the sort
    if search('^"= ', 'w')
      silent! .+1,$call BinInsertSort(s:GetSortCmpFnByType(
	    \ s:GetSortTypeByName(s:sorttype)), s:sortdirection)
    endif
  finally
    " Disallow modification
    setlocal nomodifiable
  endtry

  " Update buffer-list again with the sorted list.
  if a:bufNumsHidden
    call s:RemoveBufNumbers()
  endif

  " Replace the header with updated information
  call s:UpdateHeader()

  " Return to the position we started on
  call RestoreSoftPosition('SortBuffers')
  call ResetSoftPosition('SortBuffers')
endfunction

" END: Interface to Sort. }}}

"""
""" END: Support for sorting... based on explorer.vim }}}


" Public API {{{
function! SBUpdateBuffer(bufNr)
  if bufexists(a:bufNr+0)
    call s:DynUpdate('u', a:bufNr + 0, 0)
  endif
endfunction

function! SBCurBufNumber()
  return SBBufNumber(line('.'))
endfunction

function! SBBufNumber(line)
  " Even when buffer numbers are hidden, we sometimes turn them on
  "   temporarily, so detect it and take advantage of it for faster buffer
  "   number determination.
  if s:hideBufNums && getline(a:line) !~# '^\d\+\s\+'
    if a:line <= s:headerSize
      return -1
    endif

    let bufIndex = a:line - s:headerSize - 1
    let bufNo = MvElementAt(s:bufList, "\n", bufIndex) + 0
    if bufNo == ""
      return -1
    else
      return bufNo + 0
    endif
  else
    return s:GetBufferNumber(getline(a:line))
  endif
endfunction

" Can't accept range as the user will not be able to use the return value then.
function! SBSelectedBuffers(fline, lline) " range 
  let bufNums = SBSelectedBufNums(a:fline, a:lline)
  let bufList = ''
  if bufNums != ''
    let bufList = substitute(bufNums, '\d\+', '#&:p', 'g')
  endif
  return bufList
endfunction

function! SBSelectedBufNums(fline, lline) " range 
  let bufNums = ''
  " FIXME: When a:firstline == a:lastline, currently there seems to be no
  "   reliable way to detect if the command was executed on the visual range
  "   (as it could be the default range too), but the third condition here
  "   should be sufficient for most of the cases.
  if s:MultiSelectionExists() &&
        \!((a:fline != a:lline) ||
        \  (a:fline == a:lline && line("'<") == line("'>") &&
        \   a:fline == line("'<")))
    call MSStartSelectionIter()
    while MSHasNextSelection()
      let sel = MSNextSelection()
      let fl = MSFL(sel)
      let ll = MSLL(sel)
      while fl <= ll
        let bufNo = s:GetBufferNumber(getline(fl))
        if bufNo != -1
          let bufNums = bufNums . bufNo.' '
        endif
        let fl = fl + 1
      endwhile
    endwhile
    call MSStopSelectionIter()
  elseif a:fline > 0 && a:lline > 0
    let fl = a:fline
    while fl <= a:lline
      let bufNo = s:GetBufferNumber(getline(fl))
      if bufNo != -1
        let bufNums = bufNums . bufNo.' '
      endif
      let fl = fl + 1
    endwhile
  endif
  return bufNums
endfunction

""" BEGIN: Experimental API {{{

function! SBGet(var)
  return {a:var}
endfunction

function! SBSet(var, val)
  let {a:var} = a:val
endfunction

function! SBCall(func, ...)
  exec MakeArgumentString()
  exec "let result = {a:func}(".argumentString.")"
  return result
endfunction

function! SBEval(expr)
  exec "let result = ".a:expr
  return result
endfunction

""" END: Experimental API }}}
" Public API }}}
 

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

" Do the actual initialization.
call s:Initialize()

call s:InitializeMRU()

" Restore cpo.
let &cpo = s:save_cpo
unlet s:save_cpo

" vim6:fdm=marker et sw=2
