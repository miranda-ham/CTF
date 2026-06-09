# CTF - Deep Dive into Fraud

## Metadata

| Field | Value |  
|-------|-------|  
| **Author** | Miranda Hampton |  
| **Challenge Name** | DeepDive into Fraud |  
| **Difficulty Target** | Medium |  
| **Estimated Solve Time** | 3-5 hours |  
| **Narrative / Theme** | A former employee asks for your help proving that a dive shop is falsifying safety records.      |  
| **Design Approach** | Vuln-centric + Narative-driven| 

---
# Narrative
Your friend, a former employee of BlueWater Dive Shop reaches out to you. They worked there for two seasons and left after one too many dives that shouldn't have happened. Customers taken deeper than their certification allows. Safety stops skipped because the group was running low on air. One diver separated from the group entirely and surfaced alone with an empty tank.
None of it made it into the official records.
BlueWater operates in a Mediterranean coastal town where dive shops are rated on their safety record. A higher score means more business. Your friend has accused the owner of tampering with data since some how BlueWater still has the highest score in town. On paper, every dive BlueWater ever ran was perfect.
The owner built the website himself. He's proud of that. He advertises the safety rating right on the front page.
Your friend wants proof. She needs actual data showing what was logged versus what was submitted. Something that could be taken to the dive council.
You have the IP address. The rest is up to you.

**Goal:** Retrieve user and root flags

## Setup

**Requirements:** VirtualBox, Vagrant

```bash
vagrant up
```

The machine will be available at `192.168.56.101` once provisioning completes.

**Note:** The host may not respond to ping. Use `nmap -Pn` for scanning.
