function git#utils#locate_git_dir(path) abort
	let l:path = trim(git#utils#relative_path(a:path), '/')
	while len(l:path) > 0
		if isdirectory(l:path.'/.git')
			return l:path.'/.git'
		endif
		let l:path = strpart(l:path, 0, strridx(l:path, '/'))
	endwhile
	return isdirectory('.git') ? '.git' : v:null
endfunction
function git#utils#relative_path(file_path, from_path=v:null) abort
	let l:from_path = type(a:from_path) == type(v:null) ? getcwd() : a:from_path
	let l:from_path_len = len(l:from_path)
	if strpart(a:file_path, 0, l:from_path_len) == l:from_path
		return strpart(a:file_path, l:from_path_len)
	endif
endfunction
function git#utils#get_git_path(path) abort
	if exists('b:git_path')
		return b:git_path
	endif
	let l:path = git#utils#locate_git_dir(a:path)
	let l:last_dirsep = strridx(l:path, '/')
	let b:git_path = l:last_dirsep < 0 ? '' : strpart(l:path, 0, l:last_dirsep)
	return b:git_path
endfunction
function git#utils#get_git_relative_path(path) abort
	return git#utils#relative_path(a:path, git#utils#get_git_path(a:path))
endfunction
