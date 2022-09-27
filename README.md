# K8S Proof Of Concept

Proof of concept that prove a Multi-Tenancy K8S Cluster deployed on a
single cluster.  There are three namespaces (Dev, Staging,
Production), where a NodeJS+Vue3 webapp will be deployed according to
the branch.  Ideally each team has access to a single tenant, and
they're separated using IAM/RBAC and roles.

References: 
	- https://cloud.google.com/kubernetes-engine/docs/concepts/multitenancy-overview

When a developer have a feature branch ready to be merged, he just
open a PR against the dev branch; and after the commit pass the unit
tests, the CI will create a Docker container and push it to GAR (Google
Artifacts Registry), ready to be pulled from the K8S deployment.

Dev and Stage tenants are special and aren't accessible to
unauthorized people.  In this PoC i'm deploying the Dev and Stage
branch in those tenants and setup a basic http auth, which is not
enough in a real-world scenario, where you should use something like
[IAP](https://cloud.google.com/iap/docs/enabling-kubernetes-howto) or
even better, a private GKE Cluster specifically used for dev and stage
testing.

Using that approach each team can have access to a specific version of
the application, and in the case of the QA team, they can easily tests
new features just merged, without having them deployed on the stage or
production tenants.

`User Story-X`

Development ---> Code Review ---> Functionl Review ---> Merging on Dev
branch (or choose a better name for it) ---> Create Container and push
to GAR ---> Pull Container and deploy it to dev tenants ---> Tests on
specific tenant with authentication

## How it Works

In this repository there are both terraform code for create and manage
the GKE cluster, and the k8s code for deploy the sample webapp.

### Terraform

That's basically leverage the "gke" module made by google for easily
create a Private/Public GKE cluster, without bother to much about VPC
and other amenities.  So there's not too much to say here, just take a
glance to the code, and use basic terraform command for deploy.

	terraform apply -auto-approve

### K8S

In this case i'm using a `kustomize` workflow, defining a base
template and just apply the overlays to the tenants.

- base
  - Deployments for both backend and frontend
  - Services for backend and frontend
  - Namespace definition
  - Ingress for production
  
- overlays
  - dev
	- Deployments and ingress definition for the Dev tenant
  - stage
	- Deployments and ingress definition for the Stage tenant
  - production
	- Deployments and ingress definition for the Production tenant
  
### Nix

This is a flake project, and i'm using it for have all the tools
needed for deploying on k8s and terraform.

	nix develop

This will drop you in a sort-of python virtualenv but with:
 - terraform CLI
 - google SDK
 - helm
 - kustomize CLI
 - google auth plugin

### Webapp

Here there are the repository where i create a basic Hello world
application, using NodeJS as a backend (which just increment a counter
and expose it as an API), and a VueJS application that consumes the
NodeJS backend and display the counter.

For both backend and frontend i'm using Github Action that build the
container and push it to GAR.

There are three different pipeline, tightened to a specific branch, and
each of them build a different container for the specific tenant.  So
a merge on the `stage` branch will trigger a pipeline that build a
docker container and push it on GAR, and then this container will be
pulled by the `stage` tenant's deployment.

- Backend:
https://github.com/heph2/webapp-sample-backend

- Frontend:
https://github.com/heph2/webapp-sample-frontend

### Test

Have a look here for the production app:

http://webapp.mrkeebs.eu/

And here for the stage and dev app, which requires authentication

http://webapp-stage.mrkeebs.eu/
http://webapp-dev.mrkeebs.eu/

### Other Approaches

As i said above, there are better approaches, and probably more
"idiomatic" than this. But IMHO, for a basic webapp, having a single
cluster in multi-tenants like this will be more cost-effective and
easily to manage than have more Clusters.

And you can improve the authentication using IAP, or using some kind
of oath/SSO like Github.
