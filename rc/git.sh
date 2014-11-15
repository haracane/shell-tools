function git-add-commit() {
  local args="$*"
  if [ "$args" = "" ]; then args=.; fi
  git add $args
  git commit
}

function git-branch-copy() {
  src_branch=$1
  dst_branch=$2

  if [ "$src_branch" = "$dst_branch" ]; then return 0; fi

  current_refspec=$(git rev-parse --abbrev-ref HEAD)

  git checkout $src_branch
  if [ $? != 0 ]; then return 1; fi

  git-checkout-force $dst_branch
  if [ $? != 0 ]; then return 1; fi

  git checkout $current_refspec
}

function git-checkout-force() {
  local branch=$1
  if [ $branch = $(git rev-parse --abbrev-ref HEAD) ]; then
  	echo "Already on '$branch'" >&2
  	return 0
  fi
  git branch -D $branch > /dev/null 2>&1
  git checkout -b $branch
}

function git-checkout-remote() {
  local branch=$1
  git fetch
  git checkout $branch
  if [ $? != 0 ]; then return 1; fi
  git pull origin $branch
  if [ $? != 0 ]; then return 1; fi
}

function git-commit-each() {
  if [ "$*" != "" ]; then
    for file in $*; do
      if [ -f $file ]; then
        git add $file
        git commit -m "updated: $file"
      else
        git rm $file
        git commit -m "deleted: $file"
      fi
    done
    return
  fi

  for file in $(git status --short --untracked-files=all | grep "^ D" | awk '{print $2}'); do
    git rm $file
    git commit -m "deleted: $file"
  done
 
  for file in $(git status --short --untracked-files=all | grep "^ M" | awk '{print $2}'); do
    git add $file
    git commit -m "modified: $file"
  done
 
  for file in $(git status --short --untracked-files=all | grep "^??" | awk '{print $2}'); do
    git add $file
    git commit -m "added: $file"
  done
}

function git-hook() {
  cp ~/git/shell-tools/git/hooks/* .git/hooks/
}

function git-log-cherry-pick() {
  local count=${1:-10}
  git log --oneline | head -n $count | tac | sed 's/ / #/' | sed 's/^/git cherry-pick /g'
}

function git-merge() {
  local branch=$1

  local local_branch=$(git branch | grep "*" | awk '{print $2}')
  git checkout $branch
  if [ $? != 0 ]; then return 1; fi
  git pull origin $branch
  if [ $? != 0 ]; then return 1; fi
  git checkout $local_branch
  if [ $? != 0 ]; then return 1; fi
  git merge $branch
}

function git-parent-branch {
  local branch=${1:-$(git rev-parse --abbrev-ref HEAD)}
  local parent_branch=${branch%%-*}

  if [ "$parent_branch" = "$branch" ]; then
    parent_branch=master
  elif echo $branch | grep "^develop" > /dev/null; then
    parent_branch=develop
  elif echo $parent_branch | grep -v "feature/" > /dev/null; then
    parent_branch=master
  fi
  echo $parent_branch
}

function git-pull() {
  local repository=${1:-origin}
  local branch=${2:-$(git rev-parse --abbrev-ref HEAD)}
  git pull origin $branch
}

function git-pull-force() {
  local branch=$(git rev-parse --abbrev-ref HEAD)
  git-checkout-force tmp 2> /dev/null
  if [ $? != 0 ]; then return 1; fi
  git branch -D $branch > /dev/null 2>&1
  if [ $? != 0 ]; then return 1; fi
  git fetch
  if [ $? != 0 ]; then return 1; fi
  git checkout $branch
}

function github-push() {
  local repository=origin
  while true; do
    if [ "$1" = -f ]; then
      local f_option=$1; shift
    elif [ "$1" = --repo ]; then
      repository=$2; shift 2
    else break; fi
  done

  local branch=${1:-$(git rev-parse --abbrev-ref HEAD)}
  local parent_branch=${2:-master}

  git push $f_option $repository $branch \
  && github-urls $branch $parent_branch
}

function github-push-v2() {
  while true; do
    if [ "$1" = -f ]; then
      local f_option=$1; shift
    elif [ "$1" = --repo ]; then
      local repo_option="$1 $2"; shift
    elif [ "$1" = --no-number ]; then
      local no_number_option=$1; shift
    else break; fi
  done

  local src_refspec=${1:-$(git rev-parse --abbrev-ref HEAD)}
  local dst_refspec=${2:-$src_refspec}
  if [ "$no_number_option" = --no-number ]; then
    dst_refspec=$(echo $dst_refspec | perl -pe 's/[_\-][0-9]+$//g')
  fi

  local parent_refspec=${parent_refspec:-$(git-parent-branch $dst_refspec)}

  git-branch-copy $src_refspec $dst_refspec \
  && \
  github-push $f_option $repo_option $dst_refspec $parent_refspec
}

function github-push-url() {
  git remote -v | grep '(push)' | awk '{print $2}' | sed -e "s/^[a-z]*@\([a-z0-9\.]*\):/https:\/\/\1\//g" | sed 's/\.git$//g'
}

function github-urls() {
  local src_branch=${1:-$(git rev-parse --abbrev-ref HEAD)}
  local dst_branch=${2:-master}
  local url=$(github-push-url)

  echo "$url "
  echo "$url/tree/$src_branch "
  if [ $src_branch != $dst_branch ]; then
    echo "$url/compare/${dst_branch}...${src_branch} "
  fi
}

alias git-status-deleted='git status --short --untracked-files=all | grep "^ D " | cut -c4-'
alias git-status-existing='git status --short --untracked-files=all | grep -v "^ D " | cut -c4-'
alias git-rm-deleted='git-status-deleted | xargs git rm'

alias ga='git add'
alias gac=git-add-commit
alias gap='git add -p'
alias gbd='git branch -D'
alias gbrd='git branch -D'
alias gcam='git commit -am'
alias gce=git-commit-each
alias gci='git commit'
alias gcia='git commit --amend'
alias gca='git commit --amend'
alias gcim='git commit -m'
alias gcm='git commit -m'
alias gcl='git clean'
alias gclfd='git clean -fd'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gcof='git-checkout-force'
alias gcor='git-checkout-remote'
alias gcot='git checkout --theirs'
alias gcp='git cherry-pick'
alias gd='git diff'
alias gdc='git diff --cached'
alias gdn='git diff --name-only'
alias gf='git fetch'
## git log
alias gl='git log --oneline'
alias glh='git log --oneline | head -n 15'
alias gln='git log --name-only'
alias glp='git log -p'

alias glcp=git-log-cherry-pick

alias gmm='git-merge master'
alias gpl='git-pull'
alias gplf='git-pull-force'
alias gps='github-push-v2 --no-number'
alias gpsf='github-push-v2 --no-number -f'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbi='git rebase -i'
alias grbr='git rebase -i --root'
alias grbc='git rebase --continue'
alias grm='git rm'
alias grs='git reset'
alias grsh='git reset --hard'

alias gs='git status'
alias gss='git status -s'
alias gsd='git-status-deleted'
alias gse='git-status-existing'

for n in $(seq 50); do
  alias gd$n="git diff HEAD~$n"
  alias gdn$n="git diff --name-only HEAD~$n"
  alias gl$n="git log --oneline -n $n | tee"
  alias glcp$n="git-log-cherry-pick $n"
  alias grb$n="git rebase -i HEAD~$n"
  alias grs$n="git reset HEAD~$n"
done

alias gcmtmp='git add .; git commit -m tmp'
