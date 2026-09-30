.PHONY: dev backend frontend data

dev:
	npx concurrently "make backend" "make frontend"

backend:
	cd backend && venv/Scripts/python -m uvicorn main:app --reload --port 8000

frontend:
	cd frontend && npm run dev

data:
	cd backend && venv/Scripts/python data/generate.py

reset:
	cd backend && venv/Scripts/python data/generate.py

test:
	cd backend && venv/Scripts/pytest tests/ -m "not slow"

test-all:
	cd backend && venv/Scripts/pytest tests/
