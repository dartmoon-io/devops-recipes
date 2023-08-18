# Portainer

Start the portainer container
```bash
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/docker/portainer/volumes/data:/data portainer/portainer-ee:latest
```

Start the portainer agent container
```bash
sudo docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes -v /:/host -v /var/docker/portainer-agent/volumes/data:/data --restart always -e EDGE=1 -e EDGE_ID=[EDGE_ID] -e EDGE_KEY=[EDGE_KEY] -e EDGE_INSECURE_POLL=1 --name portainer-edge-agent --add-host=host.docker.internal:host-gateway portainer/agent:2.16.2
```

## Resources
- [https://www.portainer.io/blog/using-the-edge-agent-on-your-local-docker-instance](https://www.portainer.io/blog/using-the-edge-agent-on-your-local-docker-instance)

## Emergency access (SSO not working)
- `https://localhost:9443/#!/internal-auth`