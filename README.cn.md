# Serverless Security Workshop

[English](./README.md)

基于华为云的 Serverless 安全工作坊演示应用。

## 项目概述

本项目是一个 **Serverless 安全教学工作坊**，演示如何在华为云上构建安全的无服务器架构应用。

### 背景故事

本项目基于一个虚构的 **"Wild Rydes" 独角兽租赁平台**场景：
- 用户可以租赁各种神奇的独角兽
- 独角兽有不同的定制选项（袜子、角、眼镜、披风）
- 合作伙伴可以提供额外的配件和服务

### 教学目标

本工作坊旨在教授以下安全实践：

1. **身份与访问管理 (IAM)**
   - 如何正确配置函数权限
   - 使用 IAM 委托实现最小权限原则

2. **基础设施安全**
   - VPC 私有网络配置
   - 安全组规则设置

3. **数据安全**
   - 静态数据加密
   - 敏感信息保护

4. **传输安全**
   - HTTPS 强制使用
   - API 签名认证

5. **监控与日志**
   - 函数日志配置
   - 异常监控告警

### 核心功能

本项目实现了一个完整的 Serverless REST API，包含以下功能模块：

| 模块 | 功能 | 说明 |
|------|------|------|
| **Unicorn 部件** | 查询独角兽配件 | 列出可用的魔法袜子、角、眼镜、披风 |
| **定制管理** | 管理定制选项 | 用户可以创建、查看、删除独角兽定制 |
| **合作伙伴** | 合作伙伴管理 | 合作伙伴注册与管理（简化版） |

## 架构

```
                    ┌─────────────────────────────────────┐
                    │           APIG (API 网关)           │
                    │   HTTPS 访问，统一入口，统一认证    │
                    └──────────────┬──────────────────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          │                        │                        │
          ▼                        ▼                        ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ Unicorn Parts   │  │ Customize       │  │ Partners        │
│ FunctionGraph   │  │ FunctionGraph   │  │ FunctionGraph   │
│ /socks         │  │ /customizations │  │ /partners       │
│ /horns         │  │                 │  │                 │
│ /glasses       │  │                 │  │                 │
│ /capes         │  │                 │  │                 │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  GeminiDB (集群)   │
                    │  Cassandra模式 │
                    │  存储部件/定制/伙伴 │
                    └─────────────────────┘
```

### 技术栈

| 组件 | 华为云服务 | 说明 |
|------|-----------|------|
| API 网关 | APIG | 统一入口，HTTPS，流量控制 |
| 后端服务 | FunctionGraph | Node.js 18 运行时 |
| 数据存储 | GeminiDB | Cassandra NoSQL |
| 网络 | VPC + 安全组 | 私有网络隔离 |

## 前置条件

- 华为云账号
- AK/SK 访问凭证
- Terraform >= 1.5

## 快速开始

### 1. 克隆仓库

```bash
git clone <repo-url>
cd serverless-security-workshop
```

### 2. 配置凭据

```bash
export HW_ACCESS_KEY="your-access-key"
export HW_SECRET_KEY="your-secret-key"
```

### 3. 部署

```bash
cd infra
terraform init
terraform apply -var-file=tfvars.example
```

### 4. 验证

```bash
# 获取 API 地址
APIG_URL=$(terraform output -raw apig_url)

# 测试各 API
curl "$APIG_URL/socks"
curl "$APIG_URL/horns"
curl "$APIG_URL/glasses"
curl "$APIG_URL/capes"
curl "$APIG_URL/customizations"
```

## API 端点

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /socks | 获取魔法袜子列表 |
| GET | /horns | 获取独角兽角列表 |
| GET | /glasses | 获取魔法眼镜列表 |
| GET | /capes | 获取魔法披风列表 |
| GET | /customizations | 获取定制列表 |
| POST | /customizations | 创建新定制 |
| DELETE | /customizations/{id} | 删除定制 |
| POST | /partners | 创建合作伙伴 |

## 安全特性

本项目展示了以下华为云安全最佳实践：

1. **IAM 委托**
   - FunctionGraph 通过 Agency 访问其他服务
   - 遵循最小权限原则

2. **私有网络**
   - 所有资源部署在 VPC 内
   - 仅通过 APIG 对外暴露

3. **安全组**
   - 严格控制入站流量
   - 仅开放必要端口

4. **HTTPS 强制**
   - APIG 强制 HTTPS 访问
   - 保护数据传输安全

## 清理

```bash
terraform destroy -var-file=tfvars.example
```

## 许可证

MIT No Attribution - Copyright Huawei Cloud
