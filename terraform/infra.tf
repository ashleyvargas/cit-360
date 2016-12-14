# ASSIGNMENT 2


variable "vpc_id" {
  type = "string"
  description = "VPC ID for usage throughout the build process"
  default = "vpc-b2f407d5"
}

variable "db_password" {}

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
    cidr_block = "172.31.15.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-west-2a"

    tags {
        Name = "public_a"
    }
}

resource "aws_subnet" "public_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.16.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-west-2b"

    tags {
        Name = "public_b"
    }
}

resource "aws_subnet" "public_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.17.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-west-2c"

    tags {
        Name = "public_c"
    }
}


# PRIVATE

resource "aws_subnet" "private_subnet_a" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.0.0/22"
    availability_zone = "us-west-2a"

    tags {
        Name = "private_a"
    }
}

resource "aws_subnet" "private_subnet_b" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.5.0/22"
    availability_zone = "us-west-2b"

    tags {
        Name = "private_b"
    }
}

resource "aws_subnet" "private_subnet_c" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.10.0/22"
    availability_zone = "us-west-2c"

    tags {
        Name = "private_c"
    }
}

resource "aws_eip" "elastic_ip" {
  vpc      = true
#  depends_on = ["aws_internet_gateway.gw"]
}


resource "aws_nat_gateway" "gw" {
    allocation_id = "${aws_eip.elastic_ip.id}"
    subnet_id = "${aws_subnet.public_subnet_a.id}"
#    depends_on = ["aws_internet_gateway.gw"]
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
     cidr_blocks = ["0.0.0.0/0"]
 #     cidr_blocks = ["172.31.0.0/16"]
  #    cidr_blocks = ["130.166.220.26/16"]
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
resource "aws_instance" "bastion" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.allow_local.id}"]
    subnet_id = "${aws_subnet.public_subnet_a.id}"
    associate_public_ip_address = true
    key_name = "cit360"

    tags {
        Name = "bastionHost"
    }
}



# ASSIGNMENT 3


# * * * Security Group for DB * * * 

resource "aws_security_group" "db_security" {
  name = "db_sec_group"
  vpc_id = "${var.vpc_id}"
  description = "Allow inbound ssh traffic from VPC"

  ingress {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
 #    cidr_blocks = ["0.0.0.0/0"]
      cidr_blocks = ["172.31.0.0/16"]
  }

  tags {
    Name = "db_sec_group"
  }
}


# * * * DB Subnet Group * * * 

resource "aws_db_subnet_group" "db_subnet" {
    name = "db"
    subnet_ids = ["${aws_subnet.private_subnet_a.id}", "${aws_subnet.private_subnet_b.id}"]
    tags {
        Name = "DB subnet group"
    }
}


# * * * DB Instance * * * 

resource "aws_db_instance" "database" {
  allocated_storage    = 5
  engine               = "mariadb"
  engine_version       = "10.0.24"
  instance_class       = "db.t2.micro"
  storage_type         = "gp2"
  multi_az             = "false"
  db_subnet_group_name = "${aws_db_subnet_group.db_subnet.id}"
  name                 = "mydb"
  username             = "dbuser"
  password             = "${var.db_password}"
  parameter_group_name = "default.mariadb10.0"
  vpc_security_group_ids = ["${aws_security_group.db_security.id}"]
  

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
      cidr_blocks = ["130.166.220.26/16"]
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


resource "aws_security_group" "elb_security" {
  name = "elb_sec_group"
  vpc_id = "${var.vpc_id}"
  description = "Allow all inbound ssh traffic"

  ingress {
      from_port = 80
      to_port = 80
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

  security_groups = ["${aws_security_group.elb_security.id}"]

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
  cross_zone_load_balancing = true
  idle_timeout = 60
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
    vpc_security_group_ids = ["${aws_security_group.asmt3_instances.id}"]
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
    vpc_security_group_ids = ["${aws_security_group.asmt3_instances.id}"]
    subnet_id = "${aws_subnet.private_subnet_c.id}"
    associate_public_ip_address = false
    key_name = "cit360"

    tags {
        Name = "webserver-c"
        Service = "curriculum"
    }
}
