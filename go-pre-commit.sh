#!/bin/sh
GOLINT=$GOPATH/bin/golint
GOIMPORTS=$GOPATH/bin/goimports

# Check for golint
if [ ! -x $GOLINT ]; then
  printf "\t\033[41mPlease install golint\033[0m (go get -u golang.org/x/lint/golint)"
  exit 1
fi

# Check for goimports
if [ ! -x $GOIMPORTS ]; then
  printf "\t\033[41mPlease install goimports\033[0m (go get golang.org/x/tools/cmd/goimports)"
  exit 1
fi

# Run all test
  printf "\033[0;30m\033[42mRUNNING TEST\033[0m\n\n"
  go test -v ./test/...
  returncode=0
  if [ $returncode -ne 0 ]; then
    printf "\033[0;30m\033[41mTEST FAILED\033[0m\n\n"
    exit 1
  fi

PASS=true

for FILE in $(git diff --cached --name-only --diff-filter=ACMR | grep '\.go$')
do
  # Run goimports on the staged file
  $GOIMPORTS -w $FILE


  # Run golint on the staged file and check the exit status
  $GOLINT "-set_exit_status" $FILE
  if [ $? != 0 ]; then
    printf "\t\033[31mgolint $FILE\033[0m \033[0;30m\033[41mFAILURE!\033[0m\n\n"
    PASS=false
  else
    printf "\t\033[32mgolint $FILE\033[0m \033[0;30m\033[42mpass\033[0m\n\n"
  fi

  # Run govet on the staged file and check the exit status
  go vet $FILE
  if [ $? != 0 ]; then
    printf "\t\033[33mgo vet \033[0m \033[0;30m\033[43mWARNING!\033[0m\n\n"
    #PASS=false
  else
    printf "\t\033[32mgo vet $FILE\033[0m \033[0;30m\033[42mpass\033[0m\n\n"
  fi
done


if ! $PASS; then
  printf "\033[0;30m\033[41mCOMMIT FAILED\033[0m\n\n"
  exit 1
else
  printf "\033[0;30m\033[42mCOMMIT SUCCEEDED\033[0m\n\n"
fi

exit 0
