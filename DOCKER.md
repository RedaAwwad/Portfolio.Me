# Docker & Dokploy Notes

This repository includes a Dockerfile to build the Astro site and serve the static output using nginx. It's suitable for deploying to container platforms such as Dokploy.

Build locally:

```bash
docker build -t reda-portfolio:latest .
```

Run locally (map port 80 in the container to 8080 on host):

```bash
docker run --rm -p 8080:80 reda-portfolio:latest
# open http://localhost:8080
```

Notes for Dokploy:

- Dokploy accepts a Docker image or builds from a repository with a `Dockerfile` at the repo root. The image should listen on port 80.
- The included Dockerfile outputs the static site into `/usr/share/nginx/html` and serves it with nginx.
- If you need environment variables or a server-side runtime, replace the nginx runner with a node-based runner (serve, express, or similar) and expose the appropriate port.
