#!/bin/sh
##

# Usage/help text
usage_text () {
    echo -e "Usage: docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock squizzi/dtr-fix-authornamespace -l <limit> -c <count>"
    echo -e "-l       Set the desired batch limit (default 1000)"
    echo -e "-c       Override the automated event calculation with a desired number of events"
    exit 1
}

# Set desired limit via $LIMIT, this will set how many modifications will occur
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

# ---

# Make sure there's a LIMIT set, if not, default to 1000
if [ -z $LIMIT ]; then
    echo -e "No batch limit specified, using default of 1000"
    LIMIT=1000
fi

# Check for docker socket
if [ ! -e "/var/run/docker.sock" ]; then
    echo -e "Error: Docker not detected, did you forget to mount docker.sock?"
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
if [ -z $COUNT ]; then
    echo -e "Calculating number of tags needing to be modified..."
    COUNT=$(echo "r.db('dtr2').table('tags').filter({'authorNamespace' : ''}).count()" | docker run -i --rm --net dtr-ol -e DTR_REPLICA_ID=$REPLICA_ID -v dtr-ca-$REPLICA_ID:/ca dockerhubenterprise/rethinkcli:v2.2.0-ni non-interactive)
fi
if [ $COUNT -eq 0 ]; then
    echo -e "Nothing to modify, exiting"
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

echo -e "Modifying $COUNT tags from the DTR tags table in batches of $LIMIT"
for i in `seq $MAX`;
do
    echo "r.db('dtr2').table('tags').filter({'authorNamespace' : ''}).limit($LIMIT).update({'authorNamespace' : '00000000-0000-0000-0000-000000000000'})" | docker run -i --rm --net dtr-ol -e DTR_REPLICA_ID=$REPLICA_ID -v dtr-ca-$REPLICA_ID:/ca dockerhubenterprise/rethinkcli:v2.2.0-ni non-interactive
    echo -e "\n"$(date) "Completed batch: $i of $MAX"
done

echo -e "Done: tags table updated"
exit 0
