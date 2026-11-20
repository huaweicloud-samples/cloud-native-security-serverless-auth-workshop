# 架构说明

## 系统架构

本项目采用华为云 Serverless 架构，构建一个安全的 Unicorn 定制化 API 服务。

```
                    ┌─────────────────────────────────────┐
                    │           APIG (API 网关)           │
                    │   https://{ingress_address}/        │
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
                    │  GeminiDB (集群)    │
                    │  Cassandra模式  │
                    └─────────────────────┘
```

## 组件说明

| 组件 | 华为云服务 | 说明 |
|------|-----------|------|
| API 网关 | APIG | 统一入口，提供 HTTPS 访问 |
| 后端服务 | FunctionGraph | Node.js 18 运行时 |
| 数据存储 | GeminiDB | Cassandra模式 |
| 网络 | VPC + 安全组 | 私有网络隔离 |

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
| POST | /partners | 创建合作伙伴（简化版） |

## 安全特性

1. **私有网络**：所有资源部署在 VPC 内
2. **安全组**：仅开放必要端口 (80, 443, 8080)
3. **IAM 委托**：FunctionGraph 通过 Agency 访问其他服务
4. **HTTPS**：APIG 强制 HTTPS 访问

## 简化调整说明

本项目为适配华为云，对参照架构做了以下调整：

- **移除外部身份服务依赖**：合作伙伴管理功能简化为无需用户认证的版本
- **简化架构**：使用 FunctionGraph 内联代码（inline）简化部署
