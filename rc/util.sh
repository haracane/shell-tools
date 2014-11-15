alias ll="ls -l"

function alias-if-not-found() {
  name=$1
  cmd=$2
  if ! which $name > /dev/null; then
  	alias $name="$cmd"
  fi
}

function alias-if-exists() {
  name=$1
  cmd=$2
  if which $cmd > /dev/null; then
  	alias $name="$cmd"
  fi
}

alias-if-exists sed gsed
alias-if-not-found tac "tail -r"

function find-file() {
  name=$1
  find . -name "*$name*"
}

function rename-file-commands() {
  from=$1
  to=$2

  for file in $(find-file $from); do
    dst_file=$(echo $file | sed s/$from/$to/g)
    dst_dir=$(dirname $dst_file)
    if [ ! -d $dst_dir ]; then echo mkdir $dst_dir; fi
    echo "mv $file $(echo $file | sed s/$from/$to/g)"
  done
}

function sed-rename() {
  from=$1
  to=$2
  dirpath=${3:-.}

  for file in $(grep -lR $from $dirpath); do
    echo "sed s/$from/$to/g -i $file"
    sed "s/$from/$to/g" -i $file
  done
}
