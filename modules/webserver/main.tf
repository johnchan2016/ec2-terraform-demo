resource "aws_default_security_group" "default-sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name : "${var.env_prefix}-default-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = [var.image_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone      = var.avail_zone

  associate_public_ip_address = true

  # download key pair
  # move to .pem to ~/.ssh
  # chmod 400 ~/.ssh
  key_name = aws_key_pair.ssh-key.key_name

  user_data = file("entry-script.sh")

  tags = {
    Name = "${var.env_prefix}-server"
  }
}

//add extra volume
/*
resource "aws_ebs_volume" "ebs_volume_1" {
  availability_zone = var.avail_zone
  size = 8
  type = "gp2"

  tags = {
    "Name" = "${var.env_prefix}-ebs-volume-1"
  }
}

resource "aws_volume_attachment" "ebs_volume_1_attachment" {
  device_name = "/dev/xvdh"
  volume_id = aws_ebs_volume.ebs_volume_1.id
  instance_id = aws_instance.myapp-server.id
}
*/

//autoscale
/*
resource "aws_launch_configuration" "ec2_launch_config" {
  name_prefix = "ec2_launch_config"
  #image_id = 
  instance_type = var.instance_type
  key_name = aws_key_pair.ssh-key.key_name
  security_groups = [aws_default_security_group.default-sg.id]
}

resource "aws_autoscaling_group" "ec2_autoscale" {
  name = "ec2_autoscale"
  vpc_zone_identifier = [var.subnet_id]
  launch_configuration = aws_launch_configuration.ec2_launch_config.name
  min_size = 1
  max_size = 2
  health_check_grace_period = 300
  health_check_type = "EC2"
  force_delete = true

  tag {
    key = "Name"
    value = "ec2 instance"
    propagate_at_launch = true
  }
}


resource "aws_autoscaling_policy" "cpu_policy" {
  name = "cpu_policy"
  autoscaling_group_name = aws_autoscaling_group.ec2_autoscale.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "1"
  cooldown = "300"
  policy_type = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name = "cpu_alarm"
  alarm_description = "cpu_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "30"

  dimensions =  {
    "AutoScalingGroupName" = aws_autoscaling_group.ec2_autoscale.name
  }

  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.cpu_policy.arn]
}

resource "aws_sns_topic" "cpu_sns" {
  name = "sg_cpu_sns"
  display_name = "ASG SNS TOPIC"
}

resource "aws_autoscaling_notification" "autoscale_notification" {
  group_names = [aws_autoscaling_group.ec2_autoscale.name]
  topic_arn = aws_sns_topic.cpu_sns.arn
  notifications = [ 
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR"
    ]
}
*/