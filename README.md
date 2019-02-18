# Batch Fix Nullified authorNamespace
Tool for fixing an issue caused by `tagmigration` that causes a zero length
`authorNamespace` string to occur in the metadata.

## Usage
1. Log in to the DTR host, or set docker client directly to DTR docker daemon. [Docker CLI Options](https://docs.docker.com/engine/reference/commandline/cli/)
2. Run the following command.

For example:

```
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock \
    squizzi/dtr-fix-authorNamespace:latest -l 50 -c 1000
```

Would perform a fix of 1000 tags from the table (in no particular order)
with a limit of 50 tags per batch.

**Note:**
* `-l` defines the **limit** of tags that will occur at once.  If not specified the default limit is 1000.
* `-c` defines the **event count** to consider for modification.  This flag overrides the batch calculation that occurs if it is unset.
