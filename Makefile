.PHONY: install lint test smoke ci
install:
	pip install -r requirements.txt
lint:
	flake8 --max-line-length 100 app tests
test:
	python3 -m unittest discover -s tests -v
smoke:
	./scripts/smoke_test.sh
ci: lint test smoke
