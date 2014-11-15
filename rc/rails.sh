### Rubocop
alias rubo=rubocop
alias ruboa='rubocop -a'

### Rake
function rake-db-rollback() {
  step=${1:-1}
  rake db:rollback STEP=$step
}

alias dbrollback=rake-db-rollback
alias dbrb=rake-db-rollback

function rake-db-test-prepare() {
  rake db:test:prepare
}
alias dbtestprepare=rake-db-test-prepare
alias dbtp=rake-db-test-prepare

function rake-db-migrate() {
  version=$1
  if [ "$version" = "" ]; then
    rake db:migrate
  else
    rake db:migrate VERSION=$version
  fi
}

alias dbmigrate=rake-db-migrate
alias dbmg=rake-db-migrate
alias dbmt="rake-db-migrate;rake-db-test-prepare"

function database-yml() {
  env=development

  if [ $# -gt 1 ]; then
    env=$1
    shift
  fi

  key=$1
  default=$2

  value=$(ruby -ryaml -e 'puts YAML.load_file("config/database.yml")[ARGV[0]][ARGV[1]]' $env $key)

  echo ${value:-$default}
}

function database-client() {
  env=${1:-development}
  adapter=$(database-yml $env adapter mysql)
  host=$(database-yml $env host localhost)
  port=$(database-yml $env port)
  database=$(database-yml $env database)
  username=$(database-yml $env username)
  password=$(database-yml $env password)
  password_option=""
  case $adapter in
    mysql | mysql2 )
      port=${port:-3306}
      if [ "$password" != '' ]; then
        password_option='-p'
      fi
      echo "mysql -h $host -P $port -u $username $database $password_option"
      mysql -h $host -P $port -u $username $database $password_option
      ;;
    postgresql )
      port=${port:-5432}
      if [ "$password" != '' ]; then
        password_option='-W'
      fi
      echo "psql -h $host -p $port -U $username $database $password_option"
      psql -h $host -p $port -U $username $database $password_option
      ;;
  esac
}

alias dbcli=database-client

function delete-migration() {
  version=$1
  #version=$(ls db/migrate | grep $name | cut -d_ -f1)
  echo "DELETE FROM schema_migrations WHERE version = '$version';" | database-client
}

function insert-migration() {
  version=$1
  #version=$(ls db/migrate | grep $name | cut -d_ -f1)
  echo "INSERT INTO schema_migrations(version) VALUES (('$version'));" | database-client
}

function show-migrations() {
  echo "SELECT version FROM schema_migrations;" | database-client
}

function drop-table() {
  table=$1
  echo "DROP TABLE $table;" | database-client
}

function rescue-work() {
  QUEUE="*" rake environment resque:work
}

#### RSpec
function xargs-rspec() {
  tee | grep '_spec\.rb$' | xargs -t rspec
}

function git-status-rspec() {
  git-status-existing | xargs-rspec
}
alias gspec=git-status-rspec

function git-diff-rspec() {
  git diff --name-only $1 | xargs-rspec
}

for n in $(seq 50); do
  alias gspec$n="git-diff-rspec HEAD~$n"
done

### Rubocop
function xargs-rubocop() {
  tee | grep '\.rb$' | grep -v schema.rb | grep -v routes.rb | xargs -t rubocop $*
}

function git-status-rubocop() {
  git status --short --untracked-files=all | grep -v "^ D " | cut -c4- | xargs-rubocop $*
}

function git-diff-rubocop() {
  while true; do
    if [ "$1" = -a ]; then
      local a_option=$1; shift
    else break; fi
  done

  git diff --name-only $1 | xargs-rubocop $a_option
}

alias rubo=rubocop
alias ruboa='rubocop -a'
alias grubo=git-status-rubocop
alias gruboa='git-status-rubocop -a'

for n in $(seq 50); do
  alias grubo$n="git-diff-rubocop HEAD~$n"
  alias gruboa$n="git-diff-rubocop -a HEAD~$n"
done

### Rails
alias rs='rails server'
alias rc='rails console'


