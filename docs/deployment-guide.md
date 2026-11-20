# 部署指南

## 前置条件

1. 华为云账号
2. AK/SK 访问凭证
3. 已安装 Terraform >= 1.5

## 步骤 1：配置凭据

```bash
# 设置华为云访问凭证
export HW_ACCESS_KEY="your-access-key"
export HW_SECRET_KEY="your-secret-key"
```

## 步骤 2：初始化 Terraform

```bash
cd infra
terraform init
```

## 步骤 3：验证配置

```bash
terraform validate
terraform plan -var-file=tfvars.example
```

## 步骤 4：部署

```bash
terraform apply -var-file=tfvars.example
```

部署过程中需要输入以下变量：
- `region`: 区域（默认 cn-north-4）
- `project_name`: 项目名称
- `geminidb_password`: GeminiDB 密码

## 步骤 5：验证部署

部署完成后，查看输出：

```bash
terraform output
```

获取 API 访问地址：

```bash
# 获取 APIG 访问地址
APIG_URL=$(terraform output -raw apig_url)
echo "API URL: $APIG_URL"

# 测试 API
curl "$APIG_URL/socks"
curl "$APIG_URL/horns"
curl "$APIG_URL/glasses"
curl "$APIG_URL/capes"
curl "$APIG_URL/customizations"
```

## 步骤 6：清理资源

```bash
terraform destroy -var-file=tfvars.example
```

## 注意事项

1. **费用**：APIG 和 GeminiDB 会产生费用，详见华为云定价
2. **安全组**：确保安全组规则适合您的网络环境
3. **密码**：GeminiDB 密码至少8位，包含大小写字母和数字
