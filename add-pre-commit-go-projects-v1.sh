#!/bin/bash -e

#***********************************************************************#
#                                                                       #
#                   add-pre-commit-to-all-projects.sh                   #
#   This script adds a pre-commit hook to the project from where it's   #
#   running. This script must be in the root project directory for it   #
#   to be able to access to the .git directory of the project.          #
#                                                                       #
#***********************************************************************#


# Go to the git template hooks directory
GIT_HOOKS_PATH="$(git --exec-path)"
if [ ! -d $GIT_HOOKS_PATH ]
  then printf "\nCan't find the hooks templates directory!\n\n"
  exit 1
fi

# Create our own new template directory
USER_TEMPLATES_PATH="$(eval echo ~$user)/.git-templates"
USER_HOOKS_PATH="${USER_TEMPLATES_PATH}/hooks"

# Copy commons template to our own new template directory
mkdir -p $USER_HOOKS_PATH
cp -R $GIT_HOOKS_PATH/. $USER_HOOKS_PATH
git config --global init.templatedir $USER_TEMPLATES_PATH


cd $USER_HOOKS_PATH

# Create a custom pre-commit and make it executable (If it exists, then an error is thrown)
if [ -e pre-commit ]
  then printf "\npre-commit already exists in $USER_HOOKS_PATH!\n\n"
  exit 1
fi

printf "\nCreating executable pre-commit file\n"
touch pre-commit
chmod +x pre-commit

# Set the pre-commit strategy (Supporting Maven and Gradle)
echo "#!/bin/sh
GOLINT=$GOPATH/bin/golint
GOIMPORTS=$GOPATH/bin/goimports

# Check for golint
if [ ! -x \$GOLINT ]; then
  printf \"\t\033[41mPlease install golint\033[0m (go get -u golang.org/x/lint/golint)\"
  exit 1
fi

# Check for goimports
if [ ! -x \$GOIMPORTS ]; then
  printf \"\t\033[41mPlease install goimports\033[0m (go get golang.org/x/tools/cmd/goimports)\"
  exit 1
fi

# Run all test
  printf \"\033[0;30m\033[42mRUNNING TEST\033[0m\n\n\"
  go test -v ./test/...
  returncode=$?
  if [ \$returncode -ne 0 ]; then
    printf \"\033[0;30m\033[41mTEST FAILED\033[0m\n\n\"
    exit 1
  fi

PASS=true

for FILE in \$(git diff --cached --name-only --diff-filter=ACMR | grep '\.go$')
do
  # Run goimports on the staged file
  \$GOIMPORTS -w \$FILE


  # Run golint on the staged file and check the exit status
  \$GOLINT \"-set_exit_status\" \$FILE
  if [ \$? != 0 ]; then
    printf \"\t\033[31mgolint \$FILE\033[0m \033[0;30m\033[41mFAILURE!\033[0m\n\n\"
    PASS=false
  else
    printf \"\t\033[32mgolint \$FILE\033[0m \033[0;30m\033[42mpass\033[0m\n\n\"
  fi

  # Run govet on the staged file and check the exit status
  go vet \$FILE
  if [ \$? != 0 ]; then
    printf \"\t\033[33mgo vet $FILE\033[0m \033[0;30m\033[43mWARNING!\033[0m\n\n\"
    #PASS=false
  else
    printf \"\t\033[32mgo vet \$FILE\033[0m \033[0;30m\033[42mpass\033[0m\n\n\"
  fi
done


if ! \$PASS; then
  printf \"\033[0;30m\033[41mCOMMIT FAILED\033[0m\n\n\"
  exit 1
else
  printf \"\033[0;30m\033[42mCOMMIT SUCCEEDED\033[0m\n\n\"
fi

exit 0" >> pre-commit

printf "\npre-commit file created! Now for this project a compilation and tests execution will be running before a new commit.\n\n"