function git-status-subl() {
  revision=$1
  files=$(git-status-existing $revision | tr '\n' ' ')
  if [ "$files" = '' ]; then return 0; fi
  echo "subl $files"
  echo $files | xargs subl
}
alias gsubl=git-status-subl
