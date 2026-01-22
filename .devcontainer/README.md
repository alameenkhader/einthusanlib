# Dev Container Setup

## Prerequisites

- Docker Desktop installed and running
- Dev Container CLI (for command line usage) or VS Code with Dev Containers extension

## Using Dev Container CLI

If you prefer using the command line:

1. **Install the Dev Container CLI**
  ```bash
  brew install devcontainer
  ```

2. **Build and open the container**
  ```bash
  devcontainer up --workspace-folder .
  ```

3. **Execute commands in the container**
  ```bash
  devcontainer exec --workspace-folder . bash
  ```

4. **Rebuild the container**
  ```bash
  devcontainer up --workspace-folder . --remove-existing-container
  ```

## Running rails app
```
  rails server -b 0.0.0.0
```