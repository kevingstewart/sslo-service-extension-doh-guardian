# SSL Orchestrator DoH Guardian
DoH Guardian is an F5 SSL Orchestrator **service extension** function for monitoring/managing DNS-over-HTTPS traffic flows and detecting potentially malicious DoH exfiltration. This SSL Orchestrator service extension is invoked at a detected (and decrypted) DNS-over-HTTPS request and has several options for logging, management, and anomaly detection.

Requires:
* BIG-IP SSL Orchestrator 17.1.x (SSLO 11.1+)
* Optional URLDB subscription -and/or- custom URL category (if categorization is required)

### To implement via installer:
1. Run the following from the BIG-IP shell to get the installer:
  ```bash
  curl -sk https://raw.githubusercontent.com/kevingstewart/sslo-service-extension-doh-guardian/refs/heads/main/doh-guardian-installer.sh -o doh-guardian-installer.sh
  chmod +x doh-guardian-installer.sh
  ```

2. Export the BIG-IP user:pass:
  ```bash
  export BIGUSER='admin:password'
  ```

3. Run the script to create all of the DoH Guardian objects
  ```bash
  ./doh-guardian-installer.sh
  ```

4. The installer creates a new inspection service named "ssloS_F5_DoH". Add this inspection service to any service chain that can receive decrypted HTTP traffic. Service extension services will only trigger on decrypted HTTP, so can be inserted into service chains that may also see TLS intercepts traffic. SSL Orchestrator will simply bypass this service for anything that is not decrypted HTTP.

------
### To customize functionality
The **doh-guardian-rule** iRule has a number of editable settings:
* **DOH_LOG_LOCAL**: <br />Enables or disables local (/var/log/ltm) logging of DoH requests and events. (1=on, 0=off)
* **DOH_LOG_HSL**: <br />Defines a high-speed logging pool to send logs to external SIEM. (pool name)
* **DOH_CATEGORY_TYPE**: <br />Defines the category database to use, subscription, custom, or both. (string selection)
* **DOH_BLOCKING_BASIC**: <br />Enables or disables basic DoH blocking. This option is mutually exclusive and simply blocks all detected DoH requests. (1=on, 0=off)
* **DOH_BLACKHOLE_BY_CATEGORY**: <br />Defines the list of categories that will trigger a DoH blackhole action. (category list)
* **DOH_BLACKHOLE_BY_CATEGORY_ACTION**: <br />Allows for the default blackhole action, or a dryrun (logging) action. (string selection)
* **DOH_SINKHOLE_BY_CATEGORY**: <br />Defines the list of categories that will trigger a DoH sinkhole action. (category list)
* **DOH_SINKHOLE_BY_CATEGORY_ACTION**: <br />Allows for the default sinkhole action, or a dryrun (logging) action. (string selection)
* **DOH_SINKHOLE_IP4**: <br />Defines the IP4v address that will be used for the sinkhole action on A requests. (ipv4 address)
* **DOH_SINKHOLE_IP6**: <br />Defines the IP4v address that will be used for the sinkhole action on AAAA requests. (ipv6 address)
* **DOH_ANOMALY_DETECTION**: <br />Enables or disables anomaly detection. (1=on, 0=off)
* **DOH_ANOMALY_CONDITION_LONG_DOMAIN**: <br />Defines the long subdomain anomaly detection, by virtue of a max character length setting (integer, default=52 characters). 
* **DOH_ANOMALY_CONDITION_LONG_DOMAIN_ACTION**: <br />Defines the action to be taken on the long subdomain anomaly: dryrun, drop, blackhole, or sinkhole. (string selection)
* **DOH_ANOMALY_CONDITION_UNCOMMON_TYPE**: <br />Defines the uncommon query type anomaly detection, by virtue of a list of uncommon types. (DNS record type list)
* **DOH_ANOMALY_CONDITION_UNCOMMON_TYPE_ACTION**: <br />Defines the action to be take on the uncommon type anomaly: dryrun, drop, blackhole, or sinkhole. (string selection)

------
### DoH Inspection Explained

You may be asking, why do I need to inspect DNS-over-HTTPS traffic? DNS has been around longer than the web, and to be honest, you don't hear a lot about it with all of the other more exciting (and terrifying) security issues flying around. As it happens, though, DNS as a protocol is extremely flexible, making it very good at things like side-channel attacks and data exfiltration. In a scenario where an attacker can control a client on an enterprise network, and a DNS server out on the Internet, it becomes rather trivial for that attacker to move arbitrary data in the form of small chunks of encoded TXT records, or even dynamic subdomain names. However, as DNS itself is not encrypted, it's typically very easy to spot these anomalies. And most enterprises will implement local DNS forwarding, so data exfiltration over raw DNS is rarely successful. However...DNS-over-HTTPS (DoH) is essentially DNS wrapped in encrypted HTTPS for added security. The original intention for this is to provide privacy, but DoH has been found to possess some interesting drawbacks:

* The most popular browsers support DoH, and by default point their queries at Internet-based services like Cloudflare and Google. Where an enterprise once had full visibility of their DNS traffic, that is now absent unless you either set up local DoH services and modify all local browser clients to use this, or just block access to Cloudflare and Google DNS altogether. It is worth noting, though, that these are only two of thousands of DoH providers available.
* DoH rides on regular HTTPS, port 443, and is otherwise indistinguishable from regular HTTPS web traffic. It's not generally possible to simply "block DoH" unless you do so, either by known DoH URLs, or by decrypting it and inspecting the payloads.

Unquestionably, DNS-over-HTTPS is an important privacy enhancement to DNS; but in doing so now obfuscates serious data leakage exploits. DoH inspection is the explicit decryption of outbound HTTPS traffic and subsequent detection of the DoH requests and responses. This function allows an organization to regain visibility and control of DNS requests heading out to Internet DoH providers. From simple logging or blocking, to DNS blackhole and sinkhole actions, and some exfiltration anomaly detections, DoH inspection can be a vital part of the overall security of enterprise traffic flows.

------
### DoH Anomaly Detection Explained

Before getting into the weeds of DoH anomaly detection, it's important to illustrate a simple example of an actual exploit. There are many different tools for doing DoH exfiltration, but they all run on the same basic principles: encoding chunks of data in multiple DNS requests.

There are a number of ways to "detect" anomalous DNS-over-HTTPS traffic...

[Real time detection of malicious DoH traffic using statistical analysis](https://www.sciencedirect.com/science/article/pii/S1389128623003559)

------
### DoH Blackhole Action Explained

By [Definition]([definition](https://www.ijitee.org/wp-content/uploads/papers/v8i7c2/G10040587C219.pdf), a DNS blackhole essentially diverts a DNS client to *nothing*. A DNS blackhole will either drop the request entirely, or respond with an NXDOMAIN. However, a browser that fails in getting a DoH response will almost always retry with regular DNS, making this a less effective option. To properly blackhole a DoH request, the client must receive an actual response, but to something that does not exist. In this implementation, a DoH blackhole responds to the client with either a 199.199.199.199 IPv4 address for an A request, or 0:0:0:0:0:ffff:c7c7:c7c7 IPv6 address for a AAAA request.

------
### DoH Sinkhole Action Explained

In a sinkhole response, the resolver sends back an IP address that points to a local blocking server. In contrast to a blackhole, a DNS sinkhole is diverting to *something*. The sinkhole destination is then able to respond to the client's request, so instead of just dying, the user might get a blocking page instead. In a DoH/DNS sinkhole without SSL Orchestrator, a client would initiate a TLS handshake to this server (believing it's the real site), and would get a certificate error because the server certificate on that blocking server doesn't match the Internet hostname requested by the client. The SSL Orchestrator solution requires two configurations:

* A sinkhole internal virtual server that simply hosts the "blank" certificate that SSL Orchestrator will use to mint a trusted server certificate to the client.
* An SSL Orchestrator outbound L3 topology modified to listen on the sinkhole destination IP, and inject the blocking response content.
















