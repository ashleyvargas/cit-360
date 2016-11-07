#variable "public_key_path" {
#Example: ~/.ssh/terraform.pub
#}

#variable "key_name" {
#  description = "Desired name of AWS key pair"
#}



# Add your VPC ID to default below
variable "vpc_id" {
  type = "string"
  description = "VPC ID for usage throughout the build process"
  default = "vpc-b2f407d5"
}

provider "aws" {
  region = "us-west-2"
}


# PUBLIC

resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "default_ig"
  }
}


resource "aws_route_table" "public_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public_routing_table"
  }
}


resource "aws_subnet" "public_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.0.0/24"
    availability_zone = "us-west-2a"
    map_public_ip_on_launch = true

    tags {
        Name = "public_a"
    }
}

resource "aws_subnet" "public_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.1.0/24"
    availability_zone = "us-west-2b"
    map_public_ip_on_launch = true

    tags {
        Name = "public_b"
    }
}

resource "aws_subnet" "public_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.2.0/24"
    availability_zone = "us-west-2c"
    map_public_ip_on_launch = true

    tags {
        Name = "public_c"
    }
}


# PRIVATE

resource "aws_subnet" "private_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.100.0/22"
    availability_zone = "us-west-2a"

    tags {
        Name = "private_a"
    }
}

resource "aws_subnet" "private_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.150.0/22"
    availability_zone = "us-west-2b"

    tags {
        Name = "private_b"
    }
}

resource "aws_subnet" "private_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.200.0/22"
    availability_zone = "us-west-2c"

    tags {
        Name = "private_c"
    }
}

resource "aws_eip" "elastic_ip" {
  vpc      = true
  depends_on = ["aws_internet_gateway.gw"]
}


resource "aws_nat_gateway" "gw" {
    allocation_id = "${aws_eip.elastic_ip.id}"
    subnet_id = "${aws_subnet.private_subnet_a.id}"
    depends_on = ["aws_internet_gateway.gw"]
}


resource "aws_route_table" "private_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {
	cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_nat_gateway.gw.id}"
	}
    tags {
    Name = "private_routing_table"
  }
}




# Route Table Associations

resource "aws_route_table_association" "public_subnet_a_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_b_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_b.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

resource "aws_route_table_association" "public_subnet_c_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_c.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}



resource "aws_route_table_association" "private_subnet_a_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_a.id}"
    route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_b_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_b.id}"
    route_table_id = "${aws_route_table.private_routing_table.id}"
}

resource "aws_route_table_association" "private_subnet_c_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_c.id}"
    route_table_id = "${aws_route_table.private_routing_table.id}"
}


# Security Group

resource "aws_security_group" "allow_local" {
  name = "allow_local"
  vpc_id = "${var.vpc_id}"
  description = "Allow local inbound ssh traffic"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
 #	  cidr_blocks = ["0.0.0.0/0"]
      cidr_blocks = ["172.88.16.73/32"]
  }

  tags {
    Name = "allow_local"
  }
}


# Instance

# Create a new instance Amazon Linux AMI 2016.09.0 HVM (SSD) EBS-Backed 64-bit
# t2.micro node
resource "aws_instance" "web" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.allow_local.id}"]
    subnet_id = "${aws_subnet.public_subnet_a.id}"
#   availability_zone = "us-west-2a"
    associate_public_ip_address = true
    key_name = "cit360"

    tags {
        Name = "terraformInstance"
    }
}
