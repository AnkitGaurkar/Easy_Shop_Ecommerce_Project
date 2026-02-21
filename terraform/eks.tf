module "eks" {
  #Import the module template
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"# we are remove this version then automatic taken latest version
  #Cluster info (For Control plane)
  cluster_name    = local.name
 # cluster_version = "1.29" # if we are remove this version then automatic taken latest version  

  # Optional
  cluster_endpoint_public_access = true # this is for show our cluster to end user.

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id = module.vpc.vpc_id

  subnet_ids = module.vpc.private_subnets #interpolation   private for control plane secure

  cluster_addons = { # addons means we need latest plugins, network packages that can be fetch
    coredns = {

      most_recent = true
    }

    kube-proxy = {

      most_recent = true

    }
    vpc-cni = { #cni cluster nw interface
      most_recent = true
    }
  }
  #Control plane N/W
  control_plane_subnet_ids = module.vpc.intra_subnets # intranet for to manage internal server as control plane manage by AWS

  #Managing the nodes in the cluster
  eks_managed_node_group_defaults= {
    instance_types                         = ["t3.small"]
    attached_cluster_primary_security_group = true # this is security grp for allow on server req resp like port 8080, 22 etc
  }
    eks_managed_node_groups = {
      tws-demo-ng = {
        instance_types= ["t3.small"]
        min_size      = 2
        max_size      = 3
        desired_size  = 2
        capacity_type  = "SPOT"

      disk_size = 35 
      use_custom_launch_template = false  # Important to apply disk size!
       tags = {
        Name = "tws-demo-ng"
        Environment = "dev"
        ExtraTag = "e-commerce-app"
      }
    }
  }
 
  tags = local.tags


}

data "aws_instances" "eks_nodes" {
  instance_tags = {
    "eks:cluster-name" = module.eks.cluster_name
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [module.eks]
}
