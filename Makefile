.PHONY: all
all: get-protoc-plugins proto-gen

.PHONY: get-protoc-plugins
get-protoc-plugins:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.33
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3

.PHONY: proto
proto:
	protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative proto/file.proto

.PHONY: run-server
run-server:
	go run cmd/server/file/main.go

.PHONY: run-client
run-client:
	go run cmd/client/file/main.go

.PHONY: clean
clean:
	go mod tidy
	go mod vendor

.PHONY: test
test:
	go test ./... -v

.PHONY: gen-certs
gen-certs: gen-ca-certs gen-server-certs gen-client-certs

.PHONY: gen-ca-certs
gen-ca-certs:
	mkdir -p certs
	openssl genrsa -out certs/ca.key 4096
	openssl req -x509 -new -nodes -key certs/ca.key -sha256 -days 1024 -out certs/ca.crt -subj "/CN=gRPC CA"

.PHONY: gen-server-certs
gen-server-certs:
	openssl genrsa -out certs/server.key 4096
	openssl req -new -key certs/server.key -out certs/server.csr -subj "/CN=gRPC TLS Server"
	echo "subjectAltName=IP:0.0.0.0,IP:127.0.0.1,DNS:localhost" > certs/server_extfile.cnf
	openssl x509 -req -in certs/server.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/server.crt -days 1024 -sha256 -extfile certs/server_extfile.cnf

.PHONY: gen-client-certs
gen-client-certs:
	openssl genrsa -out certs/client.key 4096
	openssl req -new -key certs/client.key -out certs/client.csr -subj "/CN=gRPC TLS Client"
	echo "subjectAltName=IP:0.0.0.0,IP:127.0.0.1,DNS:localhost" > certs/client_extfile.cnf
	openssl x509 -req -in certs/client.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/client.crt -days 1024 -sha256 -extfile certs/client_extfile.cnf