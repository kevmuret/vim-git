if !exists('main_syntax')
	let main_syntax = 'git_commit_popup'
endif

runtime! syntax/git_common.vim

syn match gitCommitPopupMessage	"\t[^\t]\+$"
syn region gitCommitPopup	oneline keepend start=" " end="$" contains=@gitCommitPopupCluster
syn cluster gitCommitPopupCluster contains=gitCommitGraph,gitCommitDate,gitCommitAuthor,gitCommitPopupMessage
syn match gitCommitGraph	"^\([*\|][ _\\/]\)\+"
