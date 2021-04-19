# Configure the Microsoft Azure Provider
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "MY_RG"
    location = "eastus"

    tags = {
        environment = "MYLVl"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "MY_Vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "MYLVl"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "MY_Subnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    count = 3
    name                         = "MY_PubIP-${count.index}"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "MYLVl"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "MY_SG"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "MYLVl"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    count = 3
    name                      = "MY_NIC-${count.index}"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.myterraformgroup.name

    ip_configuration {
        name                          = "MY_NICConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.*.id[count.index]
    }

    tags = {
        environment = "MYLVl"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    count = 3
    network_interface_id      = azurerm_network_interface.myterraformnic.*.id[count.index]
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}


# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm" {
    count = 3
    name                  = "MYVM-${count.index}"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [
        azurerm_network_interface.myterraformnic.*.id[count.index],
        ]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk-${count.index}"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "MYVM" #Do not use any special characters IMPORTANT!!!!
    admin_username = "azureuser"
    admin_password = "U2t8s=mlS~mP"
    disable_password_authentication = false

    tags = {
        environment = "MYLVl"
    }
}