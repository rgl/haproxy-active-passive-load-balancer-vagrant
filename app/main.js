const os = require("os");
const fs = require("fs");
const http = require("http");
const https = require("https");

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

function main(http, options, metadata, port, healthzPort) {
    const ports = [port];
    if (port != healthzPort) {
        ports.push(healthzPort);
    }
    ports.forEach((port) => {
        const server = http.createServer(options, createRequestListener(metadata));
        server.listen(port);
    });
}

const fqdn = process.argv[2];
const metadata = {
    hostname: os.hostname(),
};
const httpsOptions = {
    // set the server certificate.
    key: fs.readFileSync(`${fqdn}-key.pem`),
    cert: fs.readFileSync(`${fqdn}-crt.pem`),
    // set the client certificate requirements.
    ca: fs.readFileSync('example-ca-crt.pem'),
    requestCert: false,
    rejectUnauthorized: false,
}
main(http, {}, metadata, process.argv[3], process.argv[4]);
main(https, httpsOptions, metadata, process.argv[5], process.argv[6]);
