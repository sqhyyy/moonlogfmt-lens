# -*- coding: utf-8 -*-
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
OUTPUT = DOCS / "submission-application.pdf"
CHINESE_FONT = Path(r"C:\Windows\Fonts\simhei.ttf")


def para(text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(text, style)


def main() -> None:
    pdfmetrics.registerFont(TTFont("SimHei", str(CHINESE_FONT)))
    styles = getSampleStyleSheet()

    title = ParagraphStyle(
        "Title",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=21,
        leading=25,
        textColor=colors.HexColor("#111827"),
        spaceAfter=3,
    )
    subtitle = ParagraphStyle(
        "Subtitle",
        parent=styles["BodyText"],
        fontName="SimHei",
        fontSize=10,
        leading=13,
        alignment=1,
        textColor=colors.HexColor("#0f766e"),
        spaceAfter=7,
    )
    heading = ParagraphStyle(
        "Heading",
        parent=styles["Heading2"],
        fontName="SimHei",
        fontSize=10.5,
        leading=13,
        textColor=colors.HexColor("#0f766e"),
        spaceBefore=5,
        spaceAfter=2,
    )
    body = ParagraphStyle(
        "Body",
        parent=styles["BodyText"],
        fontName="SimHei",
        fontSize=8.5,
        leading=11.5,
        textColor=colors.HexColor("#1f2937"),
        spaceAfter=3,
    )
    small = ParagraphStyle(
        "Small",
        parent=body,
        fontSize=8,
        leading=10.5,
        textColor=colors.HexColor("#4b5563"),
    )

    story = [
        para("MoonLogfmt Lens", title),
        para("MoonBit 黑客松项目申报摘要", subtitle),
        para(
            "申报人：宋庆辉　邮箱：sqh3242511142@qq.com　"
            "GitHub 与 Mooncakes：sqhyyy　手机号：18975974634",
            small,
        ),
        para("项目定位", heading),
        para(
            "MoonLogfmt Lens 是使用 MoonBit 原创实现的 logfmt 数据契约与日志质量"
            "工具箱。它不生成或采集日志，而是对已有文本进行解析、契约验证、"
            "隐私脱敏、批量画像和版本漂移分析。",
            body,
        ),
        para("解决的问题", heading),
        para(
            "logfmt 易读易写，但重复键、缺失字段、未闭合引号和控制字符会破坏"
            "自动化；字段类型变化会让下游查询失效；新增字段还可能泄露令牌、"
            "邮箱、手机号或支付信息。常规单行解析器也无法解释新版本相对于"
            "已知良好基线发生了哪些变化。",
            body,
        ),
        para("已完成功能", heading),
        para(
            "版本 0.2.0 已实现完整 logfmt 扫描与质量审计、14 类语义值识别、"
            "带类型和必填项的可执行契约、Schema 自动推断、字段名与字段值双重"
            "隐私检测、三种脱敏模式、无值结构模板与稳定指纹、批量质量门禁，"
            "以及字段新增或消失、类型变化、出现率变化、长度增长、新结构、"
            "无效率和风险回归等漂移报告。",
            body,
        ),
        para("核心创新", heading),
        para(
            "项目形成“解析、语义画像、候选契约、隐私安全投影、无值结构指纹、"
            "基线漂移解释”的闭环。同一套值类型体系贯穿所有阶段；结构比较只"
            "保留键名和语义类型，不保留具体日志值，从而降低批次分析过程中的"
            "数据暴露风险。",
            body,
        ),
        para("技术路线", heading),
        para(
            "核心解析器基于 MoonBit Char 数组手写实现，不依赖解析器生成器或"
            "外部运行时包。契约、推断、隐私、批处理和漂移模块均通过公开结构体"
            "与枚举组合，可独立调用，也可串联用于 CI。",
            body,
        ),
        para("工程证据", heading),
        para(
            "格式化后的 MoonBit 手写代码共 5558 行，其中核心库 4410 行、测试"
            "976 行、CLI 与示例 172 行。项目包含 16 个 MoonBit 文件、五种 CLI"
            "模式、四个可运行示例和 95 项自动化测试。moon fmt --check、"
            "moon check、moon build、moon test、moon package --list 和 moon info"
            "均已通过；测试结果为 95 项通过、0 项失败。",
            body,
        ),
        para("查重与生态价值", heading),
        para(
            "项目已检索 Mooncakes、GitHub、公开代码及 MoonBit OSC 相关信息。"
            "已发现的相邻项目主要负责日志生成、遥测或通用基础设施；截至查重"
            "日期，未发现同时具备 logfmt 专用契约推断、隐私脱敏、无值结构"
            "指纹、批量门禁和基线漂移解释的公开 MoonBit 项目。",
            body,
        ),
        para("开源与身份", heading),
        para(
            "许可证：Apache-2.0。拟公开仓库：github.com/sqhyyy/moonlogfmt-lens。"
            "Mooncakes 账号：sqhyyy（使用 GitHub 账号登录）。默认分支：main。",
            body,
        ),
    ]

    story.append(Spacer(1, 1.5 * mm))
    story.append(
        para(
            "项目边界：不负责日志采集、文件跟踪、网络传输、OpenTelemetry 导出、"
            "JSON 解析或应用运行时日志输出；稳定令牌和结构指纹不声明具备密码学"
            "安全性。",
            small,
        )
    )

    doc = SimpleDocTemplate(
        str(OUTPUT),
        pagesize=A4,
        rightMargin=16 * mm,
        leftMargin=16 * mm,
        topMargin=14 * mm,
        bottomMargin=14 * mm,
        title="MoonLogfmt Lens Application",
        author="Song Qinghui",
    )
    doc.build(story)


if __name__ == "__main__":
    main()
