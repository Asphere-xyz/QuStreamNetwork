# QuStream Indexer

A Subsquid indexer for tracking QuStream contract requests on Substrate-based networks. Monitors request registration and status updates from the QuStream Request Manager contract.

## What It Tracks

- **QuStream Requests**: Request registration events, status updates (Pending/Success/Fail), sender addresses, user IDs, and qBlock data
- **QuStream Statistics**: Total requests, successful requests, failed requests, and pending requests

## Setup

### Requirements

- Node.js 24+
- Docker & Docker Compose
- Subsquid CLI: `npm install -g @subsquid/cli`

### Installation

```bash
npm install      # Install dependencies
npm run start    # Build, setup, and start indexer (default: Qustream)
npm test         # Test contract events and query indexer data
```

GraphQL API: <http://localhost:4350/graphiql>

#### NOTE: you have to have a working zombienet/chain before starting the indexer

## Commands

```bash
sqd start        # Complete setup and start indexer
sqd reset        # Reset DB and restart from block 0
sqd serve        # Start processor + API (if already setup)
sqd open         # Open GraphiQL
sqd compare      # Compare DB with chain state
```

## Querying Indexer Data

The indexer exposes a GraphQL API at `http://localhost:4350/graphql`. You can query it using GraphiQL (browser interface) or programmatically.

### Using GraphiQL

Open the GraphiQL interface:

```bash
sqd open
# or visit http://localhost:4350/graphiql
```

### Example Queries

See [`verifyIndexerData.graphql`](./verifyIndexerData.graphql)

### Programmatic Access

#### Using cURL

```bash
curl -X POST http://localhost:4350/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { quStreamStats(first: 1) { edges { node { totalRequests } } } }"
  }'
```

## Configuration

Edit `.env` file (auto-created by `sqd start`):

```bash
CHAIN=qustream
CHAIN_RPC_ENDPOINT=ws://127.0.0.1:8800
TOKEN_SYMBOL=QSTG
TOKEN_DECIMALS=18
SS58_PREFIX=5041
QUSTREAM_CONTRACT_ADDRESS=

# Performance tuning (optional, defaults shown)
# RPC_RATE_LIMIT=1000
# MAX_BATCH_CALL_SIZE=10000
```

For custom chains, manually edit `.env` with your config.

## License

MIT
