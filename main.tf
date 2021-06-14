/*
################################################################################
 1. VPC
 2. Subnet
 3. Internet Gateway
 4. NAT Gateway
 5. Routing Table
 6. Security Group
 7. VPC endpoint (sagemaker studio, redshift)
################################################################################
*/
provider "aws" {
  region = "ap-northeast-2"
}

################################################################################
# 1. VPC
################################################################################
resource "aws_vpc" "this" {
  cidr_block           = "10.110.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "kyowon-vpc"
  }
}



################################################################################
# 2. Subnet
################################################################################
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.this.id
  availability_zone = "ap-northeast-2a"
  cidr_block        = "10.110.0.0/24"

  tags = {
    Name = "kyowon-pub-a"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.this.id
  availability_zone = "ap-northeast-2c"
  cidr_block        = "10.110.1.0/24"

  tags = {
    Name = "kyowon-pub-c"
  }
}

resource "aws_subnet" "private_analytics_a" {
  vpc_id            = aws_vpc.this.id
  availability_zone = "ap-northeast-2a"
  cidr_block        = "10.110.2.0/24"

  tags = {
    Name = "kyowon-pri-analytics-a"
  }
}

resource "aws_subnet" "private_analytics_c" {
  vpc_id            = aws_vpc.this.id
  availability_zone = "ap-northeast-2c"
  cidr_block        = "10.110.3.0/24"

  tags = {
    Name = "kyowon-pri-analytics-c"
  }
}

################################################################################
# 3. Internet Gateway
################################################################################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "kyowon-igw"
  }
}

################################################################################
# 4. NAT Gateway
################################################################################
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "kyowon-nat-a"
  }
}

## EIP - NAT
resource "aws_eip" "nat_a" {
  vpc = true
}

################################################################################
# 5. Routing Table
################################################################################
## public 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "kyowon-pub-rt"
  }
}

resource "aws_route_table_association" "public_rt_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public_rt.id
}

## Private
resource "aws_route_table" "private_analytics_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "kyowon-pri-analytics-rt"
  }
}

resource "aws_route_table_association" "private_analytics_rt_a" {
  subnet_id      = aws_subnet.private_analytics_a.id
  route_table_id = aws_route_table.private_analytics_rt.id
}

resource "aws_route_table_association" "private_analytics_rt_c" {
  subnet_id      = aws_subnet.private_analytics_c.id
  route_table_id = aws_route_table.private_analytics_rt.id
}


################################################################################
# 6. Security Group
################################################################################
resource "aws_security_group" "rs_sg" {
  name        = "kyowon-rs-sg"
  description = "Redshift Service"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "kyowon-rs-sg"
  }
}


resource "aws_security_group" "sagemaker_studio_sg" {
  name        = "kyowon-sagemaker-studio-sg"
  description = "sagemaker_studio"
  vpc_id      = aws_vpc.this.id  

  tags = {
    Name = "kyowon-sagemaker-studio-sg"
  }
}

resource "aws_security_group" "quicksight_sg" {
  name        = "kyowon-quicksight-sg"
  description = "Quicksight Service"
  vpc_id      = aws_vpc.this.id  

  tags = {
    Name = "kyowon-quicksight-sg"
  }
}

resource "aws_security_group" "redshift_endpoint_sg" {
  name        = "kyowon-redshift-endpoint-sg"
  description = "redshift-endpoint-sg Service"
  vpc_id      = aws_vpc.this.id  

  tags = {
    Name = "kyowon-redshift-endpoint-sg"
  }
}
################################################################################
# Security Group Rule
################################################################################

## rs_sg
## ingress
resource "aws_security_group_rule" "rs_sg_in_01" {
  type      = "ingress"
  from_port = 5439
  to_port   = 5439
  protocol  = "TCP"
  cidr_blocks = [ "0.0.0.0/0" ]
  description = ""
  security_group_id = aws_security_group.rs_sg.id

}

resource "aws_security_group_rule" "rs_sg_in_02" {
  type      = "ingress"
  from_port = 5439
  to_port   = 5439
  protocol  = "TCP"  
  description = "sagemaker_studio"
  security_group_id         = aws_security_group.rs_sg.id
  source_security_group_id  = aws_security_group.sagemaker_studio_sg.id

}

resource "aws_security_group_rule" "rs_sg_in_03" {
  type      = "ingress"
  from_port = 0
  to_port   = 65535
  protocol  = "TCP"  
  description = "quicksight"
  security_group_id         = aws_security_group.rs_sg.id
  source_security_group_id  = aws_security_group.quicksight_sg.id

}

resource "aws_security_group_rule" "rs_sg_in_04" {
  type      = "ingress"
  from_port = 2049
  to_port   = 2049
  protocol  = "TCP"  
  description = "sagemaker_studio"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id         = aws_security_group.rs_sg.id  

}

## egress
resource "aws_security_group_rule" "rs_sg_out_01" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = -1
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id         = aws_security_group.rs_sg.id  

}

## sagemaker_studio_sg
## ingress
resource "aws_security_group_rule" "sagemaker_studio_sg_in_01" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = -1   
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id         = aws_security_group.sagemaker_studio_sg.id  
}

## egress
resource "aws_security_group_rule" "sagemaker_studio_sg_out_01" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = -1   
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id         = aws_security_group.sagemaker_studio_sg.id  
}

## quicksight_sg
## ingress
resource "aws_security_group_rule" "quicksight_sg_in_01" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = "TCP"  
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id         = aws_security_group.quicksight_sg.id  
}
## egress
resource "aws_security_group_rule" "quicksight_sg_out_01" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = -1  
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id         = aws_security_group.quicksight_sg.id  

}

## redshift-endpoint-sg
## ingress
resource "aws_security_group_rule" "redshift_endpoint_sg_in_01" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "TCP"
  cidr_blocks = [ "10.110.0.0/16" ]
  description = "for kyowon-vpc access"
  security_group_id = aws_security_group.redshift_endpoint_sg.id

}

resource "aws_security_group_rule" "redshift_endpoint_sg_in_02" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "TCP"  
  cidr_blocks = [ "10.110.0.0/16" ]
  description = "for kyowon-vpc access"  
  security_group_id         = aws_security_group.redshift_endpoint_sg.id  

}

## egress
resource "aws_security_group_rule" "redshift_endpoint_sg_out_01" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = -1
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id         = aws_security_group.redshift_endpoint_sg.id  

}


################################################################################
# VPC endpoint
################################################################################

## redshift endpoint
resource "aws_vpc_endpoint" "redshift" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.ap-northeast-2.redshift"
  vpc_endpoint_type = "Interface"

  security_group_ids = [ aws_security_group.redshift_endpoint_sg.id ]

  subnet_ids          = [ 
      aws_subnet.private_analytics_a.id , 
      aws_subnet.private_analytics_c.id   
  ]
  
  private_dns_enabled = true

  tags = {
    Name = "kyowon-redshift-endpoint"
  }
}

## sagemaker endpoint
resource "aws_vpc_endpoint" "sagemaker_studio" {
  vpc_id       = aws_vpc.this.id
  service_name = "aws.sagemaker.ap-northeast-2.studio"
  vpc_endpoint_type = "Interface"

  security_group_ids = [ aws_security_group.sagemaker_studio_sg.id ]

  subnet_ids          = [ 
      aws_subnet.private_analytics_a.id , 
      aws_subnet.private_analytics_c.id   
  ]
  
  private_dns_enabled = true

  tags = {
    Name = "kyowon-sagemaker-studio-endpoint"
  }
}