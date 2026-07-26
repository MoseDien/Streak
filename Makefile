.PHONY: gen build test open clean

gen:
	mise exec -- tuist generate

build:
	mise exec -- tuist build

test:
	mise exec -- tuist test --no-selective-testing

open: gen
	open StreakDaily.xcworkspace

clean:
	rm -rf Derived StreakDaily.xcodeproj StreckDaily.xcworkspace
