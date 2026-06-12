#!/bin/bash

# 1. Validate Only (Sandbox/UAT)
# Run tests and check for component conflicts
sf project deploy start --manifest manifest/package.xml --test-level RunLocalTests --dry-run --target-org sandbox_alias

# 2. Quick Deploy (Using Job ID from Validation)
# sf project deploy quick --job-id <JOB_ID> --target-org sandbox_alias

# 3. Full Production Deployment (SFDX Format)
sf project deploy start --manifest manifest/package.xml --target-org prod_alias --test-level RunLocalTests --wait 30

# 4. MDAPI Legacy Deployment (If converting from SFDX to MDAPI)
# sf project convert source --output-dir mdapi_out
# sf project deploy start --metadata-dir mdapi_out --target-org prod_alias --wait 30
