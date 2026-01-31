.PHONY: setup compile test lint dialyzer check docs docker-build docker-test

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

docker-build:
	docker build -t alpa_ex .

docker-test:
	docker build -t alpa_ex . && docker run --rm alpa_ex
