sign define gitDelSign text=-- texthl=DiffDelete
sign define gitAddSign text=++ texthl=DiffAdd
sign define gitModSign text=!! texthl=DiffChange
sign define gitDelModSign text=!! texthl=DiffDelete

let s:diff_jobs = {}
let s:diff_jobs_byid = {}
function s:parse_diff_line(chid, line)
	let l:Parser_fn = call(s:diff_jobs[a:chid]['parser_fn'], [a:line])
	let s:diff_jobs[a:chid]['parser_fn'] = l:Parser_fn
endfunction
function s:read_diff_line(ch, msg, event)
	" a:event only apply to neovim
	if has('nvim')
		let s:diff_jobs[a:ch]['line_chunk'] .= a:msg[0]
		if len(a:msg) > 1
			for l:msg_line in extend([s:diff_jobs[a:ch]['line_chunk']], a:msg[1:-2])
				call s:parse_diff_line(a:ch, l:msg_line)
			endfor
			let s:diff_jobs[a:ch]['line_chunk'] = a:msg[-1]
		endif
	else
		let l:chid = matchstr(a:ch, '\(\d\+\)')
		call s:parse_diff_line(l:chid, a:msg)
	endif
endfunction
let s:signid = 0
function s:PlaceDiffSign(bufnr, filename, lnum, nlines, type) abort
	for l:id in range(0, a:nlines - 1)
		let s:signid += 1
		let l:signname = (a:type == 'A' ? 'gitAddSign' : (a:type == 'M' ? 'gitModSign' : (a:type == 'DM' ? 'gitDelModSign' : 'gitDelSign')))
		call sign_place(s:signid, 'GitDiffSigns', l:signname, a:bufnr, {
			\ 'lnum': a:lnum + l:id
		\ })
		if a:type == 'D' || a:type == 'DM'
			break
		endif
	endfor
endfunction
function git#sign#place_file(filepath)
	if &buftype != '' || trim(a:filepath) == ''
		return
	endif
	call sign_unplace('GitDiffSigns', {'buffer': bufnr(a:filepath)})
	if has('nvim')
		let b:vim_git_sign_diff_line_chunk = ''
		let l:jobid = jobstart('git diff -u HEAD -- '.a:filepath, {
			\ 'on_stdout': funcref('s:read_diff_line'),
			\ 'on_exit': funcref('s:exit_diff'),
		\ })
		let l:jobrealid = l:jobid
		let l:chrealid = l:jobid
	else
		let l:jobid = job_start('git diff -u HEAD -- '.a:filepath, {
			\ 'out_cb': funcref('s:read_diff_line'),
			\ 'exit_cb': funcref('s:exit_diff'),
		\ })
		let l:chid = job_getchannel(l:jobid)
		let l:jobrealid = matchstr(l:jobid, '\(\d\+\)')
		let l:chrealid = matchstr(l:chid, '\(\d\+\)')
	endif
	let l:parser_state = git#parser#diff#init(a:filepath, funcref('s:PlaceDiffSign', [bufnr(a:filepath)]))
	let s:diff_jobs[l:chrealid] = {
		\ 'jobid': l:jobrealid,
		\ 'chid': l:chrealid,
		\ 'parser_fn': funcref('git#parser#diff#parse_file', [l:parser_state]),
		\ 'parser_state': l:parser_state,
	\ }
	if has('nvim')
		let s:diff_jobs[l:chrealid]['line_chunk'] = ''
	endif
	let s:diff_jobs_byid[l:jobrealid] = s:diff_jobs[l:chrealid]
endfunction
function s:exit_diff(jobid, status, event)
	" a:event only apply to neovim
	let l:jobid = matchstr(a:jobid, '\(\d\+\)')
	let l:diff_job = s:diff_jobs_byid[l:jobid]
	if has('nvim') && l:diff_job['line_chunk'] != '' " Neovim job get an new line at the end skip it
		call s:parse_diff_line(a:jobid, l:diff_job['line_chunk'])
	endif
	call git#parser#diff#end(l:diff_job['parser_state'])
	unlet s:diff_jobs[l:diff_job['chid']]
	unlet s:diff_jobs_byid[l:jobid]
endfunction

