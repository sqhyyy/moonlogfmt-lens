# MoonLogfmt Lens 项目申报摘要

- 申报人：宋庆辉
- 邮箱：sqh3242511142@qq.com
- 手机号：18975974634
- GitHub / Mooncakes：sqhyyy
- GitHub 仓库：https://github.com/sqhyyy/moonlogfmt-lens
- Mooncakes 包：https://mooncakes.io/docs/sqhyyy/moonlogfmt-lens
- 许可证：Apache-2.0

MoonLogfmt Lens 是一个使用 MoonBit 原创实现的 logfmt 日志治理工具。它不负责生成或采集日志，而是面向已有 logfmt 文本，提供解析审计、字段契约验证、隐私脱敏、批量质量画像和版本漂移分析。

项目解决的核心问题是：logfmt 虽然易读易写，但在工程链路中容易出现重复键、缺失关键字段、类型悄然变化、敏感信息泄露和结构数量失控。MoonLogfmt Lens 可以在日志进入 CI、支持工单或下游平台前，提前发现并解释这些风险。

当前 `0.2.0` 版本已完成完整解析器、质量审计、语义类型分类、可执行契约、Schema 推断、隐私脱敏、结构指纹、批量门禁和基线漂移分析。结构指纹只保留键名和语义类型，不保留具体日志值，便于在降低数据暴露风险的前提下比较不同批次的日志结构。

项目不是日志输出库，也不是通用遥测采集器；创新点在于把“解析、语义画像、契约推断、隐私投影、无值结构指纹、批量门禁、漂移解释”连成一个消费侧治理闭环。公开检索 Mooncakes、GitHub、公开代码搜索和 MoonBit OSC 相关信息后，未发现同时具备该完整 logfmt 治理闭环的公开 MoonBit 项目。

工程完成度方面，项目包含 16 个 MoonBit 文件、5 种 CLI 模式和 4 个可运行示例。格式化后的 MoonBit 手写代码共 5558 行，其中核心库 4410 行、自动化测试 976 行、CLI 与示例 172 行。`moon fmt --check`、`moon check`、`moon build`、`moon test`、`moon package --list` 和 `moon info` 均已通过，测试结果为 95 项通过、0 项失败。GitHub Actions 最新检查通过，Mooncakes 包 `sqhyyy/moonlogfmt-lens` 版本 `0.2.0` 已公开发布。
