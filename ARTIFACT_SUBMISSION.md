# EDAM Artifact - Submission Package

This document describes the Docker-based artifact submission for the EDAM project.

## Package Contents

The artifact package includes:

1. **Dockerfile** - Complete Docker image definition with all dependencies
2. **docker-compose.yml** - Docker Compose configuration for easy deployment
3. **build-docker.sh** - Script to build and export the Docker image
4. **load-docker.sh** - Script to load a pre-built Docker image
5. **DOCKER_README.md** - Comprehensive documentation for artifact evaluation
6. **.dockerignore** - Files excluded from Docker build context

## Quick Start for Evaluators

### Step 1: Load the Docker Image

If you received `edam-artifact.tar.gz`:

```bash
./load-docker.sh
```

Or manually:
```bash
gunzip -c edam-artifact.tar.gz | docker load
```

### Step 2: Run the Container

**Option A: Using the run script (recommended):**
```bash
./run-docker.sh
```

**Option B: Using docker-compose:**
```bash
docker-compose up
```

**Option C: Using docker directly:**
```bash
docker run -d -p 3000:3000 -p 5000:5000 --name edam-artifact edam-artifact
```

### Step 3: Access Services

- **Frontend (GUI)**: http://localhost:3000
- **Backend (API)**: http://localhost:5000
- **CLI**: Access via `docker exec -it edam-artifact bash`

## Evaluation Scenarios

### Scenario 1: GUI-Based Model Generation

1. Open http://localhost:3000
2. Create or load an EDAM model
3. Generate code via the interface
4. Download generated ZIP file

**Expected**: ZIP file with Solidity contracts and tests

### Scenario 2: CLI-Based Generation

```bash
docker exec -it edam-artifact bash
source venv/bin/activate
export OPAMROOT=/root/.opam
eval $(opam env --root=/root/.opam)
python3 CLI/cli.py assettransfer --mode 2
```

**Expected**: Generated code in `/app/Generated-code/`

### Scenario 3: API-Based Generation

```bash
curl -X POST http://localhost:5000/api/convert-bulk \
  -H "Content-Type: application/json" \
  -d '{"models": [...], "server_settings": {...}}'
```

**Expected**: JSON response with download URL

## System Requirements

- Docker 20.10+ or Docker Desktop
- 4GB+ RAM recommended
- 10GB+ disk space for image

## Ports

- **3000**: Frontend GUI (React/Vite)
- **5000**: Backend API (Django)

## Troubleshooting

See `DOCKER_README.md` for detailed troubleshooting guide.

## Contact

For questions or issues, refer to the main project README or contact the authors.
