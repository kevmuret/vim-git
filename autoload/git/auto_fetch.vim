let s:git_fetch_output = []
let s:git_auto_fetch_jobid = 0
function git#auto_fetch#read_output(chid, line) abort
	call add(s:git_fetch_output, a:line)
endfunction
function git#auto_fetch#fetch(timerid) abort
	let s:git_fetch_output = []
	let l:jobid = job_start(g:git_cmd_path.' --no-optional-locks fetch '.g:git_auto_fetch_args, {
		\ 'exit_cb': 'git#auto_fetch#fetch_exit',
		\ 'out_cb': 'git#auto_fetch#read_output',
		\ 'err_cb': 'git#auto_fetch#read_output',
	\ })
endfunction
function git#auto_fetch#fetch_exit(jobid, status) abort
	if len(s:git_fetch_output) > 0
		let l:popup_options = {
			\ 'pos': 'botright',
			\ 'line': &lines - 1,
			\ 'col': &columns - 1,
			\ 'highlight': 'WarningMsg',
			\ 'border': [],
			\ 'z-index': 300,
			\ 'padding': [0,1,0,1],
			\ 'close': 'button',
			\ 'time': v:null,
			\ 'tabpage': -1,
		\ }
		if !a:status && g:git_auto_fetch
			let l:popup_options['callback'] = 'git#auto_fetch#restart'
		else
			let g:git_auto_fetch = v:false
		endif
		call popup_create(s:git_fetch_output, l:popup_options)
	elseif g:git_auto_fetch
		let s:git_auto_fetch_jobid = timer_start(g:git_auto_fetch_interval, 'git#auto_fetch#fetch')
	endif
endfunction
function git#auto_fetch#restart(id, sel) abort
	call git#auto_fetch#fetch(0)
endfunction
function git#auto_fetch#toggle() abort
	if g:git_auto_fetch
		let g:git_auto_fetch = v:false
		return
	endif
	call git#auto_fetch#start()
endfunction
function git#auto_fetch#start() abort
	let g:git_auto_fetch = v:true
	call git#auto_fetch#fetch(0)
endfunction
