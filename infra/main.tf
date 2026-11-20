# ============================================================================
# 华为云 Serverless API 架构 Terraform
# ============================================================================
# 项目: Serverless Security Workshop
# 描述: 基于华为云的 Serverless API 服务，包含 Cassandra 存储和 API 网关
# ============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.70"
    }
  }
}

provider "huaweicloud" {
  region = var.region
}

# ============================================================================
# 可用区（APIG 专享实例与 GeminiDB 需指定）
# ============================================================================

data "huaweicloud_availability_zones" "main" {}

# ============================================================================
# 变量定义
# ============================================================================

variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4"
}

variable "project_name" {
  description = "项目名称"
  type        = string
  default     = "serverless-security"
}

variable "geminidb_password" {
  description = "GeminiDB 密码"
  type        = string
  sensitive   = true
}

# ============================================================================
# 基础设施层
# ============================================================================

resource "huaweicloud_vpc" "main" {
  name                  = "${var.project_name}-vpc"
  cidr                  = "10.0.0.0/16"
  enterprise_project_id = "0"
}

resource "huaweicloud_vpc_subnet" "main" {
  name       = "${var.project_name}-subnet"
  vpc_id     = huaweicloud_vpc.main.id
  cidr       = "10.0.1.0/24"
  gateway_ip = "10.0.1.1"
}

resource "huaweicloud_networking_secgroup" "main" {
  name        = "${var.project_name}-sg"
  description = "Security group for serverless API"
}

resource "huaweicloud_networking_secgroup_rule" "allow_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

resource "huaweicloud_networking_secgroup_rule" "allow_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

resource "huaweicloud_networking_secgroup_rule" "allow_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

# ============================================================================
# 数据层 - GeminiDB Cassandra
# ============================================================================

resource "huaweicloud_geminidb_instance" "main" {
  name              = "${var.project_name}-db"
  mode              = "Cluster"
  password          = var.geminidb_password
  availability_zone = "${var.region}a,${var.region}b,${var.region}c"
  vpc_id            = huaweicloud_vpc.main.id
  subnet_id         = huaweicloud_vpc_subnet.main.id
  security_group_id = huaweicloud_networking_secgroup.main.id

  datastore {
    type           = "cassandra"
    storage_engine = "rocksDB"
    version        = "3.11"
  }

  flavor {
    num       = 3
    size      = 100
    spec_code = "geminidb.cassandra.large.4"
    storage   = "ULTRAHIGH"
  }

  tags = {
    project = var.project_name
  }
}

# ============================================================================
# 计算层 - FunctionGraph
# ============================================================================

resource "huaweicloud_identity_agency" "functiongraph" {
  name                   = "${var.project_name}-fgs-agency"
  description            = "Agency for FunctionGraph"
  duration               = "FOREVER"
  delegated_service_name = "op_svc_cff"

  project_role {
    project = var.region
    roles = [
      "OBS OperateAccess",
      "GeminiDB FullAccess",
    ]
  }
}

# Unicorn Parts Function
resource "huaweicloud_fgs_function" "unicorn_parts" {
  name        = "${var.project_name}-unicorn-parts"
  app         = "default"
  agency      = huaweicloud_identity_agency.functiongraph.name
  handler     = "index.handler"
  memory_size = 256
  timeout     = 30
  runtime     = "Node.js18.15"

  code_type = "inline"
  func_code = <<-EOF
exports.handler = async (event, context) => {
  const path = event.path || '/';
  const parts = {
    socks: ['Magic Socks', 'Invisible Socks', 'Levitation Socks'],
    horns: ['Golden Horn', 'Silver Horn', 'Crystal Horn'],
    glasses: ['Night Vision Glasses', 'X-Ray Glasses', 'Holographic Glasses'],
    capes: ['Invisibility Cape', 'Flight Cape', 'Fireproof Cape']
  };
  
  let result = parts;
  if (path.includes('/socks')) result = { socks: parts.socks };
  else if (path.includes('/horns')) result = { horns: parts.horns };
  else if (path.includes('/glasses')) result = { glasses: parts.glasses };
  else if (path.includes('/capes')) result = { capes: parts.capes };
  
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    body: JSON.stringify(result)
  };
};
EOF

  tags = {
    project = var.project_name
  }
}

# Customize Unicorn Function
resource "huaweicloud_fgs_function" "customize_unicorn" {
  name        = "${var.project_name}-customize-unicorn"
  app         = "default"
  agency      = huaweicloud_identity_agency.functiongraph.name
  handler     = "index.handler"
  memory_size = 256
  timeout     = 30
  runtime     = "Node.js18.15"

  code_type = "inline"
  func_code = <<-EOF
exports.handler = async (event, context) => {
  const httpMethod = event.httpMethod;
  const path = event.path || '/';
  const body = event.body ? JSON.parse(event.body) : {};
  
  let response = { message: 'Unicorn customization API' };
  
  if (httpMethod === 'GET' && path.includes('/customizations')) {
    response = { customizations: [] };
  } else if (httpMethod === 'POST' && path.includes('/customizations')) {
    response = { id: '1', ...body, status: 'created' };
  } else if (httpMethod === 'DELETE' && path.includes('/customizations')) {
    response = { status: 'deleted' };
  }
  
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    body: JSON.stringify(response)
  };
};
EOF

  tags = {
    project = var.project_name
  }
}

# Manage Partners Function (简化版 - 无外部身份服务依赖)
resource "huaweicloud_fgs_function" "manage_partners" {
  name        = "${var.project_name}-manage-partners"
  app         = "default"
  agency      = huaweicloud_identity_agency.functiongraph.name
  handler     = "index.handler"
  memory_size = 256
  timeout     = 30
  runtime     = "Node.js18.15"

  code_type = "inline"
  func_code = <<-EOF
exports.handler = async (event, context) => {
  // 简化版合作伙伴管理 - 不依赖外部身份服务
  const httpMethod = event.httpMethod;
  const body = event.body ? JSON.parse(event.body) : {};
  
  let response = { message: 'Partner management API (simplified)' };
  
  if (httpMethod === 'POST') {
    response = { partnerId: 'partner-1', name: body.name || 'Partner', status: 'active' };
  }
  
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    body: JSON.stringify(response)
  };
};
EOF

  tags = {
    project = var.project_name
  }
}

# ============================================================================
# API 层 - APIG
# ============================================================================

resource "huaweicloud_apig_instance" "main" {
  name              = "${var.project_name}-apig"
  edition           = "BASIC"
  vpc_id            = huaweicloud_vpc.main.id
  subnet_id         = huaweicloud_vpc_subnet.main.id
  security_group_id = huaweicloud_networking_secgroup.main.id
  maintain_begin    = "06:00:00"
  bandwidth_size    = 5
  available_zones = [
    data.huaweicloud_availability_zones.main.names[0],
    data.huaweicloud_availability_zones.main.names[1],
  ]

  tags = {
    project = var.project_name
  }
}

resource "huaweicloud_apig_group" "main" {
  name        = "${var.project_name}-api-group"
  instance_id = huaweicloud_apig_instance.main.id
  description = "API group for serverless security workshop"
}

resource "huaweicloud_apig_environment" "main" {
  name        = "release"
  instance_id = huaweicloud_apig_instance.main.id
  description = "Production environment"
}

# Unicorn Parts APIs
resource "huaweicloud_apig_api" "unicorn_socks" {
  name             = "list-socks"
  group_id         = huaweicloud_apig_group.main.id
  instance_id      = huaweicloud_apig_instance.main.id
  type             = "FunctionGraph"
  request_method   = "GET"
  request_path     = "/socks"
  request_protocol = "HTTPS"

  func_graph {
    function_urn = huaweicloud_fgs_function.unicorn_parts.urn
  }

  tags = [var.project_name]
}

resource "huaweicloud_apig_api_publishment" "unicorn_socks" {
  instance_id = huaweicloud_apig_instance.main.id
  api_id      = huaweicloud_apig_api.unicorn_socks.id
  env_id      = huaweicloud_apig_environment.main.id
}

resource "huaweicloud_apig_api" "unicorn_horns" {
  name             = "list-horns"
  group_id         = huaweicloud_apig_group.main.id
  instance_id      = huaweicloud_apig_instance.main.id
  type             = "FunctionGraph"
  request_method   = "GET"
  request_path     = "/horns"
  request_protocol = "HTTPS"

  func_graph {
    function_urn = huaweicloud_fgs_function.unicorn_parts.urn
  }

  tags = [var.project_name]
}

resource "huaweicloud_apig_api_publishment" "unicorn_horns" {
  instance_id = huaweicloud_apig_instance.main.id
  api_id      = huaweicloud_apig_api.unicorn_horns.id
  env_id      = huaweicloud_apig_environment.main.id
}

resource "huaweicloud_apig_api" "unicorn_glasses" {
  name             = "list-glasses"
  group_id         = huaweicloud_apig_group.main.id
  instance_id      = huaweicloud_apig_instance.main.id
  type             = "FunctionGraph"
  request_method   = "GET"
  request_path     = "/glasses"
  request_protocol = "HTTPS"

  func_graph {
    function_urn = huaweicloud_fgs_function.unicorn_parts.urn
  }

  tags = [var.project_name]
}

resource "huaweicloud_apig_api_publishment" "unicorn_glasses" {
  instance_id = huaweicloud_apig_instance.main.id
  api_id      = huaweicloud_apig_api.unicorn_glasses.id
  env_id      = huaweicloud_apig_environment.main.id
}

resource "huaweicloud_apig_api" "unicorn_capes" {
  name             = "list-capes"
  group_id         = huaweicloud_apig_group.main.id
  instance_id      = huaweicloud_apig_instance.main.id
  type             = "FunctionGraph"
  request_method   = "GET"
  request_path     = "/capes"
  request_protocol = "HTTPS"

  func_graph {
    function_urn = huaweicloud_fgs_function.unicorn_parts.urn
  }

  tags = [var.project_name]
}

resource "huaweicloud_apig_api_publishment" "unicorn_capes" {
  instance_id = huaweicloud_apig_instance.main.id
  api_id      = huaweicloud_apig_api.unicorn_capes.id
  env_id      = huaweicloud_apig_environment.main.id
}

# Customization APIs
resource "huaweicloud_apig_api" "customizations" {
  name             = "customizations"
  group_id         = huaweicloud_apig_group.main.id
  instance_id      = huaweicloud_apig_instance.main.id
  type             = "FunctionGraph"
  request_method   = "GET"
  request_path     = "/customizations"
  request_protocol = "HTTPS"

  func_graph {
    function_urn = huaweicloud_fgs_function.customize_unicorn.urn
  }

  tags = [var.project_name]
}

resource "huaweicloud_apig_api_publishment" "customizations" {
  instance_id = huaweicloud_apig_instance.main.id
  api_id      = huaweicloud_apig_api.customizations.id
  env_id      = huaweicloud_apig_environment.main.id
}

resource "huaweicloud_apig_api" "customizations_create" {
  name             = "create-customization"
  group_id         = huaweicloud_apig_group.main.id
  instance_id      = huaweicloud_apig_instance.main.id
  type             = "FunctionGraph"
  request_method   = "POST"
  request_path     = "/customizations"
  request_protocol = "HTTPS"

  func_graph {
    function_urn = huaweicloud_fgs_function.customize_unicorn.urn
  }

  tags = [var.project_name]
}

resource "huaweicloud_apig_api_publishment" "customizations_create" {
  instance_id = huaweicloud_apig_instance.main.id
  api_id      = huaweicloud_apig_api.customizations_create.id
  env_id      = huaweicloud_apig_environment.main.id
}

resource "huaweicloud_apig_api" "customizations_delete" {
  name             = "delete-customization"
  group_id         = huaweicloud_apig_group.main.id
  instance_id      = huaweicloud_apig_instance.main.id
  type             = "FunctionGraph"
  request_method   = "DELETE"
  request_path     = "/customizations/{id}"
  request_protocol = "HTTPS"

  func_graph {
    function_urn = huaweicloud_fgs_function.customize_unicorn.urn
  }

  tags = [var.project_name]
}

resource "huaweicloud_apig_api_publishment" "customizations_delete" {
  instance_id = huaweicloud_apig_instance.main.id
  api_id      = huaweicloud_apig_api.customizations_delete.id
  env_id      = huaweicloud_apig_environment.main.id
}

# Partner API (简化版)
resource "huaweicloud_apig_api" "partners" {
  name             = "create-partner"
  group_id         = huaweicloud_apig_group.main.id
  instance_id      = huaweicloud_apig_instance.main.id
  type             = "FunctionGraph"
  request_method   = "POST"
  request_path     = "/partners"
  request_protocol = "HTTPS"

  func_graph {
    function_urn = huaweicloud_fgs_function.manage_partners.urn
  }

  tags = [var.project_name]
}

resource "huaweicloud_apig_api_publishment" "partners" {
  instance_id = huaweicloud_apig_instance.main.id
  api_id      = huaweicloud_apig_api.partners.id
  env_id      = huaweicloud_apig_environment.main.id
}

# ============================================================================
# 输出
# ============================================================================

output "apig_url" {
  description = "APIG 访问地址"
  value       = "https://${huaweicloud_apig_instance.main.ingress_address}"
}

output "api_endpoints" {
  description = "API 端点列表"
  value = {
    socks          = "https://${huaweicloud_apig_instance.main.ingress_address}/socks"
    horns          = "https://${huaweicloud_apig_instance.main.ingress_address}/horns"
    glasses        = "https://${huaweicloud_apig_instance.main.ingress_address}/glasses"
    capes          = "https://${huaweicloud_apig_instance.main.ingress_address}/capes"
    customizations = "https://${huaweicloud_apig_instance.main.ingress_address}/customizations"
    partners       = "https://${huaweicloud_apig_instance.main.ingress_address}/partners"
  }
}

output "geminidb_endpoint" {
  description = "GeminiDB 端点"
  value       = huaweicloud_geminidb_instance.main.lb_ip_address
  sensitive   = true
}

output "function_urns" {
  description = "FunctionGraph 函数 URN"
  value = {
    unicorn_parts = huaweicloud_fgs_function.unicorn_parts.urn
    customize     = huaweicloud_fgs_function.customize_unicorn.urn
    partners      = huaweicloud_fgs_function.manage_partners.urn
  }
}
