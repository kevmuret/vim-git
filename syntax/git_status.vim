if !exists('main_syntax')
	let main_syntax = 'gitstatus'
endif

runtime! syntax/git_common.vim

syn region gitStatusLine  	oneline keepend matchgroup=gitStatusDecoration start="[┌│└]" end="$" contains=@gitStatusLineCluster

syn cluster gitStatusLineCluster contains=gitStatusHeader,gitStatusHash,gitStatusAuthor,gitStatusDate

syn keyword gitStatusHeader	contained	Branch Staged Unstaged Untracked Unmerged files
syn region gitStatusFileEdit	matchgroup=DiffChange keepend start="^🖉\t" end="$" contains=@gitStatusFileLine
syn region gitStatusFileNew	matchgroup=DiffAdd keepend start="^+\t" end="$" contains=@gitStatusFileLine
syn region gitStatusFileDelete	matchgroup=DiffDelete keepend start="^-\t" end="$" contains=@gitStatusFileLine
syn region gitStatusFileIgnored	matchgroup=NonText keepend start="^!\t" end="$" contains=@gitStatusFileLine

syn cluster gitStatusFileLine contains=gitStatusFile

syn match gitStatusFile		contained "[^\t]\+$"

hi def link gitStatusDecoration	NonText
hi def link gitStatusHeader	Special
hi def link gitStatusFile	Directory
