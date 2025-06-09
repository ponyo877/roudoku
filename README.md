# Roudoku - Aozora StoryWalk

> **Single environment deployment** - cost-optimized setup in project `gke-test-287910`

A mobile reading app that finds and narrates the perfect Aozora Bunko book for users based on their context.

## Quick Start

```bash
# Deploy infrastructure (cost-optimized)
./apply-terraform.sh

# Set up database
./scripts/setup-database.sh

# Configure Firebase (see docs/FIREBASE_SETUP.md)
```

## Project Status

- ✅ **Phase 1**: Infrastructure & Database Setup (In Progress)
- ⏳ **Phase 2-9**: Feature development

## Cost-Optimized Architecture

- **Single Environment**: No dev/prod separation to minimize costs
- **Minimal Resources**: db-f1-micro, minimal Cloud Run instances
- **Estimated Cost**: ~$15-20/month