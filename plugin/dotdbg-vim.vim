sign define brk text=-> texthl=Search
nnoremap <F9> :call sign_place(expand('%') + '-' + line("."), '', 'brk', expand('%'), { 'lnum': line(".")})<CR>
nnoremap <C-F9> :call sign_unplace('', { 'id': expand('%') + '-' + line(".")})<CR>
nnoremap <C-F10> :call StartDebugger()
nnoremap <C-F11> :call RunTest()

function! MicrosoftDocs()
  let type = OmniSharp#py#eval('getFullType()')['type']
  silent execute "!xdg-open 'https://docs.microsoft.com/en-us/dotnet/api/".type."?view=netcore-2.2'"
endfunction

function! SourceLookup()
  let type = OmniSharp#py#eval('getFullType()')['type']
  silent execute '!xdg-open "https://source.dot.net/\#q='.type.'"'
endfunction

function! DebugTest()
  call InitDebugger("debugTest", {'name': OmniSharp#py#eval('getFullType()')['type']})
endfunction

function! RunTest()
  let ch = ch_open('localhost:4321', { "mode": "json" })
  let obj = { "command": "runTest" }
  let obj["name"] = OmniSharp#py#eval('getFullType()')['type']
  let obj["filename"] = expand('%:p')

  call ch_sendexpr(ch, obj)
endfunction

function! StartDebugger()
  call InitDebugger("debugProgram", {})
endfunction

function! InitDebugger(command, obj)
  let g:db_files = []
  " call job_start('node /home/jpfeiffer/Source/dotdbg/dotdbg/app.js')
  " let term = term_start('node /home/jpfeiffer/Source/dotdbg/dotdbg/client/client.js')
  " sleep 300m
  let ch = ch_open('localhost:4321', { "mode": "json", "callback": "DebuggerHandle", "close_cb": "DebuggerCloseHandle" })
  let obj = a:obj
  let obj["command"] = a:command
  let obj["filename"] = fnamemodify(expand("%"), ":p")
  let breakpoints = sign_getplaced()
  for i in breakpoints
    let inner = i['signs']
    let i['filename'] = fnamemodify(bufname(i['bufnr']), ":p")
  endfor
  let obj["breakpoints"] = breakpoints
  call ch_sendexpr(ch, obj, { "callback": "DebuggerHandle" })
endfunction

function! DebuggerHandle(ch, msg)
  " echo "received"
  let cmd = a:msg["command"]
  if cmd == "highlight"
    call add(g:db_files, a:msg["file"])
    execute 'e '.a:msg["file"]
    match
    execute 'match Search /\%'.a:msg["lineNumber"].'l/'
    execute 'normal! '.a:msg["lineNumber"].'G'
    execute 'normal! zz'
  endif
  if cmd == "clearHighlights"
    match
  endif
endfunction

function! DebuggerCloseHandle(ch)
  " echo "closed"
  for db_file in g:db_files
    execute 'e '.db_file
    execute 'match'
    match
  endfor
endfunction
