if !exists('main_syntax')
	let main_syntax = 'gitcommit'
endif

runtime! syntax/diff.vim
unlet b:current_syntax
runtime! syntax/git_common.vim

syn region gitCommitLine  	oneline keepend matchgroup=gitCommitDecoration start="[┌│└]" end="$" contains=@gitCommitLineCluster

syn cluster gitCommitLineCluster contains=gitCommitHeader,gitCommitFileEdit,gitCommitFileNew,gitCommitFileDelete,gitCommitHash,gitCommitAuthor,gitCommitDate

"syn match gitCommitAuthor	contained	"<[^]]\+@[^@]\+>"
"syn match gitCommitHash		contained	"[0-9a-f]\{4,}"
"syn match gitCommitDate		contained	"[A-Z][a-z]\{2\} [A-Z][a-z]\{2\} [0-9]\{1,2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\} [0-9]\{4\}\( +[0-9]\{4\}\)\?"
syn keyword gitCommitHeader	contained	Commit Merge Author Date Message Files
syn region gitCommitFileEdit	matchgroup=DiffChange contained	keepend start="🖉\t" end="$" contains=@gitCommitFileLine
syn region gitCommitFileNew	matchgroup=DiffAdd contained	keepend start="+\t" end="$" contains=@gitCommitFileLine
syn region gitCommitFileDelete	matchgroup=DiffDelete contained	keepend start="-\t" end="$" contains=@gitCommitFileLine

syn cluster gitCommitFileLine contains=gitCommitHash,gitCommitFile

syn match gitCommitFile		contained "[^\t]\+$"
syn match gitCommitHash		contained "[0-9a-f]\+\.\.[0-9a-f]\+"

hi def link gitCommitDecoration	NonText
hi def link gitCommitHeader	Special
hi def link gitCommitIcon	SpecialKey
hi def link gitCommitFile	Directory
hi def link gitCommitHash	Constant
