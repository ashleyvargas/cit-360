# ASSIGNMENT 2


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
    subnet_id = "${aws_subnet.public_subnet_a.id}"
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
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
        Name = "bastionHost"
    }
}



# ASSIGNMENT 3

variable "db_pass" {
  type = "string"
  description = "db password"
  default = "vdw4d_32l"
}


# * * * Security Group for DB * * * 

resource "aws_security_group" "db" {
  name = "db_sec_group"
  vpc_id = "${var.vpc_id}"
  description = "Allow inbound ssh traffic from VPC"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
 #	  cidr_blocks = ["0.0.0.0/0"]
      cidr_blocks = ["172.31.0.0/16"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "db_sec_group"
  }
}


# * * * DB Subnet Group * * * 

resource "aws_db_subnet_group" "default" {
    name = "db"
    subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]
    tags {
        Name = "DB subnet group"
    }
}


# * * * DB Instance * * * 

resource "aws_db_instance" "default" {
  allocated_storage    = 5
  engine               = "mariadb"
  engine_version       = "10.0.24"
  instance_class       = "db.t2.micro"
  storage_type         = "gp2"
  multi_az             = "false"
  publicly_accessible  = "false"
  db_subnet_group_name = "${aws_db_subnet_group.default.id}"
  identifier           = "dbinstance"
  name                 = "mydb"
  username             = "dbuser"
  password             = "${var.db_pass}"
  

  tags {
    Name = "DB Instance"
  }
}


# * * * Security Groups * * * 

resource "aws_security_group" "asmt3_instances" {
  name = "a3_security_group"
  vpc_id = "${var.vpc_id}"
  description = "Allow port 80 and 22 from VPC"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/16"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "A3 Security Group"
  }
}


resource "aws_security_group" "elb" {
  name = "elb_sec_group"
  vpc_id = "${var.vpc_id}"
  description = "Allow all inbound ssh traffic"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "elb_sec_group"
  }
}


# * * * Load Balancer * * * 

resource "aws_elb" "webservice" {
  name = "webservice-elb"
#  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  security_groups = ["${aws_security_group.elb.id}"]
  subnets = ["${aws_subnet.public_subnet_b.id}", "${aws_subnet.public_subnet_c.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/"
    interval = 30
  }

  instances = ["${aws_instance.webserver-b.id}", "${aws_instance.webserver-c.id}"]
  connection_draining = true
  connection_draining_timeout = 60


  tags {
    Name = "default-elb"
  }
}


# * * * Web Service Instances * * * 

resource "aws_instance" "webserver-b" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
#    vpc_security_group_ids = ["${aws_security_group.allow_local.id}"]
    subnet_id = "${aws_subnet.private_subnet_b.id}"
    associate_public_ip_address = false
    key_name = "cit360"

    tags {
        Name = "webserver-b"
        Service = "curriculum"
    }
}


resource "aws_instance" "webserver-c" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
#    vpc_security_group_ids = ["${aws_security_group.allow_local.id}"]
    subnet_id = "${aws_subnet.private_subnet_c.id}"
    associate_public_ip_address = false
    key_name = "cit360"

    tags {
        Name = "webserver-c"
        Service = "curriculum"
    }
}
