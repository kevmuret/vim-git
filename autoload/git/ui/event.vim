let s:git_ui_events = {}
let s:events_map = {
	\ 'dblclick': '<2-LeftRelease>',
	\ 'enter': '<Enter>',
\ }
function git#ui#event#bind_all(namespace) abort
	for l:evtname in keys(s:events_map)
		if exists('s:git_ui_events["'.a:namespace.'"]["'.l:evtname.'"]')
			execute 'noremap '.s:events_map[l:evtname].' :call git#ui#event#trigger("'.l:evtname.'","'.a:namespace.'")<CR>'
		endif
	endfor
endfunction

function git#ui#event#unbind_all(namespace) abort
	for l:evtname in keys(s:events_map)
		if mapcheck(s:events_map[l:evtname], 'n')
			execute 'unmap '.s:events_map[l:evtname]
		endif
	endfor
endfunction

function git#ui#event#trigger(evtname, namespace) abort
	let l:lnum = line('.')
	let l:col = col("'<")
	let l:colend = col("'>")
	if !l:col
		let l:col = col('.')
	endif
	let l:textsel = getline(l:lnum)[l:col-1:l:colend-1]
	let l:synstack = synstack(l:lnum, l:col)
	call s:git_ui_events[a:namespace][a:evtname]({
		\ 'lnum': l:lnum,
		\ 'col': l:col,
		\ 'colend': l:colend,
		\ 'textsel': l:textsel,
		\ 'synname': len(l:synstack) < 1 ? '' : synIDattr(l:synstack[len(l:synstack) - 1], 'name'),
	\ })
endfunction

function git#ui#event#on(namespace, evtname, handler) abort
	if !exists('s:git_ui_events[a:namespace]')
		let s:git_ui_events[a:namespace] = {}
	endif
	let s:git_ui_events[a:namespace][a:evtname] = a:handler
endfunction

