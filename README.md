# C++ project bootstrap
Makefile for C++ project with googletest support and code coverage.

## Main Makefile targets

* Build striped binary and unit tests
```
make
```
or
```
make RELEASE=1
```
* Run binary
```
make run
```
* Run binary in debugger
```
make run-debug
```
* Run tests
```
make run-test
```
* Code coverage
```
make coverage && sensible-browser coverage/index.html
```
