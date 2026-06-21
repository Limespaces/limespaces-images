# syntax=docker/dockerfile:1
FROM node:22-alpine

WORKDIR /app

RUN npm install -g pnpm

# Copy workspace configurations
COPY pnpm-lock.yaml pnpm-workspace.yaml ./
# Copy package.json of all workspace members to cache installation layer
COPY repos/shared/package.json ./repos/shared/
COPY repos/dashboard/package.json ./repos/dashboard/
COPY repos/orchestrator/package.json ./repos/orchestrator/

# Install dependencies for the workspace
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile --store-dir /pnpm/store

COPY . .

# Set working directory to the orchestrator package
WORKDIR /app/repos/orchestrator

# Build the application
RUN pnpm run build

# Copy entrypoint script
COPY repos/images/platform/orchestrator/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV NODE_ENV=production

ENTRYPOINT ["/entrypoint.sh"]
