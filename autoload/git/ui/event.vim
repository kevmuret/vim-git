let s:git_ui_events = {}
let s:events_map = {
	\ 'dblclick': '<2-LeftRelease>',
	\ 'enter': '<Enter>',
\ }
function git#ui#event#bind_all(namespace) abort
	for l:evtname in keys(s:git_ui_events[a:namespace])
		if exists('s:events_map[l:evtname]')
			let l:mapinput = s:events_map[l:evtname]
		else
			let l:mapinput = l:evtname
		endif
		execute 'noremap <buffer><silent> '.l:mapinput.' :call git#ui#event#trigger("'.l:evtname.'","'.a:namespace.'")<CR>'
	endfor
endfunction

function git#ui#event#unbind_all(namespace) abort
	for l:evtname in keys(s:git_ui_events[a:namespace])
		if exists('s:events_map[l:evtname]')
			let l:mapinput = s:events_map[l:evtname]
		else
			let l:mapinput = l:evtname
		endif
		if mapcheck(l:mapinput, 'n')
			execute 'unmap '.l:mapinput
		endif
	endfor
endfunction

function git#ui#event#trigger(evtname, namespace) abort
	let l:lnum = line('.')
	let l:col = col(".")
	let l:vlnum = line("'<")
	let l:vlnumend = line("'<")
	let l:vcol = col("'<")
	let l:vcolend = col("'>")
	let l:textsel = getline(l:lnum)[l:vcol-1:l:vcolend-1]
	let l:synstack = synstack(l:lnum, l:col)
	let l:vsynstack = synstack(l:vlnum, l:vcol)
	let l:vsynstackend = synstack(l:vlnumend, l:vcolend)
	call s:git_ui_events[a:namespace][a:evtname]({
		\ 'lnum': l:lnum,
		\ 'col': l:col,
		\ 'vlnum': l:vlnum,
		\ 'vlnumend': l:vlnumend,
		\ 'vcol': l:vcol,
		\ 'vcolend': l:vcolend,
		\ 'textsel': l:textsel,
		\ 'synname': len(l:synstack) < 1 ? '' : synIDattr(l:synstack[len(l:synstack) - 1], 'name'),
		\ 'vsynname': len(l:vsynstack) < 1 ? '' : synIDattr(l:vsynstack[len(l:vsynstack) - 1], 'name'),
		\ 'vsynnameend': len(l:vsynstackend) < 1 ? '' : synIDattr(l:vsynstackend[len(l:vsynstackend) - 1], 'name'),
	\ })
endfunction

function git#ui#event#on(namespace, evtname, handler) abort
	if !exists('s:git_ui_events[a:namespace]')
		let s:git_ui_events[a:namespace] = {}
	endif
	let s:git_ui_events[a:namespace][a:evtname] = a:handler
endfunction

