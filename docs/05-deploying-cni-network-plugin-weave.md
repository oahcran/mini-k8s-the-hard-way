# Deploying CNI Networking Plugin - `Weave Net`

|Network Policy Support |Yes |
|----|----|

**References:**

* [Integrating Kubernetes via the Addon
](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/)
* [Troubleshooting Weave Net](https://www.weave.works/docs/net/latest/troubleshooting/)
* [Weave Net FAQ](https://www.weave.works/docs/net/latest/faq/)

## weave

Before deployment, make sure the `IPALLOC_RANGE` (the range of IP addresses used by Weave Net and the subnet they are placed in are matching `--cluster-cidr` option on kube-proxy. It is CIDR format and default `10.32.0.0/12`. Since this lab is using `10.244.0.0/16` hence require to update deployment yml file.

```
        spec:
          containers:
            - name: weave
              command:
                - /home/weave/launch.sh
              env:
                - name: IPALLOC_RANGE
                  value: 10.244.0.0/16
```

Deployment

`$ kubectl apply -f deployments/weave/net.yml`

Weave Net automatically install `weave-plugin` into `/opt/cni/bin` and put configuration under `/etc/cni/net.d`

```
# ls -Alhr --time-style=+"" /opt/cni/bin/
total 76M
-rwxr-xr-x 1 root root  28M  weave-plugin-2.5.2
lrwxrwxrwx 1 root root   18  weave-net -> weave-plugin-2.5.2
lrwxrwxrwx 1 root root   18  weave-ipam -> weave-plugin-2.5.2
-rwxr-xr-x 1 root root 3.5M  vlan
-rwxr-xr-x 1 root root 2.8M  tuning
-rwxr-xr-x 1 root root 2.6M  sample
-rwxr-xr-x 1 root root 3.9M  ptp
-rwxr-xr-x 1 root root 3.4M  portmap
-rwxr-xr-x 1 root root 3.5M  macvlan
-rwxr-xr-x 1 root root 3.0M  loopback
-rwxr-xr-x 1 root root 3.5M  ipvlan
-rwxr-xr-x 1 root root 2.9M  host-local
-rwxr-xr-x 1 root root 3.0M  host-device
-rwxr-xr-x 1 root root 2.8M  flannel
-rwxr-xr-x 1 root root 9.8M  dhcp
-rwxr-xr-x 1 root root 3.9M  bridge
```

```
# cat /etc/cni/net.d/10-weave.conflist
{
    "cniVersion": "0.3.0",
    "name": "weave",
    "plugins": [
        {
            "name": "weave",
            "type": "weave-net",
            "hairpinMode": true
        },
        {
            "type": "portmap",
            "capabilities": {"portMappings": true},
            "snat": true
        }
    ]
}
```

```
$ kubectl exec -n kube-system weave-net-pzjx8 -c weave -- /home/weave/weave --local status

        Version: 2.5.2 (up to date; next check at 2019/09/12 19:40:18)

        Service: router
       Protocol: weave 1..2
           Name: 46:55:cf:e0:35:01(mini-k8s-worker-1)
     Encryption: disabled
  PeerDiscovery: enabled
        Targets: 1
    Connections: 1 (1 failed)
          Peers: 1
 TrustedSubnets: none

        Service: ipam
         Status: ready
          Range: 10.244.0.0/16
  DefaultSubnet: 10.244.0.0/16
```