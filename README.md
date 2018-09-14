# Batch Delete Events Table in DTR
Tool for deleting the events table in batches to prevent performance
bottlenecks.

## Usage
1. Log in to the DTR host, or set docker client directly to DTR docker daemon. [Docker CLI Options](https://docs.docker.com/engine/reference/commandline/cli/)
2. Run the following command
```
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock \
    squizzi/dtr-batch-event-delete:latest -l <batch delete limit>
```

`Batch delete limit` defines the amount of deletions that will occur at once.
The number of batches that will need to run will be calculated and displayed prior to executing the deletions.
