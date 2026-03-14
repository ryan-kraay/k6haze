#!/usr/bin/env bash
set -euo pipefail

#!/usr/bin/env bash                                                                  
set -euo pipefail                                                                                                     
                                                                                                                                               
yq -o=json -I=0 '{"id": .id} * .output'
