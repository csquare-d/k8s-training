# Understanding Kubernetes: Purpose, Trade-offs, and When to Use It

A practical guide to understanding what Kubernetes is, why it exists, and whether it's the right choice for your project.

## Why I Made This Training

I work on a project with a niche use case. We're not solving Google-scale problems, but we genuinely benefit from the features Kubernetes provides. It fits our needs well, even if we're not running thousands of containers across dozens of nodes.

I put this training together not because I'm an expert or because I think you should dedicate all your time to learning Kubernetes. I made it because I think it's an interesting technology, and the most common question I hear at work, even among very smart engineers, is still "what is Kubernetes?"

That question is surprisingly hard to answer without diving into containers, orchestration, distributed systems, and a dozen other concepts. I wanted to create something that serves as a primer: what Kubernetes is, how to use it at a basic level, and some security-related stuff too.

Mostly, this was just for fun. If you learn something useful, great. If you decide Kubernetes isn't for you and you never intend on touching it unless absolutely required, that's also valid. Either way, I hope this helps to demystify what the heck Kubernetes even is.

## What is Kubernetes?

Kubernetes (often abbreviated as K8s) is an open-source container orchestration platform. It automates the deployment, scaling, and management of containerized applications across clusters of machines.

Originally developed by Google based on their internal system called Borg, Kubernetes was open-sourced in 2014 and is now maintained by the Cloud Native Computing Foundation (CNCF).

At its core, Kubernetes solves a specific problem: **how do you reliably run and manage hundreds or thousands of containers across multiple machines?**

## The Problem Kubernetes Solves

Imagine you have a web application running in containers. At a small scale, you might run it on a single server with Docker. But as you grow, questions emerge:

- What happens when that server fails?
- How do you deploy updates without downtime?
- How do you scale up during traffic spikes?
- How do you distribute traffic across multiple instances?
- How do you manage configuration and secrets across environments?
- How do you ensure containers are healthy and restart failed ones?

Kubernetes provides answers to all of these through a declarative system: you tell Kubernetes what you want (e.g., "run 5 copies of this container, ensure they're healthy, and load balance traffic to them"), and Kubernetes figures out how to make it happen and keep it that way.

## Key Capabilities

**Self-healing**: Kubernetes monitors container health and automatically restarts failed containers, replaces containers when nodes die, and kills containers that don't respond to health checks.

**Horizontal scaling**: Scale your application up or down manually with a command, or automatically based on CPU usage, memory, or custom metrics.

**Service discovery and load balancing**: Kubernetes gives containers their own IP addresses and a single DNS name for a set of containers, and can load-balance traffic across them.

**Automated rollouts and rollbacks**: You can describe the desired state for your deployed containers, and Kubernetes changes the actual state to match. It can roll out changes gradually and roll back if something goes wrong.

**Secret and configuration management**: Deploy and update secrets and application configuration without rebuilding container images or exposing secrets in your stack configuration.

**Storage orchestration**: Automatically mount storage systems of your choice—local storage, cloud providers, network storage systems.

## Should You Learn Kubernetes?

It depends on your role, goals, and where you are in your career.

**For infrastructure engineers, DevOps peeps, and platform engineering:** Kubernetes knowledge is increasingly expected. It's become an industry standard ask for these positions, and understanding it opens doors. Job postings in this space frequently list Kubernetes as a requirement or strong preference. Even if your current organization doesn't use it, your next one might. The concepts you learn (declarative infrastructure, container orchestration, service discovery) transfer to other tools too. If this is your career path, investing time here will pay off.

If you're job hunting in this space, Kubernetes on your resume does matter. It's one of those technologies that recruiters and hiring managers actively search for. Having hands-on experience, even from a home lab or personal projects, sets you apart from candidates who only have theoretical knowledge. Be prepared to talk about what you've actually done with it, not just that you've "worked with" it.

**For developers:** Learning the basics helps you collaborate with operations teams and helps you understand how your code runs in production, but deep expertise isn't explicitly necessary. Knowing how to read a Deployment manifest, understand why your pod is crashing, or interpret resource limits makes you more effective when debugging issues. You don't need to know how to set up a cluster from scratch or configure network policies. Focus on the parts that affect your code: how containers work, how environment variables and secrets get injected, how health checks function, and how to read logs. Leave the cluster administration to the platform team.

For job seekers, listing Kubernetes as a developer is a nice-to-have, not a must-have. It signals that you understand modern deployment practices, but interviewers won't expect you to whiteboard cluster architecture. If you're applying to companies that mention Kubernetes in their stack, being able to say "I've deployed my apps to Kubernetes and can troubleshoot basic issues" is enough. Don't oversell it or claim expertise you don't have.

**For security professionals:** The calculus is *very* different. Unless you're specifically doing cloud security, container security, or working in an organization that runs Kubernetes, it's likely not relevant to your day-to-day work. Most security roles (application security, GRC, SOC analysts, penetration testers focused on traditional infrastructure) won't encounter Kubernetes with any level of regularity.

Consider what you actually do day-to-day:

- **Application security engineers** spend time on code review, SAST/DAST, threat modeling, and working with developers. Kubernetes rarely enters the picture unless you're reviewing infrastructure-as-code.
- **GRC and compliance folks** care about policies, frameworks, and audit evidence. Kubernetes is just another system to assess against controls, not something requiring deep technical expertise.
- **SOC analysts** are looking at alerts, logs, and incidents. You might see Kubernetes-related events in a SIEM, but you don't need to understand pod scheduling to investigate them.
- **Traditional penetration testers** are testing networks, web apps, and Active Directory. Kubernetes engagements are a specialty niche, not the expectation.

If Kubernetes doesn't show up in your work, learning it is a curiosity project, not a career necessity.

Learning it isn't harmful, but there's certainly an opportunity cost. Time spent learning Kubernetes is time not spent on skills which may be more directly applicable to your role. That time could go toward learning a new exploitation technique, getting better at threat modeling, studying for a certification relevant to your job, or just getting better at the fundamentals of your craft.

**For security job seekers specifically:** Look at the job postings you're interested in. If they mention Kubernetes, cloud security, or container security, then yes, learn it. If they don't, your time is probably better spent elsewhere. The security job market is competitive, and you want to optimize for skills that actually appear in the roles you're targeting.

A common trap is adding every technology to your resume hoping something sticks. From an interviewer's perspective, I notice when candidates list Kubernetes but can't answer basic questions about it. If you do list Kubernetes, be ready to explain what you've done with it and discuss its security model.

That said, cloud and container security roles are growing. If you're trying to break into security or pivot within it, specializing in this area is a strategy. The demand is real, and there's less competition than in traditional security roles because the skill set is newer.

**A middle-ground approach:** If you're in security and curious, consider understanding Kubernetes security concepts at a high level (RBAC, network policies, pod security) without going deep on operations. Know what the attack surface looks like. Understand why a privileged container is dangerous. Be able to read a manifest and spot red flags. You don't need to know how to install Calico or troubleshoot kubelet issues. This gives you enough context to have informed conversations and assess risk without becoming a Kubernetes administrator.

This level of knowledge is also enough for most interviews. If a security role asks about Kubernetes and it's not specifically a cloud security position, they usually want to know that you understand the risks, not that you can administer a cluster.

**When it becomes relevant:** If you're eyeing a move into cloud or container security, or your workplace is adopting Kubernetes, then learning it makes sense. Cloud security roles increasingly expect Kubernetes knowledge because so many organizations run workloads on EKS, GKE, or AKS. Container security is a growing specialty with dedicated tools (Falco, Trivy, kubescape) and real demand. If your company is migrating to Kubernetes, getting ahead of that curve makes you valuable. These exercises would be a good starting point for any of those scenarios.

**The bottom line for job seekers:** Be strategic. Look at actual job postings for roles you want. Count how many mention Kubernetes. If it's most of them (at the time of writing this (December 2025), it most definitely is not in the majority), prioritize learning it. If it's few or none, spend your time on skills that will actually get you hired. The goal is to land a job, not to collect technologies.

For those who want to go into the "security engineering" space rather than GRC, SOC analyst, or application security roles, Kubernetes may become more relevant. Security engineering often sits closer to infrastructure, building security tooling, hardening systems, and working alongside platform teams. In that world, understanding how Kubernetes works is increasingly becoming a part of the job.

---

## The Honest Truth: You Probably Don't Need Kubernetes

Here's something that often gets lost in the hype: **most applications don't need Kubernetes**.

Kubernetes was designed for Google-scale problems. Unless you're operating at significant scale or have specific requirements that align with Kubernetes' strengths, you're likely adding complexity without proportional benefit.

### Signs You Might NOT Need Kubernetes

**Your team is small.** Kubernetes has a steep learning curve. If you have a small team, the time spent learning and maintaining Kubernetes infrastructure could be spent building product features. A small team managing Kubernetes often means everyone becomes a part-time infrastructure engineer.

**Your application is simple.** A monolithic application, a few services, or a straightforward web app doesn't need container orchestration. A single server with Docker Compose, or a Platform-as-a-Service like Heroku, Render, or Railway, will serve you well with far less complexity.

**You don't need to scale dynamically.** If your traffic is predictable and you're not constantly scaling up and down, you're paying the complexity tax of Kubernetes without using its primary benefit.

**You're a startup trying to move fast.** In the early stages, speed of iteration matters more than perfect infrastructure. You can always migrate to Kubernetes later when you actually need it. Premature optimization applies to infrastructure too.

**You're running a single container or a handful of services.** Docker Compose on a single VM is simpler, faster to set up, and easier to understand. You can run a surprisingly large workload on a single well-provisioned server.

### The Hidden Costs of Kubernetes

**Operational complexity**: Kubernetes clusters require maintenance—upgrades, security patches, monitoring, backup strategies. Even managed Kubernetes (EKS, GKE, AKS) doesn't eliminate this; it just shifts some of the burden.

**Learning curve**: Kubernetes has a vast surface area. Pods, Deployments, Services, Ingress, ConfigMaps, Secrets, RBAC, Network Policies, PersistentVolumes, StatefulSets, DaemonSets, CRDs... the list goes on. Your team needs to understand these concepts to operate effectively.

**Debugging difficulty**: When something goes wrong in Kubernetes, debugging can be challenging. Issues might be in your application, the container, the pod configuration, the network policy, the service mesh, the ingress controller, or the cluster itself.

**Resource overhead**: Kubernetes itself consumes resources. The control plane, monitoring, logging, and networking components all require CPU and memory. For small workloads, this overhead can be a significant percentage of your total resource usage.

**Cost**: Running a Kubernetes cluster—even a managed one—costs more than simpler alternatives. You're paying for control plane nodes, worker node overhead, load balancers, and often additional tooling.

---

## When Kubernetes Makes Sense

Despite the caveats, Kubernetes is genuinely excellent for certain use cases:

**You're running many services at scale.** If you have dozens or hundreds of microservices that need to communicate, scale independently, and be deployed frequently, Kubernetes provides the primitives to manage this complexity.

**You need high availability.** Kubernetes makes it straightforward to run applications across multiple nodes and availability zones, automatically handling failover.

**You have variable workloads.** If your traffic varies significantly (e.g., e-commerce during sales, batch processing jobs), Kubernetes' autoscaling capabilities provide real value.

**You're running in multiple environments.** Kubernetes provides a consistent deployment target across development, staging, and production, and across different cloud providers or on-premises data centers.

**You need advanced deployment strategies.** Blue-green deployments, canary releases, A/B testing—Kubernetes and its ecosystem make these patterns achievable.

**You're building a platform.** If you're providing infrastructure for multiple teams or building an internal platform, Kubernetes offers a foundation with strong primitives for multi-tenancy, resource quotas, and isolation.

**Your team already has Kubernetes expertise.** If your organization has invested in Kubernetes knowledge and tooling, the marginal cost of using it for new projects is lower.

---

## Kubernetes vs. Alternatives

### Docker Compose

**What it is**: A tool for defining and running multi-container applications on a single host.

**Choose Docker Compose when**:
- You're running on a single server
- You have a small number of services (< 10)
- You want simplicity and fast iteration
- Your team is small and not experienced with orchestration
- You're in development or running small production workloads

**Choose Kubernetes over Docker Compose when**:
- You need to run across multiple nodes
- You need automatic failover and self-healing
- You need to scale dynamically
- You have many services that need complex networking

**The reality**: Docker Compose can take you surprisingly far. Many successful companies run production workloads on Docker Compose until they genuinely outgrow it.

### Docker Swarm

**What it is**: Docker's native clustering and orchestration solution, built into the Docker Engine.

**Advantages of Docker Swarm**:
- Much simpler than Kubernetes
- Built into Docker—no additional installation
- Familiar Docker Compose syntax (with some modifications)
- Easier learning curve
- Good enough for many production workloads

**Why Kubernetes often wins**:
- Larger ecosystem and community
- More features (RBAC, network policies, custom resources)
- Better support from cloud providers
- More tooling and integrations
- Industry momentum (more job opportunities, more documentation)

**The reality**: Docker Swarm is technically capable and much simpler than Kubernetes. It "lost" not because of technical inferiority but because of ecosystem momentum. For small-to-medium workloads, Swarm remains a valid choice, but finding Swarm expertise and tooling is increasingly difficult.

### Managed Container Services (ECS, Cloud Run, App Runner, Fly.io)

**What they are**: Cloud provider services that run containers without requiring you to manage orchestration infrastructure.

**Choose managed services when**:
- You want to focus on your application, not infrastructure
- You're okay with some vendor lock-in
- You have straightforward scaling needs
- You want operational simplicity
- You're a small team or just one person

**Choose Kubernetes over managed services when**:
- You need portability across clouds or don't want to settle down into a cloud platform just yet
- You need fine-grained control over networking and security
- You have complex orchestration requirements
- You want to avoid vendor lock-in
- You need to run on-premises or in hybrid environments

**The reality**: For many teams, managed container services offer the right balance of capability and simplicity. AWS ECS/Fargate, Google Cloud Run, and Fly.io can handle significant scale without Kubernetes complexity.

### Platform-as-a-Service (Heroku, Render, Railway)

**What they are**: Platforms that abstract away infrastructure entirely, letting you deploy code directly.

**Choose PaaS when**:
- You want maximum simplicity
- You're building standard web applications
- Your team has limited DevOps expertise
- You want to move fast and iterate quickly
- Cost efficiency is less important than developer productivity

**Choose Kubernetes over PaaS when**:
- You need more control over your infrastructure
- You have specific compliance or security requirements
- You're at a scale where PaaS becomes expensive
- You need capabilities PaaS doesn't offer

**The reality**: PaaS is often dismissed as "not serious" infrastructure, but this is misguided. Many successful companies run on Heroku or similar platforms for years. The simplicity and developer experience are genuine advantages.

### Nomad (HashiCorp)

**What it is**: A flexible orchestrator for deploying containers, VMs, and standalone applications.

**Advantages of Nomad**:
- Simpler architecture than Kubernetes
- Can orchestrate non-containerized workloads
- Integrates well with other HashiCorp tools (Consul, Vault)
- Lower operational overhead
- Easier to understand and debug

**Why Kubernetes often wins**:
- Larger ecosystem
- More cloud provider support
- More third-party integrations
- Larger talent pool

**The reality**: Nomad is a technically excellent product that's simpler than Kubernetes while still being highly capable. It's worth serious consideration, especially if you already use HashiCorp tools.

---

## Why Companies Choose Kubernetes

Despite the complexity, Kubernetes has become the dominant container orchestration platform. Here's why:

### Industry Standardization

Kubernetes has become the de facto standard. This creates a virtuous cycle:

- Cloud providers invest heavily in managed Kubernetes (EKS, GKE, AKS)
- Vendors build tooling for Kubernetes
- Developers learn Kubernetes
- Companies adopt Kubernetes because that's where the ecosystem is
- This further entrenches Kubernetes as the standard

**Practical impact**: It's easier to hire people who know Kubernetes than Docker Swarm or Nomad. There's more documentation, more Stack Overflow answers, more blog posts.

### Cloud Portability

Kubernetes provides a consistent abstraction across cloud providers and on-premises infrastructure. In theory, you can move workloads between AWS, GCP, Azure, or your own data center.

**The reality**: True portability is harder than it sounds. Applications often use cloud-specific services (RDS, S3, Cloud SQL) that don't exist everywhere. But Kubernetes does reduce the cloud-specific surface area and makes migration more feasible.

### The CNCF Ecosystem

The Cloud Native Computing Foundation (CNCF) has built a massive ecosystem around Kubernetes:

- **Prometheus** for monitoring
- **Envoy** for service mesh
- **Helm** for package management
- **Argo** for GitOps and workflows
- **Istio/Linkerd** for service mesh
- **Cert-manager** for TLS certificates
- **And hundreds more**

This ecosystem means you're rarely building from scratch. There's usually a project or tool that solves your problem (which is nice).

### Extensibility

Kubernetes is designed to be extended. Custom Resource Definitions (CRDs) and operators let you add new capabilities:

- Database operators that automate PostgreSQL or MySQL management
- Certificate operators that handle TLS automatically
- Custom controllers for your specific business logic

This extensibility lets Kubernetes grow to fit new use cases without changing its core.

### Resume-Driven Development (Let's Be Honest)

Some Kubernetes adoption is driven by engineers wanting to learn marketable skills rather than genuine technical need. This isn't necessarily learning to learn, in some ways Kubernetes is an industry-standard tool and has real career value to know, but it does mean some organizations run Kubernetes when simpler solutions would suffice.

---

## Current Trends in Kubernetes

### Managed Kubernetes is the Default

Most organizations use managed Kubernetes (EKS, GKE, AKS) rather than self-managed clusters. Running your own control plane is pretty rare outside of specific requirements (air-gapped environments, extreme customization needs).

### GitOps / CI-CD Paradigms

GitOps—using Git as the source of truth for infrastructure and application configuration—has become the standard deployment pattern for Kubernetes. Tools like ArgoCD and Flux watch Git repositories and automatically synchronize cluster state to match.

### Platform Engineering

Organizations are building internal developer platforms on top of Kubernetes, abstracting away its complexity. Instead of developers writing Kubernetes YAML, they interact with higher-level constructs:

- Developer portals (Backstage)
- Simplified deployment interfaces
- Golden paths that encode best practices

The goal is to get Kubernetes' benefits without requiring every developer to be a Kubernetes expert.

### Service Mesh Adoption (and Skepticism)

Service meshes (Istio, Linkerd) add observability, security, and traffic management to service-to-service communication. Adoption has grown but remains controversial. Many teams find the complexity isn't worth the benefits for their scale.

### Security Hardening

Kubernetes security has matured significantly:

- Pod Security Standards (replacing Pod Security Policies)
- Policy engines (Kyverno, OPA/Gatekeeper)
- Supply chain security (Sigstore, SBOM)
- Runtime security (Falco, Sysdig)

Organizations are moving from "get it running" to "get it running securely."

### Cost Optimization

As Kubernetes usage has grown, so has spending. There's increasing focus on:

- Right-sizing resource requests
- Autoscaling to match actual demand
- Spot/preemptible instances for non-critical workloads
- Cost visibility and chargeback

### Edge and IoT

Lightweight Kubernetes distributions (K3s, MicroK8s, K0s) are enabling Kubernetes at the edge—retail stores, factories, IoT devices. Same orchestration patterns, smaller footprint, and *way easier to  manage*.

### WebAssembly (Wasm)

Early experiments are using WebAssembly as an alternative to containers. Projects like Krustlet and spin explore running Wasm workloads alongside or instead of containers. This is nascent but worth watching.

---

## Making the Decision

Here's a simple way to decide whether to use Kubernetes:

```
┌─────────────────────────────────────────────────────────────────┐
│                    DO YOU NEED KUBERNETES?                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │ Are you running > 10 services │
              │ that need to scale            │
              │ independently?                │
              └───────────────────────────────┘
                     │              │
                    YES             NO
                     │              │
                     ▼              ▼
        ┌─────────────────┐   ┌─────────────────────────┐
        │ Do you have the │   │ Consider simpler        │
        │ team/expertise  │   │ alternatives:           │
        │ to operate it?  │   │ • Docker Compose        │
        │                 │   │ • Managed containers    │
        └─────────────────┘   │ • PaaS                  │
           │          │       └─────────────────────────┘
          YES         NO
           │          │
           ▼          ▼
    ┌──────────┐  ┌────────────────────┐
    │ Consider │  │ Consider:          │
    │ K8s with │  │ • Managed K8s +    │
    │ managed  │  │   platform team    │
    │ or self- │  │ • Simpler          │
    │ hosted   │  │   orchestration    │
    └──────────┘  └────────────────────┘
```

### Questions to Ask

1. **What problem are we solving?** Be specific. "We need Kubernetes" isn't a problem statement. "We need to deploy 50 services across 3 availability zones with zero-downtime updates" is.

2. **What's the simplest solution that works?** Start simple and add complexity only when needed. You can always migrate to Kubernetes later.

3. **Who will operate this?** Kubernetes requires ongoing maintenance. Can you (and want to) do this?

4. **What's our scale?** Are you running 3 containers or 300? The answer changes the calculus significantly.

5. **What's our timeline?** If you need to ship quickly, a simpler solution now plus migration later might be better than learning Kubernetes under deadline pressure.

---

## Conclusion

Kubernetes is a powerful platform that solves real problems at scale. It has become the industry standard for container orchestration, backed by a massive ecosystem and community.

But it's not the right choice for everyone. The complexity is real, and for many applications, simpler alternatives provide better outcomes with less effort.

The best infrastructure decision is the one that lets you ship reliable software efficiently. Sometimes that's Kubernetes. Often, it's something simpler.

Don't adopt Kubernetes because it's trendy. Adopt it because you've evaluated the alternatives and determined it's the right fit for your specific needs and scale.

---
