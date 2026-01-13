This document describes a local development environment, or "playground," designed for practicing DevOps skills. It uses **Docker** and **K3d** to create isolated, interconnected environments for various projects. The setup enables you to simulate a production-like infrastructure on a single machine.

---

### 💻 Infrastructure Setup

The playground is built on a laptop with **Docker** installed. For macOS, **Rancher Desktop** is used as an alternative to Docker Desktop, with at least 4 CPU cores and 8 GB of RAM allocated to it. **K3d**, a lightweight tool for running **K3s** (a stripped-down Kubernetes distribution) in Docker, is installed to create and manage multiple Kubernetes clusters on the same machine. This setup allows for the creation of multiple clusters, like `dev` and `prod`, which can be used to simulate different environments.

### 🌐 Networking

A key component of this lab is the custom **Docker network** named `playground`. This network facilitates communication between all containers. The K3d clusters are attached to this network, allowing services within the clusters to communicate with other standalone containers.

To access services running on the laptop using a custom domain name, DNS entries are configured.

- **For a registered domain:** A DNS record is created (e.g., `*.lab.ilearndevops.in`) to point to the loopback address `127.0.0.1`. This ensures that traffic for this domain name is routed to the local machine.
- **For a made-up domain:** An entry is added to the `/etc/hosts` file (e.g., `lab.somedomain.com 127.0.0.1`). This method doesn't allow for the use of Let's Encrypt for SSL certificates, as it only works for public domains.

**Traefik** is installed in docker which acts as a load balancer and reverse proxy, routing incoming traffic to the correct services based on defined rules. It also handles **SSL termination**, encrypting and decrypting traffic for secure connections.

---

### 🛠️ Projects and Tools

The following tools and projects are an integral part of this playground, each serving a specific purpose:

- **Portainer:** A web-based user interface for managing Docker environments. It simplifies tasks like deploying, managing, and monitoring containers, and can also be used to manage Kubernetes clusters.
- **dnsmasq:** A lightweight DNS forwarder and DHCP server used for resolving internal domain names within the lab. It provides a simple way to manage local DNS records, ensuring that internal services can be accessed by name.
- **Traefik:** This tool serves as the primary **load balancer** and **reverse proxy**. It's crucial for routing external traffic to the correct services running on the K3d clusters.
- **GitLab:** A comprehensive platform for the software development lifecycle. It includes **Git repository management**, **Continuous Integration/Continuous Delivery (CI/CD)** pipelines, and other DevOps tools. The `gitlab-runner` is used to execute the CI/CD jobs defined in GitLab.
