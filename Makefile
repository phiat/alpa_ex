.PHONY: setup compile test lint dialyzer check docs

setup:
	mix deps.get

compile:
	mix compile --warnings-as-errors

test:
	mix test

lint:
	mix format --check-formatted
	mix credo --strict

dialyzer:
	mix dialyzer

check: compile lint test dialyzer

docs:
	mix docs
