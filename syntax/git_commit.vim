if !exists('main_syntax')
	let main_syntax = 'gitcommit'
endif

runtime! syntax/git_common.vim

syn region gitCommitLine  	oneline keepend matchgroup=gitCommitDecoration start="[┌│└]" end="$" contains=@gitCommitLineCluster

syn cluster gitCommitLineCluster contains=gitCommitHeader,gitCommitFileEdit,gitCommitFileNew,gitCommitFileDelete,gitCommitHash,gitCommitAuthor,gitCommitDate

syn keyword gitCommitHeader	contained	Commit Merge Author Date Message Files
syn region gitCommitFileEdit	matchgroup=DiffChange contained	keepend start="🖉\t" end="$" contains=@gitCommitFileLine
syn region gitCommitFileNew	matchgroup=DiffAdd contained	keepend start="+\t" end="$" contains=@gitCommitFileLine
syn region gitCommitFileDelete	matchgroup=DiffDelete contained	keepend start="-\t" end="$" contains=@gitCommitFileLine

syn cluster gitCommitFileLine contains=gitCommitHashes,gitCommit3Hashes,gitCommitFile

syn match gitCommitFile		contained "[^\t]\+$"
syn match gitCommit3Hashes		contained "[0-9a-f]\+,[0-9a-f]\+\.\.[0-9a-f]\+"
syn match gitCommitHashes		contained "[0-9a-f]\+\.\.[0-9a-f]\+"

hi def link gitCommitDecoration	NonText
hi def link gitCommitHeader	Special
hi def link gitCommitIcon	SpecialKey
hi def link gitCommitFile	Directory
hi def link gitCommitHashes	Constant
hi def link gitCommit3Hashes	Constant
