#!/bin/sh
## Batch delete an entire DTR events table

# Usage/help text
usage_text () {
    echo -e "Usage: docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock squizzi/dtr-batch-delete-events -l <limit> -c <count>"
    echo -e "-l       Set the desired batch deletion limit (default 1000)"
    echo -e "-c       Override the automated event calculation with a desired number of events"
    exit 1
}

# Set desired limit via $LIMIT, this will set how many deletes will occur
# at one time
# If desired, event count can also be overwritten via $COUNT
while getopts ":l:c:h" opt; do
    case $opt in
        h)
          usage_text
          ;;
        l)
          LIMIT=${OPTARG}
          ;;
        c)
          COUNT=${OPTARG}
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

# Opt validation if opts are given
if [[ ! -z $COUNT ]] && [[ ! $COUNT =~ ^-?[0-9]+$ ]]; then
   echo -e "Error: Option -c must be numeric"
   exit 1
fi

if [[ ! -z $LIMIT ]] && [[ ! $LIMIT =~ ^-?[0-9]+$ ]]; then
    echo -e "Error: Option -l must be numeric"
    exit 1
fi

# ---

# Make sure there's a LIMIT set, if not, default to 1000
if [ -z $LIMIT ]; then
    echo -e "No batch delete limit specified, using default of 1000"
    LIMIT=1000
fi

# Check for docker socket
if [ ! -e "/var/run/docker.sock" ]; then
    echo -e "Docker not detected, did you forget to mount docker.sock?"
    usage_text
    exit 1
fi

# Check to see if dtr-rethinkdb is running before continuing
RETHINKDB=`docker ps -q --filter name=dtr-rethinkdb`
if [ -z "$RETHINKDB" ]; then
    echo -e "Error: dtr-rethinkdb does not appear to be running, exiting"
    exit 1
fi

# Get the current REPLICA_ID
REPLICA_ID=$(docker inspect $(docker ps -q --filter name=dtr-rethinkdb) --format {{.Name}} | cut -d '-' -f3)
if [ -z "$REPLICA_ID" ]; then
    echo -e "Error: DTR replica id could not be determined"
    exit 1
fi

# Determine the count of the events table if -c is not given
if [ -z $COUNT]; then
    echo -e "Calculating length of events table..."
    COUNT=$(echo "r.db('dtr2').table('events').count()" | docker run --entrypoint=rethinkcli -i --rm --net dtr-ol -e DTR_REPLICA_ID=$REPLICA_ID -v dtr-ca-$REPLICA_ID:/ca docker/dtr-rethink:2.5.0 non-interactive)
fi
if [[ ! $COUNT =~ ^-?[0-9]+$ ]]; then
    # If no number is found in the events table
    echo -e "Error: Unable to calculate length of events table: $COUNT"
    exit 1
fi
if [ $COUNT -eq 0 ]; then
    echo -e "Nothing to delete, exiting"
    exit 1
fi

# Calculate the number of iterations to run, expr won't create a float
# which is perfect for our calculation, we'll add 1 onto $MAX to ensure
# we always run once to catch less then $LIMIT values
MAX=$(expr $COUNT / $LIMIT + 1)
if [ -z "$MAX" ]; then
    echo -e "Error: Unable to calculate number of iterations to run, exiting"
    exit 1
fi

# Prompt for deletion
echo -e "Preparing to delete $COUNT events from the DTR events table in batches of $LIMIT"
while true;
do
    read -r -p "Continue? Y/N: " response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        break
    else
        exit 0
    fi
done

# Start deleting in batches
for i in `seq $MAX`;
do
    echo "r.db('dtr2').table('events').limit($LIMIT).delete()" | docker run --entrypoint=rethinkcli -i --rm --net dtr-ol -e DTR_REPLICA_ID=$REPLICA_ID -v dtr-ca-$REPLICA_ID:/ca docker/dtr-rethink:2.5.0 non-interactive
    echo -e "\n"$(date) "Completed batch: $i of $MAX"
done

echo -e "Done: events table deleted"
exit 0
