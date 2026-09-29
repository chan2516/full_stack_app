module.exports = {
  apps: [{
    name: "contact-frontend",
    cwd: "/opt/contact-app/frontend",
    script: "server.js",
    env: {
      PORT: "3000",
      BACKEND_URL: "http://127.0.0.1:5000"
    }
  }]
};
