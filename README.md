# PheP DUP 1 Vorhofflimmern

## Development

### Build Image

```bash
docker build -t registry.gitlab.com/smith-phep/dup/vhf .
```

### Run Image

```bash
docker run --rm --name vhf -it -e FHIR_ENDPOINT="https://mii-agiop-polar.life.uni-leipzig.de/fhir" -e FHIR_USERNAME="polar" -e FHIR_PASSWORD="<pw>" registry.gitlab.com/smith-phep/dup/vhf
```
