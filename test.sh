#!/bin/bash

echo "*********************************************"
echo "*                                           *"
echo "*     Theory of Compilation - hw1 tests     *"
echo "*                                           *"
echo "*********************************************"

TEST_DIR="./tests/"
LEX_FILE_NAME=$2

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
    exit 1
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
  exit 1
fi

echo "Flex file found! Generating lexical analyzer..."
sep

flex $LEX_FILE_NAME
if [ ! $? -eq 0 ]
then
   echo "Flex failed to compile. Aborting tests"
   exit 1
fi

echo "Compiling lexical analyzer..."
sep

gcc -std=c99 -ll lex.yy.c
if [ ! $? -eq 0 ]
then
   echo "GCC failed to compile lexer. Aborting tests"
   exit 1
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
my_test "spec/strings"

# Cleanup
sep
echo "All tests passed! well done :)"
