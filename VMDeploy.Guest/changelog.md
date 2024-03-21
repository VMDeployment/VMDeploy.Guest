# Changelog

## 1.0.10 (2024-03-21)

+ New: Action: CertDeploy - deploy a certificate (such as a root CA cert) to a selected certificate store
+ New: Action: ScriptBlock - execute a custom scriptblock
+ Upd: Invoke-VMGuestConfiguration - fixed processing order to ensure items are not flagged as success before dependencies are successful.
+ Upd: Action: Certificate - added CertRoles & RDP configuration
+ Upd: Action: ComputerName - disabled interactive user prompts
+ Upd: Action: firewall - updated/restructured filtering
+ Upd: Action: File_copy - added file validation via hash
+ Upd: Action: ipsec - performs gpupdate and restarts IKEEXT service on execute
+ Upd: Action: ipsec_cryptoset - performs gpupdate and restarts IKEEXT service on execute
+ Fix: Action: policy_clear - fixed broken validation for local machine policy (will get filled automatically)

## 1.0.0 (2021-04-07)

+ Initial Upload
