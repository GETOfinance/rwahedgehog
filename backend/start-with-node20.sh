#!/bin/bash

# Ensure we're using Node.js v20
export PATH="/home/evm/.nvm/versions/node/v20.19.3/bin:$PATH"

echo "Using Node.js version: $(node --version)"
echo "Starting Hedgehog Backend services..."

# Start all services with the correct Node.js version
/home/evm/.nvm/versions/node/v20.19.3/bin/node ./dist/providers/price-provider.js &
/home/evm/.nvm/versions/node/v20.19.3/bin/node ./dist/providers/timeseries-provider.js &
/home/evm/.nvm/versions/node/v20.19.3/bin/node ./dist/events/issuer.firehose.js &
/home/evm/.nvm/versions/node/v20.19.3/bin/node ./dist/events/issuer.indexer.js &
/home/evm/.nvm/versions/node/v20.19.3/bin/node ./dist/events/lender.firehose.js &
/home/evm/.nvm/versions/node/v20.19.3/bin/node ./dist/events/lender.indexer.js &

echo "All Hedgehog Backend services started!"
echo "Press Ctrl+C to stop all services"

# Wait for all background processes
wait
