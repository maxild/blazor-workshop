## Developer certificate on Linux

From the root

```
$ ./scripts/create-dev-cert.sh
```

This script will also imprt the certicate into aspnetcore

```bash
$ dotnet dev-certs https --clean --import $PFXFILE -p ""
```

such that the following environment variables are not required for Kestrel
to serve it

```json
"env": {
  "ASPNETCORE_ENVIRONMENT": "Development",
  "ASPNETCORE_Kestrel__Certificates__Default__Password": "password",
  "ASPNETCORE_Kestrel__Certificates__Default__Path": "$PFXFILE"
}
```

where `$PFXFILE` is some variable conating the absolute path to the public key
(self-signed certifacte).

## Running the project

```bash
$dotnet run --project BlazingPizza.Server/BlazingPizza.Server.csproj
```

or with `dotnet-watch`

```bash
dotnet watch run --project BlazingPizza.Server/BlazingPizza.Server.csproj
```
