# git-vim
Complete Git integration for vim with UI tabs for graphs and commit.

# Features
![GitGraph-followgraph-2024-04-28154451](https://github.com/kevmuret/vim-git/assets/7468255/e8ac7151-47bf-405e-bdc3-640f5e84d94f)
![GitCommit-2024-04-28155314](https://github.com/kevmuret/vim-git/assets/7468255/d4841445-4a5b-4c71-889b-66c6921b8d35)
![GitDiffandsigns-2024-04-28161342](https://github.com/kevmuret/vim-git/assets/7468255/2e9d1397-af9a-4313-be94-24ecba219c8f)
![Gitcommands-2024-04-28162031](https://github.com/kevmuret/vim-git/assets/7468255/4753d46d-4a6a-4a49-be1f-92e78833822f)

# TODO
- A Tree explorator UI.
- Others usefull UI and commands... 

# Installation
## Manual
Copy/paste ```autoload```, ```syntax``` and ```plugin``` directories contents in your ```$HOME/.vim``` folder.

## Plugin manager vim-plug
Use this repo name : ```Plug 'kevmuret/vim-git'```.

# How to use
## Options
|Variable name|Type|Description|Default|
|----|----|----|----|
|g:git_cmd_path|String|Define path to the git command.|```'git'```|
|g:git_history_max_follow_graph|Number|Number of lines to follow a graph when dbl clicking it increase/decrease with caution on a large repository.|```10000```|

## Commands
|Command|Description|Arguments|
|----|----|----|
|GitLogLine|Display a popup menu bellow cursor line which list commits for the selected or cursor line.||
|GitLogFile|Display a popup menu bellow cursor line which list commits on the current file.||
|GitGraph|Open a tab with the asked graph.|Any valid options of the ```git log```command.|
|GitGraphFile|Open a tab with a graph of commits for the current file.||
|GitCommitShow|Open a tab with the asked commit.|Required a valid revision identifier (hash, branch, ...).|
|GitDiff|Split the window vertically to show diffs of the current file against the current HEAD version.|
|GitDiffSigns|Force update of the current file's buffer signs.||
|Git|Launch some git's commands, they can be chained with ```&&``` and ```\|\|``` operators.|See [Git command](#git-command) section.|

## Git command
The ```:Git``` command is a very handy way to run git commands, it's include command aware autocomplete like branch/rev completion and added/staged files completion. Commands are executing in embeded terminal to allow user interactions, stderr will be appended inside the ```Git cmd``` special tab which act as a command history but stdout will be lost.

Here is the list of launchable commands, since they are jutst git commands they all have the same options/behaviour as the original git command :
- add
- branch
- checkout
- cherry-pick
- commit
- fetch
- merge
- pull
- push
- rebase
- restore
- stash
- switch
