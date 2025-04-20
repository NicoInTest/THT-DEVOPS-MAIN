# Explain decisions made during the implmentation of the test

## AWS ECS-EC2 Implementation Decisions

### Infrastructure Design
1. **ECS Cluster with EC2 Instances**: 
   - **Test Environment Decision**: Used an EC2-backed ECS cluster to provide a cost-effective solution that stays within AWS Free Tier limits while still providing the necessary flexibility.
   - **Production Alternative**: In production, I would consider using ECS Fargate for serverless container management to eliminate the need to manage EC2 instances, which would improve operational efficiency and provide better auto-scaling capabilities.

2. **Auto Scaling Group**: 
   - **Test Environment Decision**: Implemented with a minimum of 1 instance and a maximum of 2 instances to handle potential load increases while maintaining cost efficiency.
   - **Production Alternative**: Would implement more granular auto-scaling policies based on CPU utilization, memory usage, and request count metrics with appropriate thresholds. Would also consider scheduled scaling for predictable traffic patterns.
   - **Enhanced Production Strategy**: Would implement advanced autoscaling based on multiple metrics including request latency, queue depth, and custom business metrics to ensure optimal performance under varying load conditions. Would also use predictive scaling based on historical patterns for anticipated traffic spikes.

3. **Service Discovery**: 
   - **Test Environment Decision**: Implemented AWS Service Discovery to allow services to communicate with each other using DNS SRV records. This makes it easier for the Order API to locate and connect to the Order Processor service.
   - **Production Alternative**: Would integrate with Route 53 for more robust DNS-based service discovery with health checking. In a more complex application, might consider implementing AWS App Mesh for service mesh capabilities.

4. **Application Load Balancer**: 
   - **Test Environment Decision**: Deployed an ALB for the Order API service to distribute traffic and provide a stable endpoint. The Order Processor is accessed internally only, so it doesn't need a public load balancer.
   - **Production Alternative**: Would implement WAF for the ALB to provide additional security, configure proper SSL/TLS policies, and set up more advanced routing rules for blue/green deployments.

5. **DynamoDB Configuration**: 
   - **Test Environment Decision**: Used PAY_PER_REQUEST billing to stay within Free Tier limits and avoid provisioning unnecessary capacity.
   - **Production Alternative**: Would analyze access patterns and potentially use provisioned capacity with auto-scaling for predictable workloads to optimize costs. Would also implement DynamoDB global tables for multi-region redundancy for critical data.
   - **Data Backup and Recovery**: Would implement comprehensive backup strategies using DynamoDB point-in-time recovery (PITR) and regular exports to S3 with appropriate retention policies. Would develop and regularly test disaster recovery procedures including cross-region recovery scenarios and data restoration exercises to ensure business continuity.
   - **Multi-Region Resilience**: Would implement DynamoDB global tables across multiple AWS regions to provide continuous availability even if an entire region experiences an outage. Would use multi-region read replicas to reduce latency for global users and provide failover capability.

6. **Container Image Building Strategy**:
   - **Test Environment Decision**: Used single-platform (linux/amd64) Docker builds to ensure simplicity and reliability during the deployment process. This decision was made after encountering issues with multi-platform builds that required more complex Docker buildx configuration.
   - **Production Alternative**: Would implement a proper CI/CD pipeline with multi-architecture builds (amd64, arm64) using Docker buildx with push-only workflow. Would set up a dedicated build system in GitHub Actions or AWS CodeBuild to handle multi-platform image building efficiently and reliably. This would provide flexibility for deploying to different types of EC2 instances, including AWS Graviton (ARM-based) instances for cost optimization.

7. **HTTPS Implementation**:
   - **Test Environment Decision**: Initially planned to implement HTTPS with a self-signed certificate, but encountered issues with ACM certificate validation. Decided to use HTTP-only for the test environment to streamline deployment and avoid timeout issues with certificate validation. This allows for faster testing while demonstrating core functionality.
   - **Production Alternative**: For production, HTTPS would be absolutely essential. Would implement proper TLS/SSL using validated ACM certificates with a registered domain name. Would configure automatic certificate renewal, HTTP-to-HTTPS redirection, and implement security headers like HSTS, CSP, and XSS protection. Would also ensure all internal service-to-service communication uses encryption in transit.

8. **Health Check Configuration**:
   - **Test Environment Decision**: Implemented basic health checks for ECS services to detect and recover from failures.
   - **Production Alternative**: Would fine-tune health check thresholds and intervals based on application behavior under load. Would implement more sophisticated health checks that validate not just basic connectivity but also application functionality and downstream dependencies. Would adjust grace periods and stabilization windows to prevent premature instance termination during deployments or temporary spikes.

9. **Monitoring and Alerting**:
   - **Test Environment Decision**: Utilized basic CloudWatch metrics available through ECS and ALB.
   - **Production Alternative**: Would implement comprehensive CloudWatch alarms for critical metrics including CPU/memory utilization, request latency, error rates, and queue depths. Would set up alerts with appropriate thresholds based on application-specific SLAs and performance baselines. Would integrate with notification systems like SNS for automated alerting and potentially integrate with incident management platforms like PagerDuty or OpsGenie.

10. **Data Encryption**:
   - **Test Environment Decision**: Used default encryption settings for simplicity in the test environment.
   - **Production Alternative**: Would enable server-side encryption for DynamoDB tables with AWS-managed keys or customer-managed KMS keys based on compliance requirements. Would implement encryption in transit for all communications and ensure proper key rotation policies. Would implement additional application-level encryption for sensitive data fields before storing in the database.

### Security Considerations
1. **IAM Roles**: 
   - **Test Environment Decision**: Implemented the principle of least privilege for IAM roles by limiting permissions strictly to what each service requires. Created fine-grained policies for DynamoDB access, ECR image pulling, and service discovery, restricting each service to only the resources it needs to access. Added region conditions to policies where applicable to prevent cross-region access.
   - **Production Alternative**: Would implement a more comprehensive permission boundary system with regular permission reviews, and integrate with AWS Organizations for multi-account security management.

2. **Network Isolation**: 
   - **Test Environment Decision**: Enhanced network security by implementing strict security group rules that follow the principle of least privilege. Restricted all security groups to only the necessary ports and protocols needed for communication, eliminating overly permissive 0.0.0.0/0 CIDR blocks for outbound traffic. Created a proper segmentation between public and private subnets, with public-facing resources only in public subnets and application/data tier in private subnets.
   - **Production Alternative**: Would implement a more rigorous network segmentation with dedicated subnets for different tiers, and use AWS PrivateLink for secure service-to-service communication without traversing the public internet.

3. **Security Groups**: 
   - **Test Environment Decision**: Implemented fine-grained security groups with restricted inbound and outbound rules following the principle of least privilege. Added descriptive comments for each rule to document its purpose. Limited the ALB security group to only communicate with ECS tasks and the ECS task security group to only communicate with required AWS services through VPC endpoints. Enhanced security groups with proper descriptions and traffic flows for better auditability.
   - **Production Alternative**: Would implement more granular security group rules with specific IP address ranges, port restrictions, and regular auditing. Would also implement Network ACLs as an additional security layer.

4. **VPC Endpoints**:
   - **Test Environment Decision**: Secured VPC endpoints with dedicated security groups that restrict traffic to only the necessary communications from ECS tasks. Implemented gateway endpoints for S3 and DynamoDB, and interface endpoints for other AWS services to allow private communication without traversing the internet.
   - **Production Alternative**: Would implement additional controls like endpoint policies to further restrict which principals and actions are allowed through each endpoint.

5. **Secrets Management**:
   - **Test Environment Decision**: Environment variables are defined directly in the task definitions/deployment files for simplicity in the test environment.
   - **Production Alternative**: Would implement AWS Secrets Manager or HashiCorp Vault for secure storage and management of sensitive information such as database credentials, API keys, and other secrets. Would implement automatic rotation of secrets, fine-grained access controls, and audit logging for all secret access. Would ensure that application containers retrieve secrets at runtime rather than having them included in environment variables or configuration files.

### DevOps Best Practices
1. **Health Checks**: 
   - **Test Environment Decision**: Implemented comprehensive health checks for both services to ensure robust monitoring.
   - **Production Alternative**: Would implement more sophisticated health checks with dependency checks and integrate with a centralized health monitoring system to provide holistic service health visibility.

2. **CloudWatch Logs**: 
   - **Test Environment Decision**: Configured both services to send logs to CloudWatch for centralized logging and debugging.
   - **Production Alternative**: Would implement a more sophisticated logging strategy with log retention policies, structured logging formats, and integration with a log analysis tool like Elasticsearch/Kibana or Splunk. Would also set up CloudWatch alarms for error thresholds.

3. **Scalability**: 
   - **Test Environment Decision**: The architecture can easily scale as needed by adjusting the auto-scaling parameters.
   - **Production Alternative**: Would implement more advanced scaling strategies based on real-time metrics, predictive scaling, and use infrastructure as code tools for scaling the entire architecture consistently.

4. **Terraform State Management**:
   - **Test Environment Decision**: Implemented a consistent remote state management approach across all Terraform workspaces (ECR, ECS-EC2) using shared S3 backend and DynamoDB state locking. Created a centralized bootstrap process that sets up the required infrastructure, ensuring all workspaces use the same locking mechanism but with workspace-specific state file paths. This allows for concurrent operations on different parts of the infrastructure without conflicts. Used deployment scripts that handle environment-specific values and account ID substitution at runtime to ensure no sensitive information is stored in the codebase. All components use AWS free tier eligible services, with PAY_PER_REQUEST billing mode for DynamoDB tables.
   - **Production Alternative**: Would implement more comprehensive state file management with automated backups, versioning, and separate state files for different environments. Would also consider using Terraform Cloud for additional features like run history, policy checks, and team access controls.

5. **Environment Separation**:
   - **Test Environment Decision**: Implemented a flexible environment management approach that supports deploying to multiple environments (dev/stage/prod) through the same codebase. Enhanced deployment scripts to accept an ENVIRONMENT variable that changes resource naming, state file paths, and ECR repository references, allowing for true environment isolation without code duplication. This provides a clean separation of infrastructure between different environments while maintaining consistency in the deployment process. Each environment gets its own state file path in the shared S3 bucket and uses the same DynamoDB table for locking to prevent conflicts.
   - **Production Alternative**: Would implement complete logical separation with separate AWS accounts for each environment using AWS Organizations, with cross-account roles for deployment. Would use Terraform workspaces more extensively and potentially implement automated promotion workflows between environments.

## Kubernetes Implementation Decisions

### Infrastructure Design
1. **Minikube Setup**: 
   - **Test Environment Decision**: Used Minikube for local Kubernetes development, making it easy to test the deployment without incurring cloud costs.
   - **Production Alternative**: Would use a managed Kubernetes service like EKS, GKE, or AKS with proper node group configurations, or implement a self-managed cluster with appropriate control plane redundancy and worker node distribution.
   - **Enhanced Kubernetes Strategy**: Would implement EKS with managed node groups in multiple availability zones for high availability. Would use GitOps tools like ArgoCD or Flux for declarative, version-controlled application deployments that automatically sync with the desired state in Git repositories. This would provide better auditability, rollback capabilities, and automated drift detection compared to manual or CI/CD-triggered deployments.

2. **Service Exposure Strategy**: 
   - **Test Environment Decision**: Configured the Order API service as NodePort to allow direct external access in the Minikube environment. This provides a simple way to test the API without additional infrastructure while developing and testing locally.
   - **Production Alternative**: In a production Kubernetes environment, I would instead:
     - Deploy an Ingress Controller (like NGINX or Traefik)
     - Use ClusterIP services for all microservices
     - Configure Ingress resources for routing external traffic
     - Implement TLS termination for secure connections
     - Set up proper network policies to control inter-service communication
   - The production approach provides better security, more sophisticated routing, certificate management, and follows the principle of having a single controlled entrypoint to the cluster.

3. **DynamoDB Local**: 
   - **Test Environment Decision**: Used a local DynamoDB instance running in the cluster to simulate AWS DynamoDB, with persistence to maintain data between restarts. This approach allows for testing without external AWS dependencies.
   - **Production Alternative**: Would use actual AWS DynamoDB service with proper IAM roles for Kubernetes (using IRSA - IAM Roles for Service Accounts), and consider DynamoDB backups, point-in-time recovery, and global tables for production workloads.

4. **Helm Charts Structure**: 
   - **Test Environment Decision**: Organized the Helm chart to be modular, with separate templates for each service component, making it easier to maintain and extend.
   - **Production Alternative**: Would implement Helm chart versioning, use Helm chart repositories for distribution, and potentially implement Helm operators for more sophisticated lifecycle management.

### Application Configuration
1. **Environment Variables**: 
   - **Test Environment Decision**: Set environment variables directly in the Helm values file for clarity and ease of configuration in the test environment.
   - **Production Alternative**: Would use Kubernetes Secrets and ConfigMaps properly managed with external secret management tools like AWS Secrets Manager or HashiCorp Vault, and implement proper secret rotation policies.

2. **Image Pull Policy**: 
   - **Test Environment Decision**: Set to "Never" for local images in Minikube, relying on local Docker builds rather than pulling from a registry to simplify the local development workflow.
   - **Production Alternative**: Would use "Always" or "IfNotPresent" with proper image versioning (no "latest" tags) and a secure private container registry with vulnerability scanning.

3. **Health Checks**: 
   - **Test Environment Decision**: Implemented both liveness and readiness probes to ensure proper service health monitoring and graceful handling of service startup.
   - **Production Alternative**: Would implement more sophisticated health checks that verify downstream dependencies, with appropriate timeout, period, and threshold settings based on application behavior under load.

4. **Resource Limits**: 
   - **Test Environment Decision**: Defined both requests and limits for CPU and memory to ensure efficient resource utilization and prevent resource contention in the test environment.
   - **Production Alternative**: Would fine-tune resource settings based on actual performance metrics, implement Vertical Pod Autoscaler for automatic resource adjustments, and use Pod Disruption Budgets to ensure service availability during cluster operations.

### DevOps Practices
1. **Data Initialization**: 
   - **Test Environment Decision**: Created a Kubernetes Job with Helm hooks to automatically initialize the DynamoDB tables and seed data after deployment for a self-contained test environment.
   - **Production Alternative**: Would implement a more sophisticated database migration strategy, potentially using tools like Flyway or Liquibase, with proper versioning and rollback capabilities, and separate the concerns of data initialization from application deployment.

2. **Service Discovery**: 
   - **Test Environment Decision**: Used Kubernetes DNS for service discovery, allowing services to communicate using stable service names.
   - **Production Alternative**: Would consider implementing a service mesh like Istio or Linkerd for more advanced service discovery, traffic management, security policy enforcement, and observability.

3. **Testing Approach**: 
   - **Test Environment Decision**: Provided scripts and instructions for testing the deployment, ensuring that the system can be validated easily in the test environment.
   - **Production Alternative**: Would implement a comprehensive testing strategy including integration tests, load tests, chaos testing, and security scanning as part of the CI/CD pipeline.

### High Availability and Disaster Recovery for Kubernetes

1. **Multi-Cluster Architecture**:
   - **Test Environment Decision**: Used a single Minikube cluster for local development and testing.
   - **Production Alternative**: Would implement multiple Kubernetes clusters across different AWS regions using EKS. Would use tools like Cluster API or Terraform to ensure consistent cluster configuration across regions. Would implement cluster federation tools for cross-cluster resource management and service discovery.

2. **Stateless Application Resilience**:
   - **Test Environment Decision**: Basic deployment of services without specific high-availability considerations beyond Kubernetes' built-in self-healing.
   - **Production Alternative**: Would implement anti-affinity rules to spread pods across nodes and availability zones. Would use multiple replicas with horizontal pod autoscaling based on multiple metrics. Would implement PodDisruptionBudgets to ensure service availability during voluntary disruptions.

3. **Stateful Workload Protection**:
   - **Test Environment Decision**: Used local persistent volumes for DynamoDB local without replication.
   - **Production Alternative**: Would use AWS EBS volumes with snapshots for fast recovery. For true disaster recovery, would implement continuous backup solutions like Velero to back up both Kubernetes resources and persistent volume data to S3 buckets in multiple regions. Would schedule regular backup testing and disaster recovery drills.

4. **Cross-Region Service Discovery**:
   - **Test Environment Decision**: Used Kubernetes DNS for simple service discovery within the cluster.
   - **Production Alternative**: Would implement a global service discovery mechanism that works across clusters and regions. Options include advanced service mesh implementations like Istio with multi-cluster capabilities, or external service discovery tools. Would implement automated failover for services between regions.

5. **Global Load Balancing**:
   - **Test Environment Decision**: Used simple NodePort services for external access.
   - **Production Alternative**: Would implement a global load balancing solution using AWS Global Accelerator or CloudFront, combined with external-dns to automatically manage DNS records. Would configure health checks and routing policies to direct traffic away from unhealthy regions automatically.

## Observability Implementation Decisions

### Monitoring Architecture
1. **Prometheus Deployment**: 
   - **Test Environment Decision**: Deployed a single Prometheus instance in the Kubernetes cluster to collect metrics from the services and infrastructure. This provides the necessary monitoring capabilities without over-complicating the setup.
   - **Production Alternative**: Would implement a Prometheus Operator with multiple Prometheus instances for high availability, federation for scalability, and long-term storage solutions like Thanos or Cortex.

2. **Grafana Configuration**: 
   - **Test Environment Decision**: Deployed Grafana with pre-configured dashboards for Kubernetes and the microservices, using simple ConfigMaps to manage the dashboard definitions.
   - **Production Alternative**: Would use Grafana with a persistent database backend, implement proper user authentication with SSO, and set up finer-grained access controls. Would also use a dedicated team to manage dashboards with source control integration.

3. **Metrics Collection**: 
   - **Test Environment Decision**: Configured basic metric collection focusing on CPU, memory, and service health to demonstrate monitoring capabilities.
   - **Production Alternative**: Would implement the RED method (Request rate, Error rate, and Duration) and USE method (Utilization, Saturation, and Errors) for comprehensive service monitoring, along with business metrics, custom application metrics, and SLI/SLO tracking.

### Dashboard Design
1. **Dashboard Selection**: 
   - **Test Environment Decision**: Created two focused dashboards - one for Kubernetes overview and one for microservices monitoring, providing a clear view of the system's health.
   - **Production Alternative**: Would implement a more comprehensive dashboarding strategy with different levels of dashboards: executive summaries, service-level dashboards, infrastructure dashboards, and detailed troubleshooting views.

2. **Alerting**: 
   - **Test Environment Decision**: Basic dashboard visualization without explicit alerts, which is sufficient for a test environment with active monitoring.
   - **Production Alternative**: Would implement a comprehensive alerting strategy with Prometheus AlertManager, integrations with PagerDuty or OpsGenie, clear alert ownership, and runbooks for different alert scenarios.

### Security and Access Control
1. **Authentication**: 
   - **Test Environment Decision**: Used simple username/password authentication for Grafana access, which is sufficient for a test environment.
   - **Production Alternative**: Would implement SSO integration, MFA, and role-based access control with proper audit logging for all monitoring tools.

2. **Security Settings**: 
   - **Test Environment Decision**: Basic security settings focusing on functionality rather than hardening for a test environment.
   - **Production Alternative**: Would implement network policies to restrict monitoring tool access, use secure communication with TLS, and regularly scan monitoring components for vulnerabilities.

# What is missing 
1. **Infrastructure as Code for All Components**: While we've implemented Terraform for AWS and Helm for Kubernetes, a comprehensive solution would include all infrastructure components as code, including CI/CD pipelines, monitoring configuration, and alerting rules.

2. **Comprehensive Security Implementation**: The security aspects could be enhanced with network policies, pod security policies, and secure secret management.

3. **Environment Management Strategy**: A complete solution should include a strategy for managing multiple environments (dev, staging, production) with appropriate isolation, promotion workflows, and consistent configuration across environments.

4. **Advanced State Management**: Production-grade Terraform implementations should include remote state storage, state locking, and proper handling of state secrets and sensitive data.

# What could be improved 
1. **Automated Deployment Pipeline**: Create a fully automated CI/CD pipeline for building, testing, and deploying the application.

2. **Monitoring and Alerting**: Implement more comprehensive monitoring with automated alerting based on service-level indicators and objectives.

3. **Documentation**: Provide more detailed architectural diagrams and operational runbooks for common maintenance tasks.

4. **GitOps Implementation**: Implement GitOps practices with tools like ArgoCD or Flux for declarative, version-controlled application deployments in Kubernetes.

5. **Enhanced Data Protection**: Implement comprehensive backup, recovery, and disaster recovery procedures for all persistent data.

# What I would do if this was in a production environment and I had more time
1. **Replace NodePort with Ingress**: Implement a proper Ingress controller for external access to services rather than using NodePort, which would provide better security, routing capabilities, and TLS termination.

2. **Set Up Proper CI/CD Pipeline**: Create a fully automated pipeline for building, testing, and deploying the application to both ECS and Kubernetes environments.

3. **Implement Real Monitoring and Alerting**: Set up comprehensive monitoring with Prometheus and Grafana, with proper alerting rules based on SLIs/SLOs, and integrate with an incident management system.

4. **Security Enhancements**: Implement network policies, pod security policies, service mesh for mTLS between services, and proper secret management with external vault solutions.

5. **Disaster Recovery Plan**: Develop and test a comprehensive disaster recovery plan, including database backups, infrastructure recovery procedures, and regular DR exercises.

6. **Performance Optimization**: Conduct load testing to identify bottlenecks and optimize resource allocation, caching strategies, and database query performance.

7. **Documentation**: Create comprehensive documentation including architecture diagrams, operational procedures, troubleshooting guides, and runbooks for common incidents.

8. **Environment Strategy**: Establish a proper environment strategy with isolated dev/staging/prod environments, each with their own infrastructure and proper promotion workflows between them.

9. **Terraform State Management**: Implement remote state storage using S3 with state locking via DynamoDB, including state versioning and automated backups.

10. **GitOps for Kubernetes**: Implement ArgoCD or Flux for GitOps-based deployment and management of Kubernetes resources, providing better auditability and automated drift detection.

11. **Advanced Auto-Scaling**: Implement comprehensive auto-scaling strategies based on multiple metrics including request rates, latency, and custom business metrics to ensure optimal performance under varying load conditions.

12. **Secrets Management**: Implement HashiCorp Vault or AWS Secrets Manager for secure storage and automated rotation of sensitive information.

13. **Multi-Region Kubernetes Strategy**: Implement Kubernetes clusters across multiple regions for high availability and disaster recovery. Set up a global load balancing solution (such as AWS Global Accelerator or CloudFlare) to distribute traffic across regional Kubernetes clusters. Implement automated failover procedures and regular disaster recovery testing to ensure reliability during region-wide outages.

14. **Stateful Workload Protection**: For stateful services, implement cross-region replication for persistent volumes using solutions like Velero for backup/restore or specialized operators for database replication. Implement regular testing of the restore process to validate data integrity and recovery procedures.

15. **Global Data Consistency**: Design data replication and synchronization strategies that maintain data consistency across multiple regions while minimizing latency. Implement appropriate consistency models based on business requirements (strong consistency vs. eventual consistency) and regularly test failover scenarios to ensure data integrity.

16. **Cross-Region Service Mesh**: Extend service mesh capabilities across regions to provide unified service discovery, traffic management, and security policies regardless of where services are deployed. This enables seamless communication between services even during partial regional outages.

### High-Availability and Disaster Recovery

1. **Multi-Region Architecture**:
   - **Test Environment Decision**: Deployed services in a single region to minimize costs while demonstrating functionality.
   - **Production Alternative**: Would implement a multi-region architecture with active-active or active-passive configuration across at least two AWS regions. Would establish automated failover mechanisms with Route 53 health checks and DNS routing policies to redirect traffic to healthy regions. Would define Recovery Time Objective (RTO) and Recovery Point Objective (RPO) requirements and design the disaster recovery strategy accordingly.

2. **ECS Cluster Resilience**:
   - **Test Environment Decision**: Created ECS instances across multiple Availability Zones within a single region.
   - **Production Alternative**: Would implement ECS clusters in multiple regions with container images replicated to ECR repositories in each region. Would use infrastructure as code to ensure consistent deployment across regions and maintain warm standby environments in secondary regions that can scale up quickly during a regional outage.

3. **Data Replication**:
   - **Test Environment Decision**: Used local data storage without cross-region replication for test purposes.
   - **Production Alternative**: Would implement cross-region data replication for all persistent data including databases, object storage, and configuration. Would use AWS services like DynamoDB Global Tables, S3 Cross-Region Replication, and Aurora Global Database where appropriate. Would implement regular testing of data consistency and failover procedures.

4. **Disaster Recovery Testing**:
   - **Test Environment Decision**: Basic functionality testing without disaster simulation.
   - **Production Alternative**: Would implement regular disaster recovery testing through simulated region failures to validate failover processes. Would conduct "game day" exercises where teams practice responding to simulated disasters to ensure both technical systems and human processes work effectively during an actual outage. Would maintain runbooks with clear, step-by-step procedures for different failure scenarios.

5. **Network Resilience**:
   - **Test Environment Decision**: Used standard VPC configuration without advanced networking features.
   - **Production Alternative**: Would implement redundant network paths across regions using AWS Transit Gateway for inter-region connectivity. Would use multiple NAT Gateways and Internet Gateways for outbound connectivity. Would implement AWS Global Accelerator to provide static IP addresses for applications and route traffic to the nearest healthy endpoint. 