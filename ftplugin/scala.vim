setlocal formatoptions=crq
setlocal textwidth=100
setlocal foldmethod=marker
setlocal foldmarker=//{,//}
setlocal foldlevel=0
setlocal ts=2 sts=2 sw=2
setlocal expandtab

"-----------------------------------------------------------------------------
" SBT Quickfix settings
"-----------------------------------------------------------------------------
let g:quickfix_load_mapping = ",qf"
let g:quickfix_next_mapping = ",qn"

"-----------------------------------------------------------------------------
" Transforming from ⇒and ←to => and <- and back again
"-----------------------------------------------------------------------------
function! scala#UnicodeCharsToNiceChars()
  let view = winsaveview()
  norm!mz
  try
    undojoin
  catch /undojoin/
  endtry
  v/^\s*\*/s/⇒/=>/eg
  v/^\s*\*/s/←/<-/eg
  norm!`z
  call winrestview(view)
endfunction

function! scala#NiceCharsToUnicodeChars()
  let view = winsaveview()
  norm!mz
  try
    undojoin
  catch /undojoin/
  endtry
  v/^\s*\*/s/=>/⇒/eg
  v/^\s*\*/s/<-/←/eg
  norm!`z
  call winrestview(view)
endfunction

map ,SU :call scala#NiceCharsToUnicodeChars()<cr>
map ,SA :call scala#UnicodeCharsToNiceChars()<cr>


"-----------------------------------------------------------------------------
" Transitioning between test files and source files
"-----------------------------------------------------------------------------
if !exists("*s:CodeOrTestFile")
  function! s:CodeOrTestFile(precmd)
  	let current = expand('%:p')
  	let other = current
    let specExt = "Spec.scala"
    if current =~ "/npl/"
      let specExt = "Test.scala"
    endif
  	if current =~ "/src/main/"
  		let other = substitute(current, "/main/", "/it/", "")
  		let other = substitute(other, ".scala$", specExt, "")
      if !filereadable(other)
        let other = substitute(current, "/main/", "/test/", "")
        let other = substitute(other, ".scala$", specExt, "")
      endif
  	elseif current =~ "/src/test/"
  		let other = substitute(current, "/test/", "/main/", "")
  		let other = substitute(other, specExt . "$", ".scala", "")
  	elseif current =~ "/src/it/"
  		let other = substitute(current, "/it/", "/main/", "")
  		let other = substitute(other, specExt . "$", ".scala", "")
    elseif current =~ "/app/model/"
  		let other = substitute(current, "/app/model/", "/test/", "")
  		let other = substitute(other, ".scala$", specExt, "")
    elseif current =~ "/app/controllers/"
  		let other = substitute(current, "/app/", "/test/scala/", "")
  		let other = substitute(other, ".scala$", specExt, "")
  	elseif current =~ "/test/scala/controllers/"
  		let other = substitute(current, "/test/scala/", "/app/", "")
  		let other = substitute(other, specExt . "$", ".scala", "")
  	elseif current =~ "/test/"
  		let other = substitute(current, "/test/", "/app/model/", "")
  		let other = substitute(other, specExt . "$", ".scala", "")
  	endif
    if &switchbuf =~ "^use"
      let i = 1
      let bufnum = winbufnr(i)
      while bufnum != -1
        let filename = fnamemodify(bufname(bufnum), ':p')
        if filename == other
          execute ":sbuffer " . filename
          return
        endif
        let i += 1
        let bufnum = winbufnr(i)
      endwhile
    endif
    if other != ''
      if strlen(a:precmd) != 0
        execute a:precmd
      endif
      execute 'edit ' . fnameescape(other)
    else
      echoerr "Alternate has evaluated to nothing."
    endif
  endfunction
endif

com! -buffer ScalaSwitchHere       :call s:CodeOrTestFile('')
com! -buffer ScalaSwitchRight      :call s:CodeOrTestFile('wincmd l')
com! -buffer ScalaSwitchSplitRight :call s:CodeOrTestFile('let b:curspr=&spr | set nospr | vsplit | wincmd l | if b:curspr | set spr | endif | unlet b:curspr')
com! -buffer ScalaSwitchLeft       :call s:CodeOrTestFile('wincmd h')
com! -buffer ScalaSwitchSplitLeft  :call s:CodeOrTestFile('let b:curspr=&spr | set nospr | vsplit | wincmd h | if b:curspr | set spr | endif | unlet b:curspr')
com! -buffer ScalaSwitchAbove      :call s:CodeOrTestFile('wincmd k')
com! -buffer ScalaSwitchSplitAbove :call s:CodeOrTestFile('let b:cursb=&sb | set nosb | split | wincmd k | if b:cursb | set sb | endif | unlet b:cursb')
com! -buffer ScalaSwitchBelow      :call s:CodeOrTestFile('wincmd j')
com! -buffer ScalaSwitchSplitBelow :call s:CodeOrTestFile('let b:cursb=&sb | set nosb | split | wincmd j | if b:cursb | set sb | endif | unlet b:cursb')

nmap <buffer> <silent> ,of :ScalaSwitchHere<cr>
nmap <buffer> <silent> ,ol :ScalaSwitchRight<cr>
nmap <buffer> <silent> ,oL :ScalaSwitchSplitRight<cr>
nmap <buffer> <silent> ,oh :ScalaSwitchLeft<cr>
nmap <buffer> <silent> ,oH :ScalaSwitchSplitLeft<cr>
nmap <buffer> <silent> ,ok :ScalaSwitchAbove<cr>
nmap <buffer> <silent> ,oK :ScalaSwitchSplitAbove<cr>
nmap <buffer> <silent> ,oj :ScalaSwitchBelow<cr>
nmap <buffer> <silent> ,oJ :ScalaSwitchSplitBelow<cr>

function! ExternalScalariform()
  if &readonly == 1
    echomsg "Current buffer is read-only. Can't Scalariform it."
  else
    :normal mm
    :%!/webdev/Tools/lazy/bin/scalariform --stdin
    :normal `m
  endif
endfunction

com! -buffer Scalariform :call ExternalScalariform()
nmap <buffer> <silent> ,sf :Scalariform<cr>
