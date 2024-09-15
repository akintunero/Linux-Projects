# Step 7: Learn System Monitoring Tools

## Beginner

1. **Create a script that uses `top` to report on resource-intensive processes**
   - Write a script that:
     - Runs `top` or `ps` to gather information on the top 5 CPU and memory-consuming processes
     - Logs this information into a file with timestamps

2. **Use `netstat` to monitor network connections and log findings**
   - Write a script that:
     - Uses `netstat` to list active network connections
     - Logs the connection details (IP addresses, ports, and protocols) into a file
     - Runs every 5 minutes using `cron`

3. **Set up basic system monitoring using Nagios**
   - Install Nagios on your server
   - Add basic monitoring for system metrics like CPU, memory, and disk usage
   - Set up email alerts for critical thresholds

## Intermediate

1. **Implement a custom dashboard using Grafana and Prometheus**
   - Install and configure Prometheus to collect system metrics
   - Install Grafana and create a dashboard to visualize Prometheus data
   - Set up custom alerts for specific metrics (e.g., high CPU usage)

2. **Create alerts based on system metrics using Zabbix**
   - Install Zabbix and configure the server and agents
   - Monitor system resources like CPU, memory, and disk usage
   - Create custom alerts for conditions such as disk space running low

3. **Develop a script that uses `sar` to generate daily performance reports**
   - Write a script that:
     - Uses `sar` (System Activity Reporter) to collect performance data
     - Generates a report summarizing CPU, memory, and disk activity
     - Emails the report to the system administrator

## Advanced

1. **Implement distributed tracing in a microservices environment**
   - Install and configure a tracing system like Jaeger or OpenTelemetry
   - Set up tracing across microservices to monitor request flow and performance bottlenecks
   - Analyze traces to identify and optimize inefficient services

2. **Set up an ELK stack (Elasticsearch, Logstash, Kibana) for log analysis**
   - Install and configure Elasticsearch, Logstash, and Kibana
   - Set up Logstash to collect and parse system logs
   - Use Kibana to visualize log data and create alerts for specific patterns (e.g., failed login attempts)

3. **Develop a predictive analysis tool for system resource usage**
   - Write a script that:
     - Collects historical system resource usage data
     - Uses statistical methods or machine learning to predict future resource usage
     - Sends alerts when resource usage is expected to exceed a predefined threshold
