if !exists("g:git_cmd_path")
	let g:git_cmd_path = 'git'
endif

command! -nargs=1 GitCommitShow call git#commit#show(<f-args>)
command! -range GitLogLine call git#history#at_line(<line1>,<line2>,expand('%'))
command! -nargs=0 GitLogFile call git#history#file(expand('%'))
command! -nargs=* GitGraph call git#history#graph(<f-args>)
command! -nargs=0 GitGraphFile call git#history#graph_file(expand('%'))

command! -nargs=* -complete=customlist,git#cmd#custom_list Git call git#cmd#execute(<f-args>)

command! -nargs=0 GitDiffSigns call git#sign#place_file(expand('%'))
autocmd BufEnter * :GitDiffSigns
autocmd BufWrite * :GitDiffSigns

command! -nargs=* GitDiff call git#diff#buffer_versus(<f-args>)
