const os = require("os");
const http = require("http");

function createRequestListener(metadata) {
    return (request, response) => {
        const serverAddress = `${request.socket.localAddress}:${request.socket.localPort}`;
        const clientAddress = `${request.socket.remoteAddress}:${request.socket.remotePort}`;
        const message = `Hostname: ${metadata.hostname}
Server Address: ${serverAddress}
Client Address: ${clientAddress}
Request URL: ${request.url}
`;
        console.log(message);
        response.writeHead(200, {"Content-Type": "text/plain"});
        response.write(message);
        response.end();
    };
}

function main(metadata, port, healthzPort) {
    const ports = [port];
    if (port != healthzPort) {
        ports.push(healthzPort);
    }
    ports.forEach((port) => {
        const server = http.createServer(createRequestListener(metadata));
        server.listen(port);
    });
}

const metadata = {
    hostname: os.hostname(),
};
main(metadata, process.argv[2], process.argv[3]);
