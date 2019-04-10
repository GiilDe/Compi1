#!/bin/bash

echo "*********************************************"
echo "*                                           *"
echo "*     Theory of Compilation - hw1 tests     *"
echo "*                                           *"
echo "*********************************************"

TEST_DIR="./tests/"
LEX_FILE_NAME=$2

function cleanup {
  rm "./a.out"
  rm "./lex.yy.c"
}

function error {
  cleanup > \dev\null
  exit 1
}

function sep {
  echo "*********************************************"
}

function my_test {
  TEST_NAME="${TEST_DIR}$1"
  IN_FILE="${TEST_NAME}.css"
  OUT_FILE="${TEST_NAME}.out"
  echo "Running test $1..."

  ./a.out < "$IN_FILE" | diff - "$OUT_FILE"
  if [ ! $? -eq 0 ]
  then
    sep
    echo "Test $1 failed. Exiting"
    error
  fi
}

# Setup
echo "Setting up the lexical analyzer..."
sep

if [ -z "$LEX_FILE_NAME" ]; then
  echo "File name not provided. Assuming file=hw1.lex"
  LEX_FILE_NAME="hw1.lex"
else
  echo "Flex file=${LEX_FILE_NAME}"
fi

if [ ! -f "$LEX_FILE_NAME" ]; then
  echo "Flex file not found. please make sure your file is within the same directory as this test file, and that it's named hw1.lex (Or run as: test.sh <file_name>)"
  error
fi

echo "Flex file found! Generating lexical analyzer..."
sep

flex $LEX_FILE_NAME
if [ ! $? -eq 0 ]
then
   echo "Flex failed to compile. Aborting tests"
   error
fi

echo "Compiling lexical analyzer..."
sep

gcc -std=c99 -ll lex.yy.c
if [ ! $? -eq 0 ]
then
   echo "GCC failed to compile lexer. Aborting tests"
   error
fi

echo "Running tests"
sep

# Staff test 1
my_test "staff/t1"
my_test "staff/t2"

# Basic tests
my_test "basic/basic1"
my_test "basic/basic2"

# Specific tests
my_test "spec/comments"
# my_test "spec/strings"
my_test "spec/eof"
my_test "spec/eof2"

# Saifun tests
my_test "spec2/at"
my_test "spec2/commentNonP1"
my_test "spec2/commentNonP2"
my_test "spec2/ex"
my_test "spec2/goodCases"
my_test "spec2/im1"
my_test "spec2/moreComplicated"
my_test "spec2/nest"
my_test "spec2/num1"
my_test "spec2/percent"
my_test "spec2/rgb1"
my_test "spec2/rgb2"
my_test "spec2/rgb3"
my_test "spec2/rgb4"
my_test "spec2/rgb5"
my_test "spec2/string1"
my_test "spec2/string2"
my_test "spec2/string3"
my_test "spec2/string4"
my_test "spec2/string5"
my_test "spec2/string6"
my_test "spec2/string7"
my_test "spec2/string8"
my_test "spec2/string9"
my_test "spec2/string10"

# Cleanup
cleanup
sep
echo "All tests passed! well done :)"
