## Motivation

In order to avoid mapping explosion, Elasticsearch comes with a [default limit](https://www.elastic.co/guide/en/elasticsearch/reference/master/mapping-settings-limit.html#mapping-settings-limit) 
set to 1000 fields in an index. In an environment where the log structure is dynamic, it is possible to exceed that limit. The requests to Elasticsearch will fail with an error:
```
"reason":"Limit of total fields [1000] in index [_index_name_] has been exceeded"
```
Recent versions of Elasticsearch come with the [flattened](https://www.elastic.co/guide/en/elasticsearch/reference/current/flattened.html#flattened) field type that perfectly suited to handle that error.
If that field type is not an option in your version, there is no other way to index data, and the whole message is lost.



`fluentbit-flattened-filter` implements fluent-bit's [Lua filter plugin](https://docs.fluentbit.io/manual/pipeline/filters/lua)
that convert some part of complex log object to string:
```json
{
  "logs": {
    "message": {
      "foo": {
        "bar": {
          "baz1": "This is example",
          "baz2": "This is example too"
        }
      }
    }
  }
}
```
to
```json
{
  "log": {
    "message": "\"foo.bar.baz1\": \"This is example\", \"foo.bar.baz2\": \"This is example too\""
  }
}
```
## Configuration

It is possible to configure script parameters via environment variables:
```
LUA_FLATTENED_PATH - path to part of log object to be converted, in example above it is set to "logs.message"
LUA_FLATTENED_SEPARATOR - in example above it is use default value '.'
```

### Kubernetes

Starting from `v2.10.0`, the [official fluent-bit chart](https://github.com/helm/charts/tree/master/stable/fluent-bit)
supports [init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
via `initContainers` value. Below is the example of `values.yaml` that installs
`fluentbit-flattened-filter` before starting fluent-bit:

```yaml
env:
  # https://github.com/Pango-Inc/fluentbit-flattened-filter#configuration
  - name: LUA_FLATTENED_PATH
    value: "log.message"

extraVolumes:
  - name: &vol_name plugins
    emptyDir:
      medium: Memory
      sizeLimit: 5Mi

extraVolumeMounts:
  - name: *vol_name
    mountPath: &plugin_path /fluent-bit/plugins

# https://docs.fluentbit.io/manual/pipeline/filters/lua
extraEntries:
  filter: |-
    [FILTER]
        Name            lua
        Match           *
        script          /fluent-bit/plugins/flattened.lua
        call            flattened

initContainers:
  load-plugin:
    image: "appropriate/curl:latest"
    imagePullPolicy: "IfNotPresent"
    volumeMounts:
      - name: *vol_name
        mountPath: *plugin_path
    command:
      - "/bin/sh"
      - "-c"
      - |
        curl -sS https://codeload.github.com/Pango-Inc/fluentbit-flattened-filter/zip/main -o /plugin.zip
        unzip /plugin.zip
        cp -av /fluentbit-flattened-filter-master/* /fluent-bit/plugins/
```
## Development

### Dev Environment

Clone repo and run:
```sh
docker compose up -d
```
then open `localhost:5601` to see results in Kibana.

### Linting

```sh
luacheck --globals main -- flattened.lua
```

### Testing

```sh
LUA_FLATTENED_PATH=log.message lua test.lua
```

### Known issues

You may see an error in fluent-bit logs like this:
```
[2022/10/05 20:41:59] [error] [filter:lua:lua.0] function main is not found
```
It means the script has or produce an error. Unfortunately, fluent-bit does not show errors from Lua.