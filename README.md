# Batch Delete Events Table in DTR
Tool for deleting the events table in batches to prevent performance
bottlenecks.

## Usage
1. Log in to the DTR host, or set docker client directly to DTR docker daemon. [Docker CLI Options](https://docs.docker.com/engine/reference/commandline/cli/)
2. Run the following command.

For example:

```
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock \
    squizzi/dtr-batch-event-delete:latest -l 50 -c 1000
```

Would perform a deletion of 1000 events from the table (in no particular order)
with a limit of 50 deletions per batch.

**Note:** 
    * `-l` defines the amount of deletions that will occur at once.  If not specified the default limit is 1000.
    * `-c` defines the number of events to consider for deletion.  This flag overrides the batch calculation that occurs if it is unset.
      unset.
