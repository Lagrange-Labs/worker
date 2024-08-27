# Update a Worker

1. Stop the worker
  ``` sh
  # If you are running docker compose directly
  docker compose down
  # If you are running the worker in systemd
  sudo systemctl stop worker.service
  ```
---
2. Update the worker

**Update from source**
 If you are building the docker from source then check `Build_from_source.md` in this same git repository.
 Make sure to edit the version to the version you would like to update to. 
 The newly built docker with the tag `lgn-coprocessor:local` should override your previous docker image.

**Update by pulling from dockerhub**

```sh
docker pull lagrangelabs/worker:mainnet
```
---
3. Run the worker
   ```sh
   # If you are running docker compose directly
   docker compose up -d
   # If you are running the worker in systemd
   sudo systemctl start worker.service
   ```