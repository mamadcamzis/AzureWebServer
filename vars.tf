variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "udacity-project"
}

variable "environment"{
  description = "The environment should be used for all resources in this example"
  default = "Deploy a web server in azure"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "francecentral"
  }

variable "username"{
  default = "username"
}

variable "password"{
  default= "password"
}

variable "server_names"{
  type = list
  default = ["prod", "dev"]
}

variable "packerImageId"{
  default = "/subscriptions/48a186d8-489b-4363-84ba-e5bf2cd35635/resourceGroups/udacity-project-rg/providers/Microsoft.Compute/images/PackerImage"
}

variable "vm_count"{
  default = "2"
}
