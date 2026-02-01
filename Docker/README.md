# EDAM Studio Docker Setup

This directory contains Docker configuration files to run EDAM Studio in a containerized environment.

## Updating Docker to Latest Version

If you need to update Docker to the latest version with Docker Compose v2 support:

```bash
cd Docker
sudo ./update-docker.sh
```

This will:
- Remove old docker-compose v1
- Install Docker from Docker's official repository
- Install Docker Compose plugin v2
- Install Docker Buildx for advanced build features

After updating, use `docker compose` (v2) instead of `docker-compose` (v1).

**If Docker service fails to start after update:**

```bash
cd Docker
sudo ./fix-docker-service.sh
```

This will reload systemd, start Docker, and enable it to start on boot.

## Quick Start

### Option 1: Using Docker Directly (Recommended - Avoids Compatibility Issues)

If you're experiencing issues with `docker-compose`, use this script:

```bash
cd Docker
./run-docker.sh
```

This script:
- Builds the Docker image
- Starts both the GUI (port 3000) and API (port 5000)
- Creates a volume for generated code
- Makes the CLI accessible

### Option 2: Using Docker Compose

**Note**: Use `docker compose` (v2, built into Docker) instead of `docker-compose` (v1) to avoid compatibility issues.

```bash
cd Docker
docker compose up --build
```

Or if you only have docker-compose v1 installed and it works:
```bash
cd Docker
docker-compose up --build
```

### Option 3: Manual Docker Commands

```bash
# Build the image
docker build -f Docker/Dockerfile -t edam-studio ..

# Run the container
docker run -d \
  -p 3000:3000 \
  -p 5000:5000 \
  --name edam-studio \
  edam-studio
```

### Using Docker directly

```bash
# Build the image
docker build -f Docker/Dockerfile -t edam-studio ..

# Run the container
docker run -d \
  -p 3000:3000 \
  -p 5000:5000 \
  --name edam-studio \
  edam-studio
```

## Accessing Services

- **GUI**: http://localhost:3000
- **API**: http://localhost:5000

## Using the CLI

The CLI is accessible in two ways:

### Method 1: Using the wrapper command

```bash
docker exec -it edam-studio edam-cli <model1> <model2> ... --mode <1|2|3|4> [options]
```

Example:
```bash
docker exec -it edam-studio edam-cli assettransfer --mode 2
```

### Method 2: Direct Python script

```bash
docker exec -it edam-studio python3 /app/Studio/CLI/cli.py <model1> <model2> ... --mode <1|2|3|4> [options]
```

## CLI Options

The CLI supports all the same options as the local installation:

```bash
docker exec -it edam-studio edam-cli --help
```

Common options:
- `--mode`: Generation mode (1, 2, 3, or 4) - **required**
- `--number_symbolic_traces`: Number of symbolic traces (default: 200)
- `--number_transition_per_trace`: Transitions per trace (default: 10)
- `--probability_new_participant`: Probability for new participant (default: 0.35)
- `--z3_check_enabled`: Enable Z3 checking

## Examples

### Generate code from a model
```bash
docker exec -it edam-studio edam-cli assettransfer --mode 2
```

### Generate code from a .edam file
```bash
# First, copy your .edam file into the container
docker cp my_model.edam edam-studio:/app/Studio/

# Then run the CLI
docker exec -it edam-studio edam-cli my_model.edam --mode 2
```

### Custom trace generation
```bash
docker exec -it edam-studio edam-cli c20 amm --mode 3 \
  --number_symbolic_traces 1000 \
  --number_transition_per_trace 40
```

## Volumes

The docker-compose.yml includes a volume for `Generated-code` to persist generated files. If you want to access generated files from the host:

```yaml
volumes:
  - ./Generated-code:/app/Studio/Generated-code
```

## Stopping Services

```bash
# Using docker compose (v2)
docker compose down

# Or using docker-compose (v1)
docker-compose down

# Using docker directly
docker stop edam-studio
docker rm edam-studio
```

## Troubleshooting

### Check logs
```bash
docker logs edam-studio
```

### Access container shell
```bash
docker exec -it edam-studio /bin/bash
```

### Rebuild after changes
```bash
# Using docker compose (v2)
docker compose up --build --force-recreate

# Or using docker-compose (v1)
docker-compose up --build --force-recreate
```

### Fix docker-compose v1 compatibility issues

If you encounter `URLSchemeUnknown: Not supported URL scheme http+docker` error:

**Option 1 (Easiest)**: Use the Docker-only script:
```bash
cd Docker
./run-docker.sh
```

**Option 2**: Use Docker Compose v2 (if available):
```bash
docker compose up --build
```

**Option 3**: Fix the environment variable and try docker-compose v1:
```bash
unset DOCKER_HOST
docker-compose up --build
```

**Option 4**: Use Docker directly:
```bash
docker build -f Docker/Dockerfile -t edam-studio ..
docker run -d -p 3000:3000 -p 5000:5000 --name edam-studio edam-studio
```

**Note**: The `http+docker` scheme error is caused by incompatibility between docker-compose v1.29.2 and urllib3 2.x. The Docker-only script (`run-docker.sh`) completely bypasses docker-compose and avoids this issue.

## Notes

- The container runs both GUI and API services simultaneously
- Generated code is stored in `/app/Studio/Generated-code` inside the container
- The CLI requires the virtual environment and opam environment, which are automatically activated in the wrapper script
