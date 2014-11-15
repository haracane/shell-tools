shell_dir=$(cd $(dirname $0); pwd)

for file in util.sh git.sh rails.sh subl.sh; do
  filepath=$shell_dir/$file
  echo "source $filepath"
  source $filepath
done
