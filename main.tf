provider "azurerm" {
  tenant_id       = "2b6e2a8e-d207-4d68-b800-dfba94a7a609"
  features {}

}

#get the image that was create by the packer script
data "azurerm_image" "web" {
  name                = "udacity-server-image"
  resource_group_name = var.packer_resource_group

}

# Create a resources group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-terraform-rg"
  location = var.location
  tags = {
    environement = var.environement
  }
}

# Create a availabity set for virtual machines
resource "azurerm_availability_set" "main" {
  name                        = "${var.prefix}-aset"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  platform_fault_domain_count = 2

  tags = {
    environement = var.environement
  }
}

# Create a network security group
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    environement = var.environement
  }

  security_rule {
    name                       = "AllowVnetInBound"
    description                = "Allow access to other VMs on the subnet"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "DenyInternetInBound"
    description                = "Deny all inbound traffic outside of the vnet from the Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }

}

# Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-publicIp"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = {
    environement = var.environement
  }
}

# Create a load balancer
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = {
    environement = var.environement
  }
}

# Load balancer backend adress pool
resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-bap"
  }

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    environement = var.environement
  }
}

# Subnet in the Virtual network
resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

}


# Interface network
resource "azurerm_network_interface" "main" {
  count = var.vm_count
  name                = "${var.prefix}-nic-${var.server_names[count.index]}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = azurerm_subnet.internal.name
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    environement = var.environement
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count = var.vm_count
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = azurerm_subnet.internal.name #"internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id

}

resource "azurerm_linux_virtual_machine" "main" {
  count = var.vm_count
  name                            = "${var.prefix}-vm-${var.server_names[count.index]}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id
  ]
  availability_set_id = azurerm_availability_set.main.id
  source_image_id     = data.azurerm_image.web.id

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    environement = var.environement,
    name        = var.server_names[count.index]
  }
}

# create managed disk for virtual machine
resource "azurerm_managed_disk" "main" {
  count                           = var.vm_count
  #name                            = "data-disk-"
  name                 = "${var.prefix}-data-disk-${count.index}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    environement = var.environement
  }
}
