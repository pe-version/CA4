# CA4 Repository Cleanup Plan

## Files to DELETE (CA3-specific, not needed for CA4)

### Documentation Files (CA3-specific)
- [ ] `CA3-ROADMAP.md` - CA3 planning, not relevant
- [ ] `CA3-DEPLOYMENT-GUIDE.md` - CA3 deployment steps
- [ ] `CA3-IMPLEMENTATION-SUMMARY.md` - CA3 summary
- [ ] `CA3-QUICK-START.md` - CA3 quick start
- [ ] `START-HERE.md` - CA3 start guide
- [ ] `DAY-1-SUMMARY.md` - CA3 day 1 notes
- [ ] `AWS-DEPLOYMENT.md` - CA3 AWS deployment
- [ ] `AWS-DEPLOYMENT-QUICKSTART.md` - CA3 quickstart
- [ ] `AWS-SIZING-ANALYSIS.md` - CA3 sizing (will redo for CA4)
- [ ] `TROUBLESHOOTING.md` - CA3 troubleshooting (Docker Swarm issues)
- [ ] `OBSERVABILITY-COMPLETE.md` - CA3 observability notes
- [ ] `OBSERVABILITY-QUICK-REF.md` - CA3 observability reference
- [ ] `ORACLE-MIGRATION-COMPLETE.txt` - CA3 Oracle attempt

### Hidden/Working Files
- [ ] `.grade-improvement-plan.md` - CA3 grading notes
- [ ] `.hpa-full-scaling-optionb.md` - CA3 HPA notes
- [ ] `.quick-wins-no-video.md` - CA3 notes

### Docker Swarm Files (Not used in CA4)
- [ ] `docker-compose.yml` - CA2 Docker Swarm
- [ ] `docker-compose.aws.yml` - CA2 Docker Swarm on AWS
- [ ] `docker-compose.aws.old.yml` - Old backup
- [ ] `docker-compose.yml.backup` - Backup
- [ ] `ansible/` - Swarm deployment automation (not needed)
- [ ] `deploy.sh` - Swarm deployment
- [ ] `deploy-aws.sh` - Swarm AWS deployment
- [ ] `deploy-with-workaround.sh` - Swarm workaround
- [ ] `destroy.sh` - Swarm destroy
- [ ] `destroy-aws.sh` - Swarm destroy AWS
- [ ] `Makefile` - Swarm targets (will create new CA4 Makefile)

### Debug/Temp Files
- [ ] `debug_logs/` - CA3 debugging
- [ ] `configs/` - Old configs
- [ ] `security-groups.json` - Old security group export

### Oracle Cloud Attempt (CA3)
- [ ] `terraform-oci/` - Oracle Cloud attempt (CA3)
- [ ] `docs/oracle-cloud-setup.md`
- [ ] `docs/DAY-1-ORACLE-QUICKSTART.md`
- [ ] `docs/CHICAGO-REGION-NOTES.md`
- [ ] `scripts/oracle-deploy.sh`
- [ ] `scripts/verify-oci-setup.sh`

### Scripts (CA3-specific)
- [ ] `scripts/init-swarm.sh` - Docker Swarm
- [ ] `scripts/validate-stack.sh` - Docker Swarm
- [ ] `scripts/scaling-test.sh` - CA3 scaling (will redo for CA4)
- [ ] `scripts/smoke-test.sh` - CA3 smoke test (will redo for CA4)

### Evidence (CA3 Screenshots/Videos)
- [ ] `evidence/` - Entire CA3 evidence directory (keep for reference, but won't commit to CA4)
- [ ] `resilience-test-script.sh` - CA3 resilience test (will redo for CA4)

### Other
- [ ] `networks/` - Docker Swarm network diagrams
- [ ] `.claude/` - Claude Code local data (won't be committed)
- [ ] `README.md` - CA3 README (will create new CA4 README)

---

## Files to KEEP (Needed for CA4)

### Core Application Code
- ✅ `producer/` - Python producer app (reuse in CA4)
- ✅ `processor/` - Python processor app (reuse in CA4)
- ✅ `mongodb/` - MongoDB init scripts (reuse in CA4)

### Kubernetes Manifests (Base for CA4)
- ✅ `k8s/base/` - CA3 K8s manifests (adapt for CA4 AWS cluster)
- ✅ `k8s/observability/` - Prometheus/Grafana/Loki configs (reuse)
- ✅ `k8s/security/` - NetworkPolicies (adapt for CA4)

### Terraform (AWS - will adapt)
- ✅ `terraform/` - AWS infrastructure (will modify for CA4)

### Scripts (Will adapt)
- ✅ `scripts/build-images.sh` - Still need to build images
- ✅ `scripts/setup-k3s-cluster.sh` - Will adapt for multi-cluster
- ✅ `scripts/deploy-aws-k3s.sh` - Will adapt
- ✅ `scripts/verify-observability.sh` - Still useful
- ✅ `scripts/load-test.sh` - May reuse
- ✅ `scripts/resilience-test.sh` - Will adapt for CA4

### Planning Documents
- ✅ `CA4-DESIGN-DECISIONS.md` - Our CA4 planning doc
- ✅ `LICENSE` - Keep license

### Git Files
- ✅ `.gitignore` - Will update for CA4
- ⚠️ `.git/` - Will reinitialize (disconnect from CA3 repo)

---

## New Files to CREATE for CA4

- [ ] `README.md` - New CA4 README
- [ ] `CA4-ARCHITECTURE.md` - Multi-cloud architecture diagram
- [ ] `CA4-DEPLOYMENT-GUIDE.md` - Step-by-step deployment
- [ ] `terraform/cloud2/` - Second cloud Terraform (GCP or DO)
- [ ] `k8s/cloud2/` - Cloud2 K8s manifests
- [ ] `k8s/wireguard/` - WireGuard VPN configs
- [ ] `scripts/setup-wireguard.sh` - VPN setup automation
- [ ] `scripts/deploy-multi-cloud.sh` - Full CA4 deployment
- [ ] `scripts/ca4-resilience-test.sh` - VPN failure scenario
- [ ] `Makefile` - New CA4 targets

---

## Summary

**DELETE**: 40+ files/directories (CA3-specific)
**KEEP**: 10 directories/files (reusable)
**CREATE**: 10+ new CA4 files
