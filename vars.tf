variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "udacity-project"
}

variable "packer_resource_group" {
  description = "Name of the resource group where the packer image is"
  default     =  "udacity-project-rg"
  }


variable "environement" {
  description = "The environment should be used for all resources in this example"
  default = "Deploy a web server in azure"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "francecentral"
  }

variable "username"{
  default = "adminuser"
}

variable "password"{
  default= "P@ssw0rd1234!"
}

variable "server_names"{
  type = list
  default = ["production", "development"]
}

variable "vm_count"{
  default = "2"
}
