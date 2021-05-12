#!/bin/bash -e

mkdir beer-api
git clone https://github.com/samuskitchen/golang-bootstrap beer-api
cd ./beer-api/
rm -rf .git
git init