# Batch Delete Events Table in DTR
Tool for deleting the events table in batches to prevent performance
bottlenecks.

## Usage
```
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock \
    squizzi/dtr-batch-event-delete:latest -l <batch delete limit>
```

Batch delete limit defines the amount of deletions that will occur at once,
the number of batches that will need to run will be calculated prior to
deletions running.
