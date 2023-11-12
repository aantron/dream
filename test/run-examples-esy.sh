#! /bin/bash

EXAMPLES=$(ls example)

for EXAMPLE in $EXAMPLES
do
  echo $EXAMPLE
  (cd example/$EXAMPLE && esy && (esy start & (sleep 10 && pkill -P $$)))
done
