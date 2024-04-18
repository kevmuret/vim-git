function git#remote#custom_list(arglead, cmd, curpos)
	let l:remotes = git#system#call_list('remote -v')
	let l:result = []
	echom l:remotes
	for l:remoteline in l:remotes
		let l:remote = matchstr(l:remoteline, '^'.a:arglead.'[^	]*')
		if l:remote != ''
			call add(l:result, l:remote)
		endif
	endfor
	return l:result
endfunction
