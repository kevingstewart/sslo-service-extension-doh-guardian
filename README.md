# SSL Orchestrator DoH Guardian
DoH Guardian is an F5 SSL Orchestrator **service extension** function for monitoring/managing DNS-over-HTTPS traffic flows and detecting potentially malicious DoH exfiltration. This SSL Orchestrator service extension is invoked at a detected (and decrypted) DNS-over-HTTPS request and has several options for logging, management, and anomaly detection.

Requires:
* BIG-IP SSL Orchestrator 17.1.x (SSLO 11.1+)
* Optional URLDB subscription -and/or- custom URL category (of categorization is required)

### To implement via installer:
1. Run the following from the BIG-IP shell to get the installer:
  ```bash
  TBD
  ```

2. Export the BIG-IP user:pass:
  ```bash
  export BIGUSER='admin:password'
  ```

3. Run the script to create all of the DoH Guardian objects
  ```bash
  ./doh-guardian-installer.sh
  ```

4. Add the resulting "ssloS_F5_DoHGuard" inspection service in SSLO to a decrypted traffic service chain. The installer creates a new inspection service named "ssloS_F5_DoHGuard". Add this inspection service to any service chain that can receive decrypted HTTP traffic. Service extension services will only trigger on decrypted HTTP, so can be inserted into service chains that may also see TLS intercepts traffic. SSL Orchestrator will simply bypass this service for anything that is not decrypted HTTP.

------
### To customize functionality
The **doh-guardian-rule** iRule has a number of editable settings:
* **DOH_LOG_LOCAL**: Enables or disables local (/var/log/ltm) logging of DoH requests and events.
* **DOH_LOG_HSL**: Defines a high-speed logging pool to send logs to external SIEM.
* **DOH_CATEGORY_TYPE**: Defines the category database to use, subscription, custom, or both.
* **DOH_BLOCKING_BASIC**: Enables or disables basic DoH blocking. This option is mutually exclusive and simply blocks all detected DoH requests.
* **DOH_BLACKHOLE_BY_CATEGORY**: Defines the list of categories that will trigger a DoH blackhole action.
* **DOH_BLACKHOLE_BY_CATEGORY_ACTION**: Allows for the default blackhole action, or a dryrun (logging) action.
* **DOH_SINKHOLE_BY_CATEGORY**: Defines the list of categories that will trigger a DoH sinkhole action.
* **DOH_SINKHOLE_BY_CATEGORY_ACTION**: Allows for the default sinkhole action, or a dryrun (logging) action.
* **DOH_SINKHOLE_IP4**: Defines the IP4v address that will be used for the sinkhole action on A requests.
* **DOH_SINKHOLE_IP6**: Defines the IP4v address that will be used for the sinkhole action on AAAA requests.
* **DOH_ANOMALY_DETECTION**: Enables or disables anomaly detection.
* **DOH_ANOMALY_CONDITION_LONG_DOMAIN**: Defines the long subdomain anomaly detection, by virtue of a max character length setting (default: 52 characters).
* **DOH_ANOMALY_CONDITION_LONG_DOMAIN_ACTION**: Defines the action to be taken on the long subdomain anomaly: dryrun, drop, blackhole, or sinkhole.
* **DOH_ANOMALY_CONDITION_UNCOMMON_TYPE**: Defines the uncommon query type anomaly detection, by virtue of a list of uncommon types.
* **DOH_ANOMALY_CONDITION_UNCOMMON_TYPE_ACTION**: Defines the action to be take on the uncommon type anomaly: dryrun, drop, blackhole, or sinkhole.

------
### DoH Blackhole Explained

Under most browser-based conditions, a failed DoH call will simply cause the browser to revert to plain DNS. One of the best ways to block a DoH/DNS request is to provide a good but fake response instead, a technique called "blackholing". A DNS blackhole is diverting to *nothing*.

------
### DoH Sinkhole Explained

In a sinkhole response, the resolver sends back an IP address that points to a local blocking server. A DNS sinkhole is diverting to *something*. The sinkhole destination is then able to respond to the client's request, so instead of just dying, the user might get a "we're watching you..." page instead. To do a sinkhole without SSL Orchestrator, a client would initiate a TLS handshake to this server (believing it's the real site), and would get a certificate error because the server certificate on that blocking server doesn't match the Internet hostname requested by the client. The SSL Orchestrator solution requires two configurations:

* A sinkhole internal virtual server that simply hosts the "blank" certificate that SSL Orchestrator will use to mint a trusted server certificate to the client.
* An SSL Orchestrator outbound L3 topology modified to listen on the sinkhole destination IP, and inject the blocking response content.

ADDITIONAL CONFIG INFO TBD

------
### DoH Anomaly Detection Explained

There are a number of ways to "detect" anomalous DNS-over-HTTPS traffic...

[Real time detection of malicious DoH traffic using statistical analysis](https://www.sciencedirect.com/science/article/pii/S1389128623003559)

------
### DoH Exfiltration Explained

DoH EXFILTRATION INFO TBD












