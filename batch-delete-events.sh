#!/bin/sh
## Batch delete an entire DTR events table

# Usage/help text
usage_text () {
    echo -e "Usage: docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock -l <batch delete limit>"
    exit 1
}

# Set desired limit via $LIMIT, this will set how many deletes will occur
# at one time
while getopts ":l:h" opt; do
    case $opt in
        h)
          usage_text
          ;;
        l)
          LIMIT=${OPTARG}
          ;;
        \?)
          usage_text
          ;;
        :)
          echo -e "Option -$OPTARG requires an argument." >&2
          exit 1;
          ;;
  esac
done


# ---

# Check for docker socket
if [ ! -e "/var/run/docker.sock" ]; then
    echo -e "Docker not detected, did you forget to mount docker.sock?"
    usage_text
    exit 1
fi

# Check to see if dtr-rethinkdb is running before continuing
RETHINKDB=`docker ps -q --filter name=dtr-rethinkdb`
if [ -z "$RETHINKDB" ]; then
    echo "Error: dtr-rethinkdb does not appear to be running, exiting"
    exit 1
fi

# Get the current REPLICA_ID
REPLICA_ID=$(docker inspect $(docker ps -q --filter name=dtr-rethinkdb) --format {{.Name}} | cut -d '-' -f3)
if [ -z "$REPLICA_ID" ]; then
    echo "Error: DTR replica id could not be determined"
    exit 1
fi

# Determine the count of the events table
echo "Calculating length of events table..."
COUNT=$(echo "r.db('dtr2').table('events').count()" | docker run --entrypoint=rethinkcli -i --rm --net dtr-ol -e DTR_REPLICA_ID=$REPLICA_ID -v dtr-ca-$REPLICA_ID:/ca docker/dtr-rethink:2.5.0 non-interactive)
if [ -z "$COUNT" ]; then
    echo "Error: Unable to calculate length of events table, exiting"
    exit 1
elif [ $COUNT -eq 0 ]; then
    echo "Nothing to delete, exiting"
    exit 1
fi

# Calculate the number of iterations to run, expr won't create a float
# which is perfect for our calculation, we'll add 1 onto $MAX to ensure
# we always run once to catch less then $LIMIT values
MAX=$(expr $COUNT / $LIMIT + 1)
if [ -z "$MAX" ]; then
    echo "Error: Unable to calculate number of iterations to run, exiting"
    exit 1
fi

# Start deleting in batches
echo -e "Deleting $COUNT events from the DTR events table in batches of $LIMIT, this may take awhile..."
for i in `seq $MAX`;
do
    echo "r.db('dtr2').table('events').limit($LIMIT).delete()" | docker run --entrypoint=rethinkcli -i --rm --net dtr-ol -e DTR_REPLICA_ID=$REPLICA_ID -v dtr-ca-$REPLICA_ID:/ca docker/dtr-rethink:2.5.0 non-interactive
    echo -e "\n"$(date) "Completed batch: $i of $MAX"
done

echo "Done: events table deleted"
