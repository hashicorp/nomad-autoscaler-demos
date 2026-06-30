# Minimal Autoscaler Example

This directory contains a minimal deployment of Nomad Autoscaler without any
third party APM and using the [Nomad Task API][1] and Workload Identity with
[workload-associated ACL policies][2]. This demonstrates:

* Creating a workload-associated ACL policy for the autoscaler
* Deploying the autoscaler using only the Nomad target and strategy plugins.
* Deploying a workload that exercises these plugins.

Start with a running Nomad agent with ACLs enabled. In another terminal window
with your `NOMAD_TOKEN` environment variable set, create the ACL policy.

```shell-session
$ nomad acl policy apply -namespace default -job autoscaler autoscaler ./acl.hcl
```

Deploy the workload with a scaling policy. Once deployed, this job will have a
single allocation but it has a scaling policy that should scale it to 2
allocations.

```shell-session
$ nomad job run ./httpd.nomad.hcl
```

Deploy the autoscaler.

```shell-session
$ nomad job run ./autoscaler.nomad.hcl
```

Once the autoscaler is finished deploying, the `httpd` job should be scaled to 2
allocations shortly afterwards.

[1]: https://developer.hashicorp.com/nomad/api-docs/task-api
[2]: https://developer.hashicorp.com/nomad/docs/concepts/workload-identity#workload-associated-acl-policies
