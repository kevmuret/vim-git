sign define gitDelSign text=-- texthl=DiffDelete
sign define gitAddSign text=++ texthl=DiffAdd
sign define gitModSign text=!! texthl=DiffChange

let s:diff_jobs = {}
let s:diff_jobid = 0
let s:diff_jobs_byid = {}
function s:parse_diff_changes(ch, msg)
	let l:new_sign = v:null
	let l:chid = matchstr(a:ch, '\(\d\+\)')
	let l:diff_job = s:diff_jobs[l:chid]
	if a:msg =~ '^@@ '
		let l:linenum_infos = matchlist(a:msg, '^@@\(\( [+-]\d\+,\d\+\)*\)')
		if len(l:linenum_infos) > 0
			for l:linenum in split(l:linenum_infos[1][1:], ' ')
				let l:infos = matchlist(l:linenum, '\([+-]\)\(\d\+\),\(\d\+\)')
				if l:infos[1] == '+'
					let l:diff_job['sign_linenum'] = str2nr(l:infos[2]) - 1
					break
				endif
			endfor
		endif
	elseif a:msg =~'^[+-]'
		if a:msg =~ '^-'
			if l:diff_job['del_linenum'] == 0
				let l:diff_job['del_linenum'] = l:diff_job['sign_linenum']
				let l:diff_job['del_nlines'] = 0
			endif
			let l:diff_job['del_nlines'] += 1
		else
			let l:sign_name = 'gitAddSign'
			if l:diff_job['del_nlines'] && l:diff_job['sign_linenum'] >= l:diff_job['del_linenum']
				let l:sign_name = 'gitModSign'
				let l:diff_job['del_nlines'] -= 1
			endif
			let l:diff_job['sign_linenum'] += 1
			let l:new_sign = {
				\ 'name': l:sign_name,
				\ 'lnum': l:diff_job['sign_linenum'],
			\ }
		endif
	else
		if l:diff_job['sign_linenum'] == l:diff_job['del_linenum']
			let l:new_sign = {
				\ 'name': 'gitDelSign',
				\ 'lnum': l:diff_job['sign_linenum'] == 0 ? 1 : l:diff_job['sign_linenum'],
			\ }
		endif
		let l:diff_job['del_linenum'] = 0
		let l:diff_job['del_nlines'] = 0
		let l:diff_job['sign_linenum'] += 1
	endif
	if !l:diff_job['del_nlines']
		let l:diff_job['del_linenum'] = 0
	endif
	if type(l:new_sign) != type(v:null)
		let l:diff_job['sign_id'] += 1
		call sign_place(l:diff_job['sign_id'], 'GitDiffSigns', l:new_sign['name'], l:diff_job['sign_bufnr'], {'lnum': l:new_sign['lnum']})
	endif
	return funcref('s:parse_diff_changes')
endfunction
function s:parse_diff_bof_changes(ch, msg)
	if a:msg =~ '^@@ '
		call s:parse_diff_changes(a:ch, a:msg)
		return funcref('s:parse_diff_changes')
	endif
	return funcref('s:parse_diff_bof_changes')
endfunction
function s:read_diff_line(ch, msg)
	let l:chid = matchstr(a:ch, '\(\d\+\)')
	let l:Parser_state = call(s:diff_jobs[l:chid]['parser_state'], [a:ch, a:msg])
	let s:diff_jobs[l:chid]['parser_state'] = l:Parser_state
endfunction
function git#sign#place_file(filepath)
	if &buftype == 'nofile'
		return
	endif
	call sign_unplace('GitDiffSigns', {'buffer': bufnr(a:filepath)})
	let l:jobid = job_start('git diff HEAD -- '.a:filepath, {
		\ 'out_cb': funcref('s:read_diff_line'),
		\ 'exit_cb': funcref('s:exit_diff'),
	\ })
	let l:chid = job_getchannel(l:jobid)
	let l:jobrealid = matchstr(l:jobid, '\(\d\+\)')
	let l:chrealid = matchstr(l:chid, '\(\d\+\)')
	let s:diff_jobs[l:chrealid] = {
		\ 'jobid': l:jobrealid,
		\ 'chid': l:chrealid,
		\ 'parser_state': funcref('s:parse_diff_bof_changes'),
		\ 'sign_bufnr': bufnr(a:filepath),
		\ 'sign_linenum': 0,
		\ 'sign_id': 0,
		\ 'del_linenum': 0,
		\ 'del_nlines': 0,
	\ }
	let s:diff_jobs_byid[l:jobrealid] = s:diff_jobs[l:chrealid]
endfunction
function s:exit_diff(jobid, status)
	unlet s:diff_jobs[s:diff_jobs_byid[matchstr(a:jobid, '\(\d\+\)')]['chid']]
	unlet s:diff_jobs_byid[matchstr(a:jobid, '\(\d\+\)')]
endfunction

